from sqlalchemy import text


def load_payments(df, engine, logger=None):
    try:
        if logger:
            logger.info(f"Loading {len(df)} rows into staging load table")

        # -------------------------------
        # STEP 1: TRUNCATE LOAD TABLE
        # -------------------------------
        with engine.begin() as conn:
            conn.execute(text("TRUNCATE TABLE Staging.APIStgPaymentsLoad"))

        # -------------------------------
        # STEP 2: LOAD DATAFRAME
        # -------------------------------
        df.to_sql(
            "APIStgPaymentsLoad",
            con=engine,
            schema="Staging",
            if_exists="append",
            index=False,
            chunksize=10000
        )

        if logger:
            logger.info("Data loaded into staging load table")

        # -------------------------------
        # STEP 3: MERGE WITH JOIN 🔥
        # -------------------------------
        merge_sql = """
        MERGE INTO Staging.APIStgPayments AS target
        USING (
            SELECT p.*
            FROM Staging.APIStgPaymentsLoad p
            INNER JOIN Staging.APIStgOrders o
                ON p.order_id = o.order_id
        ) AS source
        ON target.payment_id = source.payment_id

        WHEN NOT MATCHED BY TARGET THEN
            INSERT (
                payment_id,
                order_id,
                payment_date,
                amount,
                payment_method,
                status
            )
            VALUES (
                source.payment_id,
                source.order_id,
                source.payment_date,
                source.amount,
                source.payment_method,
                source.status
            );
        """

        with engine.begin() as conn:
            conn.execute(text(merge_sql))

        if logger:
            logger.info("MERGE completed successfully (with referential integrity)")

    except Exception as e:
        if logger:
            logger.error(f"Error during payments MERGE load: {e}")
        raise