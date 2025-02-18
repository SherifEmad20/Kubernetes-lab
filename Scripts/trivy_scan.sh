#!/bin/bash

# Check if the required arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <docker-image>"
    exit 1
fi

# Assign the Docker image argument to a variable
DOCKER_IMAGE=$1

# Define output file names
TRIVY_OUTPUT_JSON="trivy_output.json"
TRIVY_OUTPUT_CSV="trivy_output.csv"
TRIVY_OUTPUT_XLSX="trivy_output.xlsx"

# Run Trivy to scan the Docker image and output results as JSON
trivy image --format json --output "$TRIVY_OUTPUT_JSON" "$DOCKER_IMAGE"

# Check if the Trivy scan was successful
if [ $? -ne 0 ]; then
    echo "Trivy scan failed. Please check the Docker image name and try again."
    exit 2
fi

# Extract relevant fields using jq and convert to CSV format
jq -r '(
    ["Library", "Vulnerability", "Severity", "Status", "Installed Version", "Fixed Version", "Title"] | @csv
  ),
  (.Results[]?.Vulnerabilities[]? | 
    [.PkgName, .VulnerabilityID, .Severity, .Status, .InstalledVersion, .FixedVersion, .Title] | @csv
  )' "$TRIVY_OUTPUT_JSON" > "$TRIVY_OUTPUT_CSV"

# Check if jq processing was successful
if [ $? -ne 0 ]; then
    echo "Error processing Trivy output with jq."
    exit 3
fi

# Convert the CSV file to Excel format using csvkit
csvjson "$TRIVY_OUTPUT_CSV" | in2csv --format xlsx > "$TRIVY_OUTPUT_XLSX"

# Check if csvkit processing was successful
if [ $? -ne 0 ]; then
    echo "Error converting CSV to Excel format. Ensure csvkit is installed."
    exit 4
fi

# Calculate total vulnerabilities and compliance issues
TOTAL_VULNERABILITIES=$(jq '[.Results[]?.Vulnerabilities[]?] | length' "$TRIVY_OUTPUT_JSON")
TOTAL_COMPLIANCES=$(jq '[.Results[]?.Misconfigurations[]?] | length' "$TRIVY_OUTPUT_JSON")

# Display the results
echo "Trivy scan completed for image: $DOCKER_IMAGE"
echo "Total Vulnerabilities: $TOTAL_VULNERABILITIES"
echo "Total Compliances: $TOTAL_COMPLIANCES"
echo "Generated Excel File: $TRIVY_OUTPUT_XLSX"

# Clean up intermediate files
rm "$TRIVY_OUTPUT_JSON" "$TRIVY_OUTPUT_CSV"

exit 0