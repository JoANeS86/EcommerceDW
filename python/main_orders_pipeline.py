"""
-----------------------------------
          Orders Pipeline
-----------------------------------
"""

from extract.api_simulator import get_orders_api
from transform.clean_orders import validate_orders
from load.load_to_sql import load_orders
from utils.logger import get_logger
from config.db_config import engine

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

        # -------------------------------
        # VALIDATION
        # -------------------------------
        clean_df = validate_orders(raw_data, logger)

        if clean_df.empty:
            logger.warning("No valid data to load after validation")
            return

        # -------------------------------
        # LOAD
        # -------------------------------
        load_orders(clean_df, engine, logger)

        logger.info(f"Pipeline completed successfully. Loaded {len(clean_df)} records")

    except Exception as e:
        logger.exception(f"Pipeline failed: {e}")
        raise


if __name__ == "__main__":
    run_pipeline()