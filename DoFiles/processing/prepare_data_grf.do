/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification: October. 19, 2021
* Modifications: 		
* Files used:     
		- Master.dta
* Files created:  
		- heterogeneity_grf.csv
		- heterogeneity_te.csv
* Purpose: Creation of dataset for the HTE for main variables

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear


sort NombrePignorante fecha_inicial
gen eff_cost_loan = fc_admin/prestamo

*Covariates - Randomization - Outcomes
keep apr eff_cost_loan def_c des_c fc_admin  /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 /// *Controls
	log_prestamo pr_recup  edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto_bin /// *Dummy variables
	masqueprepa  pb 
	
	
order apr eff_cost_loan def_c des_c fc_admin  /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 /// *Controls
	log_prestamo pr_recup  edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto_bin /// *Dummy variables
	masqueprepa  pb 
	
	
export delimited "$directorio/_aux/heterogeneity_grf.csv", replace nolabel


********************************************************************************


use "$directorio/DB/Master.dta", clear


sort NombrePignorante fecha_inicial
gen eff_cost_loan = fc_admin/prestamo

*Covariates - Randomization - Outcomes
keep apr eff_cost_loan def_c des_c fc_admin   /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 /* *Controls */
	
order apr eff_cost_loan def_c des_c fc_admin   /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 /* *Controls */
	

export delimited "$directorio/_aux/heterogeneity_te.csv", replace nolabel

