# INTEGRAR DATOS DEL EQUIPO - RIO DAMAS EN TACAMO
# Ejecutar desde el proyecto .Rproj.
# Este script prepara los datos; no calcula Fu ni el balance.


# 1. DEFINIR LA CUENCA Y EL PERIODO

anios <- 1987:2019

configuracion <- read.csv("06_config/parametros.csv",colClasses = "character")

codigo <- configuracion$valor[configuracion$parametro == "codigo_camels"]

atributos <- read.csv("01_data/raw/catchment_attributes.csv",header = FALSE,colClasses = "character")

area_km2 <- as.numeric(atributos$V2[atributos$V1 == "area_km2"])

# Las fuentes utilizadas corresponden a esta estacion.
stopifnot(length(codigo) == 1,codigo == "10362001",length(area_km2) == 1,
          is.finite(area_km2),area_km2 > 0)

calendario <- seq(as.Date(paste0(min(anios), "-01-01")),as.Date(paste0(max(anios), "-12-31")),by = "day")


# 2. LEER Y SELECCIONAR LOS DATOS

# Precipitacion preparada por Fernanda.
clima <- read.csv("01_data/processed/clima_CR2METv25_10362001_daily_1960-2021.csv")

clima <- clima[, c("fecha", "P_mm")]
names(clima) <- c("fecha", "precipitacion_mm_dia")

# Caudal observado y completado por Alexis.
caudal <- read.csv("01_data/processed/caudal_diario_para_airGR_1987_2019.csv")

caudal <- caudal[, c("fecha", "Q_observado_m3s", "Q_completado_m3s",
                     "metodo_relleno", "estacion_donante")]

names(caudal)[2:3] <- c("caudal_m3_s", "caudal_analisis_m3_s")

# PET Hargreaves de CAMELS.
pet <- read.csv("01_data/raw/pet_hargreaves_day.csv",check.names = FALSE)

pet <- pet[, c("date", codigo)]
names(pet) <- c("fecha", "pet_mm_dia")

# Derechos superficiales de CAMELS, registrados en L/s.
derechos <- read.csv("01_data/raw/cons_sf_wr_year.csv",check.names = FALSE)

derechos <- derechos[, c("date", codigo)]
names(derechos) <- c("fecha", "derechos_superficiales_L_s")


# 3. COMPROBAR LAS FECHAS Y UNIR LAS SERIES

clima$fecha <- as.Date(clima$fecha)
pet$fecha <- as.Date(pet$fecha)
caudal$fecha <- as.Date(caudal$fecha)
derechos$fecha <- as.Date(derechos$fecha)

# Detener el proceso si existen fechas invalidas o repetidas.
for (tabla in list(clima, pet, caudal, derechos)) {
  stopifnot(
    !anyNA(tabla$fecha),
    !anyDuplicated(tabla$fecha)
  )
}

datos <- data.frame(fecha = calendario)

datos <- merge(datos, clima, by = "fecha", all.x = TRUE)
datos <- merge(datos, pet, by = "fecha", all.x = TRUE)
datos <- merge(datos, caudal, by = "fecha", all.x = TRUE)
datos <- datos[order(datos$fecha), ]

variables <- c(
  "precipitacion_mm_dia",
  "pet_mm_dia",
  "caudal_analisis_m3_s"
)

# Comprobar que todos los dias tengan P, PET y Q utilizables.
stopifnot(nrow(datos) == length(calendario),all(datos$fecha == calendario),
  all(is.finite(as.matrix(datos[, variables]))),all(as.matrix(datos[, variables]) >= 0))

# El caudal observado puede contener NA, pero no valores invalidos.
observados <- !is.na(datos$caudal_m3_s)

stopifnot(all(is.finite(datos$caudal_m3_s[observados])),
  all(datos$caudal_m3_s[observados] >= 0))

datos$anio <- as.integer(format(datos$fecha, "%Y"))

# Identificar dias sin observacion que tienen caudal completado.
datos$caudal_estimado <- is.na(datos$caudal_m3_s)


# 4. CONVERTIR LAS UNIDADES

# Un m3/s sostenido durante un dia equivale a esta lamina en mm.
factor_diario <- 86400 / (area_km2 * 1000)

