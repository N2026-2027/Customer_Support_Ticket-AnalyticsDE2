"""
streamlit_ops_dashboard.py
──────────────────────────
Dashboard operativo de Support 200k
Conecta directamente a support_200k.duckdb o al CSV como fallback.

Ejecutar:
    streamlit run streamlit_ops_dashboard.py

Dependencias:
    pip install streamlit duckdb pandas plotly
"""

import streamlit as st
import pandas as pd
import duckdb
import plotly.express as px
import plotly.graph_objects as go
from pathlib import Path

# ── CONFIG ──────────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="Support Ops Dashboard · 200k",
    page_icon="🎫",
    layout="wide",
)

DUCKDB_PATH = Path(
    "/workspaces/Customer_Support_Ticket-AnalyticsDE2/duckdb/support_200k.duckdb"
)
CSV_FALLBACK = Path(
    "/workspaces/Customer_Support_Ticket-AnalyticsDE2/data/customer_support_tickets_200k.csv"
)

# ── DATA LOAD ────────────────────────────────────────────────────────────────
@st.cache_data(show_spinner="Cargando datos…")
def load_data() -> pd.DataFrame:
    """Carga desde DuckDB si existe, sino desde CSV."""
    if DUCKDB_PATH.exists():
        con = duckdb.connect(str(DUCKDB_PATH), read_only=True)
        df = con.execute(
            "SELECT * FROM main.customer_support_tickets_200k"
        ).df()
        con.close()
    elif CSV_FALLBACK.exists():
        df = pd.read_csv(CSV_FALLBACK)
    else:
        st.error("No se encontró support_200k.duckdb ni el CSV de fallback.")
        st.stop()

    # Normalizar columnas clave
    df["sla_breached_bool"] = df["sla_breached"].str.lower().str.strip() == "yes"
    df["escalated_bool"]    = df["escalated"].str.lower().str.strip()    == "yes"
    df["ticket_created_date"] = pd.to_datetime(df["ticket_created_date"], errors="coerce")
    df["ticket_resolved_date"] = pd.to_datetime(df["ticket_resolved_date"], errors="coerce")
    df["year_month"] = df["ticket_created_date"].dt.to_period("M").astype(str)
    return df


df = load_data()

# ── SIDEBAR FILTROS ──────────────────────────────────────────────────────────
st.sidebar.header("Filtros")

regions    = ["Todos"] + sorted(df["region"].dropna().unique().tolist())
channels   = ["Todos"] + sorted(df["channel"].dropna().unique().tolist())
segments   = ["Todos"] + sorted(df["customer_segment"].dropna().unique().tolist())
priorities = ["Todos"] + sorted(df["priority"].dropna().unique().tolist())

sel_region   = st.sidebar.selectbox("Región",            regions)
sel_channel  = st.sidebar.selectbox("Canal",             channels)
sel_segment  = st.sidebar.selectbox("Segmento cliente",  segments)
sel_priority = st.sidebar.selectbox("Prioridad",         priorities)

date_min = df["ticket_created_date"].min().date()
date_max = df["ticket_created_date"].max().date()
sel_dates = st.sidebar.date_input(
    "Rango de fechas",
    value=(date_min, date_max),
    min_value=date_min,
    max_value=date_max,
)

# Aplicar filtros
mask = pd.Series(True, index=df.index)
if sel_region   != "Todos": mask &= df["region"]           == sel_region
if sel_channel  != "Todos": mask &= df["channel"]          == sel_channel
if sel_segment  != "Todos": mask &= df["customer_segment"] == sel_segment
if sel_priority != "Todos": mask &= df["priority"]         == sel_priority
if len(sel_dates) == 2:
    mask &= (df["ticket_created_date"].dt.date >= sel_dates[0]) & \
            (df["ticket_created_date"].dt.date <= sel_dates[1])

fdf = df[mask].copy()

# ── HEADER ───────────────────────────────────────────────────────────────────
st.title("🎫 Support Operations Dashboard · 200k")
st.caption(f"Datos: support_200k.duckdb | {len(fdf):,} tickets filtrados de {len(df):,} totales")

