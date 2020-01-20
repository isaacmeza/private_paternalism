/*
Effect in default for different propensity of take up predicted (using a RF)
probabilities
*/


********************************************************************************

** RUN R CODE : pfv_pred_hte.R

********************************************************************************



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

*Effect of not recovery for the nochoice/fee arm had they were given choice
* (created in pfv_pred_hte.R)
import delimited "$directorio/_aux/pred_pro_2_pago_frec_vol_fee_def_c.csv", clear
destring tau_hat_oobpredictions, replace force
merge 1:1 prenda using "$directorio/DB/Master.dta", nogen


*Generation of categories for different threshold take-up predicted probabilities
xtile perc_rf_pred = rf_pred, nq(100)
gen du1 = inrange(perc_rf_pred,0,20) if !missing(rf_pred)
gen du2 = inrange(perc_rf_pred,21,40) if !missing(rf_pred)
gen du3 = inrange(perc_rf_pred,41,60) if !missing(rf_pred)
gen du4 = inrange(perc_rf_pred,61,80) if !missing(rf_pred)
gen du5 = inrange(perc_rf_pred,81,100) if !missing(rf_pred)

su du*

local vrlist  du1 du2 du3 du4 du5
local vrlistnames  "Take up Pr: [0,20%]" "Take up Pr: (20%,40%]"  "Take up Pr: (40%,60%]"  "Take up Pr: (60%,80%]"  "Take up Pr: (80%,100%]" 

local nv = 0	
foreach var of varlist `vrlist' {
	local nv = `nv'+1
	}
	

matrix results = J(`nv', 4, .) // empty matrix for results
//  4 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) pvalue

local row = 1	
foreach indvar of varlist `vrlist' {

reg def_c `indvar' ${C0}, r cluster(suc_x_dia) 
local df = e(df_r)	
	
	matrix results[`row',1] = `row'
	// Beta 
	matrix results[`row',2] = _b[`indvar']
	// Standard error
	matrix results[`row',3] = _se[`indvar']
	// P-value
	matrix results[`row',4] = 2*ttail(`df', abs(_b[`indvar']/_se[`indvar']))
	
	local row = `row' + 1
	}
	

matrix colnames results = "k" "beta" "se" "p"
matlist results
	
	
preserve
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
			(scatter beta k if p<0.05 ,           `estimate_options_95') 
			(scatter beta k if p>=0.05 & p<0.10 , `estimate_options_90') 
			(scatter beta k if p>=0.10 ,          `estimate_options_0' )
			(rcap rcap_hi rcap_lo k if p<0.05,           `rcap_options_95')
			(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10, `rcap_options_90')
			(rcap rcap_hi rcap_lo k if p>=0.10,          `rcap_options_0' )		
			, 
			title(" ", `title_options')
			yline(0, `manual_axis')
			xtitle("", `xtitle_options')
			ytitle("Effect")
			xscale(range(`min_xaxis' `max_xaxis'))
			xscale(noline) /* because manual axis at 0 with yline above) */
			`plotregion' `graphregion'  
			legend(off)
			xlabel(1(1)`nv', valuelabel angle(vertical))
			;

#delimit cr
restore
graph export "$directorio\Figuras\takeuppr_def.pdf", replace
			
		
