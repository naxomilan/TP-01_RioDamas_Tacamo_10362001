# Rio Damas en Tacamo: GR4J y GR6J diarios, 1987-2019.
# Clima CR2MET v2.5 y PET Hargreaves-Samani: Fernanda.
# Caudal DGA: Alexis. Area de su delimitacion: 468.73 km2.

# 1. Configuracion ------------------------------------------------------
if (!dir.exists("01_data/processed") || !dir.exists("02_Rscripts")) {
  stop("Abre el archivo .Rproj desde la raiz del repositorio.")
}
for (paquete_tp in c("airGRteaching", "airGR")) {
  if (!requireNamespace(paquete_tp, quietly = TRUE)) {
    stop("Instala el paquete desde la consola: ", paquete_tp)
  }
}
codigo_camels_tp <- "10362001"
area_km2_tp <- 468.73
periodos_tp <- list(
  Calibracion = list(wup = c("1986-01-01", "1986-12-31"),
                     run = c("1987-01-01", "2006-12-31")),
  Validacion = list(wup = c("2006-01-01", "2006-12-31"),
                    run = c("2007-01-01", "2019-12-31"))
)
archivo_clima_tp <- paste0("01_data/processed/",
                           "clima_CR2METv25_10362001_daily_1960-2021.csv")
archivo_q_tp <- paste0("01_data/processed/",
                       "caudal_diario_para_airGR_1987_2019.csv")
for (carpeta_tp in c("03_outputs/tables", "03_outputs/figures", "04_metadata")) {
  dir.create(carpeta_tp, recursive = TRUE, showWarnings = FALSE)
}

# 2. Leer y revisar los datos -------------------------------------------
leer_serie_tp <- function(archivo, columnas) {
  if (!file.exists(archivo)) stop("No se encontro: ", archivo)
  x <- read.csv(archivo, stringsAsFactors = FALSE, check.names = FALSE,
                na.strings = c("NA", ""), fileEncoding = "UTF-8")
  if (nrow(x) == 0 || !all(columnas %in% names(x))) {
    stop("Revisa el contenido y las columnas de: ", archivo)
  }
  x$fecha <- as.Date(x$fecha, format = "%Y-%m-%d")
  if (anyNA(x$fecha) || anyDuplicated(x$fecha) > 0) {
    stop("Hay fechas invalidas o repetidas en: ", archivo)
  }
  x[order(x$fecha), columnas, drop = FALSE]
}
columnas_clima_tp <- c("fecha", "P_mm", "PET_mm",
                       "Tmax_degC", "Tmin_degC", "Tmed_degC")
columnas_q_tp <- c("fecha", "Q_observado_m3s", "Q_completado_m3s",
                   "es_observado", "metodo_relleno", "estacion_donante")
clima_tp <- leer_serie_tp(archivo_clima_tp, columnas_clima_tp)
caudal_tp <- leer_serie_tp(archivo_q_tp, columnas_q_tp)

for (columna_tp in c("Q_observado_m3s", "Q_completado_m3s")) {
  valores_tp <- caudal_tp[[columna_tp]]
  if (!is.numeric(valores_tp) ||
      any(!is.na(valores_tp) & !is.finite(valores_tp)) ||
      any(valores_tp < 0, na.rm = TRUE)) {
    stop("Hay caudales invalidos en: ", columna_tp)
  }
}
observados_tp <- !is.na(caudal_tp$Q_observado_m3s)
if (!identical(caudal_tp$es_observado, observados_tp)) {
  stop("es_observado no coincide con la presencia de caudales originales.")
}
if (anyNA(caudal_tp$Q_completado_m3s[observados_tp]) ||
    any(abs(caudal_tp$Q_observado_m3s[observados_tp] -
            caudal_tp$Q_completado_m3s[observados_tp]) > 1e-8)) {
  stop("La serie completada modifica algun caudal observado.")
}

