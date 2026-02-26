# frozen_string_literal: true

namespace :tickets do
  desc "Sync GitHub repo issues to Supabase (tickets table). Usage: rails tickets:sync[owner,repo]"
  task :sync, [:owner, :repo] => :environment do |_t, args|
    owner = args[:owner] || ENV["OWNER"]
    repo = args[:repo] || ENV["REPO"]
    abort "Usage: rails tickets:sync[owner,repo] or set OWNER and REPO" if owner.blank? || repo.blank?
    result = SyncTicketsToSupabaseService.new(owner: owner, repo: repo).call(state: "all", per_page: 100)
    puts "Synced #{result[:synced]} tickets for #{result[:repo]}"
  end

  desc "Create a GitHub issue (ticket), then sync so it appears in Supabase. Usage: rails tickets:create[owner,repo] or set OWNER, REPO, TITLE, BODY"
  task :create, [:owner, :repo] => :environment do |_t, args|
    owner = args[:owner] || ENV["OWNER"]
    repo = args[:repo] || ENV["REPO"]
    title = ENV["TITLE"].presence || "Test ticket from API (#{Time.current.strftime('%Y-%m-%d %H:%M')})"
    body = ENV["BODY"].presence || "This ticket was created via the GitHub Tickets API. Run sync to see it in Supabase."
    abort "Usage: OWNER=... REPO=... [TITLE=...] [BODY=...] rails tickets:create" if owner.blank? || repo.blank?

    github = GithubIssuesService.new
    issue = github.create_issue(owner, repo, title: title, body: body)
    puts "Created issue ##{issue.number}: #{issue.title}"
    puts "URL: #{issue.html_url}"

    result = SyncTicketsToSupabaseService.new(owner: owner, repo: repo).call(state: "all", per_page: 100)
    puts "Synced #{result[:synced]} tickets for #{owner}/#{repo}. New ticket should appear in Supabase."
  end
end
