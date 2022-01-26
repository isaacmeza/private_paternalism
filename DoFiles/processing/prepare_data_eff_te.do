/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification:  October. 19, 2021
* Modifications: 		
* Files used:     
		- 
* Files created:  

* Purpose: Creation of dataset for the effective cost/loan ratio HTE

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear


gen fee_arms = inlist(prod, 2 , 3 , 4 , 5 , 6 , 7) & !missing(prod)
gen insample = !missing(pro_2)

*Covariates 
keep eff_cost_loan fee_arms ///
	$C0 /// *Controls
	log_prestamo pr_recup  edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto_bin /// *Dummy variables
	masqueprepa  pb  ///
	prenda insample 

*order 
order eff_cost_loan fee_arms ///
	$C0 /// *Controls
	log_prestamo pr_recup  edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto_bin /// *Dummy variables
	masqueprepa  pb ///
	prenda insample 
	
/*
*Drop individuals without observables
foreach var of varlist edad  faltas val_pren_std genero masqueprepa { 
	drop if missing(`var') 
	}
*/
	
export delimited "$directorio/_aux/eff_te_heterogeneity.csv", replace nolabel


