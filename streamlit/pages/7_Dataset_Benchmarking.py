import streamlit as st
import plotly.express as px
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from utils.db import get_data
from utils.sidebar import render_sidebar

st.set_page_config(page_title="Dataset Benchmarking", layout="wide")
render_sidebar()

st.title("⚖️ Dataset Benchmarking")
st.markdown("Comparación técnica entre el Dataset 200k (Sintético) y el Dataset Original.")

@st.cache_data(ttl=300)
def load_data():
    return get_data("SELECT * FROM main_marts.fct_global_tickets")

df = load_data()

if df is None or df.empty:
    st.error("No hay datos en fct_global_tickets. Verificá que el pipeline haya corrido.")
    st.stop()

# ── Resumen por dataset ───────────────────────────────────────────────────────
st.subheader("📊 Resumen por Dataset")
summary = df.groupby('dataset_source').agg(
    total_tickets    = ('ticket_sk',                   'count'),
    avg_satisfaction = ('customer_satisfaction_score', 'mean'),
    avg_resolution_h = ('resolution_time_hours',       'mean'),
    sla_breach_pct   = ('sla_breached',                'mean'),
    escalation_pct   = ('escalated',                   'mean'),
).reset_index()
summary['sla_breach_pct'] = (summary['sla_breach_pct'] * 100).round(2)
summary['escalation_pct'] = (summary['escalation_pct'] * 100).round(2)
st.dataframe(summary, use_container_width=True)

st.markdown("---")

# ── Scatter complejidad vs satisfacción (solo 200k, tiene issue_complexity_score) ──
st.subheader("Complejidad vs Satisfacción (Dataset 200k)")
df_200k = df[df['dataset_source'] == '200k'].copy()
if not df_200k.empty and 'issue_complexity_score' in df_200k.columns:
    sample = df_200k.dropna(subset=['issue_complexity_score', 'customer_satisfaction_score'])
    if len(sample) > 3000:
        sample = sample.sample(3000, random_state=42)
    fig_scatter = px.scatter(
        sample,
        x="issue_complexity_score",
        y="customer_satisfaction_score",
        color="priority",
        trendline="ols",
        opacity=0.4,
        template='plotly_dark',
        labels={
            'issue_complexity_score': 'Complejidad (1-5)',
            'customer_satisfaction_score': 'Satisfacción (1-5)'
        }
    )
    st.plotly_chart(fig_scatter, use_container_width=True)
else:
    st.info("issue_complexity_score no disponible para el dataset seleccionado.")

# ── Distribución de categorías ────────────────────────────────────────────────
st.subheader("Distribución de Categorías: ¿Qué tan diferentes son?")
df_counts = df.groupby(['category', 'dataset_source']).size().reset_index(name='counts')
fig_hist = px.bar(
    df_counts, x="category", y="counts",
    color="dataset_source", barmode="group",
    template='plotly_dark',
    labels={'counts': 'Cantidad de Tickets', 'category': 'Categoría'}
)
st.plotly_chart(fig_hist, use_container_width=True)

# ── Distribución de satisfacción ──────────────────────────────────────────────
st.subheader("Distribución de Satisfacción del Cliente")
df_sat = df.dropna(subset=['customer_satisfaction_score'])
fig_dist = px.histogram(
    df_sat,
    x='customer_satisfaction_score',
    color='dataset_source',
    barmode='overlay',
    opacity=0.6,
    nbins=10,
    template='plotly_dark',
    labels={'customer_satisfaction_score': 'Score de Satisfacción'}
)
st.plotly_chart(fig_dist, use_container_width=True)

# ── SLA breach % por prioridad ────────────────────────────────────────────────
st.subheader("SLA Breach % por Prioridad — Comparativa entre Datasets")
sla_comp = df.groupby(['dataset_source', 'priority'])['sla_breached'].mean().reset_index()
sla_comp['sla_breach_pct'] = (sla_comp['sla_breached'] * 100).round(2)
fig_sla = px.bar(
    sla_comp,
    x='priority', y='sla_breach_pct',
    color='dataset_source', barmode='group',
    template='plotly_dark',
    labels={'sla_breach_pct': '% SLA Breach', 'priority': 'Prioridad'}
)
st.plotly_chart(fig_sla, use_container_width=True)