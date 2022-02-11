/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: February. 10, 2022
* Modifications: Add pooled regression treatment arms Fee/Choice
* Files used:     
		- 
* Files created:  

* Purpose: Decomposition of treatment effect 

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear


*Decomposition of FC
gen payment_fc = sum_p_c-sum_pay_fee_c-sum_int_c
replace payment_fc = 0 if payment_fc<0
*Decomposition of APR
gen payment_apr = sum_porcp_c-sum_porc_pay_fee_c-sum_porc_int_c
replace payment_apr = 0 if payment_apr<0
	*participation of each component in apr 
foreach var of varlist 	payment_fc sum_pay_fee_c sum_int_c {
	gen share_`var' = `var'/fc_admin
	gen `var'_p = share_`var'*apr
	
}
	gen share_def_c = 0
	replace share_def_c = prestamo/(0.7*fc_admin) if def_c==1
	gen def_c_p = share_def_c*apr

	
eststo clear

*FC
foreach var of varlist  fc_admin  payment_fc sum_pay_fee_c sum_int_c cost_losing_pawn  {
	*OLS 
	eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su `var' if e(sample) & pro_2==0
	estadd scalar ContrMean = `r(mean)'
}

*APR
foreach var of varlist  apr payment_fc_p sum_pay_fee_c_p sum_int_c_p def_c_p {
	*OLS 
	eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
}


esttab using "$directorio/Tables/reg_results/decomposition_main_te.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") replace 
