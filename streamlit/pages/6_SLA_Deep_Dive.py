import streamlit as st
import plotly.express as px
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from utils.db import get_data
from utils.sidebar import render_sidebar

st.set_page_config(page_title="SLA Deep Dive", layout="wide")
render_sidebar()

st.title("🎯 SLA & Response Performance")
st.markdown("Análisis detallado de tiempos de resolución y cumplimiento de promesas de servicio.")

# ── Datos ─────────────────────────────────────────────────────────────────────
@st.cache_data(ttl=300)
def load_data():
    return get_data("""
        SELECT
            dataset_source,
            priority,
            sla_status,
            category,
            channel,
            year,
            month,
            month_name,
            AVG(resolution_time_hours)      AS avg_time,
            AVG(first_response_time_hours)  AS avg_first_response,
            COUNT(*)                        AS total_tickets
        FROM main_marts.fct_global_tickets
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
    """)

df = load_data()

if df is None or df.empty:
    st.error("No hay datos en fct_global_tickets. Verificá que el pipeline haya corrido.")
    st.stop()

# ── Sidebar filtros ───────────────────────────────────────────────────────────
st.sidebar.header("Filtros")
source = st.sidebar.selectbox("Seleccionar Dataset", options=df['dataset_source'].unique())
cats   = st.sidebar.multiselect("Categoría", df['category'].unique(), default=df['category'].unique())

df_filtered = df[(df['dataset_source'] == source) & (df['category'].isin(cats))]

# ── KPIs ──────────────────────────────────────────────────────────────────────
k1, k2, k3 = st.columns(3)
total_t = df_filtered['total_tickets'].sum()
sla_ok  = df_filtered[df_filtered['sla_status'] == 'SLA_Cumplido']['total_tickets'].sum()
k1.metric("% SLA Cumplido",           f"{sla_ok/max(total_t,1)*100:.1f}%")
k2.metric("Tiempo Resol. Promedio",   f"{df_filtered['avg_time'].mean():.1f}h")
k3.metric("Primera Resp. Promedio",   f"{df_filtered['avg_first_response'].mean():.1f}h")

st.markdown("---")
col1, col2 = st.columns(2)

# ── Pie SLA ───────────────────────────────────────────────────────────────────
with col1:
    st.subheader(f"Distribución SLA — {source}")
    sla_agg = df_filtered.groupby('sla_status')['total_tickets'].sum().reset_index()
    fig_pie = px.pie(
        sla_agg, values='total_tickets', names='sla_status',
        color='sla_status', hole=0.4,
        color_discrete_map={'SLA_Cumplido': '#2ecc71', 'SLA_Incumplido': '#e74c3c'},
        template='plotly_dark'
    )
    st.plotly_chart(fig_pie, use_container_width=True)

# ── Bar tiempo por prioridad ──────────────────────────────────────────────────
with col2:
    st.subheader("Tiempo Promedio por Prioridad")
    prio_agg = df_filtered.groupby('priority')['avg_time'].mean().reset_index()
    fig_bar = px.bar(
        prio_agg, x='priority', y='avg_time', color='priority',
        labels={'avg_time': 'Horas Promedio'},
        template='plotly_dark'
    )
    st.plotly_chart(fig_bar, use_container_width=True)

# ── Evolución temporal ────────────────────────────────────────────────────────
st.subheader("Evolución Mensual del SLA")
time_agg = (
    df_filtered.groupby(['year', 'month', 'month_name', 'sla_status'])['total_tickets']
    .sum().reset_index()
)
time_agg['period'] = (
    time_agg['year'].astype(str) + "-" +
    time_agg['month'].astype(str).str.zfill(2)
)
fig_time = px.line(
    time_agg, x='period', y='total_tickets', color='sla_status',
    color_discrete_map={'SLA_Cumplido': '#2ecc71', 'SLA_Incumplido': '#e74c3c'},
    template='plotly_dark',
    labels={'period': 'Mes', 'total_tickets': 'Tickets', 'sla_status': 'Estado SLA'}
)
st.plotly_chart(fig_time, use_container_width=True)

# ── Detalle ───────────────────────────────────────────────────────────────────
st.subheader("Detalle por Categoría y Canal")
detail = (
    df_filtered.groupby(['category', 'channel', 'sla_status'])['total_tickets']
    .sum().reset_index()
    .sort_values('total_tickets', ascending=False)
)
st.dataframe(detail, use_container_width=True)