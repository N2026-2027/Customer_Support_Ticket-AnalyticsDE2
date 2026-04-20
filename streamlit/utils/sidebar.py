# streamlit/utils/sidebar.py
import streamlit as st
from utils.db import get_data, DB_PATH

def render_sidebar():
    """Sidebar con estado del stack — reutilizable en todas las páginas."""
    with st.sidebar:
        st.header("🛠️ Stack Status")

        # Estado DuckDB 200k
        try:
            df = get_data("SELECT COUNT(*) AS n FROM support_200k.fct_global_tickets")
            n = int(df['n'].iloc[0]) if not df.empty else 0
            st.success(f"DuckDB 200k: ✅ {n:,} tickets")
        except Exception as e:
            st.error(f"DuckDB 200k: ❌ {e}")

        st.info("Spark 3.3.2: Batch")
        st.divider()
        st.write("**Versión:** 1.0.0")
        st.caption(
            "[Dataset Kaggle](https://www.kaggle.com/datasets/mirzayasirabdullah07/"
            "customer-support-tickets-dataset-200k-records)"
        )