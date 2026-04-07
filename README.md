# Dataplex Data Documentation Scanner

A bash script to programmatically create and run [Google Cloud Dataplex](https://cloud.google.com/dataplex) Data Documentation scans on all tables or views in a BigQuery dataset using the REST API.

**✨ NEW:** Automatically adds required labels to publish AI-generated insights to BigQuery!

## 🎯 What This Does

This script automates the process of:
1.  ✅ **Creating Dataplex Data Documentation scans** for all tables/views in a BigQuery dataset.
2.  ✅ **Running the scans automatically.**
3.  ✅ **Adding required labels** to publish results to BigQuery.
4.  ✅ **Generating AI-powered insights** that appear in BigQuery's "Insights" tab.
5.  ✅ **Publishing documentation** to Data Catalog.

## 📋 Prerequisites

Before running this script, ensure you have:

*   ✅ **Google Cloud SDK** installed ([Installation Guide](https://cloud.google.com/sdk/docs/install))
*   ✅ **BigQuery CLI (bq)** installed (comes with gcloud)
*   ✅ **Authenticated** with gcloud: `gcloud auth login`
*   ✅ **Appropriate IAM permissions**:
    *   `roles/dataplex.editor` or `roles/dataplex.admin`
    *   `roles/bigquery.dataEditor` (to add labels to tables/views)
    *   `roles/bigquery.dataViewer` or higher on the dataset
    *   `roles/datacatalog.editor` (for catalog publishing)

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/optidus/data_insights_scan.git
cd data_insights_scan
```

### 2. Configure the Script
Open `dataplex_data_insights_scan.sh` and update these variables:
```bash
PROJECT_ID="your-gcp-project-id"
DATASET_ID="your_bigquery_dataset"
LOCATION="us-central1"  # Your preferred region
```

### 3. Make the Script Executable
```bash
chmod +x dataplex_data_insights_scan.sh
```

### 4. Run the Script
```bash
./dataplex_data_insights_scan.sh
```

### 5. View Insights in BigQuery
After **5-10 minutes**:
1.  Go to [BigQuery Console](https://console.cloud.google.com/bigquery).
2.  Navigate to your dataset and click on a table/view.
3.  Click the **"Insights"** tab to see AI-generated documentation!

---

## ⚙️ Configuration Options

### Scan Tables Instead of Views
Modify the `TABLE_FILTER` variable in the script to target specific object types:

```bash
# For VIEWS only
TABLE_FILTER='$2 == "VIEW" {print $1}'

# For TABLES only
TABLE_FILTER='$2 == "TABLE" {print $1}'

# For ALL tables and views (default)
TABLE_FILTER='NR>1 && $1 != "tableId" {print $1}'
```

### Change Region
Dataplex requires a specific regional location. Common options:
```bash
LOCATION="us-central1"      # Iowa
LOCATION="us-east1"         # South Carolina
LOCATION="europe-west1"     # Belgium
LOCATION="asia-southeast1"  # Singapore
```

---

## 📊 Viewing Results

### Using gcloud CLI
```bash
# List all scans
gcloud dataplex datascans list \
  --project=YOUR_PROJECT_ID \
  --location=us-central1 \
  --sort-by=~createTime

# Check specific scan status
gcloud dataplex datascans jobs list \
  --datascan=SCAN_ID \
  --project=YOUR_PROJECT_ID \
  --location=us-central1
```

### Verify Labels Were Added
```bash
bq show --format=prettyjson YOUR_PROJECT:YOUR_DATASET.YOUR_TABLE | grep dataplex-data-documentation
```

---

## 🔍 Understanding Scan Types

| Scan Type | Purpose | Dataplex UI | BigQuery UI | Labels Required? |
| :--- | :--- | :---: | :---: | :---: |
| **DATA_PROFILE** | Statistical profiling (min/max/nulls) | ✅ | ✅ (Profile Tab) | ❌ No |
| **DATA_DOCUMENTATION** | AI-generated insights/docs | ✅ | ✅ (Insights Tab) | ✅ **Yes** |

> [!IMPORTANT]
> To display **DATA_DOCUMENTATION** in BigQuery, the script adds labels for `published-scan`, `published-project`, and `published-location`.

---

## 🔧 Troubleshooting

*   **"Failed to get authentication token"**: Run `gcloud auth application-default login`.
*   **"Insights not appearing"**: 
    1.  Wait 15 minutes.
    2.  Check if scan status is `SUCCEEDED`.
    3.  Verify labels exist on the table via `bq show`.
*   **"Permission denied"**: Ensure you have `roles/bigquery.dataEditor` to allow the script to write labels to your tables.

---

## 📖 How It Works
The script uses the **Dataplex REST API** for creation because it offers higher compatibility across SDK versions than the standard `gcloud` command. It then uses the `bq` CLI to "tag" your tables with the scan metadata, which acts as a bridge to surface the AI insights directly within the BigQuery console.

## 🛠️ Advanced Usage: Scan Multiple Datasets
```bash
#!/bin/bash
DATASETS=("sales_data" "marketing_data" "product_data")
for DATASET in "${DATASETS[@]}"; do
  sed -i "s/DATASET_ID=\".*\"/DATASET_ID=\"$DATASET\"/" dataplex_data_insights_scan.sh
  ./dataplex_data_insights_scan.sh
done
```

---

## 📝 License & Support
This project is licensed under the **MIT License**. If you encounter issues, please open an issue in the repository or consult the [Dataplex Documentation](https://cloud.google.com/dataplex/docs).

**Made with ❤️ for the Google Cloud community.**
