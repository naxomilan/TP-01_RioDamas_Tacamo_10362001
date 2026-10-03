# \# TP-01 - Río Damas en Tacamo

# 

# \## 1. Cuenca analizada y código

# Cuenca: Río Damas en Tacamo.

# Código CAMELS-CL: 10362001.

# 

# \## 2. Integrantes del equipo

# \- Ignacio Millán: coordinador.

# \- Por completar.

# \- Por completar.

# \- Por completar.

# 

# \## 3. Objetivo del TP-01

# Caracterizar la cuenca y analizar sus procesos hidrológicos y su

# balance hídrico anual mediante un proyecto reproducible.

# 

# \## 4. Estructura del directorio

# \- 01\_data: datos originales y procesados.

# \- 02\_Rscripts: scripts de R.

# \- 03\_outputs: figuras y tablas generadas.

# \- 04\_metadata: fuentes de datos y versiones del entorno.

# \- 05\_docs: dossier y documentación.

# \- 06\_config: parámetros y configuración.

# 

# \## 5. Fuentes de datos y versiones

# Por completar con las fuentes efectivamente utilizadas.

# 

# \## 6. Requisitos de software

# Por completar con los programas y sus versiones.

# 

# \## 7. Paquetes de R requeridos

# Por completar con los paquetes utilizados.

# 

# \## 8. Instrucciones para reproducir el análisis

# 

# 1\. Abrir en RStudio el archivo `.Rproj` ubicado en la carpeta principal del repositorio.

# 2\. Ejecutar en la consola de RStudio:

# 

# ```r

# source("02\_Rscripts/run\_all.R", encoding = "UTF-8")

# ```

# 

# Actualmente, el script maestro ejecuta `00\\\\\\\\\\\\\\\_setup.R`, prepara las carpetas necesarias y genera el archivo `04\\\\\\\\\\\\\\\_metadata/R\\\\\\\\\\\\\\\_sessionInfo.txt`, que registra la versión de R, la plataforma y los paquetes cargados.

# 

# Para comprobar que se generó este archivo, ejecutar:

# 

# ```r

# file.exists("04\_metadata/R\_sessionInfo.txt")

# ```

# 

# El resultado esperado es `TRUE`.

# 

# Esta versión realiza únicamente la preparación inicial. Los módulos de análisis hidrológico se incorporarán a medida que avance el proyecto.



# La configuración compartida se encuentra en `06\\\_config/parametros.csv`.

# Actualmente contiene el nombre de la cuenca y su código CAMELS.

# El archivo se carga automáticamente desde `00\\\_setup.R` al ejecutar

# `run\\\_all.R`.

# 

# \## 9. Productos esperados

# Por completar con los archivos que generará el análisis.

# 

# \## 10. Problemas conocidos y pasos no automatizados

# Por completar, incluyendo su justificación cuando corresponda.

