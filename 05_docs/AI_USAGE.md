\# Registro de uso de inteligencia artificial



Proyecto: TP-01 — Río Damas en Tacamo

Código CAMELS: 10362001



\## Organización del trabajo y preparación del repositorio



\- Herramienta utilizada: ChatGPT.

\- Finalidad: apoyar la distribución de tareas y orientar la preparación del repositorio.

\- Componente del trabajo: propuesta de tareas, estructura de carpetas, instrucciones de Git y README.md.

\- Ejemplos de ayuda obtenida: propuesta de tareas por integrante, explicación de comandos y redacción de instrucciones para ejecutar el proyecto.

\- Verificación: se abrió el README local y se confirmó que su apartado 8 contenía las instrucciones actualizadas. Queda pendiente documentar la revisión completa de la propuesta de tareas y la estructura frente al enunciado.

\- Correcciones relevantes: pendientes de registrar según los resultados de esa revisión.



\## Preparación inicial en R y registro de fuentes



\- Herramienta utilizada: ChatGPT.

\- Finalidad: ayudar a preparar la ejecución inicial del proyecto y el registro de sus fuentes de datos.

\- Componente del trabajo: 00\_setup.R, run\_all.R, R\_sessionInfo.txt y plantilla de data\_sources.csv.

\- Ejemplos de ayuda obtenida: código para comprobar carpetas, ejecutar scripts en orden, registrar el entorno de R y crear los encabezados del registro de fuentes.

\- Verificación: run\_all.R terminó sin errores y la comprobación de existencia de 04\_metadata/R\_sessionInfo.txt devolvió TRUE. Queda pendiente registrar el resultado de la comprobación de data\_sources.csv.

\- Correcciones relevantes: no se han registrado correcciones posteriores a las comprobaciones indicadas.



\## Configuración de parámetros y revisión del CSV



Se utilizó ChatGPT para preparar `06\\\_config/parametros.csv` con el nombre de la cuenca y el código CAMELS 10362001, y para incorporar su lectura en `02\\\_Rscripts/00\\\_setup.R`. La finalidad fue centralizar los parámetros compartidos del proyecto. La ayuda incluyó el contenido del CSV, el código de lectura y las instrucciones para conservar el identificador CAMELS como texto.



Durante la verificación, la ejecución de `run\\\_all.R` se detuvo con el mensaje “no lines available in input”. Se examinó el archivo mediante `readLines("06\\\_config/parametros.csv", warn = FALSE)`, que devolvió `character(0)`, confirmando que el archivo leído no contenía líneas.



Como corrección, ChatGPT propuso escribir las tres líneas del CSV mediante `writeLines()` desde la consola de RStudio. Queda pendiente registrar la aplicación de esta corrección y comprobar que `run\\\_all.R` termine sin errores y que `config\\\_tp$codigo\\\_camels` devuelva `"10362001"`.


## Corrección del guardado local

Se utilizó ChatGPT para interpretar el estado de Git y orientar la publicación de los cambios en README.md, AI_USAGE.md y parametros.csv. Se detectó que el contenido editado en el Bloc de notas no se había guardado porque se había indicado un atajo incorrecto para la versión utilizada. Se corrigió la instrucción usando Ctrl + G. Después de guardar, se comprobó mediante git status que los tres archivos aparecían como modificados. Esta comprobación confirma el guardado local; la publicación se verificará revisando los archivos en GitHub después de subirlos.

