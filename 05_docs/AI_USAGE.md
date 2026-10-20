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

## Registro de contribuciones del equipo

- Herramienta utilizada: ChatGPT.
- Finalidad: preparar un registro de las responsabilidades y contribuciones de los cuatro integrantes.
- Componente del trabajo: CONTRIBUTORS.md.
- Ejemplos de ayuda obtenida: propuesta de una plantilla con tareas principales, participación en scripts o análisis, revisiones de otros integrantes y fechas de los aportes.
- Verificación: se contrastaron los campos de la plantilla con la recomendación del apartado 11 del enunciado. Queda pendiente completar los datos del equipo y comprobar la publicación del archivo en GitHub.
- Correcciones relevantes: no se han identificado correcciones en esta preparación inicial; los datos todavía no confirmados se dejaron pendientes.

## Revisión del cambio en run_all.R

- Herramienta utilizada: ChatGPT.
- Finalidad: identificar el cambio pendiente en el script maestro antes de registrarlo en Git.
- Componente del trabajo: `02_Rscripts/run_all.R`.
- Ejemplos de ayuda obtenida: interpretación de la salida de `git diff` y del mensaje “No newline at end of file”.
- Verificación: la comparación mostró que la única diferencia era la incorporación de un salto de línea al final del archivo. La última instrucción y el resto del código permanecieron iguales.
- Correcciones relevantes: se conservó el salto de línea final; no fue necesario modificar las instrucciones de R.

## Convención de nombres del proyecto

- Herramienta utilizada: ChatGPT.
- Finalidad: establecer criterios comunes para nombrar los archivos y facilitar su identificación y trazabilidad.
- Componente del trabajo: apartado 4 de README.md y organización de futuros archivos del proyecto.
- Ejemplos de ayuda obtenida: redacción de reglas de nomenclatura, ejemplos de nombres para scripts y resultados, y explicación del orden lógico de numeración de los scripts.
- Verificación: se contrastaron las reglas propuestas con las indicaciones del enunciado. Queda pendiente comprobar su visualización en GitHub y aplicar estos criterios a los archivos que se incorporen.
- Correcciones relevantes: se documentó la necesidad de actualizar las referencias cuando cambie un nombre. No se han registrado renombrados de archivos durante este paso.

## Conservación de carpetas vacías

- Herramienta utilizada: ChatGPT.
- Finalidad: conservar en Git la estructura de carpetas que todavía no contienen datos o resultados.
- Componente del trabajo: `01_data/raw/`, `01_data/processed/`, `03_outputs/figures/` y `03_outputs/tables/`.
- Ejemplos de ayuda obtenida: explicación de la función de los archivos `.gitkeep` y comandos de PowerShell para crearlos cuando falten y comprobar su existencia.
- Verificación: se comprobó mediante PowerShell la presencia de un archivo `.gitkeep` en cada una de las cuatro carpetas. Queda pendiente comprobar su publicación en GitHub.
- Correcciones relevantes: el procedimiento conserva los marcadores existentes y completa los que falten para mantener la estructura del repositorio.

## Revisión de exclusiones y documentación de datos

- Herramienta utilizada: ChatGPT.
- Finalidad: revisar las exclusiones de Git y establecer cómo documentar los datos que no se incorporen al repositorio.
- Componente del trabajo: `.gitignore`, apartado 5 de README.md y procedimiento de actualización de `04_metadata/data_sources.csv`.
- Ejemplos de ayuda obtenida: revisión de las reglas existentes, incorporación de exclusiones para archivos del sistema operativo y redacción del procedimiento para documentar datos excluidos.
- Verificación: se revisaron las reglas proporcionadas y se consultó la documentación oficial de Git. La comprobación mediante `git check-ignore` no mostró coincidencias para los archivos del proyecto examinados. Queda pendiente comprobar los cambios publicados en GitHub.
- Correcciones relevantes: se conservaron las reglas existentes, se añadieron las exclusiones de archivos del sistema operativo y se documentó la obligación de registrar la obtención de los datos excluidos.

## Prueba inicial desde una copia nueva

