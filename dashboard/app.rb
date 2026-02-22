# frozen_string_literal: true

# Ticket Agent Dashboard – Sinatra app with ERB
# Run: bundle exec ruby app.rb
# Visit: http://localhost:4567

require "sinatra"
require "yaml"

# Helpers (Rails-like for ERB compatibility)
helpers do
  def number_with_delimiter(n)
    n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def link_to(text, path, opts = {})
    cls = opts[:class] || ""
    "<a href=\"#{path}\" class=\"#{cls}\">#{text}</a>"
  end

  def time_ago_in_words(from_time)
    return "?" unless from_time
    secs = (Time.now - from_time).to_i
    return "just now" if secs < 60
    return "#{secs / 60}m ago" if secs < 3600
    return "#{secs / 3600}h ago" if secs < 86400
    "#{secs / 86400}d ago"
  end

  def truncate(str, length: 60)
    return "" unless str
    s = str.gsub(/[#*_\[\]]/, "")
    s.length <= length ? s : "#{s[0, length]}..."
  end
end

# Load config from main project (optional)
def load_agent_config
  config_path = File.expand_path("../config/default.yaml", __dir__)
  return {} unless File.exist?(config_path)
  YAML.load_file(config_path) || {}
rescue StandardError
  {}
end

# Mock data for test frontend (replace with API/DB when backend is ready)
def stats
  {
    open_tickets: 24,
    total_bounty_pool: 4_200,
    completed_tickets: 31,
    contributors: 12,
    total_paid: 8_750
  }
end

def featured_tickets
  [
    { id: "42", title: "Add OAuth2 support for GitHub App", type: "feature", bounty: 250, description: "Implement OAuth2 flow for the GitHub App integration so users can authorize without personal tokens." },
    { id: "38", title: "Fix race in issue sync when repo has many issues", type: "bug", bounty: 150, description: "Sync sometimes duplicates or drops issues under high concurrency. Add locking or idempotent upsert." },
    { id: "55", title: "Document scoring weights and bounty policy", type: "documentation", bounty: 100, description: "Add a docs page explaining how priority and bounty are computed, with examples." },
    { id: "61", title: "Improve dashboard mobile layout", type: "design", bounty: 120, description: "Cards and stats should stack and remain readable on small screens." },
    { id: "44", title: "Add regression tests for scoring engine", type: "testing", bounty: 180, description: "Tests that prevent score/bounty changes from degrading gold-set accuracy." }
  ]
end

def recent_completions
  [
    { title: "Setup CI for Python 3.10/3.11", claimed_by: "alice", approved_at: Time.now - 3600, points: 80 },
    { title: "Normalize GitHub labels to internal types", claimed_by: "bob", approved_at: Time.now - 7200, points: 120 },
    { title: "Add ETag support to GitHub client", claimed_by: "carol", approved_at: Time.now - 86400, points: 95 }
  ]
end

def top_contributors
  [
    { name: "alice", bounties_completed: 8, total_earned: 640 },
    { name: "bob", bounties_completed: 5, total_earned: 520 },
    { name: "carol", bounties_completed: 4, total_earned: 380 }
  ]
end

def sprint_labels
  [["Sprint-23-01", 6], ["Sprint-22-12", 4]]
end

get "/" do
  @stats = stats
  @featured_tickets = featured_tickets
  @recent_completions = recent_completions
  @top_contributors = top_contributors
  @sprint_labels = sprint_labels
  erb :index
end

get "/bounties" do
  @stats = stats
  @featured_tickets = featured_tickets
  @sprint = params["sprint"]
  erb :bounties
end

get "/leaderboard" do
  @top_contributors = top_contributors
  erb :leaderboard
end

get "/ticket/:id" do
  @ticket = featured_tickets.find { |t| t[:id].to_s == params[:id] } || { id: params[:id], title: "Ticket ##{params[:id]}", type: "other", bounty: 0, description: "No details." }
  erb :ticket
end
