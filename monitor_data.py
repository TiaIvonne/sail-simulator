#!/usr/bin/env python3
"""
Monitor incoming boat telemetry data
Check if data is flowing from Stream Analytics to SQL Database
Usage: source database.env && python3 monitor_data.py
"""

import pyodbc
import time
import os
from datetime import datetime

def get_db_connection():
    """Get database connection using environment variables"""
    server = os.getenv('SQL_SERVER')
    database = os.getenv('SQL_DATABASE') 
    username = os.getenv('SQL_USERNAME')
    password = os.getenv('SQL_PASSWORD')
    
    if not all([server, database, username, password]):
        print("❌ Missing database configuration!")
        print("💡 Load your environment variables:")
        print("   source database.env")
        print("   python3 monitor_data.py")
        return None
    
    connection_string = (
        f'DRIVER={{ODBC Driver 17 for SQL Server}};'
        f'SERVER={server};'
        f'DATABASE={database};'
        f'UID={username};'
        f'PWD={password};'
        f'Encrypt=yes;'
        f'TrustServerCertificate=yes;'
        f'Connection Timeout=30;'
    )
    
    return pyodbc.connect(connection_string)

def monitor_data():
    try:
        conn = get_db_connection()
        if not conn:
            return
        cursor = conn.cursor()
        
        print("🔍 Monitoring boat telemetry data...")
        print("Press Ctrl+C to stop")
        print("=" * 60)
        
        last_count = 0
        
        while True:
            # Get current record count
            cursor.execute("SELECT COUNT(*) FROM boat_telemetry")
            current_count = cursor.fetchone()[0]
            
            # Get latest records
            cursor.execute("""
                SELECT TOP 5 
                    boat_id, 
                    ROUND(latitude, 4) as lat, 
                    ROUND(longitude, 4) as lng, 
                    ROUND(speed, 1) as speed,
                    created_at
                FROM boat_telemetry 
                ORDER BY created_at DESC
            """)
            
            latest_records = cursor.fetchall()
            
            # Clear screen and show status
            print(f"\n📊 Total Records: {current_count} (+{current_count - last_count} new)")
            print(f"🕒 Last Check: {datetime.now().strftime('%H:%M:%S')}")
            
            if latest_records:
                print("\n🚤 Latest Boat Data:")
                print("Boat ID | Latitude  | Longitude | Speed | Time")
                print("-" * 50)
                for record in latest_records:
                    print(f"   {record[0]:2d}   | {record[1]:8.4f} | {record[2]:9.4f} | {record[3]:4.1f} | {record[4].strftime('%H:%M:%S')}")
            else:
                print("\n⏳ No data received yet. Waiting for Stream Analytics...")
                print("Make sure:")
                print("1. Your race_simulator.py is running")
                print("2. Stream Analytics job is started")
                print("3. SQL Database output is configured")
            
            last_count = current_count
            time.sleep(10)  # Check every 10 seconds
            
    except KeyboardInterrupt:
        print("\n👋 Monitoring stopped")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    monitor_data()

