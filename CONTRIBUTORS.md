# Integrantes y contribuciones

Proyecto: TP-01 — Río Damas en Tacamo

Código CAMELS: 10362001

Fecha de actualización del registro: 2026-10-20.

Este registro se completó retrospectivamente utilizando el historial de commits y la información proporcionada por el equipo. Las fechas de los commits indican cuándo se registraron los cambios en Git; el desarrollo de esas actividades pudo comenzar antes.

## Ignacio Millán

- Tareas principales: coordinación del equipo, creación y administración del repositorio, organización del proyecto reproducible, modelación hidrológica e integración final de los resultados.

- Scripts o análisis en los que participó: creación de la estructura de carpetas; preparación de `02_Rscripts/00_setup.R` y de la versión inicial de `02_Rscripts/run_all.R`; configuración de la cuenca; preparación y actualización de README, CONTRIBUTORS, registro de fuentes y registro de uso de IA. Ajuste de `.gitignore` para permitir incorporar los datos necesarios. Incorporación inicial de datos CAMELS-CL y revisión de su cobertura. Desarrollo de `02_Rscripts/modelacion_airgr.R`, integrando los datos climáticos y los caudales procesados por el equipo. Calibración y validación de GR4J y GR6J, comparación de sus métricas, generación de tablas y figuras y comprobación del balance interno de los modelos. Preparación de contenidos de modelación y organización de evidencias para el dossier técnico.

- Revisiones del trabajo de otros integrantes: revisión del registro de fuentes de Fernanda y de las exclusiones de datos del repositorio; revisión de la coherencia del área, las unidades y los períodos al integrar los datos del equipo en la modelación; revisión e integración de contribuciones mediante pull requests.

- Fechas de los principales aportes: 2026-10-02, creación del repositorio y estructura inicial; 2026-10-03, preparación de scripts iniciales, configuración, documentación, registros y prueba inicial de ejecución; 2026-10-12, ajuste de `.gitignore` y documentación del cambio; 2026-10-13, incorporación de datos CAMELS y revisión de cobertura para modelación; 2026-10-20, actualización de la modelación GR4J y GR6J y de su registro de uso de IA.

- Estado: repositorio y modelación desarrollados; integración y revisión final en curso.

- Pendientes: actualizar y ordenar el README; completar el orden de ejecución de los scripts en `run_all.R`; comprobar la ejecución completa del proyecto; revisar rutas, nombres de archivos y correspondencia entre resultados y dossier; completar los últimos detalles de documentación y entrega.

## Fernanda Ravanal

- Tareas principales: preparación de datos climáticos, control de calidad, cálculo de evapotranspiración potencial, caracterización del régimen hidroclimático y elaboración de las evidencias E02, E03 y E04 del dossier.

- Scripts o análisis en los que participó: registro y corrección de fuentes y rutas en `04_metadata/data_sources.csv`; obtención y procesamiento de CR2MET v2.5; preparación de series diarias, mensuales y anuales de clima; cálculo de PET mediante Hargreaves-Samani y comparación con CAMELS-CL. Revisión de cobertura y calidad, análisis de homogeneidad y prueba de Pettitt. Elaboración de climatología mensual, climograma, régimen de precipitación, PET y caudal, indicadores de aridez y mapas climáticos. Incorporación de la clasificación Köppen-Geiger de Beck et al. (2023). Actualización de las series climáticas usando el polígono delimitado por Alexis y actualización de los productos del régimen con el caudal rellenado. Preparación y actualización de los contenidos y cifras de E02, E03 y E04.

- Revisiones del trabajo de otros integrantes: identificación de las exclusiones de `.gitignore` que impedían compartir datos necesarios y propuesta de corregirlas; revisión de la coherencia de sus productos climáticos y de régimen al incorporar el polígono y los caudales preparados por Alexis.

- Fechas de los principales aportes: 2026-10-07, registro de fuentes CAMELS-CL y contribuciones iniciales; 2026-10-11, corrección de rutas y precisión de la versión de CR2MET y disponibilidad de temperatura media; 2026-10-16, incorporación de fuentes CR2MET v2.5 y de la serie climática diaria; 2026-10-18, incorporación de PET, controles de calidad, comparación con CAMELS, series mensuales y anuales y climograma; 2026-10-19, actualización del clima con el polígono delimitado, incorporación de caudales procesados, análisis del régimen y homogeneidad, clasificación Köppen-Geiger y actualización de E02, E03 y E04.

- Estado: tareas asignadas finalizadas el 2026-10-19.

- Pendientes: no se reportan tareas individuales pendientes.

## Alexis Llanquinao

- Tareas principales: preparación de información espacial, delimitación de la cuenca, caracterización física, elaboración de cartografía y procesamiento de caudales de la DGA.

- Scripts o análisis en los que participó: preparación y compatibilidad espacial de los datos; procesamiento del DEM Copernicus GLO-30, reproyección a UTM 18S y acondicionamiento hidrológico; delimitación de la cuenca y obtención de acumulación de flujo y red de drenaje. Comparación con la cuenca CAMELS-CL y verificación de la estación DGA y su correspondencia con CAMELS-CL. Caracterización geomorfológica, elaboración de mapas de elevación y pendiente y de la curva hipsométrica. Caracterización de cobertura del suelo CONAF y capacidad de uso del suelo. Determinación del área delimitada de 468,73 km². Procesamiento, control de calidad, reconstrucción y análisis de consistencia de los caudales DGA para 1987–2019, con preparación de los datos para el resto del equipo. Documentación de fuentes y preparación de los contenidos de delimitación y caracterización física del dossier.

- Revisiones del trabajo de otros integrantes: sin detalle individual de revisiones cruzadas en este registro.

- Fechas de los principales aportes: 2026-10-17, incorporación de scripts y productos de preparación espacial, delimitación, geomorfología, hidrografía, cobertura y capacidad de uso del suelo, además del control de calidad de caudales y actualización de fuentes; 2026-10-19, incorporación del respaldo, reconstrucción y consistencia de caudales de 1987–2019 y documentación de la fuente histórica diaria de la DGA.

- Estado: tareas asignadas finalizadas el 2026-10-19.

- Pendientes: no se reportan tareas individuales pendientes.

## Vicente Rapiman

- Tareas principales: análisis de derechos de aprovechamiento y demandas de agua, estimación de evapotranspiración mediante Budyko, balance hídrico y síntesis del funcionamiento hidrológico de la cuenca.

- Scripts o análisis en los que participó: filtrado y procesamiento de derechos de aprovechamiento de agua de Río Damas, incluida la depuración de registros sin información de subsubcuenca; análisis de demandas y de la relación entre oferta y demanda de agua; estimación de evapotranspiración mediante Budyko y elaboración del balance hídrico anual. Preparación de tablas, figuras, interpretación de resultados y esquema conceptual correspondientes a sus tareas. Elaboración de contenidos de síntesis para el dossier técnico.

- Revisiones del trabajo de otros integrantes: sin detalle individual de revisiones cruzadas en este registro.

- Fechas de los principales aportes: 2026-10-04, registro en Git del filtrado de derechos de agua de Río Damas y de la depuración de valores ausentes en SubSubCuenca; 2026-10-19, finalización de sus tareas asignadas, según lo informado por el equipo. El historial compartido no permite asignar fechas individuales a los demás análisis.

- Estado: tareas asignadas finalizadas el 2026-10-19.

- Pendientes: no se reportan tareas individuales pendientes.