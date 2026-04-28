"""
-----------------------------------
        Web Events Pipeline
-----------------------------------
"""

from extract.web_events_simulator import generate_web_events
from utils.logger import get_logger
from config.db_config import engine
from datetime import datetime, timedelta

logger = get_logger("web_events_pipeline", "web_events_pipeline.log")

def run_pipeline():
    logger.info("Starting pipeline")


    try:
        # -------------------------------
        # JSON CALL WITH RETRIES
        # -------------------------------
        max_retries = 3
        attempt = 0

        while attempt < max_retries:
            response = generate_web_events()

            if response:
                logger.info(f"JSON call successful on attempt {attempt + 1}")
                break
            else:
                logger.warning(f"JSON failed on attempt {attempt + 1}: {response['message']}")
                attempt += 1

        if response["status"] != "success":
            raise Exception("JSON failed after maximum retries")

        raw_data = response

        if not raw_data:
            logger.warning("JSON returned empty dataset")
            return
        











    except Exception as e:
        logger.exception(f"Pipeline failed: {e}")
        raise