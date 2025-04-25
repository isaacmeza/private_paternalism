library(tidyverse)   # Loads dplyr, readr, etc.
library(gdata)
library(grf)
library(MCMCpack)
library(parallel)

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
    "prestamo",
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
    "estresado_seguido",
    "na_edad",
    "na_faltas",
    "na_c_trans",
    "na_t_llegar",
    "na_fam_pide",
    "na_ahorros",
    "na_t_consis1",
    "na_t_consis2", 
    "na_confidence_100",
    "na_hace_presupuesto",
    "na_tentado",
    "na_rec_cel",
    "na_pres_antes",
    "na_cta_tanda",
    "na_genero",
    "na_masqueprepa",
    "na_estresado_seguido"    
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
    "loan.size",
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
    "stressed",
    "na.age",
    "na.trouble.paying.bills",
    "na.transport.cost",
    "na.transport.time",
    "na.fam.asks",
    "na.savings",
    "na.patience",
    "na.future.patience", 
    "na.sure.confidence",
    "na.makes.budget",
    "na.tempted",
    "na.sms.reminder",
    "na.pawn.before",
    "na.rosca",
    "na.female",
    "na.more.high.school",
    "na.stressed"    
  ))
}

fun_threshold_alpha = function(alpha, g) {
  lambda = 1/(alpha*(1-alpha))
  ind = (g<=lambda)
  den = sum(ind)
  num = ind*g
  return((2*sum(num)/den-lambda)^2)
}

opt_alfa <- function(xvar, wvar, yvar, zvar) {
  # Build a regression forest for propensity scores
  propensity.forest <- regression_forest(xvar, wvar)
  propensity_score <- predict(propensity.forest)$predictions
  
  # Avoid extreme values exactly equal to 0 or 1
  propensity_score[propensity_score == 1] <- 0.99
  propensity_score[propensity_score == 0] <- 0.01
  
  # Plot the histogram
  hist(propensity_score, xlab = "Propensity Score", main = "Histogram of Propensity Scores")
  
  # Compute g values and find optimal alpha via optimization
  g <- 1 / (propensity_score * (1 - propensity_score))
  alfa <- optimize(fun_threshold_alpha, g, interval = c(0.001, 0.499))$minimum
  
  # Filter the variables using initial alfa
  idx <- propensity_score >= alfa & propensity_score <= (1 - alfa)
  retained <- sum(idx)
  percent_retained <- 100 * retained / length(propensity_score)
  
  # Print initial information
  cat("-------------------------------------------------\n")
  cat("Initial optimal alpha:", alfa, "\n")
  cat("Initial retained observations:", retained, "out of", length(propensity_score), "\n")
  cat("Initial percentage retained:", round(percent_retained, 2), "%\n")
  cat("-------------------------------------------------\n")
  
  # Lock mechanism: if less than 80% retained, re-optimize on a tighter interval
  if (percent_retained < 80) {
    new_alfa <- optimize(fun_threshold_alpha, g, interval = c(0.001, 0.1))$minimum
    cat("Retained percentage <", 80, "%. Re-optimizing...\n")
    cat("New optimal alpha:", new_alfa, "\n")
    
    # Use new alfa and recalculate idx
    alfa <- new_alfa
    idx <- propensity_score >= alfa & propensity_score <= (1 - alfa)
    retained <- sum(idx)
    percent_retained <- 100 * retained / length(propensity_score)
    cat("After re-optimization, retained observations:", retained, "\n")
    cat("After re-optimization, percentage retained:", round(percent_retained, 2), "%\n")
    cat("-------------------------------------------------\n")
  }
  
  # Plot the new histogram
  hist(propensity_score[idx], xlab = "Propensity Score", main = "Histogram of adjusted Propensity Scores")
  
  # Filter the variables
  xvar_new <- xvar[idx, ]
  yvar_new <- yvar[idx, ]
  wvar_new <- wvar[idx]
  zvar_new <- zvar[idx]
  
  # Return results along with the final alfa used
  return(list(alfa = alfa, xvar = xvar_new, yvar = yvar_new, 
              wvar = wvar_new, zvar = zvar_new))
}

