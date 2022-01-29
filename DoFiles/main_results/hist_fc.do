/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 10, 2021
* Last date of modification: January. 26, 2022
* Modifications: Added FC dist		
* Files used:     
		- 
* Files created:  

* Purpose: Financial Cost distribution

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear

*Control group
keep if pro_2==0

*Histograms of effective cost
xtile perc_eff_d = eff_cost_loan, nq(100)

twoway (hist eff_cost_loan if perc_eff_d<=99 & des_c==0 , w(0.05) percent lwidth(medthick) lcolor(ltblue) color(ltblue)) ///
		(hist eff_cost_loan if perc_eff_d<=99 & des_c==1, w(0.05) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec.")) xtitle("APR") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_eff.pdf", replace



*Histograms of financial cost
xtile perc_a = fc_admin, nq(100)

twoway (hist fc_admin if perc_a<=99 & des_c==0, w(500) percent lwidth(medthick) lcolor(ltblue) color(ltblue)) ///
		(hist fc_admin if perc_a<=99 & des_c==1, w(500) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec." )) xtitle("Financial Cost") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_fc.pdf", replace


