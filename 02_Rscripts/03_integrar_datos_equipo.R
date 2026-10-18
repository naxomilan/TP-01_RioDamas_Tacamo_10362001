# DATOS PARA BUDYKO - RIO DAMAS EN TACAMO
# Ejecutar desde el proyecto .Rproj.
# Solo R base. PET de CAMELS provisional.
# No calcula todavia ET ni el balance de Budyko.
# Conserva los datos originales y distingue los caudales estimados.


# 1. LEER LOS DATOS

clima <- read.csv("01_data/processed/clima_CR2METv25_10362001_daily_1960-2021.csv")
caudal <- read.csv("01_data/processed/caudal_diario_dga_10362001.csv")
pet <- read.csv("01_data/raw/pet_hargreaves_day.csv")
derechos <- read.csv("01_data/processed/base_anual_derechos_superficiales.csv")

# Seleccionar las columnas climaticas.
clima <- clima[, c("fecha", "P_mm", "Tmax_degC", "Tmin_degC", "Tmed_degC")]

# Indicar que representa cada columna y sus unidades.
names(clima) <- c("fecha", "precipitacion_mm_dia", "temperatura_maxima_C","temperatura_minima_C", "temperatura_media_C")

# Seleccionar fecha y caudal.
caudal <- caudal[, c("FECHA", "Caudal_diario")]

# Nombrar las columnas del caudal original.
names(caudal) <- c("fecha", "caudal_m3_s")

# Seleccionar PET de la cuenca.
pet <- pet[, c("date", "X10362001")]

# Nombrar las columnas de PET.
names(pet) <- c("fecha", "pet_mm_dia")

# Convertir las fechas del clima.
clima$fecha <- as.Date(clima$fecha)

# Convertir las fechas del caudal.
caudal$fecha <- as.Date(caudal$fecha)

# Convertir las fechas de PET.
pet$fecha <- as.Date(pet$fecha)

# Usar el area del poligono CAMELS.
area_km2 <- 466.7784


# 2. UNIR LAS SERIES
# Incluimos enero-diciembre para contar tambien los dias
# faltantes al comienzo y final de los anos extremos.

# Encontrar el comienzo del periodo compartido.
inicio_comun <- max(min(clima$fecha), min(caudal$fecha), min(pet$fecha))

# Encontrar el final del periodo compartido.
fin_comun <- min(max(clima$fecha), max(caudal$fecha), max(pet$fecha))

# Comenzar el calendario el 1 de enero del primer ano.
inicio_calendario <- as.Date(paste0(format(inicio_comun, "%Y"), "-01-01"))

# Terminar el calendario el 31 de diciembre del ultimo ano.
fin_calendario <- as.Date(paste0(format(fin_comun, "%Y"), "-12-31"))

# Crear una fila por cada dia.
datos_budyko <- data.frame(fecha = seq(inicio_calendario, fin_calendario, by = "day"))

# Incorporar el clima manteniendo todas las fechas.
datos_budyko <- merge(datos_budyko, clima, by = "fecha", all.x = TRUE)

# Incorporar el caudal original.
datos_budyko <- merge(datos_budyko, caudal, by = "fecha", all.x = TRUE)

# Incorporar la PET.
datos_budyko <- merge(datos_budyko, pet, by = "fecha", all.x = TRUE)

# Ordenar las filas por fecha.
datos_budyko <- datos_budyko[order(datos_budyko$fecha), ]

# Identificar la cuenca.
datos_budyko$codigo_cuenca <- "10362001"

# Obtener el ano de cada fecha.
datos_budyko$anio <- as.integer(format(datos_budyko$fecha, "%Y"))


# 3. CONTAR LOS FALTANTES POR ANO
# Los faltantes se cuentan antes de realizar cualquier relleno.

# Marcar los dias sin precipitacion.
datos_budyko$falta_P <- is.na(datos_budyko$precipitacion_mm_dia)

# Marcar los dias sin PET.
datos_budyko$falta_PET <- is.na(datos_budyko$pet_mm_dia)

# Marcar los dias sin caudal original.
datos_budyko$falta_Q <- is.na(datos_budyko$caudal_m3_s)

