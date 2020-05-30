/*
Who makes mistakes? - Decomposition by a binary variable
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

**********************************Binary variable*******************************

local binary  OC 


********************************************************************************
gen choose_wrong_fee = .
gen choose_wrong_promise = .
gen quant_wrong_fee = .
gen quant_wrong_promise = .

forvalues j=0/1 {
	gen cwf_`j' = .
	gen cwf_h95_`j' = .
	gen cwf_l95_`j' = .
	gen cwf_h90_`j' = .
	gen cwf_l90_`j' = .

	gen cwp_`j' = .
	gen cwp_h95_`j' = .
	gen cwp_l95_`j' = .
	gen cwp_h90_`j' = .
	gen cwp_l90_`j' = .

	gen qwf_`j' = .
	gen qwp_`j' = .
	}

gen threshold = _n-1 if _n<=21

*Computation of people that makes mistakes in the choice arm according to estimated counterfactual
foreach var of varlist fc_te_cf {
	forvalues i = 0/200 {
		di "`i'"
		qui {
		*Classify the percentage of wrong decisions
		* (`var'>`i' & pro_6==1) : positive (in the sense of beneficial)
		* treatment effect with fee but choose no fee
		replace choose_wrong_fee = ((`var'>`i' & pro_6==1) | (`var'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
		su choose_wrong_fee if `binary'==1
		replace cwf_1 = `r(mean)'*100 in `=`i'+1'
		su choose_wrong_fee if `binary'==0
		replace cwf_0 = `r(mean)'*100 in `=`i'+1'
		
		*Quantification in $
		replace quant_wrong_fee = .
		replace quant_wrong_fee = abs(`var')*prestamo/100 if choose_wrong_fee==1
		su quant_wrong_fee if `binary'==1
		cap replace qwf_1 = `r(mean)' in `=`i'+1'
		su quant_wrong_fee if `binary'==0
		cap replace qwf_0 = `r(mean)' in `=`i'+1'
		
		
		*Confidence interval
		foreach ci in 95 90  {
			replace choose_wrong_fee = ((`var'_l`ci'>`i' & pro_6==1) | (`var'_h`ci'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
			su choose_wrong_fee if `binary'==1
			replace cwf_l`ci'_1 = `r(mean)'*100 in `=`i'+1'
			su choose_wrong_fee if `binary'==0
			replace cwf_l`ci'_0 = `r(mean)'*100 in `=`i'+1'
			
			replace choose_wrong_fee = ((`var'_h`ci'>`i' & pro_6==1) | (`var'_l`ci'<-`i' & pro_7==1)) if !missing(`var') & t_prod==4
			su choose_wrong_fee if `binary'==1
			replace cwf_h`ci'_1 = `r(mean)'*100 in `=`i'+1'
			su choose_wrong_fee if `binary'==0
			replace cwf_h`ci'_0 = `r(mean)'*100 in `=`i'+1'			
			}		
		
		
			*promise
		replace choose_wrong_promise = ((`var'>`i' & pro_8==1) | (`var'<-`i' & pro_9==1)) if !missing(`var') & t_prod==5
		su choose_wrong_promise if `binary'==1
		replace cwp_1 = `r(mean)'*100 in `=`i'+1'
		su choose_wrong_promise if `binary'==0
		replace cwp_0 = `r(mean)'*100 in `=`i'+1'		
		
		*quantification	
		replace quant_wrong_promise = .
		replace quant_wrong_promise = abs(`var')*prestamo/100 if choose_wrong_promise==1
		su quant_wrong_promise if `binary'==1
		cap replace qwp_1 = `r(mean)' in `=`i'+1'
		su quant_wrong_promise if `binary'==0
		cap replace qwp_0 = `r(mean)' in `=`i'+1'		
		
		*Confidence interval
		foreach ci in 95 90  {
			replace choose_wrong_promise = ((`var'_l`ci'>`i' & pro_8==1) | (`var'_h`ci'<-`i' & pro_9==1)) if !missing(`var') & t_prod==5
			su choose_wrong_promise if `binary'==1
			replace cwp_l`ci'_1 = `r(mean)'*100 in `=`i'+1'
			su choose_wrong_promise if `binary'==0
			replace cwp_l`ci'_0 = `r(mean)'*100 in `=`i'+1'			
			
			replace choose_wrong_promise = ((`var'_h`ci'>`i' & pro_8==1) | (`var'_l`ci'<-`i' & pro_9==1)) if !missing(`var') & t_prod==5
			su choose_wrong_promise if `binary'==1
			replace cwp_h`ci'_1 = `r(mean)'*100 in `=`i'+1'
			su choose_wrong_promise if `binary'==0
			replace cwp_h`ci'_0 = `r(mean)'*100 in `=`i'+1'			
			}	
		
		}
		}


	twoway 	(line cwf_1 threshold, lpattern(dash) lwidth(medthick) lcolor(red)) ///
			(line cwf_h95_1 threshold, lpattern(dot) lwidth(medthick) lcolor(red)) ///
			(line cwf_l95_1 threshold, lpattern(dot) lwidth(medthick) lcolor(red)) ///
			(line cwf_0 threshold, lpattern(dash) lwidth(medthick) lcolor(navy)) ///
			(line cwf_h95_0 threshold, lpattern(dot) lwidth(medthick) lcolor(navy)) ///
			(line cwf_l95_0 threshold, lpattern(dot) lwidth(medthick) lcolor(navy)) ///
			(scatter cwf_1 threshold,  msymbol(x) color(red) ) ///
			(scatter cwf_0 threshold, msymbol(x) color(navy) ) ///
			(scatter qwf_1 threshold,  msymbol(x) color(red) yaxis(2)) ///
			(scatter qwf_0 threshold, msymbol(x) color(navy) yaxis(2)) ///
			, legend(order(1 "`binary'" 4 "no `binary'" ///
				9 "Money (`binary')" 10 "Money (no `binary')"))  scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage mistake", axis(1)) ///
			ytitle("Money (in pesos)",axis(2)) ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_cw_`var'_`binary'_fee.pdf", replace
	
	
	twoway 	(line cwp_1 threshold, lpattern(dash) lwidth(medthick) lcolor(red)) ///
			(line cwp_h95_1 threshold, lpattern(dot) lwidth(medthick) lcolor(red)) ///
			(line cwp_l95_1 threshold, lpattern(dot) lwidth(medthick) lcolor(red)) ///
			(line cwp_0 threshold, lpattern(dash) lwidth(medthick) lcolor(navy)) ///
			(line cwp_h95_0 threshold, lpattern(dot) lwidth(medthick) lcolor(navy)) ///
			(line cwp_l95_0 threshold, lpattern(dot) lwidth(medthick) lcolor(navy)) ///
			(scatter cwp_1 threshold,  msymbol(x) color(red) ) ///
			(scatter cwp_0 threshold, msymbol(x) color(navy) ) ///
			(scatter qwp_1 threshold,  msymbol(x) color(red) yaxis(2)) ///
			(scatter qwp_0 threshold, msymbol(x) color(navy) yaxis(2)) ///
			, legend(order(1 "`binary'" 4 "no `binary'" ///
				9 "Money (`binary')" 10 "Money (no `binary')"))  scheme(s2mono) ///
			graphregion(color(white)) xtitle("Threshold (as % of loan)") ///
			ytitle("Percentage mistake", axis(1)) ///
			ytitle("Money (in pesos)",axis(2)) ylabel(0(10)100, axis(1)) 
	graph export "$directorio/Figuras/line_cw_`var'_`binary'_promise.pdf", replace	
		
	}

