# PREPARACION ANUAL Y GRAFICOS - RIO DAMAS EN TACAMO
# Ejecutar despues del control de calidad.
# Solo R base. Todavia no calculamos Budyko ni el balance.


# 1. LEER LOS DATOS
# Usar las tablas generadas por el primer script.

datos_diarios <- read.csv("01_data/processed/base_diaria_P_PET_Q.csv")

derechos_anuales <- read.csv("01_data/processed/base_anual_derechos_superficiales.csv")

tabla_cobertura <- read.csv("03_outputs/tables/control_calidad/cobertura_P_PET_Q.csv")

# Leer el area desde los atributos de CAMELS.
atributos_cuenca <- read.csv("01_data/raw/catchment_attributes.csv",header = FALSE,colClasses = "character")

superficie_km2 <- as.numeric(atributos_cuenca$V2[atributos_cuenca$V1 == "area_km2"])

identificador_cuenca <- unique(datos_diarios$codigo_cuenca)


# 2. PREPARAR LA TABLA ANUAL
# Conservar la cobertura y los motivos de exclusion.
# Crear columnas vacias para guardar los resultados.
# NA significa resultado no disponible.

base_anual <- tabla_cobertura

base_anual$codigo_cuenca <- identificador_cuenca
base_anual$area_km2 <- superficie_km2

base_anual$estado_area <- "Area CAMELS provisional; confirmar con integrante 2"

base_anual$precipitacion_mm_anio <- NA_real_
base_anual$pet_mm_anio <- NA_real_
base_anual$caudal_medio_m3_s <- NA_real_
base_anual$volumen_escurrido_m3_anio <- NA_real_
base_anual$escorrentia_mm_anio <- NA_real_


# 3. CALCULAR LOS VALORES ANUALES
# Usar solamente los anos completos de enero a diciembre.
# Repetir los calculos para cada ano seleccionado.

filas_completas <- which(base_anual$usar_analisis_preliminar)

for (fila_anual in filas_completas) {
  
  anio_calculo <- base_anual$anio[fila_anual]
  
  registro_anual <- datos_diarios[
    datos_diarios$anio == anio_calculo,
  ]
  
  # Sumar la precipitacion diaria para obtener mm/anio.
  base_anual$precipitacion_mm_anio[fila_anual] <- sum(
    registro_anual$precipitacion_cr2met_mm_dia
  )
  
  # Sumar la evapotranspiracion potencial diaria.
  base_anual$pet_mm_anio[fila_anual] <- sum(
    registro_anual$pet_hargreaves_mm_dia
  )
  
  # Promediar los caudales medios diarios.
  base_anual$caudal_medio_m3_s[fila_anual] <- mean(
    registro_anual$caudal_m3_s
  )
  
  # Un dia tiene 86400 segundos.
  # Caudal medio diario por segundos del dia entrega volumen diario.
  # Sumar esos volumenes entrega el volumen anual en m3.
  volumen_anual <- sum(registro_anual$caudal_m3_s * 86400)
  
  base_anual$volumen_escurrido_m3_anio[fila_anual] <- volumen_anual
  
  # Convertir el volumen anual a lamina sobre la cuenca.
  # Con volumen en m3 y area en km2, esta formula entrega mm.
  base_anual$escorrentia_mm_anio[fila_anual] <-
    volumen_anual / (superficie_km2 * 1000)
}

# No usamos na.rm = TRUE.
# Si aparece un faltante, el resultado queda como NA.
# Los anos bisiestos incluyen sus 366 registros diarios.


# 4. AGREGAR LOS DERECHOS SUPERFICIALES
# Unir las tablas por codigo de cuenca y ano.
# all.x = TRUE conserva todos los anos de la tabla.
# Los derechos no se suman entre anos ni equivalen a consumo real.

base_anual <- merge(base_anual, derechos_anuales, by = c("codigo_cuenca", "anio"), all.x = TRUE)

# Ordenar desde el primer ano hasta el ultimo.
base_anual <- base_anual[order(base_anual$anio), ]


# 5. MOSTRAR UN EJEMPLO DE CONVERSION
# Tomar el primer ano completo.
# El volumen tambien se obtiene multiplicando:
# caudal medio anual * dias del ano * 86400.

