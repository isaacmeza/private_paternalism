/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification:  January. 27, 2022
* Modifications: 
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
	genero masqueprepa /// *Dummy variables
	prenda insample 

*order 
order apr fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero masqueprepa /// *Dummy variables
	prenda insample 
	

*Drop individuals without observables
foreach var of varlist edad  faltas val_pren_std genero masqueprepa { 
	drop if missing(`var') 
	}

	
export delimited "$directorio/_aux/apr_te_heterogeneity.csv", replace nolabel

********************************************************************************

use "$directorio/DB/Master.dta", clear


gen fee_arms = inlist(prod, 2 , 3 , 4 , 5 , 6 , 7) & !missing(prod)
gen insample = !missing(pro_2)

gen eff_cost_loan = -fc_admin/prestamo


*Covariates 
keep eff_cost_loan fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero masqueprepa /// *Dummy variables
	prenda insample 

*order 
order eff_cost_loan fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero masqueprepa /// *Dummy variables
	prenda insample 
	

*Drop individuals without observables
foreach var of varlist edad  faltas val_pren_std genero masqueprepa { 
	drop if missing(`var') 
	}

	
export delimited "$directorio/_aux/eff_te_heterogeneity.csv", replace nolabel

********************************************************************************

use "$directorio/DB/Master.dta", clear


gen fee_arms = inlist(prod, 2 , 3, 4 , 5 , 6, 7) & !missing(prod)
gen insample = !missing(pro_2)

*Covariates 
keep def_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero masqueprepa /// *Dummy variables
	prenda insample 

*order 
order def_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero masqueprepa /// *Dummy variables
	prenda insample 

*Drop individuals without observables
foreach var of varlist edad  faltas val_pren_std genero masqueprepa { 
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
	genero masqueprepa /// *Dummy variables
	prenda insample 

*order 
order sum_porcp_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero masqueprepa /// *Dummy variables
	prenda insample 
	
*Drop individuals without observables
foreach var of varlist edad  faltas val_pren_std genero masqueprepa { 
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
	genero masqueprepa /// *Dummy variables
	prenda insample 

*order 
order des_c fee_arms ///
	$C0 /// *Controls
	edad  faltas val_pren_std /// *Continuous covariates
	genero masqueprepa /// *Dummy variables
	prenda insample 
	
*Drop individuals without observables
foreach var of varlist edad  faltas val_pren_std genero masqueprepa { 
	drop if missing(`var') 
	}
		
export delimited "$directorio/_aux/des_te_heterogeneity.csv", replace nolabel
