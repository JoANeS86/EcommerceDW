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

def load_orders(df, engine, logger=None):
    try:
        if logger:
            logger.info(f"Loading {len(df)} rows into Staging.APIStgOrders")

        df.to_sql(
            "APIStgOrders",
            con=engine,
            schema="Staging",
            if_exists="append",
            index=False,
            chunksize=10000
        )

        if logger:
            logger.info("Data load successful")

    except Exception as e:
        if logger:
            logger.error(f"Error while loading data: {e}")
        raise