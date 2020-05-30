** RUN R : pfv_pred.R

global dep_var pago_frec_vol_promise

import delimited "$directorio\_aux\pred_${dep_var}.csv", clear
tempfile temp_rf_pred
save `temp_rf_pred'

import delimited "$directorio\_aux\data_pfv.csv", clear 
merge 1:1 nombrepignorante prenda using `temp_rf_pred', ///
	keepusing(rf_pred) keep(3)
	
	
********************************************************************************
********************************************************************************
*INTERACTIONS	
		
*Lists of variables according to its clasification
	local familia fam_pide fam_comun 
	local ingreso faltas ahorros
	local self_control oc pb hace_presupuesto tentado rec_cel
	local experiencia pres_antes cta_tanda pr_recup visit_number
	local otros  edad genero masqueprepa estresado_seguido low_cost low_time
		
			
	do "$directorio\DoFiles\appendix\coeficients_fvp.do" ///
		"${dep_var}" "`familia'" "`ingreso'" "`self_control'" ///
		"`experiencia'" "`otros'"	