# ── KPIs ─────────────────────────────────────────────────────────────────────
k1, k2, k3, k4, k5 = st.columns(5)

total          = len(fdf)
sla_rate       = fdf["sla_breached_bool"].mean() * 100 if total else 0
escalation_rate= fdf["escalated_bool"].mean()    * 100 if total else 0
avg_csat       = fdf["customer_satisfaction_score"].mean() if total else 0
avg_resolution = fdf["resolution_time_hours"].mean() if total else 0

k1.metric("Total Tickets",       f"{total:,}")
k2.metric("SLA Breach Rate",     f"{sla_rate:.1f}%",
          delta=f"{'⚠️ Alto' if sla_rate > 50 else '✅ OK'}", delta_color="off")
k3.metric("Escalation Rate",     f"{escalation_rate:.1f}%",
          delta=f"{'⚠️ Alto' if escalation_rate > 50 else '✅ OK'}", delta_color="off")
k4.metric("CSAT Promedio",       f"{avg_csat:.2f} / 5",
          delta=f"{'🔴' if avg_csat < 3 else '🟢'}", delta_color="off")
k5.metric("Resolución Promedio", f"{avg_resolution:.1f} h")

st.divider()

# ── FILA 1: SLA por categoría  +  Tendencia mensual ─────────────────────────
col1, col2 = st.columns(2)

with col1:
    st.subheader("SLA Breach por Categoría de Ticket")
    sla_cat = (
        fdf.groupby("category")["sla_breached_bool"]
        .agg(total="count", breached="sum")
        .assign(breach_rate=lambda x: (x["breached"] / x["total"] * 100).round(2))
        .sort_values("breach_rate", ascending=True)
        .reset_index()
    )
    fig1 = px.bar(
        sla_cat, x="breach_rate", y="category", orientation="h",
        color="breach_rate",
        color_continuous_scale=["#2ecc71", "#f39c12", "#e74c3c"],
        labels={"breach_rate": "% SLA Breach", "category": "Categoría"},
        text=sla_cat["breach_rate"].apply(lambda v: f"{v:.1f}%"),
    )
    fig1.update_traces(textposition="outside")
    fig1.update_layout(
        coloraxis_showscale=False,
        margin=dict(l=0, r=10, t=10, b=0),
        height=380,
    )
    st.plotly_chart(fig1, use_container_width=True)

with col2:
    st.subheader("Tendencia Mensual: Tickets · SLA Breach · Escalaciones")
    monthly = (
        fdf.groupby("year_month")
        .agg(
            tickets=("ticket_id", "count"),
            sla_breached=("sla_breached_bool", "sum"),
            escalated=("escalated_bool", "sum"),
        )
        .reset_index()
        .sort_values("year_month")
    )
    fig2 = go.Figure()
    fig2.add_trace(go.Scatter(
        x=monthly["year_month"], y=monthly["tickets"],
        name="Tickets", mode="lines+markers", line=dict(color="#3498db", width=2),
    ))
    fig2.add_trace(go.Scatter(
        x=monthly["year_month"], y=monthly["sla_breached"],
        name="SLA Breach", mode="lines+markers", line=dict(color="#e74c3c", width=2),
    ))
    fig2.add_trace(go.Scatter(
        x=monthly["year_month"], y=monthly["escalated"],
        name="Escalados", mode="lines+markers", line=dict(color="#f39c12", width=2),
    ))
    fig2.update_layout(
        margin=dict(l=0, r=0, t=10, b=0),
        height=380,
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        xaxis_title=None, yaxis_title="Tickets",
    )
    st.plotly_chart(fig2, use_container_width=True)

# ── FILA 2: CSAT por canal  +  Mapa de calor prioridad × categoría ───────────
col3, col4 = st.columns(2)

