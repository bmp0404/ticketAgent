# GitHub Tickets API

A Ruby on Rails REST API to **retrieve and analyze** GitHub Issues (tickets) from any repository using the [GitHub API](https://docs.github.com/en/rest). Inspired by the [ticketAgent](https://github.com/bmp0404/ticketAgent) project.

## Local setup (Ruby & Rails)

**New to Ruby or Rails?** See **[docs/SETUP.md](docs/SETUP.md)** for:

- Installing Ruby 3.2+ (rbenv, rvm, system, Windows)
- Installing Bundler and project dependencies
- Configuring `.env` and your GitHub token
- Running the server locally and testing the API
- Troubleshooting common issues

## Quick start (if Ruby & Rails are already installed)

1. **Clone and install dependencies**

   ```bash
   bundle install
   ```

2. **Configure GitHub token**

   Copy the example env file and add your [GitHub Personal Access Token](https://github.com/settings/tokens) (scopes: `repo` for private repos, or `public_repo` for public only):

   ```bash
   cp .env.example .env
   # Edit .env and set GITHUB_ACCESS_TOKEN=ghp_...
   ```

3. **Configure Supabase (optional, for storing tickets)**

   Set `DATABASE_URL` in `.env` to your Supabase Postgres connection string. **Use the Session Pooler** (not the direct connection): Supabase’s direct connection is often not IPv4 compatible, which can cause "could not translate host name" or connection failures. In the Dashboard → **Database** (or **Project Settings → Database**) → under **Connection string**, choose **Session pooler** and copy the URI. Replace `[YOUR-PASSWORD]` with your database password and put it in `.env`. Then run migrations:

   ```bash
   bundle exec rails db:migrate
   ```

   Or create the table in Supabase SQL Editor using `db/supabase_tickets_schema.sql`.

4. **Start the server**

   ```bash
   bundle exec rails server
   ```

   API base URL: `http://localhost:3000`

## API Endpoints

All routes are under `/api/v1`. Use either:

- **Header:** `X-GitHub-Token: your_token` (overrides `.env`), or  
- **Env:** `GITHUB_ACCESS_TOKEN` in `.env`

### 1. List tickets (issues)

```http
GET /api/v1/repos/:owner/:repo/tickets
```

**Query params (optional):**

| Param      | Default  | Description                    |
|-----------|----------|--------------------------------|
| `state`   | `open`   | `open`, `closed`, or `all`     |
| `sort`    | `updated`| `created`, `updated`, `comments` |
| `direction` | `desc` | `asc` or `desc`                |
| `per_page`| `30`     | 1–100                          |
| `page`    | `1`      | Page number                    |
| `labels`  | —        | Comma-separated label names    |

**Example:**

```bash
curl -H "X-GitHub-Token: YOUR_TOKEN" \
  "http://localhost:3000/api/v1/repos/bmp0404/ticketAgent/tickets?state=open&per_page=10"
```

### 2. Get a single ticket

```http
GET /api/v1/repos/:owner/:repo/tickets/:number
```

**Example:**

```bash
curl -H "X-GitHub-Token: YOUR_TOKEN" \
  "http://localhost:3000/api/v1/repos/bmp0404/ticketAgent/tickets/1"
```

### 3. Analyze a single ticket

```http
GET /api/v1/repos/:owner/:repo/tickets/:number/analyze
```

Returns the ticket plus analysis: comment count, labels, assignees, age, urgency signals (e.g. bug, security), and a short summary.

**Example:**

```bash
curl -H "X-GitHub-Token: YOUR_TOKEN" \
  "http://localhost:3000/api/v1/repos/bmp0404/ticketAgent/tickets/1/analyze"
```

### 4. Analyze all tickets in a repo

```http
GET /api/v1/repos/:owner/:repo/analyze
```

**Query params (optional):** `state` (default `open`), `per_page` (default `50`).

**Example:**

```bash
curl -H "X-GitHub-Token: YOUR_TOKEN" \
  "http://localhost:3000/api/v1/repos/bmp0404/ticketAgent/analyze"
```

### 5. List tickets from Supabase (stored)

```http
GET /api/v1/repos/:owner/:repo/tickets/stored
```

Returns tickets previously synced to Supabase. No GitHub token required. Optional query params: `status`, `inferred_state`, `per_page`.

### 6. Sync repo to Supabase

```http
POST /api/v1/repos/:owner/:repo/sync
```

Fetches GitHub issues for the repo, finds linked pull requests (via issue timeline), computes priority/bounty/inferred state, and upserts into the `tickets` table. Each ticket includes **linked PRs with status** (state, merged, merged_at, etc.) for status tracking. Optional body/params: `state` (default `all`), `per_page` (default `100`).

**Example:**

```bash
curl -X POST -H "X-GitHub-Token: YOUR_TOKEN" \
  "http://localhost:3000/api/v1/repos/bmp0404/ticketAgent/sync"
```

**Rake task:** `rails tickets:sync[owner,repo]` (e.g. `rails tickets:sync[bmp0404,ticketAgent]`).

## Supabase ticket schema

Stored tickets match this shape (see `db/supabase_tickets_schema.sql` and `app/models/ticket.rb`):

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Primary key, e.g. `owner/repo#123` |
| `title` | string | Issue title |
| `body` | text | Issue body |
| `labels` | string[] | Label names |
| `assignees` | string[] | Assignee logins |
| `milestone` | string \| null | Milestone title |
| `created_at`, `updated_at`, `last_activity_at` | datetime | From GitHub / comments |
| `comment_count`, `reactions_count` | number | Counts |
| `linked_prs` | string[] | PR refs parsed from body |
| `linked_prs_details` | object[] | Linked PRs with status: `number`, `title`, `state`, `html_url`, `merged`, `merged_at`, `created_at`, `updated_at`, `closed_at`, `draft` |
| `status` | `open` \| `closed` | Issue state |
| `inferred_state` | `Backlog` \| `Ready` \| `InProgress` \| `InReview` \| `Done` | Inferred from labels/heuristics |
| `priority_score` | number | Computed score |
| `bounty_recommendation`, `bounty_confidence` | number, string | Bounty suggestion |
| `score_breakdown` | object | Component scores (impact, effort, urgency, etc.) |
| `state_history` | object[] | Audit trail (future) |

**If your Supabase `tickets` table already exists** and you want linked PR tracking, run `db/supabase_add_linked_prs_details.sql` in the Supabase SQL Editor to add the `linked_prs_details` column.

## Response shape (ticket)

- `number`, `title`, `state`, `html_url`
- `created_at`, `updated_at`, `closed_at`
- `labels` (name, color), `assignees`, `user`
- `comments_count`, `milestone` (if any)
- `body` on show/analyze

Analyze endpoints add an `analysis` object with `comment_count`, `label_names`, `age_days`, `urgency_signals`, `summary`, etc.

## Tech stack

- **Ruby 3.2**, **Rails 7.1** (API only)
- **[Octokit](https://github.com/octokit/octokit.rb)** for the GitHub API
- **Puma** as the app server

## License

MIT