# Contar los faltantes de cada variable por ano.
tabla_budyko <- aggregate(cbind(falta_P, falta_PET, falta_Q) ~ anio,datos_budyko, sum)

# Dar nombres claros al resumen.
names(tabla_budyko) <- c("anio", "faltantes_P", "faltantes_PET", "faltantes_Q_originales")

# Contar los dias del ano, incluyendo los anos bisiestos.
tabla_budyko$dias_esperados <- as.integer(as.Date(paste0(tabla_budyko$anio + 1, "-01-01")) -as.Date(paste0(tabla_budyko$anio, "-01-01")))

# Autorizar el relleno solo con 1 a 3 faltantes de Q y clima completo.
tabla_budyko$permite_relleno_Q <- with(tabla_budyko,faltantes_Q_originales >= 1 &faltantes_Q_originales <= 3 &
    faltantes_P == 0 &faltantes_PET == 0)

# Mostrar los anos que tienen algun faltante.
cat("\nFALTANTES ORIGINALES POR ANO:\n")

# Imprimir los conteos de las tres variables.
print(tabla_budyko[tabla_budyko$faltantes_P > 0 |tabla_budyko$faltantes_PET > 0 
                   |tabla_budyko$faltantes_Q_originales > 0,],row.names = FALSE)


# 4. IDENTIFICAR LOS INTERVALOS FALTANTES
# Cada fila indica la variable, las fechas y los dias consecutivos.
# Si un hueco cruza diciembre-enero, se conserva como un solo intervalo.

# Preparar una tabla vacia para los intervalos.
periodos_faltantes <- data.frame(variable = character(),inicio = as.Date(character())
                                 ,fin = as.Date(character()),dias = integer())

# Indicar las tres variables que vamos a revisar.
variables_revision <- c("precipitacion_mm_dia", "pet_mm_dia", "caudal_m3_s")

# Revisar los intervalos faltantes de cada variable.
for (variable in variables_revision) {
  
  # Identificar grupos consecutivos de datos presentes o ausentes.
  bloques <- rle(is.na(datos_budyko[[variable]]))
  
  # Encontrar la ultima fila de cada grupo.
  finales <- cumsum(bloques$lengths)
  
  # Encontrar la primera fila de cada grupo.
  comienzos <- finales - bloques$lengths + 1
  
  # Seleccionar los grupos que corresponden a faltantes.
  grupos_faltantes <- which(bloques$values)
  
  # Agregar las fechas y duraciones de esos grupos.
  periodos_faltantes <- rbind(
    periodos_faltantes,
    data.frame(
      variable = rep(variable, length(grupos_faltantes)),
      inicio = datos_budyko$fecha[comienzos[grupos_faltantes]],
      fin = datos_budyko$fecha[finales[grupos_faltantes]],
      dias = bloques$lengths[grupos_faltantes]))
}

# Mostrar los periodos encontrados.
cat("\nINTERVALOS CON DATOS FALTANTES:\n")

# Imprimir cada intervalo con su duracion.
print(periodos_faltantes, row.names = FALSE)


# 5. RELLENAR SOLO DIAS AISLADOS DE CAUDAL
# Ambos vecinos deben ser datos originales.
# No usamos una estimacion para generar otra estimacion.
# Los huecos consecutivos y los anos con mas de 3 faltantes quedan como NA.

# Obtener el caudal original del dia anterior.
caudal_anterior <- c(NA, head(datos_budyko$caudal_m3_s, -1))

# Obtener el caudal original del dia siguiente.
caudal_siguiente <- c(tail(datos_budyko$caudal_m3_s, -1), NA)

# Seleccionar los anos que cumplen el criterio anual.
anios_rellenables <- tabla_budyko$anio[tabla_budyko$permite_relleno_Q]

# Encontrar los dias faltantes aislados dentro de esos anos.
filas_relleno <- which(datos_budyko$anio %in% anios_rellenables &datos_budyko$falta_Q &
                         !is.na(caudal_anterior) &!is.na(caudal_siguiente))

