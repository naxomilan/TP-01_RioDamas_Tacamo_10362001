# 05_regimen_hidroclimatico.R
# Series mensuales y anuales del clima de la cuenca, su climatologia, el
# climograma, la comparacion con el caudal, la prueba de Pettitt sobre las
# series anuales del clima y el indice de aridez.
# Ejecutar desde la carpeta principal del repositorio (lo llama run_all.R),
# despues de 04_preparacion_clima.R.
#
# Entrada: 01_data/processed/clima_CR2METv25_<codigo>_daily_<inicio>-<fin>.csv
#          (sale del script 04). Periodo de la climatologia: parametros
#          periodo_inicio y periodo_fin de 06_config/parametros.csv.
#          Caudal diario (parametro serie_caudal, opcional) y el poligono
#          de la cuenca (poligono_clima) para pasar el caudal a lamina.
# Salida:  01_data/processed/clima_CR2METv25_<codigo>_monthly_<inicio>-<fin>.csv
#          01_data/processed/clima_CR2METv25_<codigo>_annual_<inicio>-<fin>.csv
#          03_outputs/tables/05_climatologia_mensual.csv
#          03_outputs/figures/05_climograma.png
#          03_outputs/tables/05_regimen_mensual_P_PET_Q.csv   (si hay caudal)
#          03_outputs/tables/05_clima_caudal_anual.csv        (si hay caudal)
#          03_outputs/figures/05_regimen_P_PET_Q.png          (si hay caudal)
#          03_outputs/figures/05_cobertura_caudal.png         (si hay caudal)
#          03_outputs/figures/05_evolucion_anual.png
#          03_outputs/tables/05_pettitt_clima_anual.csv
#          03_outputs/tables/05_estacionariedad_clima_anual.csv
#          03_outputs/tables/05_indice_aridez.csv
#          03_outputs/figures/05_mapas_P_T_media_anual.png  (solo con las grillas)
#          03_outputs/tables/05_mapas_rango_en_cuenca.csv   (solo con las grillas)
#          03_outputs/tables/05_resumen_calidad_E02.csv
#          03_outputs/tables/05_resumen_regimen_E03.csv, 05_estadisticos_anuales_E04.csv,
#          05_anios_extremos_E04.csv, 05_relaciones_anuales_E04.csv y 05_relleno_por_anio_E04.csv
#          01_data/processed/koppen_1991_2020_<codigo>.tif (recorte, si esta el mapa)
#          03_outputs/tables/05_koppen_cuenca.csv y 03_outputs/figures/05_mapa_koppen.png
#
# Agregacion: P y PET se SUMAN (mm/mes, mm/anio); Tmax, Tmin y Tmed se
# PROMEDIAN (degC). Un mes o un anio solo se calcula si tiene todos sus dias:
# si falta uno, queda NA. La cobertura se guarda junto al resultado.

# 1. Cargar la configuracion, si el script se corre solo
if (!exists("config_tp")) {
  source("02_Rscripts/00_setup.R", encoding = "UTF-8")
}

codigo_tp <- config_tp$codigo_camels

# 2. Leer la serie diaria del script 04
serie_diaria_tp <- list.files(
  "01_data/processed",
  pattern = paste0("^clima_CR2METv25_", codigo_tp, "_daily_.*[.]csv$"),
  full.names = TRUE
)

if (length(serie_diaria_tp) == 0) {
  stop("No esta la serie diaria de clima. Correr antes 04_preparacion_clima.R.",
       call. = FALSE)
}

diario_tp <- read.csv(serie_diaria_tp[1])
diario_tp$fecha <- as.Date(diario_tp$fecha)

if (!"PET_mm" %in% names(diario_tp)) {
  stop("La serie diaria no trae PET_mm. Correr la version del 04 con PET.",
       call. = FALSE)
}

variables_suma_tp     <- c("P_mm", "PET_mm")
variables_promedio_tp <- c("Tmax_degC", "Tmin_degC", "Tmed_degC")

# 3. Agregar a una escala (mes o anio)
# 'grupo' es la etiqueta de cada dia (por ejemplo "1987-01" o "1987").
# Los dias esperados se cuentan del calendario, no de la tabla: asi un dia que
# falte como fila tambien baja la cobertura.
# Por defecto agrega las variables del clima; el caudal (seccion 6) usa la
# misma funcion con sus propias variables.
agregar_tp <- function(datos, grupo, dias_esperados,
                       suma = variables_suma_tp,
                       promedio = variables_promedio_tp) {
  salida <- data.frame(periodo = sort(unique(grupo)))
  salida$dias_esperados <- as.integer(dias_esperados[salida$periodo])

  for (v in c(suma, promedio)) {
    con_dato <- tapply(!is.na(datos[[v]]), grupo, sum)[salida$periodo]
    funcion  <- if (v %in% suma) sum else mean
    valor    <- tapply(datos[[v]], grupo, funcion, na.rm = TRUE)[salida$periodo]

    completo <- as.integer(con_dato) == salida$dias_esperados
    salida[[v]] <- round(ifelse(completo, as.numeric(valor), NA), 3)
    salida[[paste0("cobertura_", v, "_pct")]] <-
      round(100 * as.integer(con_dato) / salida$dias_esperados, 1)
  }
  salida
}

# Dias del calendario en cada mes y en cada anio del registro
calendario_tp <- seq(min(diario_tp$fecha), max(diario_tp$fecha), by = "day")
dias_mes_tp   <- table(format(calendario_tp, "%Y-%m"))
dias_anio_tp  <- table(format(calendario_tp, "%Y"))

# 3.1 Mensual
mensual_tp <- agregar_tp(diario_tp, format(diario_tp$fecha, "%Y-%m"), dias_mes_tp)
names(mensual_tp)[1] <- "mes"
names(mensual_tp) <- sub("_mm$", "_mm_mes", names(mensual_tp))

# 3.2 Anual (anio calendario, enero a diciembre)
anual_tp <- agregar_tp(diario_tp, format(diario_tp$fecha, "%Y"), dias_anio_tp)
names(anual_tp)[1] <- "anio"
names(anual_tp) <- sub("_mm$", "_mm_anio", names(anual_tp))

anios_tp <- format(range(diario_tp$fecha), "%Y")
sufijo_tp <- paste0(anios_tp[1], "-", anios_tp[2], ".csv")

write.csv(mensual_tp,
          file.path("01_data/processed",
                    paste0("clima_CR2METv25_", codigo_tp, "_monthly_", sufijo_tp)),
          row.names = FALSE)
write.csv(anual_tp,
          file.path("01_data/processed",
                    paste0("clima_CR2METv25_", codigo_tp, "_annual_", sufijo_tp)),
          row.names = FALSE)

