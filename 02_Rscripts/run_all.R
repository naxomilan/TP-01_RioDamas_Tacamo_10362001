# run_all.R
# Script maestro del proyecto.
# Ejecutar desde la carpeta principal del repositorio.

# 1. Indicar los scripts en su orden de ejecucion
scripts_tp <- c(
  "00_setup.R"
)

# Agregar aqui los siguientes scripts cuando esten desarrollados.

# 2. Construir sus rutas relativas
rutas_scripts_tp <- file.path("02_Rscripts", scripts_tp)

# 3. Comprobar que existan todos los scripts registrados
scripts_faltantes_tp <- rutas_scripts_tp[
  !file.exists(rutas_scripts_tp)
]

if (length(scripts_faltantes_tp) > 0) {
  stop(
    "No se encontraron estos scripts: ",
    paste(scripts_faltantes_tp, collapse = ", "),
    ". Comprueba los nombres y la carpeta de trabajo.",
    call. = FALSE
  )
}

# 4. Ejecutar los scripts en el orden indicado
for (ruta_script_tp in rutas_scripts_tp) {
  message("Ejecutando: ", ruta_script_tp)
  source(ruta_script_tp, encoding = "UTF-8")
}

# 5. Actualizar el registro del entorno al finalizar
capture.output(
  utils::sessionInfo(),
  file = "04_metadata/R_sessionInfo.txt"
)

message("Ejecucion de los scripts registrados completada.")
