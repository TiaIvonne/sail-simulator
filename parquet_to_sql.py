#!/usr/bin/env python3
"""
Load Parquet files from Azure and insert into SQL for Grafana visualization
Creates historical analytics tables for advanced dashboards
Usage: source database.env && source azure_storage.env && python3 parquet_to_sql.py
"""

import pandas as pd
import pyodbc
import os
from datetime import date, timedelta
from simple_parquet_batch import get_db_connection, get_azure_client, load_from_azure_blob

def create_historical_tables():
    """Create tables for historical analytics in SQL Database"""
    max_retries = 3
    for attempt in range(max_retries):
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Set command timeout for DDL operations
            cursor.execute("SET LOCK_TIMEOUT 60000")  # 60 seconds
            
            # Create historical rankings table
            create_table_sql = """
            IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='boat_historical_rankings' AND xtype='U')
            CREATE TABLE boat_historical_rankings (
                date DATE NOT NULL,
                boat_id INT NOT NULL,
                avg_speed DECIMAL(8,2),
                max_speed DECIMAL(8,2),
                records INT,
                rank INT,
                avg_lat DECIMAL(10,6),
                avg_lng DECIMAL(10,6),
                created_at DATETIME DEFAULT GETDATE(),
                PRIMARY KEY (date, boat_id)
            );
            """
            
            cursor.execute(create_table_sql)
            conn.commit()
            conn.close()
            print("✅ Created historical rankings table")
            return
            
        except Exception as e:
            print(f"⚠️  Table creation attempt {attempt + 1} failed: {e}")
            if attempt == max_retries - 1:
                print(f"❌ Failed to create table after {max_retries} attempts")
                raise
            print("🔄 Retrying in 2 seconds...")
            import time
            time.sleep(2)

def load_parquet_to_sql(target_date):
    """Load Parquet data from Azure into SQL Database with retry logic"""
    # Load from Azure Blob Storage
    df = load_from_azure_blob(target_date)
    
    if df.empty:
        print(f"⚠️  No Parquet data found for {target_date}")
        return False
    
    # Add date column
    df['date'] = target_date
    
    # Retry logic for SQL operations
    max_retries = 3
    for attempt in range(max_retries):
        try:
            # Connect to SQL
            conn = get_db_connection()
            cursor = conn.cursor()
            
            # Set command timeout for long operations
            cursor.execute("SET LOCK_TIMEOUT 60000")  # 60 seconds
            
            # Clear existing data for this date
            cursor.execute("DELETE FROM boat_historical_rankings WHERE date = ?", target_date)
            
            # Insert Parquet data in batch
            insert_data = []
            for _, row in df.iterrows():
                insert_data.append((
                    target_date, int(row['boat_id']), row['avg_speed'], row['max_speed'],
                    int(row['records']), int(row['rank']), row['avg_lat'], row['avg_lng']
                ))
            
            # Batch insert for better performance
            cursor.executemany("""
                INSERT INTO boat_historical_rankings 
                (date, boat_id, avg_speed, max_speed, records, rank, avg_lat, avg_lng)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, insert_data)
            
            conn.commit()
            conn.close()
            
            print(f"✅ Loaded {len(df)} rankings for {target_date} into SQL")
            return True
            
        except Exception as e:
            print(f"⚠️  SQL operation attempt {attempt + 1} failed: {e}")
            if attempt == max_retries - 1:
                print(f"❌ Failed after {max_retries} attempts")
                return False
            print("🔄 Retrying in 2 seconds...")
            import time
            time.sleep(2)

def sync_all_parquet_files():
    """Sync all available Parquet files to SQL Database"""
    print("🔄 Syncing all Parquet files to SQL Database...")
    
    # Get list of available dates (you could enhance this to auto-discover)
    dates_to_sync = [
        date.today(),
        date.today() - timedelta(days=1),
        # Add more dates as needed
    ]
    
    success_count = 0
    for target_date in dates_to_sync:
        if load_parquet_to_sql(target_date):
            success_count += 1
    
    print(f"✅ Synced {success_count} Parquet files to SQL Database")

def main():
    """Main sync process"""
    print("⛵ Parquet to SQL Sync for Grafana Analytics")
    print("=" * 50)
    
    try:
        # Step 1: Create tables if needed
        create_historical_tables()
        
        # Step 2: Sync Parquet files to SQL
        sync_all_parquet_files()
        
        print("\n🎯 Now you can create Grafana panels!")

        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("💡 Make sure to run: source database.env && source azure_storage.env")

if __name__ == "__main__":
    main()
