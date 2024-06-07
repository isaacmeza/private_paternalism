
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	April. 22, 2022
* Last date of modification: May. 1, 2023
* Modifications: - Improvement of forests and change of definition in main outcomes
				- Extend the graph to full cdf
* Files used:     
		- tot_instr_forest.csv
		- tut_instr_forest.csv
		- Master.dta
* Files created:  

* Purpose: Who makes mistakes? Based on TuT & ToT forests predictions

*******************************************************************************/
*/


********************************************************************************

** RUN R CODE : tot_tut_instr_forest.R

********************************************************************************


*Load data with forest predictions (created in tot_tut_instr_forest.R)

import delimited "$directorio/_aux/tot_apr_instr_forest.csv", clear
tempfile temp_tot
rename inst_hat_oobpredictions inst_hat_1
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_1
save `temp_tot'


import delimited "$directorio/_aux/tut_apr_instr_forest.csv", clear
rename inst_hat_oobpredictions inst_hat_0
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_0
merge 1:1 prenda using `temp_tot', nogen

merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
keep if inlist(t_prod,4)

********************************************************************************
gen tau_sim_1 = . 
gen tau_sim_0 = . 

gen choose_wrong_fee = .
gen choose_wrong_fee_choose = .
gen choose_wrong_fee_nonchoose = .


gen cwf = 0
gen cwf_choose = 0
gen cwf_nonchoose = 0
gen cwf_normal_l = .
gen cwf_normal_h = .
gen cwf_choose_l = .
gen cwf_choose_h = .
gen cwf_nonchoose_l = .
gen cwf_nonchoose_h = .

local k = 1
forvalues i = -100(5)100  {
	gen cwf_normal_l`k' = .
	gen cwf_normal_h`k' = .
	gen cwf_choose_l`k' = .
	gen cwf_choose_h`k' = .	
	gen cwf_nonchoose_l`k' = .
	gen cwf_nonchoose_h`k' = .	

	local k = `k' + 1
	}


local rep_num = 100
forvalues rep = 1/`rep_num' {
	*Draw random effect Y_1-Y_0 from normal distribution with standard error according to Athey
	replace tau_sim_1 = rnormal(inst_hat_1, sqrt(inst_oobvarianceestimates_1))	
	replace tau_sim_0 = rnormal(inst_hat_0, sqrt(inst_oobvarianceestimates_0))	

	*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
	local k = 1
	forvalues i = -100(5)100  {
		qui {
		*Classify the percentage of wrong decisions
		* people who look like person i and chose the no-commitment contract would have been better off had they chosen commitment : (tau_sim_0>`i' & pro_6==1)
		* analogous for (tau_sim_1<`i' & pro_7==1)
		replace choose_wrong_fee = .
		replace choose_wrong_fee = ((tau_sim_0>`=`i'/100' & pro_6==1) | (tau_sim_1<-`=`i'/100' & pro_7==1)) if (!missing(tau_sim_1) | !missing(tau_sim_0)) & t_prod==4
		bootstrap r(mean),  reps(25) level(99): su choose_wrong_fee
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf = cwf + point_estimate[1,1]*100 in `k'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_normal_l`k' =  confidence_int[1,1]*100 in `rep'
			replace cwf_normal_h`k' =  confidence_int[2,1]*100 in `rep'
			*Only consider "choosers"
		replace choose_wrong_fee_choose = .	
		replace choose_wrong_fee_choose = (tau_sim_1<-`=`i'/100' & pro_7==1) if !missing(tau_sim_1) & pro_7==1	
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
		replace choose_wrong_fee_nonchoose = (tau_sim_0>`=`i'/100' & pro_6==1) if !missing(tau_sim_0) & pro_6==1	
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
	if `rep'==1{
		di " "
		_dots 0, title(Replication number) reps(`rep_num')
	}
	_dots `rep' 0
	}	

*Recover the means
foreach var of varlist  cwf cwf_choose cwf_nonchoose {
	replace `var' = `var'/`rep_num'
	}

*Distribution of the CI
local k = 1
forvalues i = -100(5)100  {
	foreach vr in cwf_normal cwf_nonchoose cwf_choose {
		su `vr'_l`k', d
		replace `vr'_l = `r(p5)' in `k'
		replace `vr'_l = 0 if `vr'_l < 0 & !missing(`vr'_l )
		su `vr'_h`k', d
		replace `vr'_h = `r(p95)' in `k'
		replace `vr'_h = 100 if `vr'_h > 100 & !missing(`vr'_h )
	}
	local k = `k' + 1
	}

gen threshold = -100 + (_n-1)*5 if (_n-1)*5<=200
save "$directorio/_aux/choose_wrong_tot_tut.dta", replace

**************************************PLOTS*************************************

use "$directorio/_aux/choose_wrong_tot_tut.dta", clear
keep if inrange(threshold, -50, 50)
	
twoway 	(rarea cwf_normal_l cwf_normal_h threshold, lcolor(navy%5) fcolor(navy) fintensity(50)) ///
			(line cwf threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(scatter cwf threshold, connect(l)  msymbol(x) color(navy) ) ///
			(rarea cwf_nonchoose_l cwf_nonchoose_h threshold, lcolor(dkgreen%5) fcolor(dkgreen%60) fintensity(40)) ///
			(line cwf_nonchoose threshold, lpattern(dash) lwidth(medthick) lcolor(dkgreen%80)) ///
			(scatter cwf_nonchoose threshold, connect(l) msymbol(x) color(dkgreen%80) ) ///	
			(rarea cwf_choose_l cwf_choose_h threshold, lcolor(maroon%5) fcolor(maroon%70) fintensity(40)) ///
			(line cwf_choose threshold, lpattern(dot) lwidth(medthick) lcolor(maroon%70)) ///
			(scatter cwf_choose threshold, connect(l) msymbol(x) color(maroon%70) ) ///				
			, legend(order(3 "All borrowers in choice arm"  ///
				6 "Non-choosers" 9 "Choosers") pos(6) rows(1))  ///
			graphregion(color(white)) xtitle("APR threshold (percentage points)") xlabel(-50(20)50) ///
			ytitle("% of mistakes") ///
			ylabel(0(10)100) xline(0, lcolor(black) lwidth(medthick) lpattern(dash))
graph export "$directorio/Figuras/line_cw_apr_tot_tut.pdf", replace
	
	
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
		xtitle("APR % threshold") xlabel(-50(20)50) xline(0, lcolor(black) lwidth(medthick) lpattern(dash))
graph export "$directorio/Figuras/integral_cw_apr_tot_tut.pdf", replace		
	
