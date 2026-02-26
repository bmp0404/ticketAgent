-- Run in Supabase SQL Editor if your tickets table already exists and you need to add linked PRs tracking.
-- Adds linked_prs_details (PRs that reference this issue, with state/merged/merged_at for status tracking).

ALTER TABLE tickets
  ADD COLUMN IF NOT EXISTS linked_prs_details JSONB DEFAULT '[]' NOT NULL;

COMMENT ON COLUMN tickets.linked_prs_details IS 'Linked pull requests: number, title, state, html_url, merged, merged_at, created_at, updated_at, closed_at, draft';
