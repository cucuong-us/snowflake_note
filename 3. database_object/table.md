# Tables

## 1. Standard (Permanent) Table

- A standard Snowflake table stores persistent data for analytical workloads.

- Data is organized internally into micro-partitions.

### When to use

- use for most of situations.For example, table for bronze, silver and gold layer table,...

---

## 2. Transient Table

A transient table is designed for data that does not require the same data-protection features as a permanent table.
### Characteristics

- Persists until explicitly dropped.
- Does **not** have Fail-safe.
- Supports Time Travel subject to Snowflake's retention rules.
- Useful for staging and intermediate data where Fail-safe is not required.
- Compared Permanent Table to Transient Table
    + Permanent Table: Important production data or Full data protection
    + Transient Table: Staging / intermediate data and No Fail-safe

---

## 3. Temporary Table

A temporary table exists only for the current session.

### Characteristics

- Only available within the session that created it.
- Automatically disappears when the session ends.

---

## 4. Hybrid Table

Hybrid Tables are designed for transactional and low-latency workloads while being part of Snowflake.

They support primary keys and indexes that are important for point lookups and transactional access patterns.

Example:

```sql
SELECT *
FROM customers
WHERE customer_id = 12345;
```

### When to use

- Transactional workloads
- Low-latency point lookups
- Frequent inserts/updates/deletes
- Key-based access patterns

---

