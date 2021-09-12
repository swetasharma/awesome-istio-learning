# DevOps / SRE 
Understand the world of containers and microservices.

## Assumption
1. Only simple-service app is allowed to talk to postgres database. No service from outside can connect to postgres.
2. There are no restrictions in terms of CPU, Memory.
3. The simple-service webapp will show status as ```Running``` until progres is up and ```Well Done``` once the postgres is up.

## Stack
Golang, Docker, Postgres, Minikube, Kubectl, Istio( to manage microservices within kubernetes ), Docker Hub
``` I’m using kubernetes version v1.18.3 and Istio 1.6.5. ```

## How to build image from Dockerfile of simple-service-webapp and push it to container repository (Docker Hub)  
1. Install Docker:
    > Use https://www.docker.com/products/docker-desktop to install docker on windows.
    
2. Build the image:
> Go to simple-service folder and copy the docker file and issue below command
```
docker build -t 225517/simple-service-webapp:v1 .
```

3. Verify simple-service-webaap image exist bu running below command
```
docker images
``` 

4. Push the image to repository(docker-hub)
```
docker login
docker tag 225517/simple-service-webapp:v1 225517/simple-service-webapp:v1
docker push 225517/simple-service-webapp:v1
```

5. After pushing the image to docker hub you should see message (not exactly same)
> v1: digest: sha256:00fcdfecb03a3e653d2056d3d540af21f6eec5880a3b41609b1a133448e49c15 size: 2616
## How to Spin Up a Kubernetes Cluster:
1. Install Minikube ( an opensource tool to use kubernetes locally ).
```
minikube start --vm-driver hyperv --hyperv-virtual-switch "Minikube Virtual Switch" 
```

2. Install Kube Control ( kubectl ). 
    1. ``` kubectl version ``` ( to confirm tool is available ).
    2. ``` kubectl get nodes ``` ( to check the nodes of your kubernetes cluster ).
    
## How to Set Up Istio
We will Istio for secure communication between microservices, Tracing, Monitoring and Logging, authentication and authorizaztion.
1. Download Istio: (We are downloading istio for windows 10):
    > Go to https://github.com/istio/istio/releases/tag/1.6.5 and download Istio.
    
2. ``` cd istio-1.6.5 ```

3. The istioctl client binary in the bin/ directory. Add the istioctl client to your path.
```
istioctl version
```

4. Install Istio
```
istioctl manifest apply --set profile=demo
kubectl get svc -n istio-system
kubectl get pods -n istio-system
```
Great! Installation of Istio Done.

5. Instruct Istio to automatically inject Envoy sidecar proxies
```
kubectl label namespace default istio-injection=enabled
```

6. Add the simple-service-webapp image to Minikube cache
```
minikube cache add 225517/simple-service-webapp:v1
```

As simple-service webapp depends on postgres. We need to first deploy postgres into our kubernetes cluster.
Are you excited? :wink: Let's start!!

### How to deploy postgres service in Kubernetes cluster
1. Create Kubernetes Deployments - This creates a container. The container uses postgres image.
2. Create Kubernetes Service - Defines logical set of pods and a policy to access them. 
3. To run this postgres service in your Kubernetes cluster, you will have to issue the following command:
```
kubectl apply -f postgres-service.yaml
```
> You should see output as 
``` 
> service/postgresdb created
> deployment.apps/postgresdb-v1 created
```
4. Verify postgres pod and service is running by issuing below commmand:
```
kubectl get pods
> postgresdb-v1-7dd4b56dfc-tnvcr        2/2     Running   0          20m
Kubectl get svc
> postgresdb                ClusterIP   10.108.60.181    <none>        5432/TCP   21m
```
> https://www.postgresql.org/docs/8.3/app-psql.html

