/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 10, 2021
* Last date of modification:   
* Modifications:		
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Quantile reg effective cost/loan ratio - decomposed by choice selection

*******************************************************************************/
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


********************************************************************************
*****************************Effective cost/loan********************************
********************************************************************************


matrix results = J(20, 5, .) // empty matrix for results
//  5 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) df, (5) pvalue



foreach arm of varlist pro_4 pro_5  {


	if "`arm'"=="pro_4" {
		*Dependent variables
		local qlist  0.15 0.25 0.49 0.75 0.85 
		local qlistnames "15%"  "25%" "50%" "75%" "85%"
		local contrarm pro_2
		local arm_dec_sq pro_6
		local arm_dec_nsq pro_7
		}
	else {
		*Dependent variables
		local qlist  0.15 0.25 0.51 0.75 0.85 
		local qlistnames "15%"  "25%" "50%" "75%" "85%"
		local contrarm pro_3	
		local arm_dec_sq pro_8
		local arm_dec_nsq pro_9
		}
			
	eststo clear		
	local row = 1
	local nu = 1	
	foreach quant in `qlist' {

		eststo: qreg eff_cost_loan `arm' ${C0},  vce(robust) q(`quant') iterate(700)
		su eff_cost_loan if e(sample) & `arm'==0
		estadd scalar ContrMean = `r(mean)'		
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'
		// Beta 
		matrix results[`row',2] = _b[`arm']
		// Standard error
		matrix results[`row',3] = _se[`arm']
		// deg freedom
		matrix results[`row',4] = `df'	
		// P-value
		matrix results[`row',5] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		
		local row = `row' + 1
		
		
		qreg eff_cost_loan `contrarm' ${C0},  vce(robust) q(`quant') iterate(700)		
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'
		// Beta 
		matrix results[`row',2] = _b[`contrarm']
		// Standard error
		matrix results[`row',3] = _se[`contrarm']
		// deg freedom
		matrix results[`row',4] = `df'	
		// P-value
		matrix results[`row',5] = 2*ttail(`df', abs(_b[`contrarm']/_se[`contrarm']))
		
		local row = `row' + 1
		
		
		eststo : qreg eff_cost_loan `arm_dec_sq' ${C0},  vce(robust) q(`quant') iterate(700)
		su eff_cost_loan if e(sample) & `arm_dec_sq'==0
		estadd scalar ContrMean = `r(mean)'			
		local df_sq = e(df_r)	
		matrix results[`row',1] = `nu'+0.3
		// Beta 
		matrix results[`row',2] = _b[`arm_dec_sq']
		// Standard error
		matrix results[`row',3] = _se[`arm_dec_sq']
		// deg freedom
		matrix results[`row',4] = `df'	
		// P-value
		matrix results[`row',5] = 2*ttail(`df_sq', abs(_b[`arm_dec_sq']/_se[`arm_dec_sq']))
			
		local row = `row' + 1

		eststo: qreg eff_cost_loan `arm_dec_nsq' ${C0},  vce(robust) q(`quant')  iterate(700)
		su eff_cost_loan if e(sample) & `arm_dec_nsq'==0
		estadd scalar ContrMean = `r(mean)'			
		local df_nsq = e(df_r)	
		matrix results[`row',1] = `nu'+0.3
		// Beta 
		matrix results[`row',2] = _b[`arm_dec_nsq']
		// Standard error
		matrix results[`row',3] = _se[`arm_dec_nsq']
		// deg freedom
		matrix results[`row',4] = `df'	
		// P-value
		matrix results[`row',5] = 2*ttail(`df_sq', abs(_b[`arm_dec_nsq']/_se[`arm_dec_nsq']))
			
		local row = `row' + 1
		local nu = `nu' + 1
		}
		

	matrix colnames results = "k" "beta" "se" "df" "p"
	matlist results
		
		
	preserve
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

	// GRAPH
	gen ord = _n
	#delimit ;
graph twoway 
				(scatter beta k if p<0.05 & inlist(ord,1,5,9,13,17,21,25,29),           `estimate_options_95') 
				(scatter beta k if p>=0.05 & p<0.10  & inlist(ord,1,5,9,13,17,21,25,29) , `estimate_options_90') 
				(scatter beta k if p>=0.10  & inlist(ord,1,5,9,13,17,21,25,29) ,          `estimate_options_0' )
				(scatter beta k if p<0.05 & inlist(ord,3,7,11,15,19,23,27,31) ,          mcolor(black) msymbol(T)  msize(medlarge)) 
				(scatter beta k if p>=0.05 & p<0.10 & inlist(ord,3,7,11,15,19,23,27,31), mcolor(gs7)   msymbol(T)  msize(medlarge)) 
				(scatter beta k if p>=0.10 & inlist(ord,3,7,11,15,19,23,27,31),          mcolor(gs10)   msymbol(Th)  msize(medlarge))
				(scatter beta k if p<0.05 & inlist(ord,4,8,12,16,20,24,28,32) ,          mcolor(black) msymbol(S)  msize(medlarge)) 
				(scatter beta k if p>=0.05 & p<0.10 & inlist(ord,4,8,12,16,20,24,28,32), mcolor(gs7)   msymbol(S)  msize(medlarge)) 
				(scatter beta k if p>=0.10 & inlist(ord,4,8,12,16,20,24,28,32),          mcolor(gs10)   msymbol(Sh)  msize(medlarge))
				(rcap rcap_hi rcap_lo k if p<0.05 & !inlist(ord,2,6,10,14,18,22,26,30),           `rcap_options_95')
				(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10 & !inlist(ord,2,6,10,14,18,22,26,30), `rcap_options_90')
				(rcap rcap_hi rcap_lo k if p>=0.10 & !inlist(ord,2,6,10,14,18,22,26,30),          `rcap_options_0' )		
				, 
				title(" ", `title_options')
				yline(0, `manual_axis')
				xtitle("", `xtitle_options')
				xscale(range(`min_xaxis' `max_xaxis'))
				xscale(noline) /* because manual axis at 0 with yline above) */
				`plotregion' `graphregion'  
				legend(order(4 "SQ" 7 "NSQ") rows(1))
				xlabel(1(1)5, valuelabel angle(vertical) labsize(small))
				;

	#delimit cr
	restore
	graph export "$directorio\Figuras\eff_quantile_`arm'.pdf", replace
	
	esttab using "$directorio/Tables/reg_results/eff_quantile_`arm'.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") replace 	
	}
