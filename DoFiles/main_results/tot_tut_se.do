
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
gen x1 = (t_prod==2)
gen x2 = (t_prod==4)*(prod==5)
gen z = (t_prod==4)

qui su choose_commitment 
local p_rate = `r(mean)'

*-------------------------------------------------------------------------------
eststo clear

******** ToT ********
*********************
	*Single LATE
eststo : ivregress 2sls apr  (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
	*LATE + ATE
eststo : ivregress 2sls apr x1 (x2 = z), vce(cluster suc_x_dia)
	*Reduced form 
eststo : reg apr i.t_prod ,  vce(cluster suc_x_dia)	 
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
local tot = (_b[4.t_prod])/(`p_rate')
local tot_se = (_se[4.t_prod])/(`p_rate')

estadd scalar ContrMean = `mn'
estadd scalar tot = `tot'
estadd scalar tot_se = `tot_se'
	*Stack GMM
	

******** TuT ********
*********************
	*Single LATE
eststo : ivregress 2sls apr  (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)
	*LATE + ATE
eststo : ivregress 2sls apr x1 (x2 = z), vce(cluster suc_x_dia)
	*Reduced form 
eststo : reg apr i.t_prod ,  vce(cluster suc_x_dia)	 
qui su apr if e(sample) & t_prod==1
local mn = `r(mean)'
local tut = (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
local tut_se = (sqrt(e(V)[2,2]+e(V)[3,3]-2*e(V)[3,2]))/(`p_rate')

estadd scalar ContrMean = `mn'
estadd scalar tut = `tut'
estadd scalar tut_se = `tut_se'


*-------------------------------------------------------------------------------
*Save results	
esttab using "$directorio/Tables/reg_results/tot_tut_se.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean" ///
		"tot ToT" "tot_se ToT se" ///
		"tut TuT" "tot_se TuT se" ///
		)  replace 
		