** RUN R CODE : grf.R

*TREATMENT ARM
local arm pro_2

set more off
graph drop _all
foreach depvar in def_c fc_admin_disc  {

	*Load data with heterogeneous predictions & propensities
	import delimited "$directorio/_aux/grf_`arm'_`depvar'.csv", clear
	
		
	*Overlap assumption	
	twoway (kdensity propensity_score if !missing(`arm'), lpattern(solid) lwidth(medthick)) ///
			, ///
		scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Propensity score") ///
		legend(off)			
	graph export "$directorio\Figuras\ps_overlap_`depvar'_`arm'.pdf", replace
		
		
	*Heterogeneous effect distributions
	if strpos("`depvar'","fc")!=0 {
		kdensity tau_hat_oobpredictions, generate(pts den) nograph
		su tau_hat_oobpredictions
		twoway (line den pts if ///
			inrange(pts, ` r(mean)'-2*`r(sd)',` r(mean)'+1*`r(sd)') ///
			& !missing(`arm'), lwidth(medthick)) ///
				, ///
			scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Effect") 
		}
	else {
		kdensity tau_hat_oobpredictions, generate(pts den) nograph
		su tau_hat_oobpredictions
		twoway (line den pts if !missing(`arm'), lwidth(medthick)) ///
				, ///
			scheme(s2mono) graphregion(color(white)) ytitle("Density") xtitle("Effect") ///
			legend(off)	
		}	
	graph export "$directorio\Figuras\he_dist_`depvar'_`arm'.pdf", replace
			
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
		local self_control oc pb hace_presupuesto tentado rec_cel
		local experiencia pres_antes cta_tanda pr_recup visit_number
		local otros  edad genero masqueprepa estresado_seguido low_cost low_time
		
			
		do "$directorio\DoFiles\main_results\coeficients_grf.do" ///
			"`depvar'" "`arm'" "`familia'" "`ingreso'" "`self_control'" ///
			"`experiencia'" "`otros'"	
		
	}	
		
