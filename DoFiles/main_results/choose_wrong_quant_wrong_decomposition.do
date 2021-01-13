/*
Who makes mistakes? - Decomposition by a binary variable
*/

********************************************************************************

** RUN R CODE : fc_te_grf.R

********************************************************************************


*Load data with fc_te predictions (created in fc_te_grf.R)
import delimited "$directorio/_aux/fc_te_grf.csv", clear
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)

*drop observations with high variance
su tau_hat_oobvarianceestimates, d
drop if tau_hat_oobvarianceestimates>`r(p99)'

**********************************Binary variable*******************************

local binary  OC 


********************************************************************************
gen choose_wrong_fee = .
gen quant_wrong_fee = .
gen tau_sim = .

forvalues j=0/1 {
	gen cwf_`j' = 0

	gen cwf_normal_l_`j' = 0
	gen cwf_normal_h_`j' = 0
	
	forvalues i = 0/16 {
		gen cwf_normal_l_`j'`i' = .
		gen cwf_normal_h_`j'`i' = .
		}
	
	gen qwf_`j' = 0

	}

gen threshold = _n-1 if _n<=16

local rep_num = 1000
forvalues rep = 1/`rep_num' {
di "`rep'"
*Draw random effect from normal distribution with standard error according to Athey
replace tau_sim = rnormal(-tau_hat_oobpredictions, sqrt(tau_hat_oob_fullvarianceestimate))/prestamo*100	
*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
foreach var of varlist tau_sim {
	forvalues i = 0/16 {
		qui {
		*Classify the percentage of wrong decisions
		* (`var'>`i' & pro_6==1) : positive (in the sense of beneficial)
		* treatment effect with fee but choose no fee
		replace choose_wrong_fee = ((`var'>`i' & pro_6==1) | (`var'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
		bootstrap r(mean),  reps(50) level(95): su choose_wrong_fee if `binary'==1
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf_1 = cwf_1 + point_estimate[1,1]*100 in `=`i'+1'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_normal_l_1`i' =  confidence_int[1,1]*100 in `rep'
			replace cwf_normal_h_1`i' =  confidence_int[2,1]*100 in `rep'
			
		bootstrap r(mean),  reps(50) level(95): su choose_wrong_fee if `binary'==0
		estat bootstrap, all
		mat point_estimate = e(b)
		replace cwf_0 = cwf_0 + point_estimate[1,1]*100 in `=`i'+1'
		*Confidence interval
			mat confidence_int = e(ci_normal) 
			replace cwf_normal_l_0`i' =  confidence_int[1,1]*100 in `rep'
			replace cwf_normal_h_0`i' =  confidence_int[2,1]*100 in `rep'
				
		
		
		*Quantification in $
		replace quant_wrong_fee = .
		replace quant_wrong_fee = abs(`var')*prestamo/100 if choose_wrong_fee==1
		su quant_wrong_fee if `binary'==1
		cap replace qwf_1 = qwf_1 + `r(mean)' in `=`i'+1'
		su quant_wrong_fee if `binary'==0
		cap replace qwf_0 = qwf_0 + `r(mean)' in `=`i'+1'	
		
		}
		}
	}
	}

*Recover the means
foreach var of varlist  cwf_1 cwf_0 qwf_1 qwf_0  {
	replace `var' = `var'/`rep_num'
	}
	
	
*Distribution of the CI
forvalues i = 0/16 {
	forvalues j = 0/1 {
		su cwf_normal_l_`j'`i', d
		replace cwf_normal_l_`j' = `r(p5)' in `=`i'+1'
		su cwf_normal_h_`j'`i', d
		replace cwf_normal_h_`j' = `r(p95)' in `=`i'+1'
		}
	}
	
	
	twoway 	(line cwf_1 threshold, lpattern(dash) lwidth(medthick) lcolor(red)) ///
			(line cwf_normal_l_1 threshold, lpattern(dot) lwidth(medthick) lcolor(red)) ///	
			(line cwf_normal_h_1 threshold, lpattern(dot) lwidth(medthick) lcolor(red)) ///	
			(line cwf_0 threshold, lpattern(dash) lwidth(medthick) lcolor(navy)) ///
			(line cwf_normal_l_0 threshold, lpattern(dot) lwidth(medthick) lcolor(navy)) ///	
			(line cwf_normal_h_0 threshold, lpattern(dot) lwidth(medthick) lcolor(navy)) ///				
			(scatter cwf_1 threshold,  msymbol(x) color(red) ) ///
			(scatter cwf_0 threshold, msymbol(x) color(navy) ) ///
			(scatter qwf_1 threshold,  msymbol(x) color(red) yaxis(2)) ///
			(scatter qwf_0 threshold, msymbol(x) color(navy) yaxis(2)) ///
			, legend(order(1 "`binary'" 4 "no `binary'" ///
				9 "Money (`binary')" 10 "Money (no `binary')"))  scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage mistake", axis(1)) ///
			ytitle("Money (in pesos)",axis(2)) ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_cw_fc_te_cf_`binary'_fee.pdf", replace
		
	

