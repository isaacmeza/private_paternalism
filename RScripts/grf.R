library(tidyverse)
library(grf)
library(ggplot2)

# SET WORKING DIRECTORY
setwd('C:/Users/xps-seira/Dropbox/Apps/ShareLaTeX/Donde2019')
#setwd("C:\\Users\\Ricardo\\Documents\\SEIRA\\donde2019")
set.seed(5289374)

heterogeneity_effect <- function(data_in,treatment_var,outcome_var) {
  
require("dplyr")
data_frame <- data_in %>%
  filter(data_in[,treatment_var] == 1 | data_in[,treatment_var] == 0) %>%
  select(-c( pro_2, pro_3, pro_4, pro_5 , t_producto, NombrePignorante, fecha_inicial,
             des_c, dias_al_desempenyo , 
             ref_c  , num_p , sum_porcp_c, reincidence), treatment_var, outcome_var ) %>%
  drop_na()  


# PREPARE VARIABLES
X <- select(data_frame,-c(outcome_var, treatment_var))
Y <- select(data_frame,outcome_var)
W <- as.numeric(data_frame[,treatment_var] == 1)

# ESTIMATE MODEL
tau.forest = causal_forest(
  X = model.matrix(~., data = X), 
  Y = data.matrix(Y), 
  W = W,
  honesty = TRUE)

# OVERLAP ASSUMPTION
propensity.forest = regression_forest(X, W)
propensity_score = predict(propensity.forest)$predictions
hist(propensity_score, xlab = "propensity score")

# Estimate treatment effects for the training data using out-of-bag prediction.
tau_hat_oob = predict(tau.forest, estimate.variance = TRUE)
hist(tau_hat_oob$predictions)

# Estimate the conditional average treatment effect on the full sample (CATE).
average_treatment_effect(tau.forest, target.sample = "all")

# Estimate the conditional average treatment effect on the treated sample (CATT).
# Here, we don't expect much difference between the CATE and the CATT, since
# treatment assignment was randomized.
average_treatment_effect(tau.forest, target.sample = "treated")


data.out <- add_column(data_frame,tau_hat_oob$predictions,tau_hat_oob$variance.estimates, propensity_score)
filename <- paste("_aux/grf_", treatment_var,"_",outcome_var, ".csv", sep="") 
write_csv(data.out,filename)
}

#####################################################

# READ DATASET
# Prenda level
data <- read_csv('./_aux/heterogeneity_grf.csv')
#data <- read_csv('C:\\Users\\Ricardo\\Documents\\SEIRA\\donde2019\\_aux\\heterogeneity_grf.csv')

# Customer level
data_customer <- data %>% 
  select(-c(dummy_prenda_tipo1, dummy_prenda_tipo2, dummy_prenda_tipo3, dummy_prenda_tipo4,
            dummy_choose_same1,dummy_choose_same2, visit_number)) %>%
  group_by(NombrePignorante , fecha_inicial) %>% summarise_all(funs(mean))%>%
  arrange(NombrePignorante , fecha_inicial) %>%
  group_by(NombrePignorante) %>% filter(row_number(prestamo) == 1) %>% as.data.frame()


#Heterogeneous Effects
for (t in c("pro_2", "pro_3", "pro_4", "pro_5")) {
  for (dep in c("des_c", "dias_al_desempenyo", "num_p" , "sum_porcp_c", "ref_c" )) {
    heterogeneity_effect(data,t,dep) 
  }
  heterogeneity_effect(data_customer,t,"reincidence") 
}