# Calendario diario completo, incluido el calentamiento de 1986.
fechas_tp <- seq.Date(as.Date(periodos_tp$Calibracion$wup[1]),
                      as.Date(periodos_tp$Validacion$run[2]), by = "day")
pos_clima_tp <- match(fechas_tp, clima_tp$fecha)
if (anyNA(pos_clima_tp)) stop("Faltan fechas climaticas necesarias.")
datos_airgr_tp <- clima_tp[pos_clima_tp, , drop = FALSE]
rownames(datos_airgr_tp) <- NULL
for (columna_tp in setdiff(columnas_clima_tp, "fecha")) {
  valores_tp <- datos_airgr_tp[[columna_tp]]
  if (!is.numeric(valores_tp) || any(!is.finite(valores_tp))) {
    stop("Hay datos climaticos ausentes o invalidos en: ", columna_tp)
  }
}
if (any(datos_airgr_tp$P_mm < 0 | datos_airgr_tp$PET_mm < 0) ||
    any(datos_airgr_tp$Tmin_degC > datos_airgr_tp$Tmax_degC)) {
  stop("Revisa P, PET y el orden de Tmin y Tmax.")
}
en_analisis_tp <- fechas_tp >= as.Date(periodos_tp$Calibracion$run[1])
pos_q_tp <- match(fechas_tp, caudal_tp$fecha)
if (anyNA(pos_q_tp[en_analisis_tp])) stop("Faltan fechas DGA en 1987-2019.")
datos_airgr_tp <- cbind(datos_airgr_tp,
                        caudal_tp[pos_q_tp, setdiff(columnas_q_tp, "fecha"), drop = FALSE])
rownames(datos_airgr_tp) <- NULL
datos_airgr_tp$es_observado <- !is.na(datos_airgr_tp$Q_observado_m3s)
datos_airgr_tp$etapa <- ifelse(!en_analisis_tp, "calentamiento",
                               ifelse(fechas_tp <= as.Date(periodos_tp$Calibracion$run[2]),
                                      "calibracion", "validacion"))
# Q [mm/dia] = Q [m3/s] * 86.4 / area [km2]. Se conservan los NA.
datos_airgr_tp$Q_observado_mm_dia <-
  datos_airgr_tp$Q_observado_m3s * 86.4 / area_km2_tp

# 3. Cobertura anual y entradas de los modelos --------------------------
indices_tp <- split(which(en_analisis_tp),
                    format(fechas_tp[en_analisis_tp], "%Y"))
cobertura_airgr_tp <- do.call(rbind, lapply(indices_tp, function(i) {
  obs <- datos_airgr_tp$Q_observado_m3s[i]
  comp <- datos_airgr_tp$Q_completado_m3s[i]
  data.frame(anio = as.integer(format(fechas_tp[i[1]], "%Y")),
             dias = length(i), observados = sum(!is.na(obs)),
             rellenados = sum(is.na(obs) & !is.na(comp)), pendientes = sum(is.na(comp)),
             cobertura_observada_pct = round(100 * mean(!is.na(obs)), 2))
}))
BasinObs_tp <- data.frame(
  DatesR = as.POSIXct(paste(fechas_tp, "00:00:00"), tz = "UTC"),
  P = datos_airgr_tp$P_mm, E = datos_airgr_tp$PET_mm,
  Qmm = datos_airgr_tp$Q_observado_mm_dia, T = datos_airgr_tp$Tmed_degC)
# Qmm usa solo observaciones. T se conserva, pero no se activa CemaNeige.
for (periodo_tp in periodos_tp) {
  usar_tp <- fechas_tp >= as.Date(periodo_tp$run[1]) &
    fechas_tp <= as.Date(periodo_tp$run[2])
  q_tp <- BasinObs_tp$Qmm[usar_tp]
  q_tp <- q_tp[is.finite(q_tp)]
  if (length(q_tp) < 2 || sd(q_tp) == 0) stop("No se puede calcular NSE.")
}

