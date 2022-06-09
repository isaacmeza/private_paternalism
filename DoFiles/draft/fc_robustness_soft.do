
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 16, 2022 
* Last date of modification:  
* Modifications: 
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Robustness analysis of TE in FC. We use different definitions of FC as robustness check for the TE of the SOFT arms

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear

*FC + Travel cost
gen fc_tc = fc_admin + trans_cost
gen fc_s_tc = fc_survey + trans_cost

*Fully adjusted
gen fc_fa = fc_s_tc - sum_int_c


eststo clear
foreach var of varlist fc_admin fc_survey fc_tc fc_s_tc fc_fa apr apr_survey apr_tc apr_s_tc apr_fa {
	
	* Z-score
	su `var'
	gen std_`var' = (`var'-`r(mean)')/`r(sd)'
	
	
	*Pooled
	qui eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,3,5), vce(cluster suc_x_dia)
	qui su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
	
	reg std_`var' i.t_prod $C0 if inlist(t_prod,1,3,5), vce(cluster suc_x_dia)
	estimates store `var'_p
}	

esttab using "$directorio/Tables/reg_results/fc_robustness_soft.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") replace keep(3.t_producto 5.t_producto)

		

*Beta plots (pooled)
coefplot (fc_admin_p, keep(3.t_producto) rename(3.t_producto = "FC (appraised value)") color(navy) cismooth(color(navy) n(10)) offset(0.09)) /// 
(fc_survey_p, keep(3.t_producto) rename(3.t_producto = "FC (subjective value)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_tc_p, keep(3.t_producto) rename(3.t_producto = "FC + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_s_tc_p, keep(3.t_producto) rename(3.t_producto = "FC (subj.) + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_fa_p, keep(3.t_producto) rename(3.t_producto = "FC (fully adjusted)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_p, keep(3.t_producto) rename(3.t_producto = "APR") color(navy) cismooth(color(navy) n(10)) offset(0.09)) /// 
(apr_survey_p, keep(3.t_producto) rename(3.t_producto = "APR (subj.)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_tc_p, keep(3.t_producto) rename(3.t_producto = "APR + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_s_tc_p, keep(3.t_producto) rename(3.t_producto = "APR (subj.) + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_fa_p, keep(3.t_producto) rename(3.t_producto = "APR (fully adjusted)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_admin_p, keep(5.t_producto) rename(5.t_producto = "FC (appraised value)") color(maroon) cismooth(color(maroon) n(10)) offset(-0.09)) /// 
(fc_survey_p, keep(5.t_producto) rename(5.t_producto = "FC (subjective value)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(fc_tc_p, keep(5.t_producto) rename(5.t_producto = "FC + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(fc_s_tc_p, keep(5.t_producto) rename(5.t_producto = "FC (subj.) + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(fc_fa_p, keep(5.t_producto) rename(5.t_producto = "FC (fully adjusted)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_p, keep(5.t_producto) rename(5.t_producto = "APR") color(maroon) cismooth(color(maroon) n(10)) offset(-0.09)) /// 
(apr_survey_p, keep(5.t_producto) rename(5.t_producto = "APR (subj.)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_tc_p, keep(5.t_producto) rename(5.t_producto = "APR + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_s_tc_p, keep(5.t_producto) rename(5.t_producto = "APR (subj.) + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_fa_p, keep(5.t_producto) rename(5.t_producto = "APR (fully adjusted)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
, headings("FC (appraised value)" = "{bf:Financial Cost}" "APR" = "{bf:APR}") nooffset legend(order(11 "Forced-soft" 121 "Choice-soft") pos(6) rows(1)) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects (std deviations)")
graph export "$directorio\Figuras\fc_robustness_soft.pdf", replace