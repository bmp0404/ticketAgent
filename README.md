# Ticket AI Agent (GitHub Issues Wrapper)

This repository contains the standalone build of our Ticket AI Agent.

The agent wraps GitHub Issues and provides:

- Intelligent ticket prioritization
- Bounty/prize recommendations
- Progress tracking
- Idle-time reprioritization
- Ranking explainability

This repo is intentionally separate from the main codebase.  
Integration will happen after core capabilities are stable.

---

# Semester Concrete Goals

By the end of the semester, the agent must reliably support the following capabilities.

---

## 1. GitHub Issue Ingestion (Foundational)

The system must:

- Sync GitHub Issues from a repository
- Normalize issues into internal Ticket objects
- Store tickets in a persistent database
- Perform idempotent sync (no duplicates)
- Track updates incrementally (not full re-ingestion each time)

Each internal Ticket must include:

- id
- title
- body
- labels
- assignees
- milestone
- created_at
- updated_at
- last_activity_at
- comment_count
- reactions_count
- linked PR references
- open/closed status

Definition of Done:
- Running `sync` updates the internal state without duplicating tickets.
- Ticket state reflects GitHub accurately.

---

## 2. Deterministic Prioritization Engine

The agent must:

- Compute a priority score for each ticket
- Rank all open tickets
- Provide a breakdown explaining the score

Priority inputs must include:

- Impact signals (labels, reactions, milestone presence)
- Effort signals (label-based or estimated)
- Urgency signals (bug, security, blocking)
- Aging/staleness factor

Every ranked ticket must display:

- Final score
- Component score breakdown
- Ranking position

Definition of Done:
- `rank` command outputs a sorted list with explanations.
- Weight changes in config alter rankings predictably.
- No opaque scoring logic.

---

## 3. Bounty Recommendation Engine

The agent must:

- Recommend a bounty/prize value per ticket
- Stay within configurable min/max bounds
- Provide a confidence score
- Explain the recommendation

Inputs must include:

- Estimated effort
- Priority score
- Complexity modifiers

Definition of Done:
- Each ranked ticket includes:
  - recommended bounty
  - confidence (low/medium/high)
  - explanation
- Bounty policy configurable without changing core code.

---

## 4. Progress & Status Tracking

The agent must infer and track ticket progress.

Supported states:

- Backlog
- Ready
- In Progress
- In Review
- Done

State inference must use:

1. Explicit status labels
2. Linked PR presence and merge status
3. Activity heuristics (comments, updates)
4. Issue closed status

The system must:

- Log state changes over time
- Maintain a history/audit trail

Definition of Done:
- Each ticket displays current state.
- State transitions are stored.
- Closed issues correctly marked Done.

---

## 5. Idle-Time Dynamic Reprioritization

The agent must:

- Increase priority for tickets that have been idle
- Apply capped staleness bump
- Exclude tickets labeled wontfix/icebox
- Handle in-progress staleness differently

Definition of Done:
- Running scheduled reprioritization changes rankings appropriately.
- Rank movement is logged and explainable.

---

## 6. Ranking Explainability (Mandatory)

The agent must never output a rank or bounty without:

- Clear numeric breakdown
- Reasoning components
- Human-readable explanation

Definition of Done:
- Every ticket has traceable reasoning.
- Debug mode prints full scoring inputs.

---

## 7. Configuration & Tuning System

The system must:

- Centralize weights and policies in a config file
- Support tuning without code edits
- Allow simulation of weight changes

Definition of Done:
- Changing config changes behavior deterministically.
- `simulate` mode shows impact of weight changes.

---

## 8. Evaluation Harness

We must ship a measurable evaluation system.

It must include:

- A small human-ranked gold dataset (~30 tickets)
- A ranking comparison metric
- Regression testing for scoring changes

Definition of Done:
- We can measure whether prioritization improved.
- Scoring changes cannot silently degrade performance.

---

## 9. Interface (CLI Required)

At minimum, the agent must support:

- `sync`
- `rank`
- `ticket <id>`
- `simulate`
- `export`

Optional:
- Minimal web dashboard

Definition of Done:
- A new developer can clone repo, configure GitHub token, and see ranked backlog in under 5 minutes.

---

## 10. Logging & Observability

The system must:

- Log every agent run
- Store ranking snapshots over time
- Record rank movements
- Record state transitions

Definition of Done:
- We can answer:
  - What changed?
  - Why did it change?
  - When did it change?

---

# End-of-Semester Demo Criteria

The demo must show:

1. Syncing GitHub Issues into the agent
2. Ranked backlog with explanations
3. Bounty recommendations with rationale
4. Progress state inference
5. Idle-time reprioritization in action
6. Evaluation results against gold dataset

If all of the above works reliably, the semester goal is achieved.
