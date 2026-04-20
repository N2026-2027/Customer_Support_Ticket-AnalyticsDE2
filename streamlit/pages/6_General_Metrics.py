import streamlit as st
import plotly.express as px
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from utils.db import get_data
from utils.sidebar import render_sidebar

st.set_page_config(page_title="General Metrics", page_icon="📈", layout="wide")
render_sidebar()

st.title("📈 General Metrics")
st.caption("Fuente: `support_200k.fct_global_tickets` — Resumen global del pipeline")
st.markdown("---")

# ── Carga de datos ────────────────────────────────────────────────────────────
df = get_data("SELECT * FROM support_200k.fct_global_tickets")

if df is None or df.empty:
    st.error("No hay datos en fct_global_tickets. Verificá que el pipeline haya corrido.")
    st.stop()

# ── SIDEBAR: Filtros ──────────────────────────────────────────────────────────
st.sidebar.header("🛠️ Configuración de Datos")

fuente = st.sidebar.multiselect(
    "Fuente de Datos",
    options=df['dataset_source'].unique(),
    default=df['dataset_source'].unique()
)
prioridades = st.sidebar.multiselect(
    "Prioridad de Ticket",
    options=df['priority'].dropna().unique(),
    default=df['priority'].dropna().unique()
)

df_sel = df[
    df['dataset_source'].isin(fuente) &
    df['priority'].isin(prioridades)
]

# ── KPIs globales ─────────────────────────────────────────────────────────────
k1, k2, k3, k4, k5 = st.columns(5)
k1.metric("Total Tickets",           f"{len(df_sel):,}")
k2.metric("Satisfacción Promedio",   f"{df_sel['customer_satisfaction_score'].mean():.2f}")
k3.metric("Resolución Promedio (h)", f"{df_sel['resolution_time_hours'].mean():.1f}")
sla_ok = (df_sel['sla_status'] == 'SLA_Cumplido').sum()
k4.metric("SLA Cumplidos",           f"{sla_ok:,}")
k5.metric("Escalaciones",            f"{df_sel['escalated'].sum():,}")

st.markdown("---")

# ── Distribución por categoría ─────────────────────────────────────────────────
st.subheader("📊 Comparativa: Volumen por Fuente de Datos")
fig_comp = px.histogram(
    df_sel,
    x="category",
    color="dataset_source",
    barmode="group",
    template="plotly_dark",
    title="Distribución de Tickets por Categoría y Fuente",
    labels={"category": "Categoría", "dataset_source": "Dataset"}
)
st.plotly_chart(fig_comp, use_container_width=True)

# ── Tendencia mensual ──────────────────────────────────────────────────────────
st.subheader("📅 Evolución Mensual de Tickets")
if 'year' in df_sel.columns and 'month' in df_sel.columns:
    df_time = df_sel.groupby(['year', 'month', 'dataset_source']).size().reset_index(name='total')
    df_time['period'] = (
        df_time['year'].astype(str) + "-" +
        df_time['month'].astype(str).str.zfill(2)
    )
    fig_time = px.line(
        df_time, x='period', y='total', color='dataset_source',
        template='plotly_dark',
        labels={'period': 'Mes', 'total': 'Tickets', 'dataset_source': 'Dataset'}
    )
    st.plotly_chart(fig_time, use_container_width=True)

# ── SLA por dataset ────────────────────────────────────────────────────────────
st.markdown("---")
st.subheader("🎯 Cumplimiento de SLA por Dataset")

col_left, col_right = st.columns(2)
sla_data = df_sel.groupby(['dataset_source', 'sla_status']).size().reset_index(name='total_tickets')

with col_left:
    source_opts = df_sel['dataset_source'].unique().tolist()
    source_pie  = st.selectbox("Seleccionar Fuente para Detalle", options=source_opts)
    df_pie = sla_data[sla_data['dataset_source'] == source_pie]

    fig_pie = px.pie(
        df_pie,
        values='total_tickets',
        names='sla_status',
        hole=0.4,
        color='sla_status',
        color_discrete_map={'SLA_Cumplido': '#2ecc71', 'SLA_Incumplido': '#e74c3c'},
        template="plotly_dark"
    )
    st.plotly_chart(fig_pie, use_container_width=True)

with col_right:
    sla_ok_n  = int(df_pie[df_pie['sla_status'] == 'SLA_Cumplido']['total_tickets'].sum())
    sla_bad_n = int(df_pie[df_pie['sla_status'] == 'SLA_Incumplido']['total_tickets'].sum())
    total_n   = sla_ok_n + sla_bad_n
    st.info(f"""
    **Análisis de Eficiencia — {source_pie}**

    ✅ SLA Cumplido:   **{sla_ok_n:,}** ({sla_ok_n/max(total_n,1)*100:.1f}%)
    ❌ SLA Incumplido: **{sla_bad_n:,}** ({sla_bad_n/max(total_n,1)*100:.1f}%)

    El SLA se define como resolución en menos de 24 horas.
    """)

# ── Resolución por prioridad ───────────────────────────────────────────────────
st.subheader("⏱️ Tiempo de Resolución por Prioridad")
df_prio = (
    df_sel.groupby(['priority', 'dataset_source'])['resolution_time_hours']
    .mean().reset_index()
)
fig_prio = px.bar(
    df_prio,
    x='priority', y='resolution_time_hours',
    color='dataset_source', barmode='group',
    template='plotly_dark',
    labels={'resolution_time_hours': 'Horas Promedio', 'priority': 'Prioridad'}
)
st.plotly_chart(fig_prio, use_container_width=True)