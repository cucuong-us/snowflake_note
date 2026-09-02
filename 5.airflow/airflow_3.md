# Scaling and Production Architecture
## 1 Executor 
- It decide the machenism to run Task Instance and how to run it, mean that It will bring Task Instance to 
- Executor is not a independent service, it run inside the scheduler
### 1.1 LocalExecutor
- It will create tasks that run in same machine with scheduler 
- LocalExecutor can also run task in parallel and limited by parallelism, max_active_task, Pools,..
- pros: simply install and setup, startup latency is low,..
- cos: cant scale with other machines -> vertical scaling. If failed, entire component die
### 1.2 CeleryExecutor
- Celery is a distributed task queue in Python
- It use some long-time workers and a massage broker:
    + massage broker (redis, rabbit MQ,..): keep task and send it to workers, it worker error it will handle (maybe another worker)
    + long-time workers: can place at some difference machines 
- Celery queues: it will route task to right workers, we can use 
```
@task(queue="high_memory")
```
to choose queue for this task 
- worker receiving task should have some necessary thing to run the specific task, because scheduler dont send entire enviroment to worker, It can include:
    + right version DAG 
    + Python package 
    + can access external network system 
    + necessary library
    + and something like that
- Log storage:Because task can run worker A and retry in worker B, so need to a central place to strore not just a disk of worker
- We can use: S3, GCS, CloudWatch,...
- Pros: horizotal scaling, quickly startup worker, ...
- Cos: mataince broker and result backend, need to monitor worker, broker, queue back,...
    + result backend: mean that data is retured when task completed at worker
### 1.3 KubernetesExecutor
- It run a task in a specific Kubernetes Pod
- When task finish, resources in Pod will be free
- Dont need worker live for long time and Celery broker
- Time latency in KubernetesExecutor:
    + Airflow queued
    + Pod Pending
    + Pull image
    + Container startup
    + Task Running
- That is reason why it take more time than Celery
- Request and limits
    + Request: mean that Pod need at lease this resources to use
    + Limit: task will OOMKilled when exceed that limitation
    + Examples
```
requests:
  cpu: "2"
  memory: "4Gi"
```
```
limits:
  memory: "8Gi"
```
- Pros:
    + a Pod for a Task Instance
    + It is good to Isolation 
    + CPU/RAM/GPU for a specific task
- Cons:
    + Kubernetes complexity
    + Startup latency in image pull
    + have to mantain cluster, RBAC, autoscaler, image registry
    + Pod Pending/ImagePullBackOff/OOMKilled/Evicted create more failure modes
### 1.4 Managed Airflow platform
- It is a service help us manage most of Airflow Infrastructure, such as: Amazon MWAA, Google Cloud Composer/Managed Airflow
- It will manage: 
    + Metadata Database
    + Scheduler/API Server/webserver
    + Worker provisioning/autoscaling
    + Logging/metrics integration
    + Patching
    + High availability 
    + Backup và infrastructure lifecycle
- Amazon MWAA, its architecture form 2 main part:
    + MWAA enviroment:
        - Scheduler trên AWS Fargate (AWS Fargate privide compute for container run without manage EC2)
        - Celery workers trên Fargate
        - API Server/webserver
        - AWS-managed metadata database
- Trade off 
    + version lag and feature gap: Airflow version, Provider versions, Python version, Feature support,..
    + lack of control deeply: System packages, Metadata DB, Container base image,...
    + dependency constraints: a new package can conflict with others that had installed 
    + increase cost even though there are only a few tasks
## 2 Scaling Airflow components
- Not only worker scale when the system is low
### 2.1 Scheduler
- verital: use it when:
    + Scheduler CPU is high
    + Scheduler loop is low
    + there is only one scheduler 
    + metadata DB is fine
- horizontal: use it when
    + increase scheduling throughput
    + high availability
    + if one scheduler die, other scheduler continue manage task
    + increase scheduler can increase:
        - Database queries
        - Database connections
        - Lock contention: for example, some workers can get data same locks. So, just one can get data and others have to wait 
        - Executor interactions: task can wait others in a executor
- Some signs to know that need to scale scheduler:
    + Scheduler CPU is near 100%
    + scheduler_loop_duration increase 
    + DAG Run is created that missed the deadline
    + Task have all dependencies but scheduled for long time 
### 2.2 Worker 
- worker is the most important part, scaling worker depend on type of worker
#### 2.2.1 LocalExecutor
- It run in same machine with scheduler, and It just a single node
- So we just increase CPU/RAM or adjust parallelism
=> vertical scaling
#### 2.2.2 CeleryExecutor
- It can scale vertical like LocalExecutor
- Normally, scale horizontal by adding node (worker) 
#### 2.2.3 KubernetesExecutor
- After airflow create Pool, Kubernetes provide a suitable node to run Pool
- Need to scale if:
    + if task is queued and Pod is pending: it can lack of CPU and RAM -> scale CPU and RAM
    + Queue duration increase 
    + Celery workers use entire concurrency
    + CPU/RAM worker usually reach limitation
### 2.3 DAG processing capacity
- Some problems we can see:
    + thousand of file DAG
    + DAG import many large library
    + Dynamic DAG generation is complex 
    + Parse timeout
    + lack of CPU/RAM
- Address problems:
    + increase parsing_process -> it help parse DAG file in parallel
    + increase CPU and RAM, if they are not enough
    + optimize DAG parse:
        + avoid database call at top level
        + decrease large import 
        + ignore file dont contain DAG with .airflowignore
