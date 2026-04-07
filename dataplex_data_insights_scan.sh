#!/bin/bash

# ============================================================
# Dataplex Data Documentation Scan - COMPLETE WORKING VERSION
# 
# This script creates and runs Dataplex Data Documentation scans
# for all views (or tables) in a BigQuery dataset.
# 
# INCLUDES: Automatic label addition for BigQuery insights!
# 
# Requirements:
# - gcloud CLI installed and authenticated
# - bq CLI installed
# - Appropriate permissions for Dataplex and BigQuery
# 
# Usage:
#   1. Update the variables below
#   2. Make executable: chmod +x dataplex_scan_views.sh
#   3. Run: ./dataplex_scan_views.sh
# ============================================================

# ============================================================
# CONFIGURATION - UPDATE THESE VALUES
# ============================================================

PROJECT_ID="YOUR_PROJECT_ID"           # Your GCP Project ID
DATASET_ID="YOUR_DATASET_ID"           # Your BigQuery dataset name
LOCATION="us-central1"                 # Dataplex location (e.g., us-central1, us-east1, europe-west1)

# Optional: Change this to filter tables instead of views
# For VIEWS: awk '$2 == "VIEW" {print $1}'
# For TABLES: awk '$2 == "TABLE" {print $1}'
# For ALL: awk 'NR>1 && $1 != "tableId" {print $1}'
TABLE_FILTER='NR>1 && $1 != "tableId" {print $1}'

# ============================================================
# SCRIPT START - NO CHANGES NEEDED BELOW THIS LINE
# ============================================================

echo "=========================================="
echo "Dataplex Data Documentation Scan"
echo "Complete Working Version with Auto-Labels"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Project: $PROJECT_ID"
echo "  Dataset: $DATASET_ID"
echo "  Location: $LOCATION"
echo ""

