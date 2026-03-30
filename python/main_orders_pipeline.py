"""
-----------------------------------
          Orders Pipeline
-----------------------------------
"""

from extract.api_simulator import get_orders_api
from transform.clean_orders import validate_orders
from load.load_to_sql import load_orders
from utils.logger import get_logger
from config import engine

logger = get_logger("orders_pipeline", "orders_pipeline.log")

def run_pipeline():
    logger.info("Starting pipeline")

    response = get_orders_api()

    if response["status"] != "success":
        logger.error("API failed")
        return

    raw_data = response["data"]

    clean_df = validate_orders(raw_data)

    if clean_df.empty:
        logger.warning("No valid data to load")
        return

    load_orders(clean_df, engine)

    logger.info(f"Loaded {len(clean_df)} records successfully")


if __name__ == "__main__":
    run_pipeline()