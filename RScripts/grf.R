library(tidyverse)
library(grf)
library(ggplot2)
library(DiagrammeR)
library(DiagrammeRsvg)
library(gdata)

# SET WORKING DIRECTORY
setwd('C:/Users/xps-seira/Dropbox/Apps/ShareLaTeX/Donde2020')
set.seed(5289374)

source("./RScripts/best_tree.R")

heterogeneity_effect <- function(data_in,treatment_var,outcome_var,writedata) {
  
require("dplyr")
data_frame <- data_in %>%
  filter(data_in[,treatment_var] == 1 | data_in[,treatment_var] == 0) %>%
  select(-c( pro_2, pro_3, pro_4, pro_5, pro_6, pro_7, pro_8, pro_9, fee, fecha_inicial,
             def_c, fc_admin_disc, fc_survey_disc, fc_admin, fc_survey, dias_primer_pago), 
         treatment_var, outcome_var ) %>%
  drop_na()  


# PREPARE VARIABLES
X <- select(data_frame,-c(outcome_var, treatment_var,NombrePignorante, prenda))
Y <- select(data_frame,outcome_var)
W <- as.numeric(data_frame[,treatment_var] == 1)

# ESTIMATE MODEL
tau.forest = causal_forest(
  X = model.matrix(~., data = X), 
  Y = data.matrix(Y), 
  W = W,
  honesty = TRUE)

if (writedata == 0) {
  # BEST TREE
  best_tree_info <- find_best_tree(tau.forest, "causal")
}

# OVERLAP ASSUMPTION
propensity.forest = regression_forest(X, W)
propensity_score = predict(propensity.forest)$predictions
hist(propensity_score, xlab = "propensity score")

# Estimate treatment effects for the training data using out-of-bag prediction.
tau_hat_oob = predict(tau.forest, estimate.variance = TRUE)
hist(tau_hat_oob$predictions)

# Estimate the conditional average treatment effect on the full sample (CATE).
print(average_treatment_effect(tau.forest, target.sample = "all"))

# Estimate the conditional average treatment effect on the treated sample (CATT).
# Here, we don't expect much difference between the CATE and the CATT, since
# treatment assignment was randomized.
print(average_treatment_effect(tau.forest, target.sample = "treated"))

#The (conditional) average treatment effect on the controls 
print(average_treatment_effect(tau.forest, target.sample = "control"))

#Write data
data.out <- add_column(data_frame,tau_hat_oob$predictions,tau_hat_oob$variance.estimates, propensity_score)
filename <- paste("_aux/grf_", treatment_var,"_",outcome_var, ".csv", sep="") 
if (writedata == 1) {
  write_csv(data.out,filename)
}
if (writedata == 0) {
  # Tree Plot
  tree.plot = plot(get_tree(tau.forest, best_tree_info$best_tree))
  filename_pl <- paste("Figuras/crf_", treatment_var,"_",outcome_var, ".svg", sep="") 
  cat(DiagrammeRsvg::export_svg(tree.plot), file=filename_pl)
}
}
#####################################################

# READ DATASET
# Prenda level
data <- read_csv('./_aux/heterogeneity_grf.csv')
# Data with names in english
data_copy <- data
data_copy <- rename.vars(data_copy, c(
  "dummy_dow1",
  "dummy_dow2",
  "dummy_dow3",
  "dummy_dow4",
  "dummy_dow5",
  "dummy_dow6",
  "dummy_suc1",
  "dummy_suc2",
  "dummy_suc3",
  "dummy_suc4",
  "dummy_suc5",
  "dummy_suc6",
  "prestamo",
  "pr_recup",
  "edad",
  "visit_number",
  "num_arms",
  "faltas",
  "genero",
  "pres_antes",
  "fam_pide",
  "fam_comun",
  "ahorros",
  "cta_tanda",
  "renta",
  "comida",
  "medicina",
  "luz",
  "gas",
  "telefono",
  "agua",
  "masqueprepa",
  "estresado_seguido",
  "OC",
  "pb",
  "fb",
  "hace_presupuesto",
  "tentado",
  "low_cost",
  "low_time",
  "rec_cel"
),
c(
  "monday",
  "tuesday",
  "wednesday",
  "thurdsay",
  "friday",
  "saturday",
  "branch.1",
  "branch.2",
  "branch.3",
  "branch.4",
  "branch.5",
  "branch.6",
  "loan",
  "subj.pr",
  "age",
  "number.of.visit",
  "number.of.treatment.arms",
  "income.index",
  "female",
  "pawn.before",
  "fam.asks",
  "common.asks",
  "savings",
  "rosca",
  "rent",
  "food",
  "medicine",
  "electricity",
  "gas",
  "telephone",
  "water",
  "more.high.school",
  "stressed",
  "overconfident",
  "pb",
  "fb",
  "makes.budget",
  "tempted",
  "low.cost",
  "low.time",
  "reminder"
))



#Heterogeneous Effects

for (dep in c("fc_admin_disc", "def_c")){
  heterogeneity_effect(data,"pro_2",dep,1) 
  heterogeneity_effect(data,"pro_3",dep,1) 
  heterogeneity_effect(data,"pro_4",dep,1) 
  heterogeneity_effect(data,"pro_5",dep,1) 
}


  heterogeneity_effect(data,"pro_2","dias_primer_pago",1) 

  # Plot tree with names in english
  heterogeneity_effect(data_copy,"pro_2","fc_admin_disc",0) 

