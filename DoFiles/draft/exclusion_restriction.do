/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	November. 11, 2021
* Last date of modification:   
* Modifications:		
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Comparison between choosers and no choosers vs the forced fee arm to test exclusion restriction.


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


matrix results = J(4, 5, .) // empty matrix for results
	//  5 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) df, (5) pvalue
	
reg apr i.prod ${C0} if inlist(prod,1,2,4,5) , r cluster(suc_x_dia) 
local df = e(df_r)	
		
matrix results[1,1] = 1
	// Beta 
matrix results[1,2] = _b[2.prod]
	// Standard error
matrix results[1,3] = _se[2.prod]
	// deg freedom
matrix results[1,4] = `df'	
	// P-value
matrix results[1,5] = 2*ttail(`df', abs(_b[2.prod]/_se[2.prod]))

*-------------------------------------------------------------------------------

matrix results[2,1] = 1.1
	// Beta 
matrix results[2,2] = _b[4.prod]
	// Standard error
matrix results[2,3] = _se[4.prod]
	// deg freedom
matrix results[2,4] = `df'	
	// P-value
matrix results[2,5] = 2*ttail(`df', abs(_b[4.prod]/_se[4.prod]))

*-------------------------------------------------------------------------------

matrix results[3,1] = 1.1
	// Beta 
matrix results[3,2] = _b[5.prod]
	// Standard error
matrix results[3,3] = _se[5.prod]
	// deg freedom
matrix results[3,4] = `df'	
	// P-value
matrix results[3,5] = 2*ttail(`df', abs(_b[5.prod]/_se[5.prod]))

*-------------------------------------------------------------------------------
		
reg apr pro_4 ${C0}, r cluster(suc_x_dia) 
local df = e(df_r)	
		
matrix results[4,1] = 1
	// Beta 
matrix results[4,2] = _b[pro_4]
	// Standard error
matrix results[4,3] = _se[pro_4]
	// deg freedom
matrix results[4,4] = `df'	
	// P-value
matrix results[4,5] = 2*ttail(`df', abs(_b[pro_4]/_se[pro_4]))		
		
*-------------------------------------------------------------------------------

matrix colnames results = "k" "beta" "se" "df" "p"
matlist results
		
clear
svmat results, names(col) 

// Confidence intervals (95%)
local alpha = .05 // for 95% confidence intervals
gen rcap_lo = beta - invttail(df,`=`alpha'/2')*se 
gen rcap_hi = beta + invttail(df,`=`alpha'/2')*se 

gen ord = _n

#delimit ;
graph twoway 
	(scatter beta k if p<0.05 & inlist(ord,1),  `estimate_options_95') 
	(scatter beta k if p>=0.05 & p<0.10  & inlist(ord,1) , `estimate_options_90') 
	(scatter beta k if p>=0.10  & inlist(ord,1) ,  `estimate_options_0' )
	(scatter beta k if p<0.05 & inlist(ord,2) ,  mcolor(black) msymbol(T)  msize(medlarge)) 
	(scatter beta k if p>=0.05 & p<0.10 & inlist(ord,2), mcolor(gs7)   msymbol(T)  msize(medlarge)) 
	(scatter beta k if p>=0.10 & inlist(ord,2),  mcolor(gs10)   msymbol(Th)  msize(medlarge))
	(scatter beta k if p<0.05 & inlist(ord,3) ,  mcolor(black) msymbol(S)  msize(medlarge)) 
	(scatter beta k if p>=0.05 & p<0.10 & inlist(ord,3), mcolor(gs7)   msymbol(S)  msize(medlarge)) 
	(scatter beta k if p>=0.10 & inlist(ord,3),  mcolor(gs10)   msymbol(Sh)  msize(medlarge))
	(scatter beta k if p<0.05 & inlist(ord,4),   mcolor(black)   msymbol(D)  msize(medlarge))
	(scatter beta k if p>=0.05 & p<0.10 & inlist(ord,4),  mcolor(gs7)   msymbol(D)  msize(medlarge))
	(scatter beta k if p>=0.10 & inlist(ord,4),  mcolor(gs10)   msymbol(Dh)  msize(medlarge))
	(rcap rcap_hi rcap_lo k if p<0.05 ,  `rcap_options_95')
	(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10 , `rcap_options_90')
	(rcap rcap_hi rcap_lo k if p>=0.10 ,  `rcap_options_0' )	
			, 
			title(" ", `title_options')
			yline(0, `manual_axis')
			xtitle("APR", `xtitle_options')
			ytitle("Effect")
			xscale(range(0.95 1.15))
			xscale(noline) /* because manual axis at 0 with yline above) */
			`plotregion' `graphregion'  
			legend(order(1 "Forced fee" 4 "Non chooser" 7 "Choosers" 10 "Choice arm") pos(6) rows(1))
			xlabel(none)
			;
#delimit cr
graph export "$directorio\Figuras\exclusion_restriction.pdf", replace

		
			
