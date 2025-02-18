# Service mesh:
A service mesh is a solution that can be described as a pattern or a paradigm to manage communication between microservices with each other.

# why?
from monolithic to microservice...
challanges within the microservice architecture:
1. an application is divided accross mulitple small services and each service is used for a specific case
    when deployed on a k8s cluster each service has its own logic 
2. service mesh is then introduces to facilitate the communication between the services and each others


The challanges:
1. configure endpoints of new services into the code
2. unsecure connections between services and each other inside the cluster
3. implementation of retry logic (if a service cannot connect to another service handle this case inside the code)
4. moitoring and tracing from within the code it self

In conclusion:
the developers need to add alot of unrelated logic to the business logic into the services which lead to complexity in the services instead of keeping them simple and lightweight

Solution:
Introduced as service mesh which adds a sidecar proxies to handle the extra networking logic as a third party application deployed within the service pod
the microservices communicate with each others via those sidecar proxies

The service mesh provide:
1. Traffic Management
2. security
3. observability
4. control 

ISTIO Architecture:
ISTIO uses envoy proxies which are an opensource project that istio uses to be injected into the pods

benifits:
1. has dynamic service discovery feature as it has an internal services registry with their endpoints so no need to manually configure new services routes
2. Acts as a certificate authority which generate certificates for secure communication between service to allow secure TLS communication between services and each other
3. gets Matrices and tracing data from the envoy proxies that can be used in any monitoring tools

Control plane: (istiod) --> manages and injects the envoy proxies into the pods

Data plane: --> group of the envoy proxies 

How to configure istio?
we don't need to modify any of the k8s yaml files of the services 
the istio can be defined seperatly in a different yaml files using CRDs (custom resources defintions)
CRDs --> extend kubernetes API to manage custom kuberenetes components and third-party apps such as istio or prometheus etc
            can be used like other native kubernetes objects


Using ISTIO CRDs we can:
1. configure traffic routing --> which services can talk to each other
2. traffic splitting
3. retry rules, timeouts, etc..


Commonly used CRDs:
1. VirtualService --> configures how to route the traffic to a specific service
2. DestribuionRule --> configure some policies on the traffic routed to the service

ISTIO ingress gateway:
acts as the entrypoint for the cluster 

gateway is a pod in the cluster and acts as a load balancer by accepting traffic into the cluster then direct this traffic to the microservices using virtualServices


# Installation of istio:
- download istiocli tool: curl -L https://istio.io/downloadIstio | sh -

- exported to the path: 
- export PATH=$PWD/bin:$PATH

- install to cluster with the demo profile:
- istioctl install --set profile=demo -y

- add a namespace label to inject envoy automatically to its pods:
- kubectl label namespace default istio-injection=enabled

- apply istio-gateway

- allow tunnels:
- minikube tunnel

- expose the ingress to be used in the gateway:
- export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
- export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
- export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')

- export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT


ENJOY!