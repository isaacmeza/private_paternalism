library(tidyverse)
library(grf)
library(ggplot2)

# SET WORKING DIRECTORY
setwd('C:/Users/isaac/Dropbox/Apps/ShareLaTeX/Donde2020')
set.seed(5289374)
options(digits=18)

rf_predict <- function(data_in,take.up,nme) {
  
  require("dplyr")
  data_train <- data_in %>% 
    filter(insample == 1) 

  data_test <- data_in %>% 
    select(-c(take.up, nombrepignorante, prenda, insample, tau_hat_oobpredictions))
###################################################################  
###################################################################  

    
  # PREPARE VARIABLES
  X <- select(data_train,-c(take.up, nombrepignorante, prenda, insample, tau_hat_oobpredictions))
  W <- as.numeric(data_train[,take.up] == 1)

###################################################################  
###################################################################  
  
  
  # ESTIMATE MODEL
  pred.forest = regression_forest(X, W)
  rf_pred = predict(pred.forest,data_test)$predictions
  hist(rf_pred, xlab = "predictions")
  
  data.out <- add_column(data_in, rf_pred)
  filename <- paste("_aux/pred_",nme,".csv", sep="") 
  write_csv(data.out,filename)
}

#####################################################

#RF Predictions of no-choice arm
for (arm in c("pro_2")) {
  for (pred in c("pago_frec_vol_fee")) {
    for (effect in c("def_c", "des_c")) {
      filename <- paste("_aux/",arm,"_",pred,"_",effect,".csv", sep="")
      data <- read_csv(filename)
      outname <- paste(arm,"_",pred,"_",effect,sep="")
      rf_predict(data,pred,outname) 
    }
  }
}

