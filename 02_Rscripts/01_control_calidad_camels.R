# CONTROL DE CALIDAD - RIO DAMAS EN TACAMO
# Abrir el proyecto .Rproj y ejecutar el script completo.
# Cerrar el PDF de graficos antes de ejecutarlo nuevamente.
# Los archivos originales no se modifican.


# 1. LEER LA CONFIGURACION
# Obtener el codigo y el area de la cuenca.

configuracion <- read.csv("06_config/parametros.csv",colClasses = "character")

codigo_cuenca <- configuracion$valor[configuracion$parametro == "codigo_camels"]

atributos <- read.csv("01_data/raw/catchment_attributes.csv",header = FALSE,colClasses = "character")

names(atributos) <- c("atributo", "valor", "descripcion")

area_km2 <- as.numeric(atributos$valor[atributos$atributo == "area_km2"])


# 2. PREPARAR LAS CARPETAS
# Si ya existen, se conservan.

carpeta_tablas <- "03_outputs/tables/control_calidad"
carpeta_graficos <- "03_outputs/figures/control_calidad"
carpeta_procesados <- "01_data/processed"

dir.create(carpeta_tablas, recursive = TRUE, showWarnings = FALSE)
dir.create(carpeta_graficos, recursive = TRUE, showWarnings = FALSE)
dir.create(carpeta_procesados, recursive = TRUE, showWarnings = FALSE)
dir.create("04_metadata", showWarnings = FALSE)


# 3. LEER LAS SERIES Y RESUMIR SU CALIDAD
# Trabajar con precipitacion, PET, caudal y derechos superficiales.
# NA significa dato faltante.

archivos <- c("precip_cr2met_day.csv","pet_hargreaves_day.csv","q_m3s_day.csv","cons_sf_wr_year.csv")

nombres <- c("Precipitacion CR2MET","PET Hargreaves","Caudal","Derechos superficiales consuntivos")

unidades <- c("mm/dia", "mm/dia", "m3/s", "L/s")
frecuencias <- c("day", "day", "day", "year")

series <- list()
resumen <- data.frame()

# Repetir el procedimiento para los cuatro archivos.
for (numero in 1:4) {
  
  archivo_leido <- read.csv(
    file.path("01_data/raw", archivos[numero]),
    check.names = FALSE,
    colClasses = "character",
    na.strings = c("", "NA")
  )
  
  fechas <- as.Date(archivo_leido$date, format = "%Y-%m-%d")
  valores <- as.numeric(archivo_leido[[codigo_cuenca]])
  
  # Identificar negativos y datos disponibles.
  negativos <- !is.na(valores) & valores < 0
  utiles <- !is.na(valores) & !negativos
  
  primer_dato <- min(fechas[utiles])
  ultimo_dato <- max(fechas[utiles])
  
  # Construir el calendario entre la primera y ultima fecha.
  calendario <- seq(
    min(fechas),
    max(fechas),
    by = frecuencias[numero]
  )
  
  # Resumir faltantes, ceros y extremos.
  # Los faltantes internos estan entre el primer y ultimo dato util.
  resumen <- rbind(resumen, data.frame(
    archivo = archivos[numero],
    unidad = unidades[numero],
    primer_dato,
    ultimo_dato,
    observaciones_utiles = sum(utiles),
    faltantes = sum(is.na(valores)),
    faltantes_internos = sum(
      is.na(valores) &
        fechas >= primer_dato &
        fechas <= ultimo_dato
    ),
    fechas_ausentes = sum(!calendario %in% fechas),
    fechas_repetidas = sum(duplicated(fechas)),
    desordenado = is.unsorted(fechas),
    negativos = sum(negativos),
    ceros = sum(valores == 0, na.rm = TRUE),
    minimo = min(valores[utiles]),
    maximo = max(valores[utiles])
  ))
  
  # Crear una copia de trabajo.
  # Los negativos pasan a NA; los ceros y extremos se conservan.
  copia <- data.frame(
    fecha = fechas,
    original = valores,
    valor = valores
  )
  
  copia$valor[negativos] <- NA
  
  # Completar el calendario y ordenar por fecha.
  # Las fechas sin valor quedan como NA.
  series[[numero]] <- merge(
    data.frame(fecha = calendario),
    copia,
    by = "fecha",
    all.x = TRUE
  )
}


# 4. UNIR LAS SERIES DIARIAS
# Unir por fecha y conservar el calendario comun.

