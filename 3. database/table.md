# Tables

## 1. Standard (Permanent) Table

A standard Snowflake table stores persistent data for analytical workloads.

```sql
CREATE TABLE orders (
    order_id NUMBER,
    customer_id NUMBER,
    amount NUMBER,
    order_date DATE
);
```

Data is organized internally into micro-partitions.

### When to use

- Bronze/raw data
- Silver/staging/transformed data
- Gold/fact/dimension data
- BI and analytics
- Production data
- Large scans and aggregations

---

## 2. Transient Table

A transient table is designed for data that does not require the same data-protection features as a permanent table.

```sql
CREATE TRANSIENT TABLE staging_orders (
    order_id NUMBER,
    amount NUMBER
);
```

### Characteristics

- Persists until explicitly dropped.
- Does **not** have Fail-safe.
- Supports Time Travel subject to Snowflake's retention rules.
- Useful for staging and intermediate data where Fail-safe is not required.

```text
Permanent Table
      |
      +-- Important production data
      +-- Full data protection

Transient Table
      |
      +-- Staging / intermediate data
      +-- No Fail-safe
```

---

## 3. Temporary Table

A temporary table exists only for the current session.

```sql
CREATE TEMPORARY TABLE temp_orders (
    order_id NUMBER,
    amount NUMBER
);
```

### Characteristics

- Only available within the session that created it.
- Automatically disappears when the session ends.
- Useful for intermediate calculations and session-specific work.
- Not intended for long-term persistent storage.

---

## 4. Hybrid Table

Hybrid Tables are designed for transactional and low-latency workloads while being part of Snowflake.

```sql
CREATE HYBRID TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    name VARCHAR,
    email VARCHAR
);
```

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

## 5. Table vs View

### Table

```text
Transformation -> Table -> Persistent data
```

The transformed result is stored as table data.

### Standard View

```text
SQL definition -> View -> Query executes underlying logic
```

A standard view does not store a separate copy of the query result.

---

## 6. Primary Key

```sql
CREATE TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    name VARCHAR
);
```

A primary key defines a logical uniqueness relationship.

For standard Snowflake tables, constraints such as primary keys and foreign keys are generally informational rather than enforced like traditional OLTP database constraints.

For data quality, tools such as dbt tests can be used to validate uniqueness and relationships.

---

## 7. Foreign Key

```sql
CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);
```

A foreign key describes a relationship between tables.

---

