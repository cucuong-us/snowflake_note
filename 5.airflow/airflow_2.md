# Workflow Design and Resource Management
## 1. Workflow structure and control flow
- Dependencies are before - after relations among tasks
- For example: I have a pipeline extract -> transform data. I will set the dependency that: `after extract complete, transform run`

### 1.1 How to declare dependencies
- use `>>`. For example `extract >> transform >> load`. It means that `extract` task run first, follow by transform and last one is load 
- use `<<`. For example `load << transform << extract`. it will have same results with >> above
- use python medthod:
    + set_downstream:
    ```
        extract.set_downstream(transform)
        transform.set_downstream(load)
    ```
    + set_upstream: 
    ```
    transform.set_upstream(extract)
    load.set_upstream(transform)
    ```
=> Same results with above examples
### 1.2 Fan-out
- Fan-out: mean that from a task generate multiple branchs or tasks. For example after `extract` I want airflow run `clean_tableA` and `delete_dulicate_tableB` in parallel
- But make sure that resource is enough to run it
- what happen if dont have enough resource ???
### 1.3 Fan-in
- on the other hand, Fan-in mean that from multiple branchs or task become only one task
- For example, I clean data at `clean_orders` and `clean_customer`, now I wanna create a report after that. I will use Fan-in
- Syntax in python `[clean_orders, clean_customers] >> build_report`
- A normal flow often combine Fan-in and Fan-out:
```
a general task -> fan-out-> run specific tasks -> Fan-in -> handle results,....
```
### 1.4 Characteristic of Dependency 
- It dont autamatically bring data from a task to its dependent task. We need to use TaskFlow/XCom or Cloud (S3,...), more detail in the below
- Dependency only apply in same DAG Run. For example:
    + extract_30 August -> clean_30 August: right
    + extract_30 August -> clean_30 August: wrong
### 1.5 Trigger rules
- Trigger will answer that what status at upstream tasks will make downstream tasks run:
    + all_success: entire upstream tasks succesfully run
    + all_failed: all upstream tasks failed 
    + all_done: the task will run when upstream tasks complete, dont care about it success or fail 
    + one_success: task run when one of upstream tasks run successfully 
    + one_failed: task run when one of upstream tasks failed ( for alerting as soon as possible)
    + none_failed: no upstream tasks fail (The status can be success or skipped)
    + none_failed_min_one_success: non upstream tasks failed and at least one success
    + none_skipped
    + all_done_min_one_success
### 1.6 Branching
- It allow the task choose one or multiple road to run
- Branch task can return:
    + A task_id
    + list task_id 
    + None 
- For example, use `@task.branch` to define it in Python code:
```
    @task.branch
    def choose_path(amount: int):
        if amount >= 10_000:
            return "process_large_order"

        return "process_small_order"
            @task
    def process_large_order():
        print("Manual review")

    @task
    def process_small_order():
        print("Automatic processing")

    branch = choose_path(15_000)
    large = process_large_order()
    small = process_small_order()

    branch >> [large, small]
```
- The task is returned that will be run and others will be skipped
### 1.7 Task group
- Task group use to group tasks, it's not a sub DAG, also dont have its scheduler, DAGs run,.. Tasks still contain in same DAG and DAG Run
- Task group is just a way to organize logic and UI 
- If want a independent workflow, we need to design a other DAG
### 1.8 Setup and teardown 
- I have normal flow like this: `create resource → handle task → delete resource`
    + Setup: mean that create resource for a task (such as cluster, temporary table,...)
    + teardown: mean that clean resoucre after complete a task (such as delete cluster, delete temporary table,...)
## 2. Communication and data handling:
### 2.1 XCom
- It help bring small data (File path, Table name, Record count, Job ID, Status,...) from task to task in Airflow
- For example: 
```
@task
def extract() -> str:
    return "s3://data/orders/2026-09-01.parquet"
@task
def transform(file_path: str):
    print(f"read file {file_path}")
path = extract()
transform(path)
```
### 2.2 Connection
- Store nesessary information to connect to external system and can reuse it in multiple DAG
- For example with PostgreSQL:
```
Connection ID: orders_postgres
Host: postgres.internal
Port: 5432
Database: orders
Username: airflow_user
Password: abc123
```
- And after that airflow can use it like:
```
SQLExecuteQueryOperator(
    task_id="read_orders",
    conn_id="orders_postgres",
    sql="SELECT * FROM orders",
)
```
### 2.3 Variable 
- It store general configs under key-value like this:
```
Key: environment
Value: production
```
- and Airflow can use it like this:
`environment = Variable.get("environment")`
- should use Variable for: enviroment name, bucketname, feature flags,...
### 2.4 Secrets management
- Use to store sensitive data like Password, API key, Access token, Private key, Database credential
### 2.5 external storage
- It use store real, large data and outside Airflow (S3, GCS, HDFS,...) 
## 3 Advanced task patterns
### 3.1 Dynamic Task Mapping
- It allow Airflow create number of Task Instance at runtime depend on real data:
- For example: 
```
@dag(schedule=None)
def process_files():

    @task
    def list_files() -> list[str]:
        return [
            "orders_1.csv",
            "orders_2.csv",
            "orders_3.csv",
        ]

    @task
    def process_file(filename: str):
        print(f"Processing {filename}")

    files = list_files()
    process_file.expand(filename=files)
process_files()
```
- If I have 3 file name in the returned list, Airflow create 3 Task Instance and run it in parallel
- Expand vs Partial:
    + Expand use for values change among Task Intances 
    + Partial use for not change value among Task Intances 
