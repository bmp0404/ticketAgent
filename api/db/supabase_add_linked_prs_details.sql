-- Add linked_prs_details to existing tickets table (Supabase-only).
ALTER TABLE tickets ADD COLUMN IF NOT EXISTS linked_prs_details JSONB DEFAULT '[]' NOT NULL;
