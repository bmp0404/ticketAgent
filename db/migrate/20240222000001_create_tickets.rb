# frozen_string_literal: true

class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets, id: false, if_not_exists: true do |t|
      t.string :id, null: false, primary_key: true  # e.g. "owner/repo#123"
      t.string :repo_identifier, null: false       # "owner/repo" for querying
      t.integer :issue_number, null: false
      t.string :title, null: false
      t.text :body
      t.string :labels, array: true, default: []
      t.string :assignees, array: true, default: []
      t.string :milestone
      t.datetime :created_at, null: false           # from GitHub
      t.datetime :updated_at, null: false           # from GitHub
      t.datetime :last_activity_at, null: false
      t.integer :comment_count, default: 0
      t.integer :reactions_count, default: 0
      t.string :linked_prs, array: true, default: []
      t.string :status, null: false                 # "open" | "closed"
      t.string :inferred_state, null: false         # Backlog | Ready | InProgress | InReview | Done
      t.decimal :priority_score, precision: 10, scale: 4, default: 0
      t.decimal :bounty_recommendation, precision: 10, scale: 2, default: 0
      t.string :bounty_confidence                    # low | medium | high
      t.jsonb :score_breakdown, default: {}
      t.jsonb :state_history, default: []
    end

    add_index :tickets, :repo_identifier, if_not_exists: true if column_exists?(:tickets, :repo_identifier)
    add_index :tickets, :status, if_not_exists: true
    add_index :tickets, :inferred_state, if_not_exists: true
    add_index :tickets, :priority_score, if_not_exists: true
    add_index :tickets, [:repo_identifier, :issue_number], unique: true, if_not_exists: true if column_exists?(:tickets, :repo_identifier)
  end
end
