# Virtual Warehouse

## 1. What Is a Virtual Warehouse?

A Virtual Warehouse is Snowflake's compute resource used to execute SQL statements and data processing workloads.

```text
SQL -> Virtual Warehouse -> Result
```

A warehouse is separate from Snowflake's persistent storage.

## 2. Warehouse Size

Warehouses have sizes such as:

- X-Small
- Small
- Medium
- Large
- X-Large
- etc.

Larger warehouses provide more compute resources and generally cost more credits while running.

## 3. Auto-Suspend

Auto-suspend automatically stops a warehouse after it has been idle for the configured period.

```sql
ALTER WAREHOUSE my_wh
SET AUTO_SUSPEND = 60;
```

This is useful for reducing idle compute cost.

## 4. Auto-Resume

Auto-resume allows a suspended warehouse to start automatically when a workload needs it.

```sql
ALTER WAREHOUSE my_wh
SET AUTO_RESUME = TRUE;
```

## 5. Important Cost Idea

Warehouse compute cost is primarily related to:

- Warehouse size
- How long it runs
- Number of clusters
- Pricing/edition/cloud/region

It is not simply a direct "number of rows processed = price" model.

## 6. Startup Time

If a warehouse is suspended, resuming it may introduce a small startup delay. Auto-suspend saves idle credits at the cost of potentially having to resume later.

## 7. Best Practice

Use the smallest warehouse that provides acceptable performance, then tune based on workload and measured query performance.
## 8. Cost

Cost are the used credits.
Total credits = credit of the virtual WH per hour * amount of hours
