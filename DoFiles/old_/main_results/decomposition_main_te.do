
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: Jan. 16, 2023
* Modifications: Add pooled regression treatment arms Fee/Choice
	- Change decomposition since the formula of FC was redefined
* Files used:     
		- 
* Files created:  

* Purpose: Decomposition of treatment effect 

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear

eststo clear

*TE
foreach var of varlist fc_admin  sum_int_c sum_pay_fee_c downpayment_capital cost_losing_pawn def_c apr {
	*OLS 
	eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
}



esttab using "$directorio/Tables/reg_results/decomposition_main_te.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(2.t_producto 4.t_producto) replace 