precipitacion <- series[[1]][, c("fecha", "valor")]
pet <- series[[2]][, c("fecha", "valor")]
caudal <- series[[3]][, c("fecha", "valor")]

names(precipitacion)[2] <- "precipitacion"
names(pet)[2] <- "pet"
names(caudal)[2] <- "caudal"

diarios <- merge(precipitacion, pet, by = "fecha")
diarios <- merge(diarios, caudal, by = "fecha")

diarios$anio <- as.integer(format(diarios$fecha, "%Y"))

# Identificar dias con P, PET y Q disponibles.
diarios$datos_completos <- complete.cases(
  diarios[, c("precipitacion", "pet", "caudal")]
)


# 5. CALCULAR LA COBERTURA ANUAL
# Usar anos de enero a diciembre.
# Seleccionar los anos que tienen las tres variables completas.

anios_con_datos <- diarios$anio[diarios$datos_completos]

cobertura <- data.frame()

for (anio_revision in min(anios_con_datos):max(anios_con_datos)) {
  
  datos_anio <- diarios[diarios$anio == anio_revision, ]
  
  inicio_anio <- as.Date(paste0(anio_revision, "-01-01"))
  fin_anio <- as.Date(paste0(anio_revision, "-12-31"))
  
  # Considerar 365 o 366 dias segun corresponda.
  dias_esperados <- as.integer(fin_anio - inicio_anio) + 1
  
  # Contar fechas distintas con las tres variables disponibles.
  dias_comunes <- length(unique(
    datos_anio$fecha[datos_anio$datos_completos]
  ))
  
  cobertura <- rbind(cobertura, data.frame(
    anio = anio_revision,
    dias_esperados,
    dias_P = length(unique(
      datos_anio$fecha[!is.na(datos_anio$precipitacion)]
    )),
    dias_PET = length(unique(
      datos_anio$fecha[!is.na(datos_anio$pet)]
    )),
    dias_Q = length(unique(
      datos_anio$fecha[!is.na(datos_anio$caudal)]
    )),
    dias_comunes,
    cobertura_porcentaje = round(
      100 * dias_comunes / dias_esperados, 2
    ),
    usar_analisis_preliminar = dias_comunes == dias_esperados
  ))
}

cobertura$decision <- ifelse(
  cobertura$usar_analisis_preliminar,
  "Conservar para analisis preliminar",
  "Excluir del balance anual por faltantes"
)

anios_seleccionados <- cobertura$anio[
  cobertura$usar_analisis_preliminar
]


# 6. IDENTIFICAR EXTREMOS
# Buscar maximo P, maximo Q y minimo Q.
# Conservar estos valores: no son errores automaticamente.

extremos <- data.frame()

variables_extremos <- c("precipitacion", "caudal", "caudal")
tipos_extremos <- c("Maximo P", "Maximo Q", "Minimo Q")

for (numero in 1:3) {
  
  valores_extremo <- diarios[[variables_extremos[numero]]]
  valor_extremo <- max(valores_extremo, na.rm = TRUE)
  
  if (numero == 3) {
    valor_extremo <- min(valores_extremo, na.rm = TRUE)
  }
  
  fechas_extremo <- diarios$fecha[
    which(valores_extremo == valor_extremo)
  ]
  
  extremos <- rbind(extremos, data.frame(
    tipo = tipos_extremos[numero],
    inicio = fechas_extremo,
    fin = fechas_extremo,
    dias = 1L,
    valor = valor_extremo,
    unidad = c("mm/dia", "m3/s", "m3/s")[numero],
    decision = "Conservar; revisar contexto"
  ))
}


# 7. IDENTIFICAR TRAMOS SIN CAUDAL
# Buscar dias consecutivos sin Q dentro de su periodo util.
# rle agrupa los dias faltantes y disponibles.

registro_q <- caudal[
  caudal$fecha >= resumen$primer_dato[3] &
    caudal$fecha <= resumen$ultimo_dato[3],
]

grupos <- rle(is.na(registro_q$caudal))

# Ubicar el inicio y final de cada grupo.
finales <- cumsum(grupos$lengths)
inicios <- finales - grupos$lengths + 1
faltantes <- which(grupos$values)

