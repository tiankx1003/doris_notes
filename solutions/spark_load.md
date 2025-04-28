# Spark Load

doris -> apache-doris-2.1.6-bin-x64
hadoop -> hadoop-3.3.6
hive -> hive-3.1.3
jdk -> jdk1.8.0_291
scala -> scala-2.12.17
spark -> spark-3.4.3


```bash
ln -s $SPARK_HOME/jars/spark*.jar $DORIS_HOME/fe/lib/
ln -s $HADOOP_HOME/share/hadoop/client/*.jar $DORIS/fe/lib/
zip -j $SPARK_HOME/spark_load_jars.zip $SPARK_HOME/jars/*

cat << EOF | tee $SPARK_HOME/conf/spark-env.conf
export JAVA_HOME=/opt/module/jdk1.8.0_291
export HADOOP_HOME=/opt/module/hadoop-3.3.6
export HADOOP_CONF_DIR=/opt/module/hadoop-3.3.6/etc/hadoop
export YARN_CONF_DIR=/opt/module/hadoop-3.3.6/etc/hadoop
export SPARK_DIST_CLASSPATH=$(${HADOOP_HOME}/bin/hadoop classpath)
EOF

cat << EOF | tee $DORIS_HOME/fe/conf/fe.conf
spark_home_default_dir = /opt/module/spark-3.4.3
spark_resource_path = /opt/module/spark-3.4.3/jars.zip
yarn_client_path = /opt/module/hadoop-3.3.4/bin/yarn
yarn_config_dir = /opt/module/hadoop-3.3.4/bin/etc/hadoop
EOF

echo "hello,world" > spark_load_test.csv
hadoop fs -put spark_load_test.csv hdfs://sofia:9000/user/tiankx/
```

```sql
-- doris
drop table if exists tmp.test_spark_load;
create table tmp.test_spark_load(c_id varchar(10), c_name varchar(10))
DISTRIBUTED BY HASH(c_id) BUCKETS 1
PROPERTIES ('replication_num' = '1');

DROP RESOURCE IF EXISTS "spark_cluster";
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
```