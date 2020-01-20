/*
Creation of dataset for the HTE for main variables
*/

use "$directorio/DB/Master.dta", clear


sort NombrePignorante fecha_inicial

*Covariates - Randomization - Outcomes
keep def_c fc_admin_disc dias_primer_pago /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial /// *Admin variables
	dummy_dow* dummy_suc* /// *Controls
	prestamo pr_recup  edad visit_number num_arms faltas /// *Continuous covariates
	dummy_prenda_tipo* dummy_edo_civil*  /// *Categorical covariates
	dummy_choose_same* dummy_trabajo*  /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  /// 
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time rec_cel
	
	
order def_c fc_admin_disc dias_primer_pago /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial /// *Admin variables
	dummy_dow* dummy_suc* /// *Controls
	prestamo pr_recup  edad visit_number num_arms faltas /// *Continuous covariates
	dummy_prenda_tipo* dummy_edo_civil*  /// *Categorical covariates
	dummy_choose_same1 dummy_choose_same2 dummy_trabajo1-dummy_trabajo8  /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time rec_cel

	
	
export delimited "$directorio/_aux/heterogeneity_grf.csv", replace nolabel


