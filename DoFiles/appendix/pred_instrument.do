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

global trainf=0.85
********************************************************************************

	
********************************************************************************

** RUN R CODE : instrument_pred.R 

********************************************************************************


forvalues i = 1/3 {
	*Dependent variable
	global depvar pf_suc_`i'

	*Random Forest take-up prediction (created in instrument_pred.R)
	import delimited "$directorio\_aux\pred_pf_suc_`i'.csv", clear
	
	ds $depvar insample rf_pred, not 
	global ind_var `r(varlist)'
		
	
	********************************************************************************
	*Summary statistics for independent variables
	su $depvar $ind_var if insample==1

	global oos "oos_instrument"
	********************************************************************************
	do "$directorio\DoFiles\appendix\prediction_oos_stata.do"
	********************************************************************************
	}	
