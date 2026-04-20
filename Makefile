# =============================================================================
# VARIABLES GLOBALES
# =============================================================================
COMPOSE_FILE=docker-compose.yml
# ── DOS bases DuckDB (una por dataset) ───────────────────────────────────────
DB_200K    =./duckdb/support_200k.duckdb
DB_ORIG    =./duckdb/support_original.duckdb
SPARK_BIN  =/workspaces/Customer_Support_Ticket-AnalyticsDE2/batch/spark-3.3.2-bin-hadoop3/bin/spark-submit
SPARK_SCRIPT=/workspaces/Customer_Support_Ticket-AnalyticsDE2/scripts/spark_batch_process.py
# RUTA A TU JDK LOCAL
JAVA_HOME_LOCAL=/workspaces/Customer_Support_Ticket-AnalyticsDE2/batch/jdk-11.0.2
# Variables de soporte
JAR_POSTGRES=/home/codespace/.ivy2/jars/org.postgresql_postgresql-42.5.0.jar
JAR_DUCKDB  =/home/codespace/.ivy2/jars/org.duckdb_duckdb_jdbc-0.10.3.jar


.PHONY: up down restart status \
        logs-streamlit logs-kestra \
        shell-dbt shell-postgres \
        download ingest \
        dbt-debug dbt-deps dbt-run dbt-test pipeline \
        reset-db reset-all clean-duckdb clean-all

# ── GESTIÓN DE SERVICIOS ─────────────────────────────────────────────────────
up:
	@echo "🚀 Levantando servicios en segundo plano..."
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "✅ Servicios arriba. Usá 'make status' para verificar."

down:
	@echo "🛑 Bajando servicios y limpiando redes..."
	docker compose -f $(COMPOSE_FILE) down

restart: down up

# ── MONITOREO Y LOGS ─────────────────────────────────────────────────────────
status:
	@echo "── Contenedores ──────────────────────────────────────────"
	@docker compose -f $(COMPOSE_FILE) ps
	@echo ""
	@echo "── URLs activas ──────────────────────────────────────────"
	@echo "  ✅ Kestra:    http://localhost:18080"
	@echo "  ✅ pgAdmin:   http://localhost:5050"
	@echo "  ✅ Jupyter:   http://localhost:8888"
	@echo "  ✅ Streamlit: http://localhost:8501"
	@echo ""
	@echo "── Tablas en DuckDB (200k) ───────────────────────────────"
	@docker compose -f $(COMPOSE_FILE) exec -T dbt python3 -c "\
import duckdb; \
con = duckdb.connect('/shared/duckdb/support_200k.duckdb'); \
df = con.execute(\"SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') ORDER BY 1,2\").df(); \
print(df.to_string(index=False)) if len(df) else print('  (vacía — corré: make pipeline)'); \
con.close()" 2>/dev/null || echo "  ⚠️  support_200k.duckdb no inicializada"
	@echo ""
	@echo "── Tablas en DuckDB (original) ───────────────────────────"
	@docker compose -f $(COMPOSE_FILE) exec -T dbt python3 -c "\
import duckdb; \
con = duckdb.connect('/shared/duckdb/support_original.duckdb'); \
df = con.execute(\"SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') ORDER BY 1,2\").df(); \
print(df.to_string(index=False)) if len(df) else print('  (vacía — corré: make pipeline)'); \
con.close()" 2>/dev/null || echo "  ⚠️  support_original.duckdb no inicializada"

logs-streamlit:
	docker compose logs -f streamlit

logs-kestra:
	docker compose logs -f kestra

# ── ACCESO DIRECTO ───────────────────────────────────────────────────────────
shell-dbt:
	docker compose exec dbt bash

shell-postgres:
	docker compose exec postgres psql -U admin -d support_db

# ── PIPELINE DE DATOS ────────────────────────────────────────────────────────
download:
	@echo "⬇️  Descargando dataset desde Kaggle..."
	python3 scripts/download_dataset.py

ingest:
	@echo "📥 Ejecutando Spark Batch Ingestion..."
	@echo "   → support_200k.duckdb  (200k filas)"
	@echo "   → support_original.duckdb  (18k filas)"
	JAVA_HOME=$(JAVA_HOME_LOCAL) $(SPARK_BIN) \
		--jars $(JAR_POSTGRES),$(JAR_DUCKDB) \
		--driver-class-path $(JAR_POSTGRES):$(JAR_DUCKDB) \
		--packages org.postgresql:postgresql:42.5.0,org.duckdb:duckdb_jdbc:0.10.3 \
		$(SPARK_SCRIPT)

dbt-debug:
	@echo "🔍 Verificando conexión de dbt..."
	docker compose exec dbt dbt debug --profiles-dir ..

dbt-deps:
	@echo "📦 Instalando paquetes dbt (dbt_utils)..."
	docker compose exec dbt dbt deps --profiles-dir ..

dbt-run:
	@echo "🏗️  Generando modelos en DuckDB (Staging & Marts)..."
	docker compose exec dbt dbt run --profiles-dir ..

dbt-test:
	@echo "🧪 Ejecutando tests de integridad y calidad..."
	docker compose exec dbt dbt test --profiles-dir ..

# El comando principal para el Codespace
pipeline:
	@start_time=$$(date +%s); \
	echo "🚀 Iniciando Pipeline Completo..."; \
	$(MAKE) ingest && \
	docker compose exec dbt dbt deps --profiles-dir .. && \
	docker compose exec dbt dbt run  --profiles-dir .. && \
	docker compose exec dbt dbt test --profiles-dir ..; \
	end_time=$$(date +%s); \
	elapsed=$$((end_time - start_time)); \
	echo "🏁 Pipeline finalizado en $$elapsed segundos."

# =============================================================================
# RESET (Tus comandos originales)
# =============================================================================
reset-db:
	@echo "⚠️  Borrando ambas bases DuckDB..."
	rm -f $(DB_200K) $(DB_ORIG)
	@echo "Listo. Corré: make pipeline"

reset-all:
	@echo "⚠️  Borrando DuckDB + storage Kestra..."
	rm -f $(DB_200K) $(DB_ORIG)
	rm -rf ./storage/*
	@echo "Listo. Corré: make up && make pipeline"

# ── LIMPIEZA Y MANTENIMIENTO ─────────────────────────────────────────────────
clean-duckdb:
	@echo "⚠️  Borrando bases DuckDB..."
	rm -f $(DB_200K) $(DB_ORIG)
	@echo "✅ DuckDB reseteado."

clean-all: down
	@echo "⚠️  Limpieza profunda: DuckDB, logs de Kestra y volúmenes de Docker..."
	rm -f $(DB_200K) $(DB_ORIG)
	rm -rf ./storage/*
	docker volume prune -f
	@echo "✅ Sistema limpio."
