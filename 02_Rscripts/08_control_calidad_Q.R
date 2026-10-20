# 08_control_calidad_Q.R

# Datos
camels <- read.csv(unz("01_data/raw/camels_cl_10362001.zip","q_m3s_day.csv"))
camels$date <- as.Date(camels$date)

# Conservar la base regional para disponer de estaciones donantes.
base <- read.csv(
  unz(
    "01_data/raw/caudal_diario_historico_dga_los_lagos.zip",
    "caudal_diario_historico_10.txt"
  ),
  stringsAsFactors = FALSE
)

stopifnot(
  all(c("CODIGO.ESTACION", "FECHA", "Caudal_diario") %in% names(base))
)

base$FECHA <- as.Date(base$FECHA, format = "%d/%m/%Y")

if (
  anyNA(base$FECHA) ||
  anyDuplicated(base[, c("CODIGO.ESTACION", "FECHA")]) > 0
) {
  stop("Revisa fechas invalidas o repetidas por estacion en la base DGA.")
}

# Seleccionar Rio Damas para el control de calidad.
dga <- base[base$CODIGO.ESTACION == 10362001, ]

# Serie continua: dias sin registro quedan como NA
q <- data.frame(FECHA=seq(min(dga$FECHA),max(dga$FECHA),by="day"))
q <- merge(q,dga[,c("FECHA","Caudal_diario")],all.x=TRUE)

cat("Periodo:",format(range(q$FECHA)),
    "\nRegistros validos:",sum(!is.na(q$Caudal_diario)),
    "\nFaltantes:",sum(is.na(q$Caudal_diario)),
    "\nCobertura:",round(mean(!is.na(q$Caudal_diario))*100,2),"%",
    "\nDuplicados:",sum(duplicated(dga$FECHA)),
    "\nNegativos:",sum(dga$Caudal_diario<0),"\n")
print(summary(dga$Caudal_diario))

# Fechas faltantes y cantidad por mes
fechas_faltantes <- q[is.na(q$Caudal_diario),"FECHA",drop=FALSE]
fechas_faltantes$anio <- as.integer(format(fechas_faltantes$FECHA,"%Y"))
fechas_faltantes$mes <- as.integer(format(fechas_faltantes$FECHA,"%m"))

n_mes <- aggregate(FECHA~anio+mes,fechas_faltantes,length)
names(n_mes)[3] <- "faltantes_mes"

fechas_faltantes <- merge(fechas_faltantes,n_mes,by=c("anio","mes"))
fechas_faltantes <- fechas_faltantes[order(fechas_faltantes$FECHA),]

write.csv(fechas_faltantes,
          "03_outputs/tables/fechas_faltantes_caudal_dga.csv",
          row.names=FALSE)

# Bloques consecutivos de datos faltantes
r <- rle(is.na(q$Caudal_diario))
fin <- cumsum(r$lengths)
ini <- fin-r$lengths+1

huecos <- data.frame(
  inicio=q$FECHA[ini[r$values]],
  fin=q$FECHA[fin[r$values]],
  dias=r$lengths[r$values]
)

huecos <- huecos[order(-huecos$dias),]

write.csv(huecos,
          "03_outputs/tables/faltantes_caudal_dga.csv",
          row.names=FALSE)

# Cobertura anual
q$anio <- as.integer(format(q$FECHA,"%Y"))

cob <- aggregate(!is.na(Caudal_diario)~anio,q,mean)
names(cob)[2] <- "cobertura_pct"
cob$cobertura_pct <- cob$cobertura_pct*100
cob$periodo_completo <- !cob$anio %in% c(min(q$anio),max(q$anio))

write.csv(cob,
          "03_outputs/tables/cobertura_caudal_dga.csv",
          row.names=FALSE)

# Grafico de cobertura anual (solo años completos)
g <- cob[cob$periodo_completo,]

png("03_outputs/figures/cobertura_anual_caudal.png",
    1600,900,res=150)

plot(g$anio,g$cobertura_pct,type="b",pch=16,ylim=c(60,102),
     xlab="Año",ylab="Cobertura de datos (%)",
     main="Cobertura anual de caudales - Rio Damas")
abline(h=90,lty=2)
grid()

dev.off()

# Comparacion DGA vs CAMELS-CL
comp <- merge(camels[,c("date","X10362001")],
              dga[,c("FECHA","Caudal_diario")],
              by.x="date",by.y="FECHA")

dif <- abs(comp$X10362001-comp$Caudal_diario)

cat("\nDGA vs CAMELS-CL",
    "\nDias comparables:",sum(!is.na(dif)),
    "\nCoincidencias:",sum(dif<1e-6,na.rm=TRUE),
    "\nDiferencias > 0.01:",sum(dif>0.01,na.rm=TRUE),
    "\nDiferencia maxima:",max(dif,na.rm=TRUE),"m3/s\n")

# Decisiones de control
decisiones <- data.frame(
  aspecto=c("Duplicados","Faltantes","Valores negativos",
            "Caudal maximo","DGA vs CAMELS"),
  decision=c("Sin correccion",
             "Mantener como NA; no interpolar",
             "No existen",
             "157 m3/s el 07-08-2018; conservar",
             "DGA principal; CAMELS como contraste")
)

write.csv(decisiones,
          "03_outputs/tables/decisiones_control_Q.csv",
          row.names=FALSE)

# Serie controlada
write.csv(q[,c("FECHA","Caudal_diario")],
          "01_data/processed/caudal_diario_dga_10362001.csv",
          row.names=FALSE)