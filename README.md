# ⛵ Boat Racing: A Data Engineering project with Lambda Architecture
Disclaimer: This document has been written by a person (me) not a machine.

**An implementation of Lambda Architecture for Real-time Boat Racing Analytics and batch processing using parquet files and Azure**

---

Technical requirements/tools:

- Python
- Sql (SQL Server)
- Bash for scripting
- Azure (Event hub - Stream Analytics - SQL Database - Storage)
- Grafana for visualization/dashboard

## 🏗️ **Architecture**

```
📊 LAMBDA ARCHITECTURE
┌─────────────────────────────────────────────────────────────┐
│  race_simulator.py → Event Hub → Stream Analytics           │  ← SPEED LAYER
│                    → boat_telemetry (SQL Database)          │
└─────────────┬───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────┐
│  simple_parquet_batch.py                                    │  ← BATCH LAYER
│  • Daily rankings computation                               │
│  • Parquet file storage                                     │
└─────────────┬───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────┐
│  Dashboard & Analytics                                      │  ← SERVING LAYER
│  • Combined real-time + batch data                          │
│  • Grafana visualization                                    │
└─────────────────────────────────────────────────────────────┘
```

Snapshot:

https://cosmolabs.grafana.net/dashboard/snapshot/pgkUxOtA2bfSPZVNmP2WSXFMCj0Os3xH