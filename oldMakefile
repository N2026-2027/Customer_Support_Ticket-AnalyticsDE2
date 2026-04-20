# =============================================================================
# VARIABLES GLOBALES
# =============================================================================
COMPOSE_FILE=docker-compose.yml
DB_PATH=./duckdb/support.duckdb
SPARK_BIN=/workspaces/Customer_Support_Ticket-AnalyticsDE2/batch/spark-3.3.2-bin-hadoop3/bin/spark-submit
SPARK_SCRIPT=/workspaces/Customer_Support_Ticket-AnalyticsDE2/scripts/spark_batch_process.py

.PHONY: up down restart status logs-streamlit logs-kestra shell-dbt shell-postgres

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
	@echo "  ✅ Superset:  http://localhost:8088"
	@echo "  ✅ Jupyter:   http://localhost:8888"
	@echo "  ✅ Streamlit: http://localhost:8501"
	@echo ""
	@echo "── Tablas en DuckDB ──────────────────────────────────────"
	@docker compose -f $(COMPOSE_FILE) exec -T dbt python3 -c "\
import duckdb; \
con = duckdb.connect('/shared/duckdb/support.duckdb'); \
df = con.execute(\"SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') ORDER BY 1,2\").df(); \
print(df.to_string(index=False)) if len(df) else print('  (sin tablas aún — corré: make pipeline)'); \
con.close()" 2>/dev/null || echo "  ⚠️  Base de datos no inicializada"

logs-streamlit:
	docker compose logs -f streamlit

logs-kestra:
	docker compose logs -f kestra

# ── ACCESO DIRECTO ───────────────────────────────────────────────────────────
shell-dbt:
	docker compose exec dbt bash

shell-postgres:
	docker compose exec postgres psql -U admin -d support_db
.PHONY: ingest dbt-run dbt-test dbt-debug pipeline clean-duckdb clean-all

# ── PIPELINE DE DATOS ────────────────────────────────────────────────────────
ingest:
	@echo "📥 Ejecutando Spark Batch Ingestion (Local -> Postgres/DuckDB)..."
	$(SPARK_BIN) --packages org.postgresql:postgresql:42.5.0,org.duckdb:duckdb_jdbc:0.10.3 $(SPARK_SCRIPT)

dbt-debug:
	@echo "🔍 Verificando conexión de dbt..."
	docker compose exec dbt dbt debug --profiles-dir ..

dbt-run:
	@echo "🏗️  Generando modelos en DuckDB (Staging & Marts)..."
	docker compose exec dbt dbt run --profiles-dir ..

dbt-test:
	@echo "🧪 Ejecutando tests de integridad y calidad..."
	docker compose exec dbt dbt test --profiles-dir ..

# El comando principal para el Codespace
pipeline: ingest dbt-run dbt-test
	@echo "🏁 Pipeline completo. Datos listos en Streamlit y Superset."

# =============================================================================
# PIPELINE Y OPS
# =============================================================================
up:
	docker compose up -d

ingest:
	@echo "📥 Iniciando ingesta Spark..."
	$(SPARK_BIN) --packages org.postgresql:postgresql:42.5.0,org.duckdb:duckdb_jdbc:0.10.3 $(SPARK_SCRIPT)

pipeline:
	@start_time=$$(date +%s); \
	echo "🚀 Iniciando Pipeline Completo..."; \
	$(MAKE) ingest && \
	docker compose exec dbt dbt run --profiles-dir .. && \
	docker compose exec dbt dbt test --profiles-dir ..; \
	end_time=$$(date +%s); \
	elapsed=$$((end_time - start_time)); \
	echo "🏁 Pipeline finalizado en $$elapsed segundos."

# =============================================================================
# RESET (Tus comandos originales)
# =============================================================================
reset-db:
	@echo "⚠️  Borrando $(DB)..."
	rm -f $(DB)
	@echo "Listo. Corré: make pipeline"

reset-all:
	@echo "⚠️  Borrando DuckDB + storage Kestra..."
	rm -f $(DB)
	rm -rf ./storage/*
	@echo "Listo. Corré: make up && make pipeline"


# ── LIMPIEZA Y MANTENIMIENTO ─────────────────────────────────────────────────
clean-duckdb:
	@echo "⚠️  Borrando archivo DuckDB..."
	rm -f $(DB_PATH)
	@echo "✅ DuckDB reseteado."

clean-all: down
	@echo "⚠️  Limpieza profunda: DuckDB, logs de Kestra y volúmenes de Docker..."
	rm -f $(DB_PATH)
	rm -rf ./storage/*
	docker volume prune -f
	@echo "✅ Sistema limpio."