tramos_faltantes <- data.frame(
  tipo = rep("Tramo sin Q util", length(faltantes)),
  inicio = registro_q$fecha[inicios[faltantes]],
  fin = registro_q$fecha[finales[faltantes]],
  dias = grupos$lengths[faltantes],
  valor = rep(NA_real_, length(faltantes)),
  unidad = rep("m3/s", length(faltantes)),
  decision = rep("No rellenar", length(faltantes))
)

# Reunir extremos y faltantes en una tabla.
observaciones <- rbind(extremos, tramos_faltantes)
observaciones <- observaciones[order(observaciones$inicio), ]


# 8. PREPARAR LAS BASES
# Una fila por dia para P, PET y Q.

base_diaria <- data.frame(
  codigo_cuenca,
  fecha = diarios$fecha,
  anio = diarios$anio,
  mes = as.integer(format(diarios$fecha, "%m")),
  precipitacion_cr2met_mm_dia = diarios$precipitacion,
  pet_hargreaves_mm_dia = diarios$pet,
  caudal_m3_s = diarios$caudal,
  datos_completos = diarios$datos_completos,
  anio_completo = diarios$anio %in% anios_seleccionados,
  revisar_extremo_P = diarios$fecha %in%
    extremos$inicio[extremos$tipo == "Maximo P"],
  revisar_extremo_Q = diarios$fecha %in%
    extremos$inicio[extremos$tipo != "Maximo P"]
)

# Una fila por ano para derechos superficiales.
# Convertir L/s a m3/s dividiendo por 1000.
base_derechos <- data.frame(
  codigo_cuenca,
  anio = as.integer(format(series[[4]]$fecha, "%Y")),
  fecha_referencia = series[[4]]$fecha,
  derechos_superficiales_L_s = series[[4]]$valor,
  derechos_superficiales_m3_s = series[[4]]$valor / 1000
)


# 9. REGISTRAR LAS FUENTES
# Guardar origen, unidades y decisiones.
# Las fechas y versiones desconocidas quedan indicadas.

archivos_fuente <- c(archivos, "catchment_attributes.csv")

fuentes <- data.frame(
  codigo_cuenca,
  archivo = archivos_fuente,
  producto = c(nombres, "Atributos CAMELS-CL"),
  unidad = c(unidades, "Varias; area en km2"),
  frecuencia = c("Diaria", "Diaria", "Diaria", "Anual", "Atributos"),
  primer_dato = c(as.character(resumen$primer_dato), NA_character_),
  ultimo_dato = c(as.character(resumen$ultimo_dato), NA_character_),
  version = "No documentada en los CSV",
  fecha_descarga = NA_character_,
  url = "https://camels.cr2.cl/",
  referencia = "https://doi.org/10.5194/hess-22-5817-2018"
)

# Registrar una huella para identificar los originales utilizados.
fuentes$md5 <- unname(
  tools::md5sum(file.path("01_data/raw", archivos_fuente))
)

fuentes$nota <- c(
  "Producto de trabajo; version CR2MET por confirmar",
  "PET Hargreaves; no es ET real",
  "Caudal medio diario; faltantes sin rellenar",
  "Acumulados: supuesto por confirmar; no consumo; no sumar entre anos",
  paste("Area CAMELS:", area_km2, "km2; validacion espacial pendiente")
)

fuentes$criterio <-
  "Anos calendario completos; sin relleno; extremos conservados y senalados"

fuentes$version_R <- R.version.string


# 10. GUARDAR LAS TABLAS

write.csv(base_diaria,file.path(carpeta_procesados, "base_diaria_P_PET_Q.csv"),row.names = FALSE)

write.csv(base_derechos,file.path(carpeta_procesados, "base_anual_derechos_superficiales.csv"),row.names = FALSE)

write.csv(resumen,file.path(carpeta_tablas, "resumen_series.csv"),row.names = FALSE)

write.csv(cobertura,file.path(carpeta_tablas, "cobertura_P_PET_Q.csv"),row.names = FALSE)

write.csv(observaciones,file.path(carpeta_tablas, "observaciones_revision.csv"),row.names = FALSE)

write.csv(fuentes,"04_metadata/fuentes_control_calidad.csv",row.names = FALSE)


# 11. GUARDAR LOS GRAFICOS EN UN PDF

pdf(file.path(carpeta_graficos, "graficos_revision.pdf"),width = 11,height = 6)

