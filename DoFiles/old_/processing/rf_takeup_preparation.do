/*
Data preparation for Random Forest take-up prediction 
*/

********************************************************************************

*Independent variable (not factor variables)
global ind_var dummy_dow1-dummy_dow5 dummy_suc1-dummy_suc5 /// *Controls
	prestamo pr_recup  edad visit_number num_arms faltas /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido oc pb fb hace_presupuesto tentado low_cost low_time rec_cel
	
	
*Train fraction
global trainf=0.85
set seed 9834623
********************************************************************************


********************************************************************************
*Data preparation (created in prepare_data_pfv.do)		
import delimited "$directorio\_aux\data_pfv.csv", clear 
	
********************************************************************************

foreach takeup_var in pago_frec_vol pago_frec_vol_fee pago_frec_vol_promise {
	********************************************************************************
	preserve
	keep nombrepignorante prenda ///
		`takeup_var' $ind_var 

	*Drop missing values
	foreach var of varlist `takeup_var' $ind_var {
		drop if missing(`var')
		}
		
	*Randomize order of data set
	gen u=uniform()
	sort u
	forvalues i=1/2 {
		replace u=uniform()
		sort u
		}
	qui count
	local obs = `r(N)'
	drop u

	global trainn= round($trainf *`obs'+1)	
	gen insample=1 in 1/$trainn
	replace insample=0 if missing(insample)

	export delimited "$directorio/_aux/data_pfv_test_`takeup_var'.csv", replace nolabel
	restore
	}