# Copiar el caudal original a una columna de analisis.
datos_budyko$caudal_analisis_m3_s <- datos_budyko$caudal_m3_s

# Estimar cada dia mediante el promedio de sus dos vecinos.
datos_budyko$caudal_analisis_m3_s[filas_relleno] <- (caudal_anterior[filas_relleno] + caudal_siguiente[filas_relleno]) / 2

# Marcar inicialmente todos los dias como observados o sin rellenar.
datos_budyko$caudal_estimado <- FALSE

# Identificar los dias que fueron estimados.
datos_budyko$caudal_estimado[filas_relleno] <- TRUE

# Preparar una tabla para explicar cada estimacion.
detalle_relleno <- data.frame(fecha = datos_budyko$fecha[filas_relleno],anterior_m3_s = caudal_anterior[filas_relleno],
  siguiente_m3_s = caudal_siguiente[filas_relleno],estimado_m3_s = datos_budyko$caudal_analisis_m3_s[filas_relleno])

# Mostrar los caudales utilizados en cada promedio.
cat("\nDIAS RELLENADOS:\n")

# Imprimir las estimaciones.
print(detalle_relleno, row.names = FALSE)

# Convertir el caudal a lamina diaria de escorrentia.
datos_budyko$escorrentia_mm_dia <- datos_budyko$caudal_analisis_m3_s * 86400 / (area_km2 * 1000)

# Identificar los dias con las tres variables originales.
datos_budyko$P_PET_Q_originales <- complete.cases(datos_budyko[,c("precipitacion_mm_dia", "pet_mm_dia", "caudal_m3_s")])

# Identificar los dias completos despues del relleno.
datos_budyko$P_PET_Q_disponibles <- complete.cases(datos_budyko[,c("precipitacion_mm_dia", "pet_mm_dia", "caudal_analisis_m3_s")])


# 6. RESUMIR LA COBERTURA Y CALCULAR LOS VALORES ANUALES
# Solo calculamos totales cuando P, PET y Q cubren todo el ano.
# No convertimos los datos faltantes en ceros.

# Contar dias originales, disponibles y estimados.
conteos <- aggregate(cbind(P_PET_Q_originales, P_PET_Q_disponibles, caudal_estimado) ~ anio,datos_budyko, sum)

# Nombrar los conteos.
names(conteos) <- c("anio", "dias_originales", "dias_disponibles", "dias_estimados")

# Agregar los conteos al resumen anual.
tabla_budyko <- merge(tabla_budyko, conteos, by = "anio")

# Contar cuantos faltantes de caudal permanecen.
tabla_budyko$faltantes_Q_finales <-tabla_budyko$faltantes_Q_originales - tabla_budyko$dias_estimados

# Calcular la cobertura conjunta original.
tabla_budyko$cobertura_original_porcentaje <- round(100 * tabla_budyko$dias_originales / tabla_budyko$dias_esperados, 2)

# Calcular la cobertura conjunta despues del relleno.
tabla_budyko$cobertura_porcentaje <- round(100 * tabla_budyko$dias_disponibles / tabla_budyko$dias_esperados, 2)

# Identificar los anos completos originales.
tabla_budyko$anio_completo_original <-tabla_budyko$dias_originales == tabla_budyko$dias_esperados

# Identificar los anos completos despues del relleno.
tabla_budyko$anio_completo <-tabla_budyko$dias_disponibles == tabla_budyko$dias_esperados

# Explicar los faltantes restantes de los anos excluidos.
tabla_budyko$observacion <- paste0("Excluido: faltan P=", tabla_budyko$faltantes_P,
                                   "; PET=", tabla_budyko$faltantes_PET,
                                   "; Q=", tabla_budyko$faltantes_Q_finales, " dias")

# Identificar los anos que no necesitaron estimaciones.
tabla_budyko$observacion[tabla_budyko$anio_completo_original] <- "Completo sin relleno"

# Identificar los anos recuperados con estimaciones.
tabla_budyko$observacion[tabla_budyko$anio_completo & tabla_budyko$dias_estimados > 0] <- "Completo con relleno de Q; revisar estimaciones"

