# SonarQube Setup Using Kubernetes YAML Files

This guide provides step-by-step instructions for setting up SonarQube on a Kubernetes cluster using provided YAML manifests. Follow the prerequisites and deployment steps below to get started.

## Prerequisites

- A running Kubernetes cluster (e.g. k3s, minikube, or a managed cluster)
- kubectl configured to interact with the cluster

## Setup

### Create a Namespace

Create a dedicated namespace for SonarQube:

```bash
kubectl create namespace sonarqube
```

### Apply Persistent Volume Claims

Ensure persistent storage for SonarQube and PostgreSQL:

```bash
kubectl apply -f pvcs.yaml
```

### Deploy PostgreSQL

Deploy the PostgreSQL database:

```bash
kubectl apply -f postgres.yaml
```

### Deploy SonarQube StatefulSet

Deploy the SonarQube application:

```bash
kubectl apply -f statefulset.yaml
```

### Expose SonarQube Service

Create a service to expose SonarQube internally:

```bash
kubectl apply -f service.yaml
```

### Configure Ingress

Set up an ingress resource to allow external access to SonarQube:

```bash
kubectl apply -f ingress.yaml
```

### Verify Deployment

Check if the pods are running:

```bash
kubectl get pods -n sonarqube
```

Check if the services are running:

```bash
kubectl get svc -n sonarqube
```

### Access SonarQube UI

If using Ingress, update your local hosts file:

```bash
sudo vi /etc/hosts
```

Add the following line, replacing `<Load-Balancer-Host>` with the actual address:

```
<Load-Balancer-Host> sonarqube-cluster.local
```

Then, access SonarQube in your browser:

```
http://sonarqube-cluster.local
```

### Default Login Credentials

Once SonarQube is accessible, log in using:

```
Username: admin
Password: admin
```

## Conclusion

SonarQube is now deployed on your Kubernetes cluster. You can configure additional settings in the UI and connect it to your CI/CD pipelines for code quality analysis.
