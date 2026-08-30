# Apache Airflow 3 + Amazon MWAA Notes
![alt text](image.png)
## 1. Airflow 3 and Airflow 2

- Airflow 3 separates its main parts more clearly.
- Airflow 3 adds the Task SDK and Task Execution API.
- In Airflow 2, task code could connect to the Metadata Database directly.
- In Airflow 3, task code normally talks to the API instead.
- The Dag Processor is a separate required part in Airflow 3.
- New Dag code should import from `airflow.sdk`.
- Airflow 3 can use more than one Executor at the same time.
- The Scheduler now manages backfills.


## 2. Main Airflow Components

### Scheduler

- Reads DAG schedules.
- Determines which tasks are ready.
- Sends ready tasks to the queue.
- Does not execute tasks directly.

### Worker
- Receives and executes tasks.
### Metadata Database

- Stores DAG Run and Task Instance status.
- Stores execution history, connections, configuration, and other metadata.
- Should not be used to store large business datasets.

### DAG Processor

- Reads and parses Python DAG files.
- Converts DAG code into structures understood by the scheduler.

### Triggerer

- Handles deferrable tasks.
- Allows tasks to wait for events without holding a worker for the entire waiting period.

---

## 3. Why Airflow Needs Scaling

Scale workers when:

- Many tasks run concurrently.
- Python tasks use significant CPU or RAM.
- Tasks run for a long time.
- Many tasks remain queued.

---

## 4. Where Tasks Run

### Normal Python Code

- `PythonOperator`, TaskFlow `@task`, and `BashOperator` normally run on Airflow workers.
- The code uses the worker's CPU and RAM.
- Avoid running the work directly on workers when:
  - The dataset is large.
  - The task needs significant CPU or memory.
  - The task uses Spark.
  - The task requires a complex runtime environment.

### Spark

- Spark should normally not run inside an Airflow worker.
- Airflow starts the Spark job and monitors its status.
- The Spark job runs on:
  - Databricks.
  - Amazon EMR.
  - AWS Glue.
  - Kubernetes.
  - A separate Spark cluster.

### Databricks

- Using Airflow to schedule Databricks jobs is common.
- Airflow handles orchestration.
- Databricks handles data processing.

```text
Airflow
  -> starts a Databricks job
  -> waits for the result
  -> runs the next task
```

---

## 5. Data Crawling with Airflow

# Amazon MWAA

## 6. MWAA

- MWAA stands for Amazon Managed Workflows for Apache Airflow.
- It is a managed Airflow service provided by AWS.

AWS manages:

- Scheduler.
- Workers.
- Web/API servers.
- Metadata database.
- Infrastructure replacement.
- Auto scaling.
- Airflow maintenance and patching.

The user still manages:

- DAG code.
- Python dependencies.
- Custom plugins.
- IAM execution role.
- VPC, subnets, and Security Groups.
- Airflow configuration.
- Logs and costs.
- Permissions required by tasks.

---

## 7. Self-Hosted Airflow vs. MWAA

### Self-Hosted Airflow

- Set up the scheduler, workers, web server, and database.
- Configure Celery, Kubernetes, or another executor.
- Back up the metadata database.
- Upgrade Airflow manually.
- Monitor and recover failed components.
- Scale workers and web servers manually.
- More flexible but harder to operate.

### Amazon MWAA

- AWS deploys and operates the Airflow components.
- Select an environment class and scaling limits.
- Upload DAGs and supporting files to S3.
- Configure networking and IAM.
- Less infrastructure work.
- Less system-level control.
- Often more expensive than running one small server, but requires less operational work.

---

# VPC and Networking

## 9. Why MWAA Needs a VPC

- MWAA components need a network environment in which to communicate.
- A VPC is a private network inside AWS.
- Workers may need to access:
  - S3.
  - Databases.
  - Databricks.
  - External APIs.
  - ECS, Glue, EMR, and other AWS services.
- A VPC does not provide CPU or RAM.
- It provides:
  - IP addresses.
  - Subnets.
  - Routes.
  - Security Groups.
  - Network connectivity.

### Compared with Local Airflow

Local:

- The local computer provides CPU and RAM.
- The local network allows processes to communicate.

MWAA:

- AWS provides the compute.
- The VPC provides the shared network.

---

## 10. MWAA Access to S3

- MWAA always requires a VPC, not only because it needs S3.
- MWAA can reach S3 from private subnets through:
  - A NAT Gateway.
  - An S3 VPC Endpoint.
- IAM determines whether MWAA is allowed to read S3 objects.
- Networking determines whether MWAA has a path to S3.

```text
VPC and routes: Is there a network path?
IAM: Is the action permitted?
```

---

# Security Groups

## 13. Security Group Basics

- A Security Group is a firewall attached to network resources.
- It controls allowed inbound and outbound traffic.
- Security Groups are stateful:
  - If an outbound request is allowed, its response is automatically allowed.
  - No separate inbound rule is required for that response.

### Inbound

- Controls connections initiated from another resource.
- Examples:
  - An application connects to a database.
  - A user connects to a web server.

### Outbound

- Controls connections initiated by the resource.
- Examples:
  - An MWAA worker calls an API.
  - A worker connects to a database.
  - A worker accesses the Internet.

### Choosing the Rule Direction

- Do not choose inbound or outbound based on the AWS service.
- Identify which side starts the connection.
- The request sender uses outbound.
- The request receiver requires inbound.

---

## 14. MWAA Security Groups

- MWAA can create a new Security Group automatically.
- The default VPC Security Group is not required.
- The Security Group must allow MWAA components to communicate.

When MWAA connects to a database:

- The MWAA Security Group needs outbound access.
- The database Security Group needs inbound access from the MWAA Security Group.
- Prefer Security Group IDs as sources instead of broad IP ranges.
---  

## 15. IAM 

- IAM defines who can perform which actions on which AWS resources.

The identity can be:

- A user.
- An application.
- EC2.
- Lambda.
- MWAA.
- A worker executing an Airflow task.

---

## 16. MWAA Execution Role

- MWAA uses a shared execution role.
- Scheduler, workers, and web servers do not require separate roles.
- Tasks running on workers use the MWAA execution role.

For example, an S3-reading task may require:

- `s3:GetObject`
- `s3:ListBucket`

- Tasks that start Glue, ECS, or other services need the corresponding permissions.

### Automatically Creating the Role

- Selecting `Create a new role` allows MWAA to create the execution role.
- The initial role normally allows MWAA to:
  - Read DAGs from S3.
  - Write logs to CloudWatch.
  - Access required internal MWAA resources.
- Add policies later when DAG tasks require additional services.
- Follow the principle of least privilege.

### CloudFormation IAM Role

- The optional CloudFormation role is used by CloudFormation to create resources.
- It is not the MWAA execution role.
- If the signed-in identity already has enough permissions, it can be left empty.
- CloudFormation then uses the permissions of the signed-in identity.

---

# S3 and DAG Code

## 17. Uploading a DAG to S3

- MWAA does not read DAG files directly from a local computer.
- DAG files must be uploaded to the configured S3 folder.

```text
s3://mwaa-dev-cuong-a8f3k2/dags/
```

- MWAA synchronizes files from this folder.
- The DAG processor parses the Python files and registers the DAGs.
