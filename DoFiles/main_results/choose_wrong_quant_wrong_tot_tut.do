
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	April. 22, 2022
* Last date of modification: October. 5, 2022
* Modifications: - Improvement of forests and change of definition in main outcomes
* Files used:     
		- tot_instr_forest.csv
		- tut_instr_forest.csv
		- Master.dta
* Files created:  

* Purpose: Who makes mistakes? Based on TuT & ToT forests predictions

*******************************************************************************/
*/


********************************************************************************

** RUN R CODE : tot_tut_instr_forest.R

********************************************************************************


*Load data with forest predictions (created in tot_tut_instr_forest.R)

import delimited "$directorio/_aux/tot_eff_instr_forest.csv", clear
tempfile temptoteff
rename inst_hat_oobpredictions inst_hat_1_eff
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_1_eff
save `temptoteff'
import delimited "$directorio/_aux/tut_eff_instr_forest.csv", clear
tempfile temptuteff
rename inst_hat_oobpredictions inst_hat_0_eff
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_0_eff
save `temptuteff'

import delimited "$directorio/_aux/tot_apr_instr_forest.csv", clear
tempfile temp
rename inst_hat_oobpredictions inst_hat_1
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_1
save `temp'

import delimited "$directorio/_aux/tut_apr_instr_forest.csv", clear
rename inst_hat_oobpredictions inst_hat_0
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_0
merge 1:1 prenda using `temp', nogen
merge 1:1 prenda using `temptoteff', nogen
merge 1:1 prenda using `temptuteff', nogen

merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)


********************************************************************************
gen tau_sim_1 = . 
gen tau_sim_0 = . 
gen quant_sim_1 = .
gen quant_sim_0 = .
gen choose_wrong_fee = .
gen choose_wrong_fee_choose = .
gen choose_wrong_fee_nonchoose = .


gen quant_wrong_fee_choose = .
gen quant_wrong_fee_nonchoose = .


gen cwf = 0
gen cwf_choose = 0
gen cwf_nonchoose = 0
gen cwf_normal_l = .
gen cwf_normal_h = .
gen cwf_choose_l = .
gen cwf_choose_h = .
gen cwf_nonchoose_l = .
gen cwf_nonchoose_h = .

