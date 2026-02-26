# frozen_string_literal: true

class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:tickets)

    create_table :tickets, id: false do |t|
      t.string :id, null: false
      t.string :repo_identifier, null: false
      t.integer :issue_number, null: false
      t.string :title, null: false
      t.text :body
      t.string :labels, array: true, default: []
      t.string :assignees, array: true, default: []
      t.string :milestone
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.datetime :last_activity_at, null: false
      t.integer :comment_count, default: 0
      t.integer :reactions_count, default: 0
      t.string :linked_prs, array: true, default: []
      t.jsonb :linked_prs_details, default: [], null: false
      t.string :status, null: false
      t.string :inferred_state, null: false
      t.decimal :priority_score, precision: 10, scale: 4, default: 0
      t.decimal :bounty_recommendation, precision: 10, scale: 2, default: 0
      t.string :bounty_confidence
      t.jsonb :score_breakdown, default: {}
      t.jsonb :state_history, default: []
    end

    execute "ALTER TABLE tickets ADD PRIMARY KEY (id);"
    add_index :tickets, :repo_identifier if column_exists?(:tickets, :repo_identifier)
    add_index :tickets, [:repo_identifier, :issue_number], unique: true if column_exists?(:tickets, :repo_identifier) && column_exists?(:tickets, :issue_number)
    add_index :tickets, :status if column_exists?(:tickets, :status)
    add_index :tickets, :inferred_state if column_exists?(:tickets, :inferred_state)
    add_index :tickets, :priority_score if column_exists?(:tickets, :priority_score)
  end
end
