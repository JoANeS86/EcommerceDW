"""
-----------------------------------
       SQL Server Connection
-----------------------------------
"""

import urllib.parse
import sqlalchemy as sa
from sqlalchemy import text


def get_engine():
    """
    Creates and returns a SQLAlchemy engine for SQL Server.
    Optimized with fast_executemany for bulk inserts.
    No side effects (safe to import).
    """
    params = urllib.parse.quote_plus(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=(localdb)\\Local;"
        "DATABASE=EcommerceDW;"
        "Trusted_Connection=yes"
    )

    engine = sa.create_engine(
        f"mssql+pyodbc:///?odbc_connect={params}",
        fast_executemany=True
    )

    return engine


def test_connection(engine):
    """
    Optional helper to test DB connection.
    Should be called explicitly (not on import).
    """
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT DB_NAME()"))
            db_name = result.fetchone()[0]
            print(f"Connected successfully to database: {db_name}")
    except Exception as e:
        print(f"Connection failed: {e}")


# Create a reusable engine instance
engine = get_engine()