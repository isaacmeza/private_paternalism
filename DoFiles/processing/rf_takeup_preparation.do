/*
Data preparation for Random Forest take-up prediction 
*/

********************************************************************************
*Dependent variable
global takeup_var pago_frec_vol_fee
*Independent variable (not factor variables)
global ind_var dummy_dow1-dummy_dow5 dummy_suc1-dummy_suc5 /// *Controls
	prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	dummy_prenda_tipo1-dummy_prenda_tipo4 dummy_edo_civil1-dummy_edo_civil3  /// *Categorical covariates
	dummy_choose_same1-dummy_choose_same2   /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time rec_cel
	
*Train fraction
global trainf=0.85
********************************************************************************


********************************************************************************
*Data preparation (created in prepare_data_pfv.do)		
import delimited "$directorio\_aux\data_pfv.csv", clear 
	
********************************************************************************

********************************************************************************
keep nombrepignorante prenda ///
	$takeup_var $ind_var 

*Drop missing values
foreach var of varlist $takeup_var $ind_var {
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
drop u

global trainn= round($trainf *`r(N)'+1)	
gen insample=1 in 1/$trainn
replace insample=0 if missing(insample)

export delimited "$directorio/_aux/data_pfv_test_${takeup_var}.csv", replace nolabel
