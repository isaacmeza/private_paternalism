library(tidyverse)
library(grf)
library(ggplot2)

# SET WORKING DIRECTORY
setwd('C:/Users/xps-seira/Dropbox/Apps/ShareLaTeX/Donde2019')
set.seed(5289374)


rf_predict <- function(data_in,take.up) {
  
  require("dplyr")
  data_train <- data_in %>% 
    filter(insample == 1) 
  
  data_test <- data_in %>% 
    select(-c(take.up, nombrepignorante, prenda, insample))
  ###################################################################  
  ###################################################################  
  
  
  # PREPARE VARIABLES
  X <- select(data_train,-c(take.up, nombrepignorante, prenda, insample))
  W <- as.numeric(data_train[,take.up] == 1)
  
  ###################################################################  
  ###################################################################  
  
  
  # ESTIMATE MODEL
  pred.forest = regression_forest(X, W)
  rf_pred = predict(pred.forest,data_test)$predictions
  hist(rf_pred, xlab = "predictions")
  
  data.out <- add_column(data_in, rf_pred)
  filename <- paste("_aux/pred_",take.up,".csv", sep="") 
  write_csv(data.out,filename)
}

#####################################################

# READ DATASET
# Prenda level
data_pfv_fee <- read_csv('./_aux/data_pfv_test_pago_frec_vol_fee.csv')

#RF Predictions
rf_predict(data_pfv_fee,"pago_frec_vol_fee")

