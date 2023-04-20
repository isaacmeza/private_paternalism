
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: Apr. 02, 2023
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Test null of no clerk fixed effects.

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
eststo clear

*TE
foreach var of varlist fc_admin def_c apr {
	*OLS 
	eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	eststo : reghdfe `var' i.t_prod $C0 if inlist(t_prod,1,2,4), absorb(valuador) vce(cluster suc_x_dia)
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
}



esttab using "$directorio/Tables/reg_results/clerk_fe.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(2.t_producto 4.t_producto) replace 


		
		