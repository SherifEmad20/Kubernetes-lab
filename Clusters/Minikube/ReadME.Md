# Installation of Minikube on macOS

## Requirements:

- Homebrew package manager
- VM Manager (HyperKit or VirtualBox)

### Steps:

1. **Install Homebrew on macOS**

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install Minikube**

   ```bash
   brew install minikube
   ```

3. **Install a Hypervisor (HyperKit recommended)**

   ```bash
   brew install hyperkit
   ```

4. **Start Minikube with HyperKit driver**

   ```bash
   minikube start --driver=hyperkit
   ```

5. **Verify Minikube status**
   ```bash
   minikube status
   ```

6. **Enable kubectl (if not already installed)**
   ```bash
   brew install kubectl
   ```

7. **Check Kubernetes cluster information**
   ```bash
   kubectl cluster-info
   ```

8. **Access Minikube Dashboard**
   ```bash
   minikube dashboard
   ```

### Modifying VM Resources

To allocate specific resources to Minikube:
```bash
minikube stop
minikube config set memory 8192  # Set 8GB RAM
minikube config set cpus 4       # Set 4 CPU cores
minikube config set disk-size 50GB
minikube start
```

### Deploying Applications on Minikube

1. **Create a sample deployment**
   ```bash
   kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
   ```

2. **Expose the deployment**
   ```bash
   kubectl expose deployment hello-minikube --type=NodePort --port=8080
   ```

3. **Retrieve the Minikube service URL**
   ```bash
   minikube service hello-minikube --url
   ```

### Setting Up Multi-Node Minikube Cluster

#### Create a Multi-Node Cluster

To start a Minikube cluster with multiple nodes:
```bash
minikube start --nodes 3 --driver=hyperkit
```

#### Assign Node Labels

To label nodes in the cluster:
```bash
kubectl label nodes minikube-m02 node-role.kubernetes.io/worker=worker
kubectl label nodes minikube-m03 node-role.kubernetes.io/worker=worker
```

#### Check Node Status

To list all nodes in the cluster:
```bash
kubectl get nodes
```

#### Deploy Workloads Across Nodes

To deploy a workload across different nodes:
```bash
kubectl create deployment multinode-app --image=nginx
kubectl scale deployment multinode-app --replicas=3
```

#### Expose the Deployment

To expose the deployment via a service:
```bash
kubectl expose deployment multinode-app --type=NodePort --port=80
```

To retrieve the service URL:
```bash
minikube service multinode-app --url
```

### Stopping and Deleting Minikube Cluster

To stop Minikube:
```bash
minikube stop
```

To delete Minikube completely:
```bash
minikube delete
```

### Troubleshooting

1. **Check logs**
   ```bash
   minikube logs
   ```

2. **Restart Minikube**
   ```bash
   minikube stop && minikube delete && minikube start
   ```

---
🎯 **Your Minikube multi-node cluster is now ready!**
