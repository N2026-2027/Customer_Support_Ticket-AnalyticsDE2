# scripts/spark_ingestion.py
import os
from pyspark.sql import SparkSession

# Configuramos las rutas de tu instalación manual (visto en tu imagen)
os.environ['JAVA_HOME'] = '/workspaces/Customer_Support_Ticket-AnalyticsDE2/batch/jdk-11.0.2'
os.environ['SPARK_HOME'] = '/workspaces/Customer_Support_Ticket-AnalyticsDE2/batch/spark-3.3.2-bin-hadoop3'

# Iniciamos Spark
spark = SparkSession.builder \
    .appName("Ingestion_Multi_Dataset") \
    .master("local[*]") \
    .config("spark.jars.packages", "org.duckdb:duckdb_jdbc:0.10.3") \
    .getOrCreate()

DUCKDB_PATH = "/workspaces/Customer_Support_Ticket-AnalyticsDE2/duckdb/support.duckdb"

# Dataset 1 (200k)
df_200k = spark.read.csv("/workspaces/Customer_Support_Ticket-AnalyticsDE2/data/customer_support_tickets_200k.csv", header=True, inferSchema=True)
df_200k.write.format("jdbc") \
    .option("url", f"jdbc:duckdb:{DUCKDB_PATH}") \
    .option("dbtable", "main.tickets_200k_raw") \
    .mode("overwrite").save()

# Dataset 2 (Original)
df_orig = spark.read.csv("/workspaces/Customer_Support_Ticket-AnalyticsDE2/data/customer_support_tickets.csv", header=True, inferSchema=True)
df_orig.write.format("jdbc") \
    .option("url", f"jdbc:duckdb:{DUCKDB_PATH}") \
    .option("dbtable", "main.tickets_original_raw") \
    .mode("overwrite").save()

spark.stop()
