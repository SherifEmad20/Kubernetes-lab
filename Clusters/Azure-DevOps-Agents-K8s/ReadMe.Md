# Deploying an Azure DevOps Build Agent on Kubernetes

This guide explains how to deploy an Azure DevOps build agent on a Kubernetes cluster using a **custom Docker image**, a **StatefulSet**, and a **startup script**.

## **1. Overview**

An Azure DevOps self-hosted agent allows you to run your builds and deployments on your own infrastructure. By running the agent inside a Kubernetes cluster, you can scale efficiently while maintaining control over the environment.

## **2. Prerequisites**

Before proceeding, ensure you have:

- A Kubernetes cluster (minikube, AKS, or any other K8s setup)
- `kubectl` installed and configured
- Docker installed
- An Azure DevOps organization and a Personal Access Token (PAT)

---

## **3. Creating the `start.sh` Script**

The `start.sh` script initializes and configures the Azure DevOps agent inside the container.

### **`start.sh`**

```bash
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
  "$AZP_URL/_apis/distributedtask/packages/agent?platform=<OS-Architecture>")  # This specifies the agent version compatibility with the hardware and OS. Modify it to match the needed distribution. For example: Linux-x64

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
```

---

## **4. Creating the Build Agent Dockerfile**

The Dockerfile defines the environment where the build agent will run and the tools needed for the tech stack.

### **`Dockerfile`**

```dockerfile
FROM amazonlinux:latest
SHELL ["/bin/bash", "-c"]

####################################
# Install dependencies needed by the agent
RUN yum update -y \
    && yum install -y unzip zip gzip bzip2 vim gettext gnupg tar findutils libicu

####################################
# Install Docker
RUN yum install -y docker \
    && ln -s /usr/bin/docker /usr/local/bin/docker

####################################
# Copy Start Script
COPY ./start.sh .
RUN chmod +x start.sh

####################################
# Define volumes for build caching
VOLUME /src
VOLUME /var/run/docker.sock

####################################
# Clean uneeded packages
RUN yum clean packages -y

####################################
# Start The Build Agent
CMD ["./start.sh"]

```

---

## **5. Deploying the Agent Using Kubernetes StatefulSet And ConfigMaps**

The StatefulSet deploys the agent container on the Kubernetes cluster and the ConfigMap contains the environment variables needed by the StatefulSet.

### **`statefulset.yaml`**

```yaml
# Service account used by the StatefulSet
apiVersion: v1
kind: ServiceAccount
metadata:
  name: build-agent
  namespace: build-agent
---
# ConfigMap for storing environment variables required by the build agent
apiVersion: v1
kind: ConfigMap
metadata:
  name: build-agent-environment # Name of the ConfigMap
  namespace: build-agent # Namespace where the ConfigMap is created

data:
  AZP_POOL: <AZP_POOL> # Azure DevOps agent pool
  AZP_TOKEN: <AZP_PAT> # Personal Access Token (PAT) for authentication
  AZP_URL: https://dev.azure.com/<ORG> # Azure DevOps organization URL
  AZP_WORK: /work # Directory where agent workspaces are stored

---
# StatefulSet for deploying an Azure DevOps build agent in Kubernetes
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: build-agent # Generic name for the StatefulSet
  namespace: build-agent # Namespace where the StatefulSet is deployed

spec:
  serviceName: build-agent # Associated service name
  selector:
    matchLabels:
      app: build-agent # Label selector for identifying managed pods

  replicas: 1 # Number of agent instances to deploy (adjust as needed)
  template:
    metadata:
      labels:
        app: build-agent # Label to identify the pods

    spec:
      serviceAccountName: build-agent-service-account # Service account for pod permissions
      containers:
        - name: build-agent # Name of the container
          securityContext:
            privileged: true # Run container in privileged mode if required
          image: <IMAGE_NAME>:<IMAGE_TAG> # Placeholder for build agent image
          imagePullPolicy: Always # Always pull the latest image

          env:
            - name: AZP_AGENT_NAME # Assign the pod name as the agent name
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          envFrom:
            - configMapRef:
                name: build-agent-environment # Load environment variables from ConfigMap

          volumeMounts:
            - name: dockersock # Mount Docker socket for in-container builds
              mountPath: /var/run/docker.sock
            - name: agent-work # Persistent volume for agent workspace
              mountPath: /work

      volumes:
        - name: dockersock
          hostPath:
            path: /var/run/docker.sock # Mount host Docker socket inside the container

  volumeClaimTemplates:
    - metadata:
        name: agent-work # Persistent volume claim for agent workspace
      spec:
        accessModes: ["ReadWriteOnce"] # Single node access mode
        storageClassName: standard # Generic storage class
        resources:
          requests:
            storage: 6Gi # Define required storage capacity

# This StatefulSet can be customized for various CI/CD use cases by modifying the environment variables and storage settings.
```

---

## **6. Deploying to Kubernetes**

1. **Build and push the Docker image**:

   ```bash
   docker build -t <IMAGE_NAME>:<IMAGE_TAG> .
   docker push <IMAGE_NAME>:<IMAGE_TAG>
   ```

2. **Create The Build Agent Namespace**:

   ```bash
   kubectl create ns build-agent
   ```

3. **Apply the ServiceAccount**:

   ```bash
   kubectl apply -f serviceaccount.yaml
   ```

4. **Apply the ConfigMap**:

   ```bash
   kubectl apply -f configmap.yaml
   ```

5. **Deploy the StatefulSet**:

   ```bash
   kubectl apply -f statefulset.yaml
   ```

6. **Verify the deployment**:
   ```bash
   kubectl get pods -n build-agent
   ```

---

## **7. Conclusion**

This setup allows you to run an Azure DevOps agent on a Kubernetes cluster. You can scale the agents by increasing the `replicas` count in the StatefulSet which will allow parallel CI/CD runs and resources utilization if you have only one server, and you can customize the image to fit your CI/CD pipeline needs.

---

### **References**

- [Azure DevOps Agent Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops)
