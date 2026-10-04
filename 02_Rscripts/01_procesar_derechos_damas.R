# 1. Cargar paquete
if (!require("readxl")) install.packages("readxl")
library(readxl)

# 2. Buscar archivo en 01_data/raw
ruta_archivo_excel <- list.files("01_data/raw", pattern = "Derechos_Concedidos", full.names = TRUE)[1]

# 3. Leer todo el archivo SIN encabezados
datos_original <- read_excel(ruta_archivo_excel, col_names = FALSE)

# 4. Extraer los títulos que están EXACTAMENTE en la fila 4 
encabezados <- as.character(datos_original[4, ])
colnames(datos_original) <- encabezados

# 5. Eliminar las filas 1, 2, 3 (vacías) y 4 (donde estaban los títulos)
datos_ordenados <- datos_original[-c(1, 2, 3, 4), ]

# 6. Filtrar las filas del Río Damas
filtro_damas <- apply(datos_ordenados, 1, function(fila) any(grepl("Damas", as.character(fila), ignore.case = TRUE)))
derechos_damas <- datos_ordenados[which(filtro_damas), ]

# 7. Guardar el archivo final
write.csv2(derechos_damas, "01_data/processed/Derechos_Agua_RioDamas.csv", row.names = FALSE, na = "")

cat("¡Proceso completado! Se guardaron", nrow(derechos_damas), "filas limpias.\n")