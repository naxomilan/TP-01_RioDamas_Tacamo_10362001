# 06_geomorfologia.R
library(terra)

p <- "01_data/processed"

# Datos
dem <- rast(file.path(p, "dem_utm18s_30m.tif"))
cuenca <- vect(file.path(p, "cuenca_rio_damas.gpkg"))
red <- vect(file.path(p, "red_drenaje_rio_damas.gpkg"))

# Elevacion y pendiente
dem_c <- mask(crop(dem, cuenca), cuenca)
pend <- mask(crop(terrain(dem, "slope", unit="degrees"), cuenca), cuenca)

z <- values(dem_c, na.rm=TRUE)
s <- values(pend, na.rm=TRUE)

# Geometria y drenaje
A <- expanse(cuenca, unit="km")
P <- perim(cuenca)/1000
L <- sum(perim(red))/1000
Dd <- L/A
Kc <- P/(2*sqrt(pi*A))

# Hipsometria
zmin <- min(z); zmax <- max(z)
HI <- (mean(z)-zmin)/(zmax-zmin)

z_ord <- sort(z, decreasing=TRUE)
area_rel <- seq_along(z_ord)/length(z_ord)
elev_rel <- (z_ord-zmin)/(zmax-zmin)

# Tabla de resultados
tabla <- data.frame(
  parametro=c("Area","Perimetro","Elevacion minima","Elevacion media",
              "Elevacion mediana","Elevacion maxima","Relieve",
              "Pendiente media","Pendiente mediana","Pendiente maxima",
              "Integral hipsometrica","Longitud red drenaje",
              "Densidad de drenaje","Coeficiente de compacidad"),
  valor=c(A,P,min(z),mean(z),median(z),max(z),zmax-zmin,
          mean(s),median(s),max(s),HI,L,Dd,Kc),
  unidad=c("km2","km",rep("m",5),rep("grados",3),
           "adimensional","km","km/km2","adimensional")
)

write.csv(tabla, "03_outputs/tables/geomorfologia.csv", row.names=FALSE)

# Funcion para agregar norte
norte <- function(x) {
  xn <- xmax(x)-2500
  yn <- ymax(x)-3000
  text(xn,yn,"N",font=2,cex=1.2)
  arrows(xn,yn-3000,xn,yn-600,length=.12,lwd=2)
}

# Mapa de elevacion
png("03_outputs/figures/mapa_elevacion.png",1400,1000,res=150)
plot(dem_c, main="Elevacion - Cuenca Rio Damas",
     plg=list(title="Elevacion (m)"))
plot(cuenca,add=TRUE,lwd=2)
norte(cuenca)
dev.off()

# Mapa de pendiente
png("03_outputs/figures/mapa_pendiente.png",1400,1000,res=150)
plot(pend, main="Pendiente - Cuenca Rio Damas",
     plg=list(title="Pendiente (grados)"))
plot(cuenca,add=TRUE,lwd=2)
norte(cuenca)
dev.off()

# Curva hipsometrica
png("03_outputs/figures/curva_hipsometrica.png",1400,1000,res=150)
plot(area_rel,elev_rel,type="l",lwd=2,
     xlab="Area acumulada relativa",
     ylab="Elevacion relativa",
     main="Curva hipsometrica - Cuenca Rio Damas")
grid()
dev.off()

print(tabla)