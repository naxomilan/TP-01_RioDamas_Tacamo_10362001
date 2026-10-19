# ============================================================
# 08b_respaldo_relleno_Q.R
# Rio Damas en Tacamo (10362001) | 1987-2019
# Respaldo y seleccion de metodos de relleno
# ============================================================

# Requiere "base" del control de calidad 08
if (!exists("base"))
  stop("Ejecute primero 08_control_calidad_Q.R")


# ------------------------------------------------------------
# 1. HUECOS DE LA SERIE
# ------------------------------------------------------------

periodo <- seq(as.Date("1987-01-01"), as.Date("2019-12-31"), "day")

damas <- merge(
  data.frame(FECHA = periodo),
  base[base$CODIGO.ESTACION == 10362001,
       c("FECHA","Caudal_diario")],
  by = "FECHA", all.x = TRUE
)

falt <- damas$FECHA[is.na(damas$Caudal_diario)]
g <- cumsum(c(TRUE, diff(falt) != 1))

huecos <- do.call(rbind, lapply(split(falt, g), function(x)
  data.frame(inicio = min(x), fin = max(x), dias = length(x))
))

rownames(huecos) <- NULL

huecos$metodo <- ifelse(
  huecos$dias == 1,
  "interpolacion_lineal",
  "reconstruccion_regional"
)

huecos$metodo[
  huecos$inicio == as.Date("2009-02-01")
] <- "climatologia_febrero"


# ------------------------------------------------------------
# 2. FEBRERO 2009: CLIMATOLOGIA
# ------------------------------------------------------------

feb <- damas[
  format(damas$FECHA, "%m") == "02" &
  format(damas$FECHA, "%Y") != "2009",
]

feb_anual <- aggregate(
  Caudal_diario ~ format(FECHA, "%Y"),
  feb, mean, na.rm = TRUE
)

Q_feb <- quantile(feb_anual$Caudal_diario, c(.25,.50,.75))
Q_febrero <- unname(Q_feb[2])


# ------------------------------------------------------------
# 3. BLOQUES Y ESTACIONES CANDIDATAS
# ------------------------------------------------------------

eventos <- huecos[
  huecos$metodo == "reconstruccion_regional",
  c("inicio","fin","dias")
]

eventos$evento <- seq_len(nrow(eventos))

candidatas <- c(
  10340001,10343001,10343002,10344003,10344004,
  10356001,10363002,10364001,10411002
)


# ------------------------------------------------------------
# 4. VALIDACION DE DONANTES
# Cobertura >=90 %, >=15 años y leave-one-year-out
# ------------------------------------------------------------

validar <- function(e, cod) {

  ini <- eventos$inicio[e]
  fin <- eventos$fin[e]
  a0 <- as.integer(format(ini, "%Y"))
  cruza <- as.integer(format(ini, "%Y") != format(fin, "%Y"))
  x <- NULL

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
      x <- rbind(x, data.frame(
        Qd = mean(qd, na.rm = TRUE),
        Qv = mean(qv, na.rm = TRUE)
      ))
  }

  if (is.null(x) || nrow(x) < 15) return(NULL)

  pred <- sapply(seq_len(nrow(x)), function(i)
    max(predict(lm(Qd ~ Qv, x[-i,]), x[i,]), 0))

  # Cobertura del donante durante el hueco real
  f <- seq(ini, fin, "day")
  q <- base$Caudal_diario[
    base$CODIGO.ESTACION == cod & base$FECHA %in% f
  ]
  cobertura <- 100 * sum(!is.na(q)) / length(f)

  if (cobertura < 90) return(NULL)

  data.frame(
    evento = e, codigo = cod, n_anios = nrow(x),
    cobertura = cobertura,
    r = cor(x$Qd, x$Qv),
    rho = cor(x$Qd, x$Qv, method = "spearman"),
    sesgo = mean(100*(pred-x$Qd)/x$Qd),
    error_med = median(abs(100*(pred-x$Qd)/x$Qd)),
    RMSE = sqrt(mean((pred-x$Qd)^2))
  )
}


# ------------------------------------------------------------
# 5. SELECCION DEL MEJOR DONANTE
# ------------------------------------------------------------

validacion <- do.call(rbind,
  lapply(seq_len(nrow(eventos)), function(e)
    do.call(rbind, lapply(candidatas, function(cod)
      validar(e, cod)))
  )
)

seleccion <- do.call(rbind,
  lapply(split(validacion, validacion$evento), function(x)
    x[which.min(x$error_med),])
)

rownames(seleccion) <- NULL
eventos$donante <- seleccion$codigo


# ------------------------------------------------------------
# 6. RESPALDO Y RESUMEN
# ------------------------------------------------------------

write.csv(validacion,
          "03_outputs/tables/validacion_relleno_Q.csv",
          row.names = FALSE)

write.csv(eventos,
          "03_outputs/tables/donantes_relleno_Q.csv",
          row.names = FALSE)

write.csv(huecos,
          "03_outputs/tables/huecos_caudal_Q.csv",
          row.names = FALSE)

cat("\n=== RESPALDO RELLENO ===\n")
cat("Dias faltantes:", length(falt), "\n")
cat("Huecos:", nrow(huecos), "\n")
cat("Q febrero P25/P50/P75:",
    round(Q_feb,3), "m3/s\n\n")

print(seleccion)