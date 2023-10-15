
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 16, 2022
* Last date of modification: Sept. 26, 2022
* Modifications: Change decomposition since the formula of FC was redefined
* Files used:     
		- 
* Files created:  

* Purpose: Decomposition of treatment effect FOR SOFT ARMS 

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear


*Decomposition of APR
	*participation of each component in apr 
foreach var of varlist 	sum_int_c sum_pay_fee_c cost_losing_pawn downpayment_capital {
	gen eff_`var' = `var'/prestamo	
}

	
eststo clear

*FC
foreach var of varlist  fc_admin  sum_int_c sum_pay_fee_c cost_losing_pawn downpayment_capital  {
	*OLS 
	eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,3,5), vce(cluster suc_x_dia)
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
}

*APR
foreach var of varlist  apr eff_sum_int_c eff_sum_pay_fee_c eff_cost_losing_pawn eff_downpayment_capital  {
	*OLS 
	eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,3,5), vce(cluster suc_x_dia)
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
}


esttab using "$directorio/Tables/reg_results/decomposition_te_soft.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(3.t_producto 5.t_producto) replace 