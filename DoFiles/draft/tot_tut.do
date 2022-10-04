
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification: May. 09, 2022
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: ToT-TuT analysis using STATA tot_tut package and compare it with stacked GMM

*******************************************************************************/
*/

clear all
set maxvar 100000
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

keep apr des_c def_c fc_admin  choose_commitment t_prod prod suc_x_dia 
replace fc_admin = -fc_admin
replace apr = -apr*100
replace des_c = des_c*100
replace def_c = -def_c*100

 
********************************************************************************

*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4

gen x0 = -(t_prod==4)*(prod==4)
gen x1 = (t_prod==4)*(prod==5)
gen z0 = -(t_prod==1)
gen z1 = (t_prod==2)
gen z2 = (t_prod==4)


******** TOT-TUT-ATE ********
*****************************

eststo clear
foreach var of varlist apr fc_admin des_c def_c {

		*ToT-TuT
	eststo : tot_tut `var' Z choose_commitment ,  vce(cluster suc_x_dia)	
	qui su `var' if e(sample) & t_prod==1
	local mn = `r(mean)'
	estadd scalar ContrMean = `mn'
	test ATE = TuT
	estadd scalar ate_tut = `r(p)'
	test ATE = ToT
	estadd scalar ate_tot = `r(p)'
	local sign_tt = sign(_b[ToT]-_b[TuT])
	test TuT-ToT = 0
	estadd scalar tut_tot = `r(p)'
	estadd scalar tut_tot_1 = ttail(r(df_r),`sign_tt'*sqrt(r(F)))
}



*Save results	
esttab using "$directorio/Tables/reg_results/tot_tut.csv", se ${star} b(a2) ///
		scalars("ContrMean Control Mean"  ///
		"ate_tut H_0 : ATE-TuT=0" ///
		"ate_tot H_0 : ATE-ToT=0" ///
		"tut_tot H_0 : ToT-TuT=0" ///
		"tut_tot_1 H_0 : ToT-TuT$\geq$ 0" ///
		)  replace 
		
 	
