#!/usr/bin/env bash
# Usage: ./scripts/test_api.sh [BASE_URL]
# If .env exists and GITHUB_ACCESS_TOKEN is set, it is sourced and used.

set -e
BASE_URL="${1:-http://localhost:3000}"
OWNER="${OWNER:-rails}"
REPO="${REPO:-rails}"

if [ -f .env ]; then
  set -a
  source .env
  set +a
fi

TOKEN="${GITHUB_ACCESS_TOKEN:-}"
CURL_OPTS=()
[ -n "$TOKEN" ] && CURL_OPTS+=(-H "X-GitHub-Token: $TOKEN")

echo "=== GET /up ==="
curl -s "${BASE_URL}/up"
echo ""

echo "=== GET tickets (from GitHub) ==="
curl -s "${CURL_OPTS[@]}" "${BASE_URL}/api/v1/repos/${OWNER}/${REPO}/tickets?per_page=2" | head -c 500
echo ""

echo "=== GET ticket :number (from GitHub) ==="
curl -s "${CURL_OPTS[@]}" "${BASE_URL}/api/v1/repos/${OWNER}/${REPO}/tickets/1" | head -c 500
echo ""

echo "=== GET analyze ticket ==="
curl -s "${CURL_OPTS[@]}" "${BASE_URL}/api/v1/repos/${OWNER}/${REPO}/tickets/1/analyze" | head -c 800
echo ""

echo "=== GET analyze repo ==="
curl -s "${CURL_OPTS[@]}" "${BASE_URL}/api/v1/repos/${OWNER}/${REPO}/analyze" | head -c 500
echo ""

echo "=== GET stored (from DB) ==="
curl -s "${BASE_URL}/api/v1/repos/${OWNER}/${REPO}/tickets/stored?per_page=2" | head -c 500
echo ""

echo "Done."
