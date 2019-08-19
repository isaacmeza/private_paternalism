library(tidyverse)
library(grf)
library(ggplot2)

# SET WORKING DIRECTORY
setwd('C:/Users/xps-seira/Dropbox/Apps/ShareLaTeX/Donde 2019')
set.seed(5289374)


rf_predict <- function(data_in,take.up) {
  
  require("dplyr")
  data_frame <- data_in %>%
    filter(data_in[,take.up] == 1 | data_in[,take.up] == 0) %>%
    select(-c(suc_x_dia, producto, NombrePignorante, fecha_inicial,pago_frec_voluntario_fee,
              pago_frec_voluntario_nofee,pago_frec_voluntario), take.up ) %>%
    drop_na()   
  
  # PREPARE VARIABLES
  X <- select(data_frame,-c(take.up))
  W <- as.numeric(data_frame[,take.up] == 1)
 
  
  # ESTINATE MODEL
  propensity.forest = regression_forest(X, W)
  rf_predict = predict(propensity.forest)$predictions
  hist(rf_predict, xlab = "predictions")
  
  data.out <- add_column(data_frame, rf_predict)
  filename <- paste("_aux/pred_",take.up,".csv", sep="") 
  write_csv(data.out,filename)
}

#####################################################

# READ DATASET
# Prenda level
data <- read_csv('C:/Users/xps-seira/Downloads/data_pfv.csv')



#Heterogeneous Effects
for (t in c("pago_frec_voluntario")) {
  rf_predict(data,t) 
}