- Herramienta utilizada: ChatGPT.
- Finalidad: comprobar que la preparación inicial del proyecto funcione utilizando los archivos publicados en GitHub y resolver los avisos detectados.
- Componente del trabajo: clonación del repositorio, proyecto de RStudio, `00_setup.R`, `run_all.R`, `parametros.csv` y `R_sessionInfo.txt`.
- Ejemplos de ayuda obtenida: instrucciones para probar una copia nueva, comprobar la regeneración del registro de R, validar el código CAMELS e interpretar el aviso sobre la última línea del CSV.
- Verificación: la prueba en la copia nueva terminó correctamente, regeneró `R_sessionInfo.txt` y confirmó el código CAMELS `"10362001"`. Se detectó un aviso por falta de salto de línea al final de `parametros.csv`. Después de corregirlo en el repositorio original, se comprobó la lectura del CSV sin ese aviso. La prueba abarcó la preparación inicial y se realizó en el mismo computador.
- Correcciones relevantes: se añadió un salto de línea al final de `06_config/parametros.csv`, conservando sus valores.

## Ajuste de las exclusiones de datos

- Herramienta utilizada: ChatGPT.
- Finalidad: permitir incorporar los datos necesarios al repositorio compartido y orientar la publicación del ajuste.
- Componente del trabajo: .gitignore y procedimiento de actualización mediante Git.
- Ejemplos de ayuda obtenida: identificación de las reglas que excluían datos originales, procesados y archivos Excel; explicación de git add, git commit y git push.
- Verificación: git diff confirmó la eliminación local del bloque de exclusiones. Después se creó el commit 687a164 y se confirmó su publicación en la rama ignacio/ajuste-gitignore. Queda pendiente integrar la modificación en main.
- Correcciones relevantes: se retiraron las exclusiones generales de datos, las de archivos Excel y las dos exclusiones específicas de archivos de la DGA. Se conservaron las reglas de archivos temporales y configuraciones personales. Durante la publicación se detectó que el ajuste seguía sin registrarse en un commit; se corrigió incorporándolo mediante git add, git commit y git push. El equipo revisará posteriormente qué archivos grandes requieren exclusiones específicas.

## Preparación del script de modelación y ubicación de los datos

- Herramienta utilizada: ChatGPT.
- Finalidad: orientar la organización de los datos y el inicio del script de modelación dentro de la rama de trabajo.
- Componente del trabajo: 01_data/raw/, 02_Rscripts/modelacion_airgr.R y proyecto de RStudio.
- Ejemplos de ayuda obtenida: explicación de la relación entre carpeta y rama, uso del archivo .Rproj, rutas relativas y código para localizar los archivos de datos.
- Verificación: queda pendiente comprobar que R utilice la carpeta principal del repositorio y encuentre los archivos copiados. Todavía no se ha verificado la modelación de la cuenca mediante esta asistencia.
- Correcciones relevantes: se identificaron en el script de ayudantía una ruta absoluta y referencias a otra cuenca, que deberán adaptarse antes de ejecutar el modelo del proyecto.

## Lectura inicial de las series diarias CAMELS-CL

- Herramienta utilizada: ChatGPT.
- Finalidad: preparar la lectura de las series diarias de la cuenca 10362001 para desarrollar la modelación.
- Componente del trabajo: 02_Rscripts/modelacion_airgr.R y archivos originales de 01_data/raw/camels_cl_10362001/.
- Ejemplos de ayuda obtenida: código para construir rutas relativas, leer los CSV de Q, P, PET, Tmax y Tmin, y mostrar sus columnas y primeras filas.
- Verificación: getwd() confirmó que R trabaja desde la raíz del repositorio y list.files() mostró los archivos de la cuenca, incluidos los cinco CSV seleccionados. Queda pendiente comprobar su lectura y revisar columnas, fechas, unidades y cobertura.
- Correcciones relevantes: se propuso conservar los encabezados originales mediante check.names = FALSE y revisar su contenido antes de seleccionar las columnas para el modelo. El código de lectura no modifica los archivos originales.

## Lectura y revisión inicial de las series diarias CAMELS-CL

