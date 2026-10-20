# DERECHOS SUPERFICIALES DGA - RIO DAMAS EN TACAMO
# Seleccionamos captaciones dentro de la cuenca CAMELS.
# No calculamos consumo ni sumamos caudales todavia.


# 1. CARGAR LOS PAQUETES

# Ejecutar una sola vez si faltan estos paquetes:
# install.packages(c("readxl", "sf"))

library(readxl)
library(sf)


# 2. LEER EL EXCEL

# Omitir las seis filas anteriores a los encabezados.
datos <- as.data.frame(read_excel("01_data/raw/Derechos_Concedidos_X_Region (1).xls",
                                  skip = 6,col_types = "text"))

# Seleccionar las columnas necesarias del Excel revisado.
derechos <- datos[, c(1, 2, 3, 9, 13, 14, 20, 33, 34, 35,42, 43, 44, 45, 63, 65, 66)]

# Dar nombres simples a las columnas.
names(derechos) <- c("registro", "expediente", "solicitud", "fecha_administrativa",
                     "tipo", "naturaleza", "fuente", "ejercicio","caudal_declarado", "unidad",
                     "norte", "este", "huso", "datum","varios_puntos", "renuncia", "transaccion")

# Quitar espacios sobrantes.
derechos[] <- lapply(derechos, trimws)


# 3. SELECCIONAR DERECHOS SUPERFICIALES CONSUNTIVOS

# Mantener solo derechos consuntivos de aguas superficiales.
seleccion <- derechos$tipo %in% "Consuntivo" & grepl("Superficial", derechos$naturaleza)

derechos <- derechos[seleccion, ]

# Convertir las coordenadas a numeros.
derechos$este <- as.numeric(derechos$este)
derechos$norte <- as.numeric(derechos$norte)


# 4. IDENTIFICAR EL SISTEMA DE COORDENADAS

# Esta tabla relaciona el datum y el huso con su codigo EPSG.
# Por ejemplo: datum 1984 y huso 18 corresponden al codigo 32718.
# Estos codigos identifican sistemas existentes; no se calculan.

sistemas <- c("1984_18" = 32718,  # WGS84, huso 18 Sur
              "1984_19" = 32719,  # WGS84, huso 19 Sur
              "1956_18" = 24878,  # PSAD56, huso 18 Sur
              "1956_19" = 24879,  # PSAD56, huso 19 Sur
              "1969_18" = 29188,  # SAD69, huso 18 Sur
              "1969_19" = 29189)   # SAD69, huso 19 Sur


# Juntar datum y huso: por ejemplo, crear el texto "1984_18".
grupo <- paste(derechos$datum, derechos$huso, sep = "_")

# Buscar el codigo correspondiente y guardarlo en la columna epsg.
derechos$epsg <- unname(sistemas[grupo])

# Identificar registros con coordenadas y sistema conocidos.
ubicables <- with(derechos,is.finite(este) & is.finite(norte) &
                    este > 0 & norte > 0 & !is.na(epsg))

# Guardar aparte los registros que necesitan revision.
pendientes <- derechos[!ubicables, ]

# Conservar los registros que podemos convertir en puntos.
derechos <- derechos[ubicables, ]


# 5. CREAR LOS PUNTOS DE CAPTACION

# Preparar una lista para guardar los grupos de puntos.
capas <- list()

# Procesar cada sistema de coordenadas por separado.
for (codigo in unique(derechos$epsg)) {
  
  # Seleccionar los registros del mismo sistema.
  grupo <- derechos[derechos$epsg == codigo, ]
  
  # Crear los puntos interpretando sus coordenadas originales.
  puntos <- st_as_sf(
    grupo,
    coords = c("este", "norte"),
    crs = codigo,
    remove = FALSE
  )
  
  # Transformar los puntos a un sistema comun: WGS84 / UTM 18 Sur.
  capas[[as.character(codigo)]] <- st_transform(puntos, 32718)
}

# Unir todos los grupos en una sola capa.
puntos <- do.call(rbind, capas)


# 6. SELECCIONAR CAPTACIONES DENTRO DE LA CUENCA

# Leer el poligono descargado de CAMELS.
cuenca <- st_read(
  "01_data/raw/camels_cl_10362001/polygon/polygon.shp",
  quiet = TRUE
)

# Corregir posibles problemas geometricos.
cuenca <- st_make_valid(cuenca)

# Transformar la cuenca al mismo sistema de los puntos.
cuenca <- st_transform(cuenca, 32718)

# Identificar puntos interiores o sobre el borde de la cuenca.
dentro <- lengths(st_intersects(puntos, cuenca)) > 0

# Conservar esos puntos.
derechos_cuenca <- puntos[dentro, ]


# 7. GUARDAR LAS TABLAS

# Guardar los registros seleccionados dentro de la cuenca.
write.csv(st_drop_geometry(derechos_cuenca),
          "01_data/processed/derechos_superficiales_cuenca_DGA.csv",row.names = FALSE,na = "",
          fileEncoding = "UTF-8")

# Guardar los registros regionales pendientes de ubicacion.
# Todavia no sabemos si pertenecen a nuestra cuenca.
write.csv(pendientes,"01_data/processed/derechos_DGA_pendientes_ubicacion.csv",
          row.names = FALSE,na = "",fileEncoding = "UTF-8")


# 8. GUARDAR LAS CAPAS PARA QGIS

# Guardar el limite y las captaciones en un mismo archivo.
archivo_mapa <- "01_data/processed/derechos_superficiales_cuenca_DGA.gpkg"

# Guardar el limite de la cuenca.
st_write(cuenca,archivo_mapa,layer = "limite_utilizado",delete_layer = TRUE,quiet = TRUE)

# Guardar las captaciones seleccionadas.
st_write(derechos_cuenca,archivo_mapa,layer = "captaciones",delete_layer = TRUE,quiet = TRUE)


# 9. MOSTRAR LOS RESULTADOS

cat("\nRegistros dentro de la cuenca:", nrow(derechos_cuenca))

cat("\nRegistros regionales pendientes de ubicacion:", nrow(pendientes))

cat("\n\nCondiciones de ejercicio dentro de la cuenca:\n")
print(table(derechos_cuenca$ejercicio, useNA = "ifany"))

cat("\nResultados guardados en 01_data/processed.\n")
cat("Los expedientes repetidos se conservan para revisarlos despues.\n")