# 00_setup.R
# Preparacion inicial del proyecto.
# Ejecutar desde la carpeta principal del repositorio.

# 1. Comprobar la ubicacion de trabajo
if (!file.exists("README.md") || !dir.exists("02_Rscripts")) {
  stop(
    "Abre el proyecto de RStudio desde la carpeta principal del repositorio.",
    call. = FALSE
  )
}

# 2. Crear las carpetas necesarias, si todavia no existen
carpetas_tp <- c(
  "01_data/raw",
  "01_data/processed",
  "03_outputs/figures",
  "03_outputs/tables",
  "04_metadata",
  "05_docs",
  "06_config"
)

for (carpeta_tp in carpetas_tp) {
  dir.create(carpeta_tp, recursive = TRUE, showWarnings = FALSE)
  
  if (!dir.exists(carpeta_tp)) {
    stop("No se pudo crear la carpeta: ", carpeta_tp, call. = FALSE)
  }
}

# 3. Comprobar los paquetes requeridos
# Por ahora, esta preparacion utiliza solamente R base.
# Agregaremos los paquetes externos cuando incorporemos los analisis.
paquetes_requeridos <- character(0)

paquetes_faltantes <- paquetes_requeridos[
  !vapply(
    paquetes_requeridos,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]

if (length(paquetes_faltantes) > 0) {
  stop(
    "Faltan paquetes por instalar: ",
    paste(paquetes_faltantes, collapse = ", "),
    call. = FALSE
  )
}

# 4. Registrar las versiones de R, plataforma y paquetes cargados
capture.output(
  utils::sessionInfo(),
  file = "04_metadata/R_sessionInfo.txt"
)

message("Preparacion inicial completada.")