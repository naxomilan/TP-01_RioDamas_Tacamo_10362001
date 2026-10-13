# Modelacion de Rio Damas en Tacamo
# Codigo CAMELS: 10362001

# Comprobar que estamos trabajando desde la raiz del proyecto
if (!dir.exists("01_data/raw") ||
    !dir.exists("02_Rscripts")) {
  stop("Abre primero el archivo .Rproj del repositorio.")
}

# Ubicacion de los datos originales
carpeta_datos_tp <- file.path("01_data", "raw")

# Buscar los archivos, incluidas las subcarpetas
archivos_datos_tp <- list.files(
  path = carpeta_datos_tp,
  recursive = TRUE,
  full.names = TRUE
)

# Mostrar sus rutas
print(archivos_datos_tp)

# ------------------------------------------------------------
# Lectura inicial de las series diarias
# ------------------------------------------------------------

# Asociar cada variable con su archivo
archivos_modelo_tp <- c(
  Q_mm = "q_mm_day.csv",
  P = "precip_cr2met_day.csv",
  PET = "pet_hargreaves_day.csv",
  Tmax = "tmax_cr2met_day.csv",
  Tmin = "tmin_cr2met_day.csv"
)

# Leer los archivos y conservar los nombres originales de columnas
datos_modelo_raw_tp <- lapply(
  archivos_modelo_tp,
  function(archivo_tp) {
    read.csv(
      file = file.path(
        "01_data",
        "raw",
        "camels_cl_10362001",
        archivo_tp
      ),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }
)

# Revisar el contenido de cada tabla
for (variable_tp in names(datos_modelo_raw_tp)) {
  
  cat("\nVariable:", variable_tp, "\n")
  
  cat(
    "Cantidad de filas:",
    nrow(datos_modelo_raw_tp[[variable_tp]]),
    "\n"
  )
  
  cat("Nombres de columnas:\n")
  print(names(datos_modelo_raw_tp[[variable_tp]]))
  
  cat("Primeras tres filas:\n")
  print(head(datos_modelo_raw_tp[[variable_tp]], 3))
}

# ------------------------------------------------------------
# Revisar fechas y disponibilidad de datos
# ------------------------------------------------------------

resumen_cobertura_tp <- data.frame()

for (variable_tp in names(datos_modelo_raw_tp)) {
  
  # Tomar la tabla de esta variable
  tabla_tp <- datos_modelo_raw_tp[[variable_tp]]
  
  # Leer las fechas y los valores de nuestra cuenca
  fechas_tp <- as.Date(
    tabla_tp[["date"]],
    format = "%Y-%m-%d"
  )
  
  valores_tp <- tabla_tp[["10362001"]]
  
  # Detener la revisión si hay fechas que R no reconoce
  if (anyNA(fechas_tp)) {
    stop("Hay fechas ausentes o no reconocidas en: ", variable_tp)
  }
  
  # Identificar las filas que tienen un valor registrado
  con_dato_tp <- !is.na(valores_tp)
  
  # Buscar la primera y la última fecha con un valor
  if (any(con_dato_tp)) {
    periodo_tp <- as.character(
      range(fechas_tp[con_dato_tp])
    )
  } else {
    periodo_tp <- c(NA_character_, NA_character_)
  }
  
  # Contar los días del calendario entre ambas fechas del archivo
  dias_calendario_tp <- as.integer(
    max(fechas_tp) - min(fechas_tp)
  ) + 1L
  
  # Incorporar una fila al resumen
  resumen_cobertura_tp <- rbind(
    resumen_cobertura_tp,
    data.frame(
      variable = variable_tp,
      filas = nrow(tabla_tp),
      con_dato = sum(con_dato_tp),
      sin_dato = sum(!con_dato_tp),
      primer_dato = periodo_tp[1],
      ultimo_dato = periodo_tp[2],
      fechas_repetidas = sum(duplicated(fechas_tp)),
      dias_sin_fila = dias_calendario_tp -
        length(unique(fechas_tp))
    )
  )
}

# Mostrar el resumen de las cinco variables
print(resumen_cobertura_tp, row.names = FALSE)

