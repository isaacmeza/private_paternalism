/*
Creation of dataset for the effective cost/loan ratio HTE
*/

use "$directorio/DB/Master.dta", clear


gen fee_arms = inlist(prod, 2 ,5) & !missing(prod)
gen insample = !missing(pro_2)

*Covariates 
keep eff_cost_loan genero edad val_pren_pr masqueprepa faltas ${C0} ///
	prenda fee_arms insample

*Drop missing values
foreach var of varlist $C0 eff_cost_loan genero edad val_pren_pr masqueprepa faltas ///
	prenda fee_arms insample { 
	drop if missing(`var')
	}

*order 
order eff_cost_loan fee_arms edad genero val_pren_pr masqueprepa faltas ${C0} ///
	prenda insample 
	
export delimited "$directorio/_aux/eff_te_heterogeneity.csv", replace nolabel