datos$escorrentia_mm_dia <-
  datos$caudal_analisis_m3_s * factor_diario

# Preparar los derechos del mismo periodo.
derechos$anio <- as.integer(format(derechos$fecha, "%Y"))
derechos <- derechos[derechos$anio %in% anios, ]
derechos <- derechos[order(derechos$anio), ]

stopifnot(nrow(derechos) == length(anios),all(derechos$anio == anios),
  all(is.finite(derechos$derechos_superficiales_L_s)),
  all(derechos$derechos_superficiales_L_s >= 0))

# Convertir L/s a m3/s. No acumular nuevamente entre anos.
derechos$derechos_superficiales_m3_s <- derechos$derechos_superficiales_L_s / 1000

# Contar los dias calendario de cada ano, incluidos los bisiestos.
derechos$dias_esperados <- as.integer(as.Date(paste0(derechos$anio + 1, "-01-01")) -
                                        as.Date(paste0(derechos$anio, "-01-01")))

# Demanda potencial suponiendo ejercicio continuo todo el ano.
# Esta conversion no representa consumo efectivamente medido.
derechos$demanda_derechos_mm_anio <- derechos$derechos_superficiales_m3_s * derechos$dias_esperados * factor_diario


# 5. CALCULAR TODOS LOS VALORES ANUALES

tabla_budyko <- data.frame()

for (anio in anios) {
  
  d <- datos[datos$anio == anio, ]
  derecho <- derechos[derechos$anio == anio, ]
  
  # Comprobar la cantidad de dias de cada ano.
  stopifnot(nrow(d) == derecho$dias_esperados)
  
  fila <- data.frame(
    codigo_cuenca = codigo,
    anio = anio,
    area_km2 = area_km2,
    dias_esperados = derecho$dias_esperados,
    dias_estimados = sum(d$caudal_estimado),
    anio_completo = all(complete.cases(d[, variables])),
    precipitacion_mm_anio = sum(d$precipitacion_mm_dia),
    pet_mm_anio = sum(d$pet_mm_dia),
    caudal_medio_m3_s = mean(d$caudal_analisis_m3_s),
    escorrentia_mm_anio = sum(d$escorrentia_mm_dia),
    derechos_superficiales_L_s =
      derecho$derechos_superficiales_L_s,
    derechos_superficiales_m3_s =
      derecho$derechos_superficiales_m3_s,
    demanda_derechos_mm_anio =
      derecho$demanda_derechos_mm_anio
  )
  
  tabla_budyko <- rbind(tabla_budyko, fila)
}


# 6. REGISTRAR LAS FUENTES Y GUARDAR

tabla_budyko$fuente_precipitacion <- "CR2MET v2.5; Fernanda"
tabla_budyko$fuente_pet <- "Hargreaves; CAMELS"
tabla_budyko$fuente_caudal <- "DGA; completado por Alexis"
tabla_budyko$fuente_area <- "CAMELS; catchment_attributes.csv"
tabla_budyko$fuente_derechos <- "CAMELS; cons_sf_wr_year.csv"

tabla_budyko$supuesto_demanda <- "Ejercicio completo y continuo de derechos; no consumo medido"

dir.create("01_data/processed",recursive = TRUE, showWarnings = FALSE)

write.csv(datos,"01_data/processed/base_diaria_budyko.csv",row.names = FALSE)

write.csv(tabla_budyko,"01_data/processed/base_anual_budyko.csv",row.names = FALSE)


# 7. MOSTRAR EL RESUMEN

cat("\nPeriodo:", min(anios), "-", max(anios), "\n")
cat("Area CAMELS:", area_km2, "km2\n")
cat("Anos completos:", sum(tabla_budyko$anio_completo), "\n")
cat("Dias del periodo:", nrow(datos), "\n")
cat("Dias estimados:", sum(datos$caudal_estimado), "\n")

print(tabla_budyko[, c("anio", "dias_estimados", "precipitacion_mm_anio",
    "pet_mm_anio", "escorrentia_mm_anio","demanda_derechos_mm_anio")],row.names = FALSE)

cat("\nBases guardadas. Continuar con 04_balance_budyko.R\n")