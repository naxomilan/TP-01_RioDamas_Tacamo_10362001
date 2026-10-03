# Registro de uso de inteligencia artificial

Proyecto: TP-01 — Río Damas en Tacamo

Código CAMELS: 10362001

## Organización del trabajo y preparación del repositorio

- Herramienta utilizada: ChatGPT.
- Finalidad: apoyar la distribución de tareas y orientar la preparación del repositorio.
- Componente del trabajo: propuesta de tareas, estructura de carpetas, instrucciones de Git y README.md.
- Ejemplos de ayuda obtenida: propuesta de tareas por integrante, explicación de comandos y redacción de instrucciones para ejecutar el proyecto.
- Verificación: se abrió el README local y se confirmó que su apartado 8 contenía las instrucciones actualizadas. Queda pendiente documentar la revisión completa de la propuesta de tareas y la estructura frente al enunciado.
- Correcciones relevantes: pendientes de registrar según los resultados de esa revisión.

## Preparación inicial en R y registro de fuentes

- Herramienta utilizada: ChatGPT.
- Finalidad: ayudar a preparar la ejecución inicial del proyecto y el registro de sus fuentes de datos.
- Componente del trabajo: `02_Rscripts/00_setup.R`, `02_Rscripts/run_all.R`, `04_metadata/R_sessionInfo.txt` y plantilla de `04_metadata/data_sources.csv`.
- Ejemplos de ayuda obtenida: código para comprobar carpetas, ejecutar scripts en orden, registrar el entorno de R y crear los encabezados del registro de fuentes.
- Verificación: en la versión inicial, antes de incorporar la lectura de parametros.csv, `run_all.R` terminó sin errores. La comprobación `file.exists("04_metadata/R_sessionInfo.txt")` devolvió `TRUE`. Queda pendiente registrar el resultado de la comprobación de `data_sources.csv`.
- Correcciones relevantes: no se registraron correcciones al código de preparación inicial después de esa primera comprobación. Los problemas detectados al incorporar la configuración se documentan en las siguientes entradas.

## Configuración de parámetros y revisión del CSV

- Herramienta utilizada: ChatGPT.
- Finalidad: centralizar los parámetros compartidos del proyecto y ayudar a resolver el error de lectura del archivo de configuración.
- Componente del trabajo: `06_config/parametros.csv`, su lectura desde `02_Rscripts/00_setup.R` y su incorporación al flujo de `02_Rscripts/run_all.R`.
- Ejemplos de ayuda obtenida: contenido del CSV con el nombre de la cuenca y el código CAMELS 10362001, código para leer los parámetros conservando el identificador como texto e instrucciones para diagnosticar un archivo vacío.
- Verificación: al incorporar la configuración, `run_all.R` se detuvo con el mensaje “no lines available in input”. La comprobación `readLines("06_config/parametros.csv", warn = FALSE)` devolvió `character(0)`, confirmando que el archivo leído no contenía líneas. Queda pendiente confirmar que, después de guardar su contenido, `run_all.R` termine sin errores y que `config_tp$codigo_camels` devuelva `"10362001"`.
- Correcciones relevantes: se propuso completar el CSV mediante `writeLines()` desde la consola de RStudio. Posteriormente, se identificó y corrigió un problema de guardado en el Bloc de notas, descrito en la siguiente entrada.

## Corrección del guardado local

- Herramienta utilizada: ChatGPT.
- Finalidad: identificar por qué los cambios no aparecían en GitHub y orientar su guardado y publicación.
- Componente del trabajo: `README.md`, `05_docs/AI_USAGE.md`, `06_config/parametros.csv` y procedimiento de actualización del repositorio.
- Ejemplos de ayuda obtenida: interpretación de `git status` y explicación de los comandos `git add`, `git commit` y `git push`.
- Verificación: después de guardar el contenido localmente, `git status` mostró los tres archivos como modificados. Queda pendiente registrar la comprobación del contenido publicado en GitHub después de subir los cambios.
- Correcciones relevantes: se corrigió la instrucción de guardado del Bloc de notas, reemplazando Ctrl + S por Ctrl + G, correspondiente a la versión utilizada.

## Corrección del formato del README

- Herramienta utilizada: ChatGPT.
- Finalidad: recuperar un formato Markdown legible y ordenar las instrucciones del proyecto.
- Componente del trabajo: README.md.
- Ejemplos de ayuda obtenida: reorganización de las diez secciones, corrección de encabezados y viñetas, y reconstrucción de los bloques de código y las rutas.
- Verificación: se revisó el texto facilitado y se identificaron símbolos # sobrantes y barras invertidas que alteraban el formato y las rutas. Queda pendiente comprobar la visualización del documento corregido en GitHub.
- Correcciones relevantes: se eliminaron los símbolos sobrantes, se normalizaron los nombres de archivos y se distinguieron los productos de la preparación inicial de los resultados del análisis todavía pendientes.