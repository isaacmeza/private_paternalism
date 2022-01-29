/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: January. 28, 2022
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Decomposition of treatment effect 

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear


*Decomposition of FC
gen payment_fc = sum_pdisc_c-sum_pay_fee_c-sum_int_c
gen payment_eff = sum_porcp_c-sum_porc_pay_fee_c-sum_porc_int_c

*Robustness
gen fc_tc = eff_cost_loan - trans_cost
gen eff_tc = eff_cost_loan - trans_cost/prestamo 

eststo clear

foreach var of varlist  fc_admin fc_tc payment_fc sum_pay_fee_c sum_int_c cost_losing_pawn ///
	eff_cost_loan eff_tc payment_eff sum_porc_pay_fee_c sum_porc_int_c def_c {
	*OLS 
	eststo : reg `var' pro_2 $C0, vce(cluster suc_x_dia)
	su `var' if e(sample) & pro_2==0
	estadd scalar ContrMean = `r(mean)'
}

esttab using "$directorio/Tables/reg_results/decomposition_main_te.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") replace 
