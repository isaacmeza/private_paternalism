** RUN R CODE HERE
set more off
graph drop _all
*foreach depvar in des_c  dias_al_desempenyo  ganancia  num_p  sum_porcp_c reincidence {
foreach depvar in des_c   {

	forvalues arm = 2/5 {

		*Load data with heterogeneous predictions & propensities
		import delimited "$directorio/_aux/grf_pro_`arm'_`depvar'.csv", clear
		
		tempfile temp`arm'
		save `temp`arm''
		}
		
		forvalues i = 2/4 {
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
		
		*Heterogeneous effect distributions - SEPARATE
		
		foreach var of varlist pro_2 pro_3 pro_4 pro_5{
			twoway (kdensity tau_hat_oobpredictions if !missing(`var'), lpattern(solid)), ///
			scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Effect") ///
			legend(order(1 "No choice/Fee" 2 "No choice/Promise"	3 "Choice/Fee"	4 "Choice/Promise"))			
			graph export "$directorio\Figuras\he_dist_`depvar'_`var'.pdf", replace
		}
			
		*Variable interaction results
		
	forvalues t = 2/5 {
		if "`depvar'" != "reincidence" {
		
		local vrlist prestamo pr_recup edad visit_number faltas /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time
	
		local vrlistnames loan.amt pr.recovery  age visits lack /// *Continuous covariates
	gender pawn.before fam.asks common.asks saves relay /// *Dummy variables
	rent food medicine electricity gas phone water  ///
	more.high.school stressed pb fb makes.budget tempt low.cost low.time

	
	do "$directorio\DoFiles\plot_te_he.do" ///
			"`depvar'" pro_`t' "`vrlist'" "`vrlistnames'"
	
	*Lists of variables according to its clasification
	local familia fam_pide fam_comun faltas
	local ingreso prestamo low_cost low_time ahorros
	local self_control pb fb hace_presupuesto tentado
	local experiencia pres_antes cta_tanda pr_recup visit_number
	local otros renta comida medicina luz gas telefono agua edad genero masqueprepa estresado_seguido
	
	local familianames fam.asks common.asks lack 
	local ingresonames loan.amt low.cost low.time saves
	local self_controlnames pb fb makes.budget tempt
	local experiencianames pawn.before relay pr.recovery visits
	local otrosnames rent food medicine electricity gas phone water age gender more.high.school stressed
	
	do "$directorio\DoFiles\coeficients.do" ///
			"`depvar'" pro_`t' "`vrlist'" "`vrlistnames'" "`familia'" "`ingreso'" "`self_control'" ///
			"`experiencia'" "`otros'" "`familianames'" "`ingresonames'" "`self_controlnames'" ///
			"`experiencianames'" "`otrosnames'"
		
		}
		
		else {
		
		local vrlist prestamo pr_recup  edad  faltas /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time
	
		local vrlistnames loan.amt pr.recovery  age  lack /// *Continuous covariates
	gender pawn.before fam.asks common.asks saves relay /// *Dummy variables
	rent food medicine electricity gas phone water  ///
	more.high.school stressed pb fb makes.budget tempt low.cost low.time

	
	do "$directorio\DoFiles\plot_te_he.do" ///
			"`depvar'" pro_`t' "`vrlist'" "`vrlistnames'"
	
		}	
	}
}	
		
