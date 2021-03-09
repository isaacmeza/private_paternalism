/*
OC is defined as 1 for those individuals that have a higher subjective probability of recovery.
This dofile pushes the threshold defining OC : pr_recup-pr_prob> threshold, 
and analyses the effect of the robust definition of OC with FP
*/

use "$directorio/DB/Master.dta", clear


keep if inrange(producto,4,7)
*Frequent voluntary payment        
gen pago_frec_vol_fee=(producto==5) if (producto==4 | producto==5)
gen pago_frec_vol_promise=(producto==7) if (producto==6 | producto==7)
gen pago_frec_vol=inlist(producto,5,7)


*Overconfident
drop OC
gen OC = .
xtile perc_oc = cont_OC, nq(99)

matrix results = J(100, 7, .)

forvalues i = 3/50 {
	qui{
	*Define OC in terms of the percentiles of the distribution for the difference in pr_recup-pr_prob
	replace OC = .
	replace OC = (perc_oc>`i') if (!missing(pr_recup) & !missing(pr_prob))
	
	***Regressions***
	*****************
	
	reg pago_frec_vol_fee OC ${C0} masqueprepa plan_gasto pb ,r 
	local df = e(df_r)	
		
	matrix results[`i',1] = `i'	
	// Beta 
	matrix results[`i',2] = _b[OC]
	// Standard error
	matrix results[`i',3] = _se[OC]
	// P-value
	matrix results[`i',4] = 2*ttail(`df', abs(_b[OC]/_se[OC]))
			
			
	reg pago_frec_vol_promise OC ${C0} masqueprepa plan_gasto pb ,r 
	local df = e(df_r)	
			
	// Beta 
	matrix results[`i',5] = _b[OC]
	// Standard error
	matrix results[`i',6] = _se[OC]
	// P-value
	matrix results[`i',7] = 2*ttail(`df', abs(_b[OC]/_se[OC]))
				
	}	
	}


matrix colnames results =  "k" "beta_f" "se_f" "p_f" "beta_p" "se_p" "p_p"
matlist results
		
		
clear
svmat results, names(col) 


*Graph
twoway (line beta_f k, color(navy) lpattern(solid) lwidth(medthick)) ///
		(line beta_p k, color(red) lpattern(solid) lwidth(medthick)) ///
		, scheme(s2mono) graphregion(color(white))	///
		xtitle("Percentile of (subjective-predicted) prob. dist.") ///
		ytitle("Effect of OC in frequent payment") legend(order(1 "Fee" 2 "Promise"))
graph export "$directorio\Figuras\effect_fp_oc.pdf", replace
