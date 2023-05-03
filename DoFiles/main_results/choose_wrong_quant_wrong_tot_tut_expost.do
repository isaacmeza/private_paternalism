
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	May. 1, 2023
* Last date of modification: May. 1, 2023
* Modifications:
* Files used:     
		- apr_te_grf.csv
		- Master.dta
* Files created:  

* Purpose: Who makes mistakes? Based on TuT & ToT forests predictions. Ex-post definition of mistake

*******************************************************************************/
*/


********************************************************************************

** RUN R CODE : te_grf.R

********************************************************************************


*Load data with forest predictions (created in te_grf.R)

import delimited "$directorio/_aux/eff_te_grf.csv", clear
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
keep if t_prod==4	


********************************************************************************
gen Y = eff
gen Y_sim_1 = . 
gen Y_sim_0 = . 

gen choose_wrong_fee_choose = .
gen choose_wrong_fee_nonchoose = .

gen cwf_choose = 0
gen cwf_nonchoose = 0

gen cwf_choose_l = .
gen cwf_choose_h = .
gen cwf_nonchoose_l = .
gen cwf_nonchoose_h = .

local k = 1
forvalues i = -100(5)100 {
	gen cwf_choose_l`k' = .
	gen cwf_choose_h`k' = .	
	gen cwf_nonchoose_l`k' = .
	gen cwf_nonchoose_h`k' = .	

	local k = `k' + 1
	}

	
local rep_num = 100
forvalues rep = 1/`rep_num' {
	di "`rep'"
	*Draw random counterfactual Y_1 or Y_0 from RF
	replace Y_sim_1 = rnormal(pr_mu1predictions, sqrt(pr_mu1varianceestimates))	
	replace Y_sim_0 = rnormal(pr_mu0predictions, sqrt(pr_mu0varianceestimates))	
	
*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
	local k = 1
	forvalues i = -100(5)100 {
		qui {
		*Classify the percentage of wrong decisions
		* people who look like person i and chose the no-commitment contract would have been better off had they chosen commitment : (Y_sim_1-Y>`i' & pro_6==1)
		* analogous for (Y-Y_sim_0<`i' & pro_7==1)

			*Only consider "choosers"
		replace choose_wrong_fee_choose = .	
		replace choose_wrong_fee_choose = (Y-Y_sim_0<-`=`i'/100' & pro_7==1) if pro_7==1	
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee_choose
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf_choose = cwf_choose + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_choose_l`k' =  confidence_int[1,1]*100 in `rep'
			replace cwf_choose_h`k' =  confidence_int[2,1]*100 in `rep'		
			*Only consider "non-choosers"
		replace choose_wrong_fee_nonchoose = .	
		replace choose_wrong_fee_nonchoose = (Y_sim_1-Y>`=`i'/100' & pro_6==1) if pro_6==1	
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee_nonchoose
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf_nonchoose = cwf_nonchoose + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_nonchoose_l`k' =  confidence_int[1,1]*100 in `rep'
			replace cwf_nonchoose_h`k' =  confidence_int[2,1]*100 in `rep'

		local k = `k' + 1
		}
		}

	}	

*Recover the means
foreach var of varlist  cwf_choose cwf_nonchoose {
	replace `var' = `var'/`rep_num'
	}

*Distribution of the CI
local k = 1
forvalues i = -100(5)100 {
	foreach vr in cwf_nonchoose cwf_choose {
		su `vr'_l`k', d
		replace `vr'_l = `r(p5)' in `k'
		replace `vr'_l = 0 if `vr'_l < 0 & !missing(`vr'_l )
		su `vr'_h`k', d
		replace `vr'_h = `r(p95)' in `k'
		replace `vr'_h = 100 if `vr'_h > 100 & !missing(`vr'_h )
	}
	local k = `k' + 1
	}

gen threshold = (_n-21)*5 if (_n-1)*5<=200
save "$directorio/_aux/choose_wrong_tot_tut_expost.dta", replace

**************************************PLOTS*************************************

use "$directorio/_aux/choose_wrong_tot_tut_expost.dta", clear
	
	twoway 	(rarea cwf_nonchoose_l cwf_nonchoose_h threshold, lcolor(dkgreen%5) fcolor(dkgreen%60) fintensity(40)) ///
			(line cwf_nonchoose threshold, lpattern(solid) lwidth(medthick) lcolor(dkgreen%80)) ///
			(scatter cwf_nonchoose threshold, connect(l) msymbol(x) color(dkgreen%80) ) ///	
			(rarea cwf_choose_l cwf_choose_h threshold, lcolor(maroon%5) fcolor(maroon%70) fintensity(40)) ///
			(line cwf_choose threshold, lpattern(solid) lwidth(medthick) lcolor(maroon%70)) ///
			(scatter cwf_choose threshold, connect(l) msymbol(x) color(maroon%70) ) ///				
			, legend(order(3 "Non-choosers" 6 "Choosers") pos(6) rows(1))  ///
			graphregion(color(white)) xtitle("APR threshold") ///
			ytitle("% of relevant group making mistakes") ///
			ylabel(0(10)100) xline(0, lcolor(black) lwidth(medthick))
	graph export "$directorio/Figuras/line_cw_apr_tot_tut_expost.pdf", replace
	
*-------------------------------------------------------------------------------

gen neg_cwf_nonchoose = 100-cwf_nonchoose if threshold<0
gen neg_cwf_choose = 100-cwf_choose if threshold<0
gen neg_threshold = -threshold if threshold<0

*Integral under the curve of loses
integ cwf_nonchoose threshold if threshold>=0, gen(i_pcwf0)
integ cwf_choose threshold if threshold>=0, gen(i_pcwf1)

*Integral above the curve of gains
integ neg_cwf_nonchoose neg_threshold if threshold<0, gen(i_ncwf0)
integ neg_cwf_choose neg_threshold if threshold<0, gen(i_ncwf1)


egen i_cwf1 = rowtotal(i_pcwf1 i_ncwf1)
egen i_cwf0 = rowtotal(i_pcwf0 i_ncwf0)

*Integral graph
twoway (line i_cwf1 threshold, lwidth(medthick)) ///
		(line i_cwf0 threshold, lwidth(medthick)) ///
		, legend(order(1 "Choosers" 2 "Non-choosers") pos(6) rows(1)) ///
		xtitle("APR threshold") xline(0, lcolor(black) lwidth(medthick) lpattern(dash))
graph export "$directorio/Figuras/integral_cw_apr_tot_tut_expost.pdf", replace		
		
