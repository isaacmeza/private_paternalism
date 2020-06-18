** RUN R CODE : grf.R

set more off
graph drop _all
foreach depvar in des_c  dias_al_desempenyo  num_p  sum_porcp_c ref_c reincidence {

	forvalues arm = 2/9 {

		*Load data with heterogeneous predictions & propensities
		import delimited "$directorio/_aux/grf_pro_`arm'_`depvar'.csv", clear
		
		tempfile temp`arm'
		save `temp`arm''
		}
		
		forvalues i = 2/8 {
			append using `temp`i''
			}
		*Overlap assumption
		
		twoway (kdensity propensity_score if !missing(pro_2), lpattern(solid)) ///
				(kdensity propensity_score if !missing(pro_3), lpattern(dot)) ///
				(kdensity propensity_score if !missing(pro_4), lpattern(dash)) ///				
				(kdensity propensity_score if !missing(pro_5), lpattern(dash_dot)) ///
				, ///
			scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Propensity score") ///
			legend(order(1 "No choice/Fee" 2 "No choice/Promise"	3 "Choice/Fee"	4 "Choice/Promise"))			
		graph export "$directorio\Figuras\ps_overlap_`depvar'.pdf", replace
		
		
		*Heterogeneous effect distributions
		twoway (kdensity tau_hat_oobpredictions if !missing(pro_2), lpattern(solid)) ///
				(kdensity tau_hat_oobpredictions if !missing(pro_3), lpattern(dot)) ///
				(kdensity tau_hat_oobpredictions if !missing(pro_4), lpattern(dash)) ///				
				(kdensity tau_hat_oobpredictions if !missing(pro_5), lpattern(dash_dot)) ///
				, ///
			scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Effect") ///
			legend(order(1 "No choice/Fee" 2 "No choice/Promise"	3 "Choice/Fee"	4 "Choice/Promise"))			
		graph export "$directorio\Figuras\he_dist_`depvar'.pdf", replace

		*Heterogeneous effect decomposition choice arms
		twoway (kdensity tau_hat_oobpredictions if !missing(pro_2), lpattern(solid)) ///
				(kdensity tau_hat_oobpredictions if !missing(pro_6), lpattern(dot)) ///
				(kdensity tau_hat_oobpredictions if !missing(pro_7), lpattern(dash)) ///				
				, ///
			scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Effect") ///
			legend(order(1 "No choice/Fee" 2 "Fee/SQ"	3 "Fee/NSQ"	))			
		graph export "$directorio\Figuras\he_dist_fee_decomp_`depvar'.pdf", replace
		
		twoway (kdensity tau_hat_oobpredictions if !missing(pro_2), lpattern(solid)) ///
				(kdensity tau_hat_oobpredictions if !missing(pro_8), lpattern(dot)) ///
				(kdensity tau_hat_oobpredictions if !missing(pro_9), lpattern(dash)) ///				
				, ///
			scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Effect") ///
			legend(order(1 "No choice/Fee" 2 "Promise/SQ"	3 "Promise/NSQ"	))			
		graph export "$directorio\Figuras\he_dist_promise_decomp_`depvar'.pdf", replace
				
		
		*Heterogeneous effect distributions - SEPARATE
		foreach tarm of varlist pro_2 pro_3 pro_4 pro_5{
			twoway (kdensity tau_hat_oobpredictions if !missing(`tarm'), lpattern(solid)), ///
			scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Effect") ///
			legend(order(1 "No choice/Fee" 2 "No choice/Promise"	3 "Choice/Fee"	4 "Choice/Promise"))			
			graph export "$directorio\Figuras\he_dist_`depvar'_`tarm'.pdf", replace
		}
		
		*Variable interaction results
		
	forvalues t = 2/5 {
		if "`depvar'" != "reincidence" {
		
		local vrlist prestamo pr_recup edad visit_number faltas /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time rec_cel
	
		local vrlistnames loan.amt pr.recovery  age visits lack /// *Continuous covariates
	gender pawn.before fam.asks common.asks saves relay /// *Dummy variables
	rent food medicine electricity gas phone water  ///
	more.high.school stressed pb fb makes.budget tempt low.cost low.time reminder


	do "$directorio\DoFiles\plot_te_he.do" ///
			"`depvar'" pro_`t' "`vrlist'" "`vrlistnames'"
	
	
	*Lists of variables according to its clasification
	local familia fam_pide fam_comun faltas
	local ingreso renta comida medicina luz gas telefono agua ahorros
	local self_control pb fb hace_presupuesto tentado rec_cel
	local experiencia pres_antes cta_tanda pr_recup visit_number
	local otros prestamo edad genero masqueprepa estresado_seguido low_cost low_time
	
	local familianames fam.asks common.asks lack 
	local ingresonames rent food medicine electricity gas phone water  saves
	local self_controlnames pb fb makes.budget tempt reminder
	local experiencianames pawn.before relay pr.recovery visits
	local otrosnames loan.amt age gender more.high.school stressed low.cost low.time
	
	do "$directorio\DoFiles\coeficients.do" ///
			"`depvar'" pro_`t' "`vrlist'" "`vrlistnames'" "`familia'" "`ingreso'" "`self_control'" ///
			"`experiencia'" "`otros'" "`familianames'" "`ingresonames'" "`self_controlnames'" ///
			"`experiencianames'" "`otrosnames'"
		
		}
		
		else {
		
		local vrlist prestamo pr_recup  edad  faltas /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time ///
	rec_cel
	
		local vrlistnames loan.amt pr.recovery  age  lack /// *Continuous covariates
	gender pawn.before fam.asks common.asks saves relay /// *Dummy variables
	rent food medicine electricity gas phone water  ///
	more.high.school stressed pb fb makes.budget tempt low.cost low.time ///
	reminder

	
	do "$directorio\DoFiles\plot_te_he.do" ///
			"`depvar'" pro_`t' "`vrlist'" "`vrlistnames'"
	
		}	
	}
}	
		
