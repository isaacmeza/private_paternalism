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

* Purpose: Who makes mistakes?

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


*Histogram of CATE
foreach var of varlist eff_te_cf {
	twoway (hist `var' if pro_6==1 | pro_7==1, percent  lcolor(blue) color(blue)) ///
		(hist `var' if pro_8==1 | pro_9==1, percent  lcolor(black) color(none)), ///
		scheme(s2mono) graphregion(color(white)) ///
		legend(order(1 "Fee" 2 "Promise")) xtitle("Estimated benefit")
	graph export "$directorio/Figuras/hist_benefit_fee_`var'.pdf", replace
	
	twoway (hist `var' if pro_7==1 | pro_9==1, percent  lcolor(blue) color(blue)) ///
		(hist `var' if pro_6==1 | pro_8==1, percent  lcolor(black) color(none)), ///
		scheme(s2mono) graphregion(color(white)) ///
		legend(order(1 "Choose commitment" 2 "No commitment")) xtitle("Estimated benefit")
	graph export "$directorio/Figuras/hist_benefit_choice_`var'.pdf", replace
	
	}

********************************************************************************
gen tau_sim = . 
gen choose_wrong_fee = .
gen choose_wrong_fee_soph = .

gen quant_wrong_fee = .
gen quant_wrong_fee_soph = .

gen better_forceall = 0

gen cwf = 0
gen cwf_soph = 0
gen cwf_normal_l = .
gen cwf_normal_h = .
gen bfa_normal_l = .
gen bfa_normal_h = .

forvalues i = 0/16 {
	gen cwf_normal_l`i' = .
	gen cwf_normal_h`i' = .
	gen bfa_normal_l`i' = .
	gen bfa_normal_h`i' = .
	}

gen qwf = 0
gen qwf_soph = 0
gen qbfa = 0 

gen threshold = _n-1 if _n<=16
	
local rep_num = 100
forvalues rep = 1/`rep_num' {
di "`rep'"
*Draw random effect from normal distribution with standard error according to Athey
replace tau_sim = rnormal(tau_hat_oobpredictions, sqrt(tau_hat_oobvarianceestimates))*100	

*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
foreach var of varlist tau_sim {
	forvalues i = 0/16 {
		qui {
		*Classify the percentage of wrong decisions
		* (`var'>`i' & pro_6==1) : positive (in the sense of beneficial)
		* treatment effect with fee but choose no fee
		replace choose_wrong_fee = .
		replace choose_wrong_fee = ((`var'>`i' & pro_6==1) | (`var'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf = cwf + point_estimate[1,1]*100 in `=`i'+1'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_normal_l`i' =  confidence_int[1,1]*100 in `rep'
			replace cwf_normal_h`i' =  confidence_int[2,1]*100 in `rep'
			*Only consider "sophisticated"
		replace choose_wrong_fee_soph = .	
		replace choose_wrong_fee_soph = (`var'<-`i' & pro_7==1) if !missing(`var') & t_prod==4	
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee_soph
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf_soph = cwf_soph + point_estimate[1,1]*100 in `=`i'+1'
		
		*Quantification in $
		replace quant_wrong_fee = .
		replace quant_wrong_fee = abs(`var') if choose_wrong_fee==1
		su quant_wrong_fee
		cap replace qwf = qwf + `r(mean)' in `=`i'+1'
		
			*Only consider "sophisticated"
		*Quantification in $
		replace quant_wrong_fee_soph = .
		replace quant_wrong_fee_soph = abs(`var') if choose_wrong_fee_soph==1
		su quant_wrong_fee_soph
		cap replace qwf_soph = qwf_soph + `r(mean)' in `=`i'+1'
		
		
		*If we were to force everyone to the FEE contract, how many would be
		* benefited from this policy?
		replace choose_wrong_fee = .
		replace choose_wrong_fee = (`var'>`i') if !missing(`var') & t_prod==4
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee
		estat bootstrap, all
		mat point_estimate = e(b)
		replace better_forceall = better_forceall + point_estimate[1,1]*100 in `=`i'+1'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace bfa_normal_l`i' =  confidence_int[1,1]*100 in `rep'
			replace bfa_normal_h`i' =  confidence_int[2,1]*100 in `rep'
		
		
		*Quantification in $
		replace quant_wrong_fee = .
		replace quant_wrong_fee = abs(`var') if choose_wrong_fee==1
		su quant_wrong_fee
		cap replace qbfa = qbfa + `r(mean)' in `=`i'+1'
		
		}
		}
	}
	}	

*Recover the means
foreach var of varlist better_forceall cwf cwf_soph qwf qwf_soph qbfa {
	replace `var' = `var'/`rep_num'
	}
	

*Distribution of the CI
forvalues i = 0/16 {
	su cwf_normal_l`i', d
	replace cwf_normal_l = `r(p5)' in `=`i'+1'
	su cwf_normal_h`i', d
	replace cwf_normal_h = `r(p95)' in `=`i'+1'
	
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
	graph export "$directorio/Figuras/line_better_forceall_eff_te_cf.pdf", replace

	
	
	twoway 	(rarea cwf_normal_l cwf_normal_h threshold, fcolor(navy) fintensity(40)) ///
			(line cwf threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(line cwf_normal_h threshold, lpattern(dot) lwidth(medthick) lcolor(blue)) ///
			(scatter cwf threshold,  msymbol(x) color(navy) ) ///
			(line cwf_soph threshold, lpattern(solid) lwidth(medthick) lcolor(blue%25)) ///
			(scatter qwf threshold,  msymbol(x) color(red) yaxis(2)) ///
			(scatter qwf_soph threshold,  msymbol(x) color(red%25) yaxis(2)) ///			
			, legend(order(2 "Fee arm"  ///
				6 "Money (Fee)" 5 "Sophisticated"  ///
				7 "Money (Sophisticated)"))  scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage mistakes", axis(1)) ///
			ytitle("Money (as % of loan)",axis(2)) ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_cw_eff_te_cf.pdf", replace
	

	

