# Views

## 1. Standard View

- A standard view is a database object that stores a SQL definition.
- It does not store the query result.

Use a standard view when:

- want to reuse SQL logic.
- The query is relatively simple.
- You do not need to store another copy of the result.

## 2. Secure View

- A secure view protects the view definition and limits potential exposure of underlying data.
- it may be slower than a standard view.

Use a secure view when:

- Data privacy is important.
- need to share data securely.
- Users should not see the underlying SQL definition.

## 3. Materialized View

- A materialized view stores both a SQL definition and its precomputed result.
- Snowflake automatically maintains the stored result when the base table changes.
- It requires additional storage and maintenance cost.

Use a materialized view when:

- The same expensive query runs frequently.
- Faster query performance is required.

## 4. Temporary and Recursive Views

### Temporary View

- A temporary view exists only within the session that created it.
- It is automatically removed when the session ends.

