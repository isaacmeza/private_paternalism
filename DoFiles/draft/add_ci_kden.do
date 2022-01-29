/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification:  January. 26, 2022
* Modifications: Add confidence intervals for HTE distribution
* Files used:     
		- 
* Files created:  

* Purpose: 

*******************************************************************************/
*/

** RUN R CODE : grf.R

*TREATMENT ARM
local arm pro_2

set more off
graph drop _all



foreach depvar in   eff_cost_loan  {

	*Load data with heterogeneous predictions & propensities (extended)
	import delimited "$directorio/_aux/grf_extended_`arm'_`depvar'.csv", clear
}
	
*Confidence intervals for 
gen lo_tau_hat = tau_hat_oobpredictions - 1.96*sqrt(tau_hat_oobvarianceestimates)
gen hi_tau_hat = tau_hat_oobpredictions + 1.96*sqrt(tau_hat_oobvarianceestimates)


su tau_hat_oobpredictions
local minn = `r(min)'
*Number of bins
local k = round(min(sqrt(`r(N)'), 10*ln(`r(N)')/ln(10)))

*Width
local w = (`r(max)'-`r(min)')/`k'

gen bin = .
gen lo_ci = .
gen hi_ci = .
gen height = .

forvalues i=1/`k' {
	*Identify observations in each bins
	replace bin = `i' if inrange(tau_hat_oobpredictions, `minn'+`w'*(`i'-1), `minn'+`w'*`i')
	di `i'
	count if inrange(tau_hat_oobpredictions, `minn'+`w'*(`i'-1), `minn'+`w'*`i')
	if `r(N)'>=50 {
		*Mean of lower CI for observations in each bin
		su lo_tau_hat if bin==`i'
		replace lo_ci = `r(mean)' in `i'
		*Mean of higher CI for observations in each bin	
		su hi_tau_hat if  bin==`i'
		replace hi_ci = `r(mean)' in `i'
		di ""
		*Identify number of observations in each bin (this will be the height for the CI in hist)
		replace height = `r(N)' in `i'
	}

}	


count if !missing(tau_hat_oobpredictions) & !missing(bin)
replace height = (height/`r(N)')*100

twoway (hist tau_hat_oobpredictions, percent) ///
(rcap lo_ci hi_ci height, horizontal) ///
(kdensity tau_hat_oobpredictions) ///
(kdensity lo_tau_hat) ///
(kdensity hi_tau_hat)

	
	*Overlap assumption	
	destring propensity_score, force replace
	twoway (kdensity propensity_score if !missing(`arm'), lpattern(solid) lwidth(medthick)) ///
			, ///
		scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Propensity score") ///
		legend(off)			
	graph export "$directorio\Figuras\ps_overlap_`depvar'_`arm'.pdf", replace
		
	
	
	*Heterogeneous effect distributions
	if strpos("`depvar'","fc")!=0 {
		cap drop esample
		su tau_hat_oobpredictions  , d
		gen esample = inrange(tau_hat_oobpredictions, `r(p1)', `r(p99)') 
		qui kdensity tau_hat_oobpredictions if esample==1,  nograph 
		local width =  `r(bwidth)'
		}

	else {
		cap drop esample
		gen esample = 1 
		qui kdensity tau_hat_oobpredictions ,  nograph 
		local width =  `r(bwidth)'
		}
		
	do "$directorio\DoFiles\main_results\yaxis_kdensity.do" ///
		 "tau_hat_oobpredictions" "`width'" "esample" "uno"
		 
		 	twoway (hist tau_hat_oobpredictions if esample==1, xline(0, lpattern(dot) lwidth(thick)) yaxis(1) ytitle("Percent", axis(1)) w(`width') percent lcolor(white) fcolor(none) ) ///		
		(kdensity tau_hat_oobpredictions if esample==1, yaxis(2) ylab(${uno}, notick nolab axis(2)) ///
						ytitle(" ", axis(2)) xtitle("Effect")  ///
						lcolor(black) lwidth(thick) lpattern(solid) ///
						legend(off) scheme(s2mono) graphregion(color(white))) 	
	graph export "$directorio\Figuras\he_dist_`depvar'_`arm'.pdf", replace
}