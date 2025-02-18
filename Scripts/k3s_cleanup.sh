#!/bin/bash

# Log file for script execution
LOG_FILE="/var/log/k3s_cleanup.log"

# Define the threshold for storage usage (80%)
THRESHOLD=80

# Get the current storage usage of the relevant filesystem (adjust the path if necessary)
STORAGE_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# Check if the storage usage exceeds the threshold
if [ "$STORAGE_USAGE" -lt "$THRESHOLD" ]; then
  exit 0
fi

echo "#############################################################################" >> "$LOG_FILE"
echo "Starting PVC cleanup at $(date)" >> "$LOG_FILE"
echo "Storage usage is at ${STORAGE_USAGE}%. Exceeding the threshold of ${THRESHOLD}%. Proceeding with cleanup." >> "$LOG_FILE"
echo "#############################################################################" >> "$LOG_FILE"

# Define the namespaces to clean
NAMESPACE_FILTER=("build-agent-ubuntu24 build-agent-amazon-linux")  # Add more namespaces as needed

# Loop through namespaces
for NAMESPACE in "${NAMESPACE_FILTER[@]}"; do
  echo "---------------------------------------------------------------------------------------------------------------" >> "$LOG_FILE"
  echo "Processing namespace: $NAMESPACE" >> "$LOG_FILE"
  echo "---------------------------------------------------------------------------------------------------------------" >> "$LOG_FILE"

  # Get PVCs in the current namespace
  PVC_LIST=$(kubectl get pvc -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name} {.spec.volumeName}{"\n"}{end}')

  if [ -z "$PVC_LIST" ]; then
    echo "No PVCs found in namespace: $NAMESPACE. Skipping." >> "$LOG_FILE"
    continue
  fi

  # Loop through PVCs and clean their contents
  while read -r PVC_NAME VOLUME_NAME; do
    if [ -n "$VOLUME_NAME" ]; then
      echo "---------------------------------------------------------------------------------------------------------------" >> "$LOG_FILE"
      echo "Cleaning PVC: $PVC_NAME in namespace: $NAMESPACE (Volume: $VOLUME_NAME)" >> "$LOG_FILE"
      echo "---------------------------------------------------------------------------------------------------------------" >> "$LOG_FILE"

      # Locate the PV path
      PV_PATH="/var/lib/kubelet/pods/*/volumes/*/$VOLUME_NAME"
      TARGET_PATH=$(find $PV_PATH -type d 2>/dev/null | head -n 1)

      if [ -d "$TARGET_PATH" ]; then
        echo "Found PVC directory: $TARGET_PATH" >> "$LOG_FILE"

        # Log the contents and storage usage before cleanup
        echo "Contents of PVC $PVC_NAME before cleanup:" >> "$LOG_FILE"
        ls -l "$TARGET_PATH" >> "$LOG_FILE" 2>&1
        echo "Storage usage of PVC $PVC_NAME before cleanup:" >> "$LOG_FILE"
        du -sh "$TARGET_PATH" >> "$LOG_FILE" 2>&1

        # Remove files inside the PVC directory
        echo "Removing contents of PVC: $PVC_NAME" >> "$LOG_FILE"
        rm -rf "$TARGET_PATH"/* >> "$LOG_FILE" 2>&1

        # Log the storage usage after cleanup
        echo "Storage usage of PVC $PVC_NAME after cleanup:" >> "$LOG_FILE"
        du -sh "$TARGET_PATH" >> "$LOG_FILE" 2>&1
      else
        echo "PVC path not found for $PVC_NAME. Skipping." >> "$LOG_FILE"
      fi
    fi
  done <<< "$PVC_LIST"
done

echo "#############################################################################" >> "$LOG_FILE"
echo "PVC cleanup completed at $(date)" >> "$LOG_FILE"
echo "#############################################################################" >> "$LOG_FILE"