# Graficar las cuatro series originales.
for (numero in 1:4) {
  
  grafico_serie <- series[[numero]]
  
  fechas_validas <- grafico_serie$fecha[
    !is.na(grafico_serie$original)
  ]
  
  grafico_serie <- grafico_serie[
    grafico_serie$fecha >= min(fechas_validas) &
      grafico_serie$fecha <= max(fechas_validas),
  ]
  
  plot(
    grafico_serie$fecha,
    grafico_serie$original,
    type = "l",
    col = "steelblue",
    main = nombres[numero],
    xlab = "Fecha",
    ylab = unidades[numero]
  )
}

# Graficar la cobertura anual.
colores_cobertura <- ifelse(
  cobertura$usar_analisis_preliminar,
  "steelblue", "darkorange"
)

barplot(
  cobertura$cobertura_porcentaje,
  names.arg = cobertura$anio,
  las = 2,
  cex.names = 0.7,
  col = colores_cobertura,
  ylim = c(0, 110),
  main = "Cobertura P, PET y Q: enero-diciembre",
  ylab = "Dias completos (%)"
)

abline(h = 100, lty = 2)

# Comparar las tres series durante el periodo con datos comunes.
fechas_completas <- diarios$fecha[diarios$datos_completos]

grafico_comun <- diarios[
  diarios$fecha >= min(fechas_completas) &
    diarios$fecha <= max(fechas_completas),
]

variables_grafico <- c("precipitacion", "pet", "caudal")

par(mfrow = c(3, 1), mar = c(3, 4, 2, 1))

for (numero in 1:3) {
  
  plot(
    grafico_comun$fecha,
    grafico_comun[[variables_grafico[numero]]],
    type = "l",
    col = "steelblue",
    main = nombres[numero],
    xlab = "Fecha",
    ylab = unidades[numero]
  )
}

# Mostrar siete dias antes y despues de cada extremo.
for (fila_extremo in seq_len(nrow(extremos))) {
  
  fecha_extremo <- extremos$inicio[fila_extremo]
  
  ventana_extremo <- diarios[
    diarios$fecha >= fecha_extremo - 7 &
      diarios$fecha <= fecha_extremo + 7,
  ]
  
  par(mfrow = c(2, 1), mar = c(4, 4, 3, 1))
  
  for (numero in c(1, 3)) {
    
    titulo <- paste(
      extremos$tipo[fila_extremo],
      fecha_extremo,
      "-",
      nombres[numero]
    )
    
    if (any(!is.na(ventana_extremo[[variables_grafico[numero]]]))) {
      
      plot(
        ventana_extremo$fecha,
        ventana_extremo[[variables_grafico[numero]]],
        type = "o",
        pch = 16,
        col = "steelblue",
        main = titulo,
        xlab = "Fecha",
        ylab = unidades[numero]
      )
      
      abline(
        v = as.numeric(fecha_extremo),
        col = "red",
        lty = 2
      )
      
    } else {
      
      plot.new()
      title(titulo)
      text(0.5, 0.5, "Sin datos en esta ventana")
    }
  }
}

# Mostrar los diez tramos mas largos sin caudal.
par(mfrow = c(1, 1))

if (nrow(tramos_faltantes) > 0) {
  
  tramos_mayores <- head(
    tramos_faltantes[order(-tramos_faltantes$dias), ],
    10
  )
  
  par(mar = c(5, 13, 4, 2))
  
  barplot(
    rev(tramos_mayores$dias),
    horiz = TRUE,
    las = 1,
    col = "darkorange",
    names.arg = rev(paste(
      tramos_mayores$inicio,
      tramos_mayores$fin,
      sep = " a "
    )),
    cex.names = 0.8,
    main = "Tramos internos mas largos sin Q",
    xlab = "Dias"
  )
}

# Terminar de guardar el PDF.
dev.off()


# 12. MOSTRAR RESULTADOS EN CONSOLA

print(resumen)
print(cobertura)
print(extremos)

cat(
  "\nAnos completos:",
  paste(anios_seleccionados, collapse = ", "),
  "\n"
)

cat("Cantidad de anos:", length(anios_seleccionados), "\n")

cat(
  "Tramos sin Q:", nrow(tramos_faltantes),
  "- Dias:", sum(tramos_faltantes$dias), "\n"
)

# Revisar el resumen antes de continuar con el segundo script.
# Si aparecen fechas repetidas, hay que resolverlas antes de sumar.
# El area y el periodo deben acordarse con el equipo.