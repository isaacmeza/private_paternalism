
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 17, 2022 
* Last date of modification:  
* Modifications: 		
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Quantile reg for soft arms measured in std deviations

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear

*Dependent variables
local qlist  0.15 0.25 0.47 0.75 0.85 


foreach var of varlist fc_admin  apr {
	
	local q = 1
	foreach quant in `qlist' {
		
		*Q-regs
		qreg `var' pro_3 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_3
		
		qreg `var' pro_5 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_5
		
		*Q-regs (pooled)
		qreg `var' i.t_prod $C0 if inlist(t_prod,1,3,5),  vce(robust) q(`quant')
		estimates store `var'_`q'_p		
		local q = `q'+1
	}


	*Beta plots
	coefplot (`var'_5_3, keep(pro_3) rename(pro_3 = "85%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) /// 
	(`var'_4_3, keep(pro_3) rename(pro_3 = "75%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_3_3, keep(pro_3) rename(pro_3 = "50%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_2_3, keep(pro_3) rename(pro_3 = "25%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_1_3, keep(pro_3) rename(pro_3 = "15%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_5_5, keep(pro_5) rename(pro_5 = "85%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) /// 
	(`var'_4_5, keep(pro_5) rename(pro_5 = "75%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_3_5, keep(pro_5) rename(pro_5 = "50%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_2_5, keep(pro_5) rename(pro_5 = "25%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_1_5, keep(pro_5) rename(pro_5 = "15%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06))  ///
	, nooffset legend(order(11 "Forced-soft" 66 "Choice-soft")) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects") 


/*	
	*Beta plots (pooled)
	coefplot (`var'_5_p, keep(3.t_producto) rename(3.t_producto = "85%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) /// 
	(`var'_4_p, keep(3.t_producto) rename(3.t_producto = "75%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_3_p, keep(3.t_producto) rename(3.t_producto = "50%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_2_p, keep(3.t_producto) rename(3.t_producto = "25%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_1_p, keep(3.t_producto) rename(3.t_producto = "15%") color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_5_p, keep(5.t_producto) rename(5.t_producto = "85%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) /// 
	(`var'_4_p, keep(5.t_producto) rename(5.t_producto = "75%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_3_p, keep(5.t_producto) rename(5.t_producto = "50%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_2_p, keep(5.t_producto) rename(5.t_producto = "25%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_1_p, keep(5.t_producto) rename(5.t_producto = "15%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06))  ///
	, nooffset legend(order(11 "Forced-commitment" 66 "Choice-commitment")) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects")	
*/

	graph export "$directorio\Figuras\soft_qreg_`var'.pdf", replace

}
