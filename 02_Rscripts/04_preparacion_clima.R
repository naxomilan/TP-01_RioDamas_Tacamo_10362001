# 04_preparacion_clima.R
# Series diarias del clima promedio de la cuenca, desde CR2MET v2.5.
# Ejecutar desde la carpeta principal del repositorio (lo llama run_all.R).
#
# Entrada: grillas mensuales de CR2MET v2.5 (parametro ruta_cr2met) y el
#          poligono sobre el que se promedia (parametro poligono_clima).
# Salida:  01_data/processed/clima_CR2METv25_<codigo>_daily_<inicio>-<fin>.csv
#          con fecha, P (mm/day), Tmax, Tmin y Tmed (degC).
#
# Las grillas pesan cerca de 39 GB y no se versionan (ver README, seccion de
# datos). Si no estan en el computador, el script no falla: deja la serie ya
# procesada que viene en el repositorio y avisa.
#
# Pendiente en este mismo script: PET (Hargreaves-Samani) y control de calidad.

# 1. Cargar la configuracion, si el script se corre solo
if (!exists("config_tp")) {
  source("02_Rscripts/00_setup.R", encoding = "UTF-8")
}

ruta_cr2met_tp    <- config_tp$ruta_cr2met
poligono_clima_tp <- config_tp$poligono_clima
codigo_tp         <- config_tp$codigo_camels

if (is.null(ruta_cr2met_tp) || is.null(poligono_clima_tp)) {
  stop(
    "Faltan ruta_cr2met o poligono_clima en 06_config/parametros.csv.",
    call. = FALSE
  )
}

# 2. Revisar si estan las grillas de CR2MET v2.5
carpeta_pr_tp  <- file.path(ruta_cr2met_tp, "pr")
carpeta_txn_tp <- file.path(ruta_cr2met_tp, "txn")

archivos_pr_tp  <- list.files(carpeta_pr_tp,  pattern = "[.]nc$", full.names = TRUE)
archivos_txn_tp <- list.files(carpeta_txn_tp, pattern = "[.]nc$", full.names = TRUE)

series_previas_tp <- list.files(
  "01_data/processed",
  pattern = paste0("^clima_CR2METv25_", codigo_tp, "_daily_.*[.]csv$")
)

if (length(archivos_pr_tp) == 0 || length(archivos_txn_tp) == 0) {
  if (length(series_previas_tp) > 0) {
    message(
      "04: no estan las grillas de CR2MET v2.5 en ", ruta_cr2met_tp,
      ". Se usa la serie ya procesada: ", series_previas_tp[1]
    )
  } else {
    stop(
      "No estan las grillas de CR2MET v2.5 en ", ruta_cr2met_tp,
      " ni la serie procesada. Descargarlas segun 04_metadata/data_sources.csv.",
      call. = FALSE
    )
  }
} else {

  # 3. Leer el poligono de la cuenca
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Falta instalar el paquete terra.", call. = FALSE)
  }
  library(terra)

  # El poligono se lleva al CRS de la grilla, por si llega en UTM.
  poligono_tp <- vect(poligono_clima_tp)
  poligono_tp <- project(poligono_tp, crs(rast(archivos_pr_tp[1])))

  # 4. Promediar sobre la cuenca un archivo mensual
  # Cada archivo trae 63 capas. Se eligen por nombre las del dato buscado
  # (pr_1..31, tmax_1..31 o tmin_1..31): pr_sd y cl_mask no son dato.
  # exact = TRUE pondera cada celda por la fraccion que cae dentro de la cuenca.
  promedio_cuenca_tp <- function(archivo, variable) {
    r <- rast(archivo)
    capas <- r[[grep(paste0("^", variable, "_[0-9]+$"), names(r))]]
    capas <- crop(capas, poligono_tp, snap = "out")
    v <- extract(capas, poligono_tp, fun = mean, na.rm = TRUE,
                 exact = TRUE, ID = FALSE)
    data.frame(fecha = as.Date(time(capas)), valor = as.numeric(unlist(v)))
  }

  leer_serie_tp <- function(archivos, variable) {
    message("04: leyendo ", variable, " (", length(archivos), " archivos)")
    do.call(rbind, lapply(archivos, promedio_cuenca_tp, variable = variable))
  }

  P_tp    <- leer_serie_tp(archivos_pr_tp,  "pr")
  Tmax_tp <- leer_serie_tp(archivos_txn_tp, "tmax")
  Tmin_tp <- leer_serie_tp(archivos_txn_tp, "tmin")

  # 5. Armar la tabla diaria
  # CR2MET v2.5 no trae Tmed: se calcula como (Tmax + Tmin) / 2.
  clima_tp <- data.frame(
    fecha     = P_tp$fecha,
    P_mm      = P_tp$valor,
    Tmax_degC = Tmax_tp$valor,
    Tmin_degC = Tmin_tp$valor
  )
  clima_tp$Tmed_degC <- (clima_tp$Tmax_degC + clima_tp$Tmin_degC) / 2

  # 6. Comprobaciones minimas (el control de calidad completo va despues)
  stopifnot(
    all(P_tp$fecha == Tmax_tp$fecha),  # mismas fechas en P y T
    all(P_tp$fecha == Tmin_tp$fecha),
    !anyDuplicated(clima_tp$fecha),
    all(diff(clima_tp$fecha) == 1),    # no faltan dias
    all(clima_tp$P_mm >= 0, na.rm = TRUE),
    all(clima_tp$Tmin_degC <= clima_tp$Tmax_degC, na.rm = TRUE)
  )

  # 7. Escribir la serie
  anios_tp <- format(range(clima_tp$fecha), "%Y")
  archivo_salida_tp <- file.path(
    "01_data/processed",
    paste0("clima_CR2METv25_", codigo_tp, "_daily_",
           anios_tp[1], "-", anios_tp[2], ".csv")
  )
  clima_tp[, -1] <- round(clima_tp[, -1], 3)
  write.csv(clima_tp, archivo_salida_tp, row.names = FALSE)

  message(
    "04: escrito ", archivo_salida_tp, " (", nrow(clima_tp), " dias, ",
    sum(is.na(clima_tp$P_mm)), " dias sin P)"
  )
}
