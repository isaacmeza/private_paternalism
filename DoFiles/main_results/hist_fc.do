
********************
version 17.0
********************
/*
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 10, 2021
* Last date of modification:  February. 19, 2021 
* Modifications: Put together FC & APR distributions	
* Files used:     
		- 
* Files created:  

* Purpose: FC/ APR distribution

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear

*Control group
keep if pro_2==0

*Histograms of effective cost
xtile perc_apr_d = apr, nq(100)

twoway (hist apr if apr<=750 & des_c==0 , w(20) percent lwidth(medthick) lcolor(navy) color(ltblue)) ///
		(hist apr if apr<=750 & des_c==1, w(20) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec.")) xtitle("APR %") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_apr.pdf", replace



*Histograms of financial cost
xtile perc_a = fc_admin, nq(100)

twoway (hist fc_admin if perc_a<=99 & des_c==0, w(500) percent lwidth(medthick) lcolor(navy) color(ltblue)) ///
		(hist fc_admin if perc_a<=99 & des_c==1, w(500) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec." )) xtitle("Financial Cost") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_fc.pdf", replace


