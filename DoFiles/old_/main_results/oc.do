*********************************Take.up****************************************
********************************************************************************

use "$directorio/DB/Master.dta", clear

hist cont_OC, percent scheme(s2mono) graphregion(color(white)) ///
	xtitle("Subjective-Predicted") ytitle("Percent") xline(0,lcolor(navy)) 
graph export "$directorio\Figuras\oc_hist.pdf", replace
	
keep if inrange(producto,4,7)
*Frequent voluntary payment        
gen pago_frec_vol_fee=(producto==5) if (producto==4 | producto==5)
gen pago_frec_vol_promise=(producto==7) if (producto==6 | producto==7)
gen pago_frec_vol=inlist(producto,5,7)

eststo clear
************Regressions****************

eststo: reg pago_frec_vol_promise OC ${C0},r 
su pago_frec_vol_promise if e(sample) 
estadd scalar DepVarMean = `r(mean)'
eststo: reg pago_frec_vol_fee OC ${C0},r 
su pago_frec_vol_fee if e(sample) 
estadd scalar DepVarMean = `r(mean)'

eststo: reg pago_frec_vol_promise OC ${C0} ///
	masqueprepa plan_gasto pb /// *Controls
	,r cluster(suc_x_dia)
su pago_frec_vol_promise if e(sample) 
estadd scalar DepVarMean = `r(mean)'
eststo: reg pago_frec_vol_fee OC ${C0} ///
	masqueprepa plan_gasto pb /// *Controls
	,r cluster(suc_x_dia)
su pago_frec_vol_fee if e(sample) 
estadd scalar DepVarMean = `r(mean)'


************************************HTE*****************************************
********************************************************************************
import delimited "$directorio/_aux/grf_pro_2_fc_admin.csv", clear
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)


************Regressions****************

eststo: reg tau_hat_oobpredictions OC ${C0},r 
su tau_hat_oobpredictions if e(sample) 
estadd scalar DepVarMean = `r(mean)'


eststo: reg tau_hat_oobpredictions OC ${C0} ///
	masqueprepa plan_gasto pb /// *Controls
	,r 
su tau_hat_oobpredictions if e(sample) 
estadd scalar DepVarMean = `r(mean)'



esttab using "$directorio/Tables/reg_results/oc_reg.csv", se r2 ${star} b(a2) ///
		scalars("DepVarMean Dep. Var. Mean") replace 
