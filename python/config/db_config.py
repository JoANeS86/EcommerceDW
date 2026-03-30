"""
-----------------------------------
       SQL Server Connection
-----------------------------------
"""

import sqlalchemy as sa

try:
    # Update the connection string for LocalDB
    engine = sa.create_engine("mssql+pyodbc://(localdb)\\Local/EcommerceDW?driver=ODBC+Driver+17+for+SQL+Server")
    with engine.connect() as conn:
        print("Connection successful!")
except Exception as e:
    print(f"Error: {e}")