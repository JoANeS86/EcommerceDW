"""
-----------------------------------
      Data Validation Layer
-----------------------------------
"""

def clean_campaigns(df, logger=None):
    initial = len(df)

    df = df.dropna()

    if logger:
        logger.info(f"Campaigns cleaned: {initial} -> {len(df)}")

    return df