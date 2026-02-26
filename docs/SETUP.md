# Local Setup Guide: Ruby on Rails

This guide walks you through installing Ruby and Rails and running this project locally.

---

## Prerequisites

- A terminal (Terminal.app on macOS, WSL or Git Bash on Windows)
- [Git](https://git-scm.com/) installed
- A [GitHub Personal Access Token](https://github.com/settings/tokens) (for the API; create after setup if needed)

---

## 1. Install Ruby

This project targets **Ruby 3.2+**. Use one of the options below.

### Option A: rbenv (recommended on macOS/Linux)

[rbenv](https://github.com/rbenv/rbenv) lets you install and switch Ruby versions per project.

**macOS (Homebrew):**

```bash
brew install rbenv ruby-build
rbenv init
# Follow the printed instructions (add eval "$(rbenv init -)" to your shell config)
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt update
sudo apt install rbenv ruby-build
rbenv init
# Add eval "$(rbenv init -)" to ~/.bashrc or ~/.zshrc
```

**Install Ruby 3.2 and use it in this project:**

```bash
rbenv install 3.2.2   # or latest 3.2.x
cd /path/to/githubAPIProject
rbenv local 3.2.2
```

**Verify:**

```bash
ruby -v   # Should show ruby 3.2.x
which ruby
```

### Option B: Ruby Version Manager (rvm)

```bash
# Install rvm: https://rvm.io/
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm

rvm install 3.2.2
rvm use 3.2.2
ruby -v
```

### Option C: System Ruby (Linux)

Some Linux distros ship Ruby. Prefer 3.2+ if available:

```bash
# Ubuntu 22.04+
sudo apt install ruby-full

ruby -v
```

If the version is old, use rbenv or rvm instead.

### Option D: Windows

- Use [RubyInstaller](https://rubyinstaller.org/) (pick Ruby 3.2+), or
- Use [WSL2](https://docs.microsoft.com/en-us/windows/wsl/) and follow the Linux instructions above.

---

## 2. Install Bundler and Rails

[Bundler](https://bundler.io/) manages gem dependencies. Rails will be installed via the project’s Gemfile.

**Install Bundler (if not already present):**

```bash
gem install bundler
bundler -v
```

You do **not** need to run `gem install rails`; the project’s `bundle install` will install the correct Rails version.

---

## 3. Clone and Enter the Project

If you haven’t already:

```bash
git clone <your-repo-url> githubAPIProject
cd githubAPIProject
```

If the project is already on your machine, just `cd` into it.

---

## 4. Install Project Dependencies

From the project root:

```bash
bundle install
```

This installs Rails, Puma, Octokit, dotenv, and other gems listed in the Gemfile. Resolving and installing may take a minute.

**If you see permission errors:** avoid `sudo`. Use rbenv/rvm so gems install in your user directory.

**If you see “Ruby version” errors:** ensure you’re using Ruby 3.2+ (`ruby -v`) and, with rbenv, run `rbenv local 3.2.2` (or your 3.2.x version) in the project directory.

---

## 5. Configure the Application

**Create your environment file:**

```bash
cp .env.example .env
```

**Edit `.env` and set your GitHub token:**

```bash
# Open in your editor, e.g.:
nano .env
# or
code .env
```

Set:

```env
GITHUB_ACCESS_TOKEN=ghp_your_personal_access_token_here
```

- Create a token at: [GitHub → Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
- For **public repos only**: scope `public_repo` is enough.
- For **private repos**: use the `repo` scope.

Do not commit `.env` or share your token; it’s listed in `.gitignore`.

---

## 6. Run the Server Locally

From the project root:

```bash
bundle exec rails server
```

Or the shorter form:

```bash
rails server
# or
rails s
```

You should see something like:

```
=> Booting Puma
=> Rails 7.x.x application starting in development
* Listening on http://127.0.0.1:3000
* Listening on http://[::1]:3000
Use Ctrl+C to stop the server
```

**Base URL:** `http://localhost:3000`

**Quick checks:**

- In the browser: [http://localhost:3000/up](http://localhost:3000/up) — should return “OK”.
- List routes: in another terminal, `bundle exec rails routes`.

---

## 7. Try an API Request

With the server running, in a **new terminal**:

```bash
# Replace YOUR_TOKEN with your GitHub token (or rely on .env and omit the header if you prefer)
curl -H "X-GitHub-Token: YOUR_TOKEN" \
  "http://localhost:3000/api/v1/repos/rails/rails/tickets?state=open&per_page=3"
```

You should get JSON listing a few open issues from the Rails repo.

---

## Optional: Change Port or Environment

**Custom port (e.g. 4000):**

```bash
rails server -p 4000
# API base: http://localhost:4000
```

**Run in “production” mode locally (not typical for day-to-day dev):**

```bash
RAILS_ENV=production rails server
```

---

## Troubleshooting

| Issue | What to try |
|-------|-------------|
| `ruby: command not found` | Install Ruby (Step 1). Restart the terminal; ensure rbenv/rvm is in your PATH. |
| `Bundler::GemNotFound` or version errors | Run `bundle install` again. If Ruby version is wrong, set it with `rbenv local 3.2.2` (or your 3.2.x). |
| `Rails is not currently installed` | Run `bundle install` from the project root; don’t rely on a global `gem install rails`. |
| `Unauthorized` or 401 from API | Check `GITHUB_ACCESS_TOKEN` in `.env`. Ensure the token has `repo` or `public_repo` and hasn’t expired. |
| `Address already in use` | Another process is using port 3000. Stop it or use `rails server -p 3001`. |
| SSL/certificate errors | Update system certs or Ruby/OpenSSL. With rbenv: `rbenv install 3.2.2` again with latest openssl. |

---

## Summary

1. Install **Ruby 3.2+** (e.g. with rbenv).
2. Install **Bundler**: `gem install bundler`.
3. **Clone** the repo and `cd` into it.
4. Run **`bundle install`**.
5. Copy **`.env.example`** to **`.env`** and set **`GITHUB_ACCESS_TOKEN`**.
6. Run **`bundle exec rails server`** and use **http://localhost:3000**.

For API usage and endpoints, see the main [README](../README.md).
