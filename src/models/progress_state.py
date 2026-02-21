"""
Progress states for ticket workflow (Goal 4).
"""
from enum import Enum


class ProgressState(str, Enum):
    BACKLOG = "Backlog"
    READY = "Ready"
    IN_PROGRESS = "In Progress"
    IN_REVIEW = "In Review"
    DONE = "Done"
