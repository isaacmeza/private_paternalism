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
setwd('C:/Users/isaac/Dropbox/Apps/ShareLaTeX/Donde2020')
set.seed(5289364)

source("./RScripts/best_tree.R")

fun_threshold_alpha = function(alpha, g) {
  lambda = 1/(alpha*(1-alpha))
  ind = (g<=lambda)
  den = sum(ind)
  num = ind*g
  return((2*sum(num)/den-lambda)^2)
}


heterogeneity_effect <- function(data_in,treatment_var,outcome_var,writedata,extendedsample) {
  
  require("dplyr")
  data_frame <- data_in %>%
    filter(data_in[,treatment_var] == 1 | data_in[,treatment_var] == 0) %>%
    select(-c( pro_2, pro_3, pro_4, pro_5, pro_6, pro_7, pro_8, pro_9, fee, fecha_inicial,
               apr, eff_cost_loan, def_c, des_c, fc_admin), 
           treatment_var, outcome_var ) %>%
    mutate_all(~ifelse(is.na(.), median(., na.rm = TRUE), .))  
  data_copy <- data_frame
  
  if (extendedsample == 0) {
    # Data with names in english
    data_frame <- rename.vars(data_frame, c(
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
      "num_arms_d3",
      "num_arms_d4",
      "num_arms_d5",
      "num_arms_d6", 
      "visit_number_d2", 
      "visit_number_d3", 
      "visit_number_d4", 
      "visit_number_d5", 
      "visit_number_d6", 
      "visit_number_d7",
      "log_prestamo",
      "pr_recup",
      "edad",
      "faltas",
      "val_pren_std",
      "genero",
      "pres_antes",
      "plan_gasto_bin",
      "masqueprepa",
      "pb"
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
      "num.exp.arms.3",
      "num.exp.arms.4",
      "num.exp.arms.5",
      "num.exp.arms.6",
      "visit.number.2",
      "visit.number.3",
      "visit.number.4",
      "visit.number.5",
      "visit.number.6",
      "visit.number.7",
      "log.loan",
      "subj.pr",
      "age",
      "income.index",
      "subj.loan.value",
      "female",
      "pawn.before",
      "makes.budget",
      "more.high.school",
      "pb"
    ))
  }
  
  # PREPARE VARIABLES
  X <- select(data_frame,-c(outcome_var, treatment_var,NombrePignorante, prenda))
  test <- X
  Y <- select(data_frame,outcome_var)
  W <- as.numeric(data_frame[,treatment_var] == 1)
  
  # OVERLAP ASSUMPTION
  propensity.forest = regression_forest(X, W)
  propensity_score = predict(propensity.forest)$predictions
  propensity_score[propensity_score==1] <- 0.99
  propensity_score[propensity_score==0] <- 0.01
  
  # Dropping observations with extreme values of the propensity score - CHIM (2009)
  g <- 1/(propensity_score*(1-propensity_score))
  
  # One finds the smallest value of \alpha\in [0,0.5] s.t.
  # $\lambda:=\frac{1}{\alpha(1-\alpha)}$
  # $2\frac{\sum 1(g(X)\leq\lambda)*g(X)}{\sum 1(g(X)\leq\lambda)}-\lambda\geq 0$
  # 
  # Equivalently the first value of alpha (in increasing order) such that the constraint is achieved by equality
  # (as the constraint is a monotone increasing function in alpha)
  
  alfa = optimize(fun_threshold_alpha, g, interval=c(0.001, 0.49))$minimum

  X <- X[propensity_score>=alfa & propensity_score<=(1-alfa),]
  Y <- Y[propensity_score>=alfa & propensity_score<=(1-alfa),]
  W <- W[propensity_score>=alfa & propensity_score<=(1-alfa)]

  propensity_score[propensity_score<alfa | propensity_score>(1-alfa)] <- NA
  hist(propensity_score, xlab = "propensity score")
  
  # ESTIMATE MODEL
  # Causal Forest
  tau.forest = causal_forest(
    X = model.matrix(~., data = X), 
    Y = data.matrix(Y), 
    W = W,
    Y.hat = NULL,
    W.hat = NULL,
    num.trees = 2000,
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
    stabilize.splits = TRUE,
    ci.group.size = 2,
    tune.parameters = "none",
    tune.num.trees = 200,
    tune.num.reps = 50,
    tune.num.draws = 1000,
    compute.oob.predictions = TRUE,
    num.threads = NULL,
    seed = runif(1, 0, .Machine$integer.max))
  
  
  # Estimate treatment effects for the training data using out-of-bag prediction.
  tau_hat_oob = predict(tau.forest, 
                        model.matrix(~., data = test),
                        estimate.variance = TRUE)
  hist(tau_hat_oob$predictions)

  # Save ATE results
  ate <- data.frame(rbind(average_treatment_effect(tau.forest, target.sample = "all", method = "AIPW"),
                          average_treatment_effect(tau.forest, target.sample = "overlap", method = "AIPW"),
                          average_treatment_effect(tau.forest, target.sample = "treated", method = "AIPW"),
                          average_treatment_effect(tau.forest, target.sample = "control",  method = "AIPW")))
  ate <- cbind(ate, c("all", "overlap", "treated", "control"))
  colnames(ate) <- c("beta", "se", "target_sample")
  print(ate)
  
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
  
  #Write data
  if (writedata == 1) {
    
    data.out <- add_column(data_copy,tau_hat_oob$predictions,tau_hat_oob$variance.estimates, propensity_score)
    if (extendedsample == 1) {
      
      filename_ate <- paste("_aux/grf_extended_", treatment_var,"_",outcome_var, "_ate.csv", sep="") 
      filename_tc <- paste("_aux/grf_extended_", treatment_var,"_",outcome_var, "_tc.csv", sep="") 
      filename_out <- paste("_aux/grf_extended_", treatment_var,"_",outcome_var, ".csv", sep="") 
      
    } else {
      
      # Variable importance
      var_imp <- variable_importance(tau.forest)
      var_imp <- data.frame(var_imp[2:length(var_imp)])
      var_imp <- cbind(var_imp, colnames(X))
      colnames(var_imp) <- c("Variable Importance", "Variable")
      filename_gg <- paste("Figuras/var_imp_", treatment_var,"_",outcome_var, ".pdf", sep="") 
      ggplot(var_imp, mapping = aes(x = `Variable Importance`, y = Variable)) +
        geom_point() +
        xlab("Variable Importance") + 
        ylab("Variable") +
        theme_few()
      ggsave(filename_gg)
      
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
      
      filename_blp <- paste("_aux/grf_", treatment_var,"_",outcome_var, "_blp.csv", sep="") 
      write_csv(blp, filename_blp)
      
      filename_ate <- paste("_aux/grf_", treatment_var,"_",outcome_var, "_ate.csv", sep="") 
      filename_tc <- paste("_aux/grf_", treatment_var,"_",outcome_var, "_tc.csv", sep="") 
      filename_out <- paste("_aux/grf_", treatment_var,"_",outcome_var, ".csv", sep="") 
    }
    
    write_csv(tc, filename_tc)
    write_csv(ate, filename_ate)
    write_csv(data.out,filename_out)
    
  } else {
    
    # BEST TREE
    best_tree_info <- find_best_tree(tau.forest, "causal")
    
    # Tree Plot
    tree.plot = plot(get_tree(tau.forest, best_tree_info$best_tree))
    filename_pl <- paste("Figuras/crf_", treatment_var,"_",outcome_var, ".svg", sep="") 
    cat(DiagrammeRsvg::export_svg(tree.plot), file=filename_pl)
    
    # Causal Tree
    tree <- causalTree(data.matrix(select(data_frame,outcome_var)) ~ . -NombrePignorante -prenda ,
                       data = select(data_frame,-c(outcome_var)), 
                       treatment = as.numeric(data_frame[,treatment_var] == 1),
                       split.Rule = "CT", cv.option = "CT", split.Honest = T, cv.Honest = T, split.Bucket = F, 
                       xval = 5, cp = 0, minsize = 20, propensity = 0.5)
    opcp <- tree$cptable[,1][which.min(tree$cptable[,4])]
    opfit <- prune(tree, opcp)
    filename_ct <- paste("Figuras/ct_", treatment_var,"_",outcome_var, ".pdf", sep="") 
    ct <- pdf(filename_ct)
    fancyRpartPlot(opfit,  palettes=c("Blues", "BuGn"), sub="") 
    dev.off()
    cat(ct)
    
  }
  
}
#####################################################

# READ DATASET
# Prenda level
data_extended <- read_csv('./_aux/heterogeneity_te.csv')
data <- read_csv('./_aux/heterogeneity_grf.csv')


#Heterogeneous Effects
for (arm in c("pro_2")){
  for (dep in c("apr", "eff_cost_loan", "def_c", "des_c", "fc_admin")){
    heterogeneity_effect(data_extended,arm,dep,1,1) 
    heterogeneity_effect(data,arm,dep,1,0) 
  }
}


# Plot tree with names in english
heterogeneity_effect(data,"pro_2","apr",0,0) 

