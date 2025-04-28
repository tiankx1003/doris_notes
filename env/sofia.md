# Sofia
 * *since: 2024-10-07 22:32:28*
 * tiankx@192.168.3.9
 * -p 6000 tiankx@melina

doris-2.1.6
spark-3.3.0
hadoop-3.3.4



mysql -uroot -hsofia -P9038

./bin/spark-submit --class org.apache.doris.load.loadv2.etl.SparkEtlJob \
--master yarn \
--deploy-mode cluster \
--driver-memory 1g \
--executor-memory 1g \
--executor-cores 1 \
--queue root.default \
examples/jars/spark-examples*.jar \
10


./bin/spark-submit --class org.apache.spark.examples.SparkPi \
--master yarn \
--deploy-mode cluster \
--driver-memory 1g \
--executor-memory 1g \
--executor-cores 1 \
--queue root.default \
examples/jars/spark-examples*.jar \
10

```sql
DROP RESOURCE "spark_cluster";
CREATE EXTERNAL RESOURCE "spark_cluster"
PROPERTIES
(
  "type" = "spark",
  "spark.master" = "yarn",
  "spark.submit.deployMode" = "cluster",
  -- "spark.yarn.jars" = "hdfs://sofia:9000/spark_load/149011061/__spark_repository__spark_cluster/__archive_1.2-SNAPSHOT/spark-yarn_2.12-3.4.3.jar",
  -- "spark.files" = "/tmp/aaa,/tmp/bbb",
  -- "spark.sql.parquet.fieldId.write.enabled" = "false",
  "spark.executor.memory" = "1g",
  "spark.yarn.queue" = "default",
  "spark.hadoop.yarn.resourcemanager.address" = "sofia:8032",
  "spark.hadoop.fs.defaultFS" = "hdfs://sofia:9000",
  "working_dir" = "hdfs://sofia:9000/spark_load",
  "broker" = "sofia_hdfs",
  "broker.username" = "tiankx",
  "broker.password" = "tiankx"
);
LOAD LABEL tmp.test_spark_load9 (
    DATA INFILE("hdfs://sofia:9000/user/tiankx/test_spark_load.csv")
    INTO TABLE test_spark_load
    COLUMNS TERMINATED BY ","
    (tmp_c1,tmp_c2)
    SET (c_id=tmp_c1,c_name=tmp_c2)
)
WITH RESOURCE 'spark_cluster'
("spark.executor.memory" = "1g", "spark.shuffle.compress" = "true")
PROPERTIES ("timeout" = "3600");

show load from tmp order by createtime desc limit 1\G


CREATE CATALOG hive PROPERTIES (
    'type'='hms',
    'hive.metastore.uris' = 'thrift://sofia:9083',
    'hadoop.username' = 'tiankx'
);

LOAD LABEL tmp.test_spark_load_hive01
(
    DATA FROM TABLE hive_t1
    INTO TABLE test_spark_load
)
WITH RESOURCE 'spark_cluster'
(
    "spark.executor.memory" = "2g",
    "spark.shuffle.compress" = "true"
)
PROPERTIES
(
    "timeout" = "3600"
);

CREATE EXTERNAL RESOURCE "spark_client"
PROPERTIES
(
  "type" = "spark",
  "spark.master" = "spark://sofia:7077",
  "spark.submit.deployMode" = "client",
  "working_dir" = "hdfs://sofia:9000/spark_load",
  "broker" = "sofia_hdfs",
  "broker.username" = "tiankx",
  "broker.password" = "tiankx"
);


drop table if exists tmp.test_spark_load;
create table tmp.test_spark_load(c_id varchar(10), c_name varchar(10))
DISTRIBUTED BY HASH(c_id) BUCKETS 1
PROPERTIES ('replication_num' = '1');



-- drop spark resource
DROP RESOURCE resource_name

-- show resources
SHOW RESOURCES
SHOW PROC "/resources"

-- privileges
GRANT USAGE_PRIV ON RESOURCE resource_name TO user_identity
GRANT USAGE_PRIV ON RESOURCE resource_name TO ROLE role_name

REVOKE USAGE_PRIV ON RESOURCE resource_name FROM user_identity
REVOKE USAGE_PRIV ON RESOURCE resource_name FROM ROLE role_name



CREATE EXTERNAL TABLE `tmp`.`hive_t1` (
  `c_id` varchar(10) NULL COMMENT "",
  `c_name` varchar(10) NULL COMMENT ""
) ENGINE = hive
PROPERTIES (
"hive.metastore.uris" = "thrift://sofia:9083",
"database" = "tmp",
"table" = "test_spark_load"
);

show load from tmp order by createtime desc limit 1\G


CREATE CATALOG hive PROPERTIES (
    'type'='hms',
    'hive.metastore.uris' = 'thrift://sofia:9083',
    'hadoop.username' = 'tiankx'
);

LOAD LABEL tmp.test_spark_load_hive01
(
    DATA FROM TABLE hive_t1
    INTO TABLE test_spark_load
)
WITH RESOURCE 'spark_cluster'
(
    "spark.executor.memory" = "2g",
    "spark.shuffle.compress" = "true"
)
PROPERTIES
(
    "timeout" = "3600"
);


```