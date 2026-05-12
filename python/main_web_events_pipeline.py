"""
-----------------------------------
        Web Events Pipeline
-----------------------------------
"""

from extract.json_web_events_simulator import generate_web_events
from transform.clean_web_events import clean_web_events
from load.load_web_events import load_web_events
from utils.logger import get_logger
from config.db_config import engine
from datetime import datetime

logger = get_logger("web_events_pipeline", "web_events_pipeline.log")


def run_pipeline():
    logger.info("Starting web events pipeline")

    try:
        # -------------------------------
        # GENERATE EVENTS
        # -------------------------------
        raw_data = generate_web_events()

        if not raw_data:
            logger.warning("No web events generated")
            return

        logger.info(f"Generated {len(raw_data)} raw events")

        # -------------------------------
        # CLEANING
        # -------------------------------
        df = clean_web_events(raw_data, logger)

        if df.empty:
            logger.warning("No valid events after cleaning")
            return

        # -------------------------------
        # FUTURE DATE FILTER
        # -------------------------------
        now = datetime.now()

        before_filter = len(df)
        df = df[df["event_timestamp"] <= now]
        after_filter = len(df)

        logger.info(f"Future events removed: {before_filter - after_filter}")

        if df.empty:
            logger.warning("No events after future-date filter")
            return

        # -------------------------------
        # LOAD
        # -------------------------------
        load_web_events(df, engine, logger)

        logger.info(f"Pipeline completed: {len(df)} events loaded")

    except Exception as e:
        logger.exception(f"Web events pipeline failed: {e}")
        raise


if __name__ == "__main__":
    run_pipeline()