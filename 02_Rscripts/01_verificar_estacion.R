# 01_verificar_estacion.R
library(terra)

zip <- "01_data/raw/camels_cl_10362001.zip"
zip_dga <- "01_data/raw/estaciones-de-red-hidrometrica-dga_shapefile.zip"
tmp <- tempdir()

# CAMELS-CL
camels <- read.csv(unz(zip, "catchment_attributes.csv"),
                   check.names = FALSE)

nombre <- camels[camels$gauge_id == "gauge_name", 2]
codigo <- names(camels)[2]
lat <- as.numeric(camels[camels$gauge_id == "gauge_lat", 2])
lon <- as.numeric(camels[camels$gauge_id == "gauge_lon", 2])

p_camels <- vect(data.frame(lon, lat), c("lon", "lat"),
                 crs = "EPSG:4326")
xy_camels <- crds(project(p_camels, "EPSG:32718"))

# Inventario oficial DGA
unzip(zip_dga, exdir = tmp)
est <- vect(file.path(tmp, "Estación de Red Hidrométrica DGA.shp"))

p_dga <- est[est$cod_estaci == "10362001", ]
xy_dga <- crds(project(p_dga, "EPSG:32718"))

# Diferencia DGA - CAMELS
dif <- xy_camels[1, ] - xy_dga[1, ]
distancia <- sqrt(sum(dif^2))

# Cuenca CAMELS-CL
unzip(zip, grep("^polygon/", unzip(zip, list = TRUE)$Name,
                value = TRUE), exdir = tmp)

cuenca <- vect(file.path(tmp, "polygon/polygon.shp"))

dga_en_cuenca <- relate(
  project(p_dga, crs(cuenca)),
  cuenca,
  "intersects"
)[1, 1]

# Resultados
write.csv(data.frame(
  fuente = c("DGA", "CAMELS-CL"),
  nombre = c(p_dga$nombre, nombre),
  codigo = c(p_dga$cod_estaci, codigo),
  este_utm = c(xy_dga[1, 1], xy_camels[1, 1]),
  norte_utm = c(xy_dga[1, 2], xy_camels[1, 2]),
  crs = "EPSG:32718",
  punto_dga_en_cuenca_camels = c(dga_en_cuenca, NA)
), "03_outputs/tables/verificacion_estacion.csv",
row.names = FALSE)

write.csv(data.frame(
  dif_este_m = dif[1],
  dif_norte_m = dif[2],
  distancia_m = distancia
), "03_outputs/tables/discrepancia_estacion.csv",
row.names = FALSE)