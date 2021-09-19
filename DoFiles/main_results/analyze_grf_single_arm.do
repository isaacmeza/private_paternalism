** RUN R CODE : grf.R

*TREATMENT ARM
local arm pro_2

set more off
graph drop _all
foreach depvar in  def_c fc_admin_disc eff_cost_loan {

	*Load data with heterogeneous predictions & propensities (extended)
	import delimited "$directorio/_aux/grf_extended_`arm'_`depvar'.csv", clear
	
		
	*Overlap assumption	
	twoway (kdensity propensity_score if !missing(`arm'), lpattern(solid) lwidth(medthick)) ///
			, ///
		scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Propensity score") ///
		legend(off)			
	graph export "$directorio\Figuras\ps_overlap_`depvar'_`arm'.pdf", replace
		
		
	*Heterogeneous effect distributions
	if strpos("`depvar'","fc")!=0 {
		cap drop esample
		su tau_hat_oobpredictions if `arm'==1 , d
		gen esample = inrange(tau_hat_oobpredictions, `r(p1)', `r(p99)') if `arm'==1
		qui kdensity tau_hat_oobpredictions if esample==1,  nograph 
		local width =  `r(bwidth)'
		}

	else {
		cap drop esample
		gen esample = 1 if `arm'==1
		qui kdensity tau_hat_oobpredictions if esample==1,  nograph 
		local width =  `r(bwidth)'
		}
		
	do "$directorio\DoFiles\main_results\yaxis_kdensity.do" ///
		 "tau_hat_oobpredictions" "`width'" "esample" "uno"
		 
	twoway (hist tau_hat_oobpredictions if esample==1, xline(0, lpattern(dot) lwidth(thick)) yaxis(1) ytitle("Percent", axis(1)) w(`width') percent lcolor(white) fcolor(none) ) ///		
		(kdensity tau_hat_oobpredictions if esample==1, yaxis(2) ylab(${uno}, notick nolab axis(2)) ///
						ytitle(" ", axis(2)) xtitle("Effect")  ///
						lcolor(black) lwidth(thick) lpattern(solid) ///
						legend(off) scheme(s2mono) graphregion(color(white))) 	
	graph export "$directorio\Figuras\he_dist_`depvar'_`arm'.pdf", replace
	
	****************************************************************************
	
	*Load data with heterogeneous predictions & propensities 
	import delimited "$directorio/_aux/grf_`arm'_`depvar'.csv", clear
	
	*Variable interaction results
		

		local vrlist  pr_recup  edad  faltas /// *Continuous covariates
		genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
		masqueprepa estresado_seguido oc pb  hace_presupuesto tentado low_cost low_time ///
		rec_cel
		
		local vrlistnames  pr.recovery  age  income.index /// *Continuous covariates
		gender pawn.before fam.asks common.asks savings rosca /// *Dummy variables
		more.high.school stressed oc pb  makes.budget tempt low.cost low.time ///
		reminder
		
	*Lists of variables according to its clasification
		local familia fam_pide fam_comun 
		local ingreso faltas ahorros
		local self_control pb hace_presupuesto tentado rec_cel
		local experiencia pres_antes cta_tanda pr_recup visit_number
		local otros  edad genero masqueprepa estresado_seguido low_cost low_time
		
			
		do "$directorio\DoFiles\main_results\coeficients_grf.do" ///
			"`depvar'" "`arm'" "`familia'" "`ingreso'" "`self_control'" ///
			"`experiencia'" "`otros'"	
		
	}	
		