# 4. Climatologia mensual del periodo de analisis
# Promedio, para cada mes del anio, de los valores mensuales del periodo.
# Si el periodo no esta en la configuracion, se usa todo el registro y se avisa.
inicio_tp <- suppressWarnings(as.integer(config_tp$periodo_inicio))
fin_tp    <- suppressWarnings(as.integer(config_tp$periodo_fin))

if (length(inicio_tp) == 0 || length(fin_tp) == 0 || is.na(inicio_tp) || is.na(fin_tp)) {
  inicio_tp <- as.integer(anios_tp[1])
  fin_tp    <- as.integer(anios_tp[2])
  message("05: no estan periodo_inicio y periodo_fin en la configuracion; ",
          "se usa todo el registro (", inicio_tp, "-", fin_tp, ")")
}

anio_mes_tp <- as.integer(substr(mensual_tp$mes, 1, 4))
en_periodo_tp <- mensual_tp[anio_mes_tp >= inicio_tp & anio_mes_tp <= fin_tp, ]
numero_mes_tp <- as.integer(substr(en_periodo_tp$mes, 6, 7))

climatologia_tp <- data.frame(mes = 1:12)
for (v in c("P_mm_mes", "PET_mm_mes", variables_promedio_tp)) {
  climatologia_tp[[v]] <- round(as.numeric(tapply(en_periodo_tp[[v]], numero_mes_tp, mean)), 2)
}
climatologia_tp$meses_promediados <- as.integer(table(numero_mes_tp))

write.csv(climatologia_tp, "03_outputs/tables/05_climatologia_mensual.csv",
          row.names = FALSE)

# 5. Climograma
# Barras: P media mensual (mm/mes, eje izquierdo).
# Lineas: Tmax, Tmed y Tmin medias (degC, eje derecho).
nombres_mes_tp <- c("Ene", "Feb", "Mar", "Abr", "May", "Jun",
                    "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")
temperaturas_tp <- climatologia_tp[, variables_promedio_tp]
rango_t_tp <- c(min(0, floor(min(temperaturas_tp))), ceiling(max(temperaturas_tp)) + 2)

png("03_outputs/figures/05_climograma.png", width = 1800, height = 1100, res = 200)
par(mar = c(5.5, 4.5, 4, 4.5))

centros_tp <- barplot(climatologia_tp$P_mm_mes, names.arg = nombres_mes_tp,
                      col = "lightsteelblue", border = "steelblue4",
                      ylim = c(0, max(climatologia_tp$P_mm_mes) * 1.15),
                      ylab = "P media (mm/mes)", xlab = "Mes",
                      main = paste0("Climograma, cuenca ", config_tp$nombre_cuenca,
                                    " (", codigo_tp, "), ", inicio_tp, "-", fin_tp))

# El eje derecho se dibuja en otra escala sobre el mismo grafico.
par(new = TRUE)
plot(centros_tp, temperaturas_tp$Tmax_degC, type = "b", pch = 17, col = "firebrick",
     xlim = par("usr")[1:2], xaxs = "i", ylim = rango_t_tp,
     axes = FALSE, xlab = "", ylab = "")
lines(centros_tp, temperaturas_tp$Tmed_degC, type = "b", pch = 19, col = "black")
lines(centros_tp, temperaturas_tp$Tmin_degC, type = "b", pch = 25, col = "royalblue",
      bg = "royalblue")
axis(4)
mtext("Temperatura media mensual (°C)", side = 4, line = 3)

legend("top", horiz = TRUE, bty = "n", cex = 0.85,
       legend = c("P", "Tmax", "Tmed", "Tmin"),
       fill = c("lightsteelblue", NA, NA, NA),
       border = c("steelblue4", NA, NA, NA),
       pch = c(NA, 17, 19, 25), lty = c(NA, 1, 1, 1),
       col = c(NA, "firebrick", "black", "royalblue"),
       pt.bg = c(NA, NA, NA, "royalblue"))
mtext("Fuente: CR2MET v2.5 (Boisier, 2023), promedio ponderado sobre la cuenca",
      side = 1, line = 4.5, adj = 1, cex = 0.7)
dev.off()

message(
  "05: series mensual (", nrow(mensual_tp), " meses) y anual (", nrow(anual_tp),
  " anios) escritas; climograma ", inicio_tp, "-", fin_tp,
  " en 03_outputs/figures/05_climograma.png"
)

# 6. Clima y caudal
# El caudal llega en m3/s y se pasa a lamina (mm) con el area del MISMO
# poligono que se uso para promediar el clima: asi P, PET y Q quedan sobre
# la misma superficie. Q (mm) se suma y Q (m3/s) se promedia, con la misma
# regla de meses y anios completos que el clima.
serie_caudal_tp <- config_tp$serie_caudal
anios_clima_tp  <- as.integer(anual_tp$anio)

