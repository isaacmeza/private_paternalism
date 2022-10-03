
********************
version 17.0
********************
/*
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 10, 2021
* Last date of modification:  Sept. 26, 2021 
* Modifications: Put together FC & APR distributions
		- Change of main outcomes and added third not-ended category
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
twoway (hist apr if def_c==1 , percent lwidth(medthick) lcolor(navy) color(ltblue)) ///
		(hist apr if des_c==1, percent lwidth(medthick) lcolor(black) color(none)) ///
		(hist apr if des_c==0 & def_c==0, percent lwidth(medthick) lcolor(black) color(red%20)), ///
		legend(order(1 "Default" 2 "Recovery" 3 "Not closed") pos(6) rows(1)) xtitle("APR %")  graphregion(color(white))
graph export "$directorio/Figuras/hist_apr.pdf", replace



*Histograms of financial cost
xtile perc_a = fc_admin, nq(100)

twoway (hist fc_admin if perc_a<=99 & def_c==1, w(300) percent lwidth(medthick) lcolor(navy) color(ltblue)) ///
		(hist fc_admin if perc_a<=99 & des_c==1, w(300) percent lwidth(medthick) lcolor(black) color(none)) ///
		(hist fc_admin if perc_a<=99 & des_c==0 & def_c==0, w(300) percent lwidth(medthick) lcolor(black) color(red%15)), ///
		legend(order(1 "Default" 2 "Recovery" 3 "Not closed") pos(6) rows(1)) xtitle("Financial Cost")  graphregion(color(white))
graph export "$directorio/Figuras/hist_fc.pdf", replace


