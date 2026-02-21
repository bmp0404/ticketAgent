# Ticket AI Agent – File Structure

This document defines the recommended file structure. It maps each semester goal to concrete paths so that a new developer can navigate the repo quickly.

---

## Top-level layout

```
ticketAgent/
├── README.md
├── implementation.md
├── docs/
│   └── FILE_STRUCTURE.md          # this file
├── .env.example                   # GITHUB_TOKEN, optional DB URL
├── config/
│   └── default.yaml               # weights, bounty bounds, policies (Goal 7)
├── src/
│   ├── __init__.py
│   ├── cli.py                     # CLI entry: sync, rank, ticket, simulate, export (Goal 9)
│   ├── models/                    # core data shapes
│   ├── ingestion/                 # Goal 1: GitHub sync
│   ├── storage/                   # persistence
│   ├── scoring/                   # Goal 2: prioritization engine
│   ├── bounty/                    # Goal 3: bounty recommendations
│   ├── tracking/                  # Goal 4: progress & status
│   ├── scheduler/                 # Goal 5: idle-time reprioritization
│   ├── evaluation/                # Goal 8: harness + gold dataset
│   └── observability/             # Goal 10: logging, snapshots, audit
├── tests/
│   ├── unit/
│   ├── integration/
│   └── evaluation/                # regression tests for scoring
├── gold/                          # Goal 8: human-ranked gold dataset (~30 tickets)
└── requirements.txt               # or package.json
```

Optional later:

- `web/` or `dashboard/` – minimal web UI (Goal 9 optional)
- `migrations/` under `storage/` if you add schema migrations

---

## Goal → path mapping

| Goal | Primary paths |
|------|----------------|
| 1. GitHub Issue Ingestion | `src/ingestion/`, `src/storage/`, `src/models/` |
| 2. Deterministic Prioritization | `src/scoring/`, `config/default.yaml` |
| 3. Bounty Recommendation | `src/bounty/`, `config/default.yaml` |
| 4. Progress & Status Tracking | `src/tracking/`, `src/models/` |
| 5. Idle-Time Reprioritization | `src/scheduler/`, `src/scoring/` |
| 6. Ranking Explainability | `src/scoring/` (breakdown + explainer), CLI debug mode |
| 7. Configuration & Tuning | `config/`, `src/cli.py` (simulate) |
| 8. Evaluation Harness | `src/evaluation/`, `gold/`, `tests/evaluation/` |
| 9. Interface (CLI) | `src/cli.py` |
| 10. Logging & Observability | `src/observability/` |

---

## `config/`

- **default.yaml**  
  Single place for:
  - Prioritization weights (impact, urgency, effort, staleness)
  - Bounty min/max and policy (e.g. base by size, multiplier)
  - Idle reprioritization (staleness cap, scaling factor, exclusions: wontfix, icebox)
  - Any feature flags or thresholds

No code edits needed to tune behavior; `simulate` uses this (or an override) to show impact of weight changes.

---

## `src/`

### `cli.py`

- Parses: `sync`, `rank`, `ticket <id>`, `simulate`, `export`.
- Loads config; delegates to ingestion, scoring, bounty, tracking, scheduler, observability.
- Debug mode: prints full scoring inputs (Goal 6).

### `models/`

- **ticket.py** – Internal `Ticket` (id, title, body, labels, assignees, milestone, created_at, updated_at, last_activity_at, comment_count, reactions_count, linked_prs, status, optional inferred_state, score_breakdown, state_history).
- **ranking.py** – Ranked ticket + position + score + breakdown + explanation.
- **bounty.py** – Bounty recommendation + confidence + explanation.
- **progress_state.py** – Enum/constants: Backlog, Ready, InProgress, InReview, Done.

### `ingestion/` (Goal 1)

- **github_client.py** – REST API: list issues, pagination, PR refs, ETag/updated_at for incremental sync.
- **normalizer.py** – Maps GitHub issue → internal `Ticket`.
- **sync.py** – Idempotent sync: upsert by issue id, incremental updates, no duplicates. Calls storage.

### `storage/`

- **database.py** – Abstract persistence (SQLite for semester): tickets, state_history, last sync metadata. Used by ingestion, tracking, observability.
- Optional: **migrations/** if you version schema.

### `scoring/` (Goals 2 & 6)

- **engine.py** – Computes priority score from impact, urgency, effort, staleness (weights from config). Returns score + component breakdown.
- **signals.py** – Impact (labels, reactions, milestone), urgency (bug/security/blocking), effort (labels or heuristic), aging/staleness.
- **explainer.py** – Builds human-readable explanation and numeric breakdown for every rank/bounty (Goal 6).

### `bounty/` (Goal 3)

- **recommender.py** – Uses effort, priority score, complexity; applies config policy; returns value, confidence (low/medium/high), explanation.
- **policy.py** – Reads min/max and mapping from config (e.g. XS/S/M/L base, priority multiplier).

### `tracking/` (Goal 4)

- **inferrer.py** – Infers state (Backlog | Ready | InProgress | InReview | Done) from labels, linked PRs, activity, closed status.
- **history.py** – Appends state transitions; stores in DB (state_history / audit trail).

### `scheduler/` (Goal 5)

- **idle_bump.py** – Staleness score with cap; excludes wontfix/icebox; different handling for in-progress. Calls scoring engine; writes rank movements to observability.

### `evaluation/` (Goal 8)

- **harness.py** – Loads gold dataset; runs prioritization (and optionally bounty); computes metric.
- **metrics.py** – Ranking comparison (e.g. pairwise accuracy or bucket accuracy).
- **gold_loader.py** – Loads `gold/` data (e.g. ticket_id → bucket or rank).

### `observability/` (Goal 10)

- **logging.py** – Structured logs for each run (sync, rank, reprioritization).
- **snapshots.py** – Persist ranking snapshots over time (e.g. timestamped rankings).
- **audit.py** – Record rank movements and state transitions (what changed, why, when).

---

## `tests/`

- **unit/** – Unit tests for scoring, bounty, progress inference, normalizer, sync logic.
- **integration/** – Tests that hit DB and/or GitHub (e.g. sync idempotency, no duplicates).
- **evaluation/** – Regression tests: run harness against gold; fail if metric drops below threshold (Goal 8).

---

## `gold/`

- **manual_rankings.json** (or similar) – ~30 tickets with human-defined rank/bucket (e.g. `ticket_id → High|Medium|Low` or full ordering). Used by evaluation harness and regression tests.

---

## Quick start (Goal 9)

A new developer should:

1. Clone repo.
2. Copy `.env.example` → `.env`, set `GITHUB_TOKEN`.
3. Install deps (`pip install -r requirements.txt` or `npm install`).
4. Run `sync` then `rank` and see ranked backlog with explanations in under 5 minutes.

Keeping entry point in `src/cli.py` and config in `config/default.yaml` supports this.

---

## Optional: minimal web dashboard

If you add a minimal UI:

- **web/** or **dashboard/** at repo root.
- Thin server that reads from the same storage and config; displays ranked list, ticket detail, and (if desired) simple simulate view. Keep all scoring/bounty logic in `src/` so CLI and web share one implementation.
