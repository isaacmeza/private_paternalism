********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	April. 12, 2022
* Last date of modification: 
* Modifications: 		
* Files used:     
		- Master.dta
* Files created:  
* Purpose:  Huber & Mellace (2015) bounds for TOT & TUT

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

* Rescale to positive scale (benefits)
replace apr = -apr

keep apr des_c fc_admin def_c choose_commitment t_prod suc_x_dia $C0

* From the choice arm we know that around 90% of people are non-choosers
qui su choose_commitment 
local p_rate = `r(mean)'

* Cut the top and bottom p_rate% to obtain an upper a lower bound for E[Y_0 | C=0]
* Cut the top and bottom (1-p_rate)% to obtain an upper a lower bound for E[Y_0 | C=1]

cap drop perc_apr
* Identify the distribution F_0 of Y_0 from the status-quo arm.
xtile perc_apr = apr if t_prod==1, nq(1000)

su apr if perc_apr == round(`p_rate'*1000)  & t_prod==1
local bottom_0 = `r(mean)'
su apr if apr>`bottom_0' & t_prod==1
local ub_0_0= `r(mean)'
su apr if apr<`bottom_0' & t_prod==1
local lb_0_1= `r(mean)'

su apr if perc_apr == 1000-round(`p_rate'*1000) & t_prod==1
local top_0 = `r(mean)'
su apr if apr<`top_0'  & t_prod==1
local lb_0_0 = `r(mean)'
su apr if apr>`top_0'  & t_prod==1
local ub_0_1 = `r(mean)'


* Cut the top and bottom p_rate% to obtain an upper a lower bound for E[Y_1 | C=0]
* Cut the top and bottom (1-p_rate)% to obtain an upper a lower bound for E[Y_1 | C=1]

cap drop perc_apr
* Identify the distribution F_1 of Y_1 from the treatment arm.
xtile perc_apr = apr if t_prod==2, nq(1000)

su apr if perc_apr == 90 & t_prod==2
local bottom_1 = `r(mean)'
su apr if apr>`bottom_1' & t_prod==2
local ub_1_0= `r(mean)'
su apr if apr<`bottom_1' & t_prod==2
local lb_1_1= `r(mean)'

su apr if perc_apr == 1000-round(`p_rate'*1000) & t_prod==2
local top_1 = `r(mean)'
su apr if apr<`top_1'  & t_prod==2
local lb_1_0 = `r(mean)'
su apr if apr>`top_1'  & t_prod==2
local ub_1_1 = `r(mean)'


*Bounds for the TUT
local ub_tut = `ub_1_0'-`lb_0_0'
local lb_tut = `lb_1_0'-`ub_0_0'

*Bounds for the ToT
local ub_tot = `ub_1_1'-`lb_0_1'
local lb_tot = `lb_1_1'-`ub_0_1'


reg apr i.t_prod ,  vce(cluster suc_x_dia)	 
*ToT
local tot = (_b[4.t_prod])/(`p_rate')
*TUT
local tut = (_b[2.t_prod]-_b[4.t_prod])/(1-`p_rate')	
	

di `ub_tut'
di `lb_tut'

di `ub_tot'
di `lb_tot'

di `tot'
di `tut'
