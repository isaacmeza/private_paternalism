/*
Who makes mistakes?
*/

********************************************************************************

** RUN R CODE : fc_te_grf.R

********************************************************************************


*Load data with fc_te predictions (created in fc_te_grf.R)
import delimited "$directorio/_aux/fc_te_grf.csv", clear
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)

*Counterfactuals estimates
	
	*Causal forest on nochoice/fee-vs-control
	*we put the negative of it to 'normalize' it to a positive scale
gen fc_te_cf =  -tau_hat_oobpr/prestamo*100	
*CI - 95%
gen fc_te_cf_h95 = fc_te_cf + invnorm(0.975)*sqrt(tau_hat_oob_fullvarianceestimate)*100/prestamo
gen fc_te_cf_l95 = fc_te_cf - invnorm(0.975)*sqrt(tau_hat_oob_fullvarianceestimate)*100/prestamo
*CI - 90%
gen fc_te_cf_h90 = fc_te_cf + invnorm(0.95)*sqrt(tau_hat_oob_fullvarianceestimate)*100/prestamo
gen fc_te_cf_l90 = fc_te_cf - invnorm(0.95)*sqrt(tau_hat_oob_fullvarianceestimate)*100/prestamo


*Histogram of FC treatment effect on the treated
foreach var of varlist fc_te_cf {
	twoway (hist `var' if pro_6==1 | pro_7==1, percent w(10) lcolor(blue) color(blue)) ///
		(hist `var' if pro_8==1 | pro_9==1, percent w(10)lcolor(black) color(none)), ///
		scheme(s2mono) graphregion(color(white)) ///
		legend(order(1 "Fee" 2 "Promise")) xtitle("Estimated regret")
	graph export "$directorio/Figuras/hist_regret_`var'.pdf", replace
	}

********************************************************************************
gen choose_wrong_fee = .
gen choose_wrong_promise = .
gen quant_wrong_fee = .
gen quant_wrong_promise = .

gen better_forceall = .
gen bfa_h95 = .
gen bfa_l95 = .
gen bfa_h90 = .
gen bfa_l90 = .

gen cwf = .
gen cwf_h95 = .
gen cwf_l95 = .
gen cwf_h90 = .
gen cwf_l90 = .

gen cwp = .
gen cwp_h95 = .
gen cwp_l95 = .
gen cwp_h90 = .
gen cwp_l90 = .

gen qwf = .
gen qwf_h95 = .
gen qwf_l95 = .
gen qwf_h90 = .
gen qwf_l90 = .
gen qwp = .
gen qbfa = . 

gen threshold = _n-1 if _n<=16

*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
foreach var of varlist fc_te_cf {
	forvalues i = 0/200 {
		di "`i'"
		qui {
		*Classify the percentage of wrong decisions
		* (`var'>`i' & pro_6==1) : positive (in the sense of beneficial)
		* treatment effect with fee but choose no fee
		replace choose_wrong_fee = ((`var'>`i' & pro_6==1) | (`var'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
		su choose_wrong_fee
		replace cwf = `r(mean)'*100 in `=`i'+1'
		
		*Quantification in $
		replace quant_wrong_fee = .
		replace quant_wrong_fee = abs(`var')*prestamo/100 if choose_wrong_fee==1
		su quant_wrong_fee
		cap replace qwf = `r(mean)' in `=`i'+1'
		
		*If we were to force everyone to the FEE contract, how many would be
		* benefited from this policy?
		replace choose_wrong_fee = (`var'>`i') if !missing(`var') & t_prod==4
		su choose_wrong_fee
		replace better_forceall = `r(mean)'*100 in `=`i'+1'
		
		*Quantification in $
		replace quant_wrong_fee = .
		replace quant_wrong_fee = abs(`var')*prestamo/100 if choose_wrong_fee==1
		su quant_wrong_fee
		cap replace qbfa = `r(mean)' in `=`i'+1'
		
		*Confidence interval
		foreach ci in 95 90  {
			replace choose_wrong_fee = ((`var'_l`ci'>`i' & pro_6==1) | (`var'_h`ci'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
			su choose_wrong_fee
			replace cwf_l`ci' = `r(mean)'*100 in `=`i'+1'
			
			replace quant_wrong_fee = .
			replace quant_wrong_fee = abs(`var'_l`ci')*prestamo/100 if choose_wrong_fee==1
			su quant_wrong_fee
			cap replace qwf_l`ci' = `r(mean)' in `=`i'+1'
			
			replace choose_wrong_fee = ((`var'_h`ci'>`i' & pro_6==1) | (`var'_l`ci'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
			su choose_wrong_fee
			replace cwf_h`ci' = `r(mean)'*100 in `=`i'+1'	
			
			replace quant_wrong_fee = .
			replace quant_wrong_fee = abs(`var'_h`ci')*prestamo/100 if choose_wrong_fee==1
			su quant_wrong_fee
			cap replace qwf_h`ci' = `r(mean)' in `=`i'+1'
			
			replace choose_wrong_fee = (`var'_l`ci'>`i') if !missing(`var') & t_prod==4
			su choose_wrong_fee
			replace bfa_l`ci' = `r(mean)'*100 in `=`i'+1'
			
			replace choose_wrong_fee = (`var'_h`ci'>`i') if !missing(`var') & t_prod==4
			su choose_wrong_fee
			replace bfa_h`ci' = `r(mean)'*100 in `=`i'+1'

			}		
		
		
			*promise
		replace choose_wrong_promise = ((`var'>`i' & pro_8==1) | (`var'<-`i' & pro_9==1)) if !missing(`var') & t_prod==5
		su choose_wrong_promise
		replace cwp = `r(mean)'*100 in `=`i'+1'
		
		*quantification	
		replace quant_wrong_promise = .
		replace quant_wrong_promise = abs(`var')*prestamo/100 if choose_wrong_promise==1
		su quant_wrong_promise
		cap replace qwp = `r(mean)' in `=`i'+1'
		
		*Confidence interval
		foreach ci in 95 90  {
			replace choose_wrong_promise = ((`var'_l`ci'>`i' & pro_8==1) | (`var'_h`ci'<-`i' & pro_9==1)) if !missing(`var') & t_prod==5
			su choose_wrong_promise
			replace cwp_l`ci' = `r(mean)'*100 in `=`i'+1'
			
			replace choose_wrong_promise = ((`var'_h`ci'>`i' & pro_8==1) | (`var'_l`ci'<-`i' & pro_9==1)) if !missing(`var') & t_prod==5
			su choose_wrong_promise
			replace cwp_h`ci' = `r(mean)'*100 in `=`i'+1'			
			}	
		
		}
		}


	twoway 	(line cwf threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(line cwf_h90 threshold, lpattern(dot) lwidth(medthick) lcolor(navy)) ///
			(line cwf_l90 threshold, lpattern(dot) lwidth(medthick) lcolor(navy)) ///
			(scatter cwf threshold,  msymbol(x) color(navy) ) ///
			(scatter qwf threshold,  msymbol(x) color(red) yaxis(2)) ///
			, legend(order(1 "Fee arm"  ///
				5 "Money (fee)" ))  scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage mistakes", axis(1)) ///
			ytitle("Money (in pesos)",axis(2)) ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_cw_`var'.pdf", replace
	
		twoway 	(line better_forceall threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(scatter better_forceall threshold,  msymbol(x) color(navy) ) ///
			, legend(off) scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage", axis(1)) ///
			ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_better_forceall_`var'.pdf", replace

	
	}

