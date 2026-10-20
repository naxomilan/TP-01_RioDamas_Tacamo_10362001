# 06b_preparar_uso_suelo.R
# Prepara CONAF 2018 y CIREN 2020 para 07_uso_suelo_territorio.R

library(terra)

raw  <- "01_data/raw"
proc <- "01_data/processed"

f_conaf  <- file.path(raw,  "conaf_catastro_los_lagos_2018.zip")
f_ciren  <- file.path(raw,  "ciren_suelos_los_lagos_2020.geojson")
f_cuenca <- file.path(proc, "cuenca_rio_damas.gpkg")

stopifnot(file.exists(f_conaf), file.exists(f_ciren), file.exists(f_cuenca))

# Cuenca
cuenca <- project(vect(f_cuenca), "EPSG:32718")

# ============================================================
# CONAF 2018
# ============================================================

tmp <- tempfile("conaf_")
dir.create(tmp)
unzip(f_conaf, exdir = tmp)

shp <- list.files(tmp, "\\.shp$", full.names = TRUE, recursive = TRUE)
if (length(shp) != 1) stop("No se encontró un único SHP de CONAF.")

conaf <- vect(shp)
if (!"USO" %in% names(conaf)) stop("CONAF no contiene el campo USO.")

conaf <- project(conaf, crs(cuenca))
conaf <- intersect(crop(conaf, cuenca), cuenca)

if (nrow(conaf) == 0) stop("CONAF no intersecta la cuenca.")

writeVector(
  conaf,
  file.path(proc, "cobertura_conaf_2018.gpkg"),
  overwrite = TRUE
)

# ============================================================
# CIREN 2020
# ============================================================

ciren <- vect(f_ciren)
if (!"textcaus" %in% names(ciren)) stop("CIREN no contiene el campo textcaus.")

ciren <- project(ciren, crs(cuenca))
ciren <- intersect(crop(ciren, cuenca), cuenca)

if (nrow(ciren) == 0) stop("CIREN no intersecta la cuenca.")

writeVector(
  ciren,
  file.path(proc, "suelos_ciren_2020.gpkg"),
  overwrite = TRUE
)

# ============================================================
# Control
# ============================================================

cat(
  "\nPreparación completada\n",
  "CONAF:", nrow(conaf), "polígonos |",
  length(unique(conaf$USO)), "clases\n",
  "CIREN:", nrow(ciren), "polígonos |",
  length(unique(ciren$textcaus)), "clases\n",
  "CRS: EPSG:32718\n"
)