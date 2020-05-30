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
global takeup_var pago_frec_vol
*Independent variable (not factor variables)
global ind_var dummy_dow1-dummy_dow5 dummy_suc1-dummy_suc5 /// *Controls
	prestamo pr_recup  edad visit_number num_arms faltas /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido oc pb fb hace_presupuesto tentado low_cost low_time rec_cel
	
*Train fraction
global trainf=0.85
*Directory for plots
global plot "$directorio/Figuras/Boost"
*Activate profiler (=1)
global profiler=0
********************************************************************************

	
********************************************************************************

** RUN R CODE : pfv_pred.R 

********************************************************************************

*Random Forest take-up prediction (created in pfv_pred.R)
import delimited "$directorio\_aux\pred_${takeup_var}.csv", clear

	
********************************************************************************
*Summary statistics for independent variables
su $takeup_var $ind_var if insample==1


********************************************************************************
do "$directorio\DoFiles\appendix\prediction_oos_stata.do"
********************************************************************************
	
