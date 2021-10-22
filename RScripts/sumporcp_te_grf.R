library(tidyverse)
library(grf)
library(ggplot2)

# SET WORKING DIRECTORY
setwd('C:/Users/isaac/Dropbox/Apps/ShareLaTeX/Donde2020')
set.seed(5289374)



data_in <- read_csv('./_aux/sumporcp_te_heterogeneity.csv') %>%
  mutate_all(~ifelse(is.na(.), median(., na.rm = TRUE), .))


require("dplyr")

data_train <- data_in %>% 
  filter(insample == 1) 
data_train_fee <- subset(data_train, data_train$fee_arms == 1)
data_train_nofee <- subset(data_train, data_train$fee_arms == 0)


data_test <- data_in %>% 
  select(-c(sum_porcp_c, fee_arms, prenda, insample))

###################################################################  
###################################################################  


# PREPARE VARIABLES
X <- select(data_train,-c(sum_porcp_c, fee_arms, prenda, insample))
Y <- select(data_train,sum_porcp_c)
W <- as.numeric(data_train$fee_arms == 1)

X_full <- select(data_in,-c(sum_porcp_c, fee_arms, prenda, insample))
Y_full <- select(data_in,sum_porcp_c)
W_full <- as.numeric(data_in$fee_arms == 1)

X_fee <- select(data_train_fee,-c(sum_porcp_c, fee_arms, prenda, insample))
Y_fee <- as.numeric(data_train_fee$sum_porcp_c)
X_nofee <- select(data_train_nofee,-c(sum_porcp_c, fee_arms, prenda, insample))
Y_nofee <- as.numeric(data_train_nofee$sum_porcp_c)

###################################################################  
###################################################################  


# ESTIMATE MODEL

# Causal Forest
tau.forest = causal_forest(
  X = model.matrix(~., data = X), 
  Y = data.matrix(Y), 
  W = W,
  honesty = TRUE)

tau.forest.full = causal_forest(
  X = model.matrix(~., data = X_full), 
  Y = data.matrix(Y_full), 
  W = W_full,
  honesty = TRUE)  
# Regression forest
pred.forest.fee = regression_forest(X_fee, Y_fee)
pred.forest.nofee = regression_forest(X_nofee, Y_nofee)

# Estimate treatment effects for the training data using out-of-bag prediction.
tau_hat_oob = predict(tau.forest, model.matrix(~., data = data_test), estimate.variance = TRUE)
hist(tau_hat_oob$predictions)
tau_hat_oob_full = predict(tau.forest.full, estimate.variance = TRUE)
hist(tau_hat_oob_full$predictions)

# RF prediction
rf_pred_fee = predict(pred.forest.fee,data_test)$predictions
hist(rf_pred_fee)
rf_pred_nofee = predict(pred.forest.nofee,data_test)$predictions
hist(rf_pred_nofee)

data.out <- add_column(data_in, rf_pred_fee, rf_pred_nofee, 
                       tau_hat_oob$predictions, tau_hat_oob$variance.estimates,
                       tau_hat_oob_full$predictions, tau_hat_oob_full$variance.estimates)
filename <- paste("_aux/sumporcp_te_grf",".csv", sep="") 
write_csv(data.out,filename)
