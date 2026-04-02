"""
-----------------------------------
   Read existing orders from SQL
-----------------------------------
"""

import pandas as pd


def get_existing_order_ids(engine):
    query = "SELECT order_id FROM Staging.APIStgOrders"

    df = pd.read_sql(query, engine)

    return set(df["order_id"].tolist())