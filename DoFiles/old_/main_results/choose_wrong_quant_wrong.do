/*
Who makes mistakes?
*/

********************************************************************************

** RUN R CODE : fc_te_grf.R

********************************************************************************


*Load data with fc_te predictions (created in fc_te_grf.R)
import delimited "$directorio/_aux/fc_te_grf.csv", clear
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)

*drop observations with high variance
su tau_hat_oobvarianceestimates, d
drop if tau_hat_oobvarianceestimates>`r(p99)'

*Counterfactuals estimates
	
	*Causal forest on nochoice/fee-vs-control
	*we put the negative of it to 'normalize' it to a positive scale
gen fc_te_cf =  -tau_hat_oobpredictions/prestamo*100	
*CI - 95%
gen fc_te_cf_ub95 = fc_te_cf + invnorm(0.975)*sqrt(tau_hat_oobvarianceestimates)*100/prestamo
gen fc_te_cf_lb95 = fc_te_cf - invnorm(0.975)*sqrt(tau_hat_oobvarianceestimates)*100/prestamo
*CI - 90%
gen fc_te_cf_ub90 = fc_te_cf + invnorm(0.95)*sqrt(tau_hat_oobvarianceestimates)*100/prestamo
gen fc_te_cf_lb90 = fc_te_cf - invnorm(0.95)*sqrt(tau_hat_oobvarianceestimates)*100/prestamo


*Histogram of FC treatment effect on the treated
foreach var of varlist fc_te_cf {
	twoway (hist `var' if pro_6==1 | pro_7==1, percent w(10) lcolor(blue) color(blue)) ///
		(hist `var' if pro_8==1 | pro_9==1, percent w(10) lcolor(black) color(none)), ///
		scheme(s2mono) graphregion(color(white)) ///
		legend(order(1 "Fee" 2 "Promise")) xtitle("Estimated regret")
	graph export "$directorio/Figuras/hist_regret_`var'.pdf", replace
	}

********************************************************************************
gen tau_sim = . 
gen choose_wrong_fee = .
gen choose_wrong_promise = .
gen quant_wrong_fee = .
gen quant_wrong_promise = .

gen better_forceall = 0

gen cwf = 0
gen cwf_ub95 = .
gen cwf_lb95 = .
gen cwf_ub90 = .
gen cwf_lb90 = .

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

gen cwp = 0
gen qwf = 0
gen qwp = 0
gen qbfa = 0 

gen threshold = _n-1 if _n<=16

forvalues i = 0/16 {
	di "`i'"
	qui {
	*A la Manski Bounds
	foreach ci in 95 90  {
		replace choose_wrong_fee = ((fc_te_cf_lb`ci'>`i' & pro_6==1) | (fc_te_cf_ub`ci'<-`i' & pro_7==1)) if !missing(fc_te_cf) & t_prod==4
		su choose_wrong_fee
		replace cwf_lb`ci' = `r(mean)'*100 in `=`i'+1'
		
		replace choose_wrong_fee = ((fc_te_cf_ub`ci'>`i' & pro_6==1) | (fc_te_cf_lb`ci'<-`i' & pro_7==1)) if !missing(fc_te_cf) & t_prod==4
		su choose_wrong_fee
		replace cwf_ub`ci' = `r(mean)'*100 in `=`i'+1'	
		}
		}	
	}

local rep_num = 500
forvalues rep = 1/`rep_num' {
di "`rep'"
*Draw random effect from normal distribution with standard error according to Athey
replace tau_sim = rnormal(-tau_hat_oobpredictions, sqrt(tau_hat_oobvarianceestimates))/prestamo*100	

*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
foreach var of varlist tau_sim {
	forvalues i = 0/16 {
		qui {
		*Classify the percentage of wrong decisions
		* (`var'>`i' & pro_6==1) : positive (in the sense of beneficial)
		* treatment effect with fee but choose no fee
		replace choose_wrong_fee = ((`var'>`i' & pro_6==1) | (`var'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf = cwf + point_estimate[1,1]*100 in `=`i'+1'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_normal_l`i' =  confidence_int[1,1]*100 in `rep'
			replace cwf_normal_h`i' =  confidence_int[2,1]*100 in `rep'
			
			
		*Quantification in $
		replace quant_wrong_fee = .
		replace quant_wrong_fee = abs(`var')*prestamo/100 if choose_wrong_fee==1
		su quant_wrong_fee
		cap replace qwf = qwf + `r(mean)' in `=`i'+1'
		
		*If we were to force everyone to the FEE contract, how many would be
		* benefited from this policy?
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
		replace quant_wrong_fee = abs(`var')*prestamo/100 if choose_wrong_fee==1
		su quant_wrong_fee
		cap replace qbfa = qbfa + `r(mean)' in `=`i'+1'
		
			*promise
		replace choose_wrong_promise = ((`var'>`i' & pro_8==1) | (`var'<-`i' & pro_9==1)) if !missing(`var') & t_prod==5
		su choose_wrong_promise
		replace cwp = cwp + `r(mean)'*100 in `=`i'+1'
		
		*quantification	
		replace quant_wrong_promise = .
		replace quant_wrong_promise = abs(`var')*prestamo/100 if choose_wrong_promise==1
		su quant_wrong_promise
		cap replace qwp = qwp + `r(mean)' in `=`i'+1'
		
		}
		}
	}
	}	

*Recover the means
foreach var of varlist better_forceall cwf cwp qwf qwp qbfa {
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
	
	twoway 	(rarea cwf_normal_l cwf_normal_h threshold, fcolor(navy) fintensity(40)) ///
			(line cwf threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(line cwf_normal_h threshold, lpattern(dot) lwidth(medthick) lcolor(blue)) ///
			(scatter cwf threshold,  msymbol(x) color(navy) ) ///
			(scatter qwf threshold,  msymbol(x) color(red) yaxis(2)) ///
			, legend(order(2 "Fee arm"  ///
				5 "Money (fee)" ))  scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage mistakes", axis(1)) ///
			ytitle("Money (in pesos)",axis(2)) ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_cw_fc_te_cf.pdf", replace
	
	twoway 	(rarea bfa_normal_l bfa_normal_h threshold, fcolor(navy) fintensity(40)) ///
			(line better_forceall threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(scatter better_forceall threshold,  msymbol(x) color(navy) ) ///
			, legend(off) scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage", axis(1)) ///
			ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_better_forceall_fc_te_cf.pdf", replace

	
	

