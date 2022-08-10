
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

* Purpose: ToT-TuT analysis 

*******************************************************************************/
*/
clear all
set maxvar 100000
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

*keep if visit_number==1


* Rescale to positive scale (benefits)
*gen eff_cost_loan = -fc_admin/prestamo
replace apr = -apr
replace apr_consolidated = -apr_consolidated


	*No payment | recovers ---> negation of +pay & defaults
gen pay_default = (pays_c==0 | des_c==1)

keep apr apr_consolidated des_c des_con_c pay_default choose_commitment t_prod prod suc_x_dia visit_number

********************************************************************************


eststo clear


*Stack IV/GMM
gen x0 = -(t_prod==4)*(prod==4)
gen x1 = (t_prod==4)*(prod==5)
gen z0 = -(t_prod==1)
gen z1 = (t_prod==2)
gen z2 = (t_prod==4)




******** TOT-TUT-ATE ********
*****************************

foreach var of varlist apr apr_consolidated des_c des_con_c  {
reg `var' i.t_prod,  vce(cluster suc_x_dia)	 
qui su choose_commitment 
local p_rate = `r(mean)'
local tot = (_b[4.t_prod])/(`p_rate')
local tut = (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
local ate = _b[2.t_prod]


	*Stack GMM
matrix define initval = (`tot', `ate', 1, `tut', `ate', 1)	
eststo : gmm (`var' - {tot: x1 z1} - {b1}) (`var' - {tut: x0 z0} - {b0}), instruments(1: z1 z2) instruments(2: z0 z2) vce(cluster suc_x_dia) twostep  from(initval) winitial(identity)
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
estadd scalar ContrMean = `mn'
test z0 = x0
estadd scalar ate_tut = `r(p)'
test z1 = x1
estadd scalar ate_tot = `r(p)'
local sign_tt = sign(e(b)[1,4]-e(b)[1,1])
test x0-x1 = 0
estadd scalar tut_tot = `r(p)'
estadd scalar tut_tot_1 = normal(`sign_tt'*sqrt(r(chi2)))




reg `var' i.t_prod if visit_number==1 ,  vce(cluster suc_x_dia)	 
qui su choose_commitment if visit_number==1
local p_rate = `r(mean)'
local tot = (_b[4.t_prod])/(`p_rate')
local tut = (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
local ate = _b[2.t_prod]


	*Stack GMM
matrix define initval = (`tot', `ate', 1, `tut', `ate', 1)	
eststo : gmm (`var' - {tot: x1 z1} - {b1}) (`var' - {tut: x0 z0} - {b0}) if  visit_number==1, instruments(1: z1 z2) instruments(2: z0 z2) vce(cluster suc_x_dia) twostep  from(initval) winitial(identity)
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
estadd scalar ContrMean = `mn'
test z0 = x0
estadd scalar ate_tut = `r(p)'
test z1 = x1
estadd scalar ate_tot = `r(p)'
local sign_tt = sign(e(b)[1,4]-e(b)[1,1])
test x0-x1 = 0
estadd scalar tut_tot = `r(p)'
estadd scalar tut_tot_1 = normal(`sign_tt'*sqrt(r(chi2)))



}


cap drop x0 x1 z0 z1 z2


gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4


gen x0 = -(Z==2)*(choose_commitment==0)
gen x1 = (Z==2)*(choose_commitment==1)
gen z0_ = -(Z==0)
gen z0 = (Z==0)
gen z1 = (Z==1)
gen z2 = (Z==2)


sort NombreP fecha_inicial
by NombreP  : gen first_tr = t_prod[1] if !missing(t_prod)


gen Zitt = 0 if first_tr==1
replace Zitt = 1 if first_tr==2
replace Zitt = 2 if first_tr==4


gen x0_itt = -(Zitt==2)*(choose_commitment==0)
gen x1_itt = (Zitt==2)*(choose_commitment==1)
gen z0_itt_ = -(Zitt==0)
gen z0_itt = (Zitt==0)
gen z1_itt = (Zitt==1)
gen z2_itt = (Zitt==2)



foreach var of varlist apr apr_consolidated des_c des_con_c  {
eststo : tot_tut `var' Z choose_commitment ,  vce(cluster suc_x_dia)
eststo : tot_tut `var' Z choose_commitment if visit_number==1,  vce(cluster suc_x_dia)
eststo : tot_tut `var' Z_itt choose_commitment ,  vce(cluster suc_x_dia)
}













*Save results	
esttab using "$directorio/Tables/reg_results/tot_tut_regse.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean"  ///
		"tot ToT" "p_tot p-value" ///
		"tut TuT" "p_tut p-value" ///
		"tot_tut ToT-TuT" "pvalue F p-value" ///
		"btsp_p Bootstrap (normal) p-val" ///
		"btsp_pc Bootstrap (percentile) p-val" ///
		"pval_ri RI p-val" ///
		)  replace 
		
 	