if (is.null(serie_caudal_tp) || !file.exists(serie_caudal_tp)) {
  message("05: no esta la serie de caudal (serie_caudal en la configuracion); ",
          "se omite la comparacion con el caudal")
  caudal_anual_tp <- NULL
} else {

  # 6.1 Leer el caudal y llevarlo a lamina
  # Las columnas de fecha y caudal se leen de la configuracion; si no estan,
  # se usan la primera y la segunda columna del archivo.
  # Si la serie viene rellenada, caudal_col_valor es la columna completa (la
  # que se usa para el regimen y los totales) y caudal_col_observado la
  # original con NA, que es la que sirve para contar los faltantes.
  # caudal_col_metodo, si esta, dice con que metodo se relleno cada dia.
  caudal_crudo_tp <- read.csv(serie_caudal_tp)
  col_fecha_tp <- if (is.null(config_tp$caudal_col_fecha)) names(caudal_crudo_tp)[1] else config_tp$caudal_col_fecha
  col_valor_tp <- if (is.null(config_tp$caudal_col_valor)) names(caudal_crudo_tp)[2] else config_tp$caudal_col_valor
  col_obs_tp    <- config_tp$caudal_col_observado
  col_metodo_tp <- config_tp$caudal_col_metodo

  caudal_tp <- data.frame(
    fecha = as.Date(caudal_crudo_tp[[col_fecha_tp]]),
    Q_m3s = as.numeric(caudal_crudo_tp[[col_valor_tp]])
  )
  caudal_tp$Q_obs_m3s <- if (is.null(col_obs_tp)) caudal_tp$Q_m3s else
    as.numeric(caudal_crudo_tp[[col_obs_tp]])
  caudal_tp$metodo <- if (is.null(col_metodo_tp)) NA_character_ else
    as.character(caudal_crudo_tp[[col_metodo_tp]])
  stopifnot(!anyDuplicated(caudal_tp$fecha))

  # Se completa el calendario desde el 1 de enero del primer anio hasta el 31
  # de diciembre del ultimo: un dia que no viene como fila queda NA. Asi un
  # registro que parte a mitad de anio no deja ese anio como completo.
  calendario_q_tp <- data.frame(fecha = seq(
    as.Date(paste0(format(min(caudal_tp$fecha), "%Y"), "-01-01")),
    as.Date(paste0(format(max(caudal_tp$fecha), "%Y"), "-12-31")),
    by = "day"
  ))
  caudal_tp <- merge(calendario_q_tp, caudal_tp, by = "fecha", all.x = TRUE)

  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Falta instalar el paquete terra.", call. = FALSE)
  }
  area_km2_tp <- sum(terra::expanse(terra::vect(config_tp$poligono_clima), unit = "km"))

  # Q [mm/d] = Q [m3/s] * 86400 s/d / (A [km2] * 1e6 m2/km2) * 1000 mm/m
  caudal_tp$Q_mm <- caudal_tp$Q_m3s * 86.4 / area_km2_tp

  # 6.2 Agregar a mes y anio
  dias_mes_q_tp  <- table(format(caudal_tp$fecha, "%Y-%m"))
  dias_anio_q_tp <- table(format(caudal_tp$fecha, "%Y"))

  caudal_mensual_tp <- agregar_tp(caudal_tp, format(caudal_tp$fecha, "%Y-%m"), dias_mes_q_tp,
                                  suma = "Q_mm", promedio = "Q_m3s")
  caudal_anual_tp   <- agregar_tp(caudal_tp, format(caudal_tp$fecha, "%Y"), dias_anio_q_tp,
                                  suma = "Q_mm", promedio = "Q_m3s")
  names(caudal_anual_tp)[names(caudal_anual_tp) == "periodo"] <- "anio"

  # 6.3 Regimen mensual en el periodo de analisis
  # Solo meses completos de Q dentro del periodo y dentro del registro del clima.
  anio_q_tp <- as.integer(substr(caudal_mensual_tp$periodo, 1, 4))
  q_periodo_tp <- caudal_mensual_tp[anio_q_tp >= inicio_tp & anio_q_tp <= fin_tp &
                                      anio_q_tp %in% anios_clima_tp &
                                      !is.na(caudal_mensual_tp$Q_mm), ]
  mes_q_tp <- factor(as.integer(substr(q_periodo_tp$periodo, 6, 7)), levels = 1:12)

  regimen_tp <- data.frame(
    mes          = 1:12,
    P_mm_mes     = climatologia_tp$P_mm_mes,
    PET_mm_mes   = climatologia_tp$PET_mm_mes,
    Q_mm_mes     = round(as.numeric(tapply(q_periodo_tp$Q_mm, mes_q_tp, mean)), 2),
    Q_m3s        = round(as.numeric(tapply(q_periodo_tp$Q_m3s, mes_q_tp, mean)), 3),
    meses_Q_completos = as.integer(table(mes_q_tp))
  )
  regimen_tp$Q_sobre_P <- round(regimen_tp$Q_mm_mes / regimen_tp$P_mm_mes, 2)

  write.csv(regimen_tp, "03_outputs/tables/05_regimen_mensual_P_PET_Q.csv",
            row.names = FALSE)

  png("03_outputs/figures/05_regimen_P_PET_Q.png", width = 1800, height = 1100, res = 200)
  par(mar = c(5.5, 4.5, 4, 2))
  centros_q_tp <- barplot(regimen_tp$P_mm_mes, names.arg = nombres_mes_tp,
                          col = "lightsteelblue", border = "steelblue4",
                          ylim = c(0, max(regimen_tp[, c("P_mm_mes", "PET_mm_mes", "Q_mm_mes")],
                                          na.rm = TRUE) * 1.15),
                          ylab = "Lámina media (mm/mes)", xlab = "Mes",
                          main = paste0("Regimen mensual de P, PET y Q, cuenca ", codigo_tp,
                                        " (", inicio_tp, "-", fin_tp, ")"))
  lines(centros_q_tp, regimen_tp$PET_mm_mes, type = "b", pch = 17, col = "darkorange3")
  lines(centros_q_tp, regimen_tp$Q_mm_mes, type = "b", pch = 19, col = "navy", lwd = 2)
  legend("topright", bty = "n", cex = 0.85,
         legend = c("P (CR2MET v2.5)", "PET (Hargreaves-Samani)", "Q (serie usada)"),
         fill = c("lightsteelblue", NA, NA), border = c("steelblue4", NA, NA),
         pch = c(NA, 17, 19), lty = c(NA, 1, 1), lwd = c(NA, 1, 2),
         col = c(NA, "darkorange3", "navy"))
  mtext(paste0("Q en lamina con el area del poligono de la cuenca: ",
               round(area_km2_tp, 2), " km2"),
        side = 1, line = 4.5, adj = 1, cex = 0.7)
  dev.off()

  message("05: regimen P-PET-Q escrito; area usada para Q: ", round(area_km2_tp, 2), " km2")

  # 6.4 Figura de faltantes del caudal OBSERVADO (antes de cualquier relleno)
  # Izquierda: cobertura de cada anio (gris = anio incompleto).
  # Derecha: dias sin dato por mes del anio, dentro del periodo de analisis.
  anio_dia_q_tp  <- format(caudal_tp$fecha, "%Y")
  # El calendario ya esta completo (6.1), asi que la media de !is.na es la cobertura.
  cobertura_q_tp <- round(100 * tapply(!is.na(caudal_tp$Q_obs_m3s), anio_dia_q_tp, mean), 1)
  en_periodo_q_tp <- anio_dia_q_tp %in% as.character(inicio_tp:fin_tp)
  faltan_mes_tp <- tapply(is.na(caudal_tp$Q_obs_m3s[en_periodo_q_tp]),
                          factor(as.integer(format(caudal_tp$fecha[en_periodo_q_tp], "%m")), levels = 1:12),
                          sum)

  png("03_outputs/figures/05_cobertura_caudal.png", width = 2000, height = 900, res = 200)
  par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3.5, 1))
  barplot(as.numeric(cobertura_q_tp), names.arg = names(cobertura_q_tp), las = 2, cex.names = 0.6,
          col = ifelse(cobertura_q_tp == 100, "steelblue4", "grey70"), border = NA,
          ylim = c(0, 105), ylab = "Dias con dato (%)",
          main = "Cobertura anual del caudal observado")
  abline(h = 100, lty = 3)
  barplot(as.numeric(faltan_mes_tp), names.arg = nombres_mes_tp, las = 2,
          col = "grey40", border = NA, ylab = "Dias sin dato",
          main = paste0("Dias sin caudal por mes, ", inicio_tp, "-", fin_tp))
  dev.off()
}