# 4. Funciones compartidas: metricas, tablas y figuras -------------------
evaluar_tp <- function(tabla, etapa) {
  if (any(!is.finite(tabla$Qsim))) stop("Hay caudales simulados invalidos.")
  usar <- is.finite(tabla$Qobs)
  obs <- tabla$Qobs[usar]
  sim <- tabla$Qsim[usar]
  data.frame(etapa = etapa, dias_periodo = nrow(tabla),
             dias_evaluados = length(obs),
             NSE = 1 - sum((sim - obs)^2) / sum((obs - mean(obs))^2),
             RMSE_mm_dia = sqrt(mean((sim - obs)^2)),
             sesgo_pct = 100 * sum(sim - obs) / sum(obs))
}
guardar_tabla_tp <- function(x, nombre) {
  write.csv(x, file.path("03_outputs/tables", paste0(nombre, ".csv")),
            row.names = FALSE)
}
guardar_figura_tp <- function(objeto, nombre) {
  png(file.path("03_outputs/figures", paste0(nombre, ".png")),
      width = 1800, height = 1400, res = 160)
  on.exit(dev.off())
  plot(objeto)
}

# 5. Balance interno: P + intercambio - ET real - Q - cambio de S --------
almacenamiento_tp <- function(estados, modelo) {
  nombres <- c("Prod", "Rout", if (modelo == "GR6J") "Exp")
  if (!all(nombres %in% names(estados$Store)) ||
      length(estados$UH$UH1) < 2 || length(estados$UH$UH2) < 2) {
    stop("No se encontraron todos los almacenamientos.")
  }
  # El primer valor de cada UH ya salio; los restantes siguen en transito.
  componentes <- c(unlist(estados$Store[nombres]),
                   estados$UH$UH1[-1], estados$UH$UH2[-1])
  if (any(!is.finite(componentes))) stop("Almacenamientos invalidos.")
  sum(componentes)
}
balance_tp <- function(modelo, prep, parametros, referencia, etapa) {
  ejecutar <- switch(modelo, GR4J = airGR::RunModel_GR4J,
                     GR6J = airGR::RunModel_GR6J)
  entradas <- prep$InputsModel
  fechas <- as.Date(entradas$DatesR, tz = "UTC")
  simular <- function(periodo, estados = NULL) {
    indices <- match(seq.Date(as.Date(periodo[1]), as.Date(periodo[2]),
                              by = "day"), fechas)
    if (anyNA(indices)) stop("Faltan fechas para verificar el balance.")
    opciones <- airGR::CreateRunOptions(
      FUN_MOD = ejecutar, InputsModel = entradas, IndPeriod_WarmUp = 0L,
      IndPeriod_Run = indices, IniStates = estados,
      Outputs_Sim = "all", verbose = FALSE)
    ejecutar(InputsModel = entradas, RunOptions = opciones, Param = parametros)
  }
  periodo <- periodos_tp[[etapa]]
  inicial <- simular(periodo$wup)$StateEnd
  salida <- simular(periodo$run, inicial)
  ref <- referencia$OutputsModel
  if (!identical(as.Date(salida$DatesR, tz = "UTC"),
                 as.Date(ref$DatesR, tz = "UTC"))) stop("Fechas no coincidentes.")
  diferencia <- max(abs(salida$Qsim - ref$Qsim))
  if (!is.finite(diferencia) || diferencia > 1e-7) {
    stop("El control no reproduce la simulacion. Revisa la inicializacion.")
  }
  campos <- c("Precip", "AE", "Qsim", "AExch")
  if (!all(campos %in% names(salida)) ||
      any(!is.finite(unlist(salida[campos])))) stop("Balance incompleto.")
  totales <- vapply(salida[campos], sum, numeric(1))
  s0 <- almacenamiento_tp(inicial, modelo)
  s1 <- almacenamiento_tp(salida$StateEnd, modelo)
  residuo <- unname(totales["Precip"] + totales["AExch"] -
                      totales["AE"] - totales["Qsim"] - (s1 - s0))
  data.frame(modelo = modelo, etapa = etapa,
             inicio = periodo$run[1], fin = periodo$run[2],
             dias_simulados = length(salida$Qsim), P_mm = unname(totales["Precip"]),
             ETa_mm = unname(totales["AE"]), Q_sim_mm = unname(totales["Qsim"]),
             intercambio_mm = unname(totales["AExch"]), S_inicial_mm = s0,
             S_final_mm = s1, delta_S_mm = s1 - s0, residuo_mm = residuo,
             cierre_ok = abs(residuo) <= 0.001, max_diferencia_Q_mm_dia = diferencia)
}

