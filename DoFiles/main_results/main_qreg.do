/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	January. 26, 2022
* Last date of modification:   
* Modifications:		
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Quantile reg for main outcomes measured in std deviations

*******************************************************************************/
*/



set more off
use "$directorio/DB/Master.dta", clear

*Dependent variables
local qlist  0.15 0.25 0.47 0.75 0.85 


foreach var of varlist fc_admin  eff_cost_loan {
	
	local q = 1
	foreach quant in `qlist' {
		
		*Q-regs
		qreg `var' pro_2 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_2
		
		qreg `var' pro_4 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_4
		
		local q = `q'+1
	}


	*Beta plots
	coefplot (`var'_5_2, keep(pro_2) rename(pro_2 = "85%") color(navy) cismooth(color(navy)) offset(0.06)) /// 
	(`var'_4_2, keep(pro_2) rename(pro_2 = "75%") color(navy) cismooth(color(navy)) offset(0.06)) ///
	(`var'_3_2, keep(pro_2) rename(pro_2 = "50%") color(navy) cismooth(color(navy)) offset(0.06)) ///
	(`var'_2_2, keep(pro_2) rename(pro_2 = "25%") color(navy) cismooth(color(navy)) offset(0.06)) ///
	(`var'_1_2, keep(pro_2) rename(pro_2 = "15%") color(navy) cismooth(color(navy)) offset(0.06)) ///
	(`var'_5_4, keep(pro_4) rename(pro_4 = "85%") color(maroon) cismooth(color(maroon)) offset(-0.06)) /// 
	(`var'_4_4, keep(pro_4) rename(pro_4 = "75%") color(maroon) cismooth(color(maroon)) offset(-0.06)) ///
	(`var'_3_4, keep(pro_4) rename(pro_4 = "50%") color(maroon) cismooth(color(maroon)) offset(-0.06)) ///
	(`var'_2_4, keep(pro_4) rename(pro_4 = "25%") color(maroon) cismooth(color(maroon)) offset(-0.06)) ///
	(`var'_1_4, keep(pro_4) rename(pro_4 = "15%") color(maroon) cismooth(color(maroon)) offset(-0.06))  ///
	, nooffset legend(order(51 "Forced-fee" 306 "Choice")) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects")

	graph export "$directorio\Figuras\qreg_`var'.pdf", replace

}