- Herramienta utilizada: ChatGPT.
- Finalidad: preparar la lectura de las series diarias de la cuenca 10362001 y revisar su disponibilidad temporal antes de la modelación.
- Componente del trabajo: 02_Rscripts/modelacion_airgr.R y archivos originales de 01_data/raw/camels_cl_10362001/.
- Ejemplos de ayuda obtenida: código para leer los CSV conservando sus encabezados, seleccionar la columna de la cuenca y resumir fechas, valores ausentes, fechas repetidas y continuidad del calendario.
- Verificación: el script se ejecutó sin errores. Q_mm presentó 44368 filas, con 11638 valores disponibles entre 1986-02-01 y 2019-04-22. P, PET, Tmax y Tmin presentaron 15096 valores cada una, sin NA, entre 1979-01-01 y 2020-04-30. En las cinco series se obtuvieron cero fechas repetidas y cero días sin fila dentro del calendario de cada archivo. Quedan pendientes la revisión física de los valores, la comprobación de unidades, la selección del período, la unión de las series y la modelación.
- Correcciones relevantes: se distinguió entre cantidad de filas y cantidad de observaciones disponibles. Los valores ausentes se conservaron como NA y no se modificaron los archivos originales.

## Desarrollo y revisión de la modelación hidrológica con GR4J y GR6J

- Herramienta utilizada: ChatGPT.
- Finalidad: apoyar la escritura, organización, corrección y comprensión del código de modelación hidrológica diaria de la cuenca Río Damas en Tacamo para el período 1987–2019.
- Componente del trabajo: `02_Rscripts/modelacion_airgr.R`, preparación de entradas, calibración y validación de GR4J y GR6J, tablas y figuras de resultados, registro del entorno de R y comprobación del balance interno.
- Ejemplos de ayuda obtenida: generación y optimización de código en R utilizando `airGR` y `airGRteaching`; integración de los caudales procesados de la DGA con las series climáticas y la PET preparadas por el equipo; conversión del caudal de m³/s a mm/día; cálculo de NSE, RMSE y sesgo; exportación de resultados; y explicación de los parámetros, estados y flujos de los modelos.
- Verificación: en las ejecuciones revisadas se obtuvieron resultados de calibración y validación para ambos modelos. La comprobación del balance interno devolvió `cierre_ok = TRUE` en las cuatro combinaciones de modelo y período, con residuos numéricos cercanos a cero. Esta comprobación verifica el cierre numérico del balance implementado, pero no demuestra por sí sola que el modelo represente correctamente todos los procesos físicos de la cuenca. Quedan pendientes la elección final del modelo con orientación del profesor y la comprobación de la ejecución integrada mediante `run_all.R`.
- Correcciones relevantes: se actualizó el área utilizada en la conversión del caudal a 468,73 km², correspondiente a la delimitación realizada por Alexis; se mantuvo la distinción entre caudales observados y rellenados, utilizando los observados para la calibración y las métricas; se distinguió la PET de entrada de la evapotranspiración real simulada; y se reorganizó el código para reducir repeticiones y comprobar el balance considerando los intercambios y los cambios de almacenamiento.

## Integración del flujo de ejecución del proyecto

- Herramienta utilizada: ChatGPT.
- Finalidad: organizar la ejecución conjunta de los scripts y revisar sus dependencias para facilitar la reproducción del proyecto.
- Componente del trabajo: run_all.R, lectura inicial de caudales DGA, preparación del DEM y rutas de entrada de los scripts de integración y derechos de agua.
- Ejemplos de ayuda obtenida: revisión del orden de ejecución; controles de archivos, configuración y paquetes; registro del estado de cada script; conservación de la base regional de caudales para utilizar estaciones donantes; unificación de rutas CAMELS e instrucciones para guardar los cambios en una rama de Git.
- Verificación: se revisó la sintaxis del código propuesto y se realizaron pruebas controladas del maestro, incluyendo el orden de ejecución, la transferencia de objetos entre scripts y la detención ante errores. Queda pendiente confirmar la ejecución completa en el repositorio con todos los insumos reales.
- Correcciones relevantes: se propuso crear la tabla regional base en el control de caudales, permitir la actualización del DEM existente y normalizar las rutas CAMELS. Se identificó una diferencia entre el área y la PET utilizadas en Budyko y en airGR que debe revisarse antes de comparar sus resultados.