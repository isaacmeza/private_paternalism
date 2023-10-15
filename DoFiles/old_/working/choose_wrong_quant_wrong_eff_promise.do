/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification:   
* Modifications:		
* Files used:     
		- 
* Files created:  

* Purpose: Who makes mistakes? - Promise arm

*******************************************************************************/
*/

********************************************************************************

** RUN R CODE : eff_te_grf.R

********************************************************************************


*Load data with eff_te predictions (created in eff_te_grf.R)
import delimited "$directorio/_aux/eff_te_grf.csv", clear
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)


*Counterfactuals estimates
	
	*Causal forest on nochoice/fee-vs-control
gen eff_te_cf =  tau_hat_oobpredictions*100	
*CI - 95%
gen eff_te_cf_ub95 = eff_te_cf + invnorm(0.975)*sqrt(tau_hat_oobvarianceestimates)*100
gen eff_te_cf_lb95 = eff_te_cf - invnorm(0.975)*sqrt(tau_hat_oobvarianceestimates)*100
*CI - 90%
gen eff_te_cf_ub90 = eff_te_cf + invnorm(0.95)*sqrt(tau_hat_oobvarianceestimates)*100
gen eff_te_cf_lb90 = eff_te_cf - invnorm(0.95)*sqrt(tau_hat_oobvarianceestimates)*100

********************************************************************************
gen tau_sim = . 
gen choose_wrong_promise = .
gen choose_wrong_promise_soph = .

gen quant_wrong_promise = .
gen quant_wrong_promise_soph = .

gen better_forceall = 0

gen cwp = 0
gen cwp_soph = 0
gen cwp_normal_l = .
gen cwp_normal_h = .
gen bfa_normal_l = .
gen bfa_normal_h = .

forvalues i = 0/16 {
	gen cwp_normal_l`i' = .
	gen cwp_normal_h`i' = .
	gen bfa_normal_l`i' = .
	gen bfa_normal_h`i' = .
	}

gen qwp = 0
gen qwp_soph = 0
gen qbfa = 0 

gen threshold = _n-1 if _n<=16
	
local rep_num = 50
forvalues rep = 1/`rep_num' {
di "`rep'"
*Draw random effect from normal distribution with standard error according to Athey
replace tau_sim = rnormal(tau_hat_oobpredictions, sqrt(tau_hat_oobvarianceestimates))*100	

*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
foreach var of varlist tau_sim {
	forvalues i = 0/16 {
		qui {
		*Classify the percentage of wrong decisions
		* (`var'>`i' & pro_8==1) : positive (in the sense of beneficial)
		* treatment effect with fee but choose no fee
		replace choose_wrong_promise = ((`var'>`i' & pro_8==1) | (`var'<-`i' & pro_9==1)) if !missing(`var') & t_prod==5
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_promise
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwp = cwp + point_estimate[1,1]*100 in `=`i'+1'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwp_normal_l`i' =  confidence_int[1,1]*100 in `rep'
			replace cwp_normal_h`i' =  confidence_int[2,1]*100 in `rep'
			*Only consider "sophisticated"
		replace choose_wrong_promise_soph = (`var'<-`i' & pro_9==1) if !missing(`var') & t_prod==5	
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_promise_soph
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwp_soph = cwp_soph + point_estimate[1,1]*100 in `=`i'+1'
		
		*Quantification in $
		replace quant_wrong_promise = .
		replace quant_wrong_promise = abs(`var') if choose_wrong_promise==1
		su quant_wrong_promise
		cap replace qwp = qwp + `r(mean)' in `=`i'+1'
		
			*Only consider "sophisticated"
		*Quantification in $
		replace quant_wrong_promise_soph = .
		replace quant_wrong_promise_soph = abs(`var') if choose_wrong_promise_soph==1
		su quant_wrong_promise_soph
		cap replace qwp_soph = qwp_soph + `r(mean)' in `=`i'+1'
		
		
		*If we were to force everyone to the FEE contract, how many would be
		* benefited from this policy?
		replace choose_wrong_promise = (`var'>`i') if !missing(`var') & t_prod==5
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_promise
		estat bootstrap, all
		mat point_estimate = e(b)
		replace better_forceall = better_forceall + point_estimate[1,1]*100 in `=`i'+1'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace bfa_normal_l`i' =  confidence_int[1,1]*100 in `rep'
			replace bfa_normal_h`i' =  confidence_int[2,1]*100 in `rep'
		
		
		*Quantification in $
		replace quant_wrong_promise = .
		replace quant_wrong_promise = abs(`var') if choose_wrong_promise==1
		su quant_wrong_promise
		cap replace qbfa = qbfa + `r(mean)' in `=`i'+1'
		
		}
		}
	}
	}	

*Recover the means
foreach var of varlist better_forceall cwp cwp_soph qwp qwp_soph qbfa {
	replace `var' = `var'/`rep_num'
	}
	

*Distribution of the CI
forvalues i = 0/16 {
	su cwp_normal_l`i', d
	replace cwp_normal_l = `r(p5)' in `=`i'+1'
	su cwp_normal_h`i', d
	replace cwp_normal_h = `r(p95)' in `=`i'+1'
	
	su bfa_normal_l`i', d
	replace bfa_normal_l = `r(p5)' in `=`i'+1'
	su bfa_normal_h`i', d
	replace bfa_normal_h = `r(p95)' in `=`i'+1'
	}

	
	twoway 	(rarea bfa_normal_l bfa_normal_h threshold, fcolor(navy) fintensity(40)) ///
			(line better_forceall threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(scatter better_forceall threshold,  msymbol(x) color(navy) ) ///
			, legend(off) scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage", axis(1)) ///
			ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_better_forceall_eff_te_cf_promise.pdf", replace

	
	
	twoway 	(rarea cwp_normal_l cwp_normal_h threshold, fcolor(navy) fintensity(40)) ///
			(line cwp threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(line cwp_normal_h threshold, lpattern(dot) lwidth(medthick) lcolor(blue)) ///
			(scatter cwp threshold,  msymbol(x) color(navy) ) ///
			(line cwp_soph threshold, lpattern(solid) lwidth(medthick) lcolor(blue%25)) ///
			(scatter qwp threshold,  msymbol(x) color(red) yaxis(2)) ///
			(scatter qwp_soph threshold,  msymbol(x) color(red%25) yaxis(2)) ///			
			, legend(order(2 "Promise arm"  ///
				6 "Money (Promise)" 5 "Sophisticated"  ///
				7 "Money (Sophisticated)"))  scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage mistakes", axis(1)) ///
			ytitle("Money (as % of loan)",axis(2)) ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_cw_eff_te_cf_promise.pdf", replace
	

	

