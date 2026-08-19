# Virtual Warehouse

## 1. What Is a Virtual Warehouse?

- A Virtual Warehouse is Snowflake's compute resource used to execute SQL statements and data processing workloads.


Flow: SQL -> Virtual Warehouse -> Result

## 2. Warehouse Size

Warehouses have sizes such as:

- X-Small
- Small
- Medium
- Large
- X-Large
- etc.

Larger warehouses provide more compute resources and generally cost more credits while running.

## 3. Main features of Virtual Warehouse

- Auto supspen: It can automatically stops a warehouse after it has been idle for the configured period.

- Auto-Resume: Auto-resume allows a suspended warehouse to start automatically when a workload needs it.

- Startup Time: compute need a little time to start
- Best Practice: Use the smallest warehouse and then tune based on workload and measured query performance.
- Cost: are the used credits.
Total credits = credit of the virtual WH per hour * amount of hours
