** RUN R CODE : pfv_pred.R

global dep_var pago_frec_vol_promise

import delimited "$directorio\_aux\pred_${dep_var}.csv", clear
tempfile temp_rf_pred
save `temp_rf_pred'

import delimited "$directorio\_aux\data_pfv.csv", clear 
merge 1:1 nombrepignorante prenda using `temp_rf_pred', ///
	keepusing(rf_pred) keep(3)
	
********************************************************************************
********************************************************************************
*INTERACTIONS	
		
matrix results = J(4, 4, .) // empty matrix for results
//  4 cols are: (1) Variable, (2) beta, (3) std error, (4) pvalue
		
local row = 1		
foreach var of varlist  pb fb  tentado rec_cel {
	

	qui reg rf_pred `var'  ahorros cta_tanda edad genero renta comida medicina luz gas telefono agua , r
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
foreach var in  pb fb  tempt reminder {
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
			xlabel(1(1)4,valuelabel  angle(vertical))
			;

#delimit cr
graph export "$directorio\Figuras\\${dep_var}_interactions_rf_cond.pdf", replace
graph export "$directorio\Figuras\\${dep_var}_interactions_rf_cond.png", replace

		
