/*
Default treatment effect
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

local vrlist  def_c   pos_pay_default pay_30_default def_120 pos_pay_120_def_c  def_oc def_noc def_pb 
local vrlistnames "not recover"  "not rec. | pay>0" "not rec. | pay>30%" "not rec. | days<120" "not rec. | days<120 & pay>0" "not rec. | OC" "not rec. | no OC" "not rec. | PB" "reincidence" "reincidence | rec." "reincidence | >50th perc. effect"

	
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
	***********************************Not recovery*********************************
	********************************************************************************

	*Dependent variables
	logit des_c i.prenda_tipo val_pren prestamo genero edad i.educacion i.pres_antes ///
		i.plan_gasto i.ahorros i.cta_tanda i.tent i.rec_cel faltas 
	predict pr_prob
	replace pr_prob = pr_prob*100

	gen def_oc = def_c if pr_recup>pr_prob & (!missing(pr_recup) & !missing(pr_prob))
	gen def_noc = def_c if pr_recup<=pr_prob & (!missing(pr_recup) & !missing(pr_prob))
	gen def_pb = def_c if pb | rec_cel

	local nv = 0	
	foreach var of varlist `vrlist' {
		local nv = `nv'+1
		}
			

	matrix results = J(`nv'+3, 4, .) // empty matrix for results
	//  4 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) pvalue

	local row = 1	
	foreach depvar of varlist `vrlist' {
		
		reg `depvar' `arm' ${C0}, r cluster(suc_x_dia) 
		local df = e(df_r)	
		
		matrix results[`row',1] = `row'
		// Beta 
		matrix results[`row',2] = _b[`arm']
		// Standard error
		matrix results[`row',3] = _se[`arm']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		
		local row = `row' + 1
		}

		
		*Regressions at the 'customer' level
		preserve
		collapse reincidence prestamo $C1  `arm' ///
			, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		reg reincidence `arm' ${C1} , r  
		local df = e(df_r)	
		
		matrix results[`nv'+1,1] = `nv'+1
		// Beta 
		matrix results[`nv'+1,2] = _b[`arm']
		// Standard error
		matrix results[`nv'+1,3] = _se[`arm']
		// P-value
		matrix results[`nv'+1,4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		restore
		
		
		preserve
		*Subsample of people who recovers its first pawn
		keep if prenda==first_prenda  & des_c==1
		collapse reincidence prestamo $C1  `arm' ///
			if prenda, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		reg reincidence `arm' ${C1} , r  
		local df = e(df_r)	
		
		matrix results[`nv'+2,1] = `nv'+2
		// Beta 
		matrix results[`nv'+2,2] = _b[`arm']
		// Standard error
		matrix results[`nv'+2,3] = _se[`arm']
		// P-value
		matrix results[`nv'+2,4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		restore
		
		preserve
		*Subsample of people who recovers its first pawn
		keep if prenda==first_prenda  & above_med_effect==1
		collapse reincidence prestamo $C1  `arm' ///
			if prenda, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		reg reincidence `arm' ${C1} , r  
		local df = e(df_r)	
		
		matrix results[`nv'+3,1] = `nv'+3
		// Beta 
		matrix results[`nv'+3,2] = _b[`arm']
		// Standard error
		matrix results[`nv'+3,3] = _se[`arm']
		// P-value
		matrix results[`nv'+3,4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		restore	

	matrix colnames results = "k" "beta" "se" "p"
	matlist results
		
		
	*preserve
	clear
	svmat results, names(col) 

	*Name of vars
	gen varname = ""
	local row = 1
	local lbl = "k"
	foreach var in "`vrlistnames'" {
		replace varname = "`var'" in `row'
		local varn  `var'
		local lbl  `lbl' `row' "`varn'"
		local row = `row' + 1
		}
	label define `lbl'
	label values k k

	// Confidence intervals (95%)
	local alpha = .05 // for 95% confidence intervals
	gen rcap_lo = beta - invttail(`df',`=`alpha'/2')*se
	gen rcap_hi = beta + invttail(`df',`=`alpha'/2')*se

	// GRAPH
	#delimit ;
	graph twoway 
				(scatter beta k if p<0.05 & k<=`nv',           `estimate_options_95') 
				(scatter beta k if p>=0.05 & p<0.10 & k<=`nv' , `estimate_options_90') 
				(scatter beta k if p>=0.10 & k<=`nv' ,          `estimate_options_0' )
				(rcap rcap_hi rcap_lo k if p<0.05 & k<=`nv',           `rcap_options_95')
				(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10 & k<=`nv', `rcap_options_90')
				(rcap rcap_hi rcap_lo k if p>=0.10 & k<=`nv',          `rcap_options_0' )		
				/* */
				(scatter beta k if p<0.05 & k>=`nv'+1  ,           `estimate_options_95' yaxis(2)) 
				(scatter beta k if p>=0.05 & p<0.10 & k>=`nv'+1 , `estimate_options_90' yaxis(2)) 
				(scatter beta k if p>=0.10 & k>=`nv'+1,          `estimate_options_0' yaxis(2))
				(rcap rcap_hi rcap_lo k if p<0.05 & k>=`nv'+1,           `rcap_options_95' lcolor(red) yaxis(2))
				(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10 & k>=`nv'+1, `rcap_options_90' lcolor(red) yaxis(2))
				(rcap rcap_hi rcap_lo k if p>=0.10 & k>=`nv'+1,          `rcap_options_0' lcolor(red) yaxis(2))		
				, 
				title(" ", `title_options')
				yline(0, `manual_axis' axis(1))
				xtitle("", `xtitle_options')
				ytitle("Not rec. effect",axis(1))
				ytitle("Reincidence effect",axis(2))
				xscale(range(`min_xaxis' `max_xaxis'))
				xscale(noline) /* because manual axis at 0 with yline above) */
				`plotregion' `graphregion'  
				legend(off)
				xline(8.5, lpattern(dot) lcolor(black) lwidth(thick))
				xlabel(1(1)`=`nv'+3', valuelabel angle(vertical) labsize(small))
				;

	#delimit cr
	*restore
	graph export "$directorio\Figuras\def_te_`arm'.pdf", replace
	}
