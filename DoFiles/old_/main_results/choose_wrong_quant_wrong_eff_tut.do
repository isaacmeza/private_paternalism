
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification: May. 31, 2023
* Modifications: - Adjust by compliance rate
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
import delimited "$directorio/_aux/fc_tut_te_grf.csv", clear
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
keep if t_prod==1	

********************************************************************************
gen tau_sim = . 
gen better_forceall = 0

gen bfa = 0
gen bfa_normal_l = .
gen bfa_normal_h = .

local k = 1
forvalues i = -1000(100)3000 {
	gen bfa_normal_l`k' = .
	gen bfa_normal_h`k' = .
	
	local k = `k' + 1
	}
	
local rep_num = 100
forvalues rep = 1/`rep_num' {
	di "`rep'"
	*Draw random effect from normal distribution with standard error according to Athey
	replace tau_sim = rnormal(tau_hat_oobpredictions, sqrt(tau_hat_oobvarianceestimates))	
	
*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
	local k = 1
	forvalues i = -1000(100)3000 {
		qui {

		*If we were to force everyone to the FEE contract, how many would be
		* benefited from this policy?
		replace bfa = .
		replace bfa = (tau_sim>`=`i'') if !missing(tau_sim) & t_prod==1
		bootstrap r(mean),  reps(25) level(99): su bfa
		estat bootstrap, all
		mat point_estimate = e(b)
		replace better_forceall = better_forceall + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace bfa_normal_l`k' =  confidence_int[1,1]*100 in `rep'
			replace bfa_normal_h`k' =  confidence_int[2,1]*100 in `rep'
		
		local k = `k' + 1
		}
		}

	}	

*Recover the means
foreach var of varlist better_forceall {
	replace `var' = `var'/`rep_num'
	}


*Distribution of the CI
local k = 1
forvalues i = -1000(100)3000 {
	foreach vr in bfa_normal {
		su `vr'_l`k', d
		replace `vr'_l = `r(p5)' in `k'
		replace `vr'_l = 0 if `vr'_l < 0 & !missing(`vr'_l )
		su `vr'_h`k', d
		replace `vr'_h = `r(p95)' in `k'
		replace `vr'_h = 100 if `vr'_h > 100 & !missing(`vr'_h )
	}
	local k = `k' + 1
	}

foreach var of varlist bfa_normal_l bfa_normal_h better_forceall {
	*Adjust by compliance rate
	replace `var' = `var'/(1-.144648)
}	

gen threshold = -1000 + (_n-1)*100 if (_n-1)*100<=4000
save "$directorio/_aux/choose_wrong_itt.dta", replace

**************************************PLOTS*************************************

use "$directorio/_aux/choose_wrong_itt.dta", clear 
	
twoway 	(rarea bfa_normal_l bfa_normal_h threshold, fcolor(navy) fintensity(40)) ///
	(line better_forceall threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
	(scatter better_forceall threshold,  msymbol(x) color(navy) ) ///
	, legend(off) scheme(s2mono) ///
	graphregion(color(white)) xtitle("FC threshold") ///
	ytitle("% benefitted", axis(1)) ///
	ylabel(0(10)100, axis(1)) xline(0, lcolor(black) lwidth(medthick) lpattern(dash))
graph export "$directorio/Figuras/line_better_forceall_itt_te_cf.pdf", replace
