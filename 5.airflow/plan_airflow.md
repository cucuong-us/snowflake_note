# Apache Airflow 3 — 3-Day Learning Plan

## Day 1 — Airflow 3 Fundamentals

### Main topics

- What Airflow is used for and when it is a suitable choice.
- Airflow 3 architecture and major components:
  - API Server
  - Scheduler
  - DAG Processor
  - Metadata Database
  - Executor and Workers
  - Triggerer
  - DAG Bundles
- Core workflow concepts:
  - DAGs and DAG Runs
  - Tasks and Task Instances
  - Operators and Sensors
  - Task states and dependencies
- Scheduling concepts:
  - Schedules
  - Logical dates and data intervals
  - Catchup and backfill
  - Manual and event-driven runs
- Reliable workflow design:
  - Idempotency
  - Retries and timeouts
  - Partition-based processing
  - Failure handling

### What you should understand

- How the main Airflow 3 components work together.
- How a DAG becomes a scheduled and executed workflow.
- How scheduling and historical data processing work.
- Why idempotency matters for retries and backfills.

### Learning links

- [Architecture Overview](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/overview.html)
- [Core Concepts](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/)
- [DAGs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html)
- [DAG Runs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dag-run.html)
- [Tasks](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/tasks.html)
- [Scheduler](https://airflow.apache.org/docs/apache-airflow/stable/concepts/scheduler.html)
- [Best Practices](https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html)

---

## Day 2 — Workflow Design and Resource Management

### Main topics

- Workflow structure and control flow:
  - Dependencies
  - Trigger rules
  - Branching
  - Task Groups
  - Setup and teardown tasks
- Communication and data handling:
  - XCom
  - Connections
  - Variables
  - Secrets management
  - External storage
- Advanced task patterns:
  - Dynamic Task Mapping
  - Dynamic DAG generation
  - Sensors
  - Deferrable operators
- Resource governance:
  - Global parallelism
  - DAG and task concurrency
  - Pools and pool slots
  - Priority weights
  - Queues
- Observability:
  - Logs
  - Metrics
  - Alerts
  - Task-state latency
  - Scheduler and worker health

### What you should understand

- How to organize complex workflows without creating unnecessary complexity.
- How to pass metadata and manage credentials safely.
- When to use dynamic tasks, sensors, and deferrable operators.
- How Airflow limits concurrency and protects downstream systems.
- Which metrics help identify scheduling and execution problems.

### Learning links

- [DAG Control Flow](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html#control-flow)
- [XComs](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/xcoms.html)
- [Dynamic Task Mapping](https://airflow.apache.org/docs/apache-airflow/stable/authoring-and-scheduling/dynamic-task-mapping.html)
- [Dynamic DAG Generation](https://airflow.apache.org/docs/apache-airflow/stable/howto/dynamic-dag-generation.html)
- [Sensors](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/sensors.html)
- [Deferrable Operators](https://airflow.apache.org/docs/apache-airflow/stable/authoring-and-scheduling/deferring.html)
- [Pools](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/pools.html)
- [Logging and Monitoring](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/logging-monitoring/index.html)
- [Metrics](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/logging-monitoring/metrics.html)

---

## Day 3 — Scaling and Production Architecture

### Main topics

- Executor options:
  - LocalExecutor
  - CeleryExecutor
  - KubernetesExecutor
  - Managed Airflow platforms
- Scaling Airflow components:
  - Scheduler scaling
  - Worker scaling
  - DAG processing capacity
  - Metadata database capacity
  - Broker capacity
  - Triggerer capacity
- Autoscaling:
  - Celery workers
  - KEDA
  - Kubernetes pods
  - Scaling limits and safeguards
- Performance and bottlenecks:
  - DAG parsing
  - Scheduling latency
  - Queue latency
  - Task granularity
  - Database pressure
  - Downstream-system limits
- Production architecture:
  - High availability
  - External PostgreSQL and broker
  - Remote logging
  - DAG distribution and versioning
  - Secrets and security
  - Backup and disaster recovery
- Operations and planning:
  - Capacity planning
  - SLOs and alerts
  - Backfill resource isolation
  - Cost and reliability trade-offs

### What you should understand

- How to select an executor for a workload.
- Which Airflow components need to scale independently.
- Why adding workers does not solve every performance problem.
- How to recognize scheduler, database, broker, worker, and downstream bottlenecks.
- What a production-ready Airflow 3 deployment should include.

### Learning links

- [Executor Overview](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/executor/index.html)
- [Administration and Deployment](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/index.html)
- [Database Setup](https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html)
- [Official Helm Chart](https://airflow.apache.org/docs/helm-chart/stable/index.html)
- [Helm Production Guide](https://airflow.apache.org/docs/helm-chart/stable/production-guide.html)
- [Configuration Reference](https://airflow.apache.org/docs/apache-airflow/stable/configurations-ref.html)

---
## plan day 4: dag parsing optimization
## plan day 5: general airflow optimisation and maintaince

