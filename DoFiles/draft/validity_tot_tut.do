********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	August. 21, 2023
* Last date of modification: 
* Modifications: 		
* Files used:     
		- Master.dta
* Files created:  
* Purpose:  Huber & Mellace (2015) exclusion validity for TOT & TUT

*******************************************************************************/
*/

clear all
set maxvar 100000
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

keep apr des_c def_c ref_c fc_admin  choose_commitment t_prod prod suc_x_dia 
replace fc_admin = -fc_admin
replace apr = -apr*100
replace des_c = des_c*100
replace def_c = 100-def_c*100
replace ref_c = 100-ref_c*100
 
********************************************************************************

*Definition of vars
gen Z = 0 if t_prod==1
replace Z = 1 if t_prod==2
replace Z = 2 if t_prod==4

su choose_commitment
local qq = `r(mean)'
bootstrap _b : tot_tut apr Z choose_commitment ,  vce(cluster suc_x_dia)	


local tot= _b[ToT]
local tut = _b[TuT]
tot_tut_noexclusion apr Z, quantile(`qq') tot(`tot') tut(`tut')

