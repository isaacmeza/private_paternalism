
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
		- 
* Files created:  

* Purpose: Treatment effect bars measured in std deviations for soft arms

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear


foreach var of varlist def_c fc_admin apr {
		
	* Z-score
	su `var'
	gen std_`var' = (`var'-`r(mean)')/`r(sd)'
	
	*Pooled
	reg std_`var' i.t_prod $C0 if inlist(t_prod,1,3,5), vce(cluster suc_x_dia)
	estimates store `var'_p
}


*Beta plots (pooled)
coefplot (def_c_p, keep(3.t_producto) rename(3.t_producto = "Default") color(navy) cismooth(color(navy) n(10)) offset(0.04)) /// 
(fc_admin_p, keep(3.t_producto) rename(3.t_producto = "Financial Cost") color(navy)  cismooth(color(navy) n(10))  offset(0.04)) ///
(apr_p, keep(3.t_producto) rename(3.t_producto = "APR") color(navy)  cismooth(color(navy) n(10))  offset(0.04)) ///
(def_c_p, keep(5.t_producto) rename(5.t_producto = "Default") color(maroon) cismooth(color(maroon) n(10))  offset(-0.04)) ///
(fc_admin_p, keep(5.t_producto) rename(5.t_producto = "Financial Cost")  color(maroon) cismooth(color(maroon) n(10)) offset(-0.04)) ///
(apr_p, keep(5.t_producto) rename(5.t_producto = "APR")  color(maroon) cismooth(color(maroon) n(10)) offset(-0.04)) ///
, nooffset legend(order(11 "Forced-soft" 44 "Choice-soft") pos(6) rows(1)) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects (std deviations)")
graph export "$directorio\Figuras\soft_te.pdf", replace
