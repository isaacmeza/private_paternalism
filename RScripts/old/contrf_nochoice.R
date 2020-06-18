library(tidyverse)
library(grf)
library(ggplot2)

# SET WORKING DIRECTORY
setwd('C:/Users/xps-seira/Dropbox/Apps/ShareLaTeX/Donde2019')
#setwd("C:\\Users\\Ricardo\\Documents\\SEIRA\\donde2019")
set.seed(5289374)


data_in <- read_csv('./_aux/heterogeneity_grf.csv')

require("dplyr")
data_frame <- data_in %>%
  filter(data_in[,"pro_2"] == 1 | data_in[,"pro_2"] == 0) %>%
  select(-c( pro_2, pro_3, pro_4, pro_5, pro_6, pro_7, pro_8, pro_9, fecha_inicial,
             des_c, sum_p_c, fc_admin, fc_admin_disc, fc_survey,   num_p,  sum_porcp_c, mn_p_c, mn_pdisc_c,
             dias_al_desempenyo, reincidence), pro_2, des_c ) %>%
  drop_na()  
  
  
# PREPARE VARIABLES
X <- select(data_frame,-c(des_c, pro_2,NombrePignorante, prenda))
Y <- select(data_frame,des_c)
W <- as.numeric(data_frame[,"pro_2"] == 1)
  
# ESTIMATE MODEL
tau.forest = causal_forest(
  X = model.matrix(~., data = X), 
  Y = data.matrix(Y), 
  W = W,
  honesty = TRUE)
  


# Estimate treatment effects for the test data using out-of-bag prediction.
data_test <- data_in %>%
  filter(data_in[,"pro_4"] == 1 | data_in[,"pro_4"] == 0 | data_in[,"pro_5"] == 1) %>%
  select(-c( pro_2, pro_3, pro_4, pro_5, pro_6, pro_7, pro_8, pro_9, fecha_inicial,
             des_c, sum_p_c, fc_admin, fc_admin_disc, fc_survey,   num_p,  sum_porcp_c, mn_p_c, mn_pdisc_c,
             dias_al_desempenyo, reincidence, NombrePignorante)) %>%
  drop_na()    

X.test <- select(data_test,-c(prenda))

tau_hat_oob = predict(tau.forest,  model.matrix(~., data = X.test), estimate.variance = TRUE)

data.out <- cbind(data_test$prenda,tau_hat_oob$predictions,
                  tau_hat_oob$variance.estimates) %>% as.data.frame()
colnames(data.out) <- c("prenda", "tau_hat_oobpredictions", 
                        "tau_hat_oobvarianceestimates")

write_csv(data.out,"_aux/counterfactual_nochoice_inchoicearms.csv")

