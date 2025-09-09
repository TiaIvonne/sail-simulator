# ⛵ Boat Racing Lambda Architecture

**Simple Parquet-based Lambda Architecture for Real-time Boat Racing Analytics**

---

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