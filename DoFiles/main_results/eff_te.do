/*
Effective cost/loan ratio treatment effect
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

*Dependent variables
gen eff_pospay = eff_cost_loan if sum_p_c>0
gen eff_fee = eff_cost_loan if fee==1 | prod==1
gen eff_tc = eff_cost_loan + trans_cost/prestamo

*Decomposition of effecive cost-loan ratio
gen payment = sum_porcp_c-sum_porc_pay_fee_c-sum_porc_int_c


********************************************************************************
*****************************Effective cost/loan********************************
********************************************************************************


foreach arm of varlist  pro_3 pro_2 {


	if "`arm'"=="pro_2" {
		local vrlist  payment sum_porc_pay_fee_c sum_porc_int_c  eff_cost_loan   eff_tc  eff_pospay  eff_fee  
		local vrlistnames  "S" "X" "D"  "effective cost/loan"  "cost/loan + tc" "cost/loan | pay>0" "cost/loan | fee=1" 
		}
	else {
		local vrlist  eff_cost_loan  eff_tc  eff_pospay   
		local vrlistnames  "admin (appraised)"  "subj + tc" "subj | pay>0"  
		}

	local nv = 0	
	foreach var of varlist `vrlist' {
		local nv = `nv'+1
		}
		
	eststo clear
	matrix results = J(`nv', 5, .) // empty matrix for results
	//  5 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) df, (5) pvalue

	local row = 1	
	foreach depvar of varlist `vrlist' {

	eststo: reg `depvar' `arm' ${C0}, r cluster(suc_x_dia) 
	su `depvar' if e(sample) & `arm'==0
	estadd scalar ContrMean = `r(mean)'
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
		

	matrix colnames results = "k" "beta" "se" "df" "p"
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
	gen rcap_lo = beta - invttail(df,`=`alpha'/2')*se
	gen rcap_hi = beta + invttail(df,`=`alpha'/2')*se

	// GRAPH
	local st = 1
	if "`arm'"=="pro_2" {
		replace k = 3.5 in 1
		replace k = 3.6 in 2
		replace k = 3.7 in 3
		local st = 4
		}
		
	#delimit ;
	graph twoway 
				(scatter beta k if p<0.05 & !inlist(varname,"S","T","X","D") , `estimate_options_95') 
				(scatter beta k if p>=0.05 & p<0.10 & !inlist(varname,"S","T","X","D"), `estimate_options_90') 
				(scatter beta k if p>=0.10 & !inlist(varname,"S","T","X","D") ,`estimate_options_0' )
				(scatter beta k if p<0.05 & varname=="S", msymbol(S) color(ltblue)) 
				(scatter beta k if p>=0.05 & p<0.10 & varname=="S" , msymbol(S) color(ltblue)) 
				(scatter beta k if p>=0.10 & varname=="S" , msymbol(S) color(ltblue))
				(scatter beta k if p<0.05 & varname=="D", msymbol(D) color(ltblue)) 
				(scatter beta k if p>=0.05 & p<0.10 & varname=="D" , msymbol(D) color(ltblue)) 
				(scatter beta k if p>=0.10 & varname=="D" , msymbol(D) color(ltblue))	
				(scatter beta k if p<0.05 & varname=="X", msymbol(X) color(ltblue)) 
				(scatter beta k if p>=0.05 & p<0.10 & varname=="X" , msymbol(X) color(ltblue)) 
				(scatter beta k if p>=0.10 & varname=="X" , msymbol(X) color(ltblue))	
				(scatter beta k if p<0.05 & varname=="T", msymbol(T) color(ltblue)) 
				(scatter beta k if p>=0.05 & p<0.10 & varname=="T" , msymbol(T) color(ltblue)) 
				(scatter beta k if p>=0.10 & varname=="T" , msymbol(T) color(ltblue))					
				(rcap rcap_hi rcap_lo k if p<0.05 & !inlist(varname,"S","T","X","D"),           `rcap_options_95')
				(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10 & !inlist(varname,"S","T","X","D"), `rcap_options_90')
				(rcap rcap_hi rcap_lo k if p>=0.10 & !inlist(varname,"S","T","X","D"),          `rcap_options_0' )	
				(rcap rcap_hi rcap_lo k if inlist(varname,"S","T","X","D"), color(ltblue))
				, 
				title(" ", `title_options')
				yline(0, `manual_axis')
				xtitle("", `xtitle_options')
				xscale(range(`min_xaxis' `max_xaxis'))
				xscale(noline) /* because manual axis at 0 with yline above) */
				`plotregion' `graphregion'  
				legend(off)
				xlabel(`st'(1)`nv', valuelabel angle(vertical) labsize(small))
				;
	#delimit cr

	restore
	graph export "$directorio\Figuras\eff_te_`arm'.pdf", replace
	
	esttab using "$directorio/Tables/reg_results/eff_te_`arm'.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") replace 
	}		
			
