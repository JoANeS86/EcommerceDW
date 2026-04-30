"""
-----------------------------------
        Campaigns Pipeline
-----------------------------------
"""

import os
from extract.csv_campaigns_extractor import extract_campaigns
from transform.clean_campaigns import clean_campaigns
from load.load_campaigns import load_campaigns
from utils.logger import get_logger
from config.db_config import engine

# ---------------------------------
# LOGGER
# ---------------------------------
logger = get_logger("campaigns_pipeline", "campaigns_pipeline.log")

# ---------------------------------
# PATH CONFIG
# ---------------------------------
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CAMPAIGNS_PATH = os.path.join(BASE_DIR, "data", "raw", "campaigns.csv")

# ---------------------------------
# PIPELINE
# ---------------------------------
def run_pipeline():
    logger.info("Starting campaigns pipeline")

    # Validate file existence
    if not os.path.exists(CAMPAIGNS_PATH):
        logger.error(f"File not found: {CAMPAIGNS_PATH}")
        raise FileNotFoundError(f"Campaigns file not found at {CAMPAIGNS_PATH}")

    logger.info(f"Reading campaigns file from: {CAMPAIGNS_PATH}")

    # Extract
    df = extract_campaigns(CAMPAIGNS_PATH)
    logger.info(f"Extracted {len(df)} records")

    # Transform
    df = clean_campaigns(df, logger)
    logger.info(f"Records after cleaning: {len(df)}")

    # Load
    load_campaigns(df, engine, logger)

    logger.info("Campaigns pipeline completed successfully")


# ---------------------------------
# ENTRY POINT
# ---------------------------------
if __name__ == "__main__":
    run_pipeline()