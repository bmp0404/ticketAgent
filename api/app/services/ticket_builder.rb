# frozen_string_literal: true

class TicketBuilder
  def self.build(owner:, repo:, issue:, comments: [], reactions_count: 0, linked_prs_details: [])
    new(owner: owner, repo: repo, issue: issue, comments: comments, reactions_count: reactions_count, linked_prs_details: linked_prs_details).build
  end

  def initialize(owner:, repo:, issue:, comments: [], reactions_count: 0, linked_prs_details: [])
    @owner = owner
    @repo = repo
    @issue = issue
    @comments = comments
    @reactions_count = reactions_count
    @linked_prs_details = linked_prs_details
  end

  def build
    last_activity = [
      @issue.updated_at,
      @comments.map { |c| c.respond_to?(:updated_at) ? c.updated_at : c[:updated_at] }.max
    ].compact.max || @issue.created_at

    inferred = inferred_state
    breakdown = score_breakdown(inferred)
    bounty_val, bounty_conf = bounty(breakdown, inferred)

    linked_prs = parse_linked_prs(@issue.body.to_s + " " + @issue.title.to_s)

    {
      id: Ticket.ticket_id(@owner, @repo, @issue.number),
      repo_identifier: "#{@owner}/#{@repo}",
      issue_number: @issue.number,
      title: @issue.title,
      body: @issue.body,
      labels: @issue.labels.to_a.map { |l| l.respond_to?(:name) ? l.name : l[:name] },
      assignees: @issue.assignees.to_a.map { |a| a.respond_to?(:login) ? a.login : a[:login] },
      milestone: @issue.milestone&.title,
      created_at: @issue.created_at,
      updated_at: @issue.updated_at,
      last_activity_at: last_activity,
      comment_count: @comments.size,
      reactions_count: @reactions_count,
      linked_prs: linked_prs,
      linked_prs_details: @linked_prs_details.map { |h| h.transform_keys(&:to_s) },
      status: @issue.state,
      inferred_state: inferred,
      priority_score: breakdown.values.sum.round(4),
      bounty_recommendation: bounty_val,
      bounty_confidence: bounty_conf,
      score_breakdown: breakdown,
      state_history: []
    }
  end

  private

  def inferred_state
    return "Done" if @issue.state == "closed"

    label_names = @issue.labels.to_a.map { |l| (l.respond_to?(:name) ? l.name : l[:name]).to_s.downcase }
    return "Backlog" if label_names.any? { |n| n == "backlog" || n.include?("wontfix") || n.include?("icebox") }
    return "Ready" if label_names.any? { |n| n.include?("ready") }
    return "InProgress" if label_names.any? { |n| n.include?("in progress") || n.include?("in_progress") }
    return "InReview" if label_names.any? { |n| n.include?("in review") || n.include?("in_review") }
    return "Done" if label_names.any? { |n| n.include?("done") }

    body = @issue.body.to_s
    assignees = @issue.assignees.to_a
    return "InReview" if body =~ /#\d+/ || body =~ %r{pull/\d+}
    return "Ready" if assignees.any? && body.present?

    "Backlog"
  end

  def score_breakdown(inferred_state)
    impact = 0.0
    impact += 1.0 if @issue.milestone.present?
    impact += 0.5 * @issue.labels.to_a.size
    impact += 0.3 * @reactions_count
    impact += 2.0 if @issue.labels.to_a.any? { |l| (l.respond_to?(:name) ? l.name : l.to_s).to_s =~ /bug|security/i }

    effort = 1.0
    urgency = 0.0
    urgency += 1.5 if @issue.labels.to_a.any? { |l| (l.respond_to?(:name) ? l.name : l.to_s).to_s.downcase.include?("urgent") }
    urgency += 2.0 if @issue.labels.to_a.any? { |l| (l.respond_to?(:name) ? l.name : l.to_s).to_s.downcase.include?("blocker") }

    age_days = ((Time.current - @issue.created_at) / 86400.0).to_f
    staleness = [age_days / 30.0, 5.0].min

    state_bonus = case inferred_state
                  when "Done" then 0
                  when "InReview" then 2.0
                  when "InProgress" then 1.5
                  when "Ready" then 1.0
                  else 0.5
                  end

    {
      impact: impact.round(4),
      effort: effort,
      urgency: urgency.round(4),
      staleness: staleness.round(4),
      state_bonus: state_bonus
    }
  end

  def bounty(breakdown, inferred_state)
    score = breakdown.values.sum
    base = [[25, score * 10].max, 500].min
    confidence = score > 5 ? "high" : (score > 2 ? "medium" : "low")
    [base.round(2), confidence]
  end

  def parse_linked_prs(text)
    text.scan(/#(\d+)/).flatten.uniq.map { |n| "##{n}" }
  end
end
