# Ticket AI Agent – Implementation Plan

This document describes how we will build the system defined in README.md.

---

# System Architecture

Core components:

- ingestion/
- models/
- scoring/
- bounty/
- tracking/
- scheduler/
- cli/
- eval/
- config/

---

# 1. Data Model

## Ticket Schema

Internal Ticket object:

{
  id: string,
  title: string,
  body: string,
  labels: string[],
  assignees: string[],
  milestone: string | null,
  created_at: datetime,
  updated_at: datetime,
  last_activity_at: datetime,
  comment_count: number,
  reactions_count: number,
  linked_prs: string[],
  status: open | closed,
  inferred_state: Backlog | Ready | InProgress | InReview | Done,
  priority_score: number,
  bounty_recommendation: number,
  bounty_confidence: string,
  score_breakdown: object,
  state_history: object[]
}

Database can be:

- SQLite (recommended for semester)
- or Postgres if already available

---

# 2. GitHub Ingestion

## Step 1: GitHub API Integration

- Use REST API
- Fetch issues
- Fetch linked PR references
- Handle pagination
- Store ETag or updated_at for incremental sync

## Step 2: Idempotent Sync

- Upsert tickets by GitHub issue ID
- Update only changed fields
- Record last sync time

---

# 3. Priority Scoring Engine (v0)

## Weighted Scoring Formula

priority_score =

+ impact_weight * impact_score
+ urgency_weight * urgency_score
- effort_weight * effort_score
+ staleness_weight * staleness_score

All weights configurable in config/weights.yaml.

## Explainability

score_breakdown must include:

{
  impact: +32,
  urgency: +15,
  effort: -10,
  staleness: +8
}

---

# 4. Effort Estimation

Phase 1:
- Use effort labels if present (XS/S/M/L)

Phase 2:
- Fallback heuristic:
  - length of description
  - number of acceptance criteria
  - keyword detection

Keep simple for semester.

---

# 5. Bounty Policy

## Mapping

XS → base 50
S → base 100
M → base 250
L → base 500

Final bounty:

base * priority_multiplier

Multiplier derived from normalized priority score.

Confidence:

High:
- Explicit effort label
Medium:
- Heuristic effort
Low:
- Sparse data

---

# 6. Progress Tracking

## State Inference Rules

Closed → Done

If linked PR:
- Draft → In Progress
- Open → In Review
- Merged → Done

If label status:* exists → use it

Else:
- No activity → Backlog
- Recent activity → Ready

Record transitions in state_history.

---

# 7. Idle-Time Reprioritization

staleness_score =

min(
  days_since_last_activity / scaling_factor,
  max_staleness_cap
)

Exclude:
- wontfix
- icebox

Different rule if In Progress:
- Use shorter threshold

Scheduled job:
- Daily or weekly cron runner

---

# 8. CLI Design

Commands:

sync
rank
ticket <id>
simulate
export

Use simple argument parsing.

---

# 9. Evaluation Harness

## Gold Dataset

Create:
- manual_rankings.json

Format:
{
  ticket_id: bucket (High | Medium | Low)
}

## Metric

- Pairwise ranking accuracy
or
- Bucket classification accuracy

Add regression test:
- Fail build if accuracy drops beyond threshold.

---

# 10. Development Timeline

Weeks 1–2:
- Schema + ingestion

Weeks 3–4:
- Scoring engine

Weeks 5–6:
- Bounty system

Weeks 7–8:
- Progress tracking

Weeks 9–10:
- Idle reprioritization + scheduler

Weeks 11–12:
- Evaluation harness

Weeks 13–14:
- Hardening + integration prep

---

# 11. Integration Preparation

Before moving to main codebase:

- Clean API surface
- Separate config layer
- Remove local-only assumptions
- Document extension points

---

# Success Condition

The system is successful if:

- It ranks tickets deterministically.
- It explains its decisions.
- It recommends bounded, configurable bounties.
- It dynamically reprioritizes idle tickets.
- It can be integrated cleanly into a larger marketplace system.

No hidden logic.
No black-box decisions.
Fully testable.
