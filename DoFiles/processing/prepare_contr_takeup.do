********************************************************************************

** RUN R CODE : grf.R 

********************************************************************************



********************************************************************************

foreach pred in  pago_frec_vol_fee  {

	*Data preparation (created in rf_takeup_preparation.do)
	import delimited "$directorio\_aux\data_pfv_test_`pred'.csv", clear 
	drop if missing(`pred')
	qui describe, varlist
	local vrlist =  r(varlist)
	tempfile temp_train
	save `temp_train'
	
	foreach arm in pro_2  {
		foreach effect in def_c fc_admin_disc {
			*(Dataset created in grf.R)
			import delimited "$directorio/_aux/grf_`arm'_`effect'.csv", clear
			
			gen insample = 0
			append using `temp_train'	
			keep `vrlist' tau_hat_oobpredictions 
			export delimited "$directorio/_aux/`arm'_`pred'_`effect'.csv", replace nolabel

			}
		}
	}
