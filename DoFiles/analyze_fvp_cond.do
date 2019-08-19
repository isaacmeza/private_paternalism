** RUN R CODE HERE

global dep_var pago_frec_voluntario
import delimited "$directorio/_aux/pred_pago_frec_voluntario.csv", clear

********************************************************************************
*Measures of fit (OOS)

*Difference in l1 of probabilities (predicted values)
qui gen error_rf=abs(rf_predict-$dep_var) 
	su error_rf


*Correlation
corr $dep_var rf_predict   

*MSE
* - regression forest

gen rf_eps=$dep_var-rf_predict 
gen rf_eps2= rf_eps*rf_eps
gen rf_ss=sum(rf_eps2)
count 
local mse=rf_ss[_N] / `r(N)'
di " "
di "Regression Forest:  mse=" `mse' 

*ROC curve
roctab $dep_var rf_predict   ,graph summary  graphregion(color(white))

********************************************************************************
*INTERACTIONS	
		

local nv = 0	
foreach var of varlist prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time {
	
	local nv = `nv'+1
	}

matrix results = J(`nv', 4, .) // empty matrix for results
//  4 cols are: (1) Variable, (2) beta, (3) std error, (4) pvalue
		
local row = 1		
foreach var of varlist  pb fb  tentado {
	

	qui reg rf_predict `var'  ahorros cta_tanda edad genero renta comida medicina luz gas telefono agua, r
	local df = e(df_r)	
	
	matrix results[`row',1] = `row'
	// Beta 
	matrix results[`row',2] = _b[`var']
	// Standard error
	matrix results[`row',3] = _se[`var']
	// P-value
	matrix results[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
	
	local row = `row' + 1
	}	

matrix colnames results = "k" "beta" "se" "p"
matlist results

clear
svmat results, names(col) 

*Name of vars
gen varname = ""
local row = 1
local lbl = "k"
foreach var in  pb fb  tempt {
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
local estimate_options_0  mcolor(gs10)   msymbol(Oh) msize(medlarge)
local estimate_options_90 mcolor(gs7)   msymbol(O)  msize(medlarge)
local estimate_options_95 mcolor(black) msymbol(O)  msize(medlarge)
local rcap_options_0  lcolor(gs10)   lwidth(thin)
local rcap_options_90 lcolor(gs7)   lwidth(thin)
local rcap_options_95 lcolor(black) lwidth(thin)

// GRAPH
#delimit ;
graph twoway 
			(scatter beta k if p<0.05 ,           `estimate_options_95') 
			(scatter beta k if p>=0.05 & p<0.10 , `estimate_options_90') 
			(scatter beta k if p>=0.10 ,          `estimate_options_0' )
			(rcap rcap_hi rcap_lo k if p<0.05,           `rcap_options_95')
			(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10, `rcap_options_90')
			(rcap rcap_hi rcap_lo k if p>=0.10,          `rcap_options_0' )		
			, 
			title(" ", `title_options')
			ylabel(, `ylabel_options') 
			yline(0, `manual_axis')
			xtitle("", `xtitle_options')
			xscale(range(`min_xaxis' `max_xaxis'))
			xscale(noline) /* because manual axis at 0 with yline above) */
			`plotregion' `graphregion'  
			legend(off)
			xlabel(1(1)`nv',valuelabel  angle(vertical))
			;

#delimit cr
graph export "$directorio\Figuras\fvp_interactions_rf_cond.pdf", replace

		
