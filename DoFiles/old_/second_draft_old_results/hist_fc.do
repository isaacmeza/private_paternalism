
********************
version 17.0
********************
/*
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 10, 2021
* Last date of modification:  January. 23, 2023 
* Modifications: Put together FC & APR distributions
		- Change of main outcomes and added third not-ended category
		- Remove not-ended 
* Files used:     
		- 
* Files created:  

* Purpose: FC/ APR distribution 

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear
replace apr = apr*100

*Histograms of effective cost
twoway (hist apr if def_c==1 & apr<1000 & t_prod==1, w(10) percent lwidth(medthick) lcolor(navy) color(ltblue)) ///
	(hist apr if des_c==1 & t_prod==1, w(10) percent lwidth(medthick) lcolor(black) color(none)) , ///
	legend(order(1 "Default" 2 "Recovery") pos(6) rows(1)) xtitle("APR %")  graphregion(color(white))
graph export "$directorio/Figuras/hist_apr.pdf", replace


*Histograms of financial cost
xtile perc_a = fc_admin if t_prod==1, nq(100)

twoway (hist fc_admin if perc_a<=99 & def_c==1 & t_prod==1, w(300) percent lwidth(medthick) lcolor(navy) color(ltblue)) ///
	(hist fc_admin if perc_a<=99 & des_c==1 & t_prod==1, w(300) percent lwidth(medthick) lcolor(black) color(none)) , ///
	legend(order(1 "Default" 2 "Recovery") pos(6) rows(1)) xtitle("Financial Cost")  graphregion(color(white))		
graph export "$directorio/Figuras/hist_fc.pdf", replace


