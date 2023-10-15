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


* Table OA-2: Balance conditional on survey response and question-by-question response rates by treatment arm
*do "./DoFiles/analysis/ss.do"

* Table OA-3: Survey Non-response: TUT estimates for respondents to each survey question
do "./DoFiles/appendix/tut_cond_survey.do"

* Figure OA-3: Behavior of borrowers who lost their pawn
do "./DoFiles/appendix/hist_den_default.do"

* Table OA-4: Multiple-loans robustness check
do "./DoFiles/appendix/multiple_loans.do"

* Figure OA-4: Determinants of choice
do "./DoFiles/appendix/determinants_choice.do"

* Figure OA-5: Histogram of payments
do "./DoFiles/appendix/hist_payments.do"

* Table OA-5: Bounding censoring
do "./DoFiles/appendix/censoring_imp.do"
do "./DoFiles/appendix/censoring_imp_pr.do"

* Figure OA-6: Interpolation on bounding censoring
do "./DoFiles/appendix/interpolation_censoring_imp.do"

* Figure OA-7: Survival graph
do "./DoFiles/appendix/survival_graph.do"

* Figure OA-8: % of payment over time
do "./DoFiles/appendix/cumulative_porc_pay_time.do"

* Table OA-6: Effect of Prior Assignment on Subsequent Choice
do "./DoFiles/appendix/learning_exp.do"

* Figure OA-9: Financial benefit TUT effect for different discount rates
do "./DoFiles/appendix/discounted_noeffect.do"

* Figure OA-10: Empirical CDF of Financial Cost: Forced commitment vs Control
do "./DoFiles/appendix/fosd_ecdf.do"

* Figure OA-11: Distribution of treatment effects under rank invariance.
do "./DoFiles/appendix/te_rankinvariance.do"

* Figure OA-12: Determinants sure confidence
do "./DoFiles/appendix/determinants_sure_confidence.do"

* Figure OA-13: Example Causal Tree
*rscript using "./RScripts/te_grf.R", rversion(4.2.2)



