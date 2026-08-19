# Multi-Cluster Warehouses

## 1. What Is a Multi-Cluster Warehouse?

- A multi-cluster warehouse can run multiple compute clusters to handle concurrency.

## 2. MIN_CLUSTER_COUNT and MAX_CLUSTER_COUNT

Example:

```sql
CREATE WAREHOUSE my_wh
WITH
    WAREHOUSE_SIZE = 'MEDIUM'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3;
```

`MAX_CLUSTER_COUNT = 3` means Snowflake is allowed to scale the warehouse up to three clusters.

It does not mean three clusters always run.

Snowflake decides how many clusters are needed based on workload and the configured scaling policy.

## 3. Maximized vs Auto-scale

### Maximized

The warehouse runs the configured maximum number of clusters continuously while it is running.

For example:

```text
MIN = 3
MAX = 3

Running:
Cluster 1
Cluster 2
Cluster 3
```

### Auto-scale

The warehouse can start with fewer clusters and add clusters when needed, up to the maximum.

```text
Normal:
Cluster 1

High concurrency:
Cluster 1
Cluster 2
Cluster 3
```

## 4. When to Use

Multi-cluster warehouses are useful when many users/jobs query the same warehouse concurrently and queries are waiting because of concurrency.

They are not primarily a solution for a single slow query caused by an inefficient SQL plan.

