library(tidyverse)
library(grf)
library(ggplot2)


# SET WORKING DIRECTORY
setwd('C:/Users/isaac/Dropbox/Apps/ShareLaTeX/Donde2020')
set.seed(5289374)


# READ DATASET
data_oc <- read_csv('./_aux/data_oc.csv')
data_test <- data_oc %>% 
  select(-c(prenda, producto, des_c))


# PREPARE VARIABLES
X <- select(data_oc,-c(prenda, producto, des_c))
Y <- as.numeric(data_oc$des_c == 1)
  
###################################################################  
###################################################################  
  
# ESTIMATE MODEL
pred.forest = regression_forest(X, Y)
rf_des_c_pred = predict(pred.forest,data_test)$predictions
hist(rf_des_c_pred, xlab = "predictions")
  
data.out <- add_column(data_oc, rf_des_c_pred)
write_csv(data.out,"_aux/pred_oc.csv")

