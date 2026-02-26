# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_02_22_000005) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_graphql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "supabase_vault"
  enable_extension "uuid-ossp"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "bounty_confidence_level", ["low", "medium", "high"]
  create_enum "ticket_inferred_state", ["Backlog", "Ready", "InProgress", "InReview", "Done"]
  create_enum "ticket_status", ["open", "closed"]

  create_table "tickets", id: :text, force: :cascade do |t|
    t.text "title", null: false
    t.text "body"
    t.text "labels", default: [], array: true
    t.text "assignees", default: [], array: true
    t.text "milestone"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.timestamptz "last_activity_at", default: -> { "now()" }, null: false
    t.integer "comment_count", default: 0
    t.integer "reactions_count", default: 0
    t.text "linked_prs", default: [], array: true
    t.enum "status", default: "open", null: false, enum_type: "ticket_status"
    t.enum "inferred_state", default: "Backlog", null: false, enum_type: "ticket_inferred_state"
    t.decimal "priority_score", precision: 10, scale: 2, default: "0.0"
    t.decimal "bounty_recommendation", precision: 10, scale: 2, default: "0.0"
    t.enum "bounty_confidence", default: "low", enum_type: "bounty_confidence_level"
    t.jsonb "score_breakdown", default: {}
    t.jsonb "state_history", default: []
    t.jsonb "linked_prs_details", default: [], null: false
    t.text "repo_identifier", default: ""
    t.integer "issue_number", default: 0, null: false
    t.index ["assignees"], name: "idx_tickets_assignees", using: :gin
    t.index ["created_at"], name: "idx_tickets_created_at", order: :desc
    t.index ["inferred_state"], name: "idx_tickets_inferred_state"
    t.index ["inferred_state"], name: "index_tickets_on_inferred_state"
    t.index ["labels"], name: "idx_tickets_labels", using: :gin
    t.index ["last_activity_at"], name: "idx_tickets_last_activity_at", order: :desc
    t.index ["priority_score"], name: "idx_tickets_priority_score", order: :desc
    t.index ["priority_score"], name: "index_tickets_on_priority_score"
    t.index ["repo_identifier", "issue_number"], name: "index_tickets_on_repo_identifier_and_issue_number", unique: true
    t.index ["repo_identifier"], name: "index_tickets_on_repo_identifier"
    t.index ["status"], name: "idx_tickets_status"
    t.index ["status"], name: "index_tickets_on_status"
  end
end
