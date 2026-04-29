"""
-----------------------------------
      Data Validation Layer
-----------------------------------
"""

import pandas as pd

VALID_EVENT_TYPES = {"page_view", "add_to_cart", "checkout"}


def clean_web_events(data, logger=None):
    df = pd.DataFrame(data)

    initial_count = len(df)

    # -------------------------------
    # DROP CRITICAL NULLS
    # -------------------------------
    df = df.dropna(subset=[
        "event_id",
        "customer_id",
        "event_type",
        "event_timestamp"
    ])
    after_nulls = len(df)

    # -------------------------------
    # VALID EVENT TYPES
    # -------------------------------
    df = df[df["event_type"].isin(VALID_EVENT_TYPES)]
    after_event_filter = len(df)

    # -------------------------------
    # REMOVE DUPLICATES
    # -------------------------------
    df = df.drop_duplicates(subset=["event_id"])
    after_dupes = len(df)

    # -------------------------------
    # TIMESTAMP VALIDATION
    # -------------------------------
    df["event_timestamp"] = pd.to_datetime(df["event_timestamp"], errors="coerce")
    df = df.dropna(subset=["event_timestamp"])
    final_count = len(df)

    # -------------------------------
    # LOGGING
    # -------------------------------
    if logger:
        logger.info(f"Initial events: {initial_count}")
        logger.info(f"After null removal: {after_nulls}")
        logger.info(f"After event type filter: {after_event_filter}")
        logger.info(f"After duplicates removal: {after_dupes}")
        logger.info(f"Final events: {final_count}")

    return df