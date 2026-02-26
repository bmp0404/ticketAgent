# GitHub Tickets API

Rails 7 API-only app that fetches GitHub Issues, analyzes them (priority, bounty, inferred state), stores them in Supabase (PostgreSQL), and supports creating issues and syncing to Supabase.

## Stack

- Ruby 3.2+, Rails 7.x (API-only), Octokit, Puma, dotenv-rails, pg (PostgreSQL/Supabase).

## Quick start

1. `cd api && bundle install`
2. Copy `.env.example` to `.env`. Set `GITHUB_ACCESS_TOKEN` and `DATABASE_URL`.
3. **DATABASE_URL**: Use Supabase **Session pooler** URI (not Direct). Session pooler uses host like `aws-0-<region>.pooler.supabase.com:5432` or `:6543`. Direct connection (`db.xxx.supabase.co`) can fail on IPv4-only networks.
4. Create the `tickets` table: run `rails db:migrate` or execute `db/supabase_tickets_schema.sql` in Supabase SQL Editor.
5. If your existing Supabase table has `id` as UUID, run the migration that changes `id` to TEXT, or apply the schema from scratch.
6. Start the server: `rails server` (or `bundle exec puma -C config/puma.rb`).

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/up` | Health check |
| GET | `/api/v1/repos/:owner/:repo/tickets` | List issues from GitHub (query: state, sort, direction, per_page, page, labels) |
| POST | `/api/v1/repos/:owner/:repo/tickets` | Create GitHub issue (body: title, body?, sync?). If sync=true, syncs to Supabase |
| GET | `/api/v1/repos/:owner/:repo/tickets/stored` | List tickets from DB (query: status, inferred_state, per_page) |
| POST | `/api/v1/repos/:owner/:repo/sync` | Sync GitHub issues to Supabase (params: state, per_page) |
| GET | `/api/v1/repos/:owner/:repo/tickets/:number` | Show single issue |
| GET | `/api/v1/repos/:owner/:repo/tickets/:number/analyze` | Issue + comments + analysis |
| GET | `/api/v1/repos/:owner/:repo/analyze` | Repo-level analysis sample |
| POST | `/api/v1/webhooks/github` | GitHub webhook (issues, issue_comment) – syncs to Supabase |

Use header `X-GitHub-Token` to override the default GitHub token for API requests.

## Supabase ticket schema

| Column | Type | Notes |
|--------|------|-------|
| id | TEXT PK | Format `owner/repo#issue_number` |
| repo_identifier | TEXT | `owner/repo` |
| issue_number | INTEGER | |
| title | TEXT | |
| body | TEXT | nullable |
| labels | TEXT[] | default [] |
| assignees | TEXT[] | default [] |
| milestone | TEXT | nullable |
| created_at, updated_at, last_activity_at | TIMESTAMPTZ | |
| comment_count, reactions_count | INTEGER | default 0 |
| linked_prs | TEXT[] | e.g. ["#12"] |
| linked_prs_details | JSONB | default [] |
| status | TEXT | open \| closed |
| inferred_state | TEXT | Backlog \| Ready \| InProgress \| InReview \| Done |
| priority_score | DECIMAL(10,4) | default 0 |
| bounty_recommendation | DECIMAL(10,2) | default 0 |
| bounty_confidence | TEXT | low \| medium \| high, nullable |
| score_breakdown | JSONB | default {} |
| state_history | JSONB | default [] |

Session pooler is required for reliable IPv4 connectivity. If the table was created in Supabase UI with different types (e.g. UUID id), run `db/supabase_add_linked_prs_details.sql` and/or the Rails migrations for `repo_identifier`, `issue_number`, and changing `id` to TEXT.

## Rake tasks

- `rails tickets:sync[owner,repo]` – sync all issues to Supabase (use `OWNER=... REPO=...` if args have special chars).
- `rails tickets:create[owner,repo,title,body]` – create GitHub issue and sync (use `OWNER`, `REPO`, `TITLE`, `BODY` from ENV if needed).

## Docs

See `docs/SETUP.md` for full setup (Ruby, Bundler, DATABASE_URL, testing with curl).
