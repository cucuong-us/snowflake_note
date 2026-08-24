## 1. Snapshot
- Snapshot mean that 
- The Snapshot template:
```
snapshots:
  - name: string
    relation: relation
    description: markdown_string

    config:
      database: string
      schema: string
      alias: string
      strategy: timestamp | check
      unique_key: column_name_or_expression
      check_cols: [column_name] | all
      updated_at: column_name
      snapshot_meta_column_names: dictionary
      dbt_valid_to_current: string
      hard_deletes: ignore | invalidate | new_record
```
- Explain the template:
    + name: name of object in dbt
    + relation: source of object we want to check
    + description: describe this object 
    + database and schema: their name
    + strategy:
        + timestamp: if the table have a column `update_at`, data in this column will be used for `valid_from` and `valid_to` column
        + check: if the table have no column like `update_at` the time of snapshot will be used for `valid_from` and `valid_to` column
    + dbt_valid_to_current: define `valid_to` column when the record still valid, default is NULL
    + hard_delete: 
        + ignore: the row disappear will be ignord 
        + invalidate: the row disapear, the time of snapshot will be considered to the value of `valid_to` column
        + new_record: dbt will add `dbt_is_deleted`column to track it 
### transfer dbt snapshot to SQL:
- First time to run snapshot, it will create a table and load entire records
- From second run: the SQL look like:
```
select
    source.*,
    snapshot.dbt_scd_id as old_dbt_scd_id,

    case
        when snapshot.customer_id is null
            then 'insert'

        when source.updated_at > snapshot.dbt_updated_at
            then 'update'

        else 'unchanged'
    end as dbt_change_type

from RAW.CRM.CUSTOMERS as source

left join ANALYTICS.SNAPSHOTS.CUSTOMERS_HISTORY as snapshot
    on source.customer_id = snapshot.customer_id
   and snapshot.dbt_valid_to is null;
```
- left join to find records need to insert or update, it similar to merge with source is RAW.CRM.CUSTOMERS and target is snapshot table
## 2. Incremental
```
models:
  - name: my_incremental_model
    config:
      materialized: incremental
      unique_key: id
      cluster_by: ['session_start']  
      incremental_strategy: merge
      incremental_predicates: ["DBT_INTERNAL_DEST.session_start > dateadd(day, -7, current_date)"]
     
```
- name:is the name of dbt model
- materialize: there are 4 options, choose incremental to make it become incremental model
    + view
    + table 
    + incremental
    + enphemeral 
- unique_key: tells dbt which column uniquely identifies one record
- cluster_by: choose key to cluster
- incremental strategy: only have when set materalize = incremental, there are some options:
    + merge: record with same unique_key will be update, with new unique_key -> insert, keep data if unique_key dont appear
    + append: always insert in both update and new records
    + delete + insert: delete all rows, that match unique_key, after that insert new records. (same id 2 row is coming, keep 2 row)
    + overwrite: overwrite entire target table
    + microbatch: divide large dataset into many bathch and process it with delete+insert mode
- incremental_predicates: add some additional conditions to join 

## Transform dbt to SQL

- materalize: incremental. this is a same template for all strategy
```
select
    id,
    status,
    updated_at
from RAW.APP.ORDERS
where updated_at >= dateadd(day, -3, current_date)
```
- For particular mode:
    + append:
```
insert into ANALYTICS.DBT.ORDERS (
    id,
    status,
    updated_at
)
select
    id,
    status,
    updated_at
from ORDERS__DBT_TMP;

```
+ merge:

```
merge into ANALYTICS.DBT.ORDERS as DBT_INTERNAL_DEST

using ORDERS__DBT_TMP as DBT_INTERNAL_SOURCE

on DBT_INTERNAL_DEST.id = DBT_INTERNAL_SOURCE.id

when matched then update set
    status = DBT_INTERNAL_SOURCE.status,
    updated_at = DBT_INTERNAL_SOURCE.updated_at

when not matched then insert (
    id,
    status,
    updated_at
)
values (
    DBT_INTERNAL_SOURCE.id,
    DBT_INTERNAL_SOURCE.status,
    DBT_INTERNAL_SOURCE.updated_at
);
```
+ delete+insert: 
```
delete from ANALYTICS.DBT.ORDERS as DBT_INTERNAL_DEST

using ORDERS__DBT_TMP as DBT_INTERNAL_SOURCE

where DBT_INTERNAL_DEST.id = DBT_INTERNAL_SOURCE.id;
```
```
insert into ANALYTICS.DBT.ORDERS (
    id,
    status,
    updated_at
)
select
    id,
    status,
    updated_at
from ORDERS__DBT_TMP;
```
+ overwrite: delete entire table and write new data
+ microbatch: create temporary table for batch and process it with `delete+insert`
```
create temporary table EVENTS__DBT_TMP as
select
    id,
    status,
    event_timestamp
from RAW.APP.EVENTS
where event_timestamp >= '2026-08-21 00:00:00'
  and event_timestamp <  '2026-08-22 00:00:00';
```
