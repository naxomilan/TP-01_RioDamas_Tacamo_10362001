# TP-01 — Río Damas en Tacamo

Proyecto del curso IIO422 — Hidrología, semestre 2026-S2.

Repositorio:
[TP-01_RioDamas_Tacamo_10362001](https://github.com/naxomilan/TP-01_RioDamas_Tacamo_10362001)

## 1. Cuenca analizada y código

- Cuenca: Río Damas en Tacamo, Región de Los Lagos, Chile.
- Código CAMELS-CL y estación DGA utilizada: `10362001`.
- Período principal: 1987-01-01 a 2019-12-31.
- Agregación anual: año calendario, de enero a diciembre.
- Escala de modelación hidrológica: diaria.
- Área de la delimitación utilizada en la modelación: `468.73 km²`.
- Área de referencia CAMELS-CL: `466.7784 km²`.
- Sistema de referencia del procesamiento espacial: WGS 84 / UTM zona 18S, `EPSG:32718`.

El período principal corresponde al intervalo común seleccionado para integrar clima y caudal. Los datos climáticos abarcan un intervalo mayor, que permite disponer de información previa para inicializar los modelos.

Las diferencias entre la delimitación del equipo y la referencia CAMELS-CL se documentan en los resultados. La sección 10 identifica los módulos que utilizan cada referencia.

## 2. Integrantes del equipo

| Integrante | Responsabilidades principales |
|---|---|
| Javier Ignacio Millán Arce | Coordinación, preparación del repositorio, integración de scripts, modelación GR4J y GR6J y documentación final. |
| Alexis Maximiliano Llanquinao Sandoval | Delimitación, caracterización física, procesamiento espacial y control de calidad y reconstrucción de caudales DGA. |
| Fernanda Martina Ravanal Medina | Preparación del clima, cálculo de PET, control de calidad, régimen hidroclimático y documentación de resultados. |
| Vicente Antonio Rapiman Montes | Integración de datos para el balance, análisis de Budyko y procesamiento de derechos de aprovechamiento de aguas. |

Las contribuciones se documentan en `CONTRIBUTORS.md`.

El uso de inteligencia artificial se registra en `05_docs/AI_USAGE.md`.

## 3. Objetivo del TP-01

Caracterizar la cuenca del Río Damas en Tacamo y analizar su funcionamiento hidrológico durante 1987–2019 mediante la integración de información física, climática y fluviométrica, el estudio del balance hídrico y la modelación diaria con GR4J y GR6J.

El proyecto conserva datos procesados, procedimientos y evidencias para revisar los resultados y comprender sus supuestos y limitaciones.

## 4. Estructura del directorio

Todas las rutas son relativas a la carpeta principal del repositorio, donde se encuentran `README.md` y el archivo `.Rproj`.

| Ruta | Contenido |
|---|---|
| `01_data/raw/` | Datos originales descargados de las fuentes. |
| `01_data/processed/` | Series procesadas, capas espaciales e insumos preparados. |
| `02_Rscripts/` | Scripts de procesamiento y maestro `run_all.R`. |
| `03_outputs/figures/` | Mapas y gráficos generados. |
| `03_outputs/tables/` | Tablas de resultados y verificaciones. |
| `04_metadata/` | Fuentes, versiones del entorno y registros de ejecución. |
| `05_docs/` | Dossier técnico y documentación. |
| `06_config/` | Configuración compartida en `parametros.csv`. |

### Convenciones

- Conservar los nombres y rutas utilizados por los scripts.
- Utilizar rutas relativas, evitando rutas personales como `C:/Users/...`.
- Para archivos nuevos, preferir nombres descriptivos, sin espacios ni tildes.
- Algunos originales conservan nombres especiales porque los scripts los esperan exactamente así.
- Registrar fechas como `AAAA-MM-DD`.
- Mantener los originales sin modificaciones y guardar las transformaciones en `processed/`.
- Utilizar Git para registrar versiones del código y la documentación.
- El orden de ejecución está definido en `run_all.R`, considerando las dependencias entre módulos.

## 5. Fuentes de datos y preparación de entradas

El registro detallado se encuentra en:

`04_metadata/data_sources.csv`

Este archivo documenta fuentes, versiones, unidades, cobertura temporal, enlaces y observaciones.

Los archivos grandes excluidos mediante `.gitignore` deben descargarse por separado. Clonar el repositorio no descarga esos archivos.

### 5.1. Archivos originales requeridos

Guardar los siguientes archivos directamente en `01_data/raw/`:

| Insumo | Nombre esperado | Fuente |
|---|---|---|
| Cuenca CAMELS-CL | `camels_cl_10362001.zip` | [Explorador CAMELS-CL](https://camels.cr2.cl/) |
| Estaciones DGA | `estaciones-de-red-hidrometrica-dga_shapefile.zip` | [Inventario DGA — MMA](https://lineasdebasepublicas.mma.gob.cl/datos_abiertos/dataset/inventario-de-estaciones-dga) |
| Elevación Copernicus | `copernicus_glo30_rio_damas.tar.gz` | [Copernicus GLO-30 — OpenTopography](https://portal.opentopography.org/datasetMetadata?otCollectionID=OT.032021.4326.1) |
| Red hidrográfica | `Red_Hidrografica_Final.zip` | [Hidrografía de Arica a Los Lagos — Geoportal](https://geoportal.cl/geoportal/catalog/36436/Hidrograf%C3%ADa%20de%20la%20regi%C3%B3n%20de%20Arica%20a%20la%20regi%C3%B3n%20de%20Los%20Lagos) |
| Caudales históricos DGA | `caudal_diario_historico_dga_los_lagos.zip` | [Mapas DGA](https://mapas2.mop.gob.cl/) |
| Derechos de agua DGA | `Derechos_Concedidos_X_Region (1).xls` | [Derechos registrados — DGA](https://dga.mop.gob.cl/derechos-de-agua/derechos-registrados/) |
| Cobertura CONAF 2018 | `conaf_catastro_los_lagos_2018.zip` | [Planificación catastral — IDE MINAGRI](https://ide.minagri.gob.cl/descarga-de-capas-shp/planificacion-catastral/) |
| Capacidad de uso CIREN 2020 | `ciren_suelos_los_lagos_2020.geojson` | [CIREN Los Lagos — capa 10](https://esri.ciren.cl/server/rest/services/ESTUDIO_AGROLOGICO_SUELOS/MapServer/10) |

Además, se necesita la serie climática procesada o las grillas CR2MET, y el mapa Köppen global o su recorte, según las secciones correspondientes.

Conservar los archivos comprimidos: varios scripts los leen o extraen directamente.

Los nombres de los archivos internos también deben coincidir con las indicaciones siguientes. Renombrar un archivo no convierte su formato.

### 5.2. CAMELS-CL

1. Abrir el [Explorador CAMELS-CL](https://camels.cr2.cl/).
2. Buscar Río Damas en Tacamo, código `10362001`.
3. Descargar los datos de la cuenca.
4. Guardar el archivo como:

   `01_data/raw/camels_cl_10362001.zip`

Dentro del ZIP deben encontrarse, entre otros:

- `catchment_attributes.csv`
- `q_m3s_day.csv`
- `precip_cr2met_day.csv`
- `pet_hargreaves_day.csv`
- `cons_sf_wr_year.csv`
- `polygon/polygon.shp`
- Los componentes `.shx`, `.dbf` y `.prj` del polígono.

Los archivos extraídos utilizados por los módulos integrados deben quedar en:

`01_data/raw/camels_cl_10362001/`

Ejemplo:

`01_data/raw/camels_cl_10362001/pet_hargreaves_day.csv`

El maestro actualizado extrae los archivos necesarios cuando no están presentes en esa ubicación. Otros scripts también consultan directamente el ZIP.

Evitar una carpeta duplicada:

`01_data/raw/camels_cl_10362001/camels_cl_10362001/`

Conservar el ZIP aunque sus archivos ya estén extraídos.

Las series climáticas CAMELS se utilizan como referencia y en los módulos que lo indican expresamente. La versión de CR2MET incluida en esa descarga no está identificada en el explorador; no debe asumirse que es la misma que CR2MET v2.5.

Referencia:
[DOI: 10.1594/PANGAEA.894885](https://doi.org/10.1594/PANGAEA.894885).

### 5.3. Inventario de estaciones DGA

1. Abrir el [inventario de estaciones DGA del MMA](https://lineasdebasepublicas.mma.gob.cl/datos_abiertos/dataset/inventario-de-estaciones-dga).
2. Descargar el recurso Estaciones de Red Hidrométrica DGA en formato Shapefile.
3. Guardar el ZIP como:

   `01_data/raw/estaciones-de-red-hidrometrica-dga_shapefile.zip`

El script espera encontrar dentro del ZIP:

`Estación de Red Hidrométrica DGA.shp`

Conservar todos los archivos complementarios del Shapefile.

La versión registrada corresponde a la actualización del 21 de abril de 2026.

### 5.4. Modelo de elevación Copernicus GLO-30

Fuente:
[Copernicus Global Digital Elevation Models — OpenTopography](https://portal.opentopography.org/datasetMetadata?otCollectionID=OT.032021.4326.1).

Acceso al producto:
[Copernicus GLO-30](https://portal.opentopography.org/raster?opentopoID=OTSDEM.032021.4326.3).

El proyecto utiliza el producto de aproximadamente 30 m de resolución, descargado para una extensión rectangular que cubre la cuenca.

#### Procedimiento de descarga

1. Entrar a OpenTopography y abrir Copernicus 30m / GLO-30.
2. Desplazarse hasta el apartado `Coordinates`.
3. Activar `Manually enter selection coordinates`.
4. Introducir los límites siguientes:

| Límite | Nombre equivalente | Coordenada |
|---|---|---:|
| Oeste | `xmin`, West o longitud mínima | `-73.133472` |
| Este | `xmax`, East o longitud máxima | `-72.554861` |
| Sur | `ymin`, South o latitud mínima | `-40.823194` |
| Norte | `ymax`, North o latitud máxima | `-40.528194` |

Las coordenadas están expresadas en grados decimales, WGS84, `EPSG:4326`.

Conservar los signos negativos y utilizar punto decimal. Los límites de longitud corresponden al eje X y los de latitud al eje Y.

5. Seleccionar la salida de datos de elevación en formato GeoTIFF.
6. Solicitar el procesamiento y descargar el resultado.
7. Guardar el paquete utilizado por el proyecto como:

   `01_data/raw/copernicus_glo30_rio_damas.tar.gz`

8. Comprobar que contenga:

   `output_hh.tif`

El archivo debe contener valores de elevación; una imagen de visualización del relieve no reemplaza al raster de elevaciones.

`02_preparar_datos.R` extrae el insumo y prepara:

`01_data/processed/dem_copernicus_glo30.tif`

Los módulos siguientes realizan la reproyección, el acondicionamiento hidrológico y la delimitación.

Los límites fueron proporcionados por el integrante responsable de la descarga. Conservar el original y registrar cualquier nueva descarga o cambio de versión.

### 5.5. Red hidrográfica

1. Abrir la [ficha de hidrografía de Arica a Los Lagos](https://geoportal.cl/geoportal/catalog/36436/Hidrograf%C3%ADa%20de%20la%20regi%C3%B3n%20de%20Arica%20a%20la%20regi%C3%B3n%20de%20Los%20Lagos).
2. Descargar la capa correspondiente a la versión 2022.
3. Guardarla como:

   `01_data/raw/Red_Hidrografica_Final.zip`

El script espera encontrar:

`Red_Hidrografica_Final.shp`

junto con sus archivos complementarios, directamente dentro del ZIP.

### 5.6. Caudales diarios históricos DGA

1. Abrir [Mapas DGA](https://mapas2.mop.gob.cl/).
2. Seleccionar Descargar Reportes Históricos.
3. Elegir la Región de Los Lagos.
4. Entrar en Fluviométricos → Caudal Diario Histórico.
5. Descargar el archivo regional.
6. Renombrar `caudal_diario_historico_10.zip` como:

   `caudal_diario_historico_dga_los_lagos.zip`

7. Guardarlo en:

   `01_data/raw/caudal_diario_historico_dga_los_lagos.zip`

El ZIP debe contener:

`caudal_diario_historico_10.txt`

Conservar todas las estaciones del archivo regional. La reconstrucción de faltantes utiliza estaciones donantes, además de Río Damas en Tacamo.

La descarga utilizada por el equipo está registrada con fecha 2026-10-16.

Los scripts generan:

`01_data/processed/caudal_diario_para_airGR_1987_2019.csv`

Esta serie distingue el caudal observado, el caudal completado, el método de relleno y la estación donante cuando corresponde.

### 5.7. Derechos de aprovechamiento de aguas DGA

1. Abrir [Derechos registrados — DGA](https://dga.mop.gob.cl/derechos-de-agua/derechos-registrados/).
2. Descargar el listado de la X Región de Los Lagos.
3. Utilizar la versión correspondiente al corte `2026-09-04`, registrada en los metadatos.
4. Guardar el archivo como:

   `01_data/raw/Derechos_Concedidos_X_Region (1).xls`

El nombre incluye un espacio antes de `(1)` porque así está definido en el script.

La descarga del equipo se realizó el 19 de octubre de 2026.

El procesamiento espera la estructura del Excel revisado: omite seis filas iniciales y selecciona columnas por posición. Si el portal entrega una estructura diferente, debe revisarse la lectura antes de utilizarla.

La selección espacial actual utiliza el polígono CAMELS-CL. Los derechos registrados no equivalen a consumos de agua efectivamente medidos.

### 5.8. Cobertura y uso del suelo CONAF

Fuente:
[Planificación catastral — IDE MINAGRI](https://ide.minagri.gob.cl/descarga-de-capas-shp/planificacion-catastral/).

#### Descarga del original

1. Abrir el enlace.
2. Buscar el apartado Catastro y actualización de los recursos vegetacionales y uso de la tierra.
3. Localizar la Región de Los Lagos (X).
4. Verificar que corresponda al año 2018 y a la capa `cbn_10reg_2018`.
5. Presionar Descargar.
6. Guardar el archivo como:

   `01_data/raw/conaf_catastro_los_lagos_2018.zip`

El ZIP debe contener un único archivo `.shp`, junto con sus componentes. El script busca el Shapefile también dentro de subcarpetas.

La tabla de atributos debe incluir el campo:

`USO`

El producto corresponde al catastro de recursos vegetacionales y uso de la tierra de Los Lagos.

#### Procesamiento

`06b_preparar_uso_suelo.R`:

1. Extrae el ZIP en una carpeta temporal.
2. Localiza el Shapefile.
3. Comprueba la presencia del campo `USO`.
4. Reproyecta la capa al sistema de la cuenca, `EPSG:32718`.
5. Recorta las geometrías mediante su intersección con la cuenca delimitada.
6. Comprueba que existan polígonos resultantes.
7. Guarda:

   `01_data/processed/cobertura_conaf_2018.gpkg`

`07_uso_suelo_territorio.R` utiliza este GeoPackage para calcular superficies y generar el mapa de cobertura.

### 5.9. Capacidad de uso del suelo CIREN

Fuente general:
[Estudios agrológicos de suelos — CIREN](https://esri.ciren.cl/server/rest/services/ESTUDIO_AGROLOGICO_SUELOS/MapServer/layers).

Capa utilizada:
[REGIÓN LOS LAGOS — CIREN 2020, ID 10](https://esri.ciren.cl/server/rest/services/ESTUDIO_AGROLOGICO_SUELOS/MapServer/10).

#### Acceder a la consulta

1. Abrir el listado de capas.
2. Buscar `REGIÓN LOS LAGOS (CIREN 2020) (10)`.
3. Presionar el nombre de la capa.
4. Desplazarse hasta el final de su ficha.
5. Presionar `Query`.

Acceso directo:
[Consulta de la capa CIREN Los Lagos](https://esri.ciren.cl/server/rest/services/ESTUDIO_AGROLOGICO_SUELOS/MapServer/10/query).

#### Completar el formulario

Utilizar estos valores. Cuando se indica “vacío”, dejar el campo sin contenido; no escribir esa palabra.

| Campo | Valor |
|---|---|
| Where | `1=1` |
| Text | Vacío |
| Object IDs | Vacío |
| Time | Vacío |
| Input Geometry | Vacío |
| Geometry Type | Dejar por defecto |
| Input Spatial Reference | Vacío |
| Spatial Relationship | `Intersects` |
| Distance | Vacío |
| Units | Dejar por defecto |
| Relation | Vacío |
| Out Fields | `*` |
| Return Geometry | `True` |
| Return True Curves | `False` |
| Max Allowable Offset | Vacío |
| Geometry Precision | Vacío |
| Output Spatial Reference | `4326` |
| Having Clause | Vacío |
| Return IDs Only | `False` |
| Return Count Only | `False` |
| Order By Fields | Vacío |
| Group By Fields | Vacío |
| Output Statistics | Vacío |
| Return Z | `False` |
| Return M | `False` |
| Geodatabase Version Name | Vacío |
| Historic Moment | Vacío |
| Return Distinct Values | `False` |
| Result Offset | Vacío |
| Result Record Count | Vacío |
| Return Extent Only | `False` |
| SQL Format | `None` |
| Datum Transformation | Vacío |
| Parameter Values | Vacío |
| Range Values | Vacío |
| Quantization Parameters | Vacío |
| Unique IDs | Vacío |
| Return Unique IDs Only | `False` |
| Feature Encoding | `EsriDefault` |
| Format | `GeoJSON` |

Los campos principales significan:

- `Where = 1=1`: solicitar todos los registros de la capa regional.
- `Out Fields = *`: incluir todos los atributos.
- `Return Geometry = True`: incluir los polígonos.
- `Output Spatial Reference = 4326`: entregar coordenadas en WGS84 geográfico.
- `Format = GeoJSON`: obtener la información en ese formato geográfico.

Como `Input Geometry` queda vacío, esta consulta obtiene la capa regional sin recortarla a la cuenca.

#### Ejecutar y guardar

1. Comprobar que `Format` esté seleccionado como `GeoJSON`.
2. Presionar `Query (GET)`.
3. Esperar la respuesta.
4. Descargar o guardar la respuesta como:

   `01_data/raw/ciren_suelos_los_lagos_2020.geojson`

Si el navegador muestra el contenido como texto, guardar la respuesta conservando el formato GeoJSON. Evitar guardar una página HTML o añadir una extensión `.txt`.

Comprobar que la respuesta contenga elementos geográficos y que no sea un mensaje de error. Si el servicio informa que se superó el límite de transferencia, recuperar los registros restantes antes de considerar completa la descarga.

#### Procesamiento

`06b_preparar_uso_suelo.R`:

1. Lee el GeoJSON.
2. Comprueba la presencia del campo `textcaus`.
3. Reproyecta la capa a `EPSG:32718`.
4. Recorta las geometrías mediante su intersección con la cuenca delimitada.
5. Comprueba que existan polígonos resultantes.
6. Guarda:

   `01_data/processed/suelos_ciren_2020.gpkg`

`07_uso_suelo_territorio.R` utiliza este archivo para calcular superficies por capacidad de uso y generar su mapa.

#### Dependencia común de CONAF y CIREN

La preparación de ambas capas necesita:

`01_data/processed/cuenca_rio_damas.gpkg`

Este polígono se genera previamente con `04_delimitar_cuenca.R`.

Por tanto, el orden es:

1. Delimitar la cuenca.
2. Ejecutar `06b_preparar_uso_suelo.R`.
3. Ejecutar `07_uso_suelo_territorio.R`.

Los GeoPackage se regeneran durante la ejecución y se reemplazan si ya existen. No es necesario crearlos manualmente antes de ejecutar el maestro.

### 5.10. Clima CR2MET v2.5

Fuente:
[CR2MET v2.5 — Zenodo](https://zenodo.org/records/7529682).

DOI:
[10.5281/zenodo.7529682](https://doi.org/10.5281/zenodo.7529682).

Se utilizan precipitación y temperaturas máxima y mínima diarias de 1960–2021. La temperatura media se calcula como `(Tmax + Tmin) / 2`, y la PET mediante Hargreaves-Samani.

#### Alternativa A: utilizar la serie procesada

Debe existir:

`01_data/processed/clima_CR2METv25_10362001_daily_1960-2021.csv`

Cuando no encuentra las grillas, `04_preparacion_clima.R` utiliza esa serie y vuelve a calcular PET y sus verificaciones.

Conservar una sola versión de la serie diaria con ese patrón de nombre dentro de `processed/`.

Esta alternativa permite ejecutar los análisis temporales, pero no regenera el mapa espacial de precipitación y temperatura.

#### Alternativa B: recalcular desde las grillas

1. Descargar `CR2MET_pr_v2.5.zip` y `CR2MET_txn_v2.5.zip`.
2. Extraer la precipitación en:

   `01_data/raw/cr2met_v2.5/pr/`

3. Extraer las temperaturas en:

   `01_data/raw/cr2met_v2.5/txn/`

4. Comprobar que los `.nc` estén directamente dentro de esas carpetas.
5. Deben existir 744 archivos mensuales en cada carpeta, desde enero de 1960 hasta diciembre de 2021.

Patrones esperados:

- `pr/CR2MET_pr_v2.5_day_AAAA_MM_005deg.nc`
- `txn/CR2MET_tmin_tmax_v2.5_day_AAAA_MM_005deg.nc`

No utilizar una descarga parcial: los scripts pueden detectar archivos y comenzar el procesamiento aunque falten meses.

Esta alternativa recalcula las series sobre el polígono delimitado y permite regenerar los mapas espaciales.

Las sumas de comprobación MD5 de los ZIP están en `data_sources.csv`.

### 5.11. Clasificación Köppen-Geiger

Fuente:
[Mapas Köppen-Geiger de Beck y colaboradores](https://doi.org/10.6084/m9.figshare.21789074).

Utilizar la versión registrada en `data_sources.csv`: V3, versión 2 de Figshare.

1. Descargar `koppen_geiger_tif.zip`.
2. Extraer el archivo del período 1991–2020:

   `1991_2020/koppen_geiger_0p00833333.tif`

3. Colocarlo en:

   `01_data/raw/koppen_beck2023/koppen_geiger_0p00833333.tif`

El script genera:

`01_data/processed/koppen_1991_2020_10362001.tif`

Si el mapa global no está disponible, puede utilizarse ese recorte procesado. Debe existir al menos una de las dos entradas.

El período del mapa Köppen es 1991–2020. Se utiliza para caracterizar el clima y no modifica el período principal de análisis 1987–2019.

### 5.12. Conservación de versiones

Los portales pueden actualizar sus datos. Para reproducir los resultados:

- Consultar las versiones y fechas de `data_sources.csv`.
- Conservar los originales utilizados.
- Registrar cualquier sustitución de archivos.
- Evitar mezclar versiones durante una misma ejecución.
- Documentar con rutas específicas los archivos excluidos mediante `.gitignore`.

Los enlaces permiten localizar las fuentes; la reproducción exacta también requiere conservar la versión y el contenido utilizados.

## 6. Requisitos de software

- R.
- RStudio, recomendado para abrir el proyecto `.Rproj`.
- Git, para clonar el repositorio y consultar su historial.
- WhiteboxTools, utilizado en el procesamiento hidrológico del terreno.
- Conexión a Internet para instalar dependencias y descargar insumos.
- Espacio suficiente para originales, extracción y productos intermedios, especialmente si se utilizan las grillas CR2MET.

Las versiones de R y los paquetes se registran en:

`04_metadata/R_sessionInfo.txt`

La versión de WhiteboxTools se registra en:

`04_metadata/WhiteboxTools_version.txt`

La compatibilidad de la entrega debe verificarse mediante una ejecución completa en una sesión nueva de R.

## 7. Paquetes de R requeridos

| Paquete | Uso principal |
|---|---|
| `terra` | Datos espaciales, preparación de CONAF/CIREN y grillas climáticas. |
| `whitebox` | Acceso a WhiteboxTools para terreno y drenaje. |
| `trend` | Pruebas de homogeneidad y tendencias. |
| `tseries` | Pruebas estadísticas de series temporales. |
| `urca` | Análisis de estacionariedad. |
| `readxl` | Lectura del Excel de derechos DGA. |
| `sf` | Procesamiento espacial de derechos de agua. |
| `airGR` | Modelos hidrológicos y componentes de simulación. |
| `airGRteaching` | Preparación, calibración, simulación y gráficos de GR4J y GR6J. |

Ejecutar una vez en la consola de RStudio:

```r
paquetes_tp <- c(
  "terra", "whitebox", "trend", "tseries", "urca",
  "readxl", "sf", "airGR", "airGRteaching"
)

faltantes_tp <- paquetes_tp[
  !vapply(paquetes_tp, requireNamespace, logical(1), quietly = TRUE)
]

if (length(faltantes_tp) > 0) {
  install.packages(
    faltantes_tp,
    repos = "https://cloud.r-project.org"
  )
}
```

El paquete `whitebox` y el programa WhiteboxTools son componentes distintos. Comprobar e instalar el programa desde R:

```r
if (!isTRUE(whitebox::wbt_init())) {
  whitebox::install_whitebox()
}

stopifnot(isTRUE(whitebox::wbt_init()))
whitebox::wbt_version()
```

## 8. Instrucciones para reproducir el análisis

### 8.1. Obtener el repositorio

Para una copia nueva, abrir PowerShell en la carpeta donde se desea descargar el proyecto y ejecutar:

```powershell
git clone https://github.com/naxomilan/TP-01_RioDamas_Tacamo_10362001.git
Set-Location .\TP-01_RioDamas_Tacamo_10362001
```

Si el repositorio es privado, se requiere acceso autorizado.

Consultar la versión del código:

```powershell
git rev-parse HEAD
```

El resultado identifica el commit utilizado.

### 8.2. Preparar el proyecto

1. Abrir en RStudio el archivo `.Rproj` de la carpeta principal.
2. Instalar las dependencias de la sección 7.
3. Descargar y ubicar los ocho insumos de la sección 5.1.
4. Elegir entre utilizar las grillas CR2MET o la serie climática procesada.
5. Comprobar que esté disponible el mapa Köppen global o su recorte.
6. Revisar `06_config/parametros.csv`.
7. Comprobar que el maestro incluya `06b_preparar_uso_suelo.R` antes de `07_uso_suelo_territorio.R`.

Durante la ejecución se generan la delimitación, los GeoPackage CONAF/CIREN y las series procesadas de caudal.

La comprobación inicial del maestro debe solicitar el ZIP de CONAF y el GeoJSON de CIREN. Los GeoPackage correspondientes son salidas del procesamiento.

### 8.3. Configuración compartida

`06_config/parametros.csv` utiliza las columnas `parametro` y `valor`.

| Parámetro | Valor esperado |
|---|---|
| `codigo_camels` | `10362001` |
| `nombre_cuenca` | `Rio Damas en Tacamo` |
| `periodo_inicio` | `1987` |
| `periodo_fin` | `2019` |
| `ruta_cr2met` | `01_data/raw/cr2met_v2.5` |
| `poligono_clima` | `01_data/processed/cuenca_rio_damas.gpkg` |
| `serie_caudal` | `01_data/processed/caudal_diario_para_airGR_1987_2019.csv` |
| `caudal_col_fecha` | `fecha` |
| `caudal_col_valor` | `Q_completado_m3s` |
| `caudal_col_observado` | `Q_observado_m3s` |
| `caudal_col_metodo` | `metodo_relleno` |
| `pet_referencia` | `01_data/raw/camels_cl_10362001/pet_hargreaves_day.csv` |
| `p_referencia` | `01_data/raw/camels_cl_10362001/precip_cr2met_day.csv` |
| `koppen_tif` | `01_data/raw/koppen_beck2023/koppen_geiger_0p00833333.tif` |

Conservar el código de cuenca como texto.

Algunos módulos también definen parámetros dentro de sus scripts. Cambiar el CSV no modifica automáticamente esos valores; cualquier cambio de cuenca o período requiere revisar las dependencias.

### 8.4. Ejecutar el proyecto completo

Iniciar una sesión nueva de R, sin restaurar objetos anteriores.

Desde la carpeta principal, ejecutar en la consola de RStudio:

```r
source("02_Rscripts/run_all.R", encoding = "UTF-8")
```

La versión integrada del maestro ejecuta 18 scripts:

| Orden | Script | Función |
|---|---|---|
| 1 | `00_setup.R` | Preparar carpetas y configuración. |
| 2 | `01_verificar_estacion.R` | Verificar identificación y ubicación de la estación. |
| 3 | `02_preparar_datos.R` | Preparar elevación e hidrografía. |
| 4 | `03_compatibilidad_espacial.R` | Compatibilizar los datos espaciales. |
| 5 | `04_delimitar_cuenca.R` | Delimitar la cuenca y generar drenaje. |
| 6 | `05_comparar_cuenca.R` | Comparar la delimitación con CAMELS-CL. |
| 7 | `06_geomorfologia.R` | Calcular características físicas y mapas. |
| 8 | `06b_preparar_uso_suelo.R` | Preparar, reproyectar y recortar CONAF y CIREN. |
| 9 | `07_uso_suelo_territorio.R` | Analizar cobertura y capacidad de uso. |
| 10 | `08_control_calidad_Q.R` | Revisar el caudal DGA. |
| 11 | `08b_respaldo_relleno_Q.R` | Evaluar y preparar la reconstrucción de faltantes. |
| 12 | `09_consistencia_Q.R` | Generar la serie completada y revisar consistencia. |
| 13 | `04_preparacion_clima.R` | Preparar clima, PET y control de calidad. |
| 14 | `05_regimen_hidroclimatico.R` | Analizar régimen, variabilidad y clasificación climática. |
| 15 | `03_integrar_datos_equipo.R` | Preparar entradas para balance y Budyko. |
| 16 | `04_balance_budyko.R` | Calcular balance medio y resultados de Budyko. |
| 17 | `05_derechos_superficiales_DGA.R` | Seleccionar y localizar derechos superficiales. |
| 18 | `modelacion_airgr.R` | Calibrar y validar GR4J y GR6J. |

Los scripts de caudal comparten objetos durante esta secuencia. Ejecutarlos aisladamente y fuera de orden puede provocar errores por objetos inexistentes.

La ejecución puede actualizar resultados que ya estén presentes, incluyendo los GeoPackage de CONAF y CIREN.

### 8.5. Revisar la ejecución

El maestro actualizado genera:

- `04_metadata/run_all_estado.csv`: estado y duración de cada script.
- `04_metadata/alcance_run_all.txt`: indica si se utilizaron grillas climáticas o la serie procesada.
- `04_metadata/R_sessionInfo.txt`: entorno de R.
- `04_metadata/WhiteboxTools_version.txt`: versión del programa espacial.

Consultar el estado:

```r
estado_tp <- read.csv(
  "04_metadata/run_all_estado.csv",
  stringsAsFactors = FALSE
)

print(estado_tp, row.names = FALSE)

stopifnot(
  nrow(estado_tp) == 18L,
  all(estado_tp$estado == "OK")
)
```

Comprobar las salidas del nuevo módulo territorial:

```r
stopifnot(
  file.exists("01_data/processed/cobertura_conaf_2018.gpkg"),
  file.exists("01_data/processed/suelos_ciren_2020.gpkg")
)
```

El script `06b_preparar_uso_suelo.R` también muestra en consola el número de polígonos y clases de cada capa.

Si ocurre un error, revisar la consola y el registro. Corregir la causa antes de repetir la ejecución.

Que todos los scripts terminen confirma la ejecución técnica de esa corrida. También deben revisarse las tablas, figuras y advertencias para evaluar la coherencia de los resultados.

### 8.6. Configuración de la modelación

GR4J y GR6J se ejecutan a escala diaria:

| Etapa | Período |
|---|---|
| Calentamiento de calibración | 1986-01-01 a 1986-12-31 |
| Calibración | 1987-01-01 a 2006-12-31 |
| Calentamiento de validación | 2006-01-01 a 2006-12-31 |
| Validación | 2007-01-01 a 2019-12-31 |

El calentamiento inicializa los almacenamientos del modelo antes del período evaluado.

- Precipitación y PET: serie preparada a partir de CR2MET v2.5.
- Caudal de referencia: observaciones DGA.
- Área de conversión: `468.73 km²`.
- Conversión: `Q_mm_dia = Q_m3s * 86.4 / 468.73`.
- Criterio de calibración: NSE.
- Los días rellenados no se utilizan como observaciones para calibrar ni calcular las métricas.
- Se conservan ambos modelos para comparar sus resultados.
- La configuración actual no incorpora CemaNeige.

## 9. Productos esperados

### Datos procesados principales

En `01_data/processed/`:

- `cuenca_rio_damas.gpkg`
- Modelos de elevación y productos de drenaje.
- `cobertura_conaf_2018.gpkg`
- `suelos_ciren_2020.gpkg`
- `caudal_diario_dga_10362001.csv`
- `caudal_diario_para_airGR_1987_2019.csv`
- `clima_CR2METv25_10362001_daily_1960-2021.csv`
- Series climáticas mensuales y anuales.
- `koppen_1991_2020_10362001.tif`
- `base_diaria_budyko.csv`
- `base_anual_budyko.csv`
- `derechos_superficiales_cuenca_DGA.csv`
- `derechos_DGA_pendientes_ubicacion.csv`
- `derechos_superficiales_cuenca_DGA.gpkg`
- `entradas_airgr_1986_2019.csv`

### Figuras principales

En `03_outputs/figures/`:

- `delimitacion_cuenca.png`
- `comparacion_cuenca_camels.png`
- `curva_hipsometrica.png`
- `mapa_elevacion.png`
- `mapa_pendiente.png`
- `mapa_cobertura_conaf_2018.png`
- `mapa_suelos_capacidad_uso.png`
- `04_PET_mensual_vs_CAMELS.png`
- `05_climograma.png`
- `05_regimen_P_PET_Q.png`
- `05_cobertura_caudal.png`
- `05_evolucion_anual.png`
- `05_mapa_koppen.png`
- `caudal_medio_anual_1987_2019.png`
- `airgr_calibracion.png`
- `airgr_validacion.png`
- `airgr_gr6j_calibracion.png`
- `airgr_gr6j_validacion.png`

`05_mapas_P_T_media_anual.png` se regenera solamente cuando están disponibles las grillas CR2MET.

Los gráficos de balance y Budyko se guardan en la subcarpeta `balance_budyko/`.

### Tablas principales

En `03_outputs/tables/`:

- Verificaciones de estación y comparación de delimitaciones.
- Caracterización geomorfológica.
- `cobertura_conaf_2018.csv`
- `suelos_capacidad_uso.csv`
- Control de calidad, cobertura y reconstrucción de caudales.
- Resúmenes climáticos y evidencias para E02, E03 y E04.
- Resultados de balance y Budyko en `balance_budyko/`.
- `cobertura_DGA_para_airgr.csv`
- `metricas_airgr.csv`
- `parametros_airgr.csv`
- `metricas_airgr_gr6j.csv`
- `parametros_airgr_gr6j.csv`
- `comparacion_GR4J_GR6J.csv`
- `balance_interno_airgr.csv`
- Series simuladas y configuración ejecutada de ambos modelos.

El dossier interpreta estos productos. Su edición y compilación no forman parte de `run_all.R`.

## 10. Limitaciones, pasos manuales y verificación final

### Preparación de entradas

- Las descargas originales se realizan manualmente siguiendo la sección 5.
- Los límites de descarga del DEM están documentados en la sección 5.4.
- La preparación de CONAF y CIREN está automatizada en `06b_preparar_uso_suelo.R`.
- Los archivos originales CONAF y CIREN deben estar disponibles aunque existan GeoPackage de una ejecución anterior, porque el flujo completo los regenera.
- Sin grillas CR2MET se ejecutan los análisis temporales desde la serie procesada, pero no se regeneran los mapas espaciales de precipitación y temperatura.
- Los portales pueden actualizar datos y formatos; una nueva descarga puede producir resultados diferentes.

### Revisión de los productos territoriales

Después de regenerar las capas CONAF y CIREN:

1. Ejecutar el análisis territorial posterior.
2. Revisar superficies, porcentajes y mapas.
3. Comparar los resultados con las cifras del dossier.
4. Actualizar las tablas, figuras o explicaciones del dossier si los resultados cambian.

La existencia de los archivos y de polígonos resultantes no comprueba por sí sola la cobertura completa de la cuenca ni la ausencia de superposiciones entre geometrías.

### Coherencia entre módulos

La versión revisada presenta diferencias que deben unificarse o justificarse en el dossier:

- GR4J/GR6J utiliza el área delimitada de `468.73 km²` y la PET calculada por el equipo.
- La integración para Budyko utiliza el área de `catchment_attributes.csv` y la PET de CAMELS-CL.
- La selección de derechos superficiales DGA utiliza el polígono CAMELS-CL.

El balance de Budyko emplea el parámetro de Fu `w = 2.6`, adoptado sin calibración local.

La conversión de derechos a demanda potencial supone su ejercicio continuo y no representa consumo medido.

El cierre del balance interno de los modelos es una comprobación numérica; no demuestra por sí mismo que todos sus componentes representen procesos reales de la cuenca.

### Verificación de la entrega

Antes de dar por validada la reproducción completa:

1. Ejecutar el maestro actualizado en una copia nueva y una sesión limpia de R.
2. Confirmar que los 18 scripts terminen con estado `OK`.
3. Comprobar la generación de los GeoPackage de CONAF y CIREN desde los originales.
4. Revisar el alcance registrado para la ejecución climática.
5. Comprobar tablas y figuras frente al dossier.
6. Registrar el commit de entrega y conservar la información del entorno.
7. Resolver o justificar las diferencias entre módulos.

La prueba integral debe registrarse cuando se realice. Actualizar este documento no equivale a haber completado esa verificación.