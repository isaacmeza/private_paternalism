
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 11, 2022
* Last date of modification:   
* Modifications:		
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




foreach var of varlist fc_admin fc_survey fc_tc fc_s_tc apr apr_survey apr_tc apr_s_tc apr_noint {
	* Z-score
	su `var'
	gen std_`var' = (`var'-`r(mean)')/`r(sd)'
	
	*OLS 
	reg std_`var' pro_2 $C0, vce(cluster suc_x_dia)
	estimates store `var'_2
	
	reg std_`var' pro_4 $C0, vce(cluster suc_x_dia)
	estimates store `var'_4	
}

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
, headings("FC (appraised value)" = "{bf:Financial Cost}" "APR" = "{bf:APR}") nooffset legend(order(11 "Forced-commitment" 110 "Choice-commitment")) xline(0, lcolor(gs10))  graphregion(color(white)) xtitle("T. Effects (std deviations)")

graph export "$directorio\Figuras\fc_robustness.pdf", replace