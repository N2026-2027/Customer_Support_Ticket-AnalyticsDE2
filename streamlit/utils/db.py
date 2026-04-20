# streamlit/utils/db.py
import duckdb
import pandas as pd
import streamlit as st

# ── Bases DuckDB ──────────────────────────────────────────────────────────────
# La base principal es support_200k.duckdb (target dev del profile dbt).
# Los modelos combinados (fct_global_tickets, marts) se materializan aquí.
DB_PATH          = "/shared/duckdb/support_200k.duckdb"
DB_PATH_ORIGINAL = "/shared/duckdb/support_original.duckdb"

# ── Conexión singleton ────────────────────────────────────────────────────────
@st.cache_resource
def _get_connection(path: str = DB_PATH):
    """Conexión read-only compartida entre páginas (una por base)."""
    return duckdb.connect(path, read_only=True)

# ── Función principal — usada por todas las páginas ───────────────────────────
def get_data(sql: str, db: str = DB_PATH) -> pd.DataFrame:
    """
    Ejecuta SQL sobre DuckDB y retorna un DataFrame.
    Alias principal usado por todas las páginas (get_data).
    Retorna DataFrame vacío en caso de error para no crashear la UI.
    """
    try:
        con = _get_connection(db)
        return con.execute(sql).df()
    except Exception as e:
        st.error(f"Error en consulta SQL: {e}")
        return pd.DataFrame()

# Alias por compatibilidad con código que usa query()
def query(sql: str, db: str = DB_PATH) -> pd.DataFrame:
    return get_data(sql, db)

# ── Status para el SQL Explorer ───────────────────────────────────────────────
def db_status(db: str = DB_PATH) -> dict:
    """
    Retorna dict con ok:bool, tables:list, error:str.
    Usado por 3_Explorer.py para mostrar el estado de la conexión.
    """
    try:
        con = _get_connection(db)
        tables = con.execute("""
            SELECT table_schema || '.' || table_name AS full_name
            FROM information_schema.tables
            WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
            ORDER BY 1
        """).fetchall()
        return {"ok": True, "tables": [t[0] for t in tables]}
    except Exception as e:
        return {"ok": False, "tables": [], "error": str(e)}