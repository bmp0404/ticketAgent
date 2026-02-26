#!/usr/bin/env bash
# Test API endpoints. Requires GITHUB_ACCESS_TOKEN in .env (loaded by Rails) or set GITHUB_TOKEN when running.
# Usage: ./scripts/test_api.sh [base_url]
#        GITHUB_TOKEN=ghp_xxx ./scripts/test_api.sh

set -e
BASE="${1:-http://localhost:3000}"
OWNER="${2:-bmp0404}"
REPO="${3:-ticketAgent}"

# Load token from .env if present (when run from project root)
if [ -f .env ]; then
  export GITHUB_ACCESS_TOKEN=$(grep ^GITHUB_ACCESS_TOKEN= .env 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'")
fi

TOKEN="${GITHUB_TOKEN:-$GITHUB_ACCESS_TOKEN}"
if [ -z "$TOKEN" ]; then
  echo "Warning: No GITHUB_TOKEN or GITHUB_ACCESS_TOKEN set. API calls may return 401."
  AUTH=""
else
  AUTH="-H X-GitHub-Token:$TOKEN"
fi

echo "=== Testing GitHub Tickets API ==="
echo "Base URL: $BASE"
echo ""

echo "1. Health check (GET /up)"
curl -s -w " -> %{http_code}\n" "$BASE/up"
echo ""

echo "2. List tickets (GET .../tickets?per_page=2)"
curl -s -w "\n-> %{http_code}\n" $AUTH "$BASE/api/v1/repos/$OWNER/$REPO/tickets?state=open&per_page=2" | head -c 500
echo ""
echo ""

echo "3. Get single ticket (GET .../tickets/1)"
curl -s -w "\n-> %{http_code}\n" $AUTH "$BASE/api/v1/repos/$OWNER/$REPO/tickets/1" | head -c 500
echo ""
echo ""

echo "4. Analyze ticket (GET .../tickets/1/analyze)"
curl -s -w "\n-> %{http_code}\n" $AUTH "$BASE/api/v1/repos/$OWNER/$REPO/tickets/1/analyze" | head -c 600
echo ""
echo ""

echo "5. Analyze repo (GET .../analyze?per_page=2)"
curl -s -w "\n-> %{http_code}\n" $AUTH "$BASE/api/v1/repos/$OWNER/$REPO/analyze?per_page=2" | head -c 600
echo ""
echo ""

echo "=== Done ==="