# 6.5 Tabla y figura anual (clima siempre; caudal si esta)
evolucion_tp <- anual_tp[, c("anio", "P_mm_anio", "PET_mm_anio", "Tmed_degC")]
if (!is.null(caudal_anual_tp)) {
  evolucion_tp <- merge(evolucion_tp,
                        caudal_anual_tp[, c("anio", "Q_mm", "Q_m3s", "cobertura_Q_mm_pct")],
                        by = "anio", all.x = TRUE)
  names(evolucion_tp)[names(evolucion_tp) == "Q_mm"]  <- "Q_mm_anio"
  names(evolucion_tp)[names(evolucion_tp) == "Q_m3s"] <- "Q_m3s_medio"
  evolucion_tp$Q_sobre_P <- round(evolucion_tp$Q_mm_anio / evolucion_tp$P_mm_anio, 3)
  write.csv(evolucion_tp, "03_outputs/tables/05_clima_caudal_anual.csv", row.names = FALSE)
}

anio_ev_tp <- as.integer(evolucion_tp$anio)
# Arriba: P, PET y Q en lamina. Abajo: Tmax, Tmed y Tmin anuales.
png("03_outputs/figures/05_evolucion_anual.png", width = 1800, height = 1600, res = 200)
par(mfrow = c(2, 1), mar = c(4, 4.5, 3, 2))
plot(anio_ev_tp, evolucion_tp$P_mm_anio, type = "b", pch = 19, cex = 0.6,
     col = "steelblue4", ylim = c(0, max(evolucion_tp$P_mm_anio) * 1.1),
     xlab = "Año", ylab = "Lámina anual (mm/año)",
     main = paste0("Evolución anual, cuenca ", codigo_tp))
lines(anio_ev_tp, evolucion_tp$PET_mm_anio, type = "b", pch = 17, cex = 0.6, col = "darkorange3")
if (!is.null(caudal_anual_tp)) {
  lines(anio_ev_tp, evolucion_tp$Q_mm_anio, type = "b", pch = 15, cex = 0.6, col = "navy")
}
abline(v = c(inicio_tp, fin_tp), lty = 3, col = "grey40")
legend("bottomleft", bty = "n", cex = 0.8, horiz = TRUE,
       legend = c("P", "PET", if (!is.null(caudal_anual_tp)) "Q (años completos)"),
       pch = c(19, 17, if (!is.null(caudal_anual_tp)) 15),
       col = c("steelblue4", "darkorange3", if (!is.null(caudal_anual_tp)) "navy"))
anio_t_tp <- as.integer(anual_tp$anio)
plot(anio_t_tp, anual_tp$Tmax_degC, type = "b", pch = 17, cex = 0.6, col = "firebrick",
     ylim = range(c(anual_tp$Tmin_degC, anual_tp$Tmax_degC)) + c(-1, 1),
     xlab = "Año", ylab = "Temperatura media anual (°C)")
lines(anio_t_tp, anual_tp$Tmed_degC, type = "b", pch = 19, cex = 0.6, col = "black")
lines(anio_t_tp, anual_tp$Tmin_degC, type = "b", pch = 25, cex = 0.6, col = "royalblue",
      bg = "royalblue")
abline(v = c(inicio_tp, fin_tp), lty = 3, col = "grey40")
legend("bottomleft", bty = "n", cex = 0.8, horiz = TRUE,
       legend = c("Tmax", "Tmed", "Tmin"), pch = c(17, 19, 25),
       col = c("firebrick", "black", "royalblue"), pt.bg = c(NA, NA, "royalblue"))
dev.off()

# 7. Homogeneidad y estacionariedad de las series anuales del clima
# 7.1 Prueba de Pettitt
# [CP05, paso 3] Funciones copiadas sin cambios.
# 3. Pettitt's K, split after year t, and exchangeability-based null simulation.
pettitt_stat <- function(x) {
  if (!is.numeric(x) || length(x) < 4L || anyNA(x) ||
      any(!is.finite(x))) stop("x must have at least four finite values")
  n <- length(x)
  u <- vapply(seq_len(n - 1L), function(t)
    sum(sign(outer(x[seq_len(t)], x[(t + 1L):n], `-`))), numeric(1))
  list(K = max(abs(u)), split_after = which.max(abs(u)), U = u)
}
pettitt_permutation <- function(x, B = 999L) {
  if (length(B) != 1L || is.na(B) || B < 99L || B != as.integer(B))
    stop("B must be an integer of at least 99")
  observed <- pettitt_stat(x)
  null_K <- replicate(B, pettitt_stat(sample(x))$K)
  c(split_after = observed$split_after, K = observed$K,
    p_monte_carlo = (1 + sum(null_K >= observed$K)) / (B + 1))
}

# +) Se aplica a P, PET y Tmed anuales (continuas, sin NA) en dos tramos:
#    el registro completo, para ver la historia larga, y el periodo de
#    analisis, que es el que usan el balance y Budyko. Budyko pide que P y T
#    anuales sean homogeneas y estacionarias en ese periodo (clase 19-oct).
#    El caudal no se prueba aqui: lo prueba el script de control de Q.
variables_prueba_tp <- c("P_mm_anio", "PET_mm_anio", "Tmed_degC")
tramos_tp <- list(
  registro = as.integer(anual_tp$anio),
  periodo  = inicio_tp:fin_tp
)

set.seed(20260924)
pettitt_tp <- do.call(rbind, lapply(names(tramos_tp), function(tramo) {
  datos_tramo <- anual_tp[as.integer(anual_tp$anio) %in% tramos_tp[[tramo]], ]
  do.call(rbind, lapply(variables_prueba_tp, function(v) {
    x <- datos_tramo[[v]]
    r <- pettitt_permutation(x)
    corte <- r[["split_after"]]
    data.frame(
      variable = v,
      tramo = tramo,
      periodo = paste0(datos_tramo$anio[1], "-", datos_tramo$anio[nrow(datos_tramo)]),
      n_anios = length(x),
      ultimo_anio_antes_del_quiebre = datos_tramo$anio[corte],
      K = r[["K"]],
      p_monte_carlo = r[["p_monte_carlo"]],
      # +) Aproximacion de Pettitt (1979): p ~ 2 exp(-6 K^2 / (n^3 + n^2)).
      #    Es una aproximacion asintotica, solo de referencia: la prueba del
      #    curso es la simulacion por permutaciones.
      #    Se acota a 1: con quiebres debiles la formula da valores mayores.
      p_aproximado = round(min(1, 2 * exp(-6 * r[["K"]]^2 / (length(x)^3 + length(x)^2))), 3),
      quiebre_significativo_5pct = r[["p_monte_carlo"]] < 0.05,
      media_antes = round(mean(x[seq_len(corte)]), 2),
      media_despues = round(mean(x[-seq_len(corte)]), 2)
    )
  }))
}))
write.csv(pettitt_tp, "03_outputs/tables/05_pettitt_clima_anual.csv", row.names = FALSE)

