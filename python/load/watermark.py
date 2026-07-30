"""
-----------------------------------
          Watermark Helper
-----------------------------------
"""

from sqlalchemy import text
from datetime import datetime


def get_watermark(engine, pipeline_name):
    query = text("""
        SELECT last_processed_datetime
        FROM Staging.ETLWatermark
        WHERE pipeline_name = :pipeline_name
    """)

    with engine.connect() as conn:
        result = conn.execute(query, {"pipeline_name": pipeline_name}).fetchone()

    # Fallback protection
    if result is None or result[0] is None:
        return datetime(1900, 1, 1)

    return result[0]


def update_watermark(engine, pipeline_name, new_watermark):
    query = text("""
        UPDATE Staging.ETLWatermark
        SET last_processed_datetime = :new_watermark
        WHERE pipeline_name = :pipeline_name
    """)

    with engine.begin() as conn:
        conn.execute(query, {
            "new_watermark": new_watermark,
            "pipeline_name": pipeline_name
        })