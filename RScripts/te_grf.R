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

source("./RScripts/best_tree.R")

fun_threshold_alpha = function(alpha, g) {
  lambda = 1/(alpha*(1-alpha))
  ind = (g<=lambda)
  den = sum(ind)
  num = ind*g
  return((2*sum(num)/den-lambda)^2)
}


te_grf <- function(data_in, outcome_var, name) {
  
  require("dplyr")
  data_in <- data_in %>%
    mutate_all(~ifelse(is.na(.), median(., na.rm = TRUE), .))  
  data_copy <- data_in
  data_in <- rename.vars(data_in, c(
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
  
  require("dplyr")
  
  data_train <- data_in %>% 
    filter(insample == 1) 
  
  data_test <- data_in %>% 
    select(-c(outcome_var, fee_arms, prenda, insample))
  
  ###################################################################  
  ###################################################################  
  
  
  # PREPARE VARIABLES
  X <- select(data_train,-c(outcome_var, fee_arms, prenda, insample))
  Y <- select(data_train,outcome_var)
  W <- as.numeric(data_train$fee_arms == 1)

  ###################################################################  
  ###################################################################  
  
  # Estimation of E[Y | X , W = 1] and E[Y | X , W = 0]
  X1 = X[W==1,]
  X0 = X[W==0,]
  Y1 = as.numeric(unlist(Y[W==1,]))
  Y0 = as.numeric(unlist(Y[W==0,]))
  
  mu.1 = regression_forest(X1,Y1,
    num.trees = 3000,
    sample.weights = NULL,
    clusters = NULL,
    equalize.cluster.weights = FALSE,
    sample.fraction = 0.5,
    mtry = min(ceiling(sqrt(ncol(X)) + 20), ncol(X)),
    min.node.size = 5,
    honesty = TRUE,
    honesty.fraction = 0.5,
    honesty.prune.leaves = TRUE,
    alpha = 0.05,
    imbalance.penalty = 0,
    ci.group.size = 2,
    tune.parameters = c("alpha", "imbalance.penalty"),
    tune.num.trees = 500,
    tune.num.reps = 200,
    tune.num.draws = 2000,
    compute.oob.predictions = TRUE,
    num.threads = NULL,
    seed = 1)
  
  pr_mu1 = predict(mu.1, data_test, estimate.variance = TRUE)
  
  mu.0 = regression_forest(X0,Y0,
    num.trees = 3000,
    sample.weights = NULL,
    clusters = NULL,
    equalize.cluster.weights = FALSE,
    sample.fraction = 0.5,
    mtry = min(ceiling(sqrt(ncol(X)) + 20), ncol(X)),
    min.node.size = 5,
    honesty = TRUE,
    honesty.fraction = 0.5,
    honesty.prune.leaves = TRUE,
    alpha = 0.05,
    imbalance.penalty = 0,
    ci.group.size = 2,
    tune.parameters = c("alpha", "imbalance.penalty"),
    tune.num.trees = 500,
    tune.num.reps = 200,
    tune.num.draws = 2000,
    compute.oob.predictions = TRUE,
    num.threads = NULL,
    seed = 1)
  
  pr_mu0 = predict(mu.0, data_test, estimate.variance = TRUE)
  
  # OVERLAP ASSUMPTION
  propensity.forest = regression_forest(X, W)
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
  
  X <- X[propensity_score>=alfa & propensity_score<=(1-alfa),]
  Y <- Y[propensity_score>=alfa & propensity_score<=(1-alfa),]
  W <- W[propensity_score>=alfa & propensity_score<=(1-alfa)]

  # ESTIMATE MODEL
  
  
  # Causal Forest
  tau.forest = causal_forest(
    X = model.matrix(~., data = X), 
    Y = data.matrix(Y), 
    W = W,
    Y.hat = NULL,
    W.hat = NULL,
    clusters = NULL,
    num.trees = 5000,
    sample.weights = NULL,
    equalize.cluster.weights = FALSE,
    sample.fraction = 0.5,
    mtry = min(ceiling(sqrt(ncol(X)) + 20), ncol(X)),
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
  tau_hat_oob = predict(tau.forest, model.matrix(~., data = data_test), estimate.variance = TRUE)
  hist(tau_hat_oob$predictions)
  
  # Save ATE results
  ate <- data.frame(rbind(average_treatment_effect(tau.forest, target.sample = "all", method = "AIPW"),
                          average_treatment_effect(tau.forest, target.sample = "overlap", method = "AIPW"),
                          average_treatment_effect(tau.forest, target.sample = "treated", method = "AIPW"),
                          average_treatment_effect(tau.forest, target.sample = "control",  method = "AIPW")))
  ate <- cbind(ate, c("all", "overlap", "treated", "control"))
  colnames(ate) <- c("beta", "se", "target_sample")
  filename_ate <- paste("_aux/", name, "_te_ate.csv", sep="")
  write_csv(ate, filename_ate)
  print(ate)
  
  # BEST TREE
  best_tree_info <- find_best_tree(tau.forest, "causal")
  
  # Tree Plot
  tree.plot = plot(get_tree(tau.forest, best_tree_info$best_tree))
  filename_pl <- paste("Figuras/crf_", name, ".svg", sep="") 
  cat(DiagrammeRsvg::export_svg(tree.plot), file=filename_pl)
  
  # Causal Tree
  tree <- causalTree(as.formula(paste(outcome_var, ". -fee_arms-prenda-insample", sep=" ~ ")) ,
                     data = data_train, treatment = data_train$fee_arms,
                     split.Rule = "CT", cv.option = "CT", split.Honest = T, cv.Honest = T, split.Bucket = F, 
                     xval = 5, cp = 0, minsize = 20, propensity = 0.5)
  opcp <- tree$cptable[,1][which.min(tree$cptable[,4])]
  opfit <- prune(tree, opcp)
  filename_gg <- paste("Figuras/ct_", name, ".pdf", sep="")
  ct <- pdf(filename_gg)
  fancyRpartPlot(opfit,  palettes=c("Blues", "BuGn"), sub="") 
  dev.off()
  cat(ct)
  
  # Fit-the-Fit
  X_narrow <- select(data_test,c(age,female,makes.budget,more.high.school))
  Y_fit <- tau_hat_oob$predictions
  fit_fit = regression_forest(X_narrow,Y_fit,
                              num.trees = 3000,
                              sample.weights = NULL,
                              clusters = NULL,
                              equalize.cluster.weights = FALSE,
                              sample.fraction = 0.5,
                              mtry = min(ceiling(sqrt(ncol(X)) + 20), ncol(X)),
                              min.node.size = 5,
                              honesty = TRUE,
                              honesty.fraction = 0.5,
                              honesty.prune.leaves = TRUE,
                              alpha = 0.05,
                              imbalance.penalty = 0,
                              ci.group.size = 2,
                              tune.parameters = c("alpha", "imbalance.penalty"),
                              tune.num.trees = 500,
                              tune.num.reps = 200,
                              tune.num.draws = 2000,
                              compute.oob.predictions = TRUE,
                              num.threads = NULL,
                              seed = 1)
  pr_narrow = predict(fit_fit, estimate.variance = TRUE)
  
  # Variable importance
  var_imp <- variable_importance(tau.forest)
  var_imp <- data.frame(var_imp[2:length(var_imp)])
  var_imp <- cbind(var_imp, colnames(X))
  colnames(var_imp) <- c("Variable Importance", "Variable")
  filename_vi <- paste("Figuras/var_imp_", name, ".pdf", sep="")
  ggplot(var_imp, mapping = aes(x = `Variable Importance`, y = Variable)) +
    geom_point() +
    xlab("Variable Importance") + 
    ylab("Variable") +
    theme_few()
  ggsave(filename_vi)
  
  # Best linear projection of the conditional average treatment effect on covariates
  blp <- tidy(best_linear_projection(tau.forest, X))
  print(blp)
  # Individual effects
  ind_blp = blp[FALSE,]
  for(i in names(X)){
    ind_blp = rbind(ind_blp,tidy(best_linear_projection(tau.forest, X[i])))
  }
  ind_blp <- ind_blp[ind_blp$term!="(Intercept)",]
  colnames(ind_blp) <- c("term","estimate_i", "std.error_i", "statistic_i", "p.value_i")
  blp <- merge(ind_blp, blp, by=c("term"))
  filename_blp <- paste("_aux/", name, "_te_blp.csv", sep="")
  write_csv(blp, filename_blp)
  
  
  # Assessing heterogeneity
  
  # Computes the best linear fit of the target estimand using the forest prediction 
  # (on held-out data) as well as the mean forest prediction as the sole two regressors.
  # A coefficient of 1 for 'mean.forest.prediction' suggests that the mean forest 
  # prediction is correct, whereas a coefficient of 1 for 'differential.forest.prediction'
  # additionally suggests that the forest has captured heterogeneity in the underlying signal. 
  # The p-value of the ‘differential.forest.prediction‘coefficient also acts as an omnibus test 
  # the presence of heterogeneity: If the coefficient is significantly greater than 0, 
  # then we can reject the null of no heterogeneity.
  
  tc <- tidy(test_calibration(tau.forest))
  print(tc)
  filename_tc <- paste("_aux/", name, "_te_tc.csv", sep="")
  write_csv(tc,filename_tc)
  
  # Save results
  data.out <- add_column(data_copy, tau_hat_oob$predictions, tau_hat_oob$variance.estimates,
                         pr_mu1$predictions, pr_mu1$variance.estimates,
                         pr_mu0$predictions, pr_mu0$variance.estimates,
                         pr_narrow$predictions, pr_narrow$variance.estimates)
  filename_out <- paste("_aux/", name, "_te_grf.csv", sep="")
  write_csv(data.out, filename_out)
}  
 

#####################################################

# READ DATASET
apr <- read_csv('./_aux/apr_te_heterogeneity.csv') 

#####################################################
te_grf(apr,"apr","apr") 

