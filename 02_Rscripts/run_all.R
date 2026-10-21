# run_all.R - TP-01 Rio Damas en Tacamo
# Ejecutar desde la raiz del repositorio, en una sesion nueva de R.

ejecutar_proyecto_tp <- function() {
  
  # 1. Comprobar carpeta y scripts.
  if (!file.exists("README.md") || !dir.exists("02_Rscripts")) {
    stop("Abre el archivo .Rproj de este repositorio.", call. = FALSE)
  }
  
  comprobar_archivos <- function(archivos) {
    faltan <- archivos[!file.exists(archivos)]
    
    if (length(faltan)) {
      stop(
        "Faltan archivos:\n",
        paste(faltan, collapse = "\n"),
        "\nRevisa su ubicacion y 04_metadata/data_sources.csv.",
        call. = FALSE
      )
    }
  }
  
  scripts <- c(
    "00_setup.R",
    
    # Estacion, delimitacion y caracterizacion fisica.
    "01_verificar_estacion.R",
    "02_preparar_datos.R",
    "03_compatibilidad_espacial.R",
    "04_delimitar_cuenca.R",
    "05_comparar_cuenca.R",
    "06_geomorfologia.R",
    "06b_preparar_uso_suelo.R",
    "07_uso_suelo_territorio.R",
    
    # Caudales: control, reconstruccion y consistencia.
    "08_control_calidad_Q.R",
    "08b_respaldo_relleno_Q.R",
    "09_consistencia_Q.R",
    
    # Clima y regimen, con el poligono y los caudales disponibles.
    "04_preparacion_clima.R",
    "05_regimen_hidroclimatico.R",
    
    # Integracion, balance y derechos de agua.
    "03_integrar_datos_equipo.R",
    "04_balance_budyko.R",
    "05_derechos_superficiales_DGA.R",
    
    # Modelacion con los datos ya preparados.
    "modelacion_airgr.R"
  )
  
  rutas <- file.path("02_Rscripts", scripts)
  
  comprobar_archivos(c(rutas, "06_config/parametros.csv"))
  
  # Revisar sintaxis antes de iniciar los analisis.
  invisible(lapply(rutas, parse, encoding = "UTF-8"))
  
  # 2. Comprobar paquetes y el programa WhiteboxTools.
  paquetes <- c(
    "terra", "whitebox", "trend", "tseries", "urca",
    "readxl", "sf", "airGR", "airGRteaching"
  )
  
  faltan <- paquetes[
    !vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)
  ]
  
  if (length(faltan)) {
    stop(
      "Instala estos paquetes desde la consola: ",
      paste(faltan, collapse = ", "),
      call. = FALSE
    )
  }
  
  if (!isTRUE(whitebox::wbt_init())) {
    stop(
      "Falta WhiteboxTools. Ejecuta whitebox::install_whitebox().",
      call. = FALSE
    )
  }
  
  whitebox::wbt_wd(getwd())
  
  # 3. Entorno compartido y registro de ejecucion.
  # Los scripts de caudal necesitan compartir base, huecos y donantes.
  entorno <- new.env(parent = globalenv())
  
  registro <- data.frame(
    script = scripts,
    estado = "pendiente",
    segundos = NA_real_,
    detalle = ""
  )
  
  dir.create(
    "04_metadata",
    recursive = TRUE,
    showWarnings = FALSE
  )
  
  archivo_registro <- "04_metadata/run_all_estado.csv"
  
  guardar_registro <- function() {
    write.csv(registro, archivo_registro, row.names = FALSE)
  }
  
  guardar_registro()
  
  # Guardar el entorno incluso si algun analisis se detiene.
  on.exit(
    capture.output(
      utils::sessionInfo(),
      file = "04_metadata/R_sessionInfo.txt"
    ),
    add = TRUE
  )
  
  capture.output(
    whitebox::wbt_version(),
    file = "04_metadata/WhiteboxTools_version.txt"
  )
  
  ejecutar <- function(nombre) {
    
    i <- match(nombre, scripts)
    inicio <- proc.time()[["elapsed"]]
    dispositivos <- grDevices::dev.list()
    
    # Cerrar los dispositivos graficos abiertos por esta etapa.
    on.exit({
      nuevos <- setdiff(grDevices::dev.list(), dispositivos)
      
      for (d in nuevos) {
        grDevices::dev.off(d)
      }
    }, add = TRUE)
    
    message(
      "\n[", i, "/", length(scripts),
      "] Ejecutando: ", nombre
    )
    
    registro$estado[i] <<- "en ejecucion"
    guardar_registro()
    
    tryCatch({
      
      source(
        file.path("02_Rscripts", nombre),
        local = entorno,
        encoding = "UTF-8",
        chdir = FALSE
      )
      
      if (
        nombre == "08_control_calidad_Q.R" &&
        !exists("base", envir = entorno, inherits = FALSE)
      ) {
        stop(
          "El script 08 debe crear la tabla regional base para 08b y 09."
        )
      }
      
      if (
        nombre == "04_preparacion_clima.R" &&
        !identical(entorno$archivo_salida_tp, archivo_clima)
      ) {
        stop(
          "El clima generado no cubre 1960-2021. ",
          "Revisa las grillas de entrada."
        )
      }
      
    }, error = function(e) {
      
      registro$estado[i] <<- "ERROR"
      registro$detalle[i] <<- conditionMessage(e)
      
      registro$segundos[i] <<- round(
        proc.time()[["elapsed"]] - inicio,
        1
      )
      
      guardar_registro()
      
      stop(
        "Se detuvo ", nombre, ": ", conditionMessage(e),
        "\nConsulta ", archivo_registro,
        call. = FALSE
      )
    })
    
    registro$estado[i] <<- "OK"
    
    registro$segundos[i] <<- round(
      proc.time()[["elapsed"]] - inicio,
      1
    )
    
    guardar_registro()
  }
  
  ejecutar("00_setup.R")
  cfg <- entorno$config_tp
  
  # 4. Revisar la configuracion comun, sin reemplazar el CSV.
  esperados <- c(
    codigo_camels = "10362001",
    periodo_inicio = "1987",
    periodo_fin = "2019",
    
    poligono_clima =
      "01_data/processed/cuenca_rio_damas.gpkg",
    
    serie_caudal =
      "01_data/processed/caudal_diario_para_airGR_1987_2019.csv",
    
    caudal_col_fecha = "fecha",
    caudal_col_valor = "Q_completado_m3s",
    caudal_col_observado = "Q_observado_m3s",
    caudal_col_metodo = "metodo_relleno",
    
    pet_referencia =
      "01_data/raw/camels_cl_10362001/pet_hargreaves_day.csv",
    
    p_referencia =
      "01_data/raw/camels_cl_10362001/precip_cr2met_day.csv"
  )
  
  incorrectos <- names(esperados)[
    !vapply(names(esperados), function(k) {
      identical(cfg[[k]], unname(esperados[k]))
    }, logical(1))
  ]
  
  if (length(incorrectos)) {
    stop(
      "Revisa estas filas de 06_config/parametros.csv:\n",
      paste(
        paste(incorrectos, esperados[incorrectos], sep = ","),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }
  
  if (
    is.null(cfg$ruta_cr2met) ||
    is.na(cfg$ruta_cr2met) ||
    !nzchar(cfg$ruta_cr2met)
  ) {
    stop("Falta ruta_cr2met en parametros.csv.", call. = FALSE)
  }
  
  # 5. Insumos externos: no los generan los scripts adjuntos.
  comprobar_archivos(c(
    "01_data/raw/camels_cl_10362001.zip",
    "01_data/raw/estaciones-de-red-hidrometrica-dga_shapefile.zip",
    "01_data/raw/copernicus_glo30_rio_damas.tar.gz",
    "01_data/raw/Red_Hidrografica_Final.zip",
    "01_data/raw/caudal_diario_historico_dga_los_lagos.zip",
    "01_data/raw/Derechos_Concedidos_X_Region (1).xls",
    "01_data/raw/conaf_catastro_los_lagos_2018.zip",
    "01_data/raw/ciren_suelos_los_lagos_2020.geojson"
  ))
  
  # Preparar CAMELS conservando los archivos originales existentes.
  carpeta_camels <- "01_data/raw/camels_cl_10362001"
  
  internos <- c(
    "catchment_attributes.csv",
    "pet_hargreaves_day.csv",
    "precip_cr2met_day.csv",
    "cons_sf_wr_year.csv",
    paste0("polygon/polygon.", c("shp", "shx", "dbf", "prj"))
  )
  
  extraer <- internos[
    !file.exists(file.path(carpeta_camels, internos))
  ]
  
  if (length(extraer)) {
    dir.create(
      carpeta_camels,
      recursive = TRUE,
      showWarnings = FALSE
    )
    
    unzip(
      "01_data/raw/camels_cl_10362001.zip",
      files = extraer,
      exdir = carpeta_camels,
      overwrite = FALSE
    )
  }
  
  comprobar_archivos(file.path(carpeta_camels, internos))
  
  # Revisar la disponibilidad del clima.
  archivo_clima <- paste0(
    "01_data/processed/",
    "clima_CR2METv25_10362001_daily_1960-2021.csv"
  )
  
  series <- list.files(
    "01_data/processed",
    pattern = "^clima_CR2METv25_10362001_daily_.*[.]csv$"
  )
  
  if (length(series) > 1L) {
    stop(
      "Hay varias series diarias de clima. Revisa cual debe usarse.",
      call. = FALSE
    )
  }
  
  hay_grillas <- all(vapply(c("pr", "txn"), function(x) {
    length(list.files(
      file.path(cfg$ruta_cr2met, x),
      pattern = "[.]nc$"
    )) > 0
  }, logical(1)))
  
  if (!hay_grillas) {
    comprobar_archivos(archivo_clima)
  }
  
  # Koppen puede reconstruirse desde el original o desde su recorte.
  koppen <- "01_data/processed/koppen_1991_2020_10362001.tif"
  
  if (
    is.null(cfg$koppen_tif) ||
    !file.exists(cfg$koppen_tif)
  ) {
    comprobar_archivos(koppen)
  }
  
  nota <- if (hay_grillas) {
    "Clima: se recalcula desde las grillas CR2MET disponibles."
  } else {
    paste(
      "Clima: se parte desde el CSV procesado.",
      "Los mapas espaciales de P y T no se regeneran sin grillas CR2MET."
    )
  }
  
  writeLines(nota, "04_metadata/alcance_run_all.txt")
  message(nota)
  
  message(
    "Budyko conserva la PET y el area CAMELS de su script; revisar",
    " su diferencia con la PET de Fernanda y el area 468.73 de airGR."
  )
  
  # 6. Ejecutar respetando las dependencias entre etapas.
  set.seed(20261020)
  
  for (nombre in scripts[-1]) {
    ejecutar(nombre)
  }
  
  message(
    "\nTodos los scripts terminaron. ",
    "Revisa run_all_estado.csv y alcance_run_all.txt en 04_metadata."
  )
  
  invisible(registro)
}

ejecutar_proyecto_tp()