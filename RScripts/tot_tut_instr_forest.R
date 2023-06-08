library(gdata)
library(tidyverse)
library(grf)
library(ggplot2)
library(ggthemes)
library(causalTree)
library(DiagrammeR)
library(DiagrammeRsvg)
library(rattle)
library(broom)

# SET WORKING DIRECTORY
setwd('C:/Users/isaac/Dropbox/Apps/Overleaf/Donde2022')
set.seed(1)


rename_var = function(df) { 
  df <- rename.vars(df, c(
    "dummy_dow2",
    "dummy_dow3",
    "dummy_dow4",
    "dummy_dow5",
    "dummy_dow6",
    "dummy_suc2",
    "dummy_suc3",
    "dummy_suc4",
    "dummy_suc5",
    "dummy_suc6",
    "edad",
    "faltas",
    "c_trans",
    "t_llegar",
    "fam_pide",
    "ahorros",
    "t_consis1",
    "t_consis2", 
    "confidence_100",
    "hace_presupuesto",
    "tentado",
    "rec_cel",
    "pres_antes",
    "cta_tanda",
    "genero",
    "masqueprepa",
    "estresado_seguido"
  ),
  c(
    "tuesday",
    "wednesday",
    "thurdsay",
    "friday",
    "saturday",
    "branch.2",
    "branch.3",
    "branch.4",
    "branch.5",
    "branch.6",
    "age",
    "trouble.paying.bills",
    "transport.cost",
    "transport.time",
    "fam.asks",
    "savings",
    "patience",
    "future.patience", 
    "sure.confidence",
    "makes.budget",
    "tempted",
    "sms.reminder",
    "pawn.before",
    "rosca",
    "female",
    "more.high.school",
    "stressed"
  ))
}

fun_threshold_alpha = function(alpha, g) {
  lambda = 1/(alpha*(1-alpha))
  ind = (g<=lambda)
  den = sum(ind)
  num = ind*g
  return((2*sum(num)/den-lambda)^2)
}

opt_alfa = function(xvar, wvar) {
  propensity.forest = regression_forest(xvar, wvar)
  propensity_score = predict(propensity.forest)$predictions
  propensity_score[propensity_score==1] <- 0.99
  propensity_score[propensity_score==0] <- 0.01
  hist(propensity_score, xlab = "propensity score")
  
  # Dropping observations with extreme values of the propensity score - CHIM (2009)
  g <- 1/(propensity_score*(1-propensity_score))
  
  # One finds the smallest value of \alpha\in [0,0.5] s.t.
  # $\lambda:=\frac{1}{\alpha(1-\alpha)}$
  # $2\frac{\sum 1(g(X)\leq\lambda)*g(X)}{\sum 1(g(X)\leq\lambda)}-\lambda\geq 0$
  # 
  # Equivalently the first value of alpha (in increasing order) such that the constraint is achieved by equality
  # (as the constraint is a monotone increasing function in alpha)
  
  alfa = optimize(fun_threshold_alpha, g, interval=c(0.001, 0.499))$minimum
  return(alfa)
}

fit_instr_forest = function(xvar, wvar, yvar, zvar, dta, nme) {
  # Instrumental Forest
  inst.forest = instrumental_forest(
    X = model.matrix(~., data = xvar), 
    Y = data.matrix(yvar), 
    W = wvar,
    Z = zvar,
    num.trees = 5000,
    sample.weights = NULL,
    equalize.cluster.weights = FALSE,
    sample.fraction = 0.5,
    min.node.size = 5,
    honesty = TRUE,
    honesty.fraction = 0.5,
    honesty.prune.leaves = TRUE,
    alpha = 0.05,
    imbalance.penalty = 0,
    stabilize.splits = TRUE,
    ci.group.size = 2,
    tune.parameters = c("alpha", "imbalance.penalty"),
    tune.num.trees = 500,
    tune.num.reps = 200,
    tune.num.draws = 2000,
    compute.oob.predictions = TRUE,
    num.threads = NULL,
    seed = 1)
  
  # Estimate treatment effects for the training data using out-of-bag prediction.
  inst_hat_oob = predict(inst.forest, estimate.variance = TRUE)
  hist(inst_hat_oob$predictions)
  
  # Variable importance
  var_imp <- variable_importance(inst.forest)
  var_imp <- data.frame(var_imp[2:length(var_imp)])
  var_imp <- cbind(var_imp, colnames(xvar))
  colnames(var_imp) <- c("Variable Importance", "Variable")
  filename_vi <- paste("Figuras/var_imp_", nme, ".pdf", sep="")
  ggplot(var_imp, mapping = aes(x = `Variable Importance`, y = Variable)) +
    geom_point() +
    xlab("Variable Importance") + 
    ylab("Variable") +
    theme_few()
  ggsave(filename_vi)
  
  # Save results
  data.out <- add_column(dta, inst_hat_oob$predictions, inst_hat_oob$variance.estimates)
  filename_out <- paste("_aux/", nme, "_instr_forest.csv", sep="")
  write_csv(data.out, filename_out)
}  



###################################################################  
###################################################################  

require("dplyr")

tot_tut <- read_csv('./_aux/tot_tut_apr.csv') 

data_in <- tot_tut %>%
  mutate_all(~ifelse(is.na(.), median(., na.rm = TRUE), .))  

tot <- data_in %>% 
  filter(esample_tot == 1) 
tut <- data_in %>% 
  filter(esample_tut == 1) 

tot_copy <- tot
tut_copy <- tut

rename_var(tot)
rename_var(tut)

# PREPARE VARIABLES
X_tot <- select(tot,-c(apr, forced, choice_arm, 
                       esample_tot, esample_tut, prenda))
Y_tot <- select(tot,apr)
W_tot <- as.numeric(tot$forced == 1)
Z_tot <- as.numeric(tot$choice_arm == 1)

X_tut <- select(tut,-c(apr, forced, choice_arm, 
                       esample_tot, esample_tut, prenda))
Y_tut <- select(tut,apr)
W_tut <- as.numeric(tut$forced == 1)
Z_tut <- as.numeric(tut$choice_arm == 1)

###################################################################  
###################################################################  


# OVERLAP ASSUMPTION
alfa <- mapply(opt_alfa, list(X_tot, X_tut),  list(W_tot, W_tut))
print(alfa)  


# ESTIMATE MODEL
mapply(fit_instr_forest, list(X_tot, X_tut),  list(W_tot, W_tut), list(Y_tot, Y_tut), list(Z_tot, Z_tut),
       list(tot_copy, tut_copy), c("tot_apr", "tut_apr"))

