
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	-
* Last date of modification: Sept. 26, 2022
* Modifications: Redefinition of main outcomes
* Files used:     
		- 
* Files created:  

* Purpose: Treatment effect bars measured in std deviations for main outcomes

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear


foreach var of varlist def_c des_c fc_admin apr {
		
	* Z-score
	su `var'
	gen std_`var' = (`var'-`r(mean)')/`r(sd)'
	
	*OLS 
	reg std_`var' pro_2 $C0, vce(cluster suc_x_dia)
	estimates store `var'_2
	
	reg std_`var' pro_4 $C0, vce(cluster suc_x_dia)
	estimates store `var'_4

	*Pooled
	reg std_`var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	estimates store `var'_p
}


*Beta plots (pooled)
coefplot (def_c_p, keep(2.t_producto) rename(2.t_producto = "Default") color(navy) cismooth(color(navy) n(10)) offset(0.04)) /// 
(des_c_p, keep(2.t_producto) rename(2.t_producto = "Recovery") color(navy) cismooth(color(navy) n(10)) offset(0.04)) /// 
(fc_admin_p, keep(2.t_producto) rename(2.t_producto = "Financial Cost") color(navy)  cismooth(color(navy) n(10))  offset(0.04)) ///
(apr_p, keep(2.t_producto) rename(2.t_producto = "APR") color(navy)  cismooth(color(navy) n(10))  offset(0.04)) ///
(def_c_p, keep(4.t_producto) rename(4.t_producto = "Default") color(maroon) cismooth(color(maroon) n(10))  offset(-0.04)) ///
(des_c_p, keep(4.t_producto) rename(4.t_producto = "Recovery") color(maroon) cismooth(color(maroon) n(10))  offset(-0.04)) ///
(fc_admin_p, keep(4.t_producto) rename(4.t_producto = "Financial Cost")  color(maroon) cismooth(color(maroon) n(10)) offset(-0.04)) ///
(apr_p, keep(4.t_producto) rename(4.t_producto = "APR")  color(maroon) cismooth(color(maroon) n(10)) offset(-0.04)) ///
, nooffset legend(order(11 "Forced-commitment" 66 "Choice-commitment") pos(6) rows(1)) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects (std deviations)")
graph export "$directorio\Figuras\main_te.pdf", replace