# 6. Calibrar, validar y guardar: mismo procedimiento para ambos ---------
nombres_tablas_tp <- list(
  GR4J = c("metricas_airgr", "parametros_airgr", "caudales_airgr_por_periodos",
           "configuracion_ejecutada_airgr"),
  GR6J = c("metricas_airgr_gr6j", "parametros_airgr_gr6j", "caudales_airgr_gr6j",
           "configuracion_airgr_gr6j"))
descripciones_tp <- c("Capacidad del almacenamiento de produccion",
                      "Coeficiente de intercambio entre cuencas",
                      "Capacidad del almacenamiento de transferencia",
                      "Constante temporal del hidrograma unitario",
                      "Umbral de intercambio entre cuencas",
                      "Coeficiente de vaciado del almacenamiento exponencial")
unidades_tp <- c("mm", "mm/dia", "mm", "dias", "adimensional", "mm")
resultados_airgr_tp <- list()

for (modelo_tp in names(nombres_tablas_tp)) {
  message("\nModelando con ", modelo_tp, "...")
  prep_tp <- airGRteaching::PrepGR(ObsDF = BasinObs_tp,
                                   HydroModel = modelo_tp, CemaNeige = FALSE)
  cal_tp <- airGRteaching::CalGR(PrepGR = prep_tp, CalCrit = "NSE",
                                 WupPer = periodos_tp$Calibracion$wup,
                                 CalPer = periodos_tp$Calibracion$run, transfo = "")
  val_tp <- airGRteaching::SimGR(PrepGR = prep_tp, Param = cal_tp,
                                 EffCrit = "NSE", WupPer = periodos_tp$Validacion$wup,
                                 SimPer = periodos_tp$Validacion$run, transfo = "")
  parametros_tp <- as.numeric(cal_tp$OutputsCalib$ParamFinalR)
  n_tp <- seq_along(parametros_tp)
  tabla_parametros_tp <- data.frame(parametro = paste0("X", n_tp),
                                    descripcion = descripciones_tp[n_tp], valor = parametros_tp,
                                    unidad = unidades_tp[n_tp])
  ejecuciones_tp <- list(Calibracion = cal_tp, Validacion = val_tp)
  metricas_tp <- series_tp <- balances_tp <- list()
  prefijo_tp <- if (modelo_tp == "GR4J") "airgr" else "airgr_gr6j"
  
  for (etapa_tp in names(ejecuciones_tp)) {
    objeto_tp <- ejecuciones_tp[[etapa_tp]]
    tabla_tp <- as.data.frame(objeto_tp)
    metricas_tp[[etapa_tp]] <- evaluar_tp(tabla_tp, etapa_tp)
    series_tp[[etapa_tp]] <- data.frame(
      fecha = as.Date(tabla_tp$Dates, tz = "UTC"), etapa = tolower(etapa_tp),
      P_mm_dia = tabla_tp$PrecipObs, PET_mm_dia = tabla_tp$PotEvap,
      Q_observado_mm_dia = tabla_tp$Qobs, Q_simulado_mm_dia = tabla_tp$Qsim,
      Q_observado_m3s = tabla_tp$Qobs * area_km2_tp / 86.4,
      Q_simulado_m3s = tabla_tp$Qsim * area_km2_tp / 86.4)
    balances_tp[[etapa_tp]] <- balance_tp(
      modelo_tp, prep_tp, parametros_tp, objeto_tp, etapa_tp)
    guardar_figura_tp(objeto_tp, paste0(prefijo_tp, "_", tolower(etapa_tp)))
  }
  opciones_tp <- c(codigo_camels = codigo_camels_tp, area_km2 = area_km2_tp,
                   modelo = modelo_tp, CemaNeige = "FALSE", criterio = "NSE", transfo = "",
                   calentamiento_cal_inicio = periodos_tp$Calibracion$wup[1],
                   calentamiento_cal_fin = periodos_tp$Calibracion$wup[2],
                   calibracion_inicio = periodos_tp$Calibracion$run[1],
                   calibracion_fin = periodos_tp$Calibracion$run[2],
                   calentamiento_val_inicio = periodos_tp$Validacion$wup[1],
                   calentamiento_val_fin = periodos_tp$Validacion$wup[2],
                   validacion_inicio = periodos_tp$Validacion$run[1],
                   validacion_fin = periodos_tp$Validacion$run[2],
                   archivo_clima = archivo_clima_tp, archivo_caudal = archivo_q_tp,
                   referencia_evaluacion = "DGA observado; excluir rellenos",
                   tolerancia_balance_mm = "0.001")
  tablas_tp <- list(do.call(rbind, metricas_tp), tabla_parametros_tp,
                    do.call(rbind, series_tp),
                    data.frame(parametro = names(opciones_tp), valor = unname(opciones_tp)))
  for (i_tp in seq_along(tablas_tp)) {
    guardar_tabla_tp(tablas_tp[[i_tp]], nombres_tablas_tp[[modelo_tp]][i_tp])
  }
  resultados_airgr_tp[[modelo_tp]] <- list(
    preparacion = prep_tp, calibracion = cal_tp, validacion = val_tp,
    metricas = data.frame(modelo = modelo_tp, tablas_tp[[1]]),
    parametros = tabla_parametros_tp, balance = do.call(rbind, balances_tp))
}

