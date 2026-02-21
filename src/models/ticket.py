"""
Internal Ticket model (Goal 1).
Fields: id, title, body, labels, assignees, milestone, created_at, updated_at,
last_activity_at, comment_count, reactions_count, linked_prs, status,
optional inferred_state, score_breakdown, state_history.
"""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from .progress_state import ProgressState


@dataclass
class Ticket:
    id: str
    title: str
    body: str
    labels: list[str]
    assignees: list[str]
    milestone: str | None
    created_at: datetime
    updated_at: datetime
    last_activity_at: datetime
    comment_count: int
    reactions_count: int
    linked_prs: list[str]
    status: str  # "open" | "closed"
    inferred_state: ProgressState | None = None
    score_breakdown: dict[str, Any] = field(default_factory=dict)
    state_history: list[dict[str, Any]] = field(default_factory=list)