# 7.2 Estacionariedad en el periodo de analisis (ADF y KPSS)
# [CP05, paso 4] Las mismas llamadas de la clase practica:
#   ADF:  hipotesis nula = raiz unitaria (NO estacionaria). p < 0.05 la rechaza.
#   KPSS: hipotesis nula = estacionaria en nivel. p < 0.05 la rechaza.
# +) tseries acota el p del KPSS entre 0.01 y 0.1 y el del ADF entre 0.01 y
#    0.99 (avisa con un warning, que aqui se silencia): un p = 0.1 en KPSS
#    significa "0.1 o mas".
if (!requireNamespace("tseries", quietly = TRUE)) {
  message("05: falta el paquete tseries; se omiten ADF y KPSS")
} else {
  datos_periodo_tp <- anual_tp[as.integer(anual_tp$anio) %in% (inicio_tp:fin_tp), ]
  estacionariedad_tp <- do.call(rbind, lapply(variables_prueba_tp, function(v) {
    x <- datos_periodo_tp[[v]]
    adf  <- suppressWarnings(tseries::adf.test(x, k = 4))
    kpss <- suppressWarnings(tseries::kpss.test(x, null = "Level", lshort = TRUE))
    data.frame(
      variable = v,
      periodo = paste0(inicio_tp, "-", fin_tp),
      n_anios = length(x),
      adf_estadistico = round(unname(adf$statistic), 3),
      adf_p = round(adf$p.value, 3),
      kpss_estadistico = round(unname(kpss$statistic), 3),
      kpss_p = round(kpss$p.value, 3),
      estacionaria_segun_kpss = kpss$p.value >= 0.05,
      estacionaria_segun_adf = adf$p.value < 0.05
    )
  }))
  write.csv(estacionariedad_tp, "03_outputs/tables/05_estacionariedad_clima_anual.csv",
            row.names = FALSE)
}

# 8. Indice de aridez del periodo de analisis
# Se entregan los dos cocientes, porque son inversos y la definicion se acuerda
# con el bloque de Budyko:
#   PET/P: indice de sequedad de Budyko (mayor que 1 = limitado por agua).
#   P/PET: el cociente inverso (menor = mas arido).
en_periodo_anual_tp <- anual_tp[as.integer(anual_tp$anio) >= inicio_tp &
                                  as.integer(anual_tp$anio) <= fin_tp, ]
P_media_tp   <- mean(en_periodo_anual_tp$P_mm_anio)
PET_media_tp <- mean(en_periodo_anual_tp$PET_mm_anio)

aridez_tp <- data.frame(
  indicador = c("Periodo", "Anios", "P media anual (mm/anio)", "PET media anual (mm/anio)",
                "PET/P (indice de sequedad de Budyko)", "P/PET"),
  valor = c(paste0(inicio_tp, "-", fin_tp), nrow(en_periodo_anual_tp),
            round(P_media_tp, 1), round(PET_media_tp, 1),
            round(PET_media_tp / P_media_tp, 3), round(P_media_tp / PET_media_tp, 3))
)
write.csv(aridez_tp, "03_outputs/tables/05_indice_aridez.csv", row.names = FALSE)

message(
  "05: Pettitt y aridez escritos; PET/P = ", round(PET_media_tp / P_media_tp, 3),
  " en ", inicio_tp, "-", fin_tp
)

# 9. Mapas de P y T media anual del periodo
# Salen de las grillas de CR2MET v2.5, asi que solo se rehacen en el
# computador que las tiene. Si no estan, queda la figura versionada.
# P media anual = suma de la P diaria de cada celda en el periodo / anios.
# T media anual = promedio de (Tmax + Tmin) / 2 de todos los dias del periodo.
ruta_cr2met_tp <- config_tp$ruta_cr2met
archivos_pr_tp  <- list.files(file.path(ruta_cr2met_tp, "pr"),  pattern = "[.]nc$", full.names = TRUE)
archivos_txn_tp <- list.files(file.path(ruta_cr2met_tp, "txn"), pattern = "[.]nc$", full.names = TRUE)

anio_archivo_tp <- function(archivos) {
  as.integer(sub(".*_([0-9]{4})_[0-9]{2}_.*", "\\1", basename(archivos)))
}
archivos_pr_tp  <- archivos_pr_tp[anio_archivo_tp(archivos_pr_tp) %in% inicio_tp:fin_tp]
archivos_txn_tp <- archivos_txn_tp[anio_archivo_tp(archivos_txn_tp) %in% inicio_tp:fin_tp]

if (length(archivos_pr_tp) == 0 || length(archivos_txn_tp) == 0) {
  message("05: no estan las grillas de CR2MET v2.5; se omiten los mapas ",
          "(queda la figura ya versionada, si existe)")
} else {
  library(terra)
  cuenca_mapa_tp <- vect(config_tp$poligono_clima)
  cuenca_mapa_tp <- project(cuenca_mapa_tp, crs(rast(archivos_pr_tp[1])))
  # Se recorta con un margen de 0.1 grados para ver las celdas vecinas.
  extension_tp <- ext(cuenca_mapa_tp) + 0.1

  capas_tp <- function(archivo, patron) {
    r <- rast(archivo)
    crop(r[[grep(patron, names(r))]], extension_tp, snap = "out")
  }

  message("05: mapas, leyendo ", length(archivos_pr_tp), " archivos de P y ",
          length(archivos_txn_tp), " de T")
  suma_p_tp <- Reduce(`+`, lapply(archivos_pr_tp, function(a) sum(capas_tp(a, "^pr_[0-9]+$"))))
  P_mapa_tp <- suma_p_tp / length(inicio_tp:fin_tp)

  suma_t_tp <- 0
  dias_t_tp <- 0
  for (a in archivos_txn_tp) {
    tx <- capas_tp(a, "^tmax_[0-9]+$")
    tn <- capas_tp(a, "^tmin_[0-9]+$")
    suma_t_tp <- suma_t_tp + sum((tx + tn) / 2)
    dias_t_tp <- dias_t_tp + nlyr(tx)
  }
  T_mapa_tp <- suma_t_tp / dias_t_tp

  png("03_outputs/figures/05_mapas_P_T_media_anual.png", width = 2000, height = 950, res = 200)
  par(mfrow = c(1, 2), mar = c(3, 3, 3, 5))
  plot(P_mapa_tp, col = hcl.colors(20, "Blues 3", rev = TRUE),
       main = paste0("P media anual (mm/año), ", inicio_tp, "-", fin_tp))
  lines(cuenca_mapa_tp, lwd = 2)
  plot(T_mapa_tp, col = hcl.colors(20, "YlOrRd", rev = TRUE),
       main = paste0("Tmed anual (°C), ", inicio_tp, "-", fin_tp))
  lines(cuenca_mapa_tp, lwd = 2)
  mtext("CR2MET v2.5, grilla de 0.05 grados; linea negra: limite de la cuenca",
        side = 1, line = 1.8, adj = 1, cex = 0.7)
  dev.off()

  # Rango dentro de la cuenca (celdas que la tocan), para el texto del dossier
  rango_tp <- data.frame(
    variable = c("P media anual (mm/anio)", "T media anual (degC)"),
    minimo = c(min(values(mask(P_mapa_tp, cuenca_mapa_tp, touches = TRUE)), na.rm = TRUE),
               min(values(mask(T_mapa_tp, cuenca_mapa_tp, touches = TRUE)), na.rm = TRUE)),
    maximo = c(max(values(mask(P_mapa_tp, cuenca_mapa_tp, touches = TRUE)), na.rm = TRUE),
               max(values(mask(T_mapa_tp, cuenca_mapa_tp, touches = TRUE)), na.rm = TRUE)),
    periodo = paste0(inicio_tp, "-", fin_tp)
  )
  rango_tp$minimo <- round(rango_tp$minimo, 1)
  rango_tp$maximo <- round(rango_tp$maximo, 1)
  write.csv(rango_tp, "03_outputs/tables/05_mapas_rango_en_cuenca.csv", row.names = FALSE)

  message("05: mapas escritos en 03_outputs/figures/05_mapas_P_T_media_anual.png")
}

