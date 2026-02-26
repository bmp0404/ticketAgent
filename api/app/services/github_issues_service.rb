# frozen_string_literal: true

class GithubIssuesService
  def initialize(token: nil)
    @client = Octokit::Client.new(access_token: token || ENV["GITHUB_ACCESS_TOKEN"])
  end

  def list_issues(owner, repo, state: "open", sort: "updated", direction: "desc", per_page: 30, page: 1, labels: nil)
    opts = { state: state, sort: sort, direction: direction, per_page: per_page, page: page }
    opts[:labels] = labels if labels.present?
    @client.list_issues("#{owner}/#{repo}", opts)
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

  def create_issue(owner, repo, title:, body: nil, labels: nil)
    opts = {}
    opts[:body] = body if body.present?
    opts[:labels] = Array(labels) if labels.present?
    @client.create_issue("#{owner}/#{repo}", title, body, opts)
  end

  def issue_timeline(owner, repo, issue_number)
    @client.get(
      "repos/#{owner}/#{repo}/issues/#{issue_number}/timeline",
      accept: "application/vnd.github.mockingbird-preview+json"
    )
  end

  def linked_pull_requests_for_issue(owner, repo, issue_number)
    events = issue_timeline(owner, repo, issue_number)
    pr_numbers = Array(events).select { |e| e[:event] == "cross_referenced" && e[:source] }.filter_map do |e|
      e[:source][:issue]&.dig(:number) || e[:source][:number]
    end.uniq

    pr_numbers.filter_map do |num|
      issue = issue(owner, repo, num)
      next unless issue&.pull_request.present?

      serialize_pull_request(issue)
    end
  end

  private

  def serialize_pull_request(pr)
    {
      number: pr.number,
      title: pr.title,
      state: pr.state,
      html_url: pr.html_url,
      merged: pr.merged,
      merged_at: pr.merged_at,
      created_at: pr.created_at,
      updated_at: pr.updated_at,
      closed_at: pr.closed_at,
      draft: pr.draft
    }.transform_keys(&:to_s)
  end
end
