# ============================================================
# 09_relleno_consistencia_Q.R
# Rio Damas en Tacamo (10362001) | 1987-2019
# Relleno + salidas airGR/Budyko + consistencia estadistica
# Requiere ejecutar previamente 08b_respaldo_relleno_Q.R
# ============================================================

library(trend)
library(tseries)
library(urca)

if (!all(sapply(c("base","huecos","eventos","Q_febrero"), exists)))
  stop("Ejecute primero 08b_respaldo_relleno_Q.R")


# ------------------------------------------------------------
# 1. SERIE BASE
# ------------------------------------------------------------

damas <- merge(
  data.frame(FECHA = seq(as.Date("1987-01-01"),
                         as.Date("2019-12-31"), "day")),
  base[base$CODIGO.ESTACION == 10362001,
       c("FECHA","Caudal_diario")],
  by = "FECHA", all.x = TRUE
)

names(damas)[2] <- "Q_original"
damas$Q_completado <- damas$Q_original
damas$origen <- ifelse(is.na(damas$Q_original), NA, "DGA_observado")
damas$donante <- NA_character_


# ------------------------------------------------------------
# 2. RELLENO
# ------------------------------------------------------------

# Huecos aislados: interpolacion lineal
for (f in huecos$inicio[huecos$metodo == "interpolacion_lineal"]) {
  i <- which(damas$FECHA == f)
  damas$Q_completado[i] <- mean(damas$Q_original[c(i-1,i+1)])
  damas$origen[i] <- "interpolacion_lineal"
}

# Febrero 2009: mediana climatologica obtenida en 08b
i <- damas$FECHA >= as.Date("2009-02-01") &
  damas$FECHA <= as.Date("2009-02-28") &
  is.na(damas$Q_original)

damas$Q_completado[i] <- Q_febrero
damas$origen[i] <- "climatologia_febrero"

# Bloques: regresion regional con donantes validados en 08b
for (e in seq_len(nrow(eventos))) {
  
  ini <- eventos$inicio[e]; fin <- eventos$fin[e]
  cod <- eventos$donante[e]
  a0 <- as.integer(format(ini, "%Y"))
  cruza <- as.integer(format(ini, "%Y") != format(fin, "%Y"))
  hist <- NULL
  
  for (a in 1987:2019) {
    if (a == a0) next
    
    ia <- as.Date(paste0(a, "-", format(ini, "%m-%d")))
    fa <- as.Date(paste0(a + cruza, "-", format(fin, "%m-%d")))
    n <- as.integer(fa - ia) + 1
    
    qd <- base$Caudal_diario[
      base$CODIGO.ESTACION == 10362001 &
        base$FECHA >= ia & base$FECHA <= fa]
    
    qv <- base$Caudal_diario[
      base$CODIGO.ESTACION == cod &
        base$FECHA >= ia & base$FECHA <= fa]
    
    if (sum(!is.na(qd))/n >= .90 && sum(!is.na(qv))/n >= .90)
      hist <- rbind(hist, data.frame(
        Qd = mean(qd, na.rm = TRUE),
        Qv = mean(qv, na.rm = TRUE)
      ))
  }
  
  mod <- lm(Qd ~ Qv, hist)
  
  vec <- merge(
    data.frame(FECHA = seq(ini, fin, "day")),
    base[base$CODIGO.ESTACION == cod,
         c("FECHA","Caudal_diario")],
    by = "FECHA", all.x = TRUE
  )
  
  Qv <- mean(vec$Caudal_diario, na.rm = TRUE)
  Qd <- max(as.numeric(predict(mod, data.frame(Qv = Qv))), 0)
  Qe <- Qd * vec$Caudal_diario / Qv
  
  pos <- match(vec$FECHA, damas$FECHA)
  usar <- is.na(damas$Q_original[pos]) & !is.na(Qe)
  
  damas$Q_completado[pos[usar]] <- Qe[usar]
  damas$origen[pos[usar]] <- "regresion_regional"
  damas$donante[pos[usar]] <- as.character(cod)
}


# ------------------------------------------------------------
# 3. CONTROL
# ------------------------------------------------------------

