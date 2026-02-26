-- Supabase tickets table (exact contract). Run in Supabase SQL Editor if not using Rails migrations.
-- Use Session pooler for DATABASE_URL (not Direct connection).

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
  linked_prs_details JSONB DEFAULT '[]' NOT NULL,
  status TEXT NOT NULL,
  inferred_state TEXT NOT NULL,
  priority_score DECIMAL(10,4) DEFAULT 0,
  bounty_recommendation DECIMAL(10,2) DEFAULT 0,
  bounty_confidence TEXT,
  score_breakdown JSONB DEFAULT '{}',
  state_history JSONB DEFAULT '[]'
);

CREATE INDEX IF NOT EXISTS idx_tickets_repo_identifier ON tickets(repo_identifier);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_inferred_state ON tickets(inferred_state);
CREATE INDEX IF NOT EXISTS idx_tickets_priority_score ON tickets(priority_score);
CREATE UNIQUE INDEX IF NOT EXISTS idx_tickets_repo_issue ON tickets(repo_identifier, issue_number);

-- Enable Realtime so the dashboard can subscribe to ticket changes (run if using Supabase Realtime):
-- ALTER PUBLICATION supabase_realtime ADD TABLE tickets;
