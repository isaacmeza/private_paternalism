library(tidyverse)
library(grf)
library(ggplot2)
library(DMwR)

# SET WORKING DIRECTORY
setwd('C:/Users/xps-seira/Dropbox/Apps/ShareLaTeX/Donde2020')
set.seed(5289374)


rf_predict <- function(data_in,pf) {
  
  require("dplyr")
  data_train <- data_in %>% 
    filter(insample == 1) 
  
  data_test <- data_in %>% 
    select(-c(pf, insample))
  ###################################################################  
  ###################################################################  
  
  
  # PREPARE VARIABLES
  X <- select(data_train,-c(pf, insample))
  W <- as.numeric(data_train[,pf] == 1)
  
  ###################################################################  
  ###################################################################  
  
  
  # ESTIMATE MODEL
  pred.forest = regression_forest(X, W)
  rf_pred = predict(pred.forest,data_test)$predictions
  hist(rf_pred, xlab = "predictions")
  
  data.out <- add_column(data_in, rf_pred)
  filename <- paste("_aux/pred_",pf,".csv", sep="") 
  write_csv(data.out,filename)
}



###################################################################################

# Branch x week - Predictions
rf_predict(read_csv('./_aux/instrument_1.csv'),"pf_suc_1")

# Branch x week - Predictions
rf_predict(read_csv('./_aux/instrument_2.csv'),"pf_suc_2")

# Branch x week - Predictions
rf_predict(read_csv('./_aux/instrument_3.csv'),"pf_suc_3")
