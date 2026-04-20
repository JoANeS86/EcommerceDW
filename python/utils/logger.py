"""
-----------------------------------
             Logging
-----------------------------------
"""

import os
import logging


def get_logger(name, log_file):
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)

    # Absolute path to logs folder at project root
    project_root = os.path.dirname(os.path.dirname(__file__))
    log_path = os.path.join(project_root, "logs")
    os.makedirs(log_path, exist_ok=True)

    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    # Remove existing file handlers
    for handler in logger.handlers[:]:
        if isinstance(handler, logging.FileHandler):
            logger.removeHandler(handler)

    # File handler
    file_handler = logging.FileHandler(os.path.join(log_path, log_file))
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    # Console handler
    if not any(isinstance(h, logging.StreamHandler) for h in logger.handlers):
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

    return logger
