# Learning Guide

## 1. What happens when this project runs?

When you execute `dbt build`, dbt:

1. Parses SQL, YAML, Jinja and project configuration.
2. Resolves every `source()` and `ref()` call.
3. Creates a directed acyclic graph (DAG).
4. Compiles Jinja into Snowflake SQL.
5. Wraps each model query in the DDL/DML required by its materialization.
6. Sends the SQL to Snowflake in dependency order.
7. Runs data tests at the correct places in the DAG.
8. Writes artifacts such as `manifest.json` and `run_results.json`.

dbt coordinates the work; Snowflake reads, computes and stores the data.

## 2. Follow one field through the project

`RAW_SHOP.ORDER_ITEMS.UNIT_PRICE_CENTS` follows this path:

```text
RAW_SHOP.ORDER_ITEMS.UNIT_PRICE_CENTS
  → stg_shop__order_items.unit_price
  → int_orders__item_aggregates.gross_order_amount
  → int_orders__enriched.gross_order_amount
  → fct_orders.gross_order_amount
  → fct_daily_revenue.gross_order_amount
```

This is column-level business lineage. `source()` and `ref()` establish resource-level lineage.

## 3. Why each layer exists

### Sources

`_shop__sources.yml` declares raw relations dbt reads but does not own. Source tests catch problems before bad data reaches marts. Freshness compares `_loaded_at` against the current time.

### Staging

Every staging model reads one source table. It standardizes names, types and basic values but avoids major joins and business aggregations. The project materializes staging models as views.

### Intermediate

Intermediate models make business logic modular and reusable. They are ephemeral in this demo, so dbt injects them into downstream SQL as CTEs instead of creating separate Snowflake relations.

### Marts

Marts expose stable business entities and events:

- `dim_customers`: one row per customer
- `dim_products`: one row per product
- `fct_orders`: one row per order
- `fct_order_items`: one row per order line
- `fct_daily_revenue`: one row per reporting date

Always document a mart's grain. Most severe data-modeling bugs are grain mistakes.

## 4. Materializations in this project

| Materialization | Example | Behavior |
| --- | --- | --- |
| View | Staging models | Stores query definition; computes at query time |
| Ephemeral | Intermediate models | Injected as CTE; no warehouse object |
| Table | Dimensions and facts | Rebuilt as a physical table |
| Incremental | `fct_daily_revenue` | Merges only recent partitions after first run |

The incremental model reprocesses a three-day lookback window. This captures late-arriving changes rather than trusting only rows newer than the latest target date.

## 5. Tests in this project

There are four useful levels:

1. Source tests: confirm raw identifiers are present and unique.
2. Generic tests: `unique`, `not_null`, `relationships`, `accepted_values`.
3. Custom generic tests: `positive_value` and `not_in_future`.
4. Singular tests: full SQL queries representing business-rule violations.

A data test passes when its query returns zero failing rows.

## 6. Snapshots versus incremental models

- The customer snapshot preserves historical versions of changing source records.
- The incremental revenue model reduces compute by processing a bounded time window.

Snapshots solve history; incremental models solve processing efficiency. They are not substitutes.

## 7. Development isolation

The custom `generate_schema_name` macro combines the target schema with the configured layer schema. If your target schema is `DBT_ANNIE`, models are created in:

```text
DBT_ANNIE_STAGING
DBT_ANNIE_MARTS
DBT_ANNIE_FINANCE
DBT_ANNIE_REFERENCE
```

Another developer can use `DBT_BOB_*` schemas without overwriting your relations. Production can use a stable target schema such as `ANALYTICS`.

## 8. Seeds, analyses and exposures

- A seed is a small CSV controlled in Git and loaded by dbt.
- An analysis is compiled SQL that dbt does not materialize.
- An exposure documents a downstream dashboard, notebook or application and links it to its dbt dependencies.

## 9. Recommended exercises

1. Change a source column name and inspect the compile error.
2. Add a duplicate order ID and observe the source test fail.
3. Run `dbt ls --select +fct_orders` to inspect graph selection.
4. Change staging from view to table at folder level.
5. Add a `dim_dates` model generated from a date spine.
6. Add a discount field and trace it through staging to revenue.
7. Update one raw customer, rerun the snapshot and inspect `dbt_valid_from`/`dbt_valid_to`.
8. Add a schema column to the incremental model and compare `append_new_columns` with `fail`.
9. Generate docs and inspect the exposure lineage.
10. Replace the full CI build with state-based selection after storing a production `manifest.json`.

## 10. Production improvements to add later

This project shows the structure but a real organization should additionally decide:

- Key-pair/OAuth authentication and secret rotation
- Separate CI and production service accounts
- Warehouse sizing, resource monitors and query tags
- Role/grant ownership, often managed with Terraform
- Job schedules, retries, alerts and SLAs
- Artifact storage and state-based Slim CI
- Data classification, masking policies and row access policies
- Contracts and versioning rules for public models
- Observability beyond pass/fail tests
- Cleanup of obsolete development and CI schemas

