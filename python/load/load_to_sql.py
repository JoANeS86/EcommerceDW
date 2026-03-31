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
    try:
        print(f"Loading {len(df)} rows into Staging.APIStgOrders...")
        
        # Try loading data into SQL Server
        df.to_sql(
            "APIStgOrders",  # Table name
            con=engine,
            schema="Staging",  # Ensure the schema is correct
            if_exists="replace",  # Overwrite if table exists
            index=False
        )
        print("Data load successful!")
    except Exception as e:
        print(f"Error while loading data: {e}")