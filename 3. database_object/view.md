# Views

## 1. Standard View

A standard view is a database object that stores a SQL definition rather than a separate physical copy of the query result.

```sql
CREATE VIEW v_orders AS
SELECT
    order_id,
    customer_id,
    amount
FROM raw.orders
WHERE amount > 100;
```

When you run:

```sql
SELECT *
FROM v_orders;
```

Snowflake uses the view definition to execute the underlying query against current data.


## 2. When to Use a Standard View

Use a view when:

- Logic is relatively simple.
- You want the query to use current underlying data.
- You do not need to materialize another copy of the result.
- Reusing a SQL definition is useful.

## 3. Secure View

A secure view provides additional protection around information exposed through the view, which is useful for data sharing and security-sensitive use cases.

```sql
CREATE SECURE VIEW customer_public AS
SELECT
    customer_id,
    name,
    email
FROM customers;
```

Secure views should be considered together with Snowflake's broader access-control and data-governance features.


## 4. Important Note

A view does not mean "a file containing SQL".

In a dbt project:

```text
models/staging/stg_orders.sql
```

is source code.

After `dbt run`, Snowflake can contain:

```text
STG_ORDERS
    |
    +-- VIEW object
```

The view object has a SQL definition managed by Snowflake.
