"""
-----------------------------------
          Orders Pipeline
-----------------------------------
"""

from extract.api_simulator import get_orders_api
from transform.clean_orders import validate_orders
from load.load_to_sql import load_orders
from load.watermark import get_watermark, update_watermark
from utils.logger import get_logger
from config.db_config import engine
from datetime import timedelta
from datetime import datetime

logger = get_logger("orders_pipeline", "orders_pipeline.log")


def run_pipeline():
    logger.info("Starting pipeline")

    try:
        # -------------------------------
        # API CALL WITH RETRIES
        # -------------------------------
        max_retries = 3
        attempt = 0

        while attempt < max_retries:
            response = get_orders_api()

            if response["status"] == "success":
                logger.info(f"API call successful on attempt {attempt + 1}")
                break
            else:
                logger.warning(f"API failed on attempt {attempt + 1}: {response['message']}")
                attempt += 1

        if response["status"] != "success":
            raise Exception("API failed after maximum retries")

        raw_data = response["data"]

        if not raw_data:
            logger.warning("API returned empty dataset")
            return

        # -------------------------------
        # VALIDATION
        # -------------------------------
        df = validate_orders(raw_data, logger)

        if df.empty:
            logger.warning("No valid data after validation")
            return
        
        # -------------------------------
        # FUTURE DATE FILTER
        # -------------------------------
        today = datetime.now()

        before_future_filter = len(df)

        df = df[df["order_date"] <= today]

        after_future_filter = len(df)

        logger.info(f"Records before future-date filter: {before_future_filter}")
        logger.info(f"Records after future-date filter: {after_future_filter}")
        logger.info(f"Filtered out {before_future_filter - after_future_filter} future records")

        if df.empty:
            logger.warning("No data after future-date filtering")
            return

        # -------------------------------
        # WATERMARK FILTER (WITH BUFFER)
        # -------------------------------
        watermark = get_watermark(engine, "orders_pipeline")

        buffer_days = 3
        adjusted_watermark = watermark - timedelta(days=buffer_days)

        logger.info(f"Current watermark: {watermark}")
        logger.info(f"Adjusted watermark (with {buffer_days}d buffer): {adjusted_watermark}")

        before_watermark = len(df)

        df = df[df["order_date"] > adjusted_watermark]

        after_watermark = len(df)

        logger.info(f"Records before watermark filter: {before_watermark}")
        logger.info(f"Records after watermark filter: {after_watermark}")
        logger.info(f"Filtered out {before_watermark - after_watermark} old records")

        if df.empty:
            logger.warning("No new data after watermark filtering")
            return

        # -------------------------------
        # LOAD
        # -------------------------------
        load_orders(df, engine, logger)

        logger.info(f"Loaded {len(df)} new records")

        # -------------------------------
        # UPDATE WATERMARK
        # -------------------------------
        new_watermark = df["order_date"].max()

        update_watermark(engine, "orders_pipeline", new_watermark)

        logger.info(f"Watermark updated to: {new_watermark}")

        logger.info("Pipeline completed successfully")

    except Exception as e:
        logger.exception(f"Pipeline failed: {e}")
        raise


if __name__ == "__main__":
    run_pipeline()