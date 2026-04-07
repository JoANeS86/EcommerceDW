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

def load_orders(df, engine, logger=None):
    try:
        if logger:
            logger.info(f"Loading {len(df)} rows into staging load table")

        # Step 1: Truncate load table
        with engine.begin() as conn:
            conn.execute(text("TRUNCATE TABLE Staging.APIStgOrdersLoad"))

        # Step 2: Load into staging load table
        df.to_sql(
            "APIStgOrdersLoad",
            con=engine,
            schema="Staging",
            if_exists="append",
            index=False,
            chunksize=10000
        )

        if logger:
            logger.info("Data loaded into staging load table")

        # Step 3: MERGE into final table
        merge_sql = """
        MERGE INTO Staging.APIStgOrders AS target
        USING Staging.APIStgOrdersLoad AS source
        ON target.order_id = source.order_id

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (order_id, customer_id, order_date, amount, status)
            VALUES (source.order_id, source.customer_id, source.order_date, source.amount, source.status);
        """

        with engine.begin() as conn:
            conn.execute(text(merge_sql))

        if logger:
            logger.info("MERGE completed successfully")

    except Exception as e:
        if logger:
            logger.error(f"Error during MERGE load: {e}")
        raise