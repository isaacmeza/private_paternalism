args var C

	
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



reg `var'  i.t_prod `C', r cluster(suc_x_dia) 
local df = e(df_r)	
	
matrix results = J(8, 5, .) // empty matrix for results
//  5 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) df, (5) pvalue
forval row = 1/4 {
	matrix results[`row',1] = `row'
	// Beta 
	matrix results[`row',2] = _b[`=`row'+1'.t_prod]
	// Standard error
	matrix results[`row',3] = _se[`=`row'+1'.t_prod]
	// deg freedom
	matrix results[`row',4] = `df'
	// P-value
	matrix results[`row',5] = 2*ttail(`df', abs(_b[`=`row'+1'.t_prod]/_se[`=`row'+1'.t_prod]))
	}
	
reg `var' i.producto `C', r cluster(suc_x_dia)
local df = e(df_r)	
	
//  5 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) df, (5) pvalue
forval row = 5/8 {
	matrix results[`row',1] = `row'
	// Beta 
	matrix results[`row',2] = _b[`=`row'-1'.producto]
	// Standard error
	matrix results[`row',3] = _se[`=`row'-1'.producto]
	// deg freedom
	matrix results[`row',4] = `df'
	// P-value
	matrix results[`row',5] = 2*ttail(`df', abs(_b[`=`row'-1'.producto]/_se[`=`row'-1'.producto]))
	}

matrix colnames results = "k" "beta" "se" "df" "p"
matlist results
	
	
preserve
clear
svmat results, names(col) 

replace k = 3.3 if k==5 | k==6
replace k = 4.3 if k==7 | k==8

// Confidence intervals (95%)
local alpha = .05 // for 95% confidence intervals
gen rcap_lo = beta - invttail(df,`=`alpha'/2')*se
gen rcap_hi = beta + invttail(df,`=`alpha'/2')*se

	// GRAPH
#delimit ;
graph twoway 
	(scatter beta k if p<0.05 & inlist(k,1,2,3,4),           `estimate_options_95') 
	(scatter beta k if p>=0.05 & p<0.10 & inlist(k,1,2,3,4), `estimate_options_90') 
	(scatter beta k if p>=0.10 & inlist(k,1,2,3,4),          `estimate_options_0' )
	(scatter beta k if p<0.05 & (_n==5 | _n==7) ,          mcolor(black) msymbol(T)  msize(medlarge)) 
	(scatter beta k if p>=0.05 & p<0.10 & (_n==5 | _n==7), mcolor(gs7)   msymbol(T)  msize(medlarge)) 
	(scatter beta k if p>=0.10 & (_n==5 | _n==7),          mcolor(gs10)   msymbol(Th)  msize(medlarge))
	(scatter beta k if p<0.05 & (_n==6 | _n==8) ,          mcolor(black) msymbol(S)  msize(medlarge)) 
	(scatter beta k if p>=0.05 & p<0.10 & (_n==6 | _n==8), mcolor(gs7)   msymbol(S)  msize(medlarge)) 
	(scatter beta k if p>=0.10 & (_n==6 | _n==8),          mcolor(gs10)   msymbol(Sh)  msize(medlarge))
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
	legend(order(4 "SQ" 7 "NSQ"))
	xlabel(1 "Force/Fee" 2 "Promise/Fee" 3 "Choice/Fee" 4 "Choice/Promise"
			, angle(vertical))
;

#delimit cr
graph export "$directorio\Figuras\te_allarms_`var'.pdf", replace
restore
