# frozen_string_literal: true

module Api
  module V1
    class TicketsController < ApplicationController
      before_action :set_github_service, except: [:stored]
      before_action :set_owner_repo

      def index
        state = params[:state].presence || "open"
        sort = params[:sort].presence || "updated"
        direction = params[:direction].presence || "desc"
        per_page = (params[:per_page] || 30).to_i
        page = (params[:page] || 1).to_i
        labels = params[:labels].presence

        issues = @github.list_issues(
          @owner, @repo,
          state: state, sort: sort, direction: direction,
          per_page: per_page, page: page, labels: labels
        )

        json = issues.reject { |i| i.respond_to?(:pull_request) && i.pull_request.present? }.map do |issue|
          serialize_issue(issue, include_body: false)
        end

        render json: json
      end

      def show
        issue = @github.issue(@owner, @repo, params[:number])
        render json: serialize_issue(issue, include_body: params[:include_body] == "true")
      end

      def create
        title = params.require(:title)
        body = params[:body]
        sync = ActiveModel::Type::Boolean.new.cast(params[:sync])
        labels = params[:labels]

        issue = @github.create_issue(@owner, @repo, title: title, body: body, labels: labels)

        result = { number: issue.number, title: issue.title, html_url: issue.html_url, synced: false }
        if sync
          SyncTicketsToSupabaseService.call(owner: @owner, repo: @repo, github_token: github_token, state: "all", per_page: 100)
          # Sync single issue into DB so the new one is present
          sync_single_issue(issue.number)
          result[:synced] = true
        end

        render json: result, status: :created
      end

      def stored
        repo_identifier = "#{@owner}/#{@repo}"
        scope = Ticket.by_repo(repo_identifier).by_priority
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(inferred_state: params[:inferred_state]) if params[:inferred_state].present?
        per_page = (params[:per_page] || 30).to_i
        tickets = scope.limit(per_page)

        render json: tickets.map { |t| ticket_to_json(t) }
      end

      def sync
        state = params[:state].presence || "open"
        per_page = (params[:per_page] || 100).to_i
        result = SyncTicketsToSupabaseService.call(
          owner: @owner, repo: @repo, github_token: github_token,
          state: state, per_page: per_page
        )
        render json: result
      end

      def analyze
        issue = @github.issue(@owner, @repo, params[:number])
        comments = @github.issue_comments(@owner, @repo, params[:number])
        reactions_count = issue.respond_to?(:reactions) && issue.reactions ? (issue.reactions.respond_to?(:total_count) ? issue.reactions.total_count : 0) : 0
        linked_prs_details = @github.linked_pull_requests_for_issue(@owner, @repo, params[:number])

        attrs = TicketBuilder.build(
          owner: @owner, repo: @repo, issue: issue,
          comments: comments, reactions_count: reactions_count, linked_prs_details: linked_prs_details
        )

        analysis = {
          comment_count: comments.size,
          label_names: issue.labels.to_a.map { |l| l.respond_to?(:name) ? l.name : l[:name] },
          age_days: ((Time.current - issue.created_at) / 86400).round(1),
          days_since_update: ((Time.current - issue.updated_at) / 86400).round(1),
          urgency_signals: issue.labels.to_a.map { |l| (l.respond_to?(:name) ? l.name : l.to_s).to_s }.select { |n| n =~ /urgent|blocker|bug|security/i },
          summary: attrs.slice(:inferred_state, :priority_score, :bounty_recommendation, :bounty_confidence, :score_breakdown)
        }

        render json: build_ticket_analysis(issue, comments, analysis)
      end

      def analyze_repo
        issues = @github.list_issues(@owner, @repo, state: "open", per_page: 100)
        issues = issues.reject { |i| i.respond_to?(:pull_request) && i.pull_request.present? }

        analyses = issues.first(10).map do |issue|
          comments = @github.issue_comments(@owner, @repo, issue.number)
          reactions_count = issue.respond_to?(:reactions) && issue.reactions ? (issue.reactions.respond_to?(:total_count) ? issue.reactions.total_count : 0) : 0
          linked_prs_details = @github.linked_pull_requests_for_issue(@owner, @repo, issue.number)
          attrs = TicketBuilder.build(owner: @owner, repo: @repo, issue: issue, comments: comments, reactions_count: reactions_count, linked_prs_details: linked_prs_details)
          {
            number: issue.number,
            title: issue.title,
            analysis: attrs.slice(:inferred_state, :priority_score, :bounty_recommendation, :score_breakdown)
          }
        end

        render json: { repo: "#{@owner}/#{@repo}", sample_analyses: analyses }
      end

      private

      def set_github_service
        @github = GithubIssuesService.new(token: github_token)
      end

      def github_token
        request.headers["X-GitHub-Token"].presence || ENV["GITHUB_ACCESS_TOKEN"]
      end

      def set_owner_repo
        @owner = params[:owner]
        @repo = params[:repo]
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
          labels: issue.labels.to_a.map { |l| l.respond_to?(:name) ? l.name : l[:name] },
          assignees: issue.assignees.to_a.map { |a| a.respond_to?(:login) ? a.login : a[:login] },
          user: issue.user.respond_to?(:login) ? issue.user.login : issue.user[:login],
          comments_count: issue.comments,
          reactions: issue.respond_to?(:reactions) ? issue.reactions : nil,
          milestone: issue.milestone&.title
        }
        h[:body] = issue.body if include_body
        h
      end

      def build_ticket_analysis(issue, comments, analysis)
        serialize_issue(issue, include_body: true).merge(
          analysis: analysis
        )
      end

      def ticket_to_json(t)
        t.attributes.slice(
          "id", "repo_identifier", "issue_number", "title", "body", "labels", "assignees", "milestone",
          "created_at", "updated_at", "last_activity_at", "comment_count", "reactions_count",
          "linked_prs", "linked_prs_details", "status", "inferred_state", "priority_score",
          "bounty_recommendation", "bounty_confidence", "score_breakdown", "state_history"
        )
      end

      def sync_single_issue(issue_number)
        issue = @github.issue(@owner, @repo, issue_number)
        return if issue.respond_to?(:pull_request) && issue.pull_request.present?

        comments = @github.issue_comments(@owner, @repo, issue_number)
        reactions_count = issue.respond_to?(:reactions) && issue.reactions ? (issue.reactions.respond_to?(:total_count) ? issue.reactions.total_count : 0) : 0
        linked_prs_details = @github.linked_pull_requests_for_issue(@owner, @repo, issue_number)
        attrs = TicketBuilder.build(owner: @owner, repo: @repo, issue: issue, comments: comments, reactions_count: reactions_count, linked_prs_details: linked_prs_details)
        Ticket.upsert(attrs.transform_keys(&:to_s), unique_by: :id)
      end
    end
  end
end
