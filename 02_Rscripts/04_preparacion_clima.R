# 04_preparacion_clima.R
# Series diarias del clima promedio de la cuenca, desde CR2MET v2.5,
# con su PET (Hargreaves-Samani) y su control de calidad.
# Ejecutar desde la carpeta principal del repositorio (lo llama run_all.R).
#
# Entrada: grillas mensuales de CR2MET v2.5 (parametro ruta_cr2met), el
#          poligono sobre el que se promedia (parametro poligono_clima) y
#          (si está) la PET diaria de CAMELS-CL para comparar (pet_referencia).
# Salida:  01_data/processed/clima_CR2METv25_<codigo>_daily_<inicio>-<fin>.csv
#          con fecha, P (mm/day), Tmax, Tmin, Tmed (degC) y PET (mm/day).
#          03_outputs/tables/04_*.csv con el control de calidad.
#          03_outputs/figures/04_PET_mensual_vs_CAMELS.png
#
# Las grillas pesan cerca de 39 GB y no se versionan (ver README, seccion de
# datos). Si no estan en el computador, no importa el script no falla: parte desde la
# serie ya procesada que viene en el repositorio y avisa. La PET y el control
# de calidad se calculan igual en los dos casos.

# 1. Cargar la configuracion, si el script se corre solo
if (!exists("config_tp")) {
  source("02_Rscripts/00_setup.R", encoding = "UTF-8")
}

ruta_cr2met_tp    <- config_tp$ruta_cr2met
poligono_clima_tp <- config_tp$poligono_clima
pet_referencia_tp <- config_tp$pet_referencia
codigo_tp         <- config_tp$codigo_camels

if (is.null(ruta_cr2met_tp) || is.null(poligono_clima_tp)) {
  stop(
    "Faltan ruta_cr2met o poligono_clima en 06_config/parametros.csv.",
    call. = FALSE
  )
}

if (!requireNamespace("terra", quietly = TRUE)) {
  stop("Falta instalar el paquete terra.", call. = FALSE)
}
library(terra)

# El poligono se usa en los dos casos: para promediar las grillas y para
# sacar la latitud de la PET.
poligono_tp <- vect(poligono_clima_tp)

# 2. Revisar si estan las grillas de CR2MET v2.5
carpeta_pr_tp  <- file.path(ruta_cr2met_tp, "pr")
carpeta_txn_tp <- file.path(ruta_cr2met_tp, "txn")

archivos_pr_tp  <- list.files(carpeta_pr_tp,  pattern = "[.]nc$", full.names = TRUE)
archivos_txn_tp <- list.files(carpeta_txn_tp, pattern = "[.]nc$", full.names = TRUE)

series_previas_tp <- list.files(
  "01_data/processed",
  pattern = paste0("^clima_CR2METv25_", codigo_tp, "_daily_.*[.]csv$"),
  full.names = TRUE
)

hay_grillas_tp <- length(archivos_pr_tp) > 0 && length(archivos_txn_tp) > 0

