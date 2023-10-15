
*Load data with eff_te predictions (created in te_grf.R)
import delimited "$directorio/_aux/des_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_des tau_des)
tempfile temp_des
save `temp_des'

import delimited "$directorio/_aux/def_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_def tau_def)
tempfile temp_def
save `temp_def'

import delimited "$directorio/_aux/sumporcp_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_sum tau_sum)
tempfile temp_sum
save `temp_sum'

import delimited "$directorio/_aux/eff_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_eff tau_eff)
tempfile temp_eff
save `temp_eff'

import delimited "$directorio/_aux/apr_te_grf.csv", clear
keep prenda tau_hat_oobvarianceestimates tau_hat_oobpredictions
rename (tau_hat_oobvarianceestimates tau_hat_oobpredictions) (var_apr tau_apr)
tempfile temp_apr
save `temp_apr'

*Load data with propensity score (created in choice_prediction.ipynb)
import delimited "$directorio/_aux/prop_choose.csv", clear

merge 1:1 prenda using "$directorio/DB/Master.dta", nogen keep(3)
merge 1:1 prenda using `temp_des', nogen keep(3)
merge 1:1 prenda using `temp_def', nogen keep(3)
merge 1:1 prenda using `temp_sum', nogen keep(3)
merge 1:1 prenda using `temp_eff', nogen keep(3)
merge 1:1 prenda using `temp_apr', nogen keep(3)


twoway (lpoly apr pr_gbc_1 if t_prod==1 & pr_gbc_1<0.8 ) (lpoly apr pr_gbc_1 if t_prod==2 & pr_gbc_1<0.8), ///
ytitle("APR") xtitle("PS") legend(order(1 "Control" 2 "Forced commitment"))
graph export "$directorio\Figuras\ps_te_apr.pdf", replace



twoway (lpoly apr pr_knn_1 if t_prod==1 & pr_knn_1<0.8 ) (lpoly apr pr_knn_1 if t_prod==2 & pr_knn_1<0.8 ), ///
ytitle("APR") xtitle("PS") legend(order(1 "Control" 2 "Forced commitment"))
graph export "$directorio\Figuras\ps_te_apr1.pdf", replace



