# ArgoCD Setup on Kubernetes

This guide provides step-by-step instructions for setting up **ArgoCD** on a Kubernetes cluster using Helm. Follow the prerequisites and installation steps below to get started.

## Prerequisites

- A **Kubernetes cluster** (e.g., K3s)
- **Helm** installed on your system

## **Installation with Homebrew**

Install Helm using Homebrew (if not installed):

```bash
brew install helm
```

## **Setup**

### **Create a Namespace**

Create a dedicated namespace for ArgoCD:

```bash
kubectl create namespace argocd
```

### **Change the Context Namespace**

Switch the current context to the new namespace:

```bash
kubectl config set-context --current --namespace=argocd
```

## **ArgoCD Installation**

Add the ArgoCD Helm chart repository and install ArgoCD:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace argocd
```

### **This will install:**

- **ArgoCD Server** (for managing GitOps)
- **Application Controller** (for monitoring application state)
- **Dex** (for authentication)
- **Repo Server** (for handling Git repositories)
- **Redis** (for caching)

## **Retrieve the ArgoCD Admin Password**

Get the initial `admin` password by running:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
```

## **Access the ArgoCD Local Instance**

Forward the ArgoCD server port:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Now, open **http://localhost:8080** and log in using:

- **Username:** `admin`
- **Password:** (retrieved from the previous step)

## **Alternatively, You Can Use Ingress**

### **ArgoCD Ingress Configuration**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: "Traefik" # Change to "nginx" if using Nginx
spec:
  rules:
    - host: argocd-ui-cluster.local # Replace with your domain
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
```

Apply the ingress:

```bash
kubectl apply -f argocd-ingress.yaml
```

### **Add the Ingress to Hosts**

To access **ArgoCD via domain**, add an entry to your `/etc/hosts` file:

```bash
echo "192.168.X.X argocd-ui-cluster.local" | sudo tee -a /etc/hosts
```

Replace `192.168.X.X` with your **Ingress Controller IP**.

### **Configure ArgoCD Server to be insecure for ingress to work**

```bash
kubectl -n argocd edit deployments.apps argocd-server
```

```yaml
# Under Containers.args section add the --insecure args
containers:
  - args:
      - /usr/local/bin/argocd-server
      - --port=8080
      - --metrics-port=8083
      - --insecure # Added argument
```

Update the configMap with server.insecure to be true

```bash
kubectl -n argocd edit cm argocd-cmd-params-cm
```

```yaml
server.insecure="false" # Change to true
```

Restart the ArgoCD Server

```bash
kubectl rollout restart deployment argocd-server -n argocd
```

## **ArgoCD CLI Installation (Optional)**

To manage ArgoCD from the terminal:

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd-linux-amd64
sudo mv argocd-linux-amd64 /usr/local/bin/argocd
```

### **Login to ArgoCD via CLI**

```bash
argocd login argocd.local --username admin --password <YOUR_PASSWORD>
```

## **Verify Installation**

Check if all ArgoCD components are running:

```bash
kubectl get pods -n argocd
```

---

🚀 **Now you have ArgoCD installed and accessible for GitOps-based deployments!** 🎉
