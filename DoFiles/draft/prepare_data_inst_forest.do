
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


*Behavioral variables
gen confidence_100 = (pr_recup==100) if !missing(pr_recup)
gen distressed = (f_estres==1)*(r_estress==1) if !missing(f_estres) & !missing(r_estress)
gen tentacion = (tempt==3) if !missing(tempt)
		
	
*IV
gen forced = choose==1 | t_prod==2
gen choice_arm = (t_prod==4)


*ToT
ivregress 2sls eff $C0  edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb confidence_100 distressed tentacion (forced = choice_arm) if inlist(t_prod,1,4), vce(cluster suc_x_dia)
*TuT
ivregress 2sls eff $C0  edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb  (forced = choice_arm) if inlist(t_prod,2,4), vce(cluster suc_x_dia)



su $C0  edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb confidence_100 distressed tentacion



foreach var of varlist apr eff {
	preserve	
	*ToT
	eststo : ivregress 2sls `var'   (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
	cap drop esample_tot
	gen esample_tot = e(sample)

	*TUT
	eststo : ivregress 2sls `var'  $C0  edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)
	cap drop esample_tut	
	gen esample_tut = e(sample)	
		
	keep if esample_tot==1 | esample_tut==1	
	keep `var' $C0  edad  faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb forced choice_arm esample_tot esample_tut prenda

	*Mark individuals without observables
	foreach varc of varlist edad faltas val_pren_std genero pres_antes plan_gasto masqueprepa pb { 
		drop if missing(`varc') 
	}
	export delimited "$directorio/_aux/tot_tut_`var'.csv", replace nolabel
	restore
}

	