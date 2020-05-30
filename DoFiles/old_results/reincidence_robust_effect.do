*Robustness check (reincidence)


*ADMIN DATA
use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta", clear

cap drop reincidence*

*Aux Dummies 
tab dow, gen(dummy_dow)
tab suc, gen(dummy_suc)

duplicates drop NombrePignorante fecha_inicial, force
sort NombrePignorante fecha_inicial

*Dummy indicating if customer returned after first visit (WHEN FIRST TREATED)
bysort NombrePignorante: gen first_visit = fecha_inicial[1]

cap drop aux_reincidence 
gen aux_reincidence = .

*Regressions at the 'customer' level (first obs)	
bysort NombrePignorante fecha_inicial : gen obs=_n

*Matrix to store results
matrix reincidence = J(120, 12, .)

forvalues i = 1/120 {
	replace aux_reincidence = (fecha_inicial >	first_visit + `i')		
	cap drop reincidence
	bysort NombrePignorante : egen reincidence = max(aux_reincidence)
	
	qui reg reincidence i.prod prestamo dummy* if obs==1 , r cluster(suc_x_dia)
	local df = e(df_r)	
	local k = 1
	forvalues j = 2/7 {
		// Beta (event study coefficient)
		matrix reincidence[`i',`k'] = _b[`j'.producto]
		// Half length CI
		matrix reincidence[`i',`k'+1] = invttail(`df',0.025)*_se[`j'.producto]	
		local k = `k' + 2
		}
	}	
matrix colnames reincidence = "beta_p2" "ci_p2" "beta_p3" "ci_p3" "beta_p4" "ci_p4" "beta_p5" "ci_p5" "beta_p6" "ci_p6" "beta_p7" "ci_p7"

***************************

clear
svmat reincidence, names(col) 

gen zero=0
gen days=_n


*Generate CI (95%)	
forvalues j = 2/7 {	
	gen hi_p`j' = beta_p`j' + ci_p`j'
	gen lo_p`j' = beta_p`j' - ci_p`j'
	
	twoway rarea hi_p`j' lo_p`j' days, color(gs10)  || line beta_p`i' days, lwidth(thick) lpattern(solid) lcolor(black) || line zero days , lpattern(solid) lcolor(navy) ///
		, scheme(s2mono) graphregion(color(white)) xlabel(0(30)120) ///
		xtitle("Days to learn") ytitle("Reincidence effect") legend(off) xline(30 60 90, lpattern(dot))  ///
		name(p`i', replace)
	graph export "$directorio\Figuras\reincidence_robust_curve_p`i'.pdf", replace
	
	}
	
graph combine p2 p3 p4 p5 p6 p7, scheme(s2mono) graphregion(color(white)) xcommon
graph export "$directorio\Figuras\reincidence_robust_curve.pdf", replace
		
	


