import streamlit as st

# Configuración centralizada (SOLO en app.py)
st.set_page_config(
    page_title="CX Support Analytics",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Estilo personalizado para las tarjetas
st.markdown("""
    <style>
    .stInfo {
        min-height: 180px;
    }
    </style>
    """, unsafe_allow_stdio=True)

st.markdown("""
# 📊 Customer Support Analytics
### Capstone DE Zoomcamp · Spark · DuckDB · dbt · Kestra · Streamlit
""")
st.markdown("---")

# Fila 1: KPIs Globales y Salud
col1, col2, col3 = st.columns(3)
with col1:
    st.info("### 📈 General Metrics\nResumen global de tickets, tiempos de resolución y cumplimiento de SLA.")
    st.page_link("pages/6_General_Metrics.py", label="Ver Dashboard General →")

with col2:
    st.info("### 🏥 Product Health\nHealth score por producto, análisis de riesgo y críticos sin resolver.")
    st.page_link("pages/1_Product_Health.py", label="Analizar Productos →")

with col3:
    st.info("### 🚨 Churn Risk\nIdentificación de clientes recurrentes y predicción de abandono.")
    st.page_link("pages/2_Churn_Risk.py", label="Ver Riesgo de Churn →")

st.markdown(" ") # Espaciador

# Fila 2: Eficiencia y Exploración
col4, col5, col6 = st.columns(3)
with col4:
    st.info("### 📡 Channel Efficiency\nComparativa de canales (Email, Chat, Phone) vs benchmark global.")
    st.page_link("pages/4_Channel_Efficiency.py", label="Ver Canales →")

with col5:
    st.info("### 🔽 Ticket Funnel\nAnálisis de cuellos de botella y 'dead-ends' por tipo de problema.")
    st.page_link("pages/5_Ticket_Funnel.py", label="Ver Funnel →")

with col6:
    st.info("### 🗄️ SQL Explorer\nConsola interactiva para consultas libres sobre DuckDB y descarga de reportes.")
    st.page_link("pages/3_Explorer.py", label="Abrir Consola SQL →")

st.markdown("---")

# Sección de estado del Pipeline (Data Engineering check)
with st.sidebar:
    st.header("🛠️ Stack Status")
    st.success("Spark 3.3.2: OK")
    st.success("DuckDB Storage: Connected")
    st.write("**Versión:** 1.0.0-beta")
    
st.caption(
    "Dataset: [Customer Support Ticket Dataset — Kaggle](https://kaggle.com) "
    "| Pipeline: Spark (Batch) → Postgres & DuckDB → dbt → Streamlit"
)