5. ToDo:
> Configuring environment variables in postgres deployment to crate user and its database upon startup.
> Configuring environement variables in simple-service-webapp to connect to database.
error prone and quite unsecured :smile:
1. Configure postgres with a Secrets to handle connection credentials (Decouple configuration from deployment. The values need to be encoded in base64.
2. As docker containers are ephemeral in nature. Wondering how to keep the data safe when the pod is rescheduled? :D
    a. Persistent Volumes
    b. Persistemt Volume Claims

Access the PgSQL client to create a test database, table, and adding a row.

### How to Deploy simple-service-webapp service in kubernetes cluster
1. Create Kubernetes Deployments - This creates a container. The container uses image we built in first step using Dockerfile.
2. Create Kubernetes Service - Defines logical set of pods and a policy to access them. 
3. To run this simple-service-webapp service in your Kubernetes cluster, you will have to issue the following command:
```
kubectl apply -f simple-service-webapp-service.yaml
```
> You should see output as
``` 
> service/simple-service-webapp-service created
> deployment.apps/simple-service-webapp-v1 created
```

3. Verify simple-service pod and service is running by issuing below commmand:
```
kubectl get pods
kubectl get svc
```

4. As postgresdb port is 5432 and host is postgresdb let's reflect that in config file
Open config.go file in simple service applciation and do the config changes described below
```
// Config is responsible for holding the application configuration
// variables. Each configuration point is also exported as an environment
// variable.
type Config struct {
	Port        uint   `env:"PORT" envDefault:"8080"`
	PostgresURL string `env:"POSTGRES_URL" envDefault:"postgres://user:pass@postgresdb/simple-service"`
}
```
Let's deploy the new version of the simple service webapp:
```
docker build -t 225517/simple-service-webapp:v1 .
```

push the new image to Docker Hub
```
docker push 225517/simple-service-webapp:v1
```
```
kubectl logs ${POD_NAME} ${CONTAINER_NAME}
```
> In my case it is kubectl logs simple-service-webapp-v1-689f6f8f5c-d4sbv simple-service-webapp
> Below is the output you gonna get on command prompt
> Listening on port 8080
> Mon Jul 27 14:43:37 2020 - error querying database: pq: SSL is not enabled on the server

By default, PostgreSQL comes with SSL support. It listens for both SSL and normal connections on the same port.

> Let's establish DB connection without SSL encryption
> Add ```sslmode=disable``` in simple-service-webaap-service.yaml

Cool! You just deployed simple-service webapp service into your kubernetes cluster. :coffee:

### Configuring simple-service-webapp scaled on the base of CPU metrics
HPA will increase or decrease the number of replicas

1. In order to use kubernetes feature like horizonal pod autoscaler, we need to use ```Metrics Server```.
Metrics Server is available as one of the plugins. Execute below command:
```
minikube addons enable metrics-server
kubectl -n kube-system rollout status deployment metrics-server
kubectl top nodes
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   174m         8%     2504Mi          43%
```

2. Create Horizontal Pod Autoscaler
```
kubectl autoscale deployment simple-service-webapp-v1 --cpu-percent=50 --min=1 --max=10
```
3. Check the current status of autoscaler by running:
```
kubectl get hpa
```
4. Let's add the load
send an infinite loop of queries to the simple-service-webapp
```
kubectl run -it --rm load-generator --image=busybox /bin/sh
Hit enter for command prompt

while true; do wget -q -O- http://{YOUR-CLUSTER-PUBLIC-IP}/live; done
```
5. Wait a minute or so and execute the below command to see the CPU load
```
kubectl get hpa
NAME                       REFERENCE                             TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
simple-service-webapp-v1   Deployment/simple-service-webapp-v1   265%/50%   1         10        6          7m27s
```
you can scale your pods according to your workload

6. Wondering How to consume Deployment, right? :wink:

### Expose simple-service-webapp microservice using virtual services
5.Issue the following command to create simple-service virtual service in your cluster:

```
kubectl apply -f simple-service-webapp-virtual-service.yaml
```
6. Issue the following command to confirm that sample-service-webaap virtual service is indeed up and running.
```
kubectl get svc
```
7. After creating your service, you can finally define an ingress to expose simple-service service to the outside world.
8. To deploy the new ingress-gateway in your cluster, you can issue the following command:

```
kubectl apply -f simple-service-ingress-gateway.yaml
```
9. Find the Public IP address of your kubernetes cluster by issuing below command
```
minikube tunnel
kubectl get svc -n istio-system istio-ingressgateway -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
 ``` In my case it is: 10.97.72.213 ```
  
 > Open the browser and hit http://10.97.72.213/live you should see output as ```Well done :)``` on browser.

 Congratulations !!! We deployed a simple-service-webapp and postgres on kubernetes cluster cheers!! :beer:

## Prometheus and Grafana
### How does Istio collect metrics 
Istio uses sidecar proxies as sidecontainers to microservice containers. Since all traffic flows through these proxies, they send telemetry data to Prometheus, which can be stored and visualised using tools such as Grafana.

1. Verify that the prometheus service is running in your cluster by issuing below command:
``` 
kubectl -n istio-system get svc prometheus
istioctl dashboard prometheus
```

2. Verify that the grafana service is running in your cluster by issuing below command:
```
kubectl -n istio-system get svc grafana
```
3. open the Istio Dashboard via the Grafana UI
```
kubectl -n istio-system get pod -l app=grafana
kubectl -n istio-system port-forward grafana-54b54568fc-r6tbx 3000:3000
```
4. Send traffic to mesh by visting http://{YOUR-CLUSTER-PUBLIC-IP}/live

## ToDo

1. Setting up a CI/CD pipeline to deploy a containerized application to Kubernetes.
2. Automate Kubernetes environment setup. 
3. Implementing authentication and authorization to microservice architecture using Istio and Auth0.
4. Snapshot and backup of postgresql.
5. Validate data persistence by deleting the PostgreSQL pod
6. Resize my PostgreSQL volume if I am running out of space
7. Enable secure PostgreSQL connection
Portworx offers a simpler and more cost effective solution to running HA PostgreSQL on Kubernetes.[#ToDo [4, 5, 6]]
