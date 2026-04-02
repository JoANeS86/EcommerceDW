"""
-----------------------------------
      Data Validation Layer
-----------------------------------
"""

import pandas as pd


def validate_orders(data, logger=None):
    df = pd.DataFrame(data)

    initial_count = len(df)

    # Remove nulls
    df = df.dropna()

    after_nulls = len(df)

    # Remove duplicates
    df = df.drop_duplicates(subset=["order_id"])

    after_dupes = len(df)

    # Ensure valid amounts
    df = df[df["amount"] > 0]

    final_count = len(df)

    if logger:
        logger.info(f"Initial records: {initial_count}")
        logger.info(f"After removing nulls: {after_nulls}")
        logger.info(f"After removing duplicates: {after_dupes}")
        logger.info(f"Final valid records: {final_count}")

    return df