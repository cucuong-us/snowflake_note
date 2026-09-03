 # DAG Parsing Optimization
 ## 1. DAG parsing lifecycle
 - DAGs are parsed by DAG processor, it convert python code to a structured and serialized DAG
 - from that Scheduler and API server can use it 
### 1.1 DAG discovery
- DAG processor will scan file that contain DAG code (DAG bundle) such as:
    + a local DAG directory
    + a git repository
    + a S3 or GCS location
- and after scan file Airflow will decide which file should be parsed
- it will check periodically to check new file and parse them
- .airflowignore use make Airflow it ignore some file or folder
- Safe mode: 
    + it a machenism help airflow check keyword 'airflow' or 'dag' all file
    + this step just filter file, dont choose file to parse
### 1.2 Python file execution
- airflow will import library at top-level first
- airflow will scan files every min_file_process_interva time 
=> `To optimize dont place import library API call, query DB, read lagre file at top level, heavy caculation,... because airflow will import them every scan can make Parse DAG timeout, should place it in task, it will run when Task Instance execute`
### 1.3 DAG object creation 
- this step Airflow will build DAG structure in its memory, for example:
```
DAG: daily_sales
    Task: extract
    Task: transform
    Task: load
```
- It also define: dag_id, schedule, Task, dependencies, trigger rule, retries, timeout, pools,parameters,...
### 1.4 DAG validation  
- not a independent service, it happen when parse DAG
- something it check:
    + duplicate task_id: in a DAG can have 2 task with same task_id
    + no loop dependency: because DAG is acyclic, so no loop 
    + duplicate dag_id: similar to task_id
### 1.5 DAG serialization
- after validate, airflow serilize it become JSON to store in metadata DB, for example:
```
{
  "dag_id": "daily_sales",
  "schedule": "@daily",
  "tasks": [
    {
      "task_id": "extract",
      "downstream_task_ids": ["transform"]
    },
    {
      "task_id": "transform",
      "downstream_task_ids": []
    }
  ]
}
```
- serilize help just parse once and all component can query and run it in metadata DB with user code, decrease effort for parsing
- metadata DB will store 2 information:
    + definition of the flow such as: Serialized DAG, DAG metadata, Tasks và dependencies, Schedule,...
    + runtime status: DAG Runs, Task Instances, Task states, XCom metadata, Variables and Connections, Trigger/deferred-task state,...
- scheduler will read this data to:
    + define DAGs
    + create DAG Run
    + decide which Task Instance is enough dependency and send it to executor
### 1.6 Some parameters 
- refresh_interval: how long to refresh to find new file, deleted file, for example with GitDagBundle, it check new git version
- bundle_refresh_check_interval: how long to loop and check which bundle is expire 
- min_file_process_interval: parse files Airflow knew (because value may be change, for example, there is a API call, that value change)
- parsing_processes: the number of parse in parallel
- file_parsing_sort_mode:
    + modified_time: just adjust -> prioritize to parse it
    + alphabetical  
    + random_seeded_by_host: when have multi DAG processor 
- dagbag_import_timeout: max time for import python file 
- dag_file_processor_timeout: max time for handle a DAG
- min_serialized_dag_update_interval: how long update serilized DAG into metadata DB
- parsing_pre_import_modules: remember modul imported in previous import 
- stale_dag_threshold: when parse and dont see a dag, dont deactive immerdiately, because parsing may be not completed
=> when deploy new DAG, the latency is defined: bundle refresh + parsing queue + time to parse files + serialized DAG write to DB + Scheduler read and process  
=> depend on the business to optimize them 
## 2. DAG File Organization and Discovery
- Airflow dont bring DAG by DAG to queue, it will bring DAG file and DagFileProcessorProcess looking for DAG in this file
### 2.1 One DAG per file vs multiple DAGs per file
- One DAG per file, best for large and indenpendent DAGs:
    + Pros: maintenance, one error just affect only a DAG, parse in parallel and easy to find which parsing low
    + cons: incrase discovery, may be redundant import library
- many DAG in a file:
    + Pros: avoid duplicate code and import 
    + cons: 1 import error can make whole DAG fail to load, lagre file make it become parsing bottleneck and cant parse in parallel
### 2.2 some signs of poor file organization
- some file have large last_duration
- many DAG loss because only 1 error import
- increase parsing_processes but throughput not change