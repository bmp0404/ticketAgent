# frozen_string_literal: true

class GithubIssuesService
  TIMELINE_ACCEPT = "application/vnd.github.mockingbird-preview+json"

  def initialize(access_token: nil)
    @client = Octokit::Client.new(access_token: access_token || ENV["GITHUB_ACCESS_TOKEN"])
  end

  def list_issues(owner, repo, state: "open", sort: "updated", direction: "desc", per_page: 30, page: 1, labels: nil)
    options = { state: state, sort: sort, direction: direction, per_page: per_page, page: page }
    options[:labels] = labels if labels.present?
    @client.list_issues("#{owner}/#{repo}", options)
  end

  def issue(owner, repo, number)
    @client.issue("#{owner}/#{repo}", number)
  end

  def issue_comments(owner, repo, number)
    @client.issue_comments("#{owner}/#{repo}", number)
  end

  def repository(owner, repo)
    @client.repository("#{owner}/#{repo}")
  end

  # Create a new issue (ticket) on GitHub.
  def create_issue(owner, repo, title:, body: nil, labels: nil)
    options = {}
    options[:labels] = Array(labels) if labels.present?
    @client.create_issue("#{owner}/#{repo}", title, body.to_s, options)
  end

  # Returns timeline events for an issue (includes cross_referenced when PRs link to this issue).
  def issue_timeline(owner, repo, issue_number)
    path = "repos/#{owner}/#{repo}/issues/#{issue_number}/timeline"
    @client.get(path, { accept: TIMELINE_ACCEPT })
  end

  # Fetches all pull requests that reference this issue (from timeline cross_referenced events).
  # Returns array of PR hashes with: number, title, state, html_url, merged, merged_at, created_at, updated_at.
  def linked_pull_requests_for_issue(owner, repo, issue_number)
    events = issue_timeline(owner, repo, issue_number)
    pr_numbers = []
    Array(events).each do |event|
      next unless event.respond_to?(:event) && event.event == "cross_referenced"
      next unless event.respond_to?(:source) && event.source
      source = event.source
      # source can be issue or pull_request; both have number
      num = source.respond_to?(:issue) ? source.issue&.number : source.respond_to?(:number) ? source.number : nil
      pr_numbers << num if num.is_a?(Integer)
    end
    pr_numbers.uniq!

    pr_numbers.filter_map do |num|
      ref = issue(owner, repo, num)
      next unless ref.respond_to?(:pull_request) && ref.pull_request.present?
      serialize_pull_request(ref)
    end
  end

  private

  def serialize_pull_request(pr)
    {
      number: pr.number,
      title: pr.title.to_s,
      state: pr.state.to_s,
      html_url: pr.html_url.to_s,
      merged: pr.respond_to?(:merged) ? !!pr.merged : false,
      merged_at: pr.respond_to?(:merged_at) ? pr.merged_at&.iso8601 : nil,
      created_at: pr.created_at&.iso8601,
      updated_at: pr.updated_at&.iso8601,
      closed_at: pr.respond_to?(:closed_at) ? pr.closed_at&.iso8601 : nil,
      draft: pr.respond_to?(:draft) ? !!pr.draft : false,
    }
  end
end
