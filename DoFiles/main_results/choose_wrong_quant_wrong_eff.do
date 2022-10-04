
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification: October. 5, 2022
* Modifications: - Change outcome to effective APR. Add choosers vs non-choosers analysis & split two axis in two figures.		
	- Fix quantity in money of mistakes for Choosers
* Files used:     
		- apr_te_grf.csv
		- Master.dta
* Files created:  

* Purpose: Who makes mistakes?

*******************************************************************************/
*/


********************************************************************************

** RUN R CODE : te_grf.R

********************************************************************************


*Load data with *_te predictions (created in te_grf.R)

import delimited "$directorio/_aux/eff_te_grf.csv", clear
tempfile temp
rename tau_hat_oobvarianceestimates tau_hat_oobvarianceestimates_eff
rename tau_hat_oobpredictions tau_hat_oobpredictions_eff
save `temp'

import delimited "$directorio/_aux/apr_te_grf.csv", clear
merge 1:1 prenda using `temp', nogen
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)


*Counterfactuals estimates
	
	*Causal forest on nochoice/fee-vs-control
gen apr_te_cf =  tau_hat_oobpredictions
*CI - 95%
gen apr_te_cf_ub95 = apr_te_cf + invnorm(0.975)*sqrt(tau_hat_oobvarianceestimates)
gen apr_te_cf_lb95 = apr_te_cf - invnorm(0.975)*sqrt(tau_hat_oobvarianceestimates)
*CI - 90%
gen apr_te_cf_ub90 = apr_te_cf + invnorm(0.95)*sqrt(tau_hat_oobvarianceestimates)
gen apr_te_cf_lb90 = apr_te_cf - invnorm(0.95)*sqrt(tau_hat_oobvarianceestimates)


