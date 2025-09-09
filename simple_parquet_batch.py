#!/usr/bin/env python3
"""
Simple Parquet + Azure Blob Batch Processor
Lambda Architecture study case with industry standards
"""

import pandas as pd
import pyodbc
import os
from datetime import date
from azure.storage.blob import BlobServiceClient
from io import BytesIO

def get_db_connection():
    """Simple database connection with extended timeout"""
    return pyodbc.connect(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={os.getenv('SQL_SERVER')};"
        f"DATABASE={os.getenv('SQL_DATABASE')};"
        f"UID={os.getenv('SQL_USERNAME')};"
        f"PWD={os.getenv('SQL_PASSWORD')};"
        f"Encrypt=yes;TrustServerCertificate=yes;"
        f"Connection Timeout=60;"  # Extended timeout for Azure SQL
    )

def get_azure_client():
    """Simple Azure Blob Storage connection"""
    conn_string = os.getenv('AZURE_STORAGE_CONNECTION_STRING')
    return BlobServiceClient.from_connection_string(conn_string)

def extract_daily_data(target_date=None):
    """Extract boat data from SQL Database (Speed Layer source)"""
    if target_date is None:
        target_date = date.today()
    
    print(f"📊 Extracting boat data for {target_date}")
    
    # Retry logic for connection issues
    max_retries = 3
    for attempt in range(max_retries):
        try:
            conn = get_db_connection()
            query = """
            SELECT boat_id, speed, latitude, longitude, event_time
            FROM boat_telemetry 
            WHERE CAST(event_time AS DATE) = ?
              AND speed IS NOT NULL
            ORDER BY boat_id, event_time
            """
            
            df = pd.read_sql(query, conn, params=[target_date])
            conn.close()
            
            print(f"✅ Extracted {len(df)} records")
            return df
            
        except Exception as e:
            print(f"⚠️  Attempt {attempt + 1} failed: {e}")
            if attempt == max_retries - 1:
                print(f"❌ Failed after {max_retries} attempts")
                raise
            print("🔄 Retrying in 2 seconds...")
            import time
            time.sleep(2)

def compute_boat_rankings(df):
    """Compute daily boat rankings (Batch Layer processing)"""
    print("🔢 Computing boat rankings...")
    
    # Simple aggregation by boat
    rankings = df.groupby('boat_id').agg({
        'speed': ['mean', 'max', 'count'],
        'latitude': 'mean',
        'longitude': 'mean'
    }).round(2)
    
    # Flatten column names
    rankings.columns = ['avg_speed', 'max_speed', 'records', 'avg_lat', 'avg_lng']
    rankings = rankings.reset_index()
    
    # Add ranking
    rankings['rank'] = rankings['avg_speed'].rank(ascending=False, method='dense')
    rankings = rankings.sort_values('rank')
    
    print(f"✅ Computed rankings for {len(rankings)} boats")
    return rankings

def save_to_azure_blob(df, target_date=None):
    """Save Parquet file to Azure Blob Storage (Batch Layer storage)"""
    if target_date is None:
        target_date = date.today()
    
    print("☁️  Saving to Azure Blob Storage...")
    
    # Create filename and path
    filename = f"boat_rankings_{target_date.strftime('%Y%m%d')}.parquet"
    blob_path = f"daily-rankings/{filename}"
    
    try:
        # Convert to Parquet in memory
        parquet_buffer = BytesIO()
        df.to_parquet(parquet_buffer, compression='snappy')
        parquet_buffer.seek(0)
        
        # Upload to Azure
        blob_client = get_azure_client()
        blob = blob_client.get_blob_client(container='parquet-data', blob=blob_path)
        blob.upload_blob(parquet_buffer.getvalue(), overwrite=True)
        
        print(f"✅ Saved: {blob_path}")
        return blob_path
        
    except Exception as e:
        print(f"❌ Azure upload failed: {e}")
        return None

def load_from_azure_blob(target_date=None):
    """Load Parquet file from Azure Blob Storage"""
    if target_date is None:
        target_date = date.today()
    
    filename = f"boat_rankings_{target_date.strftime('%Y%m%d')}.parquet"
    blob_path = f"daily-rankings/{filename}"
    
    try:
        blob_client = get_azure_client()
        blob = blob_client.get_blob_client(container='parquet-data', blob=blob_path)
        
        # Download and load
        parquet_data = blob.download_blob().readall()
        df = pd.read_parquet(BytesIO(parquet_data))
        
        print(f"☁️  Loaded: {blob_path}")
        return df
        
    except Exception as e:
        print(f"⚠️  Could not load {blob_path}: {e}")
        return pd.DataFrame()

def show_rankings(rankings):
    """Display boat rankings (Serving Layer preview)"""
    print("\n🏆 DAILY BOAT RANKINGS")
    print("=" * 60)
    print(f"{'Rank':<6} {'Boat':<6} {'Avg Speed':<12} {'Max Speed':<12} {'Records':<8}")
    print("-" * 60)
    
    for _, boat in rankings.head(10).iterrows():
        rank = int(boat['rank'])
        boat_id = int(boat['boat_id'])
        avg_speed = boat['avg_speed']
        max_speed = boat['max_speed']
        records = int(boat['records'])
        
        print(f"{rank:<6} {boat_id:<6} {avg_speed:<12.2f} {max_speed:<12.2f} {records:<8}")

def main():
    """Simple Lambda Architecture Batch Processing Pipeline"""
    print("⛵ Simple Parquet + Azure Blob Lambda Architecture")
    print("=" * 55)
    
    try:
        # Step 1: Extract (from Speed Layer SQL Database)
        data = extract_daily_data()
        
        if data.empty:
            print("❌ No data to process")
            return
        
        # Step 2: Transform (Batch Layer analytics)
        rankings = compute_boat_rankings(data)
        
        # Step 3: Load (Batch Layer storage - Azure Blob + Parquet)
        blob_path = save_to_azure_blob(rankings)
        
        if blob_path:
            # Step 4: Serve (Serving Layer preview)
            show_rankings(rankings)
            
            print(f"\n✅ Batch processing complete!")
            print(f"📁 Data stored in Azure: {blob_path}")
            print(f"📊 Format: Compressed Parquet (industry standard)")
            
        else:
            print("❌ Failed to save to Azure Blob Storage")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\n💡 Setup checklist:")
        print("   1. Run: source database.env")
        print("   2. Run: source azure_storage.env")
        print("   3. Ensure Azure container 'parquet-data' exists")

if __name__ == "__main__":
    main()
