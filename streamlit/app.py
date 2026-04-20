import streamlit as st

# 1. Configuración obligatoria al inicio
st.set_page_config(
    page_title="DE Support Pipeline",
    page_icon="⚙️",
    layout="wide"
)

# 2. Estilos CSS Consolidados
st.markdown("""
    <style>
    .stInfo { min-height: 190px; }
    /* Mejora visual para las tarjetas */
    div[data-testid="stVerticalBlock"] > div:has(div.stInfo) {
        border-radius: 10px;
        padding: 5px;
    }
    </style>
    """, unsafe_allow_html=True)

# 3. Encabezado
st.title("📊 Customer Support Analytics")
st.markdown("### Capstone DE Zoomcamp · Spark · DuckDB · dbt · Kestra")
st.markdown("---")

# 4. Grid de Navegación (Uso de contenedores para orden)
def create_card(title, description, link_path, link_label):
    st.info(f"### {title}\n{description}")
    st.page_link(link_path, label=link_label)

# Fila 1
row1 = st.columns(3)
with row1[0]:
    create_card("📈 General Metrics", "Resumen global de tickets y cumplimiento de SLA.", "pages/6_General_Metrics.py", "Ver Dashboard →")
with row1[1]:
    create_card("🏥 Product Health", "Health score por producto y análisis de riesgo.", "pages/1_Product_Health.py", "Analizar Productos →")
with row1[2]:
    create_card("🚨 Churn Risk", "Identificación de clientes y predicción de abandono.", "pages/2_Churn_Risk.py", "Ver Riesgo →")

st.write("") # Espaciador

# Fila 2
row2 = st.columns(3)
with row2[0]:
    create_card("📡 Channel Efficiency", "Comparativa de canales vs benchmark global.", "pages/4_Channel_Efficiency.py", "Ver Canales →")
with row2[1]:
    create_card("🔽 Ticket Funnel", "Análisis de cuellos de botella por problema.", "pages/5_Ticket_Funnel.py", "Ver Funnel →")
with row2[2]:
    create_card("🗄️ SQL Explorer", "Consola interactiva sobre DuckDB.", "pages/3_Explorer.py", "Abrir Consola →")

# Fila 3: Otros
st.markdown("---")
row3 = st.columns(2)
with row3[0]:
    create_card("🎯 SLA Deep Dive", "Análisis detallado de tiempos de respuesta.", "pages/6_SLA_Deep_Dive.py", "Ir al Deep Dive →")
with row3[1]:
    create_card("⚖️ Benchmarking", "Comparativa de escalabilidad (200k vs Original).", "pages/7_Dataset_Benchmarking.py", "Ver Benchmarking →")

# 5. Sidebar & Footer
with st.sidebar:
    st.header("🛠️ Stack Status")
    st.success("Spark 3.3.2: OK")
    st.success("DuckDB: Connected")
    st.divider()
    st.write("**Versión:** 1.0.0-beta")

st.caption(
    "Dataset: [Customer Support Ticket Dataset](https://kaggle.com) | "
    "Pipeline: Spark → DuckDB → dbt → Streamlit"
)
