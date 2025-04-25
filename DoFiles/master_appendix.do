********************
version 17.0
********************
/*
/*******************************************************************************
* Name of file:	master_appendix
* Author: Isaac M 

* Purpose: This is the master dofile that calls all individual dofiles necessary to replicate results in the appendix. 
*******************************************************************************/
*/



********************************** Appendix ************************************

* Figure OA-1: Behavior of borrowers who lost their pawn
do "./DoFiles/appendix/hist_den_default.do"

* Figure OA-2: Weekly default rates experimental branches and all branches
do "./DoFiles/appendix/weekly_def_rates.do"

* Figure OA-3: Determinants of choice
do "./DoFiles/appendix/determinants_choice.do"

* Table OA-2: Effects on intermediate outcomes
do "./DoFiles/appendix/mechanisms.do"

* Table OA-3: Bounding censoring
do "./DoFiles/appendix/censoring_imp.do"
do "./DoFiles/appendix/censoring_imp_pr.do"

* Figure OA-4: Survival graph
do "./DoFiles/appendix/survival_graph.do"

* Table OA-4: Effects on more comprehensive cost measures
do "./DoFiles/appendix/fc_robustness.do"

* Table OA-5: Effects on Repeat Pawning
do "./DoFiles/appendix/repeat_loans.do"

* Table OA-6: Lender's Profit
do "./DoFiles/appendix/lenders_profit.do"

* Table OA-7: Effect of Prior Assignment on Subsequent Choice
do "./DoFiles/appendix/learning_exp.do"

* Figure OA-5: Financial benefit TUT effect for different discount rates
do "./DoFiles/appendix/discounted_noeffect.do"

* Figure OA-6: Heterogeneity of the TUT by behavioral variables
do "./DoFiles/appendix/partition_tut.do"

* Figure OA-7: Determinants sure confidence
do "./DoFiles/appendix/determinants_sure_confidence.do"

* Figure OA-8: Fan & Park bounds for benefit in APR%
do "./DoFiles/appendix/fan_park_bnds.do"

* Figure OA-9: Distribution of treatment effects under rank invariance.
do "./DoFiles/appendix/te_rankinvariance.do"

* Figure OA-10:  Conditional ATEs from "wide" and "narrow" covariate sets
*do "./DoFiles/analysis/wide_narrow_forests.do"

