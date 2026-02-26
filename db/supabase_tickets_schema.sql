-- Run this in Supabase SQL Editor if you create the table in Supabase instead of Rails migrations.
-- Schema matches the Ticket model and your TypeScript interface.

CREATE TABLE IF NOT EXISTS tickets (
  id TEXT PRIMARY KEY,
  repo_identifier TEXT NOT NULL,
  issue_number INTEGER NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  labels TEXT[] DEFAULT '{}',
  assignees TEXT[] DEFAULT '{}',
  milestone TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  last_activity_at TIMESTAMPTZ NOT NULL,
  comment_count INTEGER DEFAULT 0,
  reactions_count INTEGER DEFAULT 0,
  linked_prs TEXT[] DEFAULT '{}',
  linked_prs_details JSONB DEFAULT '[]',
  status TEXT NOT NULL CHECK (status IN ('open', 'closed')),
  inferred_state TEXT NOT NULL CHECK (inferred_state IN ('Backlog', 'Ready', 'InProgress', 'InReview', 'Done')),
  priority_score NUMERIC(10, 4) DEFAULT 0,
  bounty_recommendation NUMERIC(10, 2) DEFAULT 0,
  bounty_confidence TEXT CHECK (bounty_confidence IS NULL OR bounty_confidence IN ('low', 'medium', 'high')),
  score_breakdown JSONB DEFAULT '{}',
  state_history JSONB DEFAULT '[]'
);

CREATE INDEX IF NOT EXISTS index_tickets_on_repo_identifier ON tickets (repo_identifier);
CREATE INDEX IF NOT EXISTS index_tickets_on_status ON tickets (status);
CREATE INDEX IF NOT EXISTS index_tickets_on_inferred_state ON tickets (inferred_state);
CREATE INDEX IF NOT EXISTS index_tickets_on_priority_score ON tickets (priority_score);
CREATE UNIQUE INDEX IF NOT EXISTS index_tickets_on_repo_and_number ON tickets (repo_identifier, issue_number);

COMMENT ON TABLE tickets IS 'GitHub issues synced with inferred state, priority, and bounty recommendations';
