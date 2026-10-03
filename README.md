# TP-01 — Río Damas en Tacamo

## 1. Cuenca analizada y código

- Cuenca: Río Damas en Tacamo.
- Código CAMELS-CL: 10362001.

## 2. Integrantes del equipo

- Ignacio Millán: coordinador.
- Por completar.
- Por completar.
- Por completar.

## 3. Objetivo del TP-01

Caracterizar la cuenca y analizar sus procesos hidrológicos y su balance hídrico anual mediante un proyecto reproducible.

## 4. Estructura del directorio

- `01_data/`: datos originales en `raw/` y datos procesados en `processed/`.
- `02_Rscripts/`: scripts de R y script maestro de ejecución.
- `03_outputs/`: figuras en `figures/` y tablas en `tables/`, generadas mediante los scripts.
- `04_metadata/`: registro de fuentes de datos e información del entorno de R.
- `05_docs/`: dossier técnico y registro de uso de inteligencia artificial.
- `06_config/`: parámetros y archivos de configuración.

## 5. Fuentes de datos y versiones

Por completar con las fuentes efectivamente utilizadas y sus versiones.

La información detallada de las fuentes se registrará en `04_metadata/data_sources.csv`.

## 6. Requisitos de software

Por completar con los programas utilizados y sus versiones.

## 7. Paquetes de R requeridos

Por completar con los paquetes utilizados y sus versiones.

## 8. Instrucciones para reproducir el análisis

1. Abrir en RStudio el archivo `.Rproj` ubicado en la carpeta principal del repositorio.
2. Ejecutar en la consola de RStudio:

```r
source("02_Rscripts/run_all.R", encoding = "UTF-8")
```

Actualmente, el script maestro está preparado para ejecutar `02_Rscripts/00_setup.R`, crear las carpetas necesarias, cargar la configuración y generar o actualizar `04_metadata/R_sessionInfo.txt`.

El archivo `R_sessionInfo.txt` registra la versión de R, la plataforma y los paquetes cargados. Para comprobar su existencia, ejecutar:

```r
file.exists("04_metadata/R_sessionInfo.txt")
```

El resultado esperado es `TRUE`.

La configuración compartida se encuentra en `06_config/parametros.csv`. Actualmente contiene el nombre de la cuenca y su código CAMELS. Este archivo se carga desde `00_setup.R` al ejecutar `run_all.R`.

Esta versión realiza únicamente la preparación inicial. Los módulos de análisis hidrológico se incorporarán a medida que avance el proyecto.

## 9. Productos esperados

En la etapa actual, se espera generar o actualizar `04_metadata/R_sessionInfo.txt`.

La lista de figuras, tablas y demás productos del análisis se completará conforme se incorporen los módulos de procesamiento.

## 10. Problemas conocidos y pasos no automatizados

Por completar con los problemas detectados, los pasos que no puedan automatizarse y su justificación.

El proyecto se encuentra en etapa de preparación inicial; todavía falta incorporar y validar los módulos de análisis hidrológico.