# 10. Resumen de calidad (cifras de la evidencia E02)
# Junta en una sola tabla los numeros que cita la ficha E02, para que cada
# uno salga de run_all.R y no de un calculo aparte.
resumen_tp <- data.frame(indicador = character(0), valor = character(0), periodo = character(0))
agregar_fila_tp <- function(indicador, valor, periodo) {
  resumen_tp <<- rbind(resumen_tp, data.frame(indicador = indicador,
                                              valor = as.character(valor),
                                              periodo = periodo))
}
periodo_txt_tp <- paste0(inicio_tp, "-", fin_tp)
registro_txt_tp <- paste0(anios_tp[1], "-", anios_tp[2])

# 10.1 Rangos diarios del clima (periodo y registro completo)
for (alcance in c("periodo", "registro")) {
  if (alcance == "periodo") {
    d <- diario_tp[format(diario_tp$fecha, "%Y") %in% as.character(inicio_tp:fin_tp), ]
    etiqueta <- periodo_txt_tp
  } else {
    d <- diario_tp
    etiqueta <- registro_txt_tp
  }
  agregar_fila_tp("P diaria maxima (mm/dia)", round(max(d$P_mm), 1), etiqueta)
  agregar_fila_tp("Fecha de la P diaria maxima", format(d$fecha[which.max(d$P_mm)]), etiqueta)
  agregar_fila_tp("Tmax diaria minima y maxima (degC)",
                  paste(round(range(d$Tmax_degC), 1), collapse = " a "), etiqueta)
  agregar_fila_tp("Tmin diaria minima y maxima (degC)",
                  paste(round(range(d$Tmin_degC), 1), collapse = " a "), etiqueta)
  agregar_fila_tp("PET diaria minima y maxima (mm/dia)",
                  paste(round(range(d$PET_mm), 2), collapse = " a "), etiqueta)
}

# 10.2 P de CR2MET v2.5 contra la P de CR2MET que trae CAMELS-CL
p_referencia_tp <- config_tp$p_referencia
if (!is.null(p_referencia_tp) && file.exists(p_referencia_tp)) {
  p_camels_tp <- read.csv(p_referencia_tp, check.names = FALSE)
  p_camels_tp <- data.frame(fecha = as.Date(p_camels_tp$date), P_camels = p_camels_tp[[codigo_tp]])
  p_comun_tp <- merge(diario_tp[, c("fecha", "P_mm")], p_camels_tp, by = "fecha")
  p_comun_tp <- p_comun_tp[complete.cases(p_comun_tp), ]
  etiqueta <- paste(format(range(p_comun_tp$fecha)), collapse = " a ")
  agregar_fila_tp("Dias comparados con CAMELS-CL", nrow(p_comun_tp), etiqueta)
  agregar_fila_tp("P media anual CR2MET v2.5 (mm/anio)", round(365.25 * mean(p_comun_tp$P_mm), 1), etiqueta)
  agregar_fila_tp("P media anual CAMELS-CL (mm/anio)", round(365.25 * mean(p_comun_tp$P_camels), 1), etiqueta)
  agregar_fila_tp("Diferencia de P (%)",
                  round(100 * (mean(p_comun_tp$P_mm) / mean(p_comun_tp$P_camels) - 1), 1), etiqueta)
  agregar_fila_tp("Correlacion diaria de P (Pearson)",
                  round(cor(p_comun_tp$P_mm, p_comun_tp$P_camels), 3), etiqueta)
} else {
  message("05: no esta la P de CAMELS-CL (p_referencia); se omite esa comparacion")
}

# 10.3 Caudal: registro, faltantes y anios utiles
P_anual_periodo_tp <- setNames(anual_tp$P_mm_anio, anual_tp$anio)[as.character(inicio_tp:fin_tp)]
agregar_fila_tp("P media anual, todos los anios (mm/anio)", round(mean(P_anual_periodo_tp), 1), periodo_txt_tp)

if (!is.null(caudal_anual_tp)) {
  q_en_periodo_tp <- caudal_tp[format(caudal_tp$fecha, "%Y") %in% as.character(inicio_tp:fin_tp), ]
  # Faltantes: siempre sobre el caudal observado
  falta_tp <- is.na(q_en_periodo_tp$Q_obs_m3s)
  mes_falta_tp <- as.integer(format(q_en_periodo_tp$fecha[falta_tp], "%m"))
  dias_faltan_anio_tp <- tapply(falta_tp, format(q_en_periodo_tp$fecha, "%Y"), sum)

  q_obs_tp <- q_en_periodo_tp[!is.na(q_en_periodo_tp$Q_obs_m3s), ]
  agregar_fila_tp("Dias en el periodo", nrow(q_en_periodo_tp), periodo_txt_tp)
  agregar_fila_tp("Dias sin caudal observado", sum(falta_tp), periodo_txt_tp)
  agregar_fila_tp("Cobertura del caudal observado (%)", round(100 * mean(!falta_tp), 2), periodo_txt_tp)
  agregar_fila_tp("Dias sin caudal observado en junio, julio y agosto", sum(mes_falta_tp %in% 6:8), periodo_txt_tp)
  agregar_fila_tp("Q observado diario minimo y maximo (m3/s)",
                  paste(range(q_obs_tp$Q_obs_m3s), collapse = " a "), periodo_txt_tp)
  agregar_fila_tp("Anios con Q observado completo", sum(dias_faltan_anio_tp == 0), periodo_txt_tp)

  # Serie que se usa (completada, si viene rellenada)
  dias_sin_q_usado_tp <- tapply(is.na(q_en_periodo_tp$Q_m3s), format(q_en_periodo_tp$fecha, "%Y"), sum)
  agregar_fila_tp("Anios con Q completo en la serie usada", sum(dias_sin_q_usado_tp == 0), periodo_txt_tp)
  agregar_fila_tp("Dias con Q usado <= 0", sum(q_en_periodo_tp$Q_m3s <= 0, na.rm = TRUE), periodo_txt_tp)
  if (any(q_en_periodo_tp$Q_m3s <= 0, na.rm = TRUE)) {
    agregar_fila_tp("Fechas con Q usado <= 0",
                    paste(format(range(q_en_periodo_tp$fecha[which(q_en_periodo_tp$Q_m3s <= 0)])), collapse = " a "),
                    periodo_txt_tp)
  }
  rellenados_tp <- q_en_periodo_tp[falta_tp & !is.na(q_en_periodo_tp$Q_m3s), ]
  if (nrow(rellenados_tp) > 0 && !all(is.na(rellenados_tp$metodo))) {
    for (m in sort(unique(rellenados_tp$metodo))) {
      agregar_fila_tp(paste0("Dias rellenados con ", m), sum(rellenados_tp$metodo == m), periodo_txt_tp)
    }
  }
}

