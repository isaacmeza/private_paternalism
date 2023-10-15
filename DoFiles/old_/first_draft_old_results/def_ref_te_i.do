set more off
*ADMIN DATA
use "$directorio/DB/Master.dta", clear

*Aux Dummies 
tab dow, gen(dummy_dow)
tab suc, gen(dummy_suc)
tab num_arms, gen(num_arms_d)
tab visit_number, gen(visit_number_d)
tab num_arms_75, gen(num_arms_75_d)
tab visit_number_75, gen(visit_number_75_d)
drop num_arms_d1 num_arms_d2 num_arms_75_d1 num_arms_75_d2 visit_number_d1 visit_number_75_d1

*Treatment arm
local arm pro_2

********************************************************************************
************************************Paid loan***********************************
********************************************************************************

matrix results = J(141, 4, .) // empty matrix for results
//  4 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) pvalue

gen des_c_i = .	
forvalues days = 90/230 {
	qui replace des_c_i = des_c
	qui replace des_c_i = 0 if dias_ultimo_mov > `days'
	qui reg des_c_i `arm' ${C0}, r cluster(suc_x_dia) 
	local df = e(df_r)	
		
	matrix results[`days'-89,1] = `days'
	// Beta 
	matrix results[`days'-89,2] = _b[`arm']
	// Standard error
	matrix results[`days'-89,3] = _se[`arm']
	// P-value
	matrix results[`days'-89,4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
	
	}
	

matrix colnames results = "k" "beta" "se" "p"
matlist results
	
	
preserve
clear
svmat results, names(col) 

// Confidence intervals (95%)
local alpha = .05 // for 95% confidence intervals
gen rcap_lo = beta - invttail(`df',`=`alpha'/2')*se
gen rcap_hi = beta + invttail(`df',`=`alpha'/2')*se

twoway 	(rarea rcap_lo rcap_hi k, color(gs10)) ///
	(line beta k, lwidth(thick) lpattern(solid)), ///
	graphregion(color(white)) scheme(s2mono) legend(off) xtitle("Cycle days") ytitle("Effect")
graph export "$directorio\Figuras\des_c_te.pdf", replace
restore

********************************************************************************
************************************Naiveness***********************************
********************************************************************************


matrix results = J(141, 4, .) // empty matrix for results
//  4 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) pvalue

gen pos_pay_default_i = .	
forvalues days = 90/230 {
	qui replace pos_pay_default_i = pos_pay_default
	qui replace pos_pay_default_i = 0 if dias_ultimo_mov > `days'
	qui reg pos_pay_default_i `arm' ${C0}, r cluster(suc_x_dia) 
	local df = e(df_r)	
		
	matrix results[`days'-89,1] = `days'
	// Beta 
	matrix results[`days'-89,2] = _b[`arm']
	// Standard error
	matrix results[`days'-89,3] = _se[`arm']
	// P-value
	matrix results[`days'-89,4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
	
	}
	

matrix colnames results = "k" "beta" "se" "p"
matlist results
	
	
preserve
clear
svmat results, names(col) 

// Confidence intervals (95%)
local alpha = .05 // for 95% confidence intervals
gen rcap_lo = beta - invttail(`df',`=`alpha'/2')*se
gen rcap_hi = beta + invttail(`df',`=`alpha'/2')*se

twoway 	(rarea rcap_lo rcap_hi k, color(gs10)) ///
	(line beta k, lwidth(thick) lpattern(solid)), ///
	graphregion(color(white)) scheme(s2mono) legend(off) xtitle("Cyle days") ytitle("Effect")
graph export "$directorio\Figuras\pos_pay_default_te.pdf", replace
restore
