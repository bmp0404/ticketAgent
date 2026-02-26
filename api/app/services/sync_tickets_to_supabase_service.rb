# frozen_string_literal: true

class SyncTicketsToSupabaseService
  def self.call(owner:, repo:, github_token: nil, state: "open", per_page: 100)
    new(owner: owner, repo: repo, github_token: github_token).call(state: state, per_page: per_page)
  end

  def initialize(owner:, repo:, github_token: nil)
    @owner = owner
    @repo = repo
    @github = GithubIssuesService.new(token: github_token)
  end

  def call(state: "open", per_page: 100)
    count = 0
    page = 1

    loop do
      issues = @github.list_issues(@owner, @repo, state: state, per_page: per_page, page: page)
      issues.each do |issue|
        next if issue.respond_to?(:pull_request) && issue.pull_request.present?

        comments = @github.issue_comments(@owner, @repo, issue.number)
        reactions_count = issue.respond_to?(:reactions) && issue.reactions ? (issue.reactions.respond_to?(:total_count) ? issue.reactions.total_count : 0) : 0
        linked_prs_details = @github.linked_pull_requests_for_issue(@owner, @repo, issue.number)

        attrs = TicketBuilder.build(
          owner: @owner,
          repo: @repo,
          issue: issue,
          comments: comments,
          reactions_count: reactions_count,
          linked_prs_details: linked_prs_details
        )

        Ticket.upsert(
          attrs.transform_keys(&:to_s),
          unique_by: :id
        )
        count += 1
      end

      break if issues.size < per_page

      page += 1
    end

    { synced: count, repo: "#{@owner}/#{@repo}" }
  end
end
