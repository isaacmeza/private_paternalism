********************
version 17.0
********************
/*
/*******************************************************************************
* Name of file:	master
* Author: Isaac M 

* Purpose: This is the master dofile that calls all individual dofiles necessary to replicate the main analysis in the paper. 
*******************************************************************************/
*/



************************************ Tables ************************************


* Table 1: Limited and balanced attrition 
do "./DoFiles/analysis/ss_att.do"

* Table 2: Summary statistics and Balance
do "./DoFiles/analysis/ss_balance.do"

* Table 3: Effects on Financial Cost
do "./DoFiles/analysis/decomposition_main_te.do"

* Table 4: Effects on intermediate outcomes
do "./DoFiles/analysis/mechanisms.do"

* Table 5: Effects on more comprehensive cost measures
do "./DoFiles/analysis/fc_robustness.do"

* Table 6: Effects on Repeat Pawning
do "./DoFiles/analysis/repeat_loans.do"

* Table 7: Treatment on the Treated (TOT), Treatment on the Untreated (TUT), Selection-on-gains (TOT - TUT), Average Selection Bias (ASB), and Average Selection Bias, calculated using the results from Section 5.3
do "./DoFiles/analysis/tot_tut.do"

* Table 8: Type I & II errors using targeting narrow rules
*Run CATE RF in R
rscript using "./RScripts/te_narrow_grf.R", rversion(4.2.2)
rscript using "./RScripts/te_grf.R", rversion(4.2.2)
rscript using "./RScripts/tot_tut_instr_forest.R", rversion(4.2.2)

do "./DoFiles/analysis/choose_wrong_quant_wrong_tot_tut.do"
do "./DoFiles/analysis/wide_narrow_forests.do"



*********************************** Figures ************************************


* Figure 1: Financial cost
do "./DoFiles/analysis/hist_fc.do"

* Figure 2: Experiment description
do "./DoFiles/analysis/consort.do"

* Figure 3: Contract Terms Summary

* Figure 4: Explanatory Material

* Figure 5: Fan & Park bounds for benefit in APR%
do "./DoFiles/analysis/fan_park_bnds.do"

* Figure 6: The Controlled Choice Design

* Figure 7: Partition of TUT by behavioral variables
do "./DoFiles/analysis/partition_tut.do"

* Figure 8: Heterogeneous Treatment Effects
do "./DoFiles/analysis/cate_dist.do"

* Figure 9: "Mistakes" in the choice arm
*do "./DoFiles/analysis/choose_wrong_quant_wrong_tot_tut.do"

* Figure 10: Cumulative Distribution Function of Conditional ATE Estimates
do "./DoFiles/analysis/cdf_cate.do"

* Figure 11: Conditional ATEs from "wide" and "narrow" covariate sets
*do "./DoFiles/analysis/wide_narrow_forests.do"

* Figure 12: Targeting rules
*do "./DoFiles/analysis/wide_narrow_forests.do"














