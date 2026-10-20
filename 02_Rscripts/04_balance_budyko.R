# BALANCE Y BUDYKO - RIO DAMAS EN TACAMO
# Ejecutar despues de 03_integrar_datos_equipo.R.
# Las laminas de agua se expresan en mm/ano.


# 1. LEER Y COMPROBAR LA BASE ANUAL

datos <- read.csv("01_data/processed/base_anual_budyko.csv")
datos <- datos[order(datos$anio), ]

anios <- 1987:2019
periodo <- paste(min(anios), max(anios), sep = "-")

variables <- c("precipitacion_mm_anio","pet_mm_anio","escorrentia_mm_anio","demanda_derechos_mm_anio")

dias_calendario <- as.integer(as.Date(paste0(anios + 1, "-01-01")) -as.Date(paste0(anios, "-01-01")))

# Comprobar anos consecutivos y valores completos.
stopifnot(nrow(datos) == length(anios),all(datos$anio == anios),all(datos$anio_completo),
          all(datos$dias_esperados == dias_calendario),all(is.finite(as.matrix(datos[, variables]))),
          all(as.matrix(datos[, variables]) >= 0),all(is.finite(datos$dias_estimados)),
          all(datos$dias_estimados >= 0),all(datos$dias_estimados <= datos$dias_esperados))


# 2. CALCULAR FU Y EL BALANCE MEDIO

P <- mean(datos$precipitacion_mm_anio)
PET <- mean(datos$pet_mm_anio)
Q <- mean(datos$escorrentia_mm_anio)
D <- mean(datos$demanda_derechos_mm_anio)

stopifnot(P > 0)

w <- 2.6  # Parametro adoptado, sin calibracion local.

aridez <- PET / P

# Aplicar Fu a los promedios del periodo.
ET <- P * (1 + aridez - (1 + aridez^w)^(1 / w))
indice_evaporativo <- ET / P

# Residuo sin descontar derechos.
residuo <- P - ET - Q

# Escenario de ejercicio completo y continuo de los derechos.
saldo <- residuo - D

if (aridez < 1) {
  regimen <- "Limitada por energia"
} else if (aridez > 1) {
  regimen <- "Limitada por agua"
} else {
  regimen <- "Transicion entre agua y energia"
}


# 3. GUARDAR LOS RESULTADOS

carpeta_tablas <- "03_outputs/tables/balance_budyko"
carpeta_graficos <- "03_outputs/figures/balance_budyko"

dir.create(carpeta_tablas, recursive = TRUE, showWarnings = FALSE)
dir.create(carpeta_graficos, recursive = TRUE, showWarnings = FALSE)

resultado <- data.frame(periodo = periodo,numero_anios = nrow(datos),dias_estimados = sum(datos$dias_estimados),
                        w = w,indice_aridez = aridez,indice_evaporativo = indice_evaporativo, regimen = regimen,
                        precipitacion_mm_anio = P,pet_mm_anio = PET,et_fu_mm_anio = ET,escorrentia_mm_anio = Q,
                        demanda_superficial_mm_anio = D, saldo_con_demanda_mm_anio = saldo,
                        residuo_sin_demanda_mm_anio = residuo,
                        supuesto = "Ejercicio completo y continuo de derechos; no consumo medido")

write.csv(resultado,file.path(carpeta_tablas, "resultados_balance_budyko.csv"),row.names = FALSE)


# 4. GRAFICAR LOS DATOS ANUALES

png(file.path(carpeta_graficos, "resumen_anual.png"),width = 1800, height = 1400, res = 150)

par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))

# Comparar P, PET y escorrentia en las mismas unidades.
limite <- max(datos[, variables[1:3]]) * 1.15

plot(datos$anio, datos$precipitacion_mm_anio,type = "o", pch = 16, col = "steelblue",
     ylim = c(0, limite),xlab = "Ano", ylab = "mm/ano",main = "Precipitacion, PET y escorrentia")

lines(datos$anio, datos$pet_mm_anio,type = "o", pch = 16, col = "darkorange")

lines(datos$anio, datos$escorrentia_mm_anio,type = "o", pch = 16, col = "darkgreen")

legend("topright", legend = c("P", "PET", "Q"),col = c("steelblue", "darkorange", "darkgreen"),
       lty = 1, bty = "n", horiz = TRUE)