### 2.4 Metadata Database capacity
- Metadata DB is a central DB of Airflow (Serialized DAG, DAG Run, Task Instances, Task state,...) and call it through API server 
- How to scale it:
    + vertical: CPU, RAM, cache,...
    + clean outdate metadata: DAG Run history, Task Instance history, Logs metadata, XCom,...
    + Index or query tuning: check query, check indexes,....
### 2.5 Broker capacity
- It's just reletive to Celery. It delivery task from queue to worker 
- Some broker information need to check:
    + the number of publishing tasks per second 
    + the number of queue
    + the number of worker consume at the specific time
    + the number of connection
- depend on tech stack we can scale:
### 2.6 Triggerer capacity 
- triggerer have many slight trigger at same time
- It use asynchronous event loop to manage those trigger
- need to check:
    + Trigger implementation
    + Network latency
    + CPU/RAM
    + Metadata DB
- we also scale it both vertical and horizontal with prons and cons sililar I mentioned above
=> `before scale we need to define the bottleneck and depend on it we will a suitable scaling`
## 3 Auto scaling 
### 3.1 Celery worker 
- in this worker 
    + I can set `worker_autoscale = 16,4`. mean that min process in this worker is 4 and max is 16
- scale the number of workers: can use KEDA or Managed Airflow platform
### 3.2 KEDA
- KEDA stand for Kubernetes Event-Driven Autoscaling
- It help workflow can reference outside event or metrics instead of only CPU and RAM 
- how KEDA caculate the number of worker:
```
desired_workers =
ceil(
    the number of queued or running task
    /
    worker_concurrency
)
```
- how to setup it 
```
workers:
  celery:
    keda:
      enabled: true
      minReplicaCount: 1
      maxReplicaCount: 20
      pollingInterval: 10
      cooldownPeriod: 120
```
### 3.3 Scaling limits
- minReplicaCount: min the number of workers (should not set it to 0 because can face to cold start)
- maxReplicaCount: limit the max of workers 
- `parallelism` in entire Airflow to limit task running at the same time 
- DAG/task concurrency:
    + max_active_runs
    + max_active_tasks
    + max_active_tis_per_dag
### 3.4 Eviction safeguards
- mean that protect workflow to Pod avoid evict by Kubernetes 
- The causes may be:
    + node out of RAM and CPU 
    + node out of ephemeral storage
    + autoscaler want to delete some node 
- some way to avoid this:
    + declare right request and limit 
    ```
    resources:
    requests:
        cpu: "500m"
        memory: "1Gi"
    limits:
        cpu: "2"
        memory: "2Gi"
    ```
    + Graceful shutdown: give time to complete task, for example:
    ```
    spec:
    terminationGracePeriodSeconds: 120
    ```
    + PriorityClass: for example 
    ```
    spec:
    priorityClassName: airflow-worker-high
    ```
## 4 Production architecture
### 4.1 High availability 
- When one thing die, the system also run normally with backup:
- We need to apply to entire component of Airflow:
    + Scheduler
    + API Server
    + Triggerer
    + Worker
    + DAG Processor
### 4.2 External PostgreSQL and broker 
- shoud not use SQLite or temporary container, we should use PostgreSQL outside the Airflow compute 
- It have to have:
    + HA/failover
    + Automated backup
    + Point-in-time recovery nếu có thể
    + Encryption at rest
    + TLS in transit
    + Private network
    + Monitoring
    + and something like that 
- should use run a non persistent broker for production 
- shoud use Redis or Rabbit MQ, and need to have: 
    + HA/failover.
    + Authentication.
    + TLS
    + Private networking.
    + Memory/disk alarms.
    + Connection limits. 
    + ....
### 4.3 remote logs
- Some resource are just temporary (such as Kubernetes Pod and may be workers) and will be deleted after task completed and its logs are also deleted, that is why we need to centre and store them to only a place 
### 4.4 DAG distribution and versioning
- There are 2 component need code DAG
    + DAG Processor
    + Workers/task runtime
- Scheduler Airflow usse serialized DAG from Metadata DB dont read directly from DAG Bundle
- distribute DAG:
    + pack to a container image and use it or send it. need to redeploy when update code
    + sync: update quickly
```
Git sync/object storage -> DAG folder trên component
```
- Airflow support 4 bundle type:
    + LocalDagBundle: from local file
    + GitDagBundle: pull from Github, most common and support versioning
    + S3DagBundle: Pull from S3
    + GCSDagBundle: Pull form GCS 
### 4.5 Secrets và security
- dont store secrets on DAG or Github, store it in safe places, for example AWS Secrets Manager
- Some important key need to make it safe:
    + Fernet key: encryp sensitive information in metadata DB
    + JWT signing key/private key: use for API authentication
    + ....
- some method to protect them:
    + TLS for UI/API, DB, broker and external services
    + RBAC cho UI/AP
    + Audit logs
    + Private network
### 4.6 Backup 
- Metadata Database:
    + Automated snapshots
    + Point-in-time recovery
    + Backup encryption
- DAG source: contain in git repo
- Secrets: Secrets Manager usually have replication/version history
- Infrastructure configuration: can use terraform 
- Disaster recovery: will answer that how long to recover and how many data loss
    + Recovery Point Objective: max time to recover data
    + Recovery Time Objective: airflow run normally 