# Step 1: Authenticate
echo "Step 1: Authenticating..."
TOKEN=$(gcloud auth print-access-token 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "✗ Failed to get authentication token"
  echo ""
  echo "Please run: gcloud auth login"
  echo "Then try again."
  exit 1
fi

echo "✓ Authenticated"
echo ""

# Step 2: Set project in gcloud config
echo "Step 2: Setting project context..."
if ! gcloud config set project $PROJECT_ID --quiet 2>/dev/null; then
  echo "✗ Failed to set project"
  echo "Please verify the PROJECT_ID is correct"
  exit 1
fi
echo "✓ Project set"
echo ""

# Step 3: List tables/views
echo "Step 3: Getting tables/views from dataset..."
TABLES=$(bq ls --project_id=$PROJECT_ID $DATASET_ID 2>/dev/null | awk "$TABLE_FILTER")

if [ -z "$TABLES" ]; then
  echo "✗ No tables/views found in dataset: $DATASET_ID"
  echo ""
  echo "Available tables/views:"
  bq ls --project_id=$PROJECT_ID $DATASET_ID
  echo ""
  echo "Please verify:"
  echo "  1. Dataset name is correct"
  echo "  2. You have permissions to access the dataset"
  echo "  3. TABLE_FILTER is set correctly"
  exit 1
fi

TABLE_COUNT=$(echo "$TABLES" | wc -l)
echo "✓ Found $TABLE_COUNT item(s) to scan:"
echo ""
echo "$TABLES" | while read t; do 
  if [ ! -z "$t" ]; then
    echo "   • $t"
  fi
done
echo ""

# Step 4: Confirm
read -p "Create and run scans for all items? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Cancelled."
  exit 0
fi

echo ""
echo "=========================================="
echo "Step 4: Creating and running scans..."
echo "=========================================="
echo ""

CREATED=0
FAILED=0
SUCCESS=0
API_URL="https://dataplex.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/dataScans"

# Store scan IDs and table names for final verification and label addition
declare -a SCAN_IDS
declare -a TABLE_NAMES

echo "$TABLES" | while IFS= read -r TABLE_NAME; do
  # Skip empty lines
  if [ -z "$TABLE_NAME" ]; then
    continue
  fi
  
  ((CREATED++))
  TIMESTAMP=$(date +%s)
  CLEAN_TABLE_NAME=$(echo "$TABLE_NAME" | tr -cd '[:alnum:]-')
  SCAN_ID="datadoc-${CLEAN_TABLE_NAME}-${TIMESTAMP}"
   
  echo "[$CREATED/$TABLE_COUNT] $TABLE_NAME"
  echo "   Scan ID: $SCAN_ID"
   
  # Create scan using REST API with FIXED JSON (generationScopes as array)
  CREATE_RESPONSE=$(curl -s -X POST \
    "${API_URL}?dataScanId=${SCAN_ID}" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d @- <<EOF
{
  "data": {
    "resource": "//bigquery.googleapis.com/projects/${PROJECT_ID}/datasets/${DATASET_ID}/tables/${TABLE_NAME}"
  },
  "executionSpec": {
    "trigger": {
      "onDemand": {}
    }
  },
  "type": "DATA_DOCUMENTATION",
  "dataDocumentationSpec": {
    "generationScopes": ["ALL"],
    "catalogPublishingEnabled": true
  }
}
EOF
)
   
  # Check if there's an error in the response
  if echo "$CREATE_RESPONSE" | grep -q '"error"'; then
    echo "   ✗ Failed to create scan"
    ERROR_MSG=$(echo "$CREATE_RESPONSE" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
    echo "   Error: $ERROR_MSG"
    ((FAILED++))
    echo ""
    continue
  fi
  
  # Extract operation name and target
  OPERATION_NAME=$(echo "$CREATE_RESPONSE" | sed -n 's/.*"name": *"\([^"]*\)".*/\1/p' | head -1)
  TARGET_NAME=$(echo "$CREATE_RESPONSE" | sed -n 's/.*"target": *"\([^"]*\)".*/\1/p' | head -1)
  
  if [ -z "$OPERATION_NAME" ] || [ -z "$TARGET_NAME" ]; then
    echo "   ✗ Failed to parse operation response"
    ((FAILED++))
    echo ""
    continue
  fi
  
  echo "   ✓ Creation operation started"
  echo "   ⏳ Waiting for operation to complete..."
   
  # Poll the operation until it's done (max 30 seconds)
  OPERATION_DONE=false
  for i in {1..15}; do
    sleep 2
    
    OPERATION_STATUS=$(curl -s -X GET \
      "https://dataplex.googleapis.com/v1/${OPERATION_NAME}" \
      -H "Authorization: Bearer $TOKEN" 2>/dev/null)
    
    if echo "$OPERATION_STATUS" | grep -q '"done": true'; then
      # Check if operation has error
      if echo "$OPERATION_STATUS" | grep -q '"error"'; then
        echo "   ✗ Operation failed"
        ERROR_MSG=$(echo "$OPERATION_STATUS" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        echo "   Error: $ERROR_MSG"
        OPERATION_DONE=false
        break
      else
        echo "   ✓ Scan created successfully"
        OPERATION_DONE=true
        break
      fi
    fi
    
    if [ $i -eq 15 ]; then
      echo "   ⚠ Operation still running after 30s, will try to run scan anyway..."
      OPERATION_DONE=true
    fi
  done
  
  if [ "$OPERATION_DONE" = false ]; then
    ((FAILED++))
    echo ""
    continue
  fi
   
  # Small additional delay
  sleep 2
   
  # Run the scan using gcloud
  echo "   🚀 Triggering scan execution..."
  
  if gcloud dataplex datascans run "$SCAN_ID" \
    --project="$PROJECT_ID" \
    --location="$LOCATION" \
    --quiet 2>/dev/null; then
    
    # Verify job was created
    sleep 3
    JOB_STATUS=$(gcloud dataplex datascans jobs list \
      --datascan="$SCAN_ID" \
      --project="$PROJECT_ID" \
      --location="$LOCATION" \
      --limit=1 \
      --format="value(state)" 2>/dev/null)
    
    if [ ! -z "$JOB_STATUS" ]; then
      echo "   ✓ Scan started (Status: $JOB_STATUS)"
      
      # Add labels to the table/view for publishing results to BigQuery
      echo "   📝 Adding documentation labels to table..."
      if bq update \
        --set_label dataplex-data-documentation-published-scan:"${SCAN_ID}" \
        --set_label dataplex-data-documentation-published-project:"${PROJECT_ID}" \
        --set_label dataplex-data-documentation-published-location:"${LOCATION}" \
        "${PROJECT_ID}:${DATASET_ID}.${TABLE_NAME}" 2>/dev/null; then
        echo "   ✓ Labels added - insights will appear in BigQuery"
      else
        echo "   ⚠️  Failed to add labels (insights may not appear in BigQuery)"
      fi
      
      ((SUCCESS++))
      SCAN_IDS+=("$SCAN_ID")
      TABLE_NAMES+=("$TABLE_NAME")
    else
      echo "   ⚠️  Scan triggered but job status unknown"
      ((SUCCESS++))
      SCAN_IDS+=("$SCAN_ID")
      TABLE_NAMES+=("$TABLE_NAME")
    fi
  else
    echo "   ✗ Failed to trigger scan execution"
    ((FAILED++))
  fi
   
  echo ""
done

echo "=========================================="
echo "✓ SCAN CREATION COMPLETE!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  Total processed: $CREATED"
echo "  Successfully started: $SUCCESS"
echo "  Failed: $FAILED"
echo ""

if [ $SUCCESS -gt 0 ]; then
  echo "=========================================="
  echo "Checking scan execution status..."
  echo "=========================================="
  echo ""
  
  # Wait a moment for jobs to initialize
  sleep 5
  
  for SCAN_ID in "${SCAN_IDS[@]}"; do
    JOB_INFO=$(gcloud dataplex datascans jobs list \
      --datascan="$SCAN_ID" \
      --project="$PROJECT_ID" \
      --location="$LOCATION" \
      --limit=1 \
      --format="value(name.basename(),state)" 2>/dev/null)
    
    if [ ! -z "$JOB_INFO" ]; then
      JOB_ID=$(echo "$JOB_INFO" | awk '{print $1}')
      JOB_STATE=$(echo "$JOB_INFO" | awk '{print $2}')
      
      STATUS_ICON="⏳"
      if [ "$JOB_STATE" = "SUCCEEDED" ]; then
        STATUS_ICON="✅"
      elif [ "$JOB_STATE" = "FAILED" ]; then
        STATUS_ICON="❌"
      elif [ "$JOB_STATE" = "RUNNING" ]; then
        STATUS_ICON="🏃"
      fi
      
      echo "$STATUS_ICON $SCAN_ID: $JOB_STATE"
    else
      echo "⚠️  $SCAN_ID: No job found"
    fi
  done
  
  echo ""
fi

echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. ⏱️  Wait 5-10 minutes for scans to complete"
echo ""
echo "2. 📊 View insights in BigQuery:"
echo "   • Go to: https://console.cloud.google.com/bigquery?project=$PROJECT_ID"
echo "   • Navigate to dataset: $DATASET_ID"
echo "   • Click on any table/view"
echo "   • Click the 'Insights' tab"
echo "   • AI-generated insights should appear!"
echo ""
echo "3. 🔍 Check scan status:"
echo "   gcloud dataplex datascans list \\"
echo "     --project=$PROJECT_ID \\"
echo "     --location=$LOCATION \\"
echo "     --sort-by=~createTime \\"
echo "     --limit=20"
echo ""
echo "4. ✅ Verify labels were added:"
echo "   bq show --format=prettyjson \\"
echo "     $PROJECT_ID:$DATASET_ID.TABLE_NAME | \\"
echo "     grep dataplex-data-documentation"
echo ""
echo "=========================================="
echo "🎉 All done! Insights will appear in BigQuery once scans complete!"
echo "=========================================="
