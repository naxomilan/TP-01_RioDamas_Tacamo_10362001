# 05_comparar_cuenca.R
library(terra)

p <- "01_data/processed"
tmp <- tempdir()

# 1. Cuenca delimitada
propia <- vect(
  file.path(p, "cuenca_rio_damas.gpkg")
)

# 2. Cuenca CAMELS-CL
zip <- "01_data/raw/camels_cl_10362001.zip"

arch <- grep(
  "^polygon/",
  unzip(zip, list = TRUE)$Name,
  value = TRUE
)

unzip(
  zip,
  arch,
  exdir = tmp,
  overwrite = TRUE
)

camels <- vect(
  file.path(tmp, "polygon/polygon.shp")
)

camels <- project(
  camels,
  crs(propia)
)

# 3. Areas
area_propia <- expanse(
  propia,
  unit = "km"
)

area_camels <- expanse(
  camels,
  unit = "km"
)

# 4. Area comun
comun <- intersect(
  propia,
  camels
)

area_comun <- sum(
  expanse(comun, unit = "km")
)

# 5. Comparacion
dif_km2 <- area_propia - area_camels
dif_pct <- 100 * dif_km2 / area_camels
superposicion <- 100 * area_comun / area_camels

resultado <- data.frame(
  area_propia_km2 = area_propia,
  area_camels_km2 = area_camels,
  diferencia_km2 = dif_km2,
  diferencia_pct = dif_pct,
  area_comun_km2 = area_comun,
  superposicion_pct = superposicion
)

# 6. Guardar tabla
write.csv(
  resultado,
  "03_outputs/tables/comparacion_cuenca.csv",
  row.names = FALSE
)

print(
  round(resultado, 2)
)

# 7. Figura comparativa
png(
  "03_outputs/figures/comparacion_cuenca_camels.png",
  width = 2000,
  height = 1600,
  res = 200
)

par(
  mar = c(4, 4, 6, 2),
  mgp = c(2.3, 0.7, 0)
)

# Base
plot(
  propia,
  col = "white",
  border = NA,
  axes = TRUE,
  main = ""
)

# Area comun
plot(
  comun,
  col = "lightgreen",
  border = NA,
  add = TRUE
)

# Nuestra cuenca
lines(
  propia,
  col = "black",
  lwd = 2.2
)

# Cuenca CAMELS-CL
lines(
  camels,
  col = "red3",
  lwd = 2.2
)

# Titulo
title(
  main = "Comparacion de delimitaciones\nCuenca Rio Damas en Tacamo",
  cex.main = 1.35,
  font.main = 2,
  line = 2.5
)

# Subtitulo
mtext(
  "Cuenca delimitada con DEM vs. cuenca CAMELS-CL",
  side = 3,
  line = 0.4,
  cex = 0.85
)

# Leyenda abajo a la izquierda
legend(
  x = xmin(propia) + 1500,
  y = ymin(propia) + 6500,
  legend = c(
    "Cuenca delimitada",
    "Cuenca CAMELS-CL",
    "Area comun"
  ),
  col = c(
    "black",
    "red3",
    "lightgreen"
  ),
  lty = c(1, 1, NA),
  lwd = c(2.2, 2.2, NA),
  pch = c(NA, NA, 22),
  pt.bg = c(NA, NA, "lightgreen"),
  pt.cex = 1.5,
  cex = 0.85,
  bg = "white",
  box.col = "black",
  box.lwd = 1
)

# Norte arriba a la derecha
xn <- xmax(propia) - 2500
yn <- ymax(propia) - 3000

text(
  xn,
  yn,
  "N",
  font = 2,
  cex = 1.2
)

arrows(
  x0 = xn,
  y0 = yn - 3000,
  x1 = xn,
  y1 = yn - 600,
  length = 0.12,
  lwd = 2
)

dev.off()