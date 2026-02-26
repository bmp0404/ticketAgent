# frozen_string_literal: true

# This file is auto-generated from the Rails migrations and/or Supabase.
# Supabase contract: id TEXT PK; repo_identifier, issue_number, title, body, labels[], assignees[], milestone, timestamps, comment_count, reactions_count, linked_prs[], linked_prs_details jsonb, status, inferred_state, priority_score, bounty_*, score_breakdown, state_history.

ActiveRecord::Schema[7.1].define(version: 2025_02_25_000001) do
  create_table "tickets", id: false, if_not_exists: true do |t|
    t.string "id", null: false
    t.string "repo_identifier", null: false
    t.integer "issue_number", null: false
    t.string "title", null: false
    t.text "body"
    t.string "labels", array: true, default: []
    t.string "assignees", array: true, default: []
    t.string "milestone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_activity_at", null: false
    t.integer "comment_count", default: 0
    t.integer "reactions_count", default: 0
    t.string "linked_prs", array: true, default: []
    t.jsonb "linked_prs_details", default: [], null: false
    t.string "status", null: false
    t.string "inferred_state", null: false
    t.decimal "priority_score", precision: 10, scale: 4, default: "0.0"
    t.decimal "bounty_recommendation", precision: 10, scale: 2, default: "0.0"
    t.string "bounty_confidence"
    t.jsonb "score_breakdown", default: {}
    t.jsonb "state_history", default: []
  end

  add_index "tickets", "id", unique: true, if_not_exists: true
  add_index "tickets", "repo_identifier", if_not_exists: true if column_exists?(:tickets, :repo_identifier)
  add_index "tickets", ["repo_identifier", "issue_number"], unique: true, if_not_exists: true if column_exists?(:tickets, :repo_identifier) && column_exists?(:tickets, :issue_number)
  add_index "tickets", "status", if_not_exists: true if column_exists?(:tickets, :status)
  add_index "tickets", "inferred_state", if_not_exists: true if column_exists?(:tickets, :inferred_state)
  add_index "tickets", "priority_score", if_not_exists: true if column_exists?(:tickets, :priority_score)
end
