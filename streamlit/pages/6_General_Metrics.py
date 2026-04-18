# --- SIDEBAR: FILTROS AVANZADOS ---
st.sidebar.header("🛠️ Configuración de Datos")

# Filtro por Fuente de Datos (200k vs Original)
fuente = st.sidebar.multiselect(
    "Fuente de Datos", 
    options=df['dataset_source'].unique(), 
    default=df['dataset_source'].unique()
)

# Filtro de Prioridad
prioridades = st.sidebar.multiselect(
    "Prioridad de Ticket", 
    options=df['priority'].unique(), 
    default=df['priority'].unique()
)

# Aplicar filtros al DataFrame
df_selection = df.query("dataset_source == @fuente & priority == @prioridades")

# Gráfico Comparativo Lado a Lado
st.subheader("📊 Comparativa: Volumen 200k vs Original")
fig_comp = px.histogram(
    df_selection, 
    x="category", 
    color="dataset_source", 
    barmode="group",
    template="plotly_dark",
    title="Distribución de Tickets por Fuente"
)
st.plotly_chart(fig_comp, use_container_width=True)

# --- GRÁFICO DE TORTA: CUMPLIMIENTO SLA ---
st.markdown("---")
st.subheader("🎯 Cumplimiento de SLA por Dataset")

col_left, col_right = st.columns(2)

# Procesamos los datos para la torta
sla_data = df_selection.groupby(['dataset_source', 'sla_status'])['total_tickets'].sum().reset_index()

with col_left:
    # Filtro rápido para la torta
    source_pie = st.selectbox("Seleccionar Fuente para Detalle", options=df_selection['dataset_source'].unique())
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
    st.write(" ")
    st.write(" ")
    st.info(f"""
    **Análisis de Eficiencia:**
    El gráfico muestra la proporción de tickets resueltos antes de las 24hs (**SLA Cumplido**) 
    frente a los que excedieron ese tiempo. 
    
    Actualmente estás visualizando los datos de: **{source_pie}**.
    """)

# --- SIDEBAR: FILTROS AVANZADOS ---
st.sidebar.header("🛠️ Configuración de Datos")

# Filtro por Fuente de Datos (200k vs Original)
fuente = st.sidebar.multiselect(
    "Fuente de Datos", 
    options=df['dataset_source'].unique(), 
    default=df['dataset_source'].unique()
)

# Filtro de Prioridad
prioridades = st.sidebar.multiselect(
    "Prioridad de Ticket", 
    options=df['priority'].unique(), 
    default=df['priority'].unique()
)

# Aplicar filtros al DataFrame
df_selection = df.query("dataset_source == @fuente & priority == @prioridades")

# Gráfico Comparativo Lado a Lado
st.subheader("📊 Comparativa: Volumen 200k vs Original")
fig_comp = px.histogram(
    df_selection, 
    x="category", 
    color="dataset_source", 
    barmode="group",
    template="plotly_dark",
    title="Distribución de Tickets por Fuente"
)
st.plotly_chart(fig_comp, use_container_width=True)
