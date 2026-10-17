# 02_preparar_datos.R
library(terra)

raw <- "01_data/raw"
proc <- "01_data/processed"
tmp <- tempdir()

# DEM Copernicus GLO-30 - OpenTopography
untar(
  file.path(raw, "copernicus_glo30_rio_damas.tar.gz"),
  exdir = proc
)

file.rename(
  file.path(proc, "output_hh.tif"),
  file.path(proc, "dem_copernicus_glo30.tif")
)

dem <- rast(file.path(proc, "dem_copernicus_glo30.tif"))

# Red hidrografica oficial IDE Chile
dir.create(file.path(proc, "hidrografia_ide"), showWarnings = FALSE)

unzip(
  file.path(raw, "Red_Hidrografica_Final.zip"),
  exdir = file.path(proc, "hidrografia_ide"),
  overwrite = TRUE
)

hidro <- vect(file.path(
  proc, "hidrografia_ide", "Red_Hidrografica_Final.shp"
))

# Cuenca CAMELS-CL + margen de 5 km
zip_camels <- file.path(raw, "camels_cl_10362001.zip")

unzip(
  zip_camels,
  grep("^polygon/", unzip(zip_camels, list = TRUE)$Name,
       value = TRUE),
  exdir = tmp
)

cuenca <- vect(file.path(tmp, "polygon/polygon.shp"))

zona <- buffer(project(cuenca, "EPSG:32718"), 5000)
zona <- project(zona, crs(hidro))

# Recorte de hidrografia
hidro_zona <- crop(hidro, zona)

writeVector(
  hidro_zona,
  file.path(proc, "hidrografia_rio_damas.gpkg"),
  overwrite = TRUE
)