forvalues i = 0(5)80 {
	gen cwf_normal_l`i' = .
	gen cwf_normal_h`i' = .
	gen cwf_choose_l`i' = .
	gen cwf_choose_h`i' = .	
	gen cwf_nonchoose_l`i' = .
	gen cwf_nonchoose_h`i' = .	

	
	gen qwf`i' = .
	gen qwf_choose`i' = .
	gen qwf_nonchoose`i' = .
	}

gen qwf = 0
gen qwf_choose = 0
gen qwf_nonchoose = 0

	
local rep_num = 100
forvalues rep = 1/`rep_num' {
	di "`rep'"
	*Draw random effect from normal distribution with standard error according to Athey
	replace tau_sim_1 = rnormal(inst_hat_1, sqrt(inst_oobvarianceestimates_1))	
	replace tau_sim_0 = rnormal(inst_hat_0, sqrt(inst_oobvarianceestimates_0))	
	
	replace quant_sim_1 = rnormal(inst_hat_1, sqrt(inst_oobvarianceestimates_1_eff))	
	replace quant_sim_0 = rnormal(inst_hat_0, sqrt(inst_oobvarianceestimates_0_eff))		
	
*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
	local k = 1
	forvalues i = 0(5)80 {
		qui {
		*Classify the percentage of wrong decisions
		* people who look like person i and chose the no-commitment contract would have been better off had they chosen commitment : (tau_sim_0>`i' & pro_6==1)
		* analogous for (tau_sim_1<`i' & pro_7==1)
		replace choose_wrong_fee = .
		replace choose_wrong_fee = ((tau_sim_0>`=`i'/100' & pro_6==1) | (tau_sim_1<-`=`i'/100' & pro_7==1)) if (!missing(tau_sim_1) | !missing(tau_sim_0)) & t_prod==4
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf = cwf + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_normal_l`i' =  confidence_int[1,1]*100 in `rep'
			replace cwf_normal_h`i' =  confidence_int[2,1]*100 in `rep'
			*Only consider "choosers"
		replace choose_wrong_fee_choose = .	
		replace choose_wrong_fee_choose = (tau_sim_1<-`=`i'/100' & pro_7==1) if !missing(tau_sim_1) & pro_7==1	
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee_choose
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf_choose = cwf_choose + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_choose_l`i' =  confidence_int[1,1]*100 in `rep'
			replace cwf_choose_h`i' =  confidence_int[2,1]*100 in `rep'		
			*Only consider "non-choosers"
		replace choose_wrong_fee_nonchoose = .	
		replace choose_wrong_fee_nonchoose = (tau_sim_0>`=`i'/100' & pro_6==1) if !missing(tau_sim_0) & pro_6==1	
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee_nonchoose
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf_nonchoose = cwf_nonchoose + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_nonchoose_l`i' =  confidence_int[1,1]*100 in `rep'
			replace cwf_nonchoose_h`i' =  confidence_int[2,1]*100 in `rep'
			
			*Only consider "choosers"
		*Quantification in $
		replace quant_wrong_fee_choose = .
		replace quant_wrong_fee_choose = abs(quant_sim_1)*100 if choose_wrong_fee_choose==1
		su quant_wrong_fee_choose
		cap replace qwf_choose`i' = `r(mean)' in `rep'
			*Only consider "non-choosers"
		*Quantification in $
		replace quant_wrong_fee_nonchoose = .
		replace quant_wrong_fee_nonchoose = abs(quant_sim_0)*100 if choose_wrong_fee_nonchoose==1
		su quant_wrong_fee_nonchoose
		cap replace qwf_nonchoose`i' = `r(mean)' in `rep'	
		
		local k = `k' + 1
		}
		}

	}	

*Recover the means
foreach var of varlist  cwf cwf_choose cwf_nonchoose {
	replace `var' = `var'/`rep_num'
	}
local k = 1
forvalues i = 0(5)80 {
	foreach vr in qwf qwf_choose qwf_nonchoose {
		su `vr'`i'
		if `r(N)'>0 {
			replace `vr' = `r(mean)' in `k'
		}
	}
	local k = `k' + 1
	}	

*Distribution of the CI
local k = 1
forvalues i = 0(5)80 {
	foreach vr in cwf_normal cwf_nonchoose cwf_choose {
		su `vr'_l`i', d
		replace `vr'_l = `r(p5)' in `k'
		replace `vr'_l = 0 if `vr'_l < 0 & !missing(`vr'_l )
		su `vr'_h`i', d
		replace `vr'_h = `r(p95)' in `k'
		replace `vr'_h = 100 if `vr'_h > 100 & !missing(`vr'_h )
	}
	local k = `k' + 1
	}

gen threshold = (_n-1)*5 if (_n-1)*5<=80
save "$directorio/_aux/choose_wrong_tot_tut.dta", replace

**************************************PLOTS*************************************

use "$directorio/_aux/choose_wrong_tot_tut.dta", clear
	
	twoway 	(rarea cwf_normal_l cwf_normal_h threshold, lcolor(navy%5) fcolor(navy) fintensity(50)) ///
			(line cwf threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(scatter cwf threshold, connect(l)  msymbol(x) color(navy) ) ///
			(rarea cwf_nonchoose_l cwf_nonchoose_h threshold, lcolor(dkgreen%5) fcolor(dkgreen%60) fintensity(40)) ///
			(line cwf_nonchoose threshold, lpattern(solid) lwidth(medthick) lcolor(dkgreen%80)) ///
			(scatter cwf_nonchoose threshold, connect(l) msymbol(x) color(dkgreen%80) ) ///	
			(rarea cwf_choose_l cwf_choose_h threshold, lcolor(maroon%5) fcolor(maroon%70) fintensity(40)) ///
			(line cwf_choose threshold, lpattern(solid) lwidth(medthick) lcolor(maroon%70)) ///
			(scatter cwf_choose threshold, connect(l) msymbol(x) color(maroon%70) ) ///				
			, legend(order(3 "Choice commitment"  ///
				6 "Non-choosers" 9 "Choosers") pos(6) rows(1))  ///
			graphregion(color(white)) xtitle("APR threshold") ///
			ytitle("% of relevant group making mistakes") ///
			ylabel(0(10)100) 
	graph export "$directorio/Figuras/line_cw_apr_tot_tut.pdf", replace
	
	
	twoway 	(scatter qwf_nonchoose threshold, connect(l) msymbol(x) color(dkgreen%90)) ///	
			(scatter qwf_choose threshold, connect(l)  msymbol(x) color(maroon%80)) ///				
			, legend(order(1 "Non-choosers" 2 "Choosers")  pos(6) rows(1)) ///
			graphregion(color(white)) xtitle("APR threshold") ///
			ytitle("Money (as % of loan)") 
	graph export "$directorio/Figuras/money_cw_apr_tot_tut.pdf", replace	

	
