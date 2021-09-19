/*
Creation of dataset for the effective cost/loan ratio decomposition HTE
*/

use "$directorio/DB/Master.dta", clear


gen fee_arms = inlist(prod, 2 , 3, 4 , 5 , 6, 7) & !missing(prod)
gen insample = !missing(pro_2)

*Covariates 
keep def_c genero edad val_pren_pr masqueprepa faltas ${C0} ///
	prenda fee_arms insample

*Drop missing values
foreach var of varlist $C0 def_c genero edad val_pren_pr masqueprepa faltas ///
	prenda fee_arms insample { 
	drop if missing(`var')
	}

*order 
order def_c fee_arms edad genero val_pren_pr masqueprepa faltas ${C0} ///
	prenda insample 
	
export delimited "$directorio/_aux/def_te_heterogeneity.csv", replace nolabel

********************************************************************************

use "$directorio/DB/Master.dta", clear


gen fee_arms = inlist(prod, 2 , 3, 4 , 5 , 6, 7) & !missing(prod)
gen insample = !missing(pro_2)

*Covariates 
keep sum_porcp_c genero edad val_pren_pr masqueprepa faltas ${C0} ///
	prenda fee_arms insample

*Drop missing values
foreach var of varlist $C0 sum_porcp_c genero edad val_pren_pr masqueprepa faltas ///
	prenda fee_arms insample { 
	drop if missing(`var')
	}

*order 
order sum_porcp_c fee_arms edad genero val_pren_pr masqueprepa faltas ${C0} ///
	prenda insample 
	
export delimited "$directorio/_aux/sumporcp_te_heterogeneity.csv", replace nolabel
