# Dataplex Data Insights Scanner

A bash script to programmatically create and run [Google Cloud Dataplex](https://cloud.google.com/dataplex) Data Documentation scans on all tables or views in a BigQuery dataset using the REST API.

## 🎯 What This Does

This script automates the process of:
1. ✅ Creating Dataplex Data Documentation scans for all tables/views in a BigQuery dataset
2. ✅ Running the scans automatically
3. ✅ Generating AI-powered insights that appear in BigQuery's "Insights" tab
4. ✅ Publishing documentation to Data Catalog

## 📋 Prerequisites

Before running this script, ensure you have:

- ✅ **Google Cloud SDK** installed ([Installation Guide](https://cloud.google.com/sdk/docs/install))
- ✅ **BigQuery CLI (bq)** installed (comes with gcloud)
- ✅ **Authenticated** with gcloud: `gcloud auth login`
- ✅ **Appropriate IAM permissions**:
  - `roles/dataplex.editor` or `roles/dataplex.admin`
  - `roles/bigquery.dataViewer` or higher on the dataset
  - `roles/datacatalog.editor` (for catalog publishing)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/optidus/data_insights_scan.git
cd data_insights_scan
2. Configure the Script
Open dataplex_data_insights_scan.sh and update these variables:

PROJECT_ID="your-gcp-project-id"
DATASET_ID="your_bigquery_dataset"
LOCATION="us-central1"  # Your preferred region
3. Make the Script Executable
chmod +x dataplex_scan_views.sh
4. Run the Script
./dataplex_scan_views.sh
The script will:

List all views/tables in the dataset
Ask for confirmation
Create and run scans for each item
Display progress and results
⚙️ Configuration Options
Scan Tables Instead of Views
By default, the script scans views only. To scan tables or all objects, modify the TABLE_FILTER variable:

# For VIEWS only (default)
TABLE_FILTER='$2 == "VIEW" {print $1}'

# For TABLES only
TABLE_FILTER='$2 == "TABLE" {print $1}'

# For ALL tables and views
TABLE_FILTER='NR>1 && $1 != "tableId" {print $1}'
Change Region
Dataplex requires a specific regional location (not multi-region). Common options:

LOCATION="us-central1"      # Iowa
LOCATION="us-east1"         # South Carolina
LOCATION="europe-west1"     # Belgium
LOCATION="asia-southeast1"  # Singapore
See Dataplex locations for all available regions.

📊 Viewing Results
In BigQuery Console
Go to BigQuery Console
Navigate to your dataset
Click on a table/view
Click the "Insights" tab
Wait 2-5 minutes for scans to complete
In Dataplex Console
Go to Dataplex Data Scans
Filter by your project
View scan status and results
Using gcloud CLI
# List all scans
gcloud dataplex data-scans list --project=YOUR_PROJECT_ID --location=us-central1

# View specific scan
gcloud dataplex data-scans describe SCAN_ID --project=YOUR_PROJECT_ID --location=us-central1
🔧 Troubleshooting
"Failed to get authentication token"
gcloud auth login
gcloud auth application-default login
"No tables/views found"
Verify the dataset name is correct
Check you have read permissions on the dataset
Ensure TABLE_FILTER matches your target objects
"Permission denied" errors
Ensure you have the required IAM roles:

# Grant yourself Dataplex Editor role
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="user:YOUR_EMAIL@example.com" \
  --role="roles/dataplex.editor"
"Location not found" errors
Use a specific regional location (e.g., us-central1) instead of multi-regional (e.g., us).

📖 How It Works
The script uses the Dataplex REST API to:

Authenticate using your gcloud credentials
List tables/views from the specified BigQuery dataset using bq ls
Create scans via POST request to the Dataplex API
Poll operations to wait for scan creation to complete (asynchronous)
Run scans via POST request to trigger the scan execution
Report results with success/failure counts
Why REST API Instead of gcloud CLI?
The gcloud dataplex commands may not be available in all gcloud SDK versions. Using the REST API directly ensures compatibility and provides more control over the scan creation process.

🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

Fork the repository
Create your feature branch (git checkout -b feature/AmazingFeature)
Commit your changes (git commit -m 'Add some AmazingFeature')
Push to the branch (git push origin feature/AmazingFeature)
Open a Pull Request
📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

🙏 Acknowledgments
Built for Google Cloud Dataplex
Uses BigQuery and Data Catalog
📧 Support
If you encounter issues:

Check the Troubleshooting section
Review Dataplex documentation
Open an issue in this repository
🔗 Related Resources
Dataplex Data Documentation
Dataplex REST API Reference
BigQuery Insights
Made with ❤️ for the Google Cloud community