# Mostrar cuantos dias de caudal fueron estimados.
plot(datos$anio, datos$dias_estimados,type = "h", lwd = 3, col = "steelblue",ylim = c(0, max(1, datos$dias_estimados) * 1.1),
     xlab = "Ano", ylab = "Dias estimados",main = "Caudal completado por ano")

# Relacion entre precipitacion y escorrentia anual.
plot(datos$precipitacion_mm_anio,datos$escorrentia_mm_anio,pch = 16, col = "darkgreen",
     xlab = "Precipitacion (mm/ano)",ylab = "Escorrentia (mm/ano)",main = "Precipitacion y escorrentia")

# Derechos expresados como demanda potencial.
plot(datos$anio, datos$demanda_derechos_mm_anio,type = "o", pch = 16, col = "darkorange",
     xlab = "Ano", ylab = "mm/ano",main = "Demanda potencial por derechos")

dev.off()


# 5. GRAFICAR EL BALANCE MEDIO

valores <- c(P, ET, Q, D, saldo)
nombres <- c("Precipitaciones", "Evapotranspiración", "Caudal salida", "Derechos consuntivos", "Saldo")

limites <- range(c(0, valores))
margen <- diff(limites) * 0.15

png(file.path(carpeta_graficos, "graficos_balance_budyko.png"),width = 1600, height = 1000, res = 150)

par(mar = c(6, 5, 4, 2))

barras <- barplot(valores,names.arg = nombres, col = c("blue", "red", "red", "red", "green"),
                  ylim = limites + c(-margen, margen),ylab = "mm/ano",main = paste("Balance medio", periodo),
                  sub = "P - ET - Q - D; derechos como demanda potencial")

text(barras, valores, labels = round(valores, 2), pos = 3)
abline(h = 0, lty = 2)

dev.off()


# 6. GRAFICAR LA CURVA DE BUDYKO

x <- seq(0, max(2.5, aridez + 0.5), length.out = 500)
y <- 1 + x - (1 + x^w)^(1 / w)

png(file.path(carpeta_graficos, "curva_budyko.png"),width = 1800, height = 1400, res = 180)

# Reservar espacio inferior para la leyenda.
layout(matrix(c(1, 2), ncol = 1), heights = c(5, 1))
par(mar = c(4, 5, 4, 2), las = 1)

plot(x, y, type = "n",xlim = c(0, max(x)), ylim = c(0, 1.18),xaxs = "i", yaxs = "i", bty = "l",
     xlab = "Indice de aridez (PET/P)",ylab = "Indice evaporativo (ET/P)",
     main = "Curva de Budyko | Rio Damas en Tacamo",cex.main = 1.25)

mtext(paste("Promedios", periodo, "| Ecuacion de Fu, w =", w),side = 3, line = 0.6, col = "gray40", cex = 0.9)

# Diferenciar los sectores de energia y agua.
rect(0, 0, 1, 1.18, col = "#EFF6FA", border = NA)
rect(1, 0, max(x), 1.18, col = "#FCF6EB", border = NA)

abline(h = seq(0.2, 1, 0.2), col = "white")
abline(v = 1, col = "gray50", lty = 3)

# Limite de agua, limite de energia y curva de Fu.
abline(h = 1, col = "#3076A8", lwd = 2, lty = 2)

segments(0, 0, 1.18, 1.18,col = "#C5633A", lwd = 2, lty = 2)

lines(x, y, col = "#247568", lwd = 3)

text(0.5, 1.10, "Limitada por energia",col = "#245775", font = 2)

text((1 + max(x)) / 2, 1.10, "Limitada por agua",col = "#876028", font = 2)

# Ubicar el punto medio de la cuenca.
segments(aridez, 0, aridez, indice_evaporativo,lty = 3, col = "gray50")

segments(0, indice_evaporativo, aridez, indice_evaporativo,lty = 3, col = "gray50")

points(aridez, indice_evaporativo,pch = 21, bg = "#183D50", col = "white",cex = 2, lwd = 1.5)

text(aridez + 0.12, indice_evaporativo - 0.08,labels = paste0("Tacamo\nPET/P = ", round(aridez, 3),
                                                              "  |  ET/P = ", round(indice_evaporativo, 3)),adj = c(0, 1), col = "#183D50", cex = 0.95)

