# Snowflake Architecture

## 1. Storage and Compute Separation

### Storage

Snowflake manages the persistent data layer. Tables store data in Snowflake-managed storage.

Objects such as databases, schemas, tables, and views are managed as database objects and metadata.

### Compute

A **Virtual Warehouse** provides compute resources for executing SQL and data processing.

A warehouse can be suspended when it is not needed and resumed when work needs to run.

## 2. Shared-nothing vs Snowflake

Traditional shared-nothing systems distribute data and compute across nodes. Snowflake uses a cloud-native architecture where storage and compute are separated, allowing compute resources to scale independently from storage.

## 3. Why Separation Matters

- Scale compute independently from storage.
- Different workloads can use different warehouses.
- Warehouses can be resized or scaled independently.
- A warehouse can be suspended when idle.
- Multiple teams/workloads can use separate compute resources against the same underlying data.

## 4. Key Mental Model

```text
Snowflake
|
+-- Storage
|   +-- Databases
|   +-- Schemas
|   +-- Tables
|   +-- Views
|
+-- Compute
    +-- Virtual Warehouses
```

## 5. Important Distinction

A suspended warehouse does **not** mean the Snowflake database disappears.

The data and database objects remain available. Compute is simply not actively running for that warehouse.