fit_instr_forest = function(xvar, xvar_test, wvar, yvar, zvar, dta, iter, pred_name = "pred") {
  
  # Random weights (bootstrap)
  n <- nrow(xvar)
  wt <- as.vector(rdirichlet(1, rep(1, n)))
  
  # Instrumental Forest
  inst.forest = instrumental_forest(
    X = model.matrix(~., data = xvar), 
    Y = data.matrix(yvar), 
    W = wvar,
    Z = zvar,
    num.trees = 5000,
    sample.weights = wt,
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
    seed = iter)
  
  # Estimate treatment effects for the training data using out-of-bag prediction.
  inst_hat_oob = predict(inst.forest, model.matrix(~., data = xvar_test), estimate.variance = FALSE)
  
  # Save results: add predictions and variance estimates with custom column names.
  data.out <- dplyr::mutate(dta,
                            !!paste0("inst_hat_", pred_name) := inst_hat_oob$predictions) %>% 
    filter(t_producto == 4)
  
  return(data.out)
}

compute_choose_wrong_stats <- function(df) {
  # Define threshold values from -100 to 100 by 5
  thresholds <- seq(-100, 100, by = 5)
  
  # Initialize a results data frame
  results <- data.frame(
    threshold = thresholds,
    cwf = numeric(length(thresholds)),
    cwf_choose = numeric(length(thresholds)),
    cwf_nonchoose = numeric(length(thresholds))
  )
  
  # Loop over each threshold
  for (k in seq_along(thresholds)) {
    i <- thresholds[k]
    # Convert to decimal (e.g., -100 becomes -1)
    t_val <- i / 100
    
    # For all borrowers in the choice arm (t_producto == 4) 
    df_subset <- df %>%
      filter(t_producto == 4 & (!is.na(inst_hat_0) | !is.na(inst_hat_1))) %>%
      mutate(choose_wrong_fee = ifelse((inst_hat_0 > t_val & pro_6 == 1) |
                                         (inst_hat_1 < -t_val & pro_7 == 1),
                                       1, 0))
    mean_cwf <- mean(df_subset$choose_wrong_fee, na.rm = TRUE) * 100
    
    # For "choosers": observations with pro_7 == 1 and non-missing inst_hat_1
    df_choose <- df %>%
      filter(pro_7 == 1 & !is.na(inst_hat_1)) %>%
      mutate(choose_wrong_fee_choose = ifelse(inst_hat_1 < -t_val, 1, 0))
    mean_cwf_choose <- mean(df_choose$choose_wrong_fee_choose, na.rm = TRUE) * 100
    
    # For "non-choosers": observations with pro_6 == 1 and non-missing inst_hat_0
    df_nonchoose <- df %>%
      filter(pro_6 == 1 & !is.na(inst_hat_0)) %>%
      mutate(choose_wrong_fee_nonchoose = ifelse(inst_hat_0 > t_val, 1, 0))
    mean_cwf_nonchoose <- mean(df_nonchoose$choose_wrong_fee_nonchoose, na.rm = TRUE) * 100
    
    # Store the computed means in the results data frame
    results$cwf[k] <- mean_cwf
    results$cwf_choose[k] <- mean_cwf_choose
    results$cwf_nonchoose[k] <- mean_cwf_nonchoose
  }
  
  return(results)
}



###################################################################  
###################################################################  

require("dplyr")

tot_tut <- read_csv('./_aux/tot_tut_btsp_apr.csv') 

data_in <- tot_tut %>%
  mutate_all(~ifelse(is.na(.), median(., na.rm = TRUE), .))  

tot <- data_in %>% 
  filter(esample_tot == 1) 
tut <- data_in %>% 
  filter(esample_tut == 1) 

tot_copy <- tot %>% dplyr::select(prenda, t_producto, pro_6, pro_7)
tut_copy <- tut %>% dplyr::select(prenda, t_producto, pro_6, pro_7)

rename_var(tot)
rename_var(tut)

# PREPARE VARIABLES
X_tot <- dplyr::select(tot,-c(apr, forced, choice_arm, 
                       esample_tot, esample_tut, prenda, t_producto, pro_6, pro_7))
Y_tot <- dplyr::select(tot,apr)
W_tot <- as.numeric(tot$forced == 1)
Z_tot <- as.numeric(tot$choice_arm == 1)

X_tut <- dplyr::select(tut,-c(apr, forced, choice_arm, 
                       esample_tot, esample_tut, prenda, t_producto, pro_6, pro_7))
Y_tut <- dplyr::select(tut,apr)
W_tut <- as.numeric(tut$forced == 1)
Z_tut <- as.numeric(tut$choice_arm == 1)

###################################################################  
###################################################################  

