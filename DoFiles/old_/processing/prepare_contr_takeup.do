/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification:   
* Modifications:		
* Files used:     
		- 
* Files created:  

* Purpose: 

*******************************************************************************/
*/


********************************************************************************

** RUN R CODE : grf.R 

********************************************************************************



********************************************************************************

foreach pred in  pago_frec_vol_fee  pago_frec_vol_promise pago_frec_vol {

	*Data preparation (created in rf_takeup_preparation.do)
	import delimited "$directorio\_aux\data_pfv_test_`pred'.csv", clear 
	drop if missing(`pred')
	replace insample = 1
	qui describe, varlist
	local vrlist =  r(varlist)
	tempfile temp_train
	save `temp_train'
	
	foreach arm in pro_2  {
		foreach effect in def_c des_c {
			*(Dataset created in grf.R)
			import delimited "$directorio/_aux/grf_`arm'_`effect'.csv", clear
			
			gen insample = 0
			append using `temp_train'	
			keep `vrlist' tau_hat_oobpredictions
				
			*Scramble (for proper read in R)
			gen uni=runiform()
			sort uni
			drop uni
			export delimited "$directorio/_aux/`arm'_`pred'_`effect'.csv", replace nolabel

			}
		}
	}
