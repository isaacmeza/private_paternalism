
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Last date of modification:   May. 31, 2023
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

		
*IV
gen forced = choose==1 | t_prod==2
gen choice_arm = (t_prod==4)


foreach var of varlist apr {
	preserve	
	*ToT
	ivregress 2sls `var' $C0  edad faltas c_trans t_llegar fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido (forced = choice_arm) if inlist(t_prod,1,4), vce(cluster suc_x_dia)
	cap drop esample_tot
	gen esample_tot = e(sample)

	*TUT
	ivregress 2sls `var' $C0 edad faltas c_trans t_llegar fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido (forced = choice_arm) if inlist(t_prod,2,4), vce(cluster suc_x_dia)
	cap drop esample_tut	
	gen esample_tut = e(sample)	
		
	keep if esample_tot==1 | esample_tut==1	
	keep `var' $C0  edad faltas c_trans t_llegar fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido forced choice_arm esample_tot esample_tut prenda

	*Drop individuals without any observables 
	drop if missing(fam_pide) & missing(ahorros) & missing(t_consis1) & missing(t_consis2) & missing(confidence_100) & missing(hace_presupuesto) & missing(tentado) & missing(rec_cel) & missing(pres_antes) & missing(cta_tanda) & missing(genero) & missing(masqueprepa) & missing(estresado_seguido) 

	*Drop individuals without observables 
	foreach varc of varlist edad faltas c_trans t_llegar fam_pide ahorros t_consis1 t_consis2 confidence_100  hace_presupuesto tentado rec_cel pres_antes cta_tanda genero masqueprepa estresado_seguido { 
		drop if missing(`varc') 
		}
	export delimited "$directorio/_aux/tot_tut_`var'.csv", replace nolabel
	restore
}

	