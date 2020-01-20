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
gen fc_te_cf =  tau_hat_oobpr/prestamo*100	
gen fc_te_cf_hi = fc_te_cf + invnorm(0.95)*sqrt(tau_hat_oob_fullvarianceestimate)*100/prestamo
gen fc_te_cf_lo = fc_te_cf - invnorm(0.95)*sqrt(tau_hat_oob_fullvarianceestimate)*100/prestamo

*Histogram of FC treatment effect on the treated
foreach var of varlist fc_te_cf {
	twoway (hist `var' if pro_6==1 | pro_7==1, percent w(10) lcolor(blue) color(blue)) ///
		(hist `var' if pro_8==1 | pro_9==1, percent w(10)lcolor(black) color(none)), ///
		scheme(s2mono) graphregion(color(white)) ///
		legend(order(1 "Fee" 2 "Promise")) xtitle("Estimated regret")
	graph export "$directorio/Figuras/hist_regret_`var'.pdf", replace
	}


gen choose_wrong_fee = .
gen choose_wrong_promise = .
gen quant_wrong_fee = .
gen quant_wrong_promise = .
gen percq_wrong_fee = .
gen percq_wrong_promise = .
gen cwf = .
gen cwp = .
gen qwf = .
gen qwp = .
gen pwf = .
gen pwp = .

gen threshold = _n if _n<=50

*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
foreach var of varlist fc_te_cf {
	forvalues i = 0/200 {
		di "`i'"
		noi {
		*Classify the percentage of wrong decisions
		replace choose_wrong_fee = ((`var'>`i' & pro_6==1) | (`var'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
		su choose_wrong_fee
		replace cwf = `r(mean)'*100 in `=`i'+1'
		*Quantification in %
		replace percq_wrong_fee = .
		replace percq_wrong_fee = abs(`var') if choose_wrong_fee==1
		su percq_wrong_fee
		cap replace pwf = `r(mean)' in `=`i'+1'
		*Quantification in $
		replace quant_wrong_fee = .
		replace quant_wrong_fee = abs(`var')*prestamo/100 if choose_wrong_fee==1
		su quant_wrong_fee
		cap replace qwf = `r(mean)' in `=`i'+1'
		
			*promise
		replace choose_wrong_promise = ((`var'>`i' & pro_8==1) | (`var'<-`i' & pro_9==1)) if !missing(`var') & t_prod==5
		su choose_wrong_promise
		replace cwp = `r(mean)'*100 in `=`i'+1'

		replace percq_wrong_promise = .
		replace percq_wrong_promise = abs(`var') if choose_wrong_promise==1
		su percq_wrong_promise
		cap replace pwp = `r(mean)' in `=`i'+1'
		
		replace quant_wrong_promise = .
		replace quant_wrong_promise = abs(`var')*prestamo/100 if choose_wrong_promise==1
		su quant_wrong_promise
		cap replace qwp = `r(mean)' in `=`i'+1'
		}
		}


	twoway (line cwf threshold, lpattern(solid) lwidth(medthick) lcolor(red)) ///
			(line cwp threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(scatter qwf threshold,  msymbol(x) color(red) yaxis(2)) ///
			(scatter qwp threshold, msymbol(x) color(navy) yaxis(2)) ///
			, legend(order(1 "% mistakes (fee)" 2 "% mistakes (promise)" ///
				3 "quant in $ (fee)" 4 "quant in $ (promise)")) scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ytitle("Percentage 'wrong'",axis(1)) ///
			ytitle("Money (in pesos)",axis(2))  ylabel(0(10)40, axis(1)) 
	graph export "$directorio/Figuras/line_cw_qw_`var'.pdf", replace

	
	twoway (line cwf threshold, lpattern(solid) lwidth(medthick) lcolor(red)) ///
			(line cwp threshold, lpattern(solid) lwidth(medthick) lcolor(navy)) ///
			(scatter pwf threshold,  msymbol(x) color(red) yaxis(2)) ///
			(scatter pwp threshold, msymbol(x) color(navy) yaxis(2)) ///
			, legend(order(1 "% mistakes (fee)" 2 "% mistakes (promise)" ///
				3 "quant in % (fee)" 4 "quant in % (promise)")) scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ytitle("Percentage 'wrong'",axis(1)) ///
			ytitle("% of loan",axis(2))  ylabel(0(10)40, axis(1)) 
	graph export "$directorio/Figuras/line_cw_pw_`var'.pdf", replace
	}

