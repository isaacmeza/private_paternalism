/*
Binscatters HTE
*/

********************************************************************************

** RUN R CODE : grf.R

********************************************************************************


*Treatment arm
local arm pro_2


********************************************************************************
********************************************************************************

foreach var in def_c fc_admin_disc dias_primer_pago {

	*Load data with heterogeneous predictions & propensities (created in grf.R)
	import delimited "$directorio/_aux/grf_`arm'_`var'.csv", clear
	gen hte_`var' = tau_hat_oobpredictions		
	tempfile temp`var'
	save `temp`var''
	}

foreach var in def_c fc_admin_disc {
	*Merge effects in one dataset
	merge 1:1 prenda using  `temp`var'', keepusing(hte_*) nogen
	}



/*(1) será verdad que los que tienen mayor impacto en recovery también tienen 
 mayor impacto en financing cost? */ 

binscatter hte_fc_admin_disc hte_def_c, nq(50) scheme(s2mono) graphregion(color(white)) ///
	xtitle("Not recovery (effect)") ytitle("FC (effect)")
graph export "$directorio\Figuras\binscatter_fc_def_`arm'.pdf", replace


	
/*(2) será verdad que los que tienen mayor decremento en first day of payment
 también tienen mayor financing cost*/

binscatter hte_fc_admin_disc hte_dias_primer_pago, nq(50) scheme(s2mono) graphregion(color(white)) ///
	xtitle("Elapsed days of first installment (effect)") ytitle("FC (effect)")	
graph export "$directorio\Figuras\binscatter_fc_days_`arm'.pdf", replace



/*(3) será verdad que los que tienen mayor decremento en first day of payment
 también tienen mayor pr de recuperacion*/

binscatter hte_def_c hte_dias_primer_pago, nq(50) scheme(s2mono) graphregion(color(white)) ///
	xtitle("Elapsed days of first installment (effect)") ytitle("Not recovery (effect)")	
graph export "$directorio\Figuras\binscatter_def_days_`arm'.pdf", replace

