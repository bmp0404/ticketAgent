# frozen_string_literal: true

class Ticket < ApplicationRecord
  self.primary_key = "id"
  self.table_name = "tickets"

  # Don't overwrite created_at/updated_at with Rails timestamps; we store GitHub timestamps
  self.record_timestamps = false

  INFERRED_STATES = %w[Backlog Ready InProgress InReview Done].freeze
  STATUSES = %w[open closed].freeze
  BOUNTY_CONFIDENCE = %w[low medium high].freeze

  validates :id, presence: true, uniqueness: true
  validates :repo_identifier, :issue_number, :title, :status, :inferred_state, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :inferred_state, inclusion: { in: INFERRED_STATES }
  validates :bounty_confidence, inclusion: { in: BOUNTY_CONFIDENCE }, allow_nil: true

  scope :by_repo, ->(repo) { where(repo_identifier: repo) }
  scope :open, -> { where(status: "open") }
  scope :closed, -> { where(status: "closed") }
  scope :by_priority, -> { order(priority_score: :desc) }

  def self.ticket_id(owner, repo, number)
    "#{owner}/#{repo}##{number}"
  end

  def self.repo_from_id(id)
    id.to_s.sub(/#\d+\z/, "")
  end
end
