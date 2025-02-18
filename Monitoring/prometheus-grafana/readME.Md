# Monitoring Setup Using Prometheus and Grafana on Kubernetes

This guide provides step-by-step instructions for setting up Prometheus and Grafana for monitoring purposes on a Kubernetes cluster. Follow the prerequisites and installation steps below to get started.

## Prerequisites

- A Kubernetes cluster (e.g. k3s)
- Helm chart tool

## Installation with Homebrew

Install Helm using Homebrew:

```bash
brew install helm
```

## Setup

Create a Namespace
Create a dedicated namespace for Prometheus and Grafana:

```bash
kubectl create namespace monitoring
```

## Change the Context Namespace

Switch the current context to the new namespace:

```bash
kubectl config set-context --current --namespace=monitoring
```

## Prometheus Installation

Add the Prometheus community Helm chart repository and install Prometheus:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

## This will install:

```
Prometheus Server (collects metrics)
Alertmanager (handles alerts)
Node Exporter (collects node-level metrics)
Grafana (visualization)
```

Get Grafana 'admin' user password by running:

```bash
kubectl --namespace monitoring get secrets prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```

## Access Grafana local instance:

```bash
  export POD_NAME=$(kubectl --namespace monitoring get pod -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=prometheus" -oname)
  kubectl --namespace monitoring port-forward $POD_NAME 3000
```

## Alternatively you can use ingresses:

Prometheus server ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
spec:
  rules:
    - host: prometheus.local # Replace with your domain
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-kube-prometheus-prometheus
                port:
                  number: 9090
```

Grafana ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
spec:
  rules:
    - host: grafana.local # Replace with your domain
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 80
```

# Add the ingress to hosts:

```bash
kubectl get ingress -n monitoring
NAME                 CLASS     HOSTS              ADDRESS                                  PORTS   AGE
grafana-ingress      traefik   grafana.local      <Load-Balancer-Host>                     80      18m
prometheus-ingress   traefik   prometheus.local   <Load-Balancer-Host>                     80      18m

sudo vi /etc/hosts
Load-Balancer-Host grafana.local
Load-Balancer-Host prometheus.local
```

## Add Prometheus as a Data Source

```
Go to Grafana → Configuration → Data Sources.
Click Add data source → Select Prometheus.
Set URL to: http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090
Click Save & Test.
```