# Agregar el codigo de la cuenca.
tabla_budyko$codigo_cuenca <- "10362001"

# Registrar el area utilizada.
tabla_budyko$area_km2 <- area_km2

# Preparar la columna de precipitacion anual.
tabla_budyko$precipitacion_mm_anio <- NA_real_

# Preparar la columna de PET anual.
tabla_budyko$pet_mm_anio <- NA_real_

# Preparar la columna de caudal medio.
tabla_budyko$caudal_medio_m3_s <- NA_real_

# Preparar la columna de volumen anual.
tabla_budyko$volumen_escurrido_m3_anio <- NA_real_

# Preparar la columna de escorrentia anual.
tabla_budyko$escorrentia_mm_anio <- NA_real_

# Calcular solamente los anos que quedaron completos.
for (fila in which(tabla_budyko$anio_completo)) {
  
  # Seleccionar los dias del ano.
  dias_anio <- datos_budyko[datos_budyko$anio == tabla_budyko$anio[fila],]
  
  # Sumar la precipitacion diaria.
  tabla_budyko$precipitacion_mm_anio[fila] <-sum(dias_anio$precipitacion_mm_dia)
  
  # Sumar la PET diaria.
  tabla_budyko$pet_mm_anio[fila] <- sum(dias_anio$pet_mm_dia)
  
  # Calcular el caudal medio anual.
  tabla_budyko$caudal_medio_m3_s[fila] <- mean(dias_anio$caudal_analisis_m3_s)
  
  # Calcular el volumen escurrido durante todo el ano.
  tabla_budyko$volumen_escurrido_m3_anio[fila] <-sum(dias_anio$caudal_analisis_m3_s) * 86400
  
  # Sumar la lamina diaria de escorrentia.
  tabla_budyko$escorrentia_mm_anio[fila] <-sum(dias_anio$escorrentia_mm_dia)
  }


# 7. INCORPORAR DERECHOS Y GUARDAR
# Los derechos registrados no representan consumo real.
# Guardamos las mismas bases y una tabla adicional de intervalos faltantes.

# Seleccionar las columnas necesarias de derechos.
derechos <- derechos[, c("codigo_cuenca", "anio","derechos_superficiales_L_s", "derechos_superficiales_m3_s")]

# Unir derechos y resultados anuales.
tabla_budyko <- merge(tabla_budyko, derechos,by = c("codigo_cuenca", "anio"), all.x = TRUE)

# Registrar la fuente de precipitacion.
tabla_budyko$fuente_precipitacion <- "CR2MET v2.5; poligono CAMELS"

# Registrar la PET provisional.
tabla_budyko$fuente_pet <- "Hargreaves CAMELS; uso provisional"

# Registrar la fuente del caudal.
tabla_budyko$fuente_caudal <- "DGA; serie procesada por Alexis"

# Registrar la fuente del area.
tabla_budyko$fuente_area <- "CAMELS; 466.7784 km2"

# Documentar el criterio de estimacion.
tabla_budyko$tratamiento_caudal <- paste("Promedio de vecinos originales para dias aislados;","maximo 3 faltantes de Q por ano y P/PET completas")

# Crear la carpeta de tablas si hace falta.
dir.create( "03_outputs/tables/control_calidad",recursive = TRUE, showWarnings = FALSE)

# Guardar los intervalos faltantes originales de P, PET y Q.
write.csv(periodos_faltantes,"03_outputs/tables/control_calidad/periodos_faltantes_budyko.csv",row.names = FALSE)

# Guardar originales, estimaciones y marcas en la misma base diaria.
write.csv(datos_budyko,"01_data/processed/base_diaria_budyko.csv",row.names = FALSE)

# Guardar conteos, cobertura y resultados en la misma base anual.
write.csv(tabla_budyko,"01_data/processed/base_anual_budyko.csv",row.names = FALSE)

# Mostrar el numero de anos completos originales.
cat("\nAnos completos sin relleno:",sum(tabla_budyko$anio_completo_original), "\n")

# Mostrar el numero de anos completos despues del relleno.
cat("Anos completos con relleno:",sum(tabla_budyko$anio_completo), "\n")


