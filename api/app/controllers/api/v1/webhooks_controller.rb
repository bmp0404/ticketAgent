# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < ApplicationController
      skip_before_action :verify_authenticity_token

      # GitHub webhook: receive issue/comment events and sync to Supabase.
      # Configure in GitHub: Settings → Webhooks → Add (Content type: application/json).
      # Events: issues, issue_comment. Secret optional (not verified here for simplicity).
      def github
        payload = JSON.parse(request.raw_post)
        event = request.headers["X-GitHub-Event"]

        case event
        when "issues"
          handle_issue_event(payload)
        when "issue_comment"
          handle_issue_comment_event(payload)
        end

        head :ok
      rescue JSON::ParserError
        render json: { error: "Invalid JSON" }, status: :bad_request
      end

      private

      def handle_issue_event(payload)
        action = payload["action"]
        issue = payload["issue"]
        return unless issue && %w[opened edited closed reopened].include?(action)

        owner = payload.dig("repository", "owner", "login")
        repo = payload.dig("repository", "name")
        number = issue["number"]

        sync_single_issue(owner, repo, number)
        notify_frontend_webhook if ENV["FRONTEND_WEBHOOK_URL"].present?
      end

      def handle_issue_comment_event(payload)
        issue = payload["issue"]
        return unless issue

        owner = payload.dig("repository", "owner", "login")
        repo = payload.dig("repository", "name")
        number = issue["number"]

        sync_single_issue(owner, repo, number)
        notify_frontend_webhook if ENV["FRONTEND_WEBHOOK_URL"].present?
      end

      def sync_single_issue(owner, repo, number)
        github = GithubIssuesService.new(token: ENV["GITHUB_ACCESS_TOKEN"])
        issue = github.issue(owner, repo, number)
        return if issue.respond_to?(:pull_request) && issue.pull_request.present?

        comments = github.issue_comments(owner, repo, number)
        reactions_count = issue.respond_to?(:reactions) && issue.reactions ? (issue.reactions.respond_to?(:total_count) ? issue.reactions.total_count : 0) : 0
        linked_prs_details = github.linked_pull_requests_for_issue(owner, repo, number)

        attrs = TicketBuilder.build(
          owner: owner, repo: repo, issue: issue,
          comments: comments, reactions_count: reactions_count, linked_prs_details: linked_prs_details
        )
        Ticket.upsert(attrs.transform_keys(&:to_s), unique_by: :id)
      end

      def notify_frontend_webhook
        uri = URI(ENV["FRONTEND_WEBHOOK_URL"])
        Net::HTTP.post(
          uri,
          { event: "tickets_updated", source: "github_webhook" }.to_json,
          "Content-Type" => "application/json"
        )
      rescue StandardError
        # Best-effort; don't fail the webhook
      end
    end
  end
end