### 3.2 Dynamic DAG Generation
- not similar to Dynamic Task Mapping, Dynamic DAG Generation allow create DAG structure at parse time
- For example:
```
TABLES = [
    "orders",
    "customers",
    "products",
]

with DAG(...) as dag:
    for table in TABLES:

        @task(task_id=f"process_{table}")
        def process_table(table_name: str):
            print(table_name)

        process_table(table)
```
- The result is:
```
process_orders
process_customers
process_products
```
### 3.3 Sensor
- Sensor: is special type of tasks for waiting requirement  
    + Poke mode: keep worker live and wait a short time
    + Reschedule mode: check once if dont meet condition -> free resouce and schedule again
### 3.4 Deferrable Operators
-  It can automatically free worker slot and transfer waitng for triggers and condition meet requirement, worker will run task again 
## 4. Resource governance
- Airflow will manage information such as:
    + how many task can run
    + how many resouce a DAG can use
    + when lack of resource, which task is prioritize 
    + and something like that
### 4.1 Global parallelism
- `parallelism` appear the max number Task Intance can run at a time, dont care about the number of worker 
- add work dont make `parallelism` increase 
- Real capacity of Airflow is min(parallelism, executor capacity, worker capacity,..)
### 4.2 DAG concurrency
- There are 2 limitation:
    + The number of DAGs Run of DAG: max_active_runs 
    + Total task of DAG : max_active_tasks
- If at the time exceed numbers above, they need to wait to run 
### 4.3 Task concurrency
- The max number of Task Instance of a specific task: max_active_tis_per_dag

### 4.4 Pool
- Pool is the max number task use a specific resouce or external system at the time 
- For example, PostgreSQL just allow 5 query at same time but I have 100 worker. I need to set:
```
Pool name: postgres_heavy
Slots: 5
```
- Pool Slot: It means reletive weight of task
### 4.5 Priority weight
- In the situation, There are a lot of tasks need to run, but resource is not enough and Airflow need to decide which task will run first 
- We will set priority_weight, more priority_weight more prioritize 
### 4.6 Queues 
- use it to route task to the right workers 
- The most common Queue is `CeleryExecutor`

## 5. Observability
- It help answer:
    + what is Pipeline doing?
    + where is the Task error?
    + why dont  tasks run?
    + The system is slowing ?
### 5.1 Logs
- Logs are detail information recorded when running
- Task Logs: Each task have: DAG ID, Run ID, Task ID, try number,....
- Dont store secrets in logs 
### 5.2 Metrics
- Metrics are collected number continously by the time (such as: task per min, the number of failed tasks,...)
- Task metrics, It can include:
    + Task success count
    + Task failure count
    + Task retry count
    + Task duration
    + Scheduled task count
    + Queued task count
    + Running task count
    + Deferred task count
    + And then we can depend on numbers and generate dashboard to monitor 
- DAG metrics may include:
    + DAG Run success/failure
    + waiting time for first task 
    + the number of active DAG run 
    + the numver of DAG Run that missed deadline
- Scheduler metrics my include:
    + Scheduler heartbeat
    + Scheduler loop duration 
    + Critical section duration.
    + Executor heartbeat duration.
- Executor:
    + Executor open slots
    + Executor queued tasks
    + Executor running tasks
- Pool: 
    + Pool open slots
    + Pool used slots
    + Pool queued tasks
- Worker:
    + Worker online/offline
    + Worker active tasks
    + Worker CPU/RAM
### 5.3 Alerts
- Alerts is a automatic notification when the event happen
- It can send alerts to: Email, Slack,.... when task fail, success, retry,....
### 5.4 Task-state latency
- Scheduled latency
    + task is available to run but places at scheduled for a long time 
    + proof may be: Scheduler slow, Pool of out slot, parallelism reach limitation,....
    + Need to check: Scheduler health, Scheduler loop duration, Pool usage,...
- Queue latency:
    + task assigned but dont run
    + proof: may be not worker listen this queue, Worker out of concurrency, Worker offline,...
- Execution latency:
    + task is running but waste a lot of time to complete
    + proof: query low, data arrive suddenly,...
### 5.5 Scheduler and worker health
#### 5.5.1 Scheduler health 
- need to sure that:
    + Scheduler heartbeat
    + Scheduler loop
    + create DAG meet the deadline ?
- I need to check when see that:
    + Multiple DAGs are not creating runs
    + Multiple tasks are stuck in the Scheduled state
    + The scheduler heartbeat is stale
    + The scheduler loop duration has increased significantly
    + No tasks are being sent to the executor
#### 5.5.2 Worker health
- CeleryExecutor, monitor: 
    + Worker online/offline.
    + Worker heartbeat.
    + Active tasks.
    + Worker concurrency.
    + Queue backlog.
    + CPU/RAM/disk.
- KubernetesExecutor, because a Pod for a specific task, need to check 
    + Pod Pending
    + Pod Running
    + Pod Failed
    + ImagePullBackOff
    + CrashLoopBackOff
    + OOMKilled
    + Evicted
