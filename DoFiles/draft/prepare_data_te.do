
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification:   October. 2, 2022
* Modifications: Added covariates for heterogeneity
* Files used:     
		- 
* Files created:  

* Purpose: Creation of dataset for the FC and APR HTE

*******************************************************************************/
*/


********************************************************************************

use "$directorio/DB/Master.dta", clear

gen fee_arms = inlist(prod, 2 , 3 , 4 , 5 , 6 , 7) & !missing(prod)
gen insample = !missing(pro_2)
replace apr = -apr


*Covariates 
keep apr fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 

*order 
order apr fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 
	

*Drop individuals without observables
foreach var of varlist edad faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb { 
	drop if missing(`var') 
	}

	
export delimited "$directorio/_aux/apr_te_heterogeneity.csv", replace nolabel



********************************************************************************

use "$directorio/DB/Master.dta", clear

gen fee_arms = inlist(prod, 2 , 3 , 4 , 5 , 6 , 7) & !missing(prod)
gen insample = !missing(pro_2)
gen eff = -fc_admin/prestamo


*Covariates 
keep eff fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 

*order 
order eff fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 
	

*Drop individuals without observables
foreach var of varlist edad faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb { 
	drop if missing(`var') 
	}

	
export delimited "$directorio/_aux/eff_te_heterogeneity.csv", replace nolabel



********************************************************************************

use "$directorio/DB/Master.dta", clear

*Compare fee vs choice arm (ITT for TuT)
replace pro_2 = . if t_prod==1
replace pro_2 = 0 if t_prod==4 

gen fee_arms = inlist(prod, 1, 2 , 3 , 4 , 5 ) & !missing(prod)
gen insample = !missing(pro_2)
gen eff_tut = -fc_admin/prestamo


*Covariates 
keep eff_tut fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 

*order 
order eff_tut fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 
	

*Drop individuals without observables
foreach var of varlist edad faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb { 
	drop if missing(`var') 
	}

	
export delimited "$directorio/_aux/eff_tut_te_heterogeneity.csv", replace nolabel



********************************************************************************

use "$directorio/DB/Master.dta", clear

gen fee_arms = inlist(prod, 2 , 3, 4 , 5 , 6, 7) & !missing(prod)
gen insample = !missing(pro_2)


*Covariates 
keep def_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 

*order 
order def_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 

*Drop individuals without observables
foreach var of varlist edad faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb { 
	drop if missing(`var') 
	}
	
export delimited "$directorio/_aux/def_te_heterogeneity.csv", replace nolabel

********************************************************************************

use "$directorio/DB/Master.dta", clear

gen fee_arms = inlist(prod, 2 , 3, 4 , 5 , 6, 7) & !missing(prod)
gen insample = !missing(pro_2)


*Covariates 
keep sum_porcp_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 

*order 
order sum_porcp_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 
	
*Drop individuals without observables
foreach var of varlist edad faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb { 
	drop if missing(`var') 
	}
		
export delimited "$directorio/_aux/sumporcp_te_heterogeneity.csv", replace nolabel

********************************************************************************

use "$directorio/DB/Master.dta", clear

gen fee_arms = inlist(prod, 2 , 3, 4 , 5 , 6, 7) & !missing(prod)
gen insample = !missing(pro_2)


*Covariates 
keep des_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 

*order 
order des_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero pres_antes plan_gasto masqueprepa pb /// *Dummy variables
	prenda insample 
	
*Drop individuals without observables
foreach var of varlist edad faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb { 
	drop if missing(`var') 
	}
		
export delimited "$directorio/_aux/des_te_heterogeneity.csv", replace nolabel
