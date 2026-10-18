# 05_regimen_hidroclimatico.R
# Series mensuales y anuales del clima de la cuenca, su climatologia y el
# climograma.
# Ejecutar desde la carpeta principal del repositorio (lo llama run_all.R),
# despues de 04_preparacion_clima.R.
#
# Entrada: 01_data/processed/clima_CR2METv25_<codigo>_daily_<inicio>-<fin>.csv
#          (sale del script 04). Periodo de la climatologia: parametros
#          periodo_inicio y periodo_fin de 06_config/parametros.csv.
# Salida:  01_data/processed/clima_CR2METv25_<codigo>_monthly_<inicio>-<fin>.csv
#          01_data/processed/clima_CR2METv25_<codigo>_annual_<inicio>-<fin>.csv
#          03_outputs/tables/05_climatologia_mensual.csv
#          03_outputs/figures/05_climograma.png
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
agregar_tp <- function(datos, grupo, dias_esperados) {
  salida <- data.frame(periodo = sort(unique(grupo)))
  salida$dias_esperados <- as.integer(dias_esperados[salida$periodo])

  for (v in c(variables_suma_tp, variables_promedio_tp)) {
    con_dato <- tapply(!is.na(datos[[v]]), grupo, sum)[salida$periodo]
    funcion  <- if (v %in% variables_suma_tp) sum else mean
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
mtext("Temperatura media (degC)", side = 4, line = 3)

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