# 7. Comparacion y registro final ---------------------------------------
comparacion_modelos_tp <- do.call(rbind,
                                  lapply(resultados_airgr_tp, function(x) x$metricas))
balance_interno_airgr_tp <- do.call(rbind,
                                    lapply(resultados_airgr_tp, function(x) x$balance))
write.csv(datos_airgr_tp, "01_data/processed/entradas_airgr_1986_2019.csv",
          row.names = FALSE)
guardar_tabla_tp(cobertura_airgr_tp, "cobertura_DGA_para_airgr")
guardar_tabla_tp(comparacion_modelos_tp, "comparacion_GR4J_GR6J")
guardar_tabla_tp(balance_interno_airgr_tp, "balance_interno_airgr")
for (nombre_tp in c("R_sessionInfo_airgr.txt", "R_sessionInfo_gr6j.txt")) {
  capture.output(utils::sessionInfo(), file = file.path("04_metadata", nombre_tp))
}
cat("\nCobertura anual del caudal DGA:\n")
print(cobertura_airgr_tp, row.names = FALSE)
cat("\nComparacion entre GR4J y GR6J:\n")
print(comparacion_modelos_tp, row.names = FALSE)
for (modelo_tp in names(resultados_airgr_tp)) {
  cat("\nParametros calibrados de", modelo_tp, ":\n")
  print(resultados_airgr_tp[[modelo_tp]]$parametros, row.names = FALSE)
}
cat("\nBalance interno acumulado por periodo, en mm:\n")
print(balance_interno_airgr_tp[, c("modelo", "etapa", "P_mm", "ETa_mm",
                                   "Q_sim_mm", "intercambio_mm", "delta_S_mm", "residuo_mm", "cierre_ok")],
      row.names = FALSE, digits = 6)
if (!all(balance_interno_airgr_tp$cierre_ok)) {
  warning("Hay balances fuera de tolerancia; revisalos antes de dar el control por aprobado.")
}
message("Modelacion y comprobacion del balance finalizadas.")