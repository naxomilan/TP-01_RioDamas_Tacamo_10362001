# 04_delimitar_cuenca.R
library(terra)
library(whitebox)

p <- "01_data/processed"

# 1. Acondicionamiento del DEM
wbt_breach_depressions_least_cost(
  file.path(p, "dem_utm18s_30m.tif"),
  file.path(p, "dem_acondicionado.tif"),
  dist = 20,
  fill = TRUE
)

# 2. Direccion y acumulacion de flujo
wbt_d8_pointer(
  file.path(p, "dem_acondicionado.tif"),
  file.path(p, "d8_pointer.tif")
)

wbt_d8_flow_accumulation(
  file.path(p, "d8_pointer.tif"),
  file.path(p, "flow_accumulation.tif"),
  out_type = "cells",
  pntr = TRUE
)

# 3. Red de drenaje (area minima = 4 km2)
acc <- rast(file.path(p, "flow_accumulation.tif"))
N_thr <- 4e6 / prod(res(acc))

wbt_extract_streams(
  file.path(p, "flow_accumulation.tif"),
  file.path(p, "streams_4km2.tif"),
  threshold = N_thr,
  zero_background = TRUE
)

# 4. Punto de salida DGA
salida <- vect(
  data.frame(id = 1, x = 664955, y = 5500540),
  geom = c("x", "y"),
  crs = "EPSG:32718"
)

writeVector(
  salida,
  file.path(p, "salida_dga_original.shp"),
  overwrite = TRUE
)

# Ajuste del outlet al drenaje
wbt_snap_pour_points(
  file.path(p, "salida_dga_original.shp"),
  file.path(p, "flow_accumulation.tif"),
  file.path(p, "salida_dga_ajustada.shp"),
  snap_dist = 1200
)

salida_adj <- vect(
  file.path(p, "salida_dga_ajustada.shp")
)

# 5. Delimitacion de la cuenca
wbt_watershed(
  file.path(p, "d8_pointer.tif"),
  file.path(p, "salida_dga_ajustada.shp"),
  file.path(p, "cuenca_rio_damas.tif")
)

cuenca <- as.polygons(
  rast(file.path(p, "cuenca_rio_damas.tif")),
  dissolve = TRUE,
  na.rm = TRUE
)

writeVector(
  cuenca,
  file.path(p, "cuenca_rio_damas.gpkg"),
  overwrite = TRUE
)

# 6. Red de drenaje vectorial
wbt_raster_streams_to_vector(
  file.path(p, "streams_4km2.tif"),
  file.path(p, "d8_pointer.tif"),
  file.path(p, "red_drenaje_4km2.shp")
)

red <- vect(
  file.path(p, "red_drenaje_4km2.shp")
)

crs(red) <- "EPSG:32718"
red <- crop(red, cuenca)

writeVector(
  red,
  file.path(p, "red_drenaje_rio_damas.gpkg"),
  overwrite = TRUE
)

# 7. Orden de Strahler
wbt_strahler_stream_order(
  file.path(p, "streams_4km2.tif"),
  file.path(p, "d8_pointer.tif"),
  file.path(p, "strahler.tif")
)

strahler <- mask(
  crop(
    rast(file.path(p, "strahler.tif")),
    cuenca
  ),
  cuenca
)

# 8. Cauce principal
wbt_find_main_stem(
  file.path(p, "d8_pointer.tif"),
  file.path(p, "streams_4km2.tif"),
  file.path(p, "cauce_principal.tif"),
  zero_background = TRUE
)

wbt_raster_streams_to_vector(
  file.path(p, "cauce_principal.tif"),
  file.path(p, "d8_pointer.tif"),
  file.path(p, "cauce_principal.shp")
)

principal <- vect(
  file.path(p, "cauce_principal.shp")
)

crs(principal) <- "EPSG:32718"
principal <- crop(principal, cuenca)

writeVector(
  principal,
  file.path(p, "cauce_principal.gpkg"),
  overwrite = TRUE
)

# 9. Resultados
area <- expanse(cuenca, unit = "km")
ajuste <- distance(salida, salida_adj)[1]
orden <- global(strahler, "max", na.rm = TRUE)[1, 1]

cat(
  "Area:", round(area, 2), "km2\n",
  "Ajuste outlet:", round(ajuste, 2), "m\n",
  "Orden Strahler maximo:", orden, "\n"
)

# 10. Figura final
png(
  "03_outputs/figures/delimitacion_cuenca.png",
  width = 2000,
  height = 1600,
  res = 200
)

par(
  mar = c(4, 4, 6, 2),
  mgp = c(2.3, 0.7, 0)
)

plot(
  cuenca,
  col = "grey95",
  border = "black",
  lwd = 2,
  axes = TRUE,
  main = ""
)

# Red de drenaje
lines(
  red,
  col = "deepskyblue3",
  lwd = 1.4
)

# Cauce principal
lines(
  principal,
  col = "red3",
  lwd = 2.8
)

# Outlet ajustado
points(
  salida_adj,
  pch = 21,
  bg = "yellow",
  col = "black",
  cex = 1.5,
  lwd = 1.5
)

# Titulo
title(
  main = "Delimitacion y red de drenaje\nCuenca Rio Damas en Tacamo",
  cex.main = 1.35,
  font.main = 2,
  line = 2.5
)

# Subtitulo
mtext(
  "Copernicus GLO-30 | UTM 18S | Umbral de drenaje: 4 km2",
  side = 3,
  line = 0.4,
  cex = 0.85
)

# Leyenda
legend(
  "bottomright",
  inset = 0.02,
  legend = c(
    "Limite de cuenca",
    "Red de drenaje",
    "Cauce principal",
    "Outlet ajustado"
  ),
  col = c(
    "black",
    "deepskyblue3",
    "red3",
    "black"
  ),
  lty = c(1, 1, 1, NA),
  lwd = c(2, 1.4, 2.8, NA),
  pch = c(NA, NA, NA, 21),
  pt.bg = c(NA, NA, NA, "yellow"),
  pt.cex = 1.2,
  cex = 0.85,
  bg = "white",
  box.lwd = 1
)

# Norte
xn <- xmax(cuenca) - 1500
yn <- ymax(cuenca) - 2500

text(
  xn, yn,
  "N",
  font = 2,
  cex = 1.1
)

arrows(
  xn,
  yn - 2500,
  xn,
  yn - 500,
  length = 0.12,
  lwd = 2
)

# Escala grafica de 5 km
x0 <- xmin(cuenca) + 2000
y0 <- ymin(cuenca) + 2000

segments(
  x0, y0,
  x0 + 5000, y0,
  lwd = 3
)

segments(
  x0, y0 - 150,
  x0, y0 + 150,
  lwd = 2
)

segments(
  x0 + 5000, y0 - 150,
  x0 + 5000, y0 + 150,
  lwd = 2
)

text(
  x0,
  y0 + 500,
  "0",
  cex = 0.8
)

text(
  x0 + 5000,
  y0 + 500,
  "5 km",
  cex = 0.8
)

dev.off()