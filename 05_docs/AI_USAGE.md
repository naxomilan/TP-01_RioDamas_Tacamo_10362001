## Preparación del clima diario de la cuenca desde CR2MET v2.5

- Integrante: Fernanda Ravanal Medina.
- Herramienta utilizada: Claude (Anthropic), en Claude Code.
- Finalidad: escribir el codigo para extraer la precipitacion y las temperaturas diarias de CR2MET v2.5 sobre el poligono de la cuenca y dejarlo integrado al flujo del equipo.
- Componente del trabajo: `02_Rscripts/04_preparacion_clima.R` (secciones 1 a 5), filas de `06_config/parametros.csv`, exclusion de las grillas en `.gitignore`, filas de CR2MET v2.5 en `04_metadata/data_sources.csv` y nota del `README.md` sobre los datos excluidos.
- Ayuda obtenida: guia para codigo para recortar las grillas con el poligono y promediarlas sobre la cuenca, resolucion de dudas en errores, le pedi un respaldo para que el script use el CSV versionado cuando no estan las grillas (unos 39 GB); instrucciones de Git para trabajar en la rama `fernanda-clima-cr2met` y ayuda con la redaccion de los mensajes de commit, para ser brebe y evitar confucion.
- Verificacion: Claude probó el script en una copia del repositorio en tres casos, en paralelo, a modo de verificar. Con las grillas genero. Sin grillas ni CSV se detuvo e indicó donde descargar los datos. volvi a correr `run_all.R` en el repositorio del equipo antes de hacer los commits.
- Correcciones relevantes: el polígono de CAMELS-CL copiado desde el repositorio de práctica tenía otra fecha en la cabecera del `.dbf` y habría chocado con la rama principal, así que se trajo desde esa rama con `git restore --source`.

## PET de Hargreaves-Samani y control de calidad del clima

- Integrante: Fernanda Ravanal Medina.
- Herramienta utilizada: Claude (Anthropic), en Claude Code.
- Finalidad: calcular la evapotranspiración potencial diaria con los datos de temperatura disponibles y revisar la calidad de las series de clima.
- Componente del trabajo: `02_Rscripts/04_preparacion_clima.R` (secciones 6 y 7) y sus productos `04_control_calidad_clima.csv`, `04_cobertura_clima_anual.csv`, `04_PET_resumen_vs_CAMELS.csv`, `04_PET_mensual_vs_CAMELS.csv` y `04_PET_mensual_vs_CAMELS.png`.
- Ayuda obtenida: guia para implementación de la ecuación de Hargreaves-Samani y de la radiación extraterrestre con la latitud del centroide del polígono; para poder comparar doce revisiones día a día (fechas duplicadas, días faltantes, datos vacíos, P negativa, Tmin mayor que Tmax, Tmed fuera de [Tmin, Tmax], temperaturas fuera de rango, PET negativa), comparación con la PET de CAMELS-CL.
- Verificación: Claude implementó las ecuaciones de las vistas en clase. Las doce revisiones dieron 0 días con problema.
- Correcciones relevantes: el paso de la radiación de MJ m⁻² d⁻¹ a mm/d usa el factor 0.408 de FAO-56 (Allen et al., 1998, ec. 20), que no se encontró en clases; se dejó marcado en el script como agregado propio con `# +)`..

## Régimen hidroclimático, homogeneidad y clasificación climática

- Integrante: Fernanda Ravanal Medina.
- Herramienta utilizada: Claude (Anthropic), en Claude Code.
- Finalidad: describir el régimen de la cuenca y revisar si las series de clima son homogéneas y estacionarias en el período de análisis.
- Componente del trabajo: `02_Rscripts/05_regimen_hidroclimatico.R`, series mensual y anual en `01_data/processed/`, tablas y figuras `05_*` de `03_outputs/`, recorte del mapa de Köppen-Geiger y su fila en `04_metadata/data_sources.csv`.
- Ayuda obtenida: consejo para series mensuales y anuales en las que un mes o un año se calcula solo si tiene todos sus días (si falta uno, queda NA); climograma; régimen mensual P-PET-Q con el caudal de Alexis pasado a lámina, Q[mm/d] = 86.4·Q[m³/s]/A[km²]; prueba de Pettitt, más el valor p aproximado de Pettitt (1979); pruebas ADF y KPSS; índice de aridez; mapas de P y T media anual; recorte del mapa de Beck et al. (2023).
- Verificación: Claude comprobó que la suma de los doce meses de la climatología coincide con la P media anual y que la suma md5 del archivo de Köppen descargado coincide con la publicada. El cambio al polígono de Alexis se hizo modificando una sola línea de `06_config/parametros.csv` y se revisaron las cifras recalculadas: P media 1601.6 mm/año y PET/P = 0.608 en 1987-2019; Köppen Cfb 92.6 % y Csb 7.4 % del área. Fernanda volvió a correr `run_all.R` en el repositorio del equipo antes de hacer los commits.
- Correcciones relevantes: en el registro 1960-2021 la P muestra un posible quiebre (p = 0.043 por simulación y 0.059 con la aproximación de Pettitt); como está en el borde, no se presentó como quiebre demostrado. Las figuras se rehicieron con tildes y unidades en °C.

## Fichas E02, E03 y E04 del dossier

- Integrante: Fernanda Ravanal Medina.
- Herramienta utilizada: Claude (Anthropic), en Claude Code.
- Finalidad: redactar en LaTeX las fichas de calidad y cobertura de la información (E02), régimen hidroclimático (E03) y evolución de las variables hidrológicas (E04).
- Componente del trabajo: `05_docs/evidencias/E02_calidad_cobertura.tex`, `E03_regimen_hidroclimatico.tex`, `E04_evolucion_variables.tex` y `referencias_E02.bib`, subidos en la rama `fernanda-caudal33-evidencias` (PR #9).
- Ayuda obtenida: correccion en la redacción de las fichas a partir de las tablas de `03_outputs/`, tablas y pies de figura, e instrucciones de Git para la rama y los commits.
- Verificación: las cifras de E03 y E04 salen de tablas que genera `run_all.R`. Las de E02 salen de esas tablas, de las tablas de los scripts de Alexis sobre el caudal (08, 08b y 09) y de los valores publicados por Correa Frías y Merlet Badilla (1997). Las fichas pasaron por dos revisiones separadas, una de formato y otra de cifras contra las tablas, ambas hechas también con Claude; E02 pasó además por una limpieza de estilo.
- Correcciones relevantes: en la primera versión de E02 algunas cifras no salían de ningún script y ahora salen de `05_resumen_calidad_E02.csv`; se mezclaban 22 y 26 años de caudal y se unificó el criterio.
