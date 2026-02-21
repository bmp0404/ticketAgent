"""
Bounty recommendation model (Goal 3).
Value, confidence (low/medium/high), explanation.
"""
from dataclasses import dataclass


@dataclass
class BountyRecommendation:
    value: float
    confidence: str  # "low" | "medium" | "high"
    explanation: str
