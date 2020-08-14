/*
Mechanism effect regression table
*/

set more off
*ADMIN DATA
use "$directorio/DB/Master.dta", clear


local mec_vars dias_primer_pago num_p  mn_p_c trans_cost dias_al_desempenyo  pays_c sum_porcp_c 


********************************************************************************
********************************Mechanism regression****************************
********************************************************************************

foreach arm of varlist pro_2 pro_3 pro_4 pro_5 {
	eststo clear
	foreach var of varlist `mec_vars' {

		eststo : reg `var' `arm' ${C0}, r cluster(suc_x_dia) 
		su `var' if e(sample) & `arm'==0
		estadd scalar ContrMean = `r(mean)'
		}


		eststo : reg sum_porcp_c i.`arm'##i.des_c ${C0}, r cluster(suc_x_dia)
		su sum_porcp_c if e(sample) & `arm'==0
		estadd scalar ContrMean = `r(mean)'
		
	*************************
		esttab using "$directorio/Tables/reg_results/mechanism_`arm'.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") replace 	
	}
