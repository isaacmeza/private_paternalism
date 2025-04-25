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


* Table 1: No selection across arms
do "./DoFiles/analysis/ss_att.do"

* Table 2: Borrower's characteristics are balanced
do "./DoFiles/analysis/ss_balance.do"

* Table 3: Effects on Financial Cost
do "./DoFiles/analysis/decomposition_main_te.do"

* Table 4: Five Treatment Effects Estimates: TOT, TUT, ASG, ASB, ASL
do "./DoFiles/analysis/tot_tut.do"

* Table 5: Type I & II errors using targeting narrow rules
*Run CATE RF in R
rscript using "./RScripts/te_narrow_grf.R", rversion(4.2.2)
rscript using "./RScripts/te_grf.R", rversion(4.2.2)
rscript using "./RScripts/tot_tut_instr_forest.R", rversion(4.2.2)

do "./DoFiles/analysis/choose_wrong_quant_wrong_tot_tut.do"
do "./DoFiles/analysis/wide_narrow_forests.do"



*********************************** Figures ************************************


* Figure 1: Experiment description
do "./DoFiles/analysis/consort.do"

* Figure 2: Graphical Intuition for the Forcing-Choice Design

* Figure 3: Heterogeneous Treatment Effects
do "./DoFiles/analysis/cate_dist.do"

* Figure 4: "Mistakes" in the choice arm.
*do "./DoFiles/analysis/choose_wrong_quant_wrong_tot_tut.do"

