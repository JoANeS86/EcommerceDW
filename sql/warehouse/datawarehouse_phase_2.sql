/*
===================================================================
                    Incremental Fact Loading
===================================================================

*/


-- Reuse Staging.ETLWatermark (add new row)


INSERT INTO Staging.ETLWatermark (pipeline_name, last_order_date)
VALUES ('fact_orders_load', '1900-01-01');


-- Update Fact Orders Stored Procedure (Incremental)


CREATE OR ALTER PROCEDURE DW.SPLoadFactOrdersIncremental
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @watermark DATETIME;
        DECLARE @adjusted_watermark DATETIME;
        DECLARE @buffer_days INT = 3;

        -- Get watermark
        SELECT @watermark = last_order_date
        FROM Staging.ETLWatermark
        WHERE pipeline_name = 'fact_orders_load';

        SET @adjusted_watermark = DATEADD(DAY, -@buffer_days, @watermark);

        PRINT 'Watermark: ' + CAST(@watermark AS VARCHAR);
        PRINT 'Adjusted watermark: ' + CAST(@adjusted_watermark AS VARCHAR);

        -- Build incremental dataset
        WITH OrdersIncremental AS (
            SELECT *
            FROM Staging.APIStgOrders
            WHERE order_date > @adjusted_watermark
        ),

        PaymentsAgg AS (
            SELECT
                order_id,
                SUM(amount) AS total_paid_amount,
                COUNT(*) AS payment_count,
                MAX(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS has_failed_payment
            FROM Staging.APIStgPayments
            GROUP BY order_id
        )

        MERGE DW.FactOrders AS target
        USING (
            SELECT
                o.order_id,
                ISNULL(dc.customer_key, -1) AS customer_key,
                dd.date_key,
                o.amount AS order_amount,

                ISNULL(p.total_paid_amount, 0) AS total_paid_amount,
                ISNULL(p.payment_count, 0) AS payment_count,
                ISNULL(p.has_failed_payment, 0) AS has_failed_payment

            FROM OrdersIncremental o

            LEFT JOIN DW.DimCustomer dc
                ON o.customer_id = dc.customer_id
                AND o.order_date >= dc.valid_from
                AND (
                    dc.valid_to IS NULL
                    OR o.order_date < dc.valid_to
                )

            INNER JOIN DW.DimDate dd
                ON CAST(o.order_date AS DATE) = dd.full_date

            LEFT JOIN PaymentsAgg p
                ON o.order_id = p.order_id
        ) AS source

        ON target.order_id = source.order_id

        WHEN MATCHED THEN
            UPDATE SET
                customer_key = source.customer_key,
                date_key = source.date_key,
                order_amount = source.order_amount,
                total_paid_amount = source.total_paid_amount,
                payment_count = source.payment_count,
                has_failed_payment = source.has_failed_payment

        WHEN NOT MATCHED THEN
            INSERT (
                order_id,
                customer_key,
                date_key,
                order_amount,
                total_paid_amount,
                payment_count,
                has_failed_payment
            )
            VALUES (
                source.order_id,
                source.customer_key,
                source.date_key,
                source.order_amount,
                source.total_paid_amount,
                source.payment_count,
                source.has_failed_payment
            );

        -- Update watermark
        UPDATE Staging.ETLWatermark
        SET last_order_date = (
            SELECT MAX(order_date)
            FROM Staging.APIStgOrders
        )
        WHERE pipeline_name = 'fact_orders_load';

        PRINT 'Incremental FactOrders load completed';

    END TRY
    BEGIN CATCH
        PRINT 'Error in incremental FactOrders load';
        THROW;
    END CATCH
END;


-- Execute Fact Orders Stored Procedure (Incremental)


EXEC DW.SPLoadFactOrdersIncremental;