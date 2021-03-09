/*Treatment regressions for payed and incurred interests & fees*/

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
local arm pro_2


************Regressions****************

matrix results = J(9, 5, .) // empty matrix for results
	//  5 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) df, (5) pvalue

local vrlistnames "Payed interests" "Incurred interests"  "Payed fees" 
	
local row = 1
foreach var of varlist sum_int_c sum_inc_int_c sum_pay_fee_c {
	reg `var' `arm' $C0, r cluster(suc_x_dia)
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
			
			
	reg `var' `arm' $C0 if des_c==1, r cluster(suc_x_dia)
	local df = e(df_r)	
			
			matrix results[`row'+1,1] = `row'+0.75
			// Beta 
			matrix results[`row'+1,2] = _b[`arm']
			// Standard error
			matrix results[`row'+1,3] = _se[`arm']
			// deg freedom
			matrix results[`row'+1,4] = `df'
			// P-value
			matrix results[`row'+1,5] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))

			
	reg `var' `arm' $C0 if des_c==0, r cluster(suc_x_dia)
	local df = e(df_r)	
			
			matrix results[`row'+2,1] = `row'+1
			// Beta 
			matrix results[`row'+2,2] = _b[`arm']
			// Standard error
			matrix results[`row'+2,3] = _se[`arm']
			// deg freedom
			matrix results[`row'+2,4] = `df'
			// P-value
			matrix results[`row'+2,5] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		
	local row = `row' + 3		
	}


	matrix colnames results = "k" "beta" "se" "df" "p"
	matlist results
		
		
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
		local row = `row' + 3
		}

	label define `lbl'
	label values k k
	gen zero = 0
	gen n=_n
	
	// Confidence intervals (95%)
	local alpha = .05 // for 95% confidence intervals
	gen rcap_lo = beta - invttail(df,`=`alpha'/2')*se
	gen rcap_hi = beta + invttail(df,`=`alpha'/2')*se

	// GRAPH
	#delimit ;
	graph twoway 
				(scatter beta k if p<0.05 & k<=6 & inlist(n,1,4),  `estimate_options_95' yaxis(1)) 
				(scatter beta k if p>=0.05 & p<0.10 & k<=6 & inlist(n,1,4), `estimate_options_90' yaxis(1)) 
				(scatter beta k if p>=0.10 & k<=6 & inlist(n,1,4),          `estimate_options_0'  yaxis(1))
				(rcap rcap_hi rcap_lo k if p<0.05 & k<=6 ,           `rcap_options_95' yaxis(1))
				(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10 & k<=6, `rcap_options_90' yaxis(1))
				(rcap rcap_hi rcap_lo k if p>=0.10 & k<=6 ,          `rcap_options_0'  yaxis(1))	
				
				(scatter beta k if inlist(n,2,5) , msymbol(S) yaxis(1) color(ltblue)) 
				(scatter beta k if inlist(n,3,6) , msymbol(T) yaxis(1) color(ltblue)) 
			
				(scatter beta k if p<0.05 & k>6 & inlist(n,7), `estimate_options_95' yaxis(2)) 
				(scatter beta k if p>=0.05 & p<0.10 & k>6 & inlist(n,7), `estimate_options_90' yaxis(2)) 
				(scatter beta k if p>=0.10 & k>6 & inlist(n,7) ,          `estimate_options_0'  yaxis(2))
				(rcap rcap_hi rcap_lo k if p<0.05 & k>6 ,           `rcap_options_95' yaxis(2))
				(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10 & k>6, `rcap_options_90' yaxis(2))
				(rcap rcap_hi rcap_lo k if p>=0.10 & k>6 ,          `rcap_options_0'  yaxis(2))	
				
				(scatter beta k if inlist(n,8) , msymbol(S) yaxis(2) color(ltblue)) 
				(scatter beta k if inlist(n,9) , msymbol(T) yaxis(2) color(ltblue)) 
				
				(line zero n if n<=6, color(black) yaxis(1))
				(line zero n if n>=6, color(black) yaxis(2))
				, 
				title(" ", `title_options')
				xtitle("", `xtitle_options')
				xline(6, lpattern(dot) lcolor(black))
				xscale(range(`min_xaxis' `max_xaxis'))
				xscale(noline) /* because manual axis at 0 with yline above) */
				`plotregion' `graphregion'  
				legend(order(7 "Recover pawn" 8 "Lost pawn"))
				xlabel(1 4 7, valuelabel angle(horizontal) labsize(small)  labgap(3))
				;

	#delimit cr
	graph export "$directorio\Figuras\int_te_`arm'.pdf", replace
	
********************************************************************************	
	
