/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification:   
* Modifications:		
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Treatment effect with all arms

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear


foreach var of varlist fc_admin_disc def_c eff_cost_loan  {
	do "$directorio\DoFiles\appendix\plot_te_allarms.do" ///
				`var' "${C0}"
	}
