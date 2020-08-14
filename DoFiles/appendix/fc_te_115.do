/*
Financial cost treatment effect
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
*ADMIN DATA
use "$directorio/DB/Master.dta", clear
*Condition to first 115 days
keep if dias_inicio<=115

*Dependent variables
gen fc_survey_pospay = fc_survey_disc if pagos>0
gen fc_survey_fee = fc_survey_disc if fee==1 | prod==1


********************************************************************************
**********************************Financial cost********************************
********************************************************************************



	local vrlist  fc_admin_disc fc_survey_disc  fc_trans_disc fc_survey_pospay fc_survey_fee  
	local vrlistnames  "admin (appraised)" "subjective"  "subj + tc" "subj | pay>0" "subj | fee=1" 

	local nv = 0	
	foreach var of varlist `vrlist' {
		local nv = `nv'+1
		}
		
	matrix results = J(`nv', 4, .) // empty matrix for results
	//  4 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) pvalue

	local row = 1	
	foreach depvar of varlist `vrlist' {

    reg `depvar' pro_2 ${C0}, r cluster(suc_x_dia) 
	local df = e(df_r)	
		
		matrix results[`row',1] = `row'
		// Beta 
		matrix results[`row',2] = _b[pro_2]
		// Standard error
		matrix results[`row',3] = _se[pro_2]
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[pro_2]/_se[pro_2]))
		
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
				xscale(range(`min_xaxis' `max_xaxis'))
				xscale(noline) /* because manual axis at 0 with yline above) */
				`plotregion' `graphregion'  
				legend(off)
				xlabel(1(1)`nv', valuelabel angle(vertical) labsize(small))
				;

	#delimit cr
	restore
	graph export "$directorio\Figuras\fc_te_115_pro_2.pdf", replace
	
