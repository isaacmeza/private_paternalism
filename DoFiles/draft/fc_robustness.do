
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 11, 2022
* Last date of modification:  February. 16, 2022 
* Modifications: Table of coefficients		
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Robustness analysis of TE in FC. We use different definitions of FC as robustness check of the main TE

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
	
	*OLS 
	reg std_`var' pro_2 $C0, vce(cluster suc_x_dia)
	estimates store `var'_2
	
	reg std_`var' pro_4 $C0, vce(cluster suc_x_dia)
	estimates store `var'_4	
	
	*Pooled
	qui eststo : reg `var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	qui su `var' if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
	
	reg std_`var' i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	estimates store `var'_p
}	

esttab using "$directorio/Tables/reg_results/fc_robustness.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") replace keep(2.t_producto 4.t_producto)

		
/*
*Beta plots
coefplot (fc_admin_2, keep(pro_2) rename(pro_2 = "FC (appraised value)") color(navy) cismooth(color(navy) n(10)) offset(0.09)) /// 
(fc_survey_2, keep(pro_2) rename(pro_2 = "FC (subjective value)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_tc_2, keep(pro_2) rename(pro_2 = "FC + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_s_tc_2, keep(pro_2) rename(pro_2 = "FC (subj.) + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_2, keep(pro_2) rename(pro_2 = "APR") color(navy) cismooth(color(navy) n(10)) offset(0.09)) /// 
(apr_survey_2, keep(pro_2) rename(pro_2 = "APR (subj.)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_tc_2, keep(pro_2) rename(pro_2 = "APR + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_s_tc_2, keep(pro_2) rename(pro_2 = "APR (subj.) + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_noint_2, keep(pro_2) rename(pro_2 = "APR - interests") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_admin_4, keep(pro_4) rename(pro_4 = "FC (appraised value)") color(maroon) cismooth(color(maroon) n(10)) offset(-0.09)) /// 
(fc_survey_4, keep(pro_4) rename(pro_4 = "FC (subjective value)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(fc_tc_4, keep(pro_4) rename(pro_4 = "FC + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(fc_s_tc_4, keep(pro_4) rename(pro_4 = "FC (subj.) + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_4, keep(pro_4) rename(pro_4 = "APR") color(maroon) cismooth(color(maroon) n(10)) offset(-0.09)) /// 
(apr_survey_4, keep(pro_4) rename(pro_4 = "APR (subj.)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_tc_4, keep(pro_4) rename(pro_4 = "APR + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_s_tc_4, keep(pro_4) rename(pro_4 = "APR (subj.) + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_noint_4, keep(pro_4) rename(pro_4 = "APR - interests") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
, headings("FC (appraised value)" = "{bf:Financial Cost}" "APR" = "{bf:APR}") nooffset legend(order(11 "Forced-commitment" 110 "Choice-commitment") pos(6) rows(1)) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects (std deviations)")
*/

*Beta plots (pooled)
coefplot (fc_admin_p, keep(2.t_producto) rename(2.t_producto = "FC (appraised value)") color(navy) cismooth(color(navy) n(10)) offset(0.09)) /// 
(fc_survey_p, keep(2.t_producto) rename(2.t_producto = "FC (subjective value)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_tc_p, keep(2.t_producto) rename(2.t_producto = "FC + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_s_tc_p, keep(2.t_producto) rename(2.t_producto = "FC (subj.) + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_fa_p, keep(2.t_producto) rename(2.t_producto = "FC (fully adjusted)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_p, keep(2.t_producto) rename(2.t_producto = "APR") color(navy) cismooth(color(navy) n(10)) offset(0.09)) /// 
(apr_survey_p, keep(2.t_producto) rename(2.t_producto = "APR (subj.)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_tc_p, keep(2.t_producto) rename(2.t_producto = "APR + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_s_tc_p, keep(2.t_producto) rename(2.t_producto = "APR (subj.) + travel cost") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(apr_fa_p, keep(2.t_producto) rename(2.t_producto = "APR (fully adjusted)") color(navy)  cismooth(color(navy) n(10))  offset(0.09)) ///
(fc_admin_p, keep(4.t_producto) rename(4.t_producto = "FC (appraised value)") color(maroon) cismooth(color(maroon) n(10)) offset(-0.09)) /// 
(fc_survey_p, keep(4.t_producto) rename(4.t_producto = "FC (subjective value)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(fc_tc_p, keep(4.t_producto) rename(4.t_producto = "FC + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(fc_s_tc_p, keep(4.t_producto) rename(4.t_producto = "FC (subj.) + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(fc_fa_p, keep(4.t_producto) rename(4.t_producto = "FC (fully adjusted)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_p, keep(4.t_producto) rename(4.t_producto = "APR") color(maroon) cismooth(color(maroon) n(10)) offset(-0.09)) /// 
(apr_survey_p, keep(4.t_producto) rename(4.t_producto = "APR (subj.)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_tc_p, keep(4.t_producto) rename(4.t_producto = "APR + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_s_tc_p, keep(4.t_producto) rename(4.t_producto = "APR (subj.) + travel cost") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
(apr_fa_p, keep(4.t_producto) rename(4.t_producto = "APR (fully adjusted)") color(maroon)  cismooth(color(maroon) n(10))  offset(-0.09)) ///
, headings("FC (appraised value)" = "{bf:Financial Cost}" "APR" = "{bf:APR}") nooffset legend(order(11 "Forced-commitment" 121 "Choice-commitment") pos(6) rows(1)) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects (std deviations)")
graph export "$directorio\Figuras\fc_robustness.pdf", replace