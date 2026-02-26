# frozen_string_literal: true

class Ticket < ApplicationRecord
  self.primary_key = "id"
  self.table_name = "tickets"
  self.record_timestamps = false

  VALID_STATUSES = %w[open closed].freeze
  VALID_INFERRED_STATES = %w[Backlog Ready InProgress InReview Done].freeze
  VALID_BOUNTY_CONFIDENCE = %w[low medium high].freeze

  validates :id, presence: true, uniqueness: true
  validates :repo_identifier, :issue_number, :title, :status, :inferred_state, presence: true
  validates :status, inclusion: { in: VALID_STATUSES }
  validates :inferred_state, inclusion: { in: VALID_INFERRED_STATES }
  validates :bounty_confidence, inclusion: { in: VALID_BOUNTY_CONFIDENCE }, allow_nil: true

  scope :by_repo, ->(repo) { where(repo_identifier: repo) }
  scope :open, -> { where(status: "open") }
  scope :closed, -> { where(status: "closed") }
  scope :by_priority, -> { order(priority_score: :desc) }

  class << self
    def ticket_id(owner, repo, number)
      "#{owner}/#{repo}##{number}"
    end

    def repo_from_id(id)
      return nil unless id.to_s.include?("#")

      id.to_s.sub(/#\d+\z/, "")
    end
  end
end
