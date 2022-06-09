
********************
version 17.0
********************
/*
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 10, 2021
* Last date of modification:   
* Modifications:		
* Files used:     
		- 
* Files created:  

* Purpose: APR distribution

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear


xtile perc_apr_d = apr, nq(100)

*Histograms of effective cost
twoway (hist apr if perc_apr_d<=99 & des_c==0 , w(20) percent lwidth(medthick) lcolor(navy) color(ltblue)) ///
		(hist apr if perc_apr_d<=99 & des_c==1, w(20) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec.") pos(6) rows(1)) xtitle("APR %") graphregion(color(white))
graph export "$directorio/Figuras/hist_apr.pdf", replace


