/*
Reincidence treatment effect
*/


// GRAPH FORMATTING
// For graphs:
local labsize medlarge
local bigger_labsize large
local ylabel_options labsize(`labsize') angle(horizontal)
local xlabel_options nogrid notick labsize(`labsize')
local xtitle_options size(`labsize') margin(top)
local title_options size(`bigger_labsize') margin(bottom) color(black)
local manual_axis lwidth(thin) lcolor(black) lpattern(solid)
local plotregion plotregion(margin(sides) fcolor(white) lstyle(none) lcolor(white)) 
local graphregion graphregion(fcolor(white) lstyle(none) lcolor(white)) 
local T_line_options lwidth(thin) lcolor(gray) lpattern(dash)
// To show significance: hollow gray (gs7) will be insignificant from 0,
//  filled-in gray significant at 10%
//  filled-in black significant at 5%
local estimate_options_0  mcolor(gs9)  msymbol(Oh) msize(large)
local estimate_options_90 mcolor(gs7)   msymbol(O)  msize(large)
local estimate_options_95 mcolor(black) msymbol(O)  msize(large)
local rcap_options_0  lcolor(gs10)   lwidth(thin)
local rcap_options_90 lcolor(gs7)   lwidth(thin)
local rcap_options_95 lcolor(black) lwidth(thin)
********************************************************************************


set more off
				
eststo clear
matrix results = J(13, 4, .) // empty matrix for results
	//  4 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) pvalue
	
	local row = 1	
	local nu = 1
	
foreach arm in pro_2 pro_3 {
	*ADMIN DATA
	import delimited "$directorio/_aux/grf_`arm'_fc_admin_disc.csv", clear
	keep prenda tau_hat_oobpredictions
	tempfile temp_hte
	save `temp_hte'

	use "$directorio/DB/Master.dta", clear
	merge 1:1 prenda using `temp_hte', nogen


	*Variable creation
	su tau_hat_oobpredictions, d
	gen above_med_effect = (tau_hat_oobpredictions<=`r(p50)')

	********************************************************************************
	***********************************Reincidence**********************************
	********************************************************************************
	
		
		*Regressions at the 'customer' level
		preserve
		collapse reincidence prestamo $C1  `arm' ///
			, by(NombrePignorante fecha_inicial)

		*Analyze reincidence for the FIRST treatment arm
		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		eststo: reg reincidence `arm' ${C1} , r 
		su reincidence if e(sample) & `arm'==0
		estadd scalar ContrMean = `r(mean)'
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'
		// Beta 
		matrix results[`row',2] = _b[`arm']
		// Standard error
		matrix results[`row',3] = _se[`arm']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		local row = `row' + 1
		local nu = `nu' + 1
		restore
		
		if "`arm'"=="pro_2" {
		*Reincidence definition when first piece NOT recovered
		preserve
		collapse reincidence_fnr prestamo $C1  `arm' ///
			, by(NombrePignorante fecha_inicial)

		*Analyze reincidence for the FIRST treatment arm
		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		eststo: reg reincidence_fnr `arm' ${C1} , r 
		su reincidence_fnr if e(sample) & `arm'==0
		estadd scalar ContrMean = `r(mean)'
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'
		// Beta 
		matrix results[`row',2] = _b[`arm']
		// Standard error
		matrix results[`row',3] = _se[`arm']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		local row = `row' + 1
		local nu = `nu' + 1
		restore
		}
		
		preserve
		*Subsample of people who recovers its first pawn
		keep if prenda==first_prenda  & des_c==1
		collapse reincidence prestamo $C1  `arm' ///
			if prenda, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		eststo: reg reincidence `arm' ${C1} , r 
		su reincidence if e(sample) & `arm'==0
		estadd scalar ContrMean = `r(mean)' 
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'
		// Beta 
		matrix results[`row',2] = _b[`arm']
		// Standard error
		matrix results[`row',3] = _se[`arm']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		local row = `row' + 1
		local nu = `nu' + 1
		restore
		
		preserve
		*Subsample of people who recovers its first pawn
		keep if prenda==first_prenda  & above_med_effect==1
		collapse reincidence prestamo $C1  `arm' ///
			if prenda, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		eststo: reg reincidence `arm' ${C1} , r 
		su reincidence if e(sample) & `arm'==0
		estadd scalar ContrMean = `r(mean)' 
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'
		// Beta 
		matrix results[`row',2] = _b[`arm']
		// Standard error
		matrix results[`row',3] = _se[`arm']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		local row = `row' + 1
		local nu = `nu' + 2
		restore	
		
	}
	
*ADMIN DATA
use "$directorio/DB/Master.dta", clear	
	
foreach arm of varlist pro_4 pro_5 {

	if "`arm'"=="pro_4" {
		local cbr = 2
		local nsq = 5
		local arm_dec_sq pro_6
		local arm_dec_nsq pro_7
		}
	else {
		local cbr = 3
		local nsq = 7
		local arm_dec_sq pro_8
		local arm_dec_nsq pro_9
		}

		*Regressions at the 'customer' level
		preserve
		collapse reincidence prestamo $C1  `arm' ///
			, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		eststo: reg reincidence `arm' ${C1} , r  
		su reincidence if e(sample) & `arm'==0
		estadd scalar ContrMean = `r(mean)' 
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'
		// Beta 
		matrix results[`row',2] = _b[`arm']
		// Standard error
		matrix results[`row',3] = _se[`arm']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		local row = `row' + 1
		local nu = `nu' + 1	
		restore
		
		
		preserve
		collapse reincidence prestamo $C1  `arm_dec_sq' ///
			, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		eststo: reg reincidence `arm_dec_sq' ${C1} , r  
		su reincidence if e(sample) & `arm_dec_sq'==0
		estadd scalar ContrMean = `r(mean)' 		
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'-0.1
		// Beta 
		matrix results[`row',2] = _b[`arm_dec_sq']
		// Standard error
		matrix results[`row',3] = _se[`arm_dec_sq']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`arm_dec_sq']/_se[`arm_dec_sq']))
		local row = `row' + 1	
		restore
		
		preserve
		collapse reincidence prestamo $C1  `arm_dec_nsq' ///
			, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		eststo: reg reincidence `arm_dec_nsq' ${C1} , r
		su reincidence if e(sample) & `arm_dec_nsq'==0
		estadd scalar ContrMean = `r(mean)' 		
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'+0.1
		// Beta 
		matrix results[`row',2] = _b[`arm_dec_nsq']
		// Standard error
		matrix results[`row',3] = _se[`arm_dec_nsq']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`arm_dec_nsq']/_se[`arm_dec_nsq']))
			
		local row = `row' + 1
		restore
		local nu = `nu' + 2
		
		}
	
matrix colnames results = "k" "beta" "se" "p"
matlist results
		
clear
svmat results, names(col) 


// Confidence intervals (95%)
local alpha = .05 // for 95% confidence intervals
gen rcap_lo = beta - invnorm(`=`alpha'/2')*se
gen rcap_hi = beta + invnorm(`=`alpha'/2')*se

// GRAPH
gen ord=_n

#delimit ;
graph twoway 
			(scatter beta k if p<0.05 & mod(k, 1) == 0 ,           `estimate_options_95') 
			(scatter beta k if p>=0.05 & p<0.10 & mod(k, 1) == 0 , `estimate_options_90') 
			(scatter beta k if p>=0.10 & mod(k, 1) == 0,          `estimate_options_0' )
			(scatter beta k if p<0.05 & inlist(ord,9,12),          mcolor(black) msymbol(T)  msize(medlarge)) 
			(scatter beta k if p>=0.05 & inlist(ord,9,12), mcolor(gs7)   msymbol(T)  msize(medlarge)) 
			(scatter beta k if p>=0.10 & inlist(ord,9,12),          mcolor(gs10)   msymbol(Th)  msize(medlarge))
			(scatter beta k if p<0.05  & inlist(ord,10,13),          mcolor(black) msymbol(S)  msize(medlarge)) 
			(scatter beta k if p>=0.05 & p<0.10 & inlist(ord,10,13), mcolor(gs7)   msymbol(S)  msize(medlarge)) 
			(scatter beta k if p>=0.10 & inlist(ord,10,13),          mcolor(gs10)   msymbol(Sh)  msize(medlarge))			
			(rcap rcap_hi rcap_lo k if p<0.05,           `rcap_options_95')
			(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10, `rcap_options_90')
			(rcap rcap_hi rcap_lo k if p>=0.10,          `rcap_options_0' )		
			, 
			title(" ", `title_options')
			yline(0, `manual_axis')
			xtitle("", `xtitle_options')
			xscale(range(`min_xaxis' `max_xaxis'))
			xscale(noline) /* because manual axis at 0 with yline above) */
			`plotregion' `graphregion'  
			legend(order(5 "SQ" 7 "NSQ") rows(1))
			xline(5, lpattern(dot) lwidth(thick) lcolor(black))
			xline(9, lpattern(dot) lwidth(thick) lcolor(black))
			xline(12, lpattern(dot) lwidth(thick) lcolor(black))
			xlabel(1 "reincidence (Forcing/Fee)" 
			2 "reincidence (fnr)"
			3 "reincidence | rec."  
			4 "reincidence | >50th perc."
			6 "reincidence (Forcing/Promise)" 
			7 "reincidence | rec." 
			8 "reincidence | >50th perc."
			10 "reincidence (Choice/Fee)"
			13 "reincidence (Choice/Promise)", angle(vertical) labsize(small))
			;

#delimit cr

graph export "$directorio\Figuras\re_te.pdf", replace
	
esttab using "$directorio/Tables/reg_results/re_te.csv", se r2 star(* 0.1 ** 0.05 *** 0.01) b(a2) ///
	scalars("ContrMean Control Mean") replace 
	
