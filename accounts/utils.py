"""
Utility functions for accounts app
"""


def format_timedelta(td):
    """
    Format timedelta to Korean-friendly string format

    Args:
        td: timedelta object

    Returns:
        str: Formatted string like "2일 5시간 30분" or "1분 미만"
    """
    if not td:
        return ""

    total_seconds = int(td.total_seconds())

    # If negative or zero, return "만료됨"
    if total_seconds <= 0:
        return "만료됨"

    days = td.days
    hours = (total_seconds % 86400) // 3600
    minutes = (total_seconds % 3600) // 60

    parts = []
    if days > 0:
        parts.append(f"{days}일")
    if hours > 0:
        parts.append(f"{hours}시간")
    if minutes > 0:
        parts.append(f"{minutes}분")

    return " ".join(parts) if parts else "1분 미만"
