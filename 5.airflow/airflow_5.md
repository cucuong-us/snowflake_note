# General airflow optimisation and maintaince
## 1 Scheduler and Worker Optimization
### 1.1 Optimize Scheduler throughput
- Scheduler have loops in short time to:
    + check DAG and create DAG Run 
    + check dependencies, concurrency and pool and bring task to worker 
- scheduler throughtput is the number of DAG Run and Task Instance that Scheduler can handle in the period
- the main purpose of it:
    + decrease time tasks place scheduled
    + decrease DAG Run schedule delay
- the basic way is to increase CPU for scheduler when CPU usually reach 100% when: 
    + task.scheduled_duration is high
    + Metadata DB is fine
    + some workers are empty
- run many scheduler in parrallel when CPU-bound (mean that task mainly need CPU more RAM or network) and the capacity of Metadata DB is fine. it will help us:
    + increase throughput and have HA 
    + but have additionally DB connection and query, dont do it when DB is not fine
- If the CPI is low and loop also is low, need to optimize DB
    + use PostgreSQL for production
    + use connection pooling, mean that create a connection once and reuse it 
    + trace low query 
    + cleanup historical data 
- decrease active run with decrease max_active_run:
    + but it may be make some DAGs Run have to wait to run
    + example to use it:
        + large DAGs and each DAG use much resources 
        + backfill create a lot of DAGs Run 
        + source or target have some limitations
### 1.2 Optimize Worker concurrency
- Choose the number of currency:
    + CPU-bound tasks: should set concurrency lower than CPU cores to avoid CPU contention
    + Memory-heavy tasks: the number of concurrency = RAM / peak RAM of task 
    + I/O-bound tasks:
- Seperate worker, for example:
    + worker for normal task 
    + worker for heavy task
    + worker for gpu task 
    
=> It help us custom cucurrency for specific worker 
- Scale the number of workers instead of concurrency:
    + if the worker usually reach the limitation of CPU and RAM 
    + if a woker fail, others can work
### 1.3 Optimize autoscaling
- Celery:
    + increase or decrease workers depend on queued task 
    + can use: 
        - Celery autoscaling
        - or KEDA khi Worker when running Kubernetes
    + can set:
```
minimum workers
maximum workers
cooldown period:wating time to scale
scale-up rate: for example 4 pod per min 
scale-down rate 
```
- KubernetesExecutor
    + each task have a seperate Pod
    + need to optimize:
        - Pod resource requests
        - Pod resource limits
        - Image size
        - Image pull policy/cache
### 1.4 Optimize task scheduling và queue latency
- if scheduled_duration is high we need to check one by one:
    + check Pool slot
    + check parallelism
    + max_active_tasks 
    + max_active_runs 
    + CPU of scheduler
    + check metadata DB latency
    + last one consider add more scheduler
### 1.5 Optimize zombie, stalled và lost tasks
- Zombie task, Airflow Metadata DB store running status but process die or dont heartbeat (Worker OOMKilled, Pod restart or evict, node die,...)
    + ensure that Worker/task heartbeat is stable
    + dont allow network problem 
    + use worker retry policy 
- Stalled task: task stuck for long time (scheduled, queued, running for a long time). Address it with execution_timeout
- lost task: airflow dont track task or get the results although task is assigned for worker before  (celery worker die after receive task, broker loss connection, executor restart and loss state temorary,...)
    + task stuck in queued 
    + task stuck in running 
    + for a long time, airflow consider it fail
## 2 Metadata Database Optimization
- If metadata DB is slow, other components also run slow
- DB usually become bottleneck because when scale others component(many worker, DAG, tasks,... ) it need to scale for suitable with those component 
- Dont choose SQLite, choose PostgreSQL or My SQL
- use poor connection to reuse 
- cleanup DB:
```
airflow db clean \
  --clean-before-timestamp "2026-01-01T00:00:00+00:00" \
  --dry-run
```
-  --dry-run have know the number of rows can delete but dont actually delete
- by default, droped data will store in archive table, use --skip-archive to delete immerdiately without archive
- Connection exhaustion: mean that aiflow need connection but pool out of stock,
    + signs: timeout when get connection, API requests slow or error,...
    + solution: set pool size that is suitable for real situation, dont increase max_connection without envidence 
