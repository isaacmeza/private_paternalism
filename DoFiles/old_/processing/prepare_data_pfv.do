/*
Creation of dataset for the prediction of take-up
*/


use "$directorio/DB/Master.dta", clear


sort NombrePignorante fecha_inicial

*Covariates - Randomization - Outcomes
keep NombrePignorante prenda suc_x_dia producto /// *Admin variables
	dummy_dow* dummy_suc* /// *Controls
	prestamo pr_recup  edad visit_number num_arms faltas /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  /// 
	masqueprepa estresado_seguido OC pb fb hace_presupuesto tentado low_cost low_time rec_cel
	
	
	
order NombrePignorante prenda suc_x_dia /// *Admin variables
	dummy_dow* dummy_suc* /// *Controls
	prestamo pr_recup  edad visit_number num_arms faltas /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  /// 
	masqueprepa estresado_seguido OC pb fb hace_presupuesto tentado low_cost low_time rec_cel

	
	
keep if inrange(producto,4,7)
*Frequent voluntary payment        
gen pago_frec_vol_fee=(producto==5) if (producto==4 | producto==5)
gen pago_frec_vol_promise=(producto==7) if (producto==6 | producto==7)
gen pago_frec_vol=inlist(producto,5,7)
drop producto
		
export delimited "$directorio/_aux/data_pfv.csv", replace nolabel


