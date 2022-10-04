
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Last date of modification:   October. 2, 2022
* Modifications: Added covariates for heterogeneity
* Modifications: 
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
replace plan_gasto = inlist(plan_gasto,1,2) if !missing(plan_gasto)

*IV
gen choice_nsq = (prod==5) /*z=2, t=1*/
gen choice_vs_control = (t_prod==4) if inlist(t_prod,4,1) 
gen choice_nonsq = (prod!=4) /*z!=2, t!=0*/
gen forced_fee_vs_choice = (t_prod==2) if inlist(t_prod,2,4)


foreach var of varlist apr eff {
	preserve	
	*ToT
	eststo : ivregress 2sls `var'  $C0  edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
	cap drop esample_tot
	gen esample_tot = e(sample)

	*TUT
	eststo : ivregress 2sls `var'  $C0  edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)
	cap drop esample_tut	
	gen esample_tut = e(sample)	
		
	keep if esample_tot==1 | esample_tut==1	
	keep `var' $C0   edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb choice_nsq choice_vs_control choice_nonsq forced_fee_vs_choice esample_tot esample_tut prenda

	*Drop individuals without observables
	foreach varc of varlist edad faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb { 
		drop if missing(`varc') 
	}
	export delimited "$directorio/_aux/tot_tut_`var'.csv", replace nolabel
	restore
}

	