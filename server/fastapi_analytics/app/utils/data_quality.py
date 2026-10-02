"""Single place that turns a TickerScore row's data_quality columns into the
shape query responses hand out.

Why it lives here: the NULL -> 'full' conversion has to be identical on every
read path. charts.py and scores.py both expose it, and a later S2 (stale
detection) will filter on it. One definition, no drift.
"""
from typing import Optional


def data_quality_dict(score_obj) -> Optional[dict]:
    """Build the data_quality payload for a TickerScore row.

    Returns None when there is no score row for the date -- the field is then
    omitted rather than carrying a made-up default.

    NULL columns (rows written before the 2026-10-02 migration) read as
    `full` / `ai_available = True`, so clients never branch on NULL.
    """
    if score_obj is None:
        return None

    mode = score_obj.analysis_mode or 'full'
    available = score_obj.ai_available
    return {
        'analysis_mode': mode,
        'history_days': score_obj.history_days,
        'ai_available': available if available is not None else (mode == 'full'),
    }
