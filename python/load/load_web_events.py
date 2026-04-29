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


def load_web_events(df, engine, logger=None):
    try:
        if logger:
            logger.info(f"Loading {len(df)} web events into staging load table")

        # -------------------------------
        # TRUNCATE LOAD TABLE
        # -------------------------------
        with engine.begin() as conn:
            conn.execute(text("TRUNCATE TABLE Staging.JSONStgWebEventsLoad"))

        # -------------------------------
        # LOAD INTO LOAD TABLE
        # -------------------------------
        df.to_sql(
            "JSONStgWebEventsLoad",
            con=engine,
            schema="Staging",
            if_exists="append",
            index=False,
            chunksize=10000
        )

        if logger:
            logger.info("Web events loaded into load table")

        # -------------------------------
        # MERGE INTO FINAL TABLE
        # -------------------------------
        merge_sql = """
        MERGE INTO Staging.APIStgWebEvents AS target
        USING Staging.JSONStgWebEventsLoad AS source
        ON target.event_id = source.event_id

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                event_id,
                order_id,
                customer_id,
                event_type,
                event_timestamp
            )
            VALUES (
                source.event_id,
                source.order_id,
                source.customer_id,
                source.event_type,
                source.event_timestamp
            );
        """

        with engine.begin() as conn:
            conn.execute(text(merge_sql))

        if logger:
            logger.info("Web events MERGE completed successfully")

    except Exception as e:
        if logger:
            logger.error(f"Error loading web events: {e}")
        raise