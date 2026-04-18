misma carpeta):

bash

```
# Definir JAVA_HOME y actualizar el PATH
export JAVA_HOME=$(pwd)/jdk-11.0.2
export PATH=$JAVA_HOME/bin:$PATH

# Definir SPARK_HOME y actualizar el PATH
export SPARK_HOME=$(pwd)/spark-3.3.2-bin-hadoop3
export PATH=$PATH:$SPARK_HOME/bin
```

Usa el código con precaución.

3. Verificación final

Antes de tirar el `make`, chequeá que las versiones sean las correctas:

bash

```
java -version    # Debería decir openjdk version "11.0.2"
spark-submit --version  # Debería decir version 3.3.2
```
