"""
Ranked ticket output (Goals 2 & 6).
Position, final score, component breakdown, human-readable explanation.
"""
from dataclasses import dataclass
from typing import Any


@dataclass
class RankedTicket:
    position: int
    ticket_id: str
    final_score: float
    score_breakdown: dict[str, Any]
    explanation: str
