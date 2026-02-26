# frozen_string_literal: true

module Api
  module V1
    class TicketsController < ApplicationController
      before_action :set_github_service, except: [:stored]

      # GET /api/v1/repos/:owner/:repo/tickets
      def index
        issues = @github.list_issues(
          params[:owner],
          params[:repo],
          state: params[:state] || "open",
          sort: params[:sort] || "updated",
          direction: params[:direction] || "desc",
          per_page: (params[:per_page] || 30).to_i.clamp(1, 100),
          page: (params[:page] || 1).to_i,
          labels: params[:labels]
        )
        render json: issues.map { |i| serialize_issue(i) }
      end

      # GET /api/v1/repos/:owner/:repo/tickets/:number
      def show
        issue = @github.issue(params[:owner], params[:repo], params[:number])
        render json: serialize_issue(issue, include_body: true)
      end

      # GET /api/v1/repos/:owner/:repo/tickets/:number/analyze
      def analyze
        issue = @github.issue(params[:owner], params[:repo], params[:number])
        comments = @github.issue_comments(params[:owner], params[:repo], params[:number])
        analysis = build_ticket_analysis(issue, comments)
        render json: analysis
      end

      # GET /api/v1/repos/:owner/:repo/analyze
      def analyze_repo
        issues = @github.list_issues(
          params[:owner],
          params[:repo],
          state: params[:state] || "open",
          per_page: (params[:per_page] || 50).to_i.clamp(1, 100)
        )
        analyses = issues.map do |issue|
          build_ticket_analysis(issue, [])
        end
        render json: { tickets: analyses, count: analyses.size }
      end

      # POST /api/v1/repos/:owner/:repo/tickets — create a GitHub issue (ticket), optionally sync to Supabase
      def create
        title = params[:title].presence || "Ticket from API (#{Time.current.strftime('%Y-%m-%d %H:%M')})"
        body = params[:body].presence
        issue = @github.create_issue(params[:owner], params[:repo], title: title, body: body)
        sync_after = ActiveModel::Type::Boolean.new.cast(params[:sync])
        if sync_after
          SyncTicketsToSupabaseService.new(
            owner: params[:owner],
            repo: params[:repo],
            github_token: request.headers["X-GitHub-Token"].presence || ENV["GITHUB_ACCESS_TOKEN"],
          ).call(state: "all", per_page: 100)
        end
        render json: { number: issue.number, title: issue.title, html_url: issue.html_url, synced: sync_after }, status: :created
      end

      # GET /api/v1/repos/:owner/:repo/tickets/stored — list tickets from Supabase
      def stored
        repo = "#{params[:owner]}/#{params[:repo]}"
        tickets = Ticket.by_repo(repo).by_priority
        tickets = tickets.where(status: params[:status]) if params[:status].present?
        tickets = tickets.where(inferred_state: params[:inferred_state]) if params[:inferred_state].present?
        tickets = tickets.limit((params[:per_page] || 50).to_i.clamp(1, 100))
        render json: tickets
      end

      # POST /api/v1/repos/:owner/:repo/sync — sync GitHub issues to Supabase
      def sync
        result = SyncTicketsToSupabaseService.new(
          owner: params[:owner],
          repo: params[:repo],
          github_token: request.headers["X-GitHub-Token"].presence || ENV["GITHUB_ACCESS_TOKEN"],
        ).call(state: params[:state] || "all", per_page: (params[:per_page] || 100).to_i.clamp(1, 100))
        render json: result
      end

      private

      def set_github_service
        token = request.headers["X-GitHub-Token"].presence || ENV["GITHUB_ACCESS_TOKEN"]
        raise Octokit::Unauthorized if token.blank?
        @github = GithubIssuesService.new(access_token: token)
      end

      def serialize_issue(issue, include_body: false)
        h = {
          number: issue.number,
          title: issue.title,
          state: issue.state,
          html_url: issue.html_url,
          created_at: issue.created_at,
          updated_at: issue.updated_at,
          closed_at: issue.closed_at,
          labels: issue.labels.map { |l| { name: l.name, color: l.color } },
          assignees: issue.assignees.map { |a| { login: a.login, avatar_url: a.avatar_url } },
          user: issue.user ? { login: issue.user.login, avatar_url: issue.user.avatar_url } : nil,
          comments_count: issue.comments,
          reactions: issue.respond_to?(:reactions) ? issue.reactions : nil,
          milestone: issue.milestone ? { title: issue.milestone.title, state: issue.milestone.state } : nil,
        }
        h[:body] = issue.body if include_body
        h[:pull_request] = issue.respond_to?(:pull_request) && issue.pull_request.present?
        h
      end

      def build_ticket_analysis(issue, comments)
        serialize_issue(issue, include_body: true).merge(
          analysis: {
            comment_count: comments.size,
            has_labels: issue.labels.any?,
            label_names: issue.labels.map(&:name),
            is_assigned: issue.assignees.any?,
            has_milestone: issue.milestone.present?,
            age_days: ((Time.current - issue.created_at) / 1.day).round,
            days_since_update: ((Time.current - issue.updated_at) / 1.day).round,
            urgency_signals: urgency_signals(issue),
            summary: summarize_issue(issue, comments),
          }
        )
      end

      def urgency_signals(issue)
        signals = []
        label_names = issue.labels.map(&:name).map(&:downcase)
        signals << "bug" if label_names.any? { |n| n.include?("bug") }
        signals << "security" if label_names.any? { |n| n.include?("security") }
        signals << "priority" if label_names.any? { |n| n.include?("priority") || n.include?("urgent") }
        signals << "blocker" if label_names.any? { |n| n.include?("blocker") }
        signals
      end

      def summarize_issue(issue, comments)
        parts = []
        parts << "Open" if issue.state == "open"
        parts << "#{issue.comments} comment(s)"
        parts << "#{issue.labels.size} label(s)" if issue.labels.any?
        parts << "Assigned" if issue.assignees.any?
        parts << "In milestone: #{issue.milestone.title}" if issue.milestone.present?
        parts.join(", ")
      end
    end
  end
end