stopifnot(
  !anyNA(damas$Q_completado),
  all(damas$Q_completado >= 0),
  all(damas$Q_original == damas$Q_completado |
        is.na(damas$Q_original))
)


# ------------------------------------------------------------
# 4. SALIDA DIARIA PARA airGR
# ------------------------------------------------------------

Q_airGR <- data.frame(
  fecha = damas$FECHA,
  Q_observado_m3s = damas$Q_original,
  Q_completado_m3s = damas$Q_completado,
  es_observado = !is.na(damas$Q_original),
  metodo_relleno = damas$origen,
  estacion_donante = damas$donante
)

write.csv(
  Q_airGR,
  "01_data/processed/caudal_diario_para_airGR_1987_2019.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 5. SALIDA ANUAL PARA BUDYKO
# ------------------------------------------------------------

damas$anio <- as.integer(format(damas$FECHA, "%Y"))

Q_Budyko <- aggregate(Q_completado ~ anio, damas, mean)
names(Q_Budyko)[2] <- "Q_medio_anual_m3s"

write.csv(
  Q_Budyko,
  "03_outputs/tables/caudal_anual_para_Budyko_1987_2019.csv",
  row.names = FALSE
)

Q <- ts(Q_Budyko$Q_medio_anual_m3s, start = 1987)


# ------------------------------------------------------------
# 6. HOMOGENEIDAD Y ESTACIONARIEDAD
# ------------------------------------------------------------

pettitt  <- trend::pettitt.test(Q)
buishand <- trend::br.test(Q)
snht     <- trend::snh.test(Q)

adf  <- tseries::adf.test(Q)
kpss <- tseries::kpss.test(Q, null = "Trend")
pp   <- urca::ur.pp(Q, type = "Z-tau", model = "trend")

# Tabla de resultados
resultados <- data.frame(
  grupo = c(rep("Homogeneidad", 3), rep("Estacionariedad", 3)),
  test = c("Pettitt", "Buishand", "SNHT",
           "ADF", "KPSS", "Phillips-Perron"),
  estadistico = as.numeric(c(
    pettitt$statistic,
    buishand$statistic,
    snht$statistic,
    adf$statistic,
    kpss$statistic,
    pp@teststat
  )),
  p_value = c(
    pettitt$p.value,
    buishand$p.value,
    snht$p.value,
    adf$p.value,
    kpss$p.value,
    NA
  ),
  valor_critico_1pct = c(rep(NA, 5), pp@cval[1, "1pct"]),
  valor_critico_5pct = c(rep(NA, 5), pp@cval[1, "5pct"]),
  valor_critico_10pct = c(rep(NA, 5), pp@cval[1, "10pct"])
)

write.csv(
  resultados,
  "03_outputs/tables/resultados_homogeneidad_estacionariedad.csv",
  row.names = FALSE
)

cat("\n=== RESULTADOS ESTADISTICOS ===\n")
print(resultados)

# ------------------------------------------------------------
# 7. FIGURA Y RESUMEN
# ------------------------------------------------------------

png("03_outputs/figures/caudal_medio_anual_1987_2019.png",
    1400, 800, res = 150)

plot(Q_Budyko$anio, Q_Budyko$Q_medio_anual_m3s,
     type = "o", pch = 16,
     xlab = "Año", ylab = expression(Q~(m^3/s)),
     main = "Rio Damas en Tacamo - Caudal medio anual")

abline(h = mean(Q), lty = 2)
dev.off()

cat("\n=== RESULTADOS ESTADISTICOS ===\n")
print(resultados)

cat("\n=== RESUMEN SERIE ===\n")
cat("Periodo: 1987-2019\n")
cat("Dias:", nrow(damas), "\n")
cat("Observados DGA:", sum(!is.na(damas$Q_original)), "\n")
cat("Reconstruidos:", sum(is.na(damas$Q_original)), "\n")
cat("NA finales:", sum(is.na(damas$Q_completado)), "\n")
cat("Q medio:", round(mean(damas$Q_completado),3), "m3/s\n")
print(table(damas$origen))