
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

* Purpose: Quantile effects for choosers vs non-choosers

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear

*Dependent variables
local qlist  0.15 0.25 0.47 0.75 0.85 


foreach var of varlist  fc_admin apr {
	
	local q = 1
	foreach quant in `qlist' {
		
		*Q-regs (HARD)
		qreg `var' pro_6 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_6
		
		qreg `var' pro_7 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_7
		
		*Q-regs (SOFT)
		qreg `var' pro_8 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_8
		
		qreg `var' pro_9 $C0,  vce(robust) q(`quant')
		estimates store `var'_`q'_9		
		
		local q = `q'+1	
	}


	*Beta plots
	coefplot (`var'_5_6, keep(pro_6) rename(pro_6 = "85%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) /// 
	(`var'_4_6, keep(pro_6) rename(pro_6 = "75%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_3_6, keep(pro_6) rename(pro_6 = "50%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_2_6, keep(pro_6) rename(pro_6 = "25%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_1_6, keep(pro_6) rename(pro_6 = "15%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_5_7, keep(pro_7) rename(pro_7 = "85%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) /// 
	(`var'_4_7, keep(pro_7) rename(pro_7 = "75%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_3_7, keep(pro_7) rename(pro_7 = "50%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_2_7, keep(pro_7) rename(pro_7 = "25%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_1_7, keep(pro_7) rename(pro_7 = "15%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06))  ///
	, nooffset legend(order(11 "Non-choosers" 66 "Choosers") pos(6) rows(1)) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects") 


	graph export "$directorio\Figuras\qreg_hard_`var'.pdf", replace

	*Beta plots
	coefplot (`var'_5_8, keep(pro_8) rename(pro_8 = "85%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) /// 
	(`var'_4_8, keep(pro_8) rename(pro_8 = "75%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_3_8, keep(pro_8) rename(pro_8 = "50%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_2_8, keep(pro_8) rename(pro_8 = "25%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_1_8, keep(pro_8) rename(pro_8 = "15%") msymbol(square) color(navy) cismooth(color(navy) n(10)) offset(0.06)) ///
	(`var'_5_9, keep(pro_9) rename(pro_9 = "85%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) /// 
	(`var'_4_9, keep(pro_9) rename(pro_9 = "75%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_3_9, keep(pro_9) rename(pro_9 = "50%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_2_9, keep(pro_9) rename(pro_9 = "25%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06)) ///
	(`var'_1_9, keep(pro_9) rename(pro_9 = "15%") color(maroon) cismooth(color(maroon) n(10)) offset(-0.06))  ///
	, nooffset legend(order(11 "Non-choosers" 66 "Choosers") pos(6) rows(1)) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects") 


	graph export "$directorio\Figuras\qreg_soft_`var'.pdf", replace	
}