# Mostrar los anos que se pueden utilizar.
cat("Anos utilizables:",tabla_budyko$anio[tabla_budyko$anio_completo], "\n")

# Mostrar la decision para cada ano.
print(tabla_budyko[, c("anio", "faltantes_Q_originales", "dias_estimados",
    "faltantes_Q_finales", "anio_completo", "observacion")],row.names = FALSE)


# 8. GRAFICOS PARA REVISAR LAS ESTIMACIONES
# La primera pagina resume los faltantes anuales.
# Las siguientes muestran cada relleno y la lluvia de esos dias.

# Crear la carpeta de figuras si hace falta.
dir.create( "03_outputs/figures/control_calidad",recursive = TRUE, showWarnings = FALSE)

# Abrir el PDF; debe estar cerrado en Acrobat.
pdf("03_outputs/figures/control_calidad/revision_dias_faltantes.pdf",width = 9, height = 7)

# Preparar dos graficos por pagina.
par(mfrow = c(2, 1), mar = c(4, 4, 3, 1))

# Mostrar los dias faltantes originales de caudal.
plot(tabla_budyko$anio, tabla_budyko$faltantes_Q_originales,type = "h", lwd = 3,
     ylim = c(0, max(3, tabla_budyko$faltantes_Q_originales)),xlab = "Ano",
     ylab = "Dias sin caudal",main = "Faltantes originales de caudal por ano")

# Marcar el limite anual elegido.
abline(h = 3, col = "red", lty = 2)

# Explicar la linea roja.
legend("topright", "Limite de 3 dias por ano",col = "red", lty = 2, bty = "n")

# Comparar la cobertura original y la cobertura con relleno.
plot(tabla_budyko$anio, tabla_budyko$cobertura_original_porcentaje,type = "b", pch = 1, ylim = c(0, 100),
  xlab = "Ano", ylab = "Cobertura conjunta (%)",main = "Disponibilidad de P, PET y Q")

# Agregar la cobertura despues del relleno.
points(tabla_budyko$anio, tabla_budyko$cobertura_porcentaje,col = "red", pch = 16)

# Explicar los simbolos.
legend("bottomleft", c("Original", "Con relleno de Q"),col = c("black", "red"), pch = c(1, 16), bty = "n")

# Revisar cada dia que fue rellenado.
for (fila in filas_relleno) {
  
  # Obtener la fecha estimada.
  fecha_revision <- datos_budyko$fecha[fila]
  
  # Seleccionar siete dias antes y siete despues.
  ventana <- datos_budyko[datos_budyko$fecha >= fecha_revision - 7 &datos_budyko$fecha <= fecha_revision + 7,]
  
  # Mostrar el caudal de analisis como una linea.
  plot(ventana$fecha, ventana$caudal_analisis_m3_s,type = "l",xlab = "Fecha",
       ylab = "Caudal (m3/s)",main = paste("Revision del relleno:", fecha_revision))
  
  # Mostrar los caudales originales con circulos.
  points(ventana$fecha, ventana$caudal_m3_s, pch = 1)
  
  # Mostrar los caudales estimados en rojo.
  points(ventana$fecha[ventana$caudal_estimado],ventana$caudal_analisis_m3_s[ventana$caudal_estimado],col = "red", pch = 16)
  
  # Explicar los puntos del grafico.
  legend("topright", c("Observado", "Estimado"),col = c("black", "red"), pch = c(1, 16), bty = "n")
  
  # Mostrar la precipitacion alrededor del relleno.
  plot(ventana$fecha, ventana$precipitacion_mm_dia,type = "h",xlab = "Fecha", ylab = "Lluvia (mm/dia)",main = "Precipitacion durante la revision")
  
  # Marcar la fecha del caudal estimado.
  abline(v = as.numeric(fecha_revision), col = "red", lty = 2)
  
  # Explicar la linea de referencia.
  legend("topright", "Fecha del caudal estimado",col = "red", lty = 2, bty = "n")
}

# Cerrar el PDF para terminar de guardarlo.
dev.off()