*Histogram of CATE
foreach var of varlist apr_te_cf {
	twoway (hist `var' if pro_6==1 | pro_7==1, percent  lcolor(blue) color(blue)) ///
		(hist `var' if pro_8==1 | pro_9==1, percent  lcolor(black) color(none)), ///
		 graphregion(color(white)) ///
		legend(order(1 "Fee" 2 "Promise")) xtitle("Estimated benefit")
	graph export "$directorio/Figuras/hist_benefit_fee_`var'.pdf", replace
	
	twoway (hist `var' if pro_7==1 | pro_9==1, percent  lcolor(blue) color(blue)) ///
		(hist `var' if pro_6==1 | pro_8==1, percent  lcolor(black) color(none)), ///
		graphregion(color(white)) ///
		legend(order(1 "Choose commitment" 2 "No commitment")) xtitle("Estimated benefit")
	graph export "$directorio/Figuras/hist_benefit_choice_`var'.pdf", replace
	
	}

********************************************************************************
gen tau_sim = . 
gen quant_sim = .
gen choose_wrong_fee = .
gen choose_wrong_fee_choose = .
gen choose_wrong_fee_nonchoose = .

gen quant_wrong_fee = .
gen quant_wrong_fee_choose = .
gen quant_wrong_fee_nonchoose = .

gen better_forceall = 0

gen cwf = 0
gen cwf_choose = 0
gen cwf_nonchoose = 0
gen cwf_normal_l = .
gen cwf_normal_h = .
gen cwf_choose_l = .
gen cwf_choose_h = .
gen cwf_nonchoose_l = .
gen cwf_nonchoose_h = .
gen bfa_normal_l = .
gen bfa_normal_h = .

forvalues i = 0(5)80 {
	gen cwf_normal_l`i' = .
	gen cwf_normal_h`i' = .
	gen cwf_choose_l`i' = .
	gen cwf_choose_h`i' = .	
	gen cwf_nonchoose_l`i' = .
	gen cwf_nonchoose_h`i' = .	
	gen bfa_normal_l`i' = .
	gen bfa_normal_h`i' = .
	
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
	replace tau_sim = rnormal(tau_hat_oobpredictions, sqrt(tau_hat_oobvarianceestimates))	
	replace quant_sim = rnormal(tau_hat_oobpredictions_eff, sqrt(tau_hat_oobvarianceestimates_eff))	
	
*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
	local k = 1
	forvalues i = 0(5)80 {
		qui {
		*Classify the percentage of wrong decisions
		* (tau_sim>`i' & pro_6==1) : positive (in the sense of beneficial)
		* treatment effect with fee but choose no fee
		replace choose_wrong_fee = .
		replace choose_wrong_fee = ((tau_sim>`=`i'/100' & pro_6==1) | (tau_sim<-`=`i'/100' & pro_7==1)) if !missing(tau_sim) & t_prod==4
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
		replace choose_wrong_fee_choose = (tau_sim<-`=`i'/100' & pro_7==1) if !missing(tau_sim) & pro_7==1	
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
		replace choose_wrong_fee_nonchoose = (tau_sim>`=`i'/100' & pro_6==1) if !missing(tau_sim) & pro_6==1	
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee_nonchoose
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf_nonchoose = cwf_nonchoose + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_nonchoose_l`i' =  confidence_int[1,1]*100 in `rep'
			replace cwf_nonchoose_h`i' =  confidence_int[2,1]*100 in `rep'
			
			
		*Quantification in $
		replace quant_wrong_fee = .
		replace quant_wrong_fee = abs(quant_sim)*100 if choose_wrong_fee==1
		su quant_wrong_fee
		cap replace qwf`i' = `r(mean)' in `rep'		
			*Only consider "choosers"
		*Quantification in $
		replace quant_wrong_fee_choose = .
		replace quant_wrong_fee_choose = abs(quant_sim)*100 if choose_wrong_fee_choose==1
		su quant_wrong_fee_choose
		cap replace qwf_choose`i' = `r(mean)' in `rep'
			*Only consider "non-choosers"
		*Quantification in $
		replace quant_wrong_fee_nonchoose = .
		replace quant_wrong_fee_nonchoose = abs(quant_sim)*100 if choose_wrong_fee_nonchoose==1
		su quant_wrong_fee_nonchoose
		cap replace qwf_nonchoose`i' = `r(mean)' in `rep'	
		
********************************************************************************
		
		*If we were to force everyone to the FEE contract, how many would be
		* benefited from this policy?
		replace choose_wrong_fee = .
		replace choose_wrong_fee = (tau_sim>`=`i'/100') if !missing(tau_sim) & t_prod==4
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee
		estat bootstrap, all
		mat point_estimate = e(b)
		replace better_forceall = better_forceall + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace bfa_normal_l`i' =  confidence_int[1,1]*100 in `rep'
			replace bfa_normal_h`i' =  confidence_int[2,1]*100 in `rep'
		
		local k = `k' + 1
		}
		}

	}	

*Recover the means
foreach var of varlist better_forceall cwf cwf_choose cwf_nonchoose {
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
	foreach vr in cwf_normal cwf_nonchoose cwf_choose bfa_normal {
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
save "$directorio/_aux/choose_wrong.dta", replace

**************************************PLOTS*************************************

use "$directorio/_aux/choose_wrong.dta", clear 

	
	twoway 	(rarea bfa_normal_l bfa_normal_h threshold, fcolor(navy) fintensity(40)) ///
			(line better_forceall threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(scatter better_forceall threshold,  msymbol(x) color(navy) ) ///
			, legend(off) scheme(s2mono) ///
			graphregion(color(white)) xtitle("APR threshold") ///
			ytitle("% benefitted", axis(1)) ///
			ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_better_forceall_apr_te_cf.pdf", replace

	
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
	graph export "$directorio/Figuras/line_cw_apr_te_cf.pdf", replace
	
	
	twoway 	(scatter qwf threshold,  connect(l) jitter(4) msymbol(x) color(navy)) ///
			(scatter qwf_nonchoose threshold, connect(l) msymbol(x) color(dkgreen%90)) ///	
			(scatter qwf_choose threshold, connect(l)  msymbol(x) color(maroon%80)) ///				
			, legend(order(1 "Choice commitment"  ///
				2 "Non-choosers" 3 "Choosers") pos(6) rows(1)) ///
			graphregion(color(white)) xtitle("APR threshold") ///
			ytitle("Money (as % of loan)") 
	graph export "$directorio/Figuras/money_cw_apr_te_cf.pdf", replace	

	