# Leyenda fuera del area de datos.
par(mar = c(0, 0, 0, 0))
plot.new()

legend("top", ncol = 2, bty = "n", cex = 0.95,legend = c(paste0("Curva de Fu (w = ", w, ")"),
                                                         "Tacamo: ET estimada con Fu","Limite de agua (ET = P)","Limite de energia (ET = PET)"),
       col = c("#247568", "#183D50", "#3076A8", "#C5633A"),lty = c(1, NA, 2, 2),
       pch = c(NA, 19, NA, NA),lwd = c(3, NA, 2, 2))

text(0.5, 0.18,"Clasificacion del promedio del periodo; no representa cada estacion del ano.",
     cex = 0.85, col = "gray40")

dev.off()


#  RESUMEN 

print(resultado)

cat("\nPeriodo comprobado:", periodo, "\n")
cat("Cantidad de anos consecutivos:", nrow(datos), "\n")
cat("Clasificacion media:", regimen, "\n")
cat("PET/P:", round(aridez, 3), "\n")
cat("ET Fu/P:", round(indice_evaporativo, 3), "\n")
cat("Saldo con demanda:", round(saldo, 2), "mm/ano\n")
cat("Residuo sin demanda:", round(residuo, 2), "mm/ano\n")
cat("Graficos guardados en:", carpeta_graficos, "\n")




# 8. EVOLUCION DE LOS DERECHOS SUPERFICIALES
# Son derechos equivalentes bajo ejercicio continuo, no consumo medido.

anios_derechos <- datos$anio
demanda <- datos$demanda_derechos_mm_anio

# Obtener el primer valor, el ultimo y el promedio del periodo.
ultimo <- length(demanda)
promedio_demanda <- mean(demanda)

# Guardar una tabla pequena para la presentacion.
resumen_derechos <- data.frame(periodo = c(as.character(anios_derechos[1]),
                                           as.character(anios_derechos[ultimo]),
                                           paste0("Promedio ", periodo)),
                               derechos_equivalentes_mm_anio = c(demanda[1],
                                                                 demanda[ultimo],promedio_demanda))

write.csv(resumen_derechos,file.path(carpeta_tablas, 
                                     "resumen_derechos_superficiales.csv"),row.names = FALSE)


# Preparar el grafico independiente.
png(file.path(carpeta_graficos, "evolucion_derechos_superficiales.png"),
    width = 1800, height = 1100, res = 180)

par(mar = c(7, 5, 4, 2), las = 1)

plot(anios_derechos, demanda,type = "o",pch = 16,lwd = 2,col = "darkorange3",
     ylim = c(0, max(demanda) * 1.25),xlab = "Año",ylab = "Lámina equivalente (mm/año)",
     main = "Evolución de los derechos superficiales",bty = "l")

# Dibujar el promedio de todo el periodo.
abline(h = promedio_demanda,col = "steelblue",lwd = 2,lty = 2)

# Destacar el valor del ultimo año.
points(anios_derechos[ultimo], demanda[ultimo],pch = 19, cex = 1.5, col = "darkorange3")

text(anios_derechos[ultimo], demanda[ultimo],
     labels = paste0(anios_derechos[ultimo],
                     ": ",round(demanda[ultimo], 2), " mm/año"), pos = 2, offset = 0.8,cex = 0.95)

# Explicar las dos lineas.
legend("topleft",legend = c("Derechos superficiales equivalentes",paste0("Promedio ", periodo, ": ",
                                                                         round(promedio_demanda, 2), " mm/año")),col = c("darkorange3", "steelblue"),
       lty = c(1, 2),lwd = 2,pch = c(16, NA),bty = "n",cex = 0.9)

# Aclarar la fuente y el supuesto.
mtext("Fuente: CAMELS-CL, cons_sf_wr_year.csv.",side = 1, line = 4.5, cex = 0.8)

mtext("Ejercicio continuo sobre el área de la cuenca; no consumo efectivo medido.",
      side = 1, line = 5.5, cex = 0.8)

dev.off()

# Mostrar la tabla en consola.
print(resumen_derechos, row.names = FALSE)