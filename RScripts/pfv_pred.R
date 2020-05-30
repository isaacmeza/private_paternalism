library(tidyverse)
library(grf)
library(ggplot2)
library(DMwR)

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



###################################################################################

# Prenda level
data_pfv_fee <- read_csv('./_aux/data_pfv_test_pago_frec_vol_fee.csv')

# data_train <- data_pfv_fee %>% 
#   filter(insample == 1) %>%
#   as.data.frame() %>%
#   mutate(pago_frec_vol_fee = as.factor(pago_frec_vol_fee)) 
# data_test <- data_pfv_fee %>% 
#   filter(insample == 0)  %>%
#   as.data.frame() %>%
#   mutate(pago_frec_vol_fee = as.factor(pago_frec_vol_fee)) 
# 
# ## Using SMOTE to create a more "balanced problem"
# data.smoted <- SMOTE(pago_frec_vol_fee ~ .-nombrepignorante -prenda -insample,
#                      data_train, k = 2, perc.over = 300, perc.under=200)
# 
# data_pfv_fee <- rbind(data.smoted, data_test)
# write_csv(data_pfv_fee,"_aux/data_pfv_test_smoted_pago_frec_vol_fee.csv")

#################################################################################

# READ DATASET
data_pfv_promise <- read_csv('./_aux/data_pfv_test_pago_frec_vol_promise.csv')

# data_train <- data_pfv_promise %>% 
#   filter(insample == 1) %>%
#   as.data.frame() %>%
#   mutate(pago_frec_vol_promise = as.factor(pago_frec_vol_promise)) 
# data_test <- data_pfv_promise %>% 
#   filter(insample == 0)  %>%
#   as.data.frame() %>%
#   mutate(pago_frec_vol_promise = as.factor(pago_frec_vol_promise)) 
# 
# ## Using SMOTE to create a more "balanced problem"
# data.smoted <- SMOTE(pago_frec_vol_promise ~ .-nombrepignorante-prenda-insample,
#                      data_train, k = 2, perc.over = 300, perc.under=200)
# 
# data_pfv_promise <- rbind(data.smoted, data_test)
# write_csv(data_pfv_promise,"_aux/data_pfv_test_smoted_pago_frec_vol_promise.csv")

#################################################################################

# READ DATASET
data_pfv <- read_csv('./_aux/data_pfv_test_pago_frec_vol.csv')

# data_train <- data_pfv %>% 
#   filter(insample == 1) %>%
#   as.data.frame() %>%
#   mutate(pago_frec_vol = as.factor(pago_frec_vol)) 
# data_test <- data_pfv %>% 
#   filter(insample == 0)  %>%
#   as.data.frame() %>%
#   mutate(pago_frec_vol = as.factor(pago_frec_vol)) 
# 
# ## Using SMOTE to create a more "balanced problem"
# data.smoted <- SMOTE(pago_frec_vol ~ .-nombrepignorante-prenda-insample,
#                      data_train, k = 2, perc.over = 300, perc.under=200)
# 
# data_pfv <- rbind(data.smoted, data_test)
# write_csv(data_pfv,"_aux/data_pfv_test_smoted_pago_frec_vol.csv")


##################################################################

#RF Predictions
rf_predict(data_pfv_fee,"pago_frec_vol_fee")
rf_predict(data_pfv_promise, "pago_frec_vol_promise")
rf_predict(data_pfv,"pago_frec_vol")