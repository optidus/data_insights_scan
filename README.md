# Dataplex Data Insights Scanner

A bash script to programmatically create and run [Google Cloud Dataplex](https://cloud.google.com/dataplex) Data Documentation scans on all tables or views in a BigQuery dataset using the REST API.

## 🎯 What This Does

This script automates the process of:

1.  ✅ **Creating Dataplex Data Documentation scans** for all tables/views in a BigQuery dataset.
2.  ✅ **Running the scans automatically.**
3.  ✅ **Generating AI-powered insights** that appear in BigQuery's "Insights" tab.
4.  ✅ **Publishing documentation** to Data Catalog.

## 📋 Prerequisites

Before running this script, ensure you have:

  * ✅ **Google Cloud SDK** installed ([Installation Guide](https://cloud.google.com/sdk/docs/install))
  * ✅ **BigQuery CLI (bq)** installed (comes with gcloud)
  * ✅ **Authenticated** with gcloud: `gcloud auth login`
  * ✅ **Appropriate IAM permissions**:
      * `roles/dataplex.editor` or `roles/dataplex.admin`
      * `roles/bigquery.dataViewer` or higher on the dataset
      * `roles/datacatalog.editor` (for catalog publishing)

## 🚀 Quick Start

### 1\. Clone the Repository

```bash
git clone https://github.com/optidus/data_insights_scan.git
cd data_insights_scan
```

### 2\. Configure the Script

Open `dataplex_data_insights_scan.sh` and update these variables:

```bash
PROJECT_ID="your-gcp-project-id"
DATASET_ID="your_bigquery_dataset"
LOCATION="us-central1"  # Your preferred region
```

### 3\. Make the Script Executable

```bash
chmod +x dataplex_data_insights_scan.sh
```

### 4\. Run the Script

```bash
./dataplex_data_insights_scan.sh
```

The script will:

  * List all views/tables in the dataset.
  * Ask for confirmation.
  * Create and run scans for each item.
  * Display progress and results.

-----

## ⚙️ Configuration Options

### Scan Tables Instead of Views

By default, the script scans views only. To scan tables or all objects, modify the `TABLE_FILTER` variable:

```bash
# For VIEWS only (default)
TABLE_FILTER='$2 == "VIEW" {print $1}'

# For TABLES only
TABLE_FILTER='$2 == "TABLE" {print $1}'

# For ALL tables and views
TABLE_FILTER='NR>1 && $1 != "tableId" {print $1}'
```

### Change Region

Dataplex requires a specific regional location (not multi-region). Common options:

  * `LOCATION="us-central1"` (Iowa)
  * `LOCATION="us-east1"` (South Carolina)
  * `LOCATION="europe-west1"` (Belgium)
  * `LOCATION="asia-southeast1"` (Singapore)

-----

## 📊 Viewing Results

### In BigQuery Console

1.  Go to **BigQuery Console**.
2.  Navigate to your dataset.
3.  Click on a table/view.
4.  Click the **"Insights"** tab.
5.  Wait 2-5 minutes for scans to complete.

### Using gcloud CLI

```bash
# List all datascans
gcloud dataplex datascans list \
  --project=YOUR_PROJECT_ID \
  --location=us-central1

# Filter for DATA_DOCUMENTATION scans only
gcloud dataplex datascans list \
  --project=YOUR_PROJECT_ID \
  --location=us-central1 \
  --filter="type=DATA_DOCUMENTATION"

# View a specific scan
gcloud dataplex datascans describe SCAN_ID \
  --project=YOUR_PROJECT_ID \
  --location=us-central1

# View scan execution history
gcloud dataplex datascans jobs list SCAN_ID \
  --project=YOUR_PROJECT_ID \
  --location=us-central1
```

-----

## 🔧 Troubleshooting

  * **"Failed to get authentication token"**
      * Run `gcloud auth login` followed by `gcloud auth application-default login`.
  * **"No tables/views found"**
      * Verify the dataset name is correct and you have read permissions.
      * Ensure `TABLE_FILTER` matches your target objects.
  * **"Permission denied" errors**
      * Ensure you have the required IAM roles. Use this command to grant access:
    <!-- end list -->
    ```bash
    gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
      --member="user:YOUR_EMAIL@example.com" \
      --role="roles/dataplex.editor"
    ```
  * **"Location not found" errors**
      * Use a specific regional location (e.g., `us-central1`) instead of multi-regional (e.g., `us`).

-----

## 📖 How It Works

The script uses the Dataplex REST API to:

1.  Authenticate using your gcloud credentials.
2.  List tables/views from the specified BigQuery dataset using `bq ls`.
3.  Create scans via `POST` request to the Dataplex API.
4.  Poll operations to wait for scan creation to complete (asynchronous).
5.  Run scans via `POST` request to trigger the scan execution.

### Why REST API Instead of gcloud CLI?

Using the REST API directly ensures compatibility across different gcloud SDK versions and provides more granular control over the scan creation process than the standard CLI commands might offer.

-----

## 🤝 Contributing

Contributions are welcome\! Please feel free to submit a Pull Request.

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

  * Built for **Google Cloud Dataplex**.
  * Uses **BigQuery** and **Data Catalog**.

## 🔗 Related Resources

  * [Dataplex Data Documentation](https://www.google.com/search?q=https://cloud.google.com/dataplex/docs/data-documentation)
  * [Dataplex REST API Reference](https://www.google.com/search?q=https://cloud.google.com/dataplex/docs/reference/rest)
  * [BigQuery Insights](https://www.google.com/search?q=https://cloud.google.com/bigquery/docs/analyze-data-insights)
