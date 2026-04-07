# Dataplex Data Insights Scan

A bash script to programmatically create and run [Google Cloud Dataplex](https://cloud.google.com/dataplex) Data Documentation scans on all tables or views in a BigQuery dataset using the REST API.

**✨ NEW:** Automatically adds required labels to publish AI-generated insights to BigQuery!

---

## 🎯 What This Does

This script automates the process of:
1.  ✅ Creating Dataplex Data Documentation scans for all tables/views in a BigQuery dataset.
2.  ✅ Running the scans automatically.
3.  ✅ **Adding required labels to publish results to BigQuery.**
4.  ✅ Generating AI-powered insights that appear in BigQuery's "Insights" tab.
5.  ✅ Publishing documentation to Data Catalog.

---

## 📋 Prerequisites

Before running this script, ensure you have the following:

| Prerequisite | Details |
| :--- | :--- |
| **Google Cloud SDK** | Installed ([Installation Guide](https://cloud.google.com/sdk/docs/install)). |
| **BigQuery CLI (bq)** | Installed (comes with the gcloud SDK). |
| **Authentication** | Authenticated with gcloud: `gcloud auth login`. |
| **IAM Permissions** | You need the following roles on your GCP project: `roles/dataplex.editor` or `roles/dataplex.admin`, `roles/bigquery.dataEditor` (to add labels to tables/views), `roles/bigquery.dataViewer` or higher on the dataset, `roles/datacatalog.editor` (for catalog publishing). |

---

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
The script will:
*   List all tables/views in the dataset.
*   Ask for confirmation.
*   Create and run scans for each item.
*   **Automatically add labels to publish insights to BigQuery.**
*   Display progress and results.

### 5. View Insights in BigQuery
After 5-10 minutes:
1.  Go to the [BigQuery Console](https://www.google.com/url?sa=E&q=https%3A%2F%2Fconsole.cloud.google.com%2Fbigquery).
2.  Navigate to your dataset.
3.  Click on any table/view.
4.  Click the **"Insights"** tab.
5.  🎉 See AI-generated insights!

---

## ⚙️ Configuration Options

### Scan Tables Instead of Views
By default, the script scans **all tables and views**. To change this, modify the `TABLE_FILTER` variable:

```bash
# For VIEWS only
TABLE_FILTER='$2 == "VIEW" {print $1}'

# For TABLES only
TABLE_FILTER='$2 == "TABLE" {print $1}'

# For ALL tables and views (default)
TABLE_FILTER='NR>1 && $1 != "tableId" {print $1}'
```

### Change Region
Dataplex requires a specific regional location (not multi-region). Common options:

```bash
LOCATION="us-central1"      # Iowa
LOCATION="us-east1"         # South Carolina
LOCATION="europe-west1"     # Belgium
LOCATION="asia-southeast1"  # Singapore
```
See [Dataplex locations](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdataplex%2Fdocs%2Flocations) for all available regions.

---

## 📊 Viewing Results

### In BigQuery Console
1.  Go to the [BigQuery Console](https://www.google.com/url?sa=E&q=https%3A%2F%2Fconsole.cloud.google.com%2Fbigquery).
2.  Navigate to your dataset.
3.  Click on a table/view.
4.  Click the **"Insights"** tab.
5.  Wait 2-10 minutes for scans to complete.

> **Note:** Data Documentation scan results appear in **both** the Dataplex Console and BigQuery's "Insights" tab (after labels are added).

### In Dataplex Console
1.  Go to [Dataplex Data Scans](https://www.google.com/url?sa=E&q=https%3A%2F%2Fconsole.cloud.google.com%2Fdataplex%2Fdata-scans).
2.  Filter by your project and location.
3.  Click on a scan to view details and results.
4.  View the documentation insights generated.

> **Important:** For insights to appear in BigQuery's "Insights" tab, the script must successfully add the required labels to each table/view.

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

# View scan details
gcloud dataplex datascans describe SCAN_ID \
  --project=YOUR_PROJECT_ID \
  --location=us-central1
```

### Verify Labels Were Added
```bash
# Check if labels were added to a table
bq show --format=prettyjson YOUR_PROJECT:YOUR_DATASET.YOUR_TABLE | \
  grep dataplex-data-documentation
```
You should see:
```json
"dataplex-data-documentation-published-scan": "SCAN_ID",
"dataplex-data-documentation-published-project": "PROJECT_ID",
"dataplex-data-documentation-published-location": "LOCATION"
```

---

## 🔧 Troubleshooting

### "Failed to get authentication token"
```bash
gcloud auth login
gcloud auth application-default login
```

### "No tables/views found"
*   Verify the dataset name is correct.
*   Check you have read permissions on the dataset.
*   Ensure `TABLE_FILTER` matches your target objects.

### "Permission denied" errors
Ensure you have the required IAM roles:
```bash
# Grant yourself Dataplex Editor role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:YOUR_EMAIL@example.com" \
  --role="roles/dataplex.editor"

# Grant BigQuery Data Editor role (needed to add labels)
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:YOUR_EMAIL@example.com" \
  --role="roles/bigquery.dataEditor"
```

### "Insights not appearing in BigQuery"
1.  **Wait longer**: Scans can take 5-15 minutes to complete.
2.  **Check scan status**: Verify the scan shows `SUCCEEDED`.
    ```bash
    gcloud dataplex datascans jobs list \
      --datascan=SCAN_ID \
      --project=YOUR_PROJECT_ID \
      --location=us-central1
    ```
3.  **Verify labels**: Ensure labels were added to the table.
    ```bash
    bq show --format=prettyjson YOUR_PROJECT:DATASET.TABLE | grep dataplex
    ```
4.  **Hard refresh**: Clear browser cache or use incognito mode.
5.  **Check permissions**: Ensure you have `roles/datacatalog.viewer`.

### "Failed to add labels"
The script automatically adds labels, but if it fails:
```bash
# Manually add labels
bq update \
  --set_label dataplex-data-documentation-published-scan:SCAN_ID \
  --set_label dataplex-data-documentation-published-project:PROJECT_ID \
  --set_label dataplex-data-documentation-published-location:LOCATION \
  PROJECT_ID:DATASET_ID.TABLE_NAME
```

### Scans stuck in PENDING
*   Dataplex may have concurrency limits.
*   Usually scans start within 2-5 minutes.
*   If stuck > 10 minutes, try manually triggering:
    ```bash
    gcloud dataplex datascans run SCAN_ID \
      --project=PROJECT_ID \
      --location=LOCATION
    ```

---

## 📖 How It Works

The script uses the [Dataplex REST API](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdataplex%2Fdocs%2Freference%2Frest) to:
1.  **Authenticate** using your gcloud credentials.
2.  **List tables/views** from the specified BigQuery dataset using `bq ls`.
3.  **Create scans** via POST request to the Dataplex API.
4.  **Poll operations** to wait for scan creation to complete (asynchronous).
5.  **Run scans** via `gcloud dataplex datascans run`.
6.  **Add labels** to tables/views using `bq update` to enable insights publishing.
7.  **Report results** with success/failure counts.

### Why REST API for Creation?
The `gcloud dataplex datascans create` command may not be available in all gcloud SDK versions. Using the REST API for creation ensures compatibility, while using gcloud CLI for running scans provides reliability.

### Why Labels Are Required
Dataplex Data Documentation scans generate insights that are visible in the Dataplex Console. However, to display them in BigQuery's "Insights" tab, these labels must be added to each table/view:
*   `dataplex-data-documentation-published-scan`: The scan ID.
*   `dataplex-data-documentation-published-project`: The GCP project ID.
*   `dataplex-data-documentation-published-location`: The Dataplex location.

The script automatically adds these labels after starting each scan, enabling insights to appear in both Dataplex Console and BigQuery.

---

## 🔍 Understanding Scan Types

Dataplex supports two types of scans:

| Scan Type | Purpose | Visible in Dataplex UI | Visible in BigQuery |
| :--- | :--- | :--- | :--- |
| **DATA_PROFILE** | Statistical profiling (min, max, nulls, distributions, etc.) | ✅ Yes | ✅ Yes (Data Profile tab) |
| **DATA_DOCUMENTATION** | AI-generated insights and documentation | ✅ Yes | ✅ Yes (Insights tab) |

### Key Differences:

**`DATA_PROFILE` scans:**
*   Generate statistical summaries of your data.
*   Show column-level statistics (min, max, mean, null counts, cardinality).
*   Display data distributions and patterns.
*   Visible in BigQuery's "Data Profile" tab.
*   Visible in Dataplex Console.
*   **Do not require labels** to appear in BigQuery.

**`DATA_DOCUMENTATION` scans:**
*   Generate AI-powered natural language insights.
*   Provide column descriptions and recommendations.
*   Explain data patterns and anomalies.
*   Suggest data quality improvements.
*   **Require labels on tables/views** to appear in BigQuery.
*   Visible in BigQuery's "Insights" tab (after labels are added).
*   Visible in Dataplex Console.

This script creates **DATA_DOCUMENTATION** scans, which generate AI-powered insights visible in both the Dataplex Console and BigQuery's "Insights" tab (once the required labels are added).

---

## 🎯 Use Cases

*   **Automated documentation**: Generate insights for all tables in a data warehouse.
*   **Data discovery**: Help users understand unfamiliar datasets.
*   **AI-powered descriptions**: Get natural language explanations of your data.
*   **Onboarding**: Provide new team members with instant dataset context.
*   **Compliance**: Document data lineage and usage patterns.
*   **Data quality**: Receive AI recommendations on improving data quality.

---

## 🛠️ Advanced Usage

### Scan Multiple Datasets
```bash
#!/bin/bash

DATASETS=("sales_data" "marketing_data" "product_data")
PROJECT_ID="your-project-id"
LOCATION="us-central1"

for DATASET in "${DATASETS[@]}"; do
  echo "Scanning dataset: $DATASET"
  
  # Update script configuration
  sed -i "s/DATASET_ID=\".*\"/DATASET_ID=\"$DATASET\"/" dataplex_data_insights_scan.sh
  
  # Run script
  ./dataplex_data_insights_scan.sh
  
  echo "Completed $DATASET"
  echo ""
done
```

### Add Labels to Existing Scans
If you have scans that completed before labels were added, use the included helper script:
```bash
# The auto_labels.sh script finds all successful scans and adds labels
chmod +x auto_labels.sh
./auto_labels.sh
```
Or manually for a specific table:
```bash
bq update \
  --set_label dataplex-data-documentation-published-scan:SCAN_ID \
  --set_label dataplex-data-documentation-published-project:PROJECT_ID \
  --set_label dataplex-data-documentation-published-location:LOCATION \
  PROJECT_ID:DATASET_ID.TABLE_NAME
```

### Clean Up Old Scans
```bash
# Delete scans older than a certain date
gcloud dataplex datascans list \
  --project=YOUR_PROJECT_ID \
  --location=us-central1 \
  --filter="createTime<2024-01-01" \
  --format="value(name.basename())" | while read SCAN; do
  echo "Deleting $SCAN"
  gcloud dataplex datascans delete "$SCAN" \
    --project=YOUR_PROJECT_ID \
    --location=us-central1 \
    --quiet
done
```

### Delete All Scans for a Dataset
```bash
# Delete all scans associated with a specific dataset
gcloud dataplex datascans list \
  --project=YOUR_PROJECT_ID \
  --location=us-central1 \
  --format="value(name.basename(),data.resource)" | \
  grep "YOUR_DATASET" | \
  awk '{print $1}' | while read SCAN; do
  echo "Deleting $SCAN"
  gcloud dataplex datascans delete "$SCAN" \
    --project=YOUR_PROJECT_ID \
    --location=us-central1 \
    --quiet
done
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
1.  Fork the repository.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/url?sa=E&q=LICENSE) file for details.

---

## 🙏 Acknowledgments

*   Built for [Google Cloud Dataplex](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdataplex).
*   Uses [BigQuery](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fbigquery) and [Data Catalog](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdata-catalog).
*   Inspired by the need for automated data documentation.

---

## 📧 Support

If you encounter issues:
1.  Check the [Troubleshooting](#-troubleshooting) section.
2.  Review [Dataplex documentation](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdataplex%2Fdocs).
3.  Open an issue in this repository.
4.  Check existing issues for solutions.

---

## 🔗 Related Resources

*   [Dataplex Data Documentation](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdataplex%2Fdocs%2Fdata-documentation)
*   [Dataplex REST API Reference](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdataplex%2Fdocs%2Freference%2Frest)
*   [BigQuery Insights](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fbigquery%2Fdocs%2Finsights)
*   [gcloud dataplex datascans commands](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fsdk%2Fgcloud%2Freference%2Fdataplex%2Fdatascans)
*   [BigQuery Labels](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fbigquery%2Fdocs%2Flabels-intro)

---

## 💡 Tips & Best Practices

*   **Run during off-hours**: Scans consume resources, schedule during low-traffic periods.
*   **Monitor costs**: Data Documentation scans are billed - check pricing.
*   **Batch processing**: The script handles multiple tables efficiently.
*   **Error handling**: Failed scans are reported - check error messages for details.
*   **Re-running scans**: Safe to re-run on same tables - creates new scans with timestamps.
*   **Clean up regularly**: Delete old scans to reduce clutter.
*   **Label verification**: Always verify labels were added for insights to appear in BigQuery.
*   **Regional consistency**: Keep scans in the same region as your BigQuery dataset.
*   **View both UIs**: Check both Dataplex Console and BigQuery for complete insights.

---

## 📊 Example Output

```
==========================================
Dataplex Data Documentation Scan
Complete Working Version with Auto-Labels
==========================================

Configuration:
  Project: my-project
  Dataset: sales_data
  Location: us-central1

Step 1: Authenticating...
✓ Authenticated

Step 2: Setting project context...
✓ Project set

Step 3: Getting tables/views from dataset...
✓ Found 5 item(s) to scan:

   • customers
   • orders
   • products
   • transactions
   • revenue_summary

Create and run scans for all items? (y/n): y

==========================================
Step 4: Creating and running scans...
==========================================

[1/5] customers
   Scan ID: datadoc-customers-1775579456
   ✓ Creation operation started
   ⏳ Waiting for operation to complete...
   ✓ Scan created successfully
   🚀 Triggering scan execution...
   ✓ Scan started (Status: PENDING)
   📝 Adding documentation labels to table...
   ✓ Labels added - insights will appear in BigQuery

[2/5] orders
   Scan ID: datadoc-orders-1775579489
   ✓ Creation operation started
   ⏳ Waiting for operation to complete...
   ✓ Scan created successfully
   🚀 Triggering scan execution...
   ✓ Scan started (Status: PENDING)
   📝 Adding documentation labels to table...
   ✓ Labels added - insights will appear in BigQuery

...

==========================================
✓ SCAN CREATION COMPLETE!
==========================================

Summary:
  Total processed: 5
  Successfully started: 5
  Failed: 0

==========================================
Checking scan execution status...
==========================================

⏳ datadoc-customers-1775579456: PENDING
⏳ datadoc-orders-1775579489: PENDING
🏃 datadoc-products-1775579523: RUNNING
⏳ datadoc-transactions-1775579556: PENDING
⏳ datadoc-revenue-summary-1775579589: PENDING

==========================================
Next Steps:
==========================================

1. ⏱️  Wait 5-10 minutes for scans to complete

2. 📊 View insights in BigQuery:
   • Go to: https://console.cloud.google.com/bigquery?project=my-project
   • Navigate to dataset: sales_data
   • Click on any table/view
   • Click the 'Insights' tab
   • AI-generated insights should appear!

3. 🔍 Check scan status:
   gcloud dataplex datascans list \
     --project=my-project \
     --location=us-central1 \
     --sort-by=~createTime \
     --limit=20

==========================================
🎉 All done! Insights will appear in BigQuery once scans complete!
==========================================
```

---

## 🎓 Learning Resources

*   [Understanding Dataplex Data Documentation](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdataplex%2Fdocs%2Fdata-documentation)
*   [BigQuery Insights Overview](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fbigquery%2Fdocs%2Finsights)
*   [Dataplex Best Practices](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdataplex%2Fdocs%2Fbest-practices)
*   [Data Catalog Tagging](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdata-catalog%2Fdocs%2Ftags)

---

## ❓ FAQ

**Q: Do I need to add labels manually?**\
A: No, the script automatically adds the required labels after each scan starts.

**Q: Can I scan views or only tables?**\
A: Both! The script works with tables, views, materialized views, and external tables.

**Q: How long do scans take?**\
A: Typically 5-15 minutes depending on data size and complexity.

**Q: Are scans free?**\
A: No, Data Documentation scans are billed. Check [Dataplex pricing](https://www.google.com/url?sa=E&q=https%3A%2F%2Fcloud.google.com%2Fdataplex%2Fpricing).

**Q: Can I re-run scans?**\
A: Yes, you can safely re-run scans. The script creates new scans with timestamps.

**Q: Why use REST API instead of pure gcloud?**\
A: The REST API ensures compatibility across gcloud versions, while gcloud is used for reliable scan execution.

**Q: What if insights don't appear?**\
A: Check that: (1) Scan succeeded, (2) Labels were added, (3) You have datacatalog.viewer role, (4) Wait 10-15 minutes.

---

**Made with ❤️ for the Google Cloud community**

**Star ⭐ this repo if it helped you!**
