"""
-----------------------------------
      Data Validation Layer
-----------------------------------
"""

import pandas as pd


def validate_payments(data, logger=None):
    df = pd.DataFrame(data)

    initial_count = len(df)

    # -------------------------------
    # REMOVE NULLS
    # -------------------------------
    df = df.dropna(subset=[
        "payment_id",
        "order_id",
        "payment_date",
        "amount",
        "payment_method",
        "status"
    ])

    after_nulls = len(df)

    # -------------------------------
    # REMOVE DUPLICATES
    # -------------------------------
    df = df.drop_duplicates(subset=["payment_id"])

    after_dupes = len(df)

    # -------------------------------
    # REMOVE INVALID AMOUNTS
    # -------------------------------
    df = df[df["amount"] > 0]

    after_amount_filter = len(df)

    # -------------------------------
    # LOGGING
    # -------------------------------
    if logger:
        logger.info(f"Initial records: {initial_count}")
        logger.info(f"After removing nulls: {after_nulls}")
        logger.info(f"After removing duplicates: {after_dupes}")
        logger.info(f"After removing invalid amounts: {after_amount_filter}")
        logger.info(f"Final valid records: {len(df)}")

        # -------------------------------
        # BUSINESS METRICS (NEW 🔥)
        # -------------------------------
        failed_payments = df[df["status"] == "failed"].shape[0]
        refunded_payments = df[df["status"] == "refunded"].shape[0]

        logger.info(f"Failed payments: {failed_payments}")
        logger.info(f"Refunded payments: {refunded_payments}")

    return df