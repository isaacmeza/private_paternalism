/*
Creation of dataset for the FC HTE
*/

use "$directorio/DB/Master.dta", clear


gen fee_arms = inlist(prod, 2 ,5) & !missing(prod)
gen insample = !missing(pro_2)

*Covariates 
keep fc_admin_disc genero edad val_pren_pr masqueprepa faltas ${C0} ///
	prenda fee_arms insample

*Drop missing values
foreach var of varlist $C0 fc_admin_disc genero edad val_pren_pr masqueprepa faltas ///
	prenda fee_arms insample { 
	drop if missing(`var')
	}

*order 
order fc_admin_disc fee_arms edad genero val_pren_pr masqueprepa faltas ${C0} ///
	prenda insample 
	
export delimited "$directorio/_aux/fc_te_heterogeneity.csv", replace nolabel


