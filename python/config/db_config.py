"""
-----------------------------------
       SQL Server Connection
-----------------------------------
"""

import urllib.parse
import sqlalchemy as sa
from sqlalchemy import text  # Import the text function

try:
    # Update the connection string for LocalDB
    params = urllib.parse.quote_plus(
        "DRIVER={ODBC Driver 17 for SQL Server};SERVER=(localdb)\\Local;DATABASE=EcommerceDW;Trusted_Connection=yes"
    )
    
    engine = sa.create_engine(f"mssql+pyodbc:///?odbc_connect={params}")
    
    # Test the connection
    with engine.connect() as conn:
        print("Connection successful!")

    # Check the current database
    with engine.connect() as conn:
        result = conn.execute(text("SELECT DB_NAME()"))  # Wrap the query with text()
        print(f"Connected to database: {result.fetchone()[0]}")

except Exception as e:
    print(f"Error: {e}")