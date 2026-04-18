import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sha2, lower, current_timestamp

# 1. Configuración de Entorno (Ajustado a tu imagen)
os.environ['JAVA_HOME'] = '/workspaces/Customer_Support_Ticket-AnalyticsDE2/batch/jdk-11.0.2'
os.environ['SPARK_HOME'] = '/workspaces/Customer_Support_Ticket-AnalyticsDE2/batch/spark-3.3.2-bin-hadoop3'

# 2. Inicializar Spark con conectores
spark = SparkSession.builder \
    .appName("CustomerSupport_Final_Pipeline") \
    .master("local[*]") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.5.0,org.duckdb:duckdb_jdbc:0.10.3") \
    .getOrCreate()

# 3. Rutas de Archivos
CSV_INPUT = "/workspaces/Customer_Support_Ticket-AnalyticsDE2/data/customer_support_tickets_200k.csv"
DUCKDB_PATH = "/workspaces/Customer_Support_Ticket-AnalyticsDE2/duckdb/support.duckdb"

print(f"🚀 Leyendo dataset desde: {CSV_INPUT}")

# 4. Lectura Batch (Reemplaza al pd.read_csv por chunks)
df_raw = spark.read.csv(CSV_INPUT, header=True, inferSchema=True)

# 5. Transformaciones de Ingeniería
df_transformed = df_raw.select(
    col("ticket_id"),
    sha2(col("customer_email").cast("string"), 256).alias("email_pii"), # Anonimización
    lower(col("category")).alias("category"),
    col("priority"),
    col("status"),
    col("resolution_time_hours").cast("double"),
    current_timestamp().alias("processed_at")
)

# 6. Carga a PostgreSQL (Capa Operativa en Docker)
# Nota: Usamos localhost porque el puerto 5432 está mapeado en tu compose
print("🐘 Cargando a PostgreSQL...")
df_transformed.write.format("jdbc") \
    .option("url", "jdbc:postgresql://localhost:5432/support_db") \
    .option("dbtable", "raw_tickets") \
    .option("user", "admin") \
    .option("password", "admin_password") \
    .mode("overwrite").save()

# 7. Carga a DuckDB (Capa Analítica para dbt/Streamlit)
print("🦆 Cargando a DuckDB...")
df_transformed.write.format("jdbc") \
    .option("url", f"jdbc:duckdb:{DUCKDB_PATH}") \
    .option("dbtable", "stg_tickets") \
    .mode("overwrite").save()

print("🏁 Proceso completado exitosamente.")
spark.stop()
