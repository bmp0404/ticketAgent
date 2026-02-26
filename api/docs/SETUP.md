# GitHub Tickets API – Setup

## Prerequisites

- Ruby 3.2+ (e.g. via rbenv: `rbenv install 3.2`, `rbenv local 3.2`)
- Bundler: `gem install bundler`
- GitHub personal access token (repo scope)
- Supabase project with Postgres

## Steps

1. **Clone and enter API**
   ```bash
   cd api
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Environment**
   - Copy `.env.example` to `.env`
   - Set `GITHUB_ACCESS_TOKEN` to your GitHub token
   - Set `DATABASE_URL` to your Supabase **Session pooler** connection string:
     - In Supabase: Project Settings → Database → Connection string → **Session pooler** (URI)
     - Host will look like `aws-0-us-east-1.pooler.supabase.com`, port `5432` or `6543`
     - Replace `[YOUR-PASSWORD]` with your database password

4. **Database**
   - Option A: Run Rails migrations: `bundle exec rails db:migrate`
   - Option B: Run `db/supabase_tickets_schema.sql` in Supabase SQL Editor
   - If the table already exists with UUID `id`, run the migration that changes `id` to TEXT, or use `db/supabase_add_linked_prs_details.sql` if only adding the column

5. **Start server**
   ```bash
   bundle exec rails server
   ```
   Server runs at `http://localhost:3000` (or `PORT` from `.env`).

6. **Test**
   - Health: `curl http://localhost:3000/up`
   - List tickets (replace owner/repo): `curl -H "X-GitHub-Token: YOUR_TOKEN" "http://localhost:3000/api/v1/repos/owner/repo/tickets"`
   - Or use `scripts/test_api.sh` (source `.env` for token): `./scripts/test_api.sh http://localhost:3000`

## GitHub webhook (optional)

1. In your GitHub repo: Settings → Webhooks → Add webhook
2. Payload URL: `https://your-api-host/api/v1/webhooks/github`
3. Content type: `application/json`
4. Events: **issues**, **issue_comment**
5. Save. On issue open/edit/close or new comment, the API will upsert that ticket into Supabase; the dashboard can use Supabase Realtime to show live updates.