with col3:
    st.subheader("CSAT Promedio por Canal y Segmento de Cliente")
    csat_ch = (
        fdf.groupby(["channel", "customer_segment"])["customer_satisfaction_score"]
        .mean()
        .round(2)
        .reset_index()
        .rename(columns={"customer_satisfaction_score": "avg_csat"})
    )
    fig3 = px.bar(
        csat_ch, x="channel", y="avg_csat", color="customer_segment",
        barmode="group",
        color_discrete_sequence=px.colors.qualitative.Set2,
        labels={"avg_csat": "CSAT Promedio", "channel": "Canal", "customer_segment": "Segmento"},
        range_y=[0, 5],
    )
    fig3.update_layout(
        margin=dict(l=0, r=0, t=10, b=0),
        height=350,
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
    )
    st.plotly_chart(fig3, use_container_width=True)

with col4:
    st.subheader("Mapa de Calor: Tasa SLA Breach — Prioridad × Categoría")
    heat = (
        fdf.groupby(["priority", "category"])["sla_breached_bool"]
        .mean()
        .mul(100).round(1)
        .reset_index()
        .pivot(index="priority", columns="category", values="sla_breached_bool")
    )
    # Ordenar prioridades lógicamente
    prio_order = [p for p in ["Urgent", "High", "Medium", "Low"] if p in heat.index]
    heat = heat.loc[prio_order]

    fig4 = px.imshow(
        heat,
        color_continuous_scale=["#2ecc71", "#f39c12", "#e74c3c"],
        labels=dict(x="Categoría", y="Prioridad", color="% SLA Breach"),
        text_auto=".1f",
        aspect="auto",
    )
    fig4.update_layout(
        margin=dict(l=0, r=0, t=10, b=0),
        height=350,
        xaxis=dict(tickangle=-30),
    )
    st.plotly_chart(fig4, use_container_width=True)

# ── FILA 3: Top 20 clientes con más SLA breach ──────────────────────────────
st.subheader("Top 20 Clientes por Riesgo Operativo (SLA Breach + Escalaciones)")

risk_df = (
    fdf.groupby(["customer_email", "customer_name", "customer_segment", "subscription_type", "region"])
    .agg(
        total_tickets     =("ticket_id",           "count"),
        sla_breached      =("sla_breached_bool",   "sum"),
        escalated         =("escalated_bool",       "sum"),
        avg_csat          =("customer_satisfaction_score", "mean"),
        avg_resolution_h  =("resolution_time_hours","mean"),
    )
    .assign(
        sla_rate_pct  =lambda x: (x["sla_breached"] / x["total_tickets"] * 100).round(1),
        esc_rate_pct  =lambda x: (x["escalated"]    / x["total_tickets"] * 100).round(1),
        avg_csat      =lambda x: x["avg_csat"].round(2),
        avg_resolution_h=lambda x: x["avg_resolution_h"].round(1),
        # Risk score: SLA 40% + Escalation 30% + CSAT invertido 30%
        risk_score    =lambda x: (
            (x["sla_breached"] / x["total_tickets"] * 40) +
            (x["escalated"]    / x["total_tickets"] * 30) +
            ((1 - (x["avg_csat"] - 1) / 4) * 30)
        ).round(1),
    )
    .sort_values("risk_score", ascending=False)
    .head(20)
    .reset_index()
)

# Color del risk_score
def color_risk(val):
    if val >= 75:   return "background-color:#e74c3c;color:white"
    elif val >= 55: return "background-color:#f39c12;color:white"
    elif val >= 35: return "background-color:#f1c40f"
    return "background-color:#2ecc71;color:white"

display_cols = {
    "customer_name":    "Cliente",
    "customer_segment": "Segmento",
    "subscription_type":"Plan",
    "region":           "Región",
    "total_tickets":    "Tickets",
    "sla_rate_pct":     "SLA Breach %",
    "esc_rate_pct":     "Escalación %",
    "avg_csat":         "CSAT",
    "avg_resolution_h": "Resolución (h)",
    "risk_score":       "Risk Score",
}

st.dataframe(
    risk_df[list(display_cols.keys())]
    .rename(columns=display_cols)
    .style.applymap(color_risk, subset=["Risk Score"]),
    use_container_width=True,
    height=420,
)

# ── FOOTER ────────────────────────────────────────────────────────────────────
st.caption("Fuente: support_200k.duckdb · main.customer_support_tickets_200k · 200,000 filas · 30 columnas")
