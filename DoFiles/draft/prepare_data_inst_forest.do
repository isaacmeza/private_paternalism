
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Last date of modification:   May. 2, 2023
* Modifications:-Added covariates for heterogeneity
				-Added one covariate (sure_confidence) and restrict to new sample and definition of dep vars
* Files used:     
		- 
* Files created:  

* Purpose: TOT-TUT data preparation

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

*Depvars
replace apr = -apr
gen eff = -fc_admin/prestamo

		
*IV
gen forced = choose==1 | t_prod==2
gen choice_arm = (t_prod==4)


foreach var of varlist apr eff {
	preserve	
	*ToT
	ivregress 2sls `var' $C0  edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb confidence_100 (forced = choice_arm) if inlist(t_prod,1,4), vce(cluster suc_x_dia)
	cap drop esample_tot
	gen esample_tot = e(sample)

	*TUT
	ivregress 2sls `var' $C0 edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb confidence_100 (forced = choice_arm) if inlist(t_prod,2,4), vce(cluster suc_x_dia)
	cap drop esample_tut	
	gen esample_tut = e(sample)	
		
	keep if esample_tot==1 | esample_tut==1	
	keep `var' $C0  edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb confidence_100 forced choice_arm esample_tot esample_tut prenda

	*Mark individuals without observables
	foreach varc of varlist val_pren_std confidence_100 genero pres_antes edad plan_gasto faltas masqueprepa pb  { 
		drop if missing(`varc') 
	}
	export delimited "$directorio/_aux/tot_tut_`var'.csv", replace nolabel
	restore
}

	