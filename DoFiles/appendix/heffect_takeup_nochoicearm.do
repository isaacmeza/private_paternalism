********************************************************************************

** RUN FILES : pfv_pred_hte.R 

********************************************************************************

	
	
********************************************************************************
foreach pred in  pago_frec_vol_fee  {
	foreach arm in pro_2  {
		foreach effect in def_c  fc_admin_disc  {

			*Load data with heterogeneous predictions for the TE of var `effect'
			* of arm `arm' merged with probability prediction of `pred'
			* (created in pfv_pred_hte.R)
			import delimited "$directorio/_aux/pred_`arm'_`pred'_`effect'.csv", clear
			destring tau_hat_oobpredictions, replace force
			*Heterogeneous effect/Commitment device	
			if "`effect'"=="log_fc_admin" {
				local bw = 0.05
				}
			else {
				local bw = 0.075
				}
			lpoly tau_hat_oobpredictions rf_pred, noscatter ci bw(`bw')  ///
				lineopts(lwidth(thick)) ///
				scheme(s2mono) graphregion(color(white)) xtitle("Take up predictions (counterfactual)") ///
				ytitle("Heterogeneous effect") legend(off) title("") note("") 
			graph export "$directorio\Figuras\takeup_he_`arm'_`pred'_`effect'.pdf", replace			
			
			}
		}	
	}
