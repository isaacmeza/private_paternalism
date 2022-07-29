
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
gen eff_cost_loan = -fc_admin/prestamo
replace apr = -apr

	*No payment | recovers ---> negation of +pay & defaults
gen pay_default = (pays_c==0 | des_c==1)

keep apr  choose_commitment t_prod prod suc_x_dia $C0
********************************************************************************


gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4


gen x0 = -(Z==2)*(choose_commitment==0)
gen x1 = (Z==2)*(choose_commitment==1)
gen z0_ = -(Z==0)
gen z0 = (Z==0)
gen z1 = (Z==1)
gen z2 = (Z==2)
gen ones = 1
gen ones_ = -1
timer on 1
ivregress 2sls apr z1 (x1 = z2), vce(cluster suc_x_dia)
timer off 1

timer on 2
*mat list e(V)
tot_tut apr Z choose_commitment ,  vce(cluster suc_x_dia)
*mat list e(V)
timer off 2


timer list





