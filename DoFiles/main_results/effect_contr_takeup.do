/*
Effect in default for different propensity of take up predicted (using a RF)
probabilities

Author : Isaac Meza
*/


********************************************************************************

** RUN R CODE : pfv_pred_hte.R

********************************************************************************


*Effect of not recovery for the nochoice/fee arm had they were given choice
* (created in pfv_pred_hte.R)
import delimited "$directorio/_aux/pred_pro_2_pago_frec_vol_fee_def_c.csv", clear asdouble
destring tau_hat_oobpredictions, replace force
keep if insample==0
keep nombre prenda tau_hat_oobpredictions rf_pred
merge 1:1 prenda using "$directorio/DB/Master.dta" 


*Generation of categories for different threshold take-up predicted probabilities
xtile perc_rf_pred = rf_pred, nq(100)

su rf_pred if inrange(perc_rf_pred,0,10)
local tr1 = `r(max)'
su rf_pred if inrange(perc_rf_pred,0,20)
local tr2 = `r(max)'
su rf_pred if inrange(perc_rf_pred,0,30)
local tr3 = `r(max)'

*Binscatter output
qui binscatter tau_hat_oobpredictions rf_pred, nq(100) /// 
	savedata("$directorio\_aux\binscatter_effect_pr") replace
	
insheet using "$directorio\_aux\binscatter_effect_pr.csv", clear

su rf_pred
local maxrange = `r(max)'

*Compute linear fits
forvalues i=1/3 {
	reg tau_hat_oobpredictions rf_pred if rf_pred>=`tr`i''
	local beta`i' = _b[rf_pred]
	local alfa`i' = _b[_cons]
	}

twoway (scatter tau_hat_oobpredictions rf_pred, mcolor(navy) lcolor(maroon)) ///
(function `beta1'*x+`alfa1', ///
	range(`tr1' `maxrange') lcolor(maroon)) ///
(function `beta2'*x+`alfa2', ///
	range(`tr2' `maxrange') lcolor(maroon)) ///
(function `beta3'*x+`alfa3', ///
	range(`tr3' `maxrange') lcolor(maroon)), ///	
		graphregion(fcolor(white)) ///
		xline(`tr1', lpattern(dash) lcolor(gs8)) ///
		xline(`tr2', lpattern(dash) lcolor(gs8)) ///
		xline(`tr3', lpattern(dash) lcolor(gs8)) ///
		legend(off order()) scheme(s2mono) graphregion(color(white)) ///
		xtitle("Predicted probability") ytitle("HTE")
graph export "$directorio\Figuras\takeuppr_def.pdf", replace
			
		