write.csv(resumen_tp, "03_outputs/tables/05_resumen_calidad_E02.csv", row.names = FALSE)
message("05: resumen de calidad escrito en 03_outputs/tables/05_resumen_calidad_E02.csv")

# 11. Cifras del regimen (E03) y de la evolucion anual (E04)
# Tablas con los numeros que citan las fichas E03 y E04, para que cada uno
# salga de run_all.R.

# 11.1 Regimen mensual del periodo
regimen_e03_tp <- data.frame(indicador = character(0), valor = character(0))
fila_e03_tp <- function(indicador, valor) {
  regimen_e03_tp <<- rbind(regimen_e03_tp, data.frame(indicador = indicador, valor = as.character(valor)))
}
cl_tp <- climatologia_tp
fila_e03_tp("Periodo", periodo_txt_tp)
fila_e03_tp("Mes de P maxima", nombres_mes_tp[which.max(cl_tp$P_mm_mes)])
fila_e03_tp("Mes de P minima", nombres_mes_tp[which.min(cl_tp$P_mm_mes)])
fila_e03_tp("P de mayo a agosto (% del anio)", round(100 * sum(cl_tp$P_mm_mes[5:8]) / sum(cl_tp$P_mm_mes), 1))
fila_e03_tp("Meses con PET mayor que P", paste(nombres_mes_tp[cl_tp$PET_mm_mes > cl_tp$P_mm_mes], collapse = " "))
fila_e03_tp("Mes mas frio (Tmed, degC)", paste(nombres_mes_tp[which.min(cl_tp$Tmed_degC)], round(min(cl_tp$Tmed_degC), 2)))
fila_e03_tp("Mes mas calido (Tmed, degC)", paste(nombres_mes_tp[which.max(cl_tp$Tmed_degC)], round(max(cl_tp$Tmed_degC), 2)))
if (exists("regimen_tp") && !is.null(caudal_anual_tp)) {
  fila_e03_tp("Mes de Q maximo", nombres_mes_tp[which.max(regimen_tp$Q_mm_mes)])
  fila_e03_tp("Mes de Q minimo", nombres_mes_tp[which.min(regimen_tp$Q_mm_mes)])
  fila_e03_tp("Q de mayo a agosto (% del anio)", round(100 * sum(regimen_tp$Q_mm_mes[5:8]) / sum(regimen_tp$Q_mm_mes), 1))
  fila_e03_tp("Cociente Q maximo / Q minimo mensual", round(max(regimen_tp$Q_mm_mes) / min(regimen_tp$Q_mm_mes), 1))
  fila_e03_tp("Q/P mensual minimo y maximo", paste(range(regimen_tp$Q_sobre_P), collapse = " a "))
}
write.csv(regimen_e03_tp, "03_outputs/tables/05_resumen_regimen_E03.csv", row.names = FALSE)

# 11.2 Estadisticos anuales del periodo (solo anios con todas las variables)
anual_e04_tp <- merge(evolucion_tp, anual_tp[, c("anio", "Tmax_degC", "Tmin_degC")], by = "anio")
anual_e04_tp <- anual_e04_tp[as.integer(anual_e04_tp$anio) %in% (inicio_tp:fin_tp), ]
variables_e04_tp <- intersect(c("P_mm_anio", "PET_mm_anio", "Q_mm_anio", "Q_m3s_medio",
                                "Tmax_degC", "Tmed_degC", "Tmin_degC", "Q_sobre_P"),
                              names(anual_e04_tp))
estadisticos_tp <- do.call(rbind, lapply(variables_e04_tp, function(v) {
  x <- anual_e04_tp[[v]]
  ok <- !is.na(x)
  data.frame(
    variable = v, n_anios = sum(ok),
    media = round(mean(x[ok]), 2), desviacion = round(sd(x[ok]), 2),
    cv_pct = round(100 * sd(x[ok]) / mean(x[ok]), 1),
    minimo = round(min(x[ok]), 2), anio_minimo = anual_e04_tp$anio[ok][which.min(x[ok])],
    maximo = round(max(x[ok]), 2), anio_maximo = anual_e04_tp$anio[ok][which.max(x[ok])]
  )
}))
write.csv(estadisticos_tp, "03_outputs/tables/05_estadisticos_anuales_E04.csv", row.names = FALSE)

# 11.3 Anios mas secos y mas humedos segun P, y relaciones entre variables
orden_p_tp <- anual_e04_tp[order(anual_e04_tp$P_mm_anio), ]
extremos_tp <- rbind(head(orden_p_tp, 3), tail(orden_p_tp, 3))
extremos_tp$tipo <- rep(c("seco", "humedo"), each = 3)
columnas_ext_tp <- intersect(c("tipo", "anio", "P_mm_anio", "PET_mm_anio", "Q_mm_anio", "Q_sobre_P"), names(extremos_tp))
write.csv(extremos_tp[, columnas_ext_tp], "03_outputs/tables/05_anios_extremos_E04.csv", row.names = FALSE)

relaciones_tp <- data.frame(indicador = c("Correlacion P-PET anual", "Correlacion PET-Tmed anual"),
                            valor = c(round(cor(anual_e04_tp$P_mm_anio, anual_e04_tp$PET_mm_anio), 3),
                                      round(cor(anual_e04_tp$PET_mm_anio, anual_e04_tp$Tmed_degC), 3)))
