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

## Wiring to the real backend later

- **Stats / tickets**: Replace the `stats`, `featured_tickets`, `recent_completions`, `top_contributors`, and `sprint_labels` methods in `app.rb` with:
  - HTTP calls to a future Python API (e.g. `/api/rank`, `/api/stats`), or
  - Reads from the agent’s SQLite DB (e.g. via a small Ruby library or a thin API from the Python CLI).
- **Config**: The app can already load `../config/default.yaml`; use it for display or to drive API requests.

## Port

Sinatra’s default port is **4567**. To use another port:

```bash
PORT=3000 bundle exec ruby app.rb
```

Then open http://localhost:3000 .