anos_completos <- base_anual[base_anual$usar_analisis_preliminar,]

ejemplo_anual <- anos_completos[1, ]

volumen_comprobado <-
  ejemplo_anual$caudal_medio_m3_s *
  ejemplo_anual$dias_esperados *
  86400

cat("\nEjemplo del ano", ejemplo_anual$anio, "\n")

cat("Volumen sumando dias:",ejemplo_anual$volumen_escurrido_m3_anio,"m3\n")

cat("Volumen usando Q medio:",volumen_comprobado,"m3\n")

cat("Escorrentia:",ejemplo_anual$escorrentia_mm_anio,"mm/anio\n")


# 6. GUARDAR LA TABLA
# Los anos incompletos mantienen NA en los calculos hidrologicos.
# Se actualiza el mismo archivo en cada ejecucion.

write.csv(base_anual,"01_data/processed/base_anual_balance.csv",row.names = FALSE)

# Mostrar los resultados de los anos completos.
print(
  anos_completos[, c(
    "anio",
    "precipitacion_mm_anio",
    "pet_mm_anio",
    "caudal_medio_m3_s",
    "escorrentia_mm_anio"
  )],
  row.names = FALSE
)

cat("\nAnos completos calculados:", nrow(anos_completos), "\n")


# 7. PREPARAR LA IMAGEN
# Guardar cuatro graficos en un solo archivo.

dir.create("03_outputs/figures/analisis_anual",recursive = TRUE,showWarnings = FALSE)

png( "03_outputs/figures/analisis_anual/graficos_anuales.png", width = 1800, height = 1400, res = 150)

# Organizar los graficos en dos filas y dos columnas.
par(mfrow = c(2, 2))


# 8. GRAFICO DE COBERTURA
# Mostrar el porcentaje de dias con P, PET y Q disponibles.

plot(base_anual$anio,base_anual$cobertura_porcentaje,type = "h",lwd = 4,col = "steelblue",
     ylim = c(0, 105),main = "Cobertura anual", xlab = "Ano", ylab = "Dias con datos completos (%)")

# Dibujar una linea en el 100 %.
abline(h = 100, lty = 2)


# 9. GRAFICO DE PRECIPITACION, PET Y ESCORRENTIA
# Comparar las tres variables en mm/anio.
# Los espacios sin linea son anos excluidos, no ceros.

plot(base_anual$anio,base_anual$precipitacion_mm_anio,type = "o",pch = 16,col = "blue",ylim = c(0, 2500),
  main = "Precipitacion, PET y escorrentia",xlab = "Ano",ylab = "mm/anio")

lines(base_anual$anio,base_anual$pet_mm_anio,type = "o",pch = 16,col = "orange")

lines(base_anual$anio,base_anual$escorrentia_mm_anio,type = "o",pch = 16,col = "darkgreen")

legend("topright",legend = c("Precipitacion", "PET", "Escorrentia"),
       col = c("blue", "orange", "darkgreen"),lty = 1,bty = "n")


# 10. GRAFICO DE PRECIPITACION Y ESCORRENTIA
# Cada punto representa un ano completo.

plot(anos_completos$precipitacion_mm_anio,anos_completos$escorrentia_mm_anio,pch = 16,col = "blue",
  main = "Precipitacion y escorrentia",xlab = "Precipitacion (mm/anio)",ylab = "Escorrentia (mm/anio)")


# 11. GRAFICO DE DERECHOS SUPERFICIALES
# Mostrar el valor registrado en cada ano.
# Estos valores no representan consumo observado.

plot(base_anual$anio,base_anual$derechos_superficiales_L_s,type = "o",pch = 16,col = "purple",
  main = "Derechos superficiales consuntivos",xlab = "Ano",ylab = "Derechos registrados (L/s)")


# 12. TERMINAR DE GUARDAR LA IMAGEN
# dev.off() cierra el archivo grafico.

dev.off()

cat("\nArchivos generados:\n")
cat("01_data/processed/base_anual_balance.csv\n")
cat("03_outputs/figures/analisis_anual/graficos_anuales.png\n")

# El area utilizada sigue siendo provisional.
# Los anos completos no son consecutivos.
# PET es evapotranspiracion potencial, no evapotranspiracion real.
