
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	January. 26, 2022
* Last date of modification: February. 16, 2022  
* Modifications: Pooled specification		
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Quantile reg for main outcomes measured in std deviations

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear

*Dependent variables
local qlist  0.15 0.25 0.47 0.75 0.85 


foreach var of varlist fc_admin  apr {
	
	local q = 1
	foreach quant in `qlist' {
		
		*Q-regs
		qreg `var' pro_2 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_2
		
		qreg `var' pro_4 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_4
		
		*Q-regs (pooled)
		qreg `var' i.t_prod $C0 if inlist(t_prod,1,2,4),  vce(robust) q(`quant')
		estimates store `var'_`q'_p		
		local q = `q'+1
	}


	*Beta plots
	coefplot (`var'_5_2, keep(pro_2) rename(pro_2 = "85%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) /// 
	(`var'_4_2, keep(pro_2) rename(pro_2 = "75%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_3_2, keep(pro_2) rename(pro_2 = "50%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_2_2, keep(pro_2) rename(pro_2 = "25%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_1_2, keep(pro_2) rename(pro_2 = "15%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_5_4, keep(pro_4) rename(pro_4 = "85%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) /// 
	(`var'_4_4, keep(pro_4) rename(pro_4 = "75%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_3_4, keep(pro_4) rename(pro_4 = "50%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_2_4, keep(pro_4) rename(pro_4 = "25%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_1_4, keep(pro_4) rename(pro_4 = "15%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06))  ///
	, nooffset legend(order(11 "Forced-commitment" 66 "Choice-commitment")) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects") 


/*	
	*Beta plots (pooled)
	coefplot (`var'_5_p, keep(2.t_producto) rename(2.t_producto = "85%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) /// 
	(`var'_4_p, keep(2.t_producto) rename(2.t_producto = "75%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_3_p, keep(2.t_producto) rename(2.t_producto = "50%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_2_p, keep(2.t_producto) rename(2.t_producto = "25%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_1_p, keep(2.t_producto) rename(2.t_producto = "15%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_5_p, keep(4.t_producto) rename(4.t_producto = "85%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) /// 
	(`var'_4_p, keep(4.t_producto) rename(4.t_producto = "75%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_3_p, keep(4.t_producto) rename(4.t_producto = "50%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_2_p, keep(4.t_producto) rename(4.t_producto = "25%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_1_p, keep(4.t_producto) rename(4.t_producto = "15%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06))  ///
	, nooffset legend(order(11 "Forced-commitment" 66 "Choice-commitment")) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects")	
*/

	graph export "$directorio\Figuras\qreg_`var'.pdf", replace

}
