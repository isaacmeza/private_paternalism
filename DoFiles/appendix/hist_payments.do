
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 23, 2022
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Histogram of payments

*******************************************************************************/
*/

use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2.dta", clear	   


*Status-quo
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==1, w(4) discrete percent color(navy%70)) ///
	(scatteri 0 30 25 30 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 60 25 60 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 90 25 90 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Percent")
graph export "$directorio/Figuras/hist_payments_sq.pdf", replace
		
*Forced commitment	
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==2, w(4) discrete percent color(navy%70)) ///
	(scatteri 0 30 25 30 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 60 25 60 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 90 25 90 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Percent")
graph export "$directorio/Figuras/hist_payments_fc.pdf", replace
	
*Choice commitment	
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==4, w(4) discrete percent color(navy%70)) ///
	(scatteri 0 30 25 30 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 60 25 60 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 90 25 90 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Percent")
graph export "$directorio/Figuras/hist_payments_cc.pdf", replace	


*Forced soft	
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==3, w(4) discrete percent color(navy%70)) ///
	(scatteri 0 30 25 30 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 60 25 60 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 90 25 90 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Percent")
graph export "$directorio/Figuras/hist_payments_fs.pdf", replace
	
*Choice soft	
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==5, w(4) discrete percent color(navy%70)) ///
	(scatteri 0 30 25 30 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 60 25 60 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	(scatteri 0 90 25 90 , c(l lwidth(vvvthick)) m(i) color(maroon%90)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Percent")
graph export "$directorio/Figuras/hist_payments_cs.pdf", replace	