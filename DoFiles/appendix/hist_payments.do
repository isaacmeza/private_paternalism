
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 23, 2022
* Last date of modification: March. 15, 2022
* Modifications: - added xline and frequency format
* Files used:     
		- 
* Files created:  

* Purpose: Histogram of payments

*******************************************************************************/
*/

use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2.dta", clear	   


*Status-quo
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==1, xline(30 60 90, lcolor(maroon%90)) w(3) discrete freq color(navy%70)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Count") xtitle(" ") ylabel(0(100)550)
graph export "$directorio/Figuras/hist_payments_sq.pdf", replace
		
*Forced commitment	
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==2, xline(30 60 90, lcolor(maroon%90)) w(3) discrete freq color(navy%70)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Count") xtitle(" ") ylabel(0(100)550)
graph export "$directorio/Figuras/hist_payments_fc.pdf", replace
	
*Choice commitment	
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==4, xline(30 60 90, lcolor(maroon%90)) w(3) discrete freq color(navy%70)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Count") xtitle(" ") ylabel(0(100)550)
graph export "$directorio/Figuras/hist_payments_cc.pdf", replace	


*Forced soft	
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==3, xline(30 60 90, lcolor(maroon%90)) w(3) discrete freq color(navy%70)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Count") xtitle(" ") ylabel(0(100)550)
graph export "$directorio/Figuras/hist_payments_fs.pdf", replace
	
*Choice soft	
twoway (hist days_payment if inrange(days_payment, 1,120) & t_prod==5, xline(30 60 90, lcolor(maroon%90)) w(3) discrete freq color(navy%70)) ///
	, xlabel(0(30)120) legend(off) graphregion(color(white))  ///
	ytitle("Count") xtitle(" ") ylabel(0(100)550)
graph export "$directorio/Figuras/hist_payments_cs.pdf", replace	