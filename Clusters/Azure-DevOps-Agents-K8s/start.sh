#!/bin/bash
# Exit immediately if any command fails
set -e

# Validate if AZP_URL is set, otherwise exit with an error
if [ -z "$AZP_URL" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

# Check if AZP_TOKEN_FILE is set, otherwise check for AZP_TOKEN
if [ -z "$AZP_TOKEN_FILE" ]; then
  if [ -z "$AZP_TOKEN" ]; then
    echo 1>&2 "error: missing AZP_TOKEN environment variable"
    exit 1
  fi

  # Store the token in a file for authentication
  AZP_TOKEN_FILE=/azp/.token
  echo -n $AZP_TOKEN > "$AZP_TOKEN_FILE"
fi

# Unset AZP_TOKEN from the environment to enhance security
unset AZP_TOKEN

# Create the work directory if it is defined
if [ -n "$AZP_WORK" ]; then
  mkdir -p "$AZP_WORK"
fi

# Remove any existing agent installation and create a fresh directory
rm -rf /azp/agent
mkdir /azp/agent
cd /azp/agent

# Allow the agent to run as root
export AGENT_ALLOW_RUNASROOT="1"

# Define a cleanup function to remove the agent on exit
cleanup() {
  if [ -e config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    # Unregister the agent from Azure DevOps
    ./config.sh remove --unattended \
      --auth PAT \
      --token $(cat "$AZP_TOKEN_FILE")
  fi
}

# Function to print section headers in light cyan color
print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

# Ignore the token variables in the agent environment
export VSO_AGENT_IGNORE=AZP_TOKEN,AZP_TOKEN_FILE

print_header "1. Determining matching Azure Pipelines agent..."

# Fetch the latest agent package from Azure DevOps API
AZP_AGENT_RESPONSE=$(curl -LsS \
  -u user:$(cat "$AZP_TOKEN_FILE") \
  -H 'Accept:application/json;api-version=3.0-preview' \
  "$AZP_URL/_apis/distributedtask/packages/agent?platform=linux-arm64")

# Extract the latest version's download URL using jq (JSON parser)
if echo "$AZP_AGENT_RESPONSE" | jq . >/dev/null 2>&1; then
  AZP_AGENTPACKAGE_URL=$(echo "$AZP_AGENT_RESPONSE" \
    | jq -r '.value | map([.version.major,.version.minor,.version.patch,.downloadUrl]) | sort | .[length-1] | .[3]')
fi

# Validate if the agent package URL is retrieved, otherwise exit
if [ -z "$AZP_AGENTPACKAGE_URL" -o "$AZP_AGENTPACKAGE_URL" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent - check that account '$AZP_URL' is correct and the token is valid for that account"
  exit 1
fi

print_header "2. Downloading and installing Azure Pipelines agent..."
echo "$AZP_AGENTPACKAGE_URL"

# Download and extract the agent package
curl -LsS $AZP_AGENTPACKAGE_URL | tar -xz & wait $!

# Source the environment variables from the agent package
source ./env.sh

# Set up cleanup traps for termination signals
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

print_header "3. Configuring Azure Pipelines agent..."

# Run the agent configuration script in unattended mode
./config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "$AZP_URL" \
  --auth PAT \
  --token $(cat "$AZP_TOKEN_FILE") \
  --pool "${AZP_POOL:-Default}" \
  --work "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula & wait $!

# Remove the token file after successful configuration to enhance security
rm $AZP_TOKEN_FILE

print_header "4. Running Azure Pipelines agent..."

# `exec` the node runtime so it's aware of TERM and INT signals
# AgentService.js understands how to handle agent self-update and restart
exec ./externals/node/bin/node ./bin/AgentService.js interactive