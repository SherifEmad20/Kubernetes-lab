# HashiCorp Vault Setup Using Helm on Kubernetes

This guide provides step-by-step instructions for setting up HashiCorp Vault using Helm on a Kubernetes cluster. Follow the prerequisites and installation steps below to get started.

## Prerequisites

- A Kubernetes cluster (e.g. k3s, minikube, or a managed cluster)
- Helm chart tool

## Installation with Homebrew

Install Helm using Homebrew:

```bash
brew install helm
```

## Setup

Create a Namespace
Create a dedicated namespace for Vault:

```bash
kubectl create namespace vault
```

## Change the Context Namespace

Switch the current context to the new namespace:

```bash
kubectl config set-context --current --namespace=vault
```

## Vault Installation

Add the HashiCorp Helm chart repository and install Vault:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault --namespace vault --create-namespace
```

## This will install:

```
Vault Server (handles secrets management)
Auto-unseal capabilities (if configured)
Vault Agent (optional for service integration)
```

### Verify Vault Installation

Check if the Vault pods are running:

```bash
kubectl get pods -n vault
```

## Unsealing Vault

Vault is installed in a sealed state and needs to be unsealed before use.

1. Initialize Vault and capture the unseal keys and root token:

```bash
kubectl exec -it vault-0 -- vault operator init
Unseal Key 1: <Unseal_Key_1>
Unseal Key 2: <Unseal_Key_2>
Unseal Key 3: <Unseal_Key_3>
Unseal Key 4: <Unseal_Key_4>
Unseal Key 5: <Unseal_Key_5>

Initial Root Token: <Root_Token>
```

2. Unseal Vault using three of the provided unseal keys (run three times with different keys):

```bash
kubectl exec -it vault-0 -- vault operator unseal <UNSEAL_KEY>
```

3. Verify that Vault is unsealed:

```bash
kubectl exec -it vault-0 -- vault status
```

4. Enable secrets:

```bash
kubectl exec -it vault-0 --vault login <Root_token>

kubectl exec -it vault-0 --vault secrets enable -path=<Add_your_path> kv

# Testing secrets
kubectl exec -it vault-0 --vault kv put secret/mysecret username="admin" password="mypassword"

kubectl exec -it vault-0 --vault kv get secret/mysecret
```

## Access Vault UI

### Port Forwarding (Alternative Method)

To access Vault UI locally, run:

```bash
kubectl port-forward svc/vault-ui 8200 -n vault
```

Then, open [http://localhost:8200](http://localhost:8200) in your browser.

## Alternatively, use Ingress:

Create an ingress resource for Vault UI.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vault-ingress
  namespace: vault
spec:
  rules:
    - host: vault.local # Replace with your domain
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: vault
                port:
                  number: 8200
```

### Add the Ingress to Hosts:

```bash
kubectl get ingress -n vault
NAME            CLASS     HOSTS        ADDRESS                 PORTS   AGE
vault-ingress   traefik   vault.local  <Load-Balancer-Host>     80      10m

sudo vi /etc/hosts
Load-Balancer-Host vault.local
```

## Login to Vault

Once Vault is unsealed, log in using the root token obtained during initialization:

```bash
kubectl exec -it vault-0 -- vault login <ROOT_TOKEN>
```

## Configure Vault as a Kubernetes Secret Store

1. Enable the Kubernetes authentication method:

```bash
kubectl exec -it vault-0 -- vault auth enable kubernetes
```

2. Set up the Kubernetes authentication configuration:

```bash
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

## Conclusion

Vault is now installed and unsealed on your Kubernetes cluster. You can access the UI via Ingress or port-forwarding and use it for secrets management in your applications.
