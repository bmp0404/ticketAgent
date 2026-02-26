# frozen_string_literal: true

# Builds a Ticket record (for Supabase) from a GitHub issue + optional comments.
# Computes: inferred_state, priority_score, bounty_recommendation, bounty_confidence, score_breakdown, state_history.
class TicketBuilder
  INFERRED_STATES = %w[Backlog Ready InProgress InReview Done].freeze
  LABEL_STATE_MAP = {
    "backlog" => "Backlog",
    "ready" => "Ready",
    "in progress" => "InProgress",
    "in review" => "InReview",
    "done" => "Done",
    "wontfix" => "Backlog",
    "icebox" => "Backlog",
  }.freeze

  def initialize(owner:, repo:, issue:, comments: [], reactions_count: 0, linked_prs_details: [])
    @owner = owner
    @repo = repo
    @issue = issue
    @comments = comments
    @reactions_count = reactions_count
    @linked_prs_details = linked_prs_details
  end

  def build
    inferred = infer_state
    breakdown = compute_score_breakdown(inferred)
    priority = breakdown.values.sum
    bounty, bounty_conf = compute_bounty(priority, breakdown)
    id = Ticket.ticket_id(@owner, @repo, @issue.number)

    {
      id: id,
      repo_identifier: "#{@owner}/#{@repo}",
      issue_number: @issue.number,
      title: @issue.title.to_s,
      body: @issue.body.to_s,
      labels: @issue.labels.map(&:name),
      assignees: @issue.assignees.map(&:login),
      milestone: @issue.milestone&.title,
      created_at: @issue.created_at,
      updated_at: @issue.updated_at,
      last_activity_at: last_activity_at,
      comment_count: @comments.size,
      reactions_count: @reactions_count,
      linked_prs: extract_linked_prs,
      linked_prs_details: @linked_prs_details,
      status: @issue.state,
      inferred_state: inferred,
      priority_score: priority.round(4),
      bounty_recommendation: bounty,
      bounty_confidence: bounty_conf,
      score_breakdown: breakdown,
      state_history: [], # populated on subsequent syncs if we track history
    }
  end

  private

  def last_activity_at
    return @issue.updated_at if @comments.empty?
    last_comment = @comments.max_by(&:created_at)
    [@issue.updated_at, last_comment&.created_at].compact.max
  end

  def extract_linked_prs
    text = [@issue.body, @issue.title].compact.join(" ")
    # Match "fixes #123", "PR #45", "https://github.com/owner/repo/pull/12", etc.
    pr_refs = text.scan(/#(\d+)/).flatten.uniq
    pr_refs.map { |n| "##{n}" }
  end

  def infer_state
    return "Done" if @issue.state == "closed"
    label_names = @issue.labels.map { |l| l.name.downcase }
    label_names.each do |name|
      key = name.downcase.gsub(/\s+/, " ")
      return LABEL_STATE_MAP[key] if LABEL_STATE_MAP.key?(key)
    end
    # Heuristics: assigned + has description => Ready; has PR link => InReview
    return "InReview" if @issue.body.to_s.match?(/pull\s*request|#\d+/i)
    return "Ready" if @issue.assignees.any? && @issue.body.present?
    "Backlog"
  end

  def compute_score_breakdown(inferred_state)
    impact = 0.0
    impact += 10 if @issue.labels.any?
    impact += 5 if @issue.milestone.present?
    impact += (@reactions_count * 2).clamp(0, 20)
    impact += 15 if @issue.labels.any? { |l| l.name.downcase.include?("bug") }
    impact += 25 if @issue.labels.any? { |l| l.name.downcase.include?("security") }

    effort = 5.0
    effort += 5 if @issue.labels.any? { |l| l.name.downcase.include?("effort") }

    urgency = 0.0
    urgency += 20 if @issue.labels.any? { |l| l.name.downcase.include?("urgent") }
    urgency += 15 if @issue.labels.any? { |l| l.name.downcase.include?("blocker") }

    age_days = ((Time.current - @issue.created_at) / 1.day).to_i
    staleness = [age_days * 0.5, 15].min

    state_bonus = case inferred_state
                 when "InProgress" then 10
                 when "InReview" then 5
                 when "Ready" then 3
                 else 0
                 end

    {
      impact: impact.round(2),
      effort: effort.round(2),
      urgency: urgency.round(2),
      staleness: staleness.round(2),
      state_bonus: state_bonus.round(2),
    }
  end

  def compute_bounty(priority_score, breakdown)
    base = [priority_score * 2, 50].max
    base = [base, 500].min
    confidence = priority_score > 30 ? "high" : (priority_score > 15 ? "medium" : "low")
    [base.round(2), confidence]
  end
end