if (!hay_grillas_tp) {
  if (length(series_previas_tp) == 0) {
    stop(
      "No estan las grillas de CR2MET v2.5 en ", ruta_cr2met_tp,
      " ni la serie procesada. Descargarlas segun 04_metadata/data_sources.csv.",
      call. = FALSE
    )
  }

  message(
    "04: no estan las grillas de CR2MET v2.5 en ", ruta_cr2met_tp,
    ". Se parte desde la serie ya procesada: ", series_previas_tp[1]
  )

  # Solo se leen P y temperaturas: la PET se vuelve a calcular abajo.
  clima_tp <- read.csv(series_previas_tp[1])
  clima_tp <- clima_tp[, c("fecha", "P_mm", "Tmax_degC", "Tmin_degC", "Tmed_degC")]
  clima_tp$fecha <- as.Date(clima_tp$fecha)

} else {

  # 3. Llevar el poligono al CRS de la grilla, por si llega en UTM
  poligono_grilla_tp <- project(poligono_tp, crs(rast(archivos_pr_tp[1])))

  # 4. Promediar sobre la cuenca un archivo mensual
  # Cada archivo trae 63 capas. Se eligen por nombre las del dato buscado
  # (pr_1..31, tmax_1..31 o tmin_1..31): pr_sd y cl_mask no son dato.
  # exact = TRUE pondera cada celda por la fraccion que cae dentro de la cuenca.
  promedio_cuenca_tp <- function(archivo, variable) {
    r <- rast(archivo)
    capas <- r[[grep(paste0("^", variable, "_[0-9]+$"), names(r))]]
    capas <- crop(capas, poligono_grilla_tp, snap = "out")
    v <- extract(capas, poligono_grilla_tp, fun = mean, na.rm = TRUE,
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

  stopifnot(
    all(P_tp$fecha == Tmax_tp$fecha),  # mismas fechas en P y T
    all(P_tp$fecha == Tmin_tp$fecha)
  )

  # 5. Armar la tabla diaria
  # CR2MET v2.5 no trae Tmed: se calcula como (Tmax + Tmin) / 2.
  clima_tp <- data.frame(
    fecha     = P_tp$fecha,
    P_mm      = P_tp$valor,
    Tmax_degC = Tmax_tp$valor,
    Tmin_degC = Tmin_tp$valor
  )
  clima_tp$Tmed_degC <- (clima_tp$Tmax_degC + clima_tp$Tmin_degC) / 2

  # Se redondea aqui, igual que la serie versionada, para que la PET salga
  # identica con o sin grillas.
  clima_tp[, -1] <- round(clima_tp[, -1], 3)
}

# 6. PET de Hargreaves-Samani
# Metodo de la clase de evapotranspiracion (C11, IIO352/IIO422), que lo
# recomienda cuando los unicos datos disponibles son de temperatura.

# 6.1 Latitud de la cuenca
# Se usa la latitud del centroide del poligono, en grados geograficos.
# Supuesto: un solo valor de Ra para toda la cuenca.
poligono_geo_tp <- project(poligono_tp, "EPSG:4326")
latitud_tp      <- crds(centroids(poligono_geo_tp))[1, "y"]
phi_tp          <- latitud_tp * pi / 180   # rad; latitud sur negativa

# 6.2 Radiacion extraterrestre, Ra [MJ m-2 d-1]
# [lamina 25/54] Ecuacion 7 (Allen et al., 1998)
J_tp     <- as.integer(format(clima_tp$fecha, "%j"))       # dia juliano
S0_tp    <- 0.0820                                         # MJ m-2 min-1
dr_tp    <- 1 + 0.033 * cos(2 * pi * J_tp / 365)
delta_tp <- 0.409 * sin(2 * pi * J_tp / 365 - 1.39)
ws_tp    <- acos(-tan(phi_tp) * tan(delta_tp))

Ra_MJ_tp <- (24 * 60 / pi) * S0_tp * dr_tp *
  (ws_tp * sin(phi_tp) * sin(delta_tp) +
     cos(phi_tp) * cos(delta_tp) * sin(ws_tp))

# +) La ecuacion 6 pide Ra en mm/d. Se convierte con el factor 0.408,
#    equivalente de evaporacion de 1 MJ m-2 d-1 (Allen et al., 1998, ec. 20).
Ra_mm_tp <- 0.408 * Ra_MJ_tp

# 6.3 ETP [mm d-1]
# [lamina 24/54] Ecuacion 6 (Hargreaves y Samani, 1985)
# Supuesto: se aplica sobre las temperaturas ya promediadas en la cuenca.
clima_tp$PET_mm <- 0.0023 * Ra_mm_tp * (clima_tp$Tmed_degC + 17.78) *
  sqrt(clima_tp$Tmax_degC - clima_tp$Tmin_degC)

message(
  "04: PET Hargreaves-Samani con latitud ", round(latitud_tp, 3),
  " (centroide del poligono)"
)

# 7. Control de calidad
dir.create("03_outputs/tables",  recursive = TRUE, showWarnings = FALSE)
dir.create("03_outputs/figures", recursive = TRUE, showWarnings = FALSE)

# 7.1 Revisiones dia a dia
# Cada fila cuenta los dias que no cumplen. Lo estructural (fechas) detiene
# el script; lo fisico queda en la tabla para revisarlo y explicarlo.
dias_tp <- nrow(clima_tp)

revision_tp <- data.frame(
  revision = c(
    "Fechas duplicadas",
    "Dias que faltan entre la primera y la ultima fecha",
    "P sin dato",
    "Tmax sin dato",
    "Tmin sin dato",
    "PET sin dato",
    "P negativa",
    "Tmin mayor que Tmax",
    "Tmed fuera de [Tmin, Tmax]",
    "Tmax fuera de [-30, 45] degC",
    "Tmin fuera de [-30, 45] degC",
    "PET negativa"
  ),
  dias_con_problema = c(
    sum(duplicated(clima_tp$fecha)),
    as.integer(diff(range(clima_tp$fecha))) + 1 - length(unique(clima_tp$fecha)),
    sum(is.na(clima_tp$P_mm)),
    sum(is.na(clima_tp$Tmax_degC)),
    sum(is.na(clima_tp$Tmin_degC)),
    sum(is.na(clima_tp$PET_mm)),
    sum(clima_tp$P_mm < 0, na.rm = TRUE),
    sum(clima_tp$Tmin_degC > clima_tp$Tmax_degC, na.rm = TRUE),
    sum(clima_tp$Tmed_degC < clima_tp$Tmin_degC |
          clima_tp$Tmed_degC > clima_tp$Tmax_degC, na.rm = TRUE),
    sum(clima_tp$Tmax_degC < -30 | clima_tp$Tmax_degC > 45, na.rm = TRUE),
    sum(clima_tp$Tmin_degC < -30 | clima_tp$Tmin_degC > 45, na.rm = TRUE),
    sum(clima_tp$PET_mm < 0, na.rm = TRUE)
  )
)
revision_tp$dias_revisados <- dias_tp
revision_tp$resultado <- ifelse(revision_tp$dias_con_problema == 0,
                                "cumple", "revisar")

write.csv(revision_tp, "03_outputs/tables/04_control_calidad_clima.csv",
          row.names = FALSE)

stopifnot(
  revision_tp$dias_con_problema[1] == 0,   # sin duplicados
  revision_tp$dias_con_problema[2] == 0    # sin dias faltantes
)

# 7.2 Cobertura por anio y variable
# Porcentaje de dias con dato sobre los dias del anio calendario.
anio_tp <- as.integer(format(clima_tp$fecha, "%Y"))
dias_anio_tp <- function(a) ifelse((a %% 4 == 0 & a %% 100 != 0) | a %% 400 == 0, 366, 365)

cobertura_tp <- data.frame(anio = sort(unique(anio_tp)))
cobertura_tp$dias_del_anio <- dias_anio_tp(cobertura_tp$anio)
for (v in c("P_mm", "Tmax_degC", "Tmin_degC", "PET_mm")) {
  con_dato <- tapply(!is.na(clima_tp[[v]]), anio_tp, sum)
  cobertura_tp[[paste0("cobertura_", v, "_pct")]] <-
    round(100 * as.numeric(con_dato) / cobertura_tp$dias_del_anio, 1)
}

write.csv(cobertura_tp, "03_outputs/tables/04_cobertura_clima_anual.csv",
          row.names = FALSE)

# 7.3 Comparacion con la PET de CAMELS-CL (si esta en el repositorio)
# CAMELS-CL tambien calcula su PET con Hargreaves, pero desde una version
# anterior de CR2MET. Sirve para ver si el orden de magnitud y el ciclo
# anual son coherentes, no para decidir cual esta bien.
if (!is.null(pet_referencia_tp) && file.exists(pet_referencia_tp)) {

  camels_tp <- read.csv(pet_referencia_tp, check.names = FALSE)
  camels_tp <- data.frame(
    fecha      = as.Date(camels_tp$date),
    PET_camels = camels_tp[[codigo_tp]]
  )

  comun_tp <- merge(clima_tp[, c("fecha", "PET_mm")], camels_tp, by = "fecha")
  comun_tp <- comun_tp[complete.cases(comun_tp), ]

  # Promedio mensual multianual en el periodo que comparten
  mes_tp <- as.integer(format(comun_tp$fecha, "%m"))
  mensual_tp <- data.frame(
    mes                      = 1:12,
    PET_CR2METv25_mm_dia     = round(as.numeric(tapply(comun_tp$PET_mm,     mes_tp, mean)), 3),
    PET_CAMELS_mm_dia        = round(as.numeric(tapply(comun_tp$PET_camels, mes_tp, mean)), 3)
  )
  mensual_tp$diferencia_pct <- round(
    100 * (mensual_tp$PET_CR2METv25_mm_dia - mensual_tp$PET_CAMELS_mm_dia) /
      mensual_tp$PET_CAMELS_mm_dia, 1
  )

  periodo_tp <- format(range(comun_tp$fecha))
  resumen_tp <- data.frame(
    indicador = c(
      "Periodo comparado (inicio)",
      "Periodo comparado (fin)",
      "Dias comparados",
      "PET media anual CR2MET v2.5 (mm/anio)",
      "PET media anual CAMELS-CL (mm/anio)",
      "Diferencia (%)",
      "Correlacion diaria (Pearson)"
    ),
    valor = c(
      periodo_tp[1],
      periodo_tp[2],
      nrow(comun_tp),
      round(365.25 * mean(comun_tp$PET_mm), 1),
      round(365.25 * mean(comun_tp$PET_camels), 1),
      round(100 * (mean(comun_tp$PET_mm) - mean(comun_tp$PET_camels)) /
              mean(comun_tp$PET_camels), 1),
      round(cor(comun_tp$PET_mm, comun_tp$PET_camels), 3)
    )
  )

  write.csv(mensual_tp, "03_outputs/tables/04_PET_mensual_vs_CAMELS.csv",
            row.names = FALSE)
  write.csv(resumen_tp, "03_outputs/tables/04_PET_resumen_vs_CAMELS.csv",
            row.names = FALSE)

  png("03_outputs/figures/04_PET_mensual_vs_CAMELS.png",
      width = 1600, height = 1000, res = 200)
  plot(mensual_tp$mes, mensual_tp$PET_CR2METv25_mm_dia, type = "b", pch = 19,
       ylim = c(0, max(mensual_tp[, 2:3]) * 1.1), xaxt = "n",
       xlab = "Mes", ylab = "PET media (mm/dia)",
       main = paste0("PET Hargreaves-Samani, cuenca ", codigo_tp,
                     " (", substr(periodo_tp[1], 1, 4), "-",
                     substr(periodo_tp[2], 1, 4), ")"))
  lines(mensual_tp$mes, mensual_tp$PET_CAMELS_mm_dia, type = "b", pch = 1, lty = 2)
  axis(1, at = 1:12, labels = c("Ene", "Feb", "Mar", "Abr", "May", "Jun",
                                "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"))
  legend("top", bty = "n",
         legend = c("Calculada con CR2MET v2.5", "CAMELS-CL (pet_hargreaves)"),
         pch = c(19, 1), lty = c(1, 2))
  dev.off()

  message("04: PET comparada con CAMELS-CL entre ", periodo_tp[1],
          " y ", periodo_tp[2])
} else {
  message("04: no esta la PET de CAMELS-CL (pet_referencia); se omite la comparacion")
}

# 8. Escribir la serie
anios_tp <- format(range(clima_tp$fecha), "%Y")
archivo_salida_tp <- file.path(
  "01_data/processed",
  paste0("clima_CR2METv25_", codigo_tp, "_daily_",
         anios_tp[1], "-", anios_tp[2], ".csv")
)
clima_tp[, -1] <- round(clima_tp[, -1], 3)
write.csv(clima_tp, archivo_salida_tp, row.names = FALSE)

message(
  "04: escrito ", archivo_salida_tp, " (", nrow(clima_tp), " dias; ",
  sum(revision_tp$resultado == "revisar"), " revisiones por mirar en ",
  "03_outputs/tables/04_control_calidad_clima.csv)"
)
