# 07_uso_suelo_territorio.R
library(terra)

p <- "01_data/processed"
cuenca <- vect(file.path(p,"cuenca_rio_damas.gpkg"))
A <- expanse(cuenca,unit="km")

norte <- function(x){
  xn <- xmax(x)-2500; yn <- ymax(x)-3000
  text(xn,yn,"N",font=2,cex=1.3)
  arrows(xn,yn-3000,xn,yn-600,length=.12,lwd=2)
}

# ============================================================
# CONAF 2018
# ============================================================

conaf <- vect(file.path(p,"cobertura_conaf_2018.gpkg"))
conaf$area_km2 <- expanse(conaf,unit="km")
uso <- aggregate(area_km2~USO,as.data.frame(conaf),sum)
uso$porcentaje <- uso$area_km2/A*100
write.csv(uso,"03_outputs/tables/cobertura_conaf_2018.csv",row.names=FALSE)

clases_conaf <- c("Áreas Urbanas e Industriales","Bosques","Cuerpos de Agua",
                  "Praderas y Matorrales","Terrenos Agrícolas")
col_conaf <- c("#D7191C","#006837","#2166AC","#762A83","#FEC44F")
conaf$color <- col_conaf[match(conaf$USO,clases_conaf)]

png("03_outputs/figures/mapa_cobertura_conaf_2018.png",1900,1200,res=150)
par(mar=c(4,4,6,3))
plot(conaf,col=conaf$color,border="grey30",lwd=.35,main="")
plot(cuenca,add=TRUE,lwd=2)

mtext("Cobertura y uso de suelo CONAF 2018",side=3,line=3.2,
      cex=1.35,font=2)
mtext("Cuenca Rio Damas",side=3,line=1.5,cex=1.05)

norte(cuenca)
legend(xmin(cuenca)+1500,ymin(cuenca)+9000,
       legend=clases_conaf,fill=col_conaf,border="grey30",
       title="Cobertura / uso de suelo",cex=.85,bg="white")
dev.off()

# ============================================================
# CIREN 2020
# ============================================================

suelos <- vect(file.path(p,"suelos_ciren_2020.gpkg"))
suelos$area_km2 <- expanse(suelos,unit="km")
capacidad <- aggregate(area_km2~textcaus,as.data.frame(suelos),sum)
capacidad$porcentaje <- capacidad$area_km2/A*100
write.csv(capacidad,"03_outputs/tables/suelos_capacidad_uso.csv",row.names=FALSE)

clases_ciren <- c("II","III","IV","VI","VII","N.C.")
nombres_ciren <- c(
  "II - Limitaciones moderadas para cultivos",
  "III - Limitaciones severas para cultivos",
  "IV - Limitaciones muy severas para cultivos",
  "VI - No apto para cultivos; praderas o forestal",
  "VII - Limitaciones muy severas; forestal o conservacion",
  "N.C. - No clasificado"
)
col_ciren <- c("#1B9E77","#E66101","#7570B3","#E7298A","#66A61E","#A6A6A6")
suelos$color <- col_ciren[match(suelos$textcaus,clases_ciren)]

png("03_outputs/figures/mapa_suelos_capacidad_uso.png",1900,1200,res=150)
par(mar=c(4,4,6,3))
plot(suelos,col=suelos$color,border="grey30",lwd=.35,main="")
plot(cuenca,add=TRUE,lwd=2)

mtext("Capacidad de uso del suelo CIREN 2020",side=3,line=3.2,
      cex=1.35,font=2)
mtext("Cuenca Rio Damas",side=3,line=1.5,cex=1.05)

norte(cuenca)
legend("bottomleft",legend=nombres_ciren,fill=col_ciren,border="grey30",
       title="Capacidad de uso",cex=.8,bg="white",inset=.02)
dev.off()

print(uso)
print(capacidad)