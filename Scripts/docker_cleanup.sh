#!/bin/bash

# Log file for script execution
LOG_FILE="/var/log/docker_cleanup.log"

# Define the threshold for storage usage (80%)
THRESHOLD=80

# Get the current storage usage of the relevant filesystem (adjust the path if necessary)
STORAGE_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# Check if the storage usage exceeds the threshold
if [ "$STORAGE_USAGE" -lt "$THRESHOLD" ]; then
  exit 0
fi

echo "#############################################################################" >> "$LOG_FILE"
# Log the start time of the cleanup
echo "Starting Docker cleanup at $(date)" >> "$LOG_FILE"
echo "Storage usage is at ${STORAGE_USAGE}%. Exceeding the threshold of ${THRESHOLD}%. Proceeding with cleanup." >> "$LOG_FILE"
echo "#############################################################################" >> "$LOG_FILE"

# Stop and remove all containers
if docker ps -aq | grep -q .; then
  echo "Stopping all running containers..." >> "$LOG_FILE"
  docker stop $(docker ps -aq) >> "$LOG_FILE" 2>&1
  echo "Removing all containers..." >> "$LOG_FILE"
  docker rm $(docker ps -aq) >> "$LOG_FILE" 2>&1
else
  echo "No containers to stop or remove." >> "$LOG_FILE"
fi

# Remove all images
if docker images -q | grep -q .; then
  echo "Removing all Docker images..." >> "$LOG_FILE"
  docker rmi -f $(docker images -q) >> "$LOG_FILE" 2>&1
else
  echo "No Docker images to remove." >> "$LOG_FILE"
fi

# Remove unused volumes
if docker volume ls -q | grep -q .; then
  echo "Removing all unused Docker volumes..." >> "$LOG_FILE"
  docker volume rm $(docker volume ls -q) >> "$LOG_FILE" 2>&1
else
  echo "No unused Docker volumes to remove." >> "$LOG_FILE"
fi

# Remove unused networks
if docker network ls -q | grep -q .; then
  echo "Removing all unused Docker networks..." >> "$LOG_FILE"
  docker network prune -f >> "$LOG_FILE" 2>&1
else
  echo "No unused Docker networks to remove." >> "$LOG_FILE"
fi

# Log the completion of the cleanup
echo "#############################################################################" >> "$LOG_FILE"
echo "Docker cleanup completed at $(date)" >> "$LOG_FILE"
echo "#############################################################################" >> "$LOG_FILE"
