
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	July. 25, 2023
* Last date of modification: July. 25, 2023
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: TuT by response group

*******************************************************************************/
*/
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

replace fc_admin = -fc_admin
replace apr = -apr*100
 
*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4
	
*-------------------------------------------------------------------------------

********************************************************
*			      		 REGRESSIONS				   *
********************************************************

eststo clear

foreach vardep of varlist apr fc_admin {
	eststo : tot_tut `vardep' Z choose_commitment ,  vce(cluster suc_x_dia)
	foreach var of varlist val_pren_orig faltas pb hace_presupuesto pr_recup pres_antes edad genero masqueprepa {
		eststo : tot_tut `vardep' Z choose_commitment if !missing(`var'),  vce(cluster suc_x_dia)
	}
}
esttab using "$directorio/Tables/reg_results/tut_cond_survey.csv", se r2 ${star} b(a2) ///
		keep(TuT) replace 
	
	