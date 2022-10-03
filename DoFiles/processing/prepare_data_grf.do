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

*Covariates - Randomization - Outcomes
keep apr def_c des_c fc_admin /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 suc_x_dia /// *Controls
	edad  faltas val_pren_std genero masqueprepa

order apr def_c des_c fc_admin /// *Dependent variables
	pro_* fee NombrePignorante prenda fecha_inicial  /// *Admin variables
	$C0 suc_x_dia /// *Controls
	edad  faltas val_pren_std genero masqueprepa

	*Drop individuals without observables
foreach var of varlist edad faltas val_pren_std genero masqueprepa { 
	drop if missing(`var') 
	}
	
export delimited "$directorio/_aux/heterogeneity_grf.csv", replace nolabel


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

