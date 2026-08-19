# Database structure
```Snowflake Account
       |
       +-- Database
              |
              +-- Schema
              |     |
              |     +-- Table
              |     +-- View
              |     +-- Stage
              |     +-- Stream
              |     +-- Task
              |     +-- ...
              |
              +-- Schema
                    |
                    +-- Table
                    +-- View
                    +-- ...
                    
```


## 1. Database

A **Database** is a logical container for schemas and database objects in Snowflake.

```sql
CREATE DATABASE analytics;
```
## 2. Schema
A **Schema** is a folder to store Snowflake objects (View, Table,...)
