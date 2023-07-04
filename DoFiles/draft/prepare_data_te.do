
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification:   May. 31, 2023
* Modifications: Added covariates for heterogeneity
				-Added one covariate (sure_confidence) and restrict to new sample and definition of dep. Keep only relevant dep vars.
				-Recover NA's
* Files used:     
		- 
* Files created:  

* Purpose: Creation of dataset for the FC and APR HTE

*******************************************************************************/



********************************************************************************

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

gen fee_arms = inlist(prod, 2 , 4 , 5) & !missing(prod)
gen insample = !missing(pro_2)
replace apr = -apr


*Covariates 
keep apr fee_arms $C0 ///
	prestamo edad faltas c_trans t_llegar /// *Continuous covariates
	fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido  /// *Dummy variables
	prenda insample suc_x_dia

*order 
order apr fee_arms $C0 ///
	prestamo edad faltas c_trans t_llegar /// *Continuous covariates
	fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido  /// *Dummy variables
	prenda insample suc_x_dia
	

*Drop individuals without any observables 
drop if missing(fam_pide) & missing(ahorros) & missing(t_consis1) & missing(t_consis2) & missing(confidence_100) & missing(hace_presupuesto) & missing(tentado) & missing(rec_cel) & missing(pres_antes) & missing(cta_tanda) & missing(genero) & missing(masqueprepa) & missing(estresado_seguido) 

*Drop individuals without observables 
foreach var of varlist edad faltas c_trans t_llegar fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido { 
	drop if missing(`var') 
	}

export delimited "$directorio/_aux/apr_te_heterogeneity.csv", replace nolabel



********************************************************************************

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

gen fee_arms = inlist(prod, 2 , 4 , 5) & !missing(prod)
gen insample = !missing(pro_2)
gen apr_narrow = -apr


*Covariates 
keep apr_narrow fee_arms ///
	 /// *Controls
	prestamo edad   /// *Continuous covariates
	genero pres_antes  masqueprepa  /// *Dummy variables
	prenda insample 

*order 
order apr_narrow fee_arms ///
	 /// *Controls
	prestamo edad   /// *Continuous covariates
	genero pres_antes  masqueprepa  /// *Dummy variables
	prenda insample 
	
*Drop individuals without any observables 
drop if missing(genero) & missing(pres_antes) & missing(masqueprepa) 

*Impute NA's
foreach var of varlist  genero pres_antes  masqueprepa { 
	replace `var' = 2 if missing(`var') 
	}

*Drop individuals without observables
foreach var of varlist edad { 
	drop if missing(`var') 
	}

export delimited "$directorio/_aux/apr_narrow_te_heterogeneity.csv", replace nolabel



********************************************************************************

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

gen fee_arms = inlist(prod, 2 , 4 , 5) & !missing(prod)
gen insample = !missing(pro_2)
replace fc_admin = -fc_admin


*Covariates 
keep fc_admin fee_arms $C0 ///
	prestamo edad faltas c_trans t_llegar /// *Continuous covariates
	fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido  /// *Dummy variables
	prenda insample suc_x_dia

*order 
order fc_admin fee_arms $C0 ///
	prestamo edad faltas c_trans t_llegar /// *Continuous covariates
	fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido  /// *Dummy variables
	prenda insample suc_x_dia
	

*Drop individuals without any observables 
drop if missing(fam_pide) & missing(ahorros) & missing(t_consis1) & missing(t_consis2) & missing(confidence_100) & missing(hace_presupuesto) & missing(tentado) & missing(rec_cel) & missing(pres_antes) & missing(cta_tanda) & missing(genero) & missing(masqueprepa) & missing(estresado_seguido) 

*Drop individuals without observables 
foreach var of varlist edad faltas c_trans t_llegar fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido { 
	drop if missing(`var') 
	}

export delimited "$directorio/_aux/fc_admin_te_heterogeneity.csv", replace nolabel



********************************************************************************


use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

gen fee_arms = inlist(prod, 2 , 4 , 5) & !missing(prod)
gen insample = !missing(pro_2)


*Covariates 
keep def_c fee_arms $C0 ///
	prestamo edad faltas c_trans t_llegar /// *Continuous covariates
	fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido  /// *Dummy variables
	prenda insample suc_x_dia

*order 
order def_c fee_arms $C0 ///
	prestamo edad faltas c_trans t_llegar /// *Continuous covariates
	fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido  /// *Dummy variables
	prenda insample suc_x_dia
	

*Drop individuals without any observables 
drop if missing(fam_pide) & missing(ahorros) & missing(t_consis1) & missing(t_consis2) & missing(confidence_100) & missing(hace_presupuesto) & missing(tentado) & missing(rec_cel) & missing(pres_antes) & missing(cta_tanda) & missing(genero) & missing(masqueprepa) & missing(estresado_seguido) 

*Drop individuals without observables 
foreach var of varlist edad faltas c_trans t_llegar fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido { 
	drop if missing(`var') 
	}

export delimited "$directorio/_aux/def_c_te_heterogeneity.csv", replace nolabel



********************************************************************************

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

gen fee_arms = inlist(prod, 2 , 4 , 5) & !missing(prod)
gen insample = !missing(pro_2)


*Covariates 
keep des_c fee_arms $C0 ///
	prestamo edad faltas c_trans t_llegar /// *Continuous covariates
	fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido  /// *Dummy variables
	prenda insample suc_x_dia

*order 
order des_c fee_arms $C0 ///
	prestamo edad faltas c_trans t_llegar /// *Continuous covariates
	fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido  /// *Dummy variables
	prenda insample suc_x_dia
	

*Drop individuals without any observables 
drop if missing(fam_pide) & missing(ahorros) & missing(t_consis1) & missing(t_consis2) & missing(confidence_100) & missing(hace_presupuesto) & missing(tentado) & missing(rec_cel) & missing(pres_antes) & missing(cta_tanda) & missing(genero) & missing(masqueprepa) & missing(estresado_seguido) 

*Drop individuals without observables 
foreach var of varlist edad faltas c_trans t_llegar fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido { 
	drop if missing(`var') 
	}

export delimited "$directorio/_aux/des_c_te_heterogeneity.csv", replace nolabel



********************************************************************************