if ("Q_mm_anio" %in% names(anual_e04_tp) && all(!is.na(anual_e04_tp$Q_mm_anio))) {
  relaciones_tp <- rbind(relaciones_tp, data.frame(
    indicador = c("Correlacion P-Q anual",
                  "P - Q medio (mm/anio)",
                  "PET media (mm/anio)",
                  "(P - Q) / PET"),
    valor = c(round(cor(anual_e04_tp$P_mm_anio, anual_e04_tp$Q_mm_anio), 3),
              round(mean(anual_e04_tp$P_mm_anio - anual_e04_tp$Q_mm_anio), 1),
              round(mean(anual_e04_tp$PET_mm_anio), 1),
              round(mean(anual_e04_tp$P_mm_anio - anual_e04_tp$Q_mm_anio) / mean(anual_e04_tp$PET_mm_anio), 3))
  ))
}
write.csv(relaciones_tp, "03_outputs/tables/05_relaciones_anuales_E04.csv", row.names = FALSE)
message("05: cifras de E03 y E04 escritas en 03_outputs/tables/05_*_E03.csv y 05_*_E04.csv")

# 11.4 Peso del relleno en el caudal anual (si la serie trae el metodo)
# Para cada anio: dias rellenados y que parte del volumen anual sale de ellos.
if (!is.null(caudal_anual_tp) && exists("caudal_tp") && !all(is.na(caudal_tp$metodo))) {
  en_per_tp <- caudal_tp[format(caudal_tp$fecha, "%Y") %in% as.character(inicio_tp:fin_tp), ]
  relleno_dia_tp <- is.na(en_per_tp$Q_obs_m3s) & !is.na(en_per_tp$Q_m3s)
  anio_rel_tp <- format(en_per_tp$fecha, "%Y")
  relleno_anio_tp <- data.frame(
    anio = sort(unique(anio_rel_tp)),
    dias_rellenados = as.integer(tapply(relleno_dia_tp, anio_rel_tp, sum)),
    pct_volumen_rellenado = round(100 * as.numeric(tapply(en_per_tp$Q_m3s * relleno_dia_tp, anio_rel_tp, sum)) /
                                    as.numeric(tapply(en_per_tp$Q_m3s, anio_rel_tp, sum)), 1)
  )
  relleno_anio_tp <- relleno_anio_tp[relleno_anio_tp$dias_rellenados > 0, ]
  write.csv(relleno_anio_tp, "03_outputs/tables/05_relleno_por_anio_E04.csv", row.names = FALSE)
}

# 11.5 Anios en que P - Q supera a la PET
if ("Q_mm_anio" %in% names(anual_e04_tp) && all(!is.na(anual_e04_tp$Q_mm_anio))) {
  supera_tp <- sum(anual_e04_tp$P_mm_anio - anual_e04_tp$Q_mm_anio > anual_e04_tp$PET_mm_anio)
  relaciones_tp <- rbind(relaciones_tp, data.frame(
    indicador = c("Anios con P - Q mayor que PET", "Anios del periodo"),
    valor = c(supera_tp, nrow(anual_e04_tp))))
  write.csv(relaciones_tp, "03_outputs/tables/05_relaciones_anuales_E04.csv", row.names = FALSE)
}

# 12. Clasificacion de Koppen-Geiger (Beck et al., 2023)
# Mapa de 1 km para 1991-2020 (parametro koppen_tif). Como el original pesa
# poco mas de 12 MB y vive en raw (que no se versiona), el script guarda el
# recorte de la cuenca en processed: sin el original, se usa ese recorte.
# Codigos de clase segun legend.txt del mismo producto.
simbolos_koppen_tp <- c("Af", "Am", "Aw", "BWh", "BWk", "BSh", "BSk", "Csa", "Csb", "Csc",
                        "Cwa", "Cwb", "Cwc", "Cfa", "Cfb", "Cfc", "Dsa", "Dsb", "Dsc", "Dsd",
                        "Dwa", "Dwb", "Dwc", "Dwd", "Dfa", "Dfb", "Dfc", "Dfd", "ET", "EF")
recorte_koppen_tp <- file.path("01_data/processed", paste0("koppen_1991_2020_", codigo_tp, ".tif"))
koppen_tif_tp <- config_tp$koppen_tif

if (!is.null(koppen_tif_tp) && file.exists(koppen_tif_tp)) {
  library(terra)
  k_tp <- rast(koppen_tif_tp)
  cuenca_k_tp <- project(vect(config_tp$poligono_clima), crs(k_tp))
  k_cuenca_tp <- crop(k_tp, ext(cuenca_k_tp) + 0.05, snap = "out")
  writeRaster(k_cuenca_tp, recorte_koppen_tp, overwrite = TRUE, datatype = "INT1U")
} else if (file.exists(recorte_koppen_tp)) {
  message("05: no esta el mapa original de Koppen (koppen_tif); se usa el recorte ",
          recorte_koppen_tp)
}

if (file.exists(recorte_koppen_tp)) {
  library(terra)
  k_cuenca_tp <- rast(recorte_koppen_tp)
  cuenca_k_tp <- project(vect(config_tp$poligono_clima), crs(k_cuenca_tp))
  fr_tp <- extract(k_cuenca_tp, cuenca_k_tp, exact = TRUE)
  names(fr_tp)[2] <- "clase"
  koppen_tabla_tp <- aggregate(fraction ~ clase, fr_tp, sum)
  koppen_tabla_tp$simbolo <- simbolos_koppen_tp[koppen_tabla_tp$clase]
  koppen_tabla_tp$pct_area <- round(100 * koppen_tabla_tp$fraction / sum(koppen_tabla_tp$fraction), 1)
  koppen_tabla_tp <- koppen_tabla_tp[order(-koppen_tabla_tp$pct_area), c("clase", "simbolo", "pct_area")]
  write.csv(koppen_tabla_tp, "03_outputs/tables/05_koppen_cuenca.csv", row.names = FALSE)

  clases_tp <- sort(unique(values(k_cuenca_tp)))
  clases_tp <- clases_tp[!is.na(clases_tp)]
  colores_k_tp <- c(Csb = "#C8C800", Cfb = "#64FF50", Cfc = "#32C800", Csc = "#969600",
                    Cfa = "#C8FF50", Csa = "#FFFF00", ET = "#B2B2B2", Dfb = "#37C8FF", Dfc = "#007D7D")
  # Colores de legend.txt para las clases de la zona; otra clase sale en gris.
  col_clases_tp <- unname(colores_k_tp[simbolos_koppen_tp[clases_tp]])
  col_clases_tp[is.na(col_clases_tp)] <- "grey60"
  png("03_outputs/figures/05_mapa_koppen.png", width = 1400, height = 1100, res = 200)
  par(mar = c(3, 3, 3, 1))
  plot(k_cuenca_tp, type = "classes", levels = simbolos_koppen_tp[clases_tp],
       col = col_clases_tp,
       main = "Köppen-Geiger 1991-2020 (Beck et al., 2023)")
  lines(cuenca_k_tp, lwd = 2)
  dev.off()
  message("05: Koppen-Geiger: ", paste(koppen_tabla_tp$simbolo, koppen_tabla_tp$pct_area, "%", collapse = "; "))
}
