clear all
set more off

********************************************************************************

* a plugin has to be explicitly loaded (unlike an ado file)
* "capture" means that if it's loaded already this line won't give an error

*Directory for .\boost64.dll 
cd "$directorio"
*cd D:\WKDir-Stata
capture program drop boost_plugin
program boost_plugin, plugin using("$directorio\boost64.dll")

set more off
set seed 12345678

********************************************************************************
*Dependent variable
global dep_var pago_frec_vol
*Independent variable (not factor variables)
global ind_var dummy_dow1-dummy_dow5 dummy_suc1-dummy_suc5 /// *Controls
	prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	dummy_prenda_tipo1-dummy_prenda_tipo4 dummy_edo_civil1-dummy_edo_civil3  /// *Categorical covariates
	dummy_choose_same1-dummy_choose_same2   /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time rec_cel
	
*Train fraction
global trainf=0.85
*Directory for plots
global plot "$directorio/Figuras/Boost"
*Activate profiler (=1)
global profiler=0
********************************************************************************


	
********************************************************************************
*Data preparation		
import delimited "$directorio\_aux\data_pfv.csv", clear 
	
********************************************************************************

********************************************************************************
keep nombrepignorante prenda ///
	$dep_var $ind_var 

*Drop missing values
foreach var of varlist $dep_var $ind_var {
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

export delimited "$directorio/_aux/data_pfv_test.csv", replace nolabel

	
************************************************************************	
***** RUN R CODE ***********************************************************
************************************************************************

preserve	
import delimited "$directorio\_aux\pred_${dep_var}.csv", clear
tempfile temp_rf_pred
save `temp_rf_pred'
restore
merge 1:1 nombrepignorante prenda using `temp_rf_pred', ///
	keepusing(rf_pred) keep(3)

	
********************************************************************************
*Summary statistics for independent variables
su $dep_var $ind_var in 1/$trainn


********************************************************************************
do "$directorio\DoFiles\prediction_oos_stata.do"
********************************************************************************
	