# Overlap
crump <- mapply(
  FUN = opt_alfa,
  xvar = list(X_tot, X_tut),
  wvar = list(W_tot, W_tut),
  yvar = list(Y_tot, Y_tut),
  zvar = list(Z_tot, Z_tut),
  SIMPLIFY = FALSE
)


# Define the wrapper function
fit_model_wrapper <- function(i) {
  # ESTIMATE MODEL using mapply on both datasets
  results <- mapply(
    FUN = fit_instr_forest,
    xvar = list(crump[[1]]$xvar, crump[[2]]$xvar),
    xvar_test = list(X_tot, X_tut),
    wvar = list(crump[[1]]$wvar, crump[[2]]$wvar),
    yvar = list(crump[[1]]$yvar, crump[[2]]$yvar),
    zvar = list(crump[[1]]$zvar, crump[[2]]$zvar),
    dta = list(tot_copy, tut_copy),
    iter = c(i, i),                  # Set seed for each call
    pred_name = c("1", "0"),
    SIMPLIFY = FALSE                # Return list of outputs
  )
  
  # Merge the two resulting datasets on 'prenda' and unify the common columns
  merged_data <- merge(results[[1]], results[[2]], by = "prenda", all = TRUE) %>%
    mutate(
      t_producto = coalesce(t_producto.x, t_producto.y),
      pro_6 = coalesce(pro_6.x, pro_6.y),
      pro_7 = coalesce(pro_7.x, pro_7.y)
    ) %>%
    dplyr::select(-ends_with(".x"), -ends_with(".y"))
  
  # Compute the "choose wrong fee" statistics on the merged dataset
  cwf_stats <- compute_choose_wrong_stats(merged_data)
  # Iter id
  cwf_stats$iter <- i
  
  return(cwf_stats)
}

reps <- 1:2

cl <- makeCluster(detectCores() - 2)
clusterExport(cl, varlist = c("fit_instr_forest", "compute_choose_wrong_stats", "crump", "X_tot", "X_tut", 
                              "tot_copy", "tut_copy", "W_tot", "W_tut", "Y_tot", "Y_tut", 
                              "Z_tot", "Z_tut"))

# Also, load the required packages on each worker
clusterEvalQ(cl, {
  library(tidyverse)
  library(grf)
  library(MCMCpack)
})

start_time <- Sys.time()
results_list <- parLapply(cl, reps, fit_model_wrapper)
end_time <- Sys.time()
cat("Total running time:", end_time - start_time, "\n")

stopCluster(cl)

# Combine all the results into one data frame
cw_tot_tut_btsp <- bind_rows(results_list)

# Save final results to disk
write_csv(cw_tot_tut_btsp, "./_aux/choose_wrong_tot_tut_btsp.csv")
saveRDS(cw_tot_tut_btsp, "./_aux/choose_wrong_tot_tut_btsp.rds")


###################################################################  
################################################################### 
###################################################################  
################################################################### 


library(dplyr)
library(tidyr)
library(ggplot2)


cw_tot_tut_btsp_long <- cw_tot_tut_btsp %>%
  pivot_longer(
    cols = c("cwf", "cwf_choose", "cwf_nonchoose"),
    names_to = "variable",
    values_to = "value"
  )


# Compute summary stats by threshold and variable
final_summary <- cw_tot_tut_btsp_long %>%
  group_by(threshold, variable) %>%
  summarize(
    mean_value = mean(value),
    lower_ci = quantile(value, 0.025),
    upper_ci = quantile(value, 0.975),
    .groups = "drop"
  )
write_csv(final_summary, "./_aux/cw_apr_tot_tut.csv")


# Create summary plot (mean and 95% CI across thresholds)
summary_plot <- ggplot(final_summary, aes(x = threshold, y = mean_value, color = variable)) +
  geom_line(size = 1) +
  geom_ribbon(aes(ymin = lower_ci, ymax = upper_ci, fill = variable),
              alpha = 0.2, color = NA) +
  labs(
    x = "Threshold",
    y = "Mean Value",
    title = "Mean and 95% Interval across Replicates"
  ) +
  theme_minimal()

# Create density plot for threshold == 0
density_plot <- ggplot(cw_tot_tut_btsp_long %>% filter(threshold == 0),
                       aes(x = value, fill = variable)) +
  geom_density(alpha = 0.5) +
  labs(
    x = "Metric Value",
    y = "Density",
    title = "Density at Threshold 0"
  ) +
  theme_minimal()
