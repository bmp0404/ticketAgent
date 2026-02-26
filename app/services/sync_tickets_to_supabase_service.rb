# frozen_string_literal: true

# Syncs GitHub issues for a repo into the tickets table (Supabase/Postgres).
# Fetches issues from GitHub, builds Ticket records with inferred_state/priority/bounty, upserts.
class SyncTicketsToSupabaseService
  def initialize(owner:, repo:, github_token: nil)
    @owner = owner
    @repo = repo
    @github = GithubIssuesService.new(access_token: github_token || ENV["GITHUB_ACCESS_TOKEN"])
  end

  def call(state: "open", per_page: 100)
    synced = 0
    page = 1
    loop do
      issues = @github.list_issues(@owner, @repo, state: state, per_page: per_page, page: page)
      break if issues.empty?

      issues.each do |issue|
        next if issue.respond_to?(:pull_request?) && issue.pull_request?
        attrs = build_ticket_attrs(issue)
        Ticket.upsert(attrs, unique_by: :id)
        synced += 1
      end

      break if issues.size < per_page
      page += 1
    end
    { synced: synced, repo: "#{@owner}/#{@repo}" }
  end

  private

  def build_ticket_attrs(issue)
    comments = @github.issue_comments(@owner, @repo, issue.number)
    reactions_count = issue.respond_to?(:reactions) && issue.reactions ? (issue.reactions.total_count || 0) : 0
    linked_prs_details = @github.linked_pull_requests_for_issue(@owner, @repo, issue.number)
    TicketBuilder.new(
      owner: @owner,
      repo: @repo,
      issue: issue,
      comments: comments,
      reactions_count: reactions_count,
      linked_prs_details: linked_prs_details,
    ).build
  end
end
