
use "$directorio/DB/Master.dta", clear

*Aux Dummies 
foreach var of varlist dow suc prenda_tipo edo_civil choose_same trabajo {
	tab `var', gen(dummy_`var')
	}

sort NombrePignorante fecha_inicial

*Covariates - Randomization - Outcomes
keep des_c  dias_al_desempenyo  num_p  sum_porcp_c ref_c reincidence /// *Dependent variables
	t_producto  NombrePignorante fecha_inicial /// *Admin variables
	dummy_dow* dummy_suc* /// *Controls
	prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	dummy_prenda_tipo* dummy_edo_civil*  /// *Categorical covariates
	dummy_choose_same* dummy_trabajo*  /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time
	
	
order des_c  dias_al_desempenyo  num_p  sum_porcp_c ref_c reincidence /// *Dependent variables
	t_producto  NombrePignorante fecha_inicial /// *Admin variables
	dummy_dow* dummy_suc* /// *Controls
	prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	dummy_prenda_tipo* dummy_edo_civil*  /// *Categorical covariates
	dummy_choose_same1 dummy_choose_same2 dummy_trabajo1-dummy_trabajo8  /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time
	
forvalues i = 2/5 {
	gen pro_`i' = (t_producto == `i') 
	replace pro_`i' = . if (t_producto!=`i' & t_producto!=1)
	}

		
export delimited "$directorio/_aux/heterogeneity_grf.csv", replace nolabel


** RUN R CODE HERE
