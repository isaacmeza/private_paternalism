
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

* Rescale to positive scale (benefits)
gen eff_cost_loan = -fc_admin/prestamo
replace apr = -apr

	*No payment | recovers ---> negation of +pay & defaults
gen pay_default = (pays_c==0 | des_c==1)

keep apr des_c eff_cost_loan pay_default choose_commitment t_prod prod suc_x_dia $C0
********************************************************************************

* TOT-TUT using LATE approach
*IV
gen choice_nsq = (prod==5) /*z=2, t=1*/
gen choice_vs_control = (t_prod==4) if inlist(t_prod,1,4) 
gen choice_nonsq = (prod!=4) /*z!=2, t!=0*/
gen forced_fee_vs_choice = (t_prod==2) if inlist(t_prod,2,4)

 
*Stack IV/GMM
gen x0 = -(t_prod==4)*(prod==4)
gen x1 = (t_prod==4)*(prod==5)
gen z0 = -(t_prod==1)
gen z1 = (t_prod==2)
gen z2 = (t_prod==4)

qui su choose_commitment 
local p_rate = `r(mean)'

*-------------------------------------------------------------------------------
eststo clear

******** ToT ********
*********************
	*Single LATE
eststo : ivregress 2sls apr  (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
eststo : ivregress 2sls apr $C0 (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
	*LATE + ATE
eststo : ivregress 2sls apr z1 (x1 = z2), vce(cluster suc_x_dia)
test z1 = x1
estadd scalar ate_tot = `r(p)'
eststo : ivregress 2sls apr z1 $C0 (x1 = z2), vce(cluster suc_x_dia)
test z1 = x1
estadd scalar ate_tot = `r(p)'
	*Diagnostics
ivreg2 apr z1 (x1 = z2), cluster(suc_x_dia) first endog(x1) orthog(z2)
	*Reduced form 
qui su choose_commitment 
local p_rate = `r(mean)'	
eststo : reg apr i.t_prod ,  vce(cluster suc_x_dia)	 
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
local tot = (_b[4.t_prod])/(`p_rate')
local tot_se = (_se[4.t_prod])/(`p_rate')
local ate = _b[2.t_prod]

estadd scalar ContrMean = `mn'
estadd scalar tot = `tot'
estadd scalar tot_se = `tot_se'

eststo : reg apr i.t_prod $C0,  vce(cluster suc_x_dia)	 
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
local tot = (_b[4.t_prod])/(`p_rate')
local tot_se = (_se[4.t_prod])/(`p_rate')
local ate = _b[2.t_prod]

estadd scalar ContrMean = `mn'
estadd scalar tot = `tot'
estadd scalar tot_se = `tot_se'
	*GMM
eststo : gmm (apr - {tot: x1 z1} - {b0}), instruments(z1 z2) vce(cluster suc_x_dia) twostep	
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
test z1 = x1
estadd scalar ate_tot = `r(p)'

eststo : gmm (apr - {tot: x1 z1 $C0} - {b0}), instruments(z1 z2 $C0) vce(cluster suc_x_dia) twostep 
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
estadd scalar ContrMean = `mn'
test z1 = x1
estadd scalar ate_tot = `r(p)'

******** TuT ********
*********************
	*Single LATE
eststo : ivregress 2sls apr  (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)
eststo : ivregress 2sls apr $C0 (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)
	*LATE + ATE
eststo : ivregress 2sls apr z0 (x0 = z2), vce(cluster suc_x_dia)
test z0 = x0
estadd scalar ate_tut = `r(p)'
eststo : ivregress 2sls apr z0 $C0 (x0 = z2), vce(cluster suc_x_dia)
test z0 = x0
estadd scalar ate_tut = `r(p)'
	*Diagnostics
ivreg2 apr z0 (x0 = z2), cluster(suc_x_dia) first endog(x0) orthog(z2)
	*Reduced form 
qui su choose_commitment 
local p_rate = `r(mean)'	
eststo : reg apr i.t_prod ,  vce(cluster suc_x_dia)	 
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
local tut = (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
local tut_se = (sqrt(e(V)[2,2]+e(V)[3,3]-2*e(V)[3,2]))/(1-`p_rate')

estadd scalar ContrMean = `mn'
estadd scalar tut = `tut'
estadd scalar tut_se = `tut_se'

eststo : reg apr i.t_prod $C0,  vce(cluster suc_x_dia)	 
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
local tut = (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
local tut_se = (sqrt(e(V)[2,2]+e(V)[3,3]-2*e(V)[3,2]))/(1-`p_rate')

estadd scalar ContrMean = `mn'
estadd scalar tut = `tut'
estadd scalar tut_se = `tut_se'
	*GMM
matrix define initval = (`tut', `ate', 1)
eststo : gmm (apr - {tut: x0 z0} - {b0}), instruments(z0 z2) vce(cluster suc_x_dia) twostep  from(initval) winitial(identity)
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
estadd scalar ContrMean = `mn'
test z0 = x0
estadd scalar ate_tut = `r(p)'

eststo : gmm (apr - {tut: x0 z0 $C0} - {b0}), instruments(z0 z2 $C0) vce(cluster suc_x_dia) twostep  winitial(identity)
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
estadd scalar ContrMean = `mn'
test z0 = x0
estadd scalar ate_tut = `r(p)'

******** TOT-TUT-ATE ********
*****************************
	*Stack GMM
matrix define initval = (`tot', `ate', 1, `tut', `ate', 1)	
eststo : gmm (apr - {tot: x1 z1} - {b1}) (apr - {tut: x0 z0} - {b0}), instruments(1: z1 z2) instruments(2: z0 z2) vce(cluster suc_x_dia) twostep  from(initval) winitial(identity)
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

eststo : gmm (apr - {tot: x1 z1 $C0} - {b1}) (apr - {tut: x0 z0 $C0} - {b0}), instruments(1: z1 z2 $C0) instruments(2: z0 z2 $C0) vce(cluster suc_x_dia) twostep  winitial(identity)
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

*-------------------------------------------------------------------------------
*Save results	
esttab using "$directorio/Tables/reg_results/tot_tut_se.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean" ///
		"tot ToT" "tot_se ToT se" ///
		"tut TuT" "tut_se TuT se" ///
		"ate_tot H_0 : ATE-ToT = 0" ///
		"ate_tut H_0 : ATE-TuT = 0" ///
		"tut_tot H_0 : TuT-ToT = 0" ///
		"tut_tot_1 H_0 : TuT-ToT $\geq$ 0" ///
		)  replace 
		