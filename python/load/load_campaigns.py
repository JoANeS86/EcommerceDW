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

from sqlalchemy import text

def load_campaigns(df, engine, logger=None):
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE Staging.CSVStgCampaigns"))

    df.to_sql(
        "CSVStgCampaigns",
        con=engine,
        schema="Staging",
        if_exists="append",
        index=False
    )

    if logger:
        logger.info(f"Loaded {len(df)} campaigns")