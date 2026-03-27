"""
-----------------------------------
       Load to SQL Server
-----------------------------------

First time this code is executed, we're utilizing 'if_exists="replace"',
since at that moment the APIStgOrders table in SSMS is empty and has only
one column.

The replace option will automatically drop and recreate the table with
the correct schema based on the DataFrame you're loading.

"""

import pandas as pd

def load_orders(df, engine):
    df.to_sql(
        "EcommerceDW.Staging.APIStgOrders",
        con=engine,
        if_exists="append",
        index=False
    )