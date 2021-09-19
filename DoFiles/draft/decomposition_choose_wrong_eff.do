/*
Who makes mistakes?
		
Author : Isaac Meza
*/

********************************************************************************

** RUN R CODE : eff_te_grf.R

********************************************************************************


*Load data with eff_te predictions (created in eff_te_grf.R)
import delimited "$directorio/_aux/des_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_des tau_des)
tempfile temp_des
save `temp_des'

import delimited "$directorio/_aux/def_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_def tau_def)
tempfile temp_def
save `temp_def'

import delimited "$directorio/_aux/sumporcp_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_sum tau_sum)
tempfile temp_sum
save `temp_sum'

import delimited "$directorio/_aux/eff_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_eff tau_eff)

merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
merge 1:1 prenda using `temp_des', nogen keep(3)
merge 1:1 prenda using `temp_def', nogen keep(3)
merge 1:1 prenda using `temp_sum', nogen keep(3)


*drop observations with high variance
su var_eff, d
drop if var_eff>`r(p99)'

*Linear decomposition
reg tau_eff tau_sum tau_def, r nocons	
predict tau_pre
test tau_def==1/0.7
reg var_eff var_sum var_def, r nocons	
predict var_pre



********************************************************************************

forvalues i = 1/4 {
	gen choose_wrong_fee`i' = .
	gen tau_sim`i' = .
	gen cwf`i' = 0
	gen cwf_normal_l`i' = .
	gen cwf_normal_h`i' = .
	
	forvalues j = 0/16 {
		gen cwf_normal_l`i'_`j' = .
		gen cwf_normal_h`i'_`j' = .
		}
}


gen threshold = _n-1 if _n<=16
	
local rep_num = 200
forvalues rep = 1/`rep_num' {
di "`rep'"
*Draw random effect from normal distribution with standard error according to Athey
replace tau_sim1 = rnormal(-tau_eff, sqrt(var_eff))*100	
replace tau_sim2 = rnormal(-tau_pre, sqrt(var_pre))*100	
replace tau_sim3 = rnormal(-tau_def, sqrt(var_def))*100	
replace tau_sim4 = rnormal(-tau_sum, sqrt(var_sum))*100	

*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
local k = 1
foreach var of varlist tau_sim1 tau_sim2 tau_sim3 tau_sim4 {
	forvalues i = 0/16 {
		qui {
		*Classify the percentage of wrong decisions
		* (`var'>`i' & pro_6==1) : positive (in the sense of beneficial)
		* treatment effect with fee but choose no fee
		replace choose_wrong_fee`k' = ((`var'>`i' & pro_6==1) | (`var'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee`k'
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf`k' = cwf`k' + point_estimate[1,1]*100 in `=`i'+1'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_normal_l`k'_`i' =  confidence_int[1,1]*100 in `rep'
			replace cwf_normal_h`k'_`i' =  confidence_int[2,1]*100 in `rep'
		}
		}
	local k = `k' + 1	
	}
	}	

*Recover the means
foreach var of varlist  cwf1 cwf2 cwf3 cwf4 {
	replace `var' = `var'/`rep_num'
	}
	

*Distribution of the CI
forvalues k = 1/4 {
	forvalues i = 0/16 {
		su cwf_normal_l`k'_`i', d
		replace cwf_normal_l`k' = `r(p5)' in `=`i'+1'
		su cwf_normal_h`k'_`i', d
		replace cwf_normal_h`k' = `r(p95)' in `=`i'+1'
		}
	}

	
	twoway 	(rarea cwf_normal_l1 cwf_normal_h1 threshold, fcolor(navy) fintensity(40)) ///
			(line cwf1 threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(scatter cwf1 threshold,  msymbol(x) color(navy) ) ///
			(rarea cwf_normal_l2 cwf_normal_h2 threshold, fcolor(blue) fintensity(30)) ///
			(line cwf2 threshold, lpattern(solid) lwidth(medthick) lcolor(blue%60)) ///
			(scatter cwf2 threshold,  msymbol(x) color(blue%60) ) ///
			(rarea cwf_normal_l3 cwf_normal_h3 threshold, fcolor(red) fintensity(20)) ///
			(line cwf3 threshold, lpattern(solid) lwidth(medthick) lcolor(red%60)) ///
			(scatter cwf3 threshold,  msymbol(x) color(red%60) ) ///
			(rarea cwf_normal_l4 cwf_normal_h4 threshold, fcolor(green) fintensity(20)) ///
			(line cwf4 threshold, lpattern(solid) lwidth(medthick) lcolor(green%60)) ///
			(scatter cwf4 threshold,  msymbol(x) color(green%60) ) ///
			, legend(order(2 "Effective cost/loan"  5 "Predicted" ///
				8 "Default" 11 "Sum of Payments"))  scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage mistakes", axis(1)) 
	graph export "$directorio/Figuras/line_cw_eff_decomposition_te_cf.pdf", replace
			
