
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
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Intermediate outcomes table

*******************************************************************************/
*/

set more off
*ADMIN DATA
use "$directorio/DB/Master.dta", clear


local mec_vars dias_primer_pago num_p  mn_p_c dias_al_desempenyo  dias_ultimo_mov  pays_c sum_porcp_c zero_pay_default


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
	
