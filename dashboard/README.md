# Ticket Agent Dashboard (Test Frontend)

A minimal test frontend for the Ticket AI Agent, using **Embedded Ruby (ERB)** and a dashboard structure similar to the AMOS Build UI. Built with **Sinatra** so you get Rails-like ERB templates without a full Rails stack.

## What’s included

- **ERB views**: `views/layout.erb`, `views/index.erb`, `views/bounties.erb`, `views/leaderboard.erb`, `views/ticket.erb`
- **Dashboard**: Hero, stats cards, top-priority tickets, recent completions, top contributors, sprint labels
- **Mock data**: In-memory data in `app.rb` so the UI works before the Python backend is ready. You can later replace this with API calls or DB reads.

## Prerequisites

- **Ruby 3.x** (3.0+). Check: `ruby -v`
- **Bundler**: `gem install bundler` if needed

## Setup (local)

1. **Go to the dashboard directory**
   ```bash
   cd ticketAgent/dashboard
   ```
   (Or from repo root: `cd ticketAgent/ticketAgent/dashboard`.)

2. **Install dependencies**
   ```bash
   bundle install
   ```
   If you get permission errors (e.g. writing to system Ruby), install gems into the project instead:
   ```bash
   bundle install --path vendor/bundle
   ```
   Then run the app with: `bundle exec ruby app.rb` (same as below).

3. **Start the server**
   ```bash
   bundle exec ruby app.rb
   ```
   You should see something like:
   ```
   [2025-02-22 12:00:00] INFO  WEBrick 1.x.x
   [2025-02-22 12:00:00] INFO  ruby 3.x.x
   == Sinatra (v3.x.x) has taken the stage on 4567 for development
   ```

4. **Open in browser**
   - **Dashboard**: http://localhost:4567  
   - **Bounties**: http://localhost:4567/bounties  
   - **Leaderboard**: http://localhost:4567/leaderboard  
   - **Ticket detail**: http://localhost:4567/ticket/42  

## Optional: live reload

To auto-restart the server when you change `app.rb` or views:

```bash
bundle exec rerun -- ruby app.rb
```

(Requires the `rerun` gem from the `development` group; it’s in the Gemfile.)

## Project layout

```
dashboard/
├── README.md           # This file
├── Gemfile             # Ruby deps (Sinatra, erubi, rerun)
├── app.rb              # Sinatra app, routes, helpers, mock data
└── views/
    ├── layout.erb      # Wrapper: nav, Bootstrap 5, dark theme
    ├── index.erb       # Main dashboard (stats + featured tickets + sidebar)
    ├── bounties.erb    # All bounties / filtered by sprint
    ├── leaderboard.erb # Top contributors
    └── ticket.erb      # Single ticket detail
```

## Wiring to the Tickets API and Supabase Realtime

The dashboard can load tickets from the **GitHub Tickets API** (Rails app in `../api`) and get **realtime updates** via Supabase.

1. **Copy env**
   ```bash
   cp .env.example .env
   ```

2. **Optional – load tickets from API**
   - In `.env` set:
     - `TICKETS_API_URL=http://localhost:3000` (Rails API base URL)
     - `REPO_IDENTIFIER=owner/repo` (e.g. `rails/rails`)
   - Stats and featured tickets will come from the API’s stored tickets (Supabase). Run a sync from the API first (e.g. `rails tickets:sync` or `POST /api/v1/repos/owner/repo/sync`).

3. **Optional – realtime updates**
   - In `.env` set:
     - `SUPABASE_URL=https://xxxx.supabase.co`
     - `SUPABASE_ANON_KEY=eyJ...`
   - In Supabase, enable Realtime for the `tickets` table:
     ```sql
     ALTER PUBLICATION supabase_realtime ADD TABLE tickets;
     ```
   - When the API (or a GitHub webhook) updates tickets in Supabase, the dashboard will auto-refresh.

4. **GitHub webhook (API)**
   - Point GitHub repo webhooks (issues, issue_comment) at `POST /api/v1/webhooks/github`. The API will upsert tickets into Supabase; the dashboard’s Supabase Realtime subscription will then show updates.

## Legacy / mock data

- **Stats / tickets**: If `TICKETS_API_URL` and `REPO_IDENTIFIER` are not set, the dashboard uses in-memory mock data.
- **Config**: The app can load `../config/default.yaml` for display or to drive API requests.

## Port

Sinatra’s default port is **4567**. To use another port:

```bash
PORT=3000 bundle exec ruby app.rb
```

Then open http://localhost:3000 .
