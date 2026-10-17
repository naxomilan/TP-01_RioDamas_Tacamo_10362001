# 03_compatibilidad_espacial.R
library(terra)

proc <- "01_data/processed"

# Cargar datos
dem <- rast(file.path(proc, "dem_copernicus_glo30.tif"))
hidro <- vect(file.path(proc, "hidrografia_rio_damas.gpkg"))

# CRS comun: WGS84 / UTM 18S
dem_utm <- project(
  dem,
  "EPSG:32718",
  res = 30,
  method = "bilinear"
)

hidro_utm <- project(hidro, crs(dem_utm))

# Guardar
writeRaster(
  dem_utm,
  file.path(proc, "dem_utm18s_30m.tif"),
  overwrite = TRUE
)

writeVector(
  hidro_utm,
  file.path(proc, "hidrografia_utm18s.gpkg"),
  overwrite = TRUE
)