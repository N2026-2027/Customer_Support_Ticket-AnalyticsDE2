#!/usr/bin/env python3
# =============================================================================
# scripts/spark_batch_process.py
# =============================================================================
import os
import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sha2, current_timestamp, lit

# ── Rutas ─────────────────────────────────────────────────────────────────────
JAVA_HOME  = os.environ.get('JAVA_HOME',
    '/workspaces/Customer_Support_Ticket-AnalyticsDE2/batch/jdk-11.0.2')
SPARK_HOME = os.environ.get('SPARK_HOME',
    '/workspaces/Customer_Support_Ticket-AnalyticsDE2/batch/spark-3.3.2-bin-hadoop3')
os.environ['JAVA_HOME']  = JAVA_HOME
os.environ['SPARK_HOME'] = SPARK_HOME

DATA_DIR        = os.environ.get('DATA_DIR',
    '/workspaces/Customer_Support_Ticket-AnalyticsDE2/data')
DUCKDB_DIR      = os.environ.get('DUCKDB_DIR',
    '/workspaces/Customer_Support_Ticket-AnalyticsDE2/duckdb')

DUCKDB_200K     = f"{DUCKDB_DIR}/support_200k.duckdb"
DUCKDB_ORIGINAL = f"{DUCKDB_DIR}/support_original.duckdb"

PG_URL  = os.environ.get('PG_URL',      'jdbc:postgresql://localhost:5432/support_db')
PG_USER = os.environ.get('PG_USER',     'admin')
PG_PASS = os.environ.get('PG_PASSWORD', 'admin_password')

CSV_200K = f"{DATA_DIR}/customer_support_tickets_200k.csv"
CSV_ORIG = f"{DATA_DIR}/customer_support_tickets.csv"

# ── Spark ─────────────────────────────────────────────────────────────────────
spark = SparkSession.builder \
    .appName("CustomerSupport_Final_Pipeline") \
    .master("local[*]") \
    .config("spark.jars.packages",
            "org.postgresql:postgresql:42.5.0,org.duckdb:duckdb_jdbc:0.10.3") \
    .config("spark.sql.shuffle.partitions", "8") \
    .getOrCreate()

spark.sparkContext.setLogLevel("WARN")

# ── Helpers ───────────────────────────────────────────────────────────────────
def write_postgres(df, table: str):
    print(f"  🐘 → PostgreSQL: {table}")
    df.write.format("jdbc") \
        .option("url",      PG_URL) \
        .option("dbtable",  table) \
        .option("user",     PG_USER) \
        .option("password", PG_PASS) \
        .option("driver",   "org.postgresql.Driver") \
        .mode("overwrite").save()

def write_duckdb(df, duckdb_path: str, table: str):
    db_name = os.path.basename(duckdb_path)
    print(f"  🦆 → DuckDB ({db_name}): main.{table}")
    df.write.format("jdbc") \
        .option("url",     f"jdbc:duckdb:{duckdb_path}") \
        .option("dbtable", f"main.{table}") \
        .mode("overwrite").save()

# ─────────────────────────────────────────────────────────────────────────────
# 1. Dataset 200k  →  support_200k.duckdb
# ─────────────────────────────────────────────────────────────────────────────
print(f"\n{'='*60}")
print(f"📥 Dataset 200k: {CSV_200K}")
print(f"   destino DuckDB: support_200k.duckdb")
print(f"{'='*60}")

if not os.path.exists(CSV_200K):
    print(f"❌ No encontrado: {CSV_200K}")
    sys.exit(1)

# ARREGLO: Agregadas opciones multiLine y escape para evitar desorden de columnas
df_200k = spark.read.csv(CSV_200K, header=True, inferSchema=True, multiLine=True, escape='"')
print(f"   ✅ {df_200k.count():,} filas | {len(df_200k.columns)} columnas")

df_200k_clean = df_200k \
    .withColumn("customer_email",
                sha2(col("customer_email").cast("string"), 256)) \
    .withColumn("customer_name",
                sha2(col("customer_name").cast("string"), 256)) \
    .withColumn("processed_at",   current_timestamp()) \
    .withColumn("dataset_source", lit("200k"))

write_postgres(df_200k_clean, "public.customer_support_tickets_200k")
write_duckdb(  df_200k_clean, DUCKDB_200K, "customer_support_tickets_200k")

# ─────────────────────────────────────────────────────────────────────────────
# 2. Dataset original  →  support_original.duckdb
# ─────────────────────────────────────────────────────────────────────────────
if os.path.exists(CSV_ORIG):
    print(f"\n{'='*60}")
    print(f"📥 Dataset original: {CSV_ORIG}")
    print(f"   destino DuckDB: support_original.duckdb")
    print(f"{'='*60}")

    # ARREGLO: Agregadas opciones multiLine y escape para evitar desorden de columnas
    df_orig = spark.read.csv(CSV_ORIG, header=True, inferSchema=True, multiLine=True, escape='"')
    print(f"   ✅ {df_orig.count():,} filas | {len(df_orig.columns)} columnas")

    df_orig_clean = df_orig \
        .withColumn("Customer Email",
                    sha2(col("Customer Email").cast("string"), 256)) \
        .withColumn("Customer Name",
                    sha2(col("Customer Name").cast("string"), 256)) \
        .withColumn("processed_at",   current_timestamp()) \
        .withColumn("dataset_source", lit("original"))

    write_postgres(df_orig_clean, "public.customer_support_tickets")
    write_duckdb(  df_orig_clean, DUCKDB_ORIGINAL, "customer_support_tickets")
else:
    print(f"\n⚠️  Dataset original no encontrado: {CSV_ORIG} — saltando.")

print(f"\n{'='*60}")
print("🏁 Spark finalizado correctamente.")
print(f"   📦 support_200k.duckdb     → {DUCKDB_200K}")
print(f"   📦 support_original.duckdb → {DUCKDB_ORIGINAL}")
print(f"{'='*60}\n")
spark.stop()
