/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification: May. 02, 2023
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

*Covariates - Randomization - Outcomes
keep apr def_c des_c fc_admin /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 suc_x_dia /// *Controls
	edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb confidence_100

order apr def_c des_c fc_admin /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 suc_x_dia /// *Controls
	edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb confidence_100

	*Drop individuals without observables
foreach var of varlist val_pren_std confidence_100 genero pres_antes edad plan_gasto faltas masqueprepa pb { 
	drop if missing(`var') 
	}
	
export delimited "$directorio/_aux/heterogeneity_grf.csv", replace nolabel


********************************************************************************


use "$directorio/DB/Master.dta", clear

sort NombrePignorante fecha_inicial
replace apr = -fc_admin/prestamo
replace fc_admin = -fc_admin

*Covariates - Randomization - Outcomes
keep apr def_c des_c fc_admin /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	suc_x_dia /// *Controls
	edad genero pres_antes masqueprepa 

order apr def_c des_c fc_admin /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	suc_x_dia /// *Controls
	edad genero pres_antes masqueprepa 

	*Drop individuals without observables
foreach var of varlist  genero pres_antes edad masqueprepa { 
	drop if missing(`var') 
	}
	
export delimited "$directorio/_aux/heterogeneity_simple_grf.csv", replace nolabel


********************************************************************************


use "$directorio/DB/Master.dta", clear

sort NombrePignorante fecha_inicial

*Covariates - Randomization - Outcomes
keep apr def_c des_c fc_admin /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 suc_x_dia /* *Controls */
	
order apr def_c des_c fc_admin /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 suc_x_dia /* *Controls */
	
export delimited "$directorio/_aux/heterogeneity_te.csv", replace nolabel

