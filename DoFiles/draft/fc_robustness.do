
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 11, 2022
* Last date of modification:  January. 10, 2023
* Modifications: Table of coefficients		
	- Remove coefficient plot
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Robustness analysis of TE in FC. We use different definitions of FC as robustness check of the main TE 

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear

eststo clear
foreach var of varlist fc_admin fc_survey fc_tc fc_int fc_fa apr apr_survey apr_tc apr_int apr_fa {
	
	*Pooled
	eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
	
}	

esttab using "$directorio/Tables/reg_results/fc_robustness.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") replace keep(2.t_producto 4.t_producto)
