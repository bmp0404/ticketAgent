# frozen_string_literal: true

namespace :tickets do
  desc "Sync GitHub issues to Supabase [owner, repo]. Use ENV OWNER, REPO if args contain special chars."
  task :sync, [:owner, :repo] => :environment do |_t, args|
    owner = args[:owner] || ENV["OWNER"]
    repo = args[:repo] || ENV["REPO"]
    raise "Set OWNER and REPO (or pass owner,repo)" if owner.blank? || repo.blank?

    result = SyncTicketsToSupabaseService.call(owner: owner, repo: repo, state: "all", per_page: 100)
    puts "Synced #{result[:synced]} tickets for #{result[:repo]}"
  end

  desc "Create a GitHub issue and sync to Supabase. Use ENV OWNER, REPO, TITLE, BODY."
  task :create, [:owner, :repo, :title, :body] => :environment do |_t, args|
    owner = args[:owner] || ENV["OWNER"]
    repo = args[:repo] || ENV["REPO"]
    title = args[:title] || ENV["TITLE"] || "New ticket"
    body = args[:body] || ENV["BODY"]
    raise "Set OWNER and REPO" if owner.blank? || repo.blank?

    github = GithubIssuesService.new
    issue = github.create_issue(owner, repo, title: title, body: body)
    puts "Created issue ##{issue.number}: #{issue.html_url}"

    SyncTicketsToSupabaseService.call(owner: owner, repo: repo, state: "all", per_page: 100)
    puts "Synced to Supabase."
  end
end
