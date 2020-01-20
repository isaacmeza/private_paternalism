*We analyze the relation between the propensity of take-up against treatment effect
* so we can assess wether people who demand the commitment device has more treatment effect



***************************************FEE**************************************
*Load data with heterogeneous predictions for the TE
import delimited "$directorio/_aux/grf_pro_6_des_c.csv", clear
keep if pro_6==1
tempfile temphte
save `temphte', replace	
import delimited "$directorio/_aux/grf_pro_7_des_c.csv", clear
keep if pro_7==1
append using `temphte'
tempfile temphte
save `temphte', replace


*Load data with probability prediction of take-up & merge with HTE
import delimited "$directorio\_aux\pred_pago_frec_vol_fee.csv", clear
merge 1:1 nombrepignorante prenda using `temphte', nogen	
		
*Heterogeneeous effect/Commitment device		
lpoly tau_hat_oobpredictions rf_pred, noscatter msymbol(Oh) ci bw(.1) ///
	scheme(s2mono) graphregion(color(white)) xtitle("Take up predictions") ///
	ytitle("Heterogeneous effect") legend(off) title("") note("")
graph export "$directorio\Figuras\takeup_fee_he.pdf", replace
		


*************************************PROMISE************************************
*Load data with heterogeneous predictions for the TE
import delimited "$directorio/_aux/grf_pro_8_des_c.csv", clear
keep if pro_8==1
tempfile temphte
save `temphte', replace	
import delimited "$directorio/_aux/grf_pro_9_des_c.csv", clear
keep if pro_9==1
append using `temphte'
tempfile temphte
save `temphte', replace


*Load data with probability prediction of take-up & merge with HTE
import delimited "$directorio\_aux\pred_pago_frec_vol_promise.csv", clear
merge 1:1 nombrepignorante prenda using `temphte', nogen	
		
*Heterogeneeous effect/Commitment device		
lpoly tau_hat_oobpredictions rf_pred, noscatter msymbol(Oh) ci bw(.1) ///
	scheme(s2mono) graphregion(color(white)) xtitle("Take up predictions") ///
	ytitle("Heterogeneous effect") legend(off) title("") note("")
graph export "$directorio\Figuras\takeup_promise_he.pdf", replace



**************************************POOLED************************************
*Load data with heterogeneous predictions for the TE
forvalues i = 6/9 {
	import delimited "$directorio/_aux/grf_pro_`i'_des_c.csv", clear
	keep if pro_`i'==1
	tempfile temphte`i'
	save `temphte`i'', replace	
	}
forvalues i = 6/8 {
	append using `temphte`i''
	}
tempfile temphte	
save `temphte', replace


*Load data with probability prediction of take-up & merge with HTE
import delimited "$directorio\_aux\pred_pago_frec_vol.csv", clear
merge 1:1 nombrepignorante prenda using `temphte', nogen	
		
*Heterogeneeous effect/Commitment device		
lpoly tau_hat_oobpredictions rf_pred, noscatter msymbol(Oh) ci bw(.1) ///
	scheme(s2mono) graphregion(color(white)) xtitle("Take up predictions") ///
	ytitle("Heterogeneous effect") legend(off) title("") note("")
graph export "$directorio\Figuras\takeup_he.pdf", replace
