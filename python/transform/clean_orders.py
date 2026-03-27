"""
-----------------------------------
      Data Validation Layer
-----------------------------------
"""

import pandas as pd

def validate_orders(data):
    df = pd.DataFrame(data)

    # Remove nulls
    df = df.dropna()

    # Remove duplicates
    df = df.drop_duplicates(subset=["order_id"])

    # Ensure valid amounts
    df = df[df["amount"] > 0]

    return df