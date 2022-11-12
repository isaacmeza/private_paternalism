
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose:  

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
	
	gen x0_ = (t_prod==4)*(prod==4)
gen x1 = (t_prod==4)*(prod==5)
gen z0 = -(t_prod==1)
gen z1 = (t_prod==2)
gen z2 = (t_prod==4)

qui su choose_commitment 
local p_rate = `r(mean)'

*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4



gen eligio = choose_commitment
replace eligio = 0 if missing(eligio)


gen no_eligio = 1-eligio

	*Single LATE
eststo : ivregress 2sls apr  (choice_nsq =  choice_vs_control) , vce(cluster suc_x_dia)
	*LATE + ATE

eststo : ivregress gmm apr  z1 ( x1 = z0  ), vce(cluster suc_x_dia)
eststo : ivregress 2sls apr z1 (x1 = z2), vce(cluster suc_x_dia)
eststo : ivregress gmm apr  z1 (  x0 =  z2  ), vce(cluster suc_x_dia) first

eststo : ivregress gmm apr  z1 (  x0 =  z2  ), vce(cluster suc_x_dia) first






	*Reduced form 
qui su choose_commitment 
local p_rate = `r(mean)'	
eststo : reg apr i.t_prod ,  vce(cluster suc_x_dia)	 
local tot = (_b[4.t_prod])/(`p_rate')
di `tot'


*ASL
su choose_commitment
local p_rate = `r(mean)'	
su apr if choose==1 & t_prod==4
local ey_d1_z2 = `r(mean)'	
su apr if t_prod==2
local ey_z1 = `r(mean)'	





*ASB
su apr if t_prod==1
local ey_z0 = `r(mean)'	
su apr if choose==0 & t_prod==4
local ey_d0_z2 = `r(mean)'	

di "ASL"
di (`ey_d1_z2' - `ey_z1')/(1-`p_rate')

di "ASB"
di (`ey_z0' - `ey_d0_z2')/(`p_rate')

di "ASG"
*ASG
di (`ey_d1_z2' - `ey_z1')/(1-`p_rate') - (`ey_z0' - `ey_d0_z2')/(`p_rate')



reg apr i.prod 
*ASB
di (_b[1.prod]-_b[4.prod])/(`p_rate')
di (-_b[4.prod])/(`p_rate')


gen z_1 = prod==2

gen z_0 = prod==1

gen z_2_d_0 = prod==4

gen ddd = t_prod==2 | prod==5

gen new_y = apr*(1-z_1)*(1-ddd)

gen uno_z1 = 1-z_1
gen z_2ddd = -(t_prod==4)*ddd


gen z_2 = t_prod==4


gen uno_d_z2 = (1-ddd)*z_2
ivregress 2sls new_y uno_z1 (z_2ddd = z_2), nocons
ivregress 2sls new_y z_0 (uno_d_z2 = z_2), nocons


ivregress 2sls apr z_1 (z_2_d_0 = z_0) if prod!=5

*ASL
di (_b[5.prod]-_b[2.prod])/(1-`p_rate')



gen eligio = choose_commitment
replace eligio = 0 if missing(eligio)


gen zz1 =  prod==2
gen zz2  = prod==4 | prod==5
gen dd  = prod==5


ivregress 2sls apr   i.prod ( eligio = 4.t_prod)



su choose_commitment

tot_tut apr Z choose_commitment ,  vce(cluster suc_x_dia)	

 su choose_commitment


******** TuT ********
*********************
	*Single LATE
eststo : ivregress 2sls apr  (choice_nonsq =  forced_fee_vs_choice) , vce(cluster suc_x_dia)
	*LATE + ATE
eststo : ivregress 2sls apr z0 (x0 = z2), vce(cluster suc_x_dia)

	*Reduced form 
qui su choose_commitment 
local p_rate = `r(mean)'	
eststo : reg apr i.t_prod ,  vce(cluster suc_x_dia)	 
local tut = (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')
di `tut'
