
# SSL certificates using cert-manager

## Requirements:
1. Kubernetes Cluster
2. Helm charts
3. Ingress Controller
4. Load Balancer

### Install nginx ingress controller:
```
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install nginx-ingress nginx-stable/nginx-ingress --namespace nginx-ingress --create-namespace --set rbac.create=true --set installCRDs=true
```
### Install Metallb load balancer:
```
helm repo add metallb https://metallb.github.io/metallb
helm repo update
helm install metallb metallb/metallb --namespace metallb-system --create-namespace --set installCRDs=true
```

- **Define the addresses pool:**
  ```yaml
  apiVersion: metallb.io/v1beta1
  kind: IPAddressPool
  metadata:
    name: first-pool
    namespace: metallb-system
  spec:
    addresses:
    - <Start range - End range>
  ```

- **Define L2Advertisement to use the address pool:**
  ```yaml
  apiVersion: metallb.io/v1beta1
  kind: L2Advertisement
  metadata:
    name: L2Advertisement
    namespace: metallb-system
  spec:
    ipAddressPools:
    - first-pool
  ```

### Install cert-manager:
```
helm repo add jetstack https://charts.jetstack.io --force-update
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.14.4 --set installCRDs=true
```

### Self-Signed Certificate:
- **First generate a Certificate Authority key:**
  ```
  openssl genrsa -out ca.key 4096
  ```

- **Generate a certificate from this key that is valid for 30 years:**
  ```
  openssl req -new -x509 -sha256 -days 10950 -key ca.key -out ca.crt
  ```

- **Create a secret to store the ca.crt and ca.key and pass it to the issuer:**
  Convert the files to base64 to be used in the secret:
  ```
  cat ca.crt | base64 
  cat ca.key | base64
  ```

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: ca-secret
    namespace: cert-manager
  type: Opaque
  data:
    tls.crt: ### value from base64
    tls.key: ### Value from base64
  ```

### Apply the YAML files:
#### Issuer:
- **The issuer is responsible for solving certificate challenges and issuing the certificate to the DNS to make it secure:**
  ```yaml
  apiVersion: cert-manager.io/v1
  kind: ClusterIssuer
  metadata:
    name: test-selfsigned
  spec:
    ca:
      secretName: ca-secret
  ```

#### Certificate:
- **The certificate itself that is created as a secret in the namespace by the issuer:**
  ```yaml
  apiVersion: cert-manager.io/v1
  kind: Certificate
  metadata:
    name: selfsigned-cert
  spec:
    secretName: selfsigned-cert-tls
    issuerRef:
      name: test-selfsigned
      kind: ClusterIssuer
    dnsNames:
      - <Your DNS>
  ```

### Example Deployment:
#### Deployment:
```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 3
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
```

#### Service:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    protocol: TCP
```

#### Ingress:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
  labels:
    name: nginx-ingress
spec:
  tls:
    - hosts: 
      - <Same DNS in the certificate>
      secretName: selfsigned-cert-tls
  rules:
  - host: <Same DNS in the certificate>
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: nginx
            port: 
              number: 80
```
- **Export the DNS in the local hosts file**
  ```bash
  kubectl get svc -n nginx-ingress
  ### Take the External-IP of the nginx-ingress-controller service
  sudo vim /etc/hosts
  <External-IP> <DNS>
  ```
