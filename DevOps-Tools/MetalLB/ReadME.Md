
# Installation of Metallb Load balancer

## Requirements:
1. Kubernetes Cluster
2. Helm charts
3. Installation of MetalLB (a load balancer that allows communication with the Kubernetes cluster from the outside)

### Steps for Installing MetalLB:
- **Installation of MetalLB:**
  ```bash
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

