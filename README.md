# ⛵ Boat Racing Lambda Architecture

**Simple Parquet-based Lambda Architecture for Real-time Boat Racing Analytics**

---

## 🏗️ **Architecture**

```
📊 LAMBDA ARCHITECTURE
┌─────────────────────────────────────────────────────────────┐
│  race_simulator.py → Event Hub → Stream Analytics          │  ← SPEED LAYER
│                    → boat_telemetry (SQL Database)         │
└─────────────┬───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────┐
│  simple_parquet_batch.py                                   │  ← BATCH LAYER
│  • Daily rankings computation                              │
│  • Parquet file storage                                    │
└─────────────┬───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────┐
│  Dashboard & Analytics                                     │  ← SERVING LAYER
│  • Combined real-time + batch data                        │
│  • Grafana visualization                                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 **Project Structure**

```
techionista/
├── README.md                        # This documentation
├── race_simulator.py               # Data generator (Speed Layer)
├── race_simulator_copy.py          # Backup copy
├── azure_parquet_batch.py          # Azure Blob batch processor (Batch Layer)
├── run.sh                          # Simple runner script
├── requirements_simple.txt         # Python dependencies
├── azure_storage.env              # Azure credentials template
├── grafana_dashboard_queries.sql   # Grafana queries
├── stream_analytics_updated.sql    # Stream Analytics query
├── monitor_data.py                 # Database monitoring
└── terraform/                     # Infrastructure (optional)
```

---

## 🚀 **Quick Start**

### **1. Install Dependencies**
```bash
pip3 install -r requirements_simple.txt
```

### **2. Test Setup**
```bash
./run.sh test
```

### **3. Run Batch Processing**
```bash
./run.sh process
```

### **4. View Results**
```bash
./run.sh preview
```

---

## 🎯 **Key Features**

### **Speed Layer (Real-time)**
- ✅ Live boat telemetry ingestion
- ✅ Stream Analytics processing
- ✅ Real-time SQL Database storage

### **Batch Layer (Historical)**
- ✅ Daily rankings computation
- ✅ Azure Blob Storage for Parquet files
- ✅ Compressed, efficient columnar storage
- ✅ Historical trend analysis

### **Serving Layer (Combined)**
- ✅ Real-time + batch data combination
- ✅ Performance status indicators
- ✅ Dashboard preview

---

## 💰 **Cost Analysis**

| Component | Monthly Cost |
|-----------|-------------|
| Azure Event Hub | ~$10 |
| Stream Analytics | ~$10 |
| SQL Database | ~$5 |
| Azure Blob Storage | ~$1-2 |
| **Total** | **~$26-27** |

---

## 📊 **Data Flow**

### **Real-time (Speed Layer)**
1. `race_simulator.py` generates boat telemetry
2. Data flows to Azure Event Hub
3. Stream Analytics processes and stores in SQL
4. `latest_boat_positions` view shows current state

### **Batch Processing (Batch Layer)**
1. `azure_parquet_batch.py` reads daily data from SQL
2. Computes rankings and statistics with Pandas
3. Saves compressed results to Azure Blob Storage
4. Enables historical analysis and long-term storage

### **Serving (Combined)**
1. Combines real-time positions with daily rankings
2. Shows performance status (above/below average)
3. Provides data for Grafana dashboards

---

## 🎛️ **Usage**

### **Setup Azure Storage**
```bash
# 1. Edit azure_storage.env with your Azure Storage connection string
# 2. Load environment variables
source azure_storage.env
```

### **Daily Operations**
```bash
# Run batch processing
./run.sh process

# View dashboard preview  
./run.sh preview

# List available data in Azure
./run.sh list

# Test system health
./run.sh test
```

### **Data Analysis**
```python
# Load data from Azure Blob Storage
from azure_parquet_batch import AzureParquetBatch
from datetime import date

processor = AzureParquetBatch()
df = processor.load_from_azure_blob(date.today())

# Analyze
print(df.describe())
print(df.nlargest(5, 'speed_mean'))
```

---

## 🏆 **Portfolio Highlights**

### **Technical Skills**
- **Lambda Architecture**: Proper separation of speed/batch/serving layers
- **Real-time Processing**: Azure Event Hub + Stream Analytics
- **Batch Processing**: Python + Pandas + Parquet
- **Data Engineering**: Efficient columnar storage and analytics
- **Cloud Architecture**: Azure services integration
- **Cost Optimization**: Local processing reduces cloud costs

### **Business Value**
- **Real-time Insights**: Live race monitoring
- **Historical Analysis**: Performance trends and rankings
- **Scalable**: Can handle thousands of boats
- **Cost Effective**: ~$25/month total infrastructure

---

## 📈 **Sample Output**

```
🎛️  DASHBOARD PREVIEW
============================================================
Boat   Current  Avg     Rank   Status      
------ -------- ------- ------ ------------
1      28.5     25.2    2      Above Average
2      32.1     30.8    1      Above Average  
3      22.3     24.1    3      Below Average
4      26.8     27.1    4      Below Average
```

---

## ✅ **Success Metrics**

- [x] **True Lambda Architecture** implemented
- [x] **Industry-standard Parquet** for batch storage
- [x] **Cost-effective** solution (<$30/month)
- [x] **Portfolio-ready** with clear documentation
- [x] **Scalable** architecture for production use

---

**🎯 This project demonstrates modern data engineering practices with real-time and batch processing, using industry-standard tools while maintaining cost efficiency.**
