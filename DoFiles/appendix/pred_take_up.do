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


********************************************************************************
*Directory for plots
global plot "$directorio/Figuras/Boost"
*Activate profiler (=1)
global profiler=0
********************************************************************************

	
********************************************************************************

** RUN R CODE : pfv_pred.R 

********************************************************************************


foreach var in pago_frec_vol pago_frec_vol_fee pago_frec_vol_promise {

	*Dependent variable
	global takeup_var `var'

	*Random Forest take-up prediction (created in pfv_pred.R)
	import delimited "$directorio\_aux\pred_${takeup_var}.csv", clear

		
	********************************************************************************
	*Summary statistics for independent variables
	su $takeup_var $ind_var if insample==1


	********************************************************************************
	do "$directorio\DoFiles\appendix\prediction_oos_stata.do"
	********************************************************************************
	}	
