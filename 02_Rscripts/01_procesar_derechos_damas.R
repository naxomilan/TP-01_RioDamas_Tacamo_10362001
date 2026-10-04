# ==============================================================================
# SCRIPT 01: Derechos Río Damas
# Proyecto: TP-01_RioDamas_Tacamo_10362001
# Vicente Rapiman Montes
# ==============================================================================

# 1. Cargar paquetes necesarios
if (!require("readxl")) install.packages("readxl")
library(readxl)

# 2. Localizar archivo crudo en 01_data/raw/
ruta_archivo_excel <- list.files("01_data/raw", pattern = "Derechos_Concedidos", full.names = TRUE)[1]

# 3. Leer planilla completa sin encabezados predeterminados
datos_original <- read_excel(ruta_archivo_excel, col_names = FALSE)

# 4. Extraer los encabezados oficiales (ubicados en la fila 4)
encabezados <- as.character(datos_original[4, ])
colnames(datos_original) <- encabezados

# 5. Limpieza de filas iniciales de metadatos (filas 1 a 4)
datos_ordenados <- datos_original[-c(1, 2, 3, 4), ]

# 6. Filtrar registros asociados a la cuenca / río "Damas"
filtro_damas <- apply(datos_ordenados, 1, function(fila) any(grepl("Damas", as.character(fila), ignore.case = TRUE)))
derechos_damas <- datos_ordenados[which(filtro_damas), ]

# 7. Control de Calidad: Depuración de registros sin 'SubSubCuenca'
col_subsub <- colnames(derechos_damas)[grep("subsubcuenca", colnames(derechos_damas), ignore.case = TRUE)][1]
valores_subsub <- derechos_damas[[col_subsub]]

# Identificar registros con información válida (excluye NA, "NA" textual y celdas vacías)
filas_validas <- !is.na(valores_subsub) & valores_subsub != "NA" & trimws(valores_subsub) != ""
filas_eliminadas <- sum(!filas_validas)

# Filtrar tabla conservando solo filas válidas
derechos_damas <- derechos_damas[which(filas_validas), ]

# 8. Exportación de datos procesados (Formato regional chileno ';')
write.csv2(derechos_damas, "01_data/processed/Derechos_Agua_RioDamas.csv", row.names = FALSE, na = "")


