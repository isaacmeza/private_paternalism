/*
Quantile reg effective c/l (all fees) 
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

*Sum all possible fees (worst-case scenario)
gen eff_all_fee = eff_cost_loan 
replace eff_all_fee = eff_all_fee + 0.02*(ceil(dias_ultimo_mov/30))/3 if  pro_2==1

********************************************************************************
**********************************Financial cost********************************
********************************************************************************

*Dependent variables
local qlist  0.15 0.25 0.47 0.75 0.84 
local qlistnames "15%"  "25%" "50%" "75%" "85%"
	
matrix results = J(6, 5, .) // empty matrix for results
//  5 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) df, (5) pvalue



foreach arm of varlist pro_2  {

	eststo clear
	local row = 1	
	foreach quant in `qlist' {

		qui qreg eff_all_fee `arm' ${C0},  vce(robust) q(`quant')
		local df = e(df_r)	
		
		matrix results[`row',1] = `row'
		// Beta 
		matrix results[`row',2] = _b[`arm']
		// Standard error
		matrix results[`row',3] = _se[`arm']
		// deg freedom
		matrix results[`row',4] = `df'
		// P-value
		matrix results[`row',5] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		
		local row = `row' + 1
		}
		
	reg eff_all_fee `arm' ${C0}, r cluster(suc_x_dia) 
	local df = e(df_r)	
		
	matrix results[`row',1] = 3.1
	// Beta 
	matrix results[`row',2] = _b[`arm']
	// Standard error
	matrix results[`row',3] = _se[`arm']
	// deg freedom
	matrix results[`row',4] = `df'
	// P-value
	matrix results[`row',5] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		
	local row = `row' + 1
		

	matrix colnames results = "k" "beta" "se" "df" "p"
	matlist results
		
		
	
	clear
	svmat results, names(col) 

	*Name of vars
	gen varname = ""
	local row = 1
	local lbl = "k"
	foreach var in "`qlistnames'" {
		replace varname = "`var'" in `row'
		local varn  `var'
		local lbl  `lbl' `row' "`varn'"
		local row = `row' + 1
		}
			
	label define `lbl'
	label values k k

	// Confidence intervals (95%)
	local alpha = .05 // for 95% confidence intervals
	gen rcap_lo = beta - invttail(df,`=`alpha'/2')*se
	gen rcap_hi = beta + invttail(df,`=`alpha'/2')*se

	local min_yaxis = 0
	local max_yaxis = 0

	su rcap_lo
	local min_yaxis = min(`r(min)', `min_yaxis')
	local max_yaxis = max(`r(max)', `max_yaxis')

	su rcap_hi
	local min_yaxis = min(`r(min)', `min_yaxis')
	local max_yaxis = max(`r(max)', `max_yaxis')


	// GRAPH
	#delimit ;
	graph twoway 
				(scatter beta k if p<0.05 & _n<=5 ,           `estimate_options_95') 
				(scatter beta k if p>=0.05 & p<0.10 & _n<=5 , `estimate_options_90') 
				(scatter beta k if p>=0.10 & _n<=5 ,          `estimate_options_0' )
				(scatter beta k if  _n==6 , `estimate_options_95' msymbol(X)) 				
				(rcap rcap_hi rcap_lo k if p<0.05,           `rcap_options_95')
				(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10, `rcap_options_90')
				(rcap rcap_hi rcap_lo k if p>=0.10,          `rcap_options_0' )		
				, 
				title(" ", `title_options')
				yline(0, `manual_axis')
				xtitle("", `xtitle_options')
				yscale(range(`min_yaxis' `max_yaxis'))
				xscale(noline) /* because manual axis at 0 with yline above) */
				`plotregion' `graphregion'  
				legend(off)
				xlabel(1(1)5, valuelabel angle(vertical))
				;

	#delimit cr
	
	graph export "$directorio\Figuras\eff_allfee_quantile_`arm'.pdf", replace
	
	}
