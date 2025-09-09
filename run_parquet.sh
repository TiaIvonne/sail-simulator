#!/bin/bash
# Simple Parquet + Azure runner for study case

echo "⛵ Simple Parquet Lambda Architecture"
echo "===================================="

# Load environment variables
if [ -f "database.env" ]; then
    echo "🔐 Loading database config..."
    source database.env
else
    echo "❌ database.env not found!"
    exit 1
fi

if [ -f "azure_storage.env" ]; then
    echo "☁️  Loading Azure storage config..."
    source azure_storage.env
else
    echo "❌ azure_storage.env not found!"
    exit 1
fi

# Run simple parquet batch processor
echo "🚀 Running Parquet batch processing..."
python3 simple_parquet_batch.py

echo ""
echo "💡 What just happened:"
echo "   📊 Extracted data from SQL Database (Speed Layer)"
echo "   ⚙️  Computed boat rankings (Batch Layer)"
echo "   ☁️  Saved Parquet file to Azure Blob (Batch Storage)"
echo "   🎛️  Displayed results (Serving Layer)"
