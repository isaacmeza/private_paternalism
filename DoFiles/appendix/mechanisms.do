
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: February. 17, 2022
* Modifications: Added conditional on default outcomes
* Files used:     
		- 
* Files created:  

* Purpose: Intermediate outcomes table 

*******************************************************************************/
*/

set more off
*ADMIN DATA
use "$directorio/DB/Master.dta", clear

*Makes payment & defaults
gen pay_default = (pays_c==1 & def_c==1)

*% of first payment
gen first_pay_porc = first_pay/prestamo

*Conditional on default
gen num_v_d = num_v if def_c==1
gen sum_porcp_c_d = sum_porcp_c if def_c==1
gen zero_pay_default_d = zero_pay_default if def_c==1

*Conditional on recovery
gen num_v_r = num_v if des_c==1
gen num_p_r = num_p if des_c==1

*Recovery on first visit
gen rec_fd = (des_c==1 & num_v==1)

*Mean % size of payment
gen mn_p_c_p = mn_p_c/prestamo

local mec_vars dias_primer_pago first_pay_porc rec_fd num_v num_v_d num_v_r mn_p_c_p dias_al_desempenyo  dias_ultimo_mov  sum_porcp_c sum_porcp_c_d pay_default zero_pay_default zero_pay_default_d 


********************************************************************************
***********************Intermediate outcomes regression*************************
********************************************************************************

eststo clear
foreach var of varlist `mec_vars' {

	eststo : reg `var' i.t_prod ${C0} if inlist(t_prod,1,2,4),  vce(cluster suc_x_dia) 
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
}

		
*************************
esttab using "$directorio/Tables/reg_results/mechanism.csv", se r2 ${star} b(a2) ///
	scalars("ContrMean Control Mean") keep(2.t_producto 4.t_producto) replace 	
	
