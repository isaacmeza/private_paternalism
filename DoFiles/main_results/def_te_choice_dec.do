/*
Default treatment effect - decomposed by choice selection
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

local vrlist  def_c   pos_pay_default pay_30_default def_120 pos_pay_120_def_c  def_oc def_noc def_pb 
local vrlistnames "not recover"  "not rec. | pay>0" "not rec. | pay>30%" "not rec. | days<120" "not rec. | days<120 & pay>0" "not rec. | OC" "not rec. | no OC" "not rec. | PB" "reincidence"

*ADMIN DATA
use "$directorio/DB/Master.dta", clear

********************************************************************************
***********************************Not recovery*********************************
********************************************************************************

*Dependent variables
logit des_c i.prenda_tipo val_pren prestamo genero edad i.educacion i.pres_antes ///
	i.plan_gasto i.ahorros i.cta_tanda i.tent i.rec_cel faltas 
predict pr_prob

gen def_oc = def_c if pr_recup>pr_prob
gen def_noc = def_c if pr_recup<=pr_prob
gen def_pb = def_c if pb | rec_cel


foreach arm in pro_4 pro_5 {


	if "`arm'"=="pro_4" {
		local contrarm pro_2
		local arm_dec_sq pro_6
		local arm_dec_nsq pro_7
		}
	else {
		local contrarm pro_3	
		local arm_dec_sq pro_8
		local arm_dec_nsq pro_9
		}


	local nv = 0	
	foreach var of varlist `vrlist' {
		local nv = `nv'+1
		}
			

	matrix results = J(`=(`nv'+1)*4', 4, .) // empty matrix for results
	//  4 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) pvalue

	local row = 1	
	local nu = 1
	foreach depvar of varlist `vrlist' {
		
		reg `depvar' `arm' ${C0}, r cluster(suc_x_dia) 
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'
		// Beta 
		matrix results[`row',2] = _b[`arm']
		// Standard error
		matrix results[`row',3] = _se[`arm']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		
		local row = `row' + 1
		
		reg `depvar' `contrarm' ${C0}, r cluster(suc_x_dia) 
		local df = e(df_r)	
		
		matrix results[`row',1] = `nu'
		// Beta 
		matrix results[`row',2] = _b[`contrarm']
		// Standard error
		matrix results[`row',3] = _se[`contrarm']
		// P-value
		matrix results[`row',4] = 2*ttail(`df', abs(_b[`contrarm']/_se[`contrarm']))
		
		local row = `row' + 1
		
		reg `depvar' `arm_dec_sq' ${C0}, r cluster(suc_x_dia) 
		local df_sq = e(df_r)	
		matrix results[`row',1] = `nu'+0.3
		// Beta 
		matrix results[`row',2] = _b[`arm_dec_sq']
		// Standard error
		matrix results[`row',3] = _se[`arm_dec_sq']
		// P-value
		matrix results[`row',4] = 2*ttail(`df_sq', abs(_b[`arm_dec_sq']/_se[`arm_dec_sq']))
			
		local row = `row' + 1

		reg `depvar' `arm_dec_nsq' ${C0}, r cluster(suc_x_dia) 
		local df_nsq = e(df_r)	
		matrix results[`row',1] = `nu'+0.3
		// Beta 
		matrix results[`row',2] = _b[`arm_dec_nsq']
		// Standard error
		matrix results[`row',3] = _se[`arm_dec_nsq']
		// P-value
		matrix results[`row',4] = 2*ttail(`df_sq', abs(_b[`arm_dec_nsq']/_se[`arm_dec_nsq']))
			
		local row = `row' + 1
		local nu = `nu' + 1
		}


		*Regressions at the 'customer' level
		preserve
		collapse reincidence prestamo $C1  `arm' ///
			, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		reg reincidence `arm' ${C1} , r  
		local df = e(df_r)	
		
		matrix results[`=`nv'*4+1',1] = `=`nv'+1'
		// Beta 
		matrix results[`=`nv'*4+1',2] = _b[`arm']
		// Standard error
		matrix results[`=`nv'*4+1',3] = _se[`arm']
		// P-value
		matrix results[`=`nv'*4+1',4] = 2*ttail(`df', abs(_b[`arm']/_se[`arm']))
		restore
		
		preserve
		collapse reincidence prestamo $C1  `contrarm' ///
			, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		reg reincidence `contrarm' ${C1} , r  
		local df = e(df_r)	
		
		matrix results[`=`nv'*4+2',1] = `=`nv'+1'
		// Beta 
		matrix results[`=`nv'*4+2',2] = _b[`contrarm']
		// Standard error
		matrix results[`=`nv'*4+2',3] = _se[`contrarm']
		// P-value
		matrix results[`=`nv'*4+2',4] = 2*ttail(`df', abs(_b[`contrarm']/_se[`contrarm']))
		restore
		
		preserve
		collapse reincidence prestamo $C1  `arm_dec_sq' ///
			, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		reg reincidence `arm_dec_sq' ${C1} , r  
		local df = e(df_r)	
		
		matrix results[`=`nv'*4+3',1] = `=`nv'+1'+0.3
		// Beta
		matrix results[`=`nv'*4+3',2] = _b[`arm_dec_sq']
		// Standard error
		matrix results[`=`nv'*4+3',3] = _se[`arm_dec_sq']
		// P-value
		matrix results[`=`nv'*4+3',4] = 2*ttail(`df', abs(_b[`arm_dec_sq']/_se[`arm_dec_sq']))
		restore
		
		preserve
		collapse reincidence prestamo $C1  `arm_dec_nsq' ///
			, by(NombrePignorante fecha_inicial)

		sort NombrePignorante fecha_inicial
		bysort NombrePignorante : keep if _n==1

		reg reincidence `arm_dec_nsq' ${C1} , r  
		local df = e(df_r)	
		
		matrix results[`=`nv'*4+4',1] = `=`nv'+1'+0.3
		// Beta 
		matrix results[`=`nv'*4+4',2] = _b[`arm_dec_nsq']
		// Standard error
		matrix results[`=`nv'*4+4',3] = _se[`arm_dec_nsq']
		// P-value
		matrix results[`=`nv'*4+4',4] = 2*ttail(`df', abs(_b[`arm_dec_nsq']/_se[`arm_dec_nsq']))
		restore

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
	gen ord = _n
	#delimit ;
	graph twoway 
				(scatter beta k if p<0.05 & k<`nv'+1 & inlist(ord,1,5,9,13,17,21,25,29),           `estimate_options_95') 
				(scatter beta k if p>=0.05 & p<0.10 & k<`nv'+1 & inlist(ord,1,5,9,13,17,21,25,29) , `estimate_options_90') 
				(scatter beta k if p>=0.10 & k<`nv'+1 & inlist(ord,1,5,9,13,17,21,25,29) ,          `estimate_options_0' )
				(scatter beta k if p<0.05 & k<`nv'+1 & inlist(ord,3,7,11,15,19,23,27,31) ,          mcolor(black) msymbol(T)  msize(medlarge)) 
				(scatter beta k if p>=0.05 & p<0.10 & k<`nv'+1 & inlist(ord,3,7,11,15,19,23,27,31), mcolor(gs7)   msymbol(T)  msize(medlarge)) 
				(scatter beta k if p>=0.10 & k<`nv'+1 & inlist(ord,3,7,11,15,19,23,27,31),          mcolor(gs10)   msymbol(Th)  msize(medlarge))
				(scatter beta k if p<0.05 & k<`nv'+1 & inlist(ord,4,8,12,16,20,24,28,32) ,          mcolor(black) msymbol(S)  msize(medlarge)) 
				(scatter beta k if p>=0.05 & p<0.10 & k<`nv'+1 & inlist(ord,4,8,12,16,20,24,28,32), mcolor(gs7)   msymbol(S)  msize(medlarge)) 
				(scatter beta k if p>=0.10 & k<`nv'+1 & inlist(ord,4,8,12,16,20,24,28,32),          mcolor(gs10)   msymbol(Sh)  msize(medlarge))
				(scatter beta k if p<0.10 & k<`nv'+1 & inlist(ord,2),          mcolor(ltblue)   msymbol(D)  msize(medlarge))
				(scatter beta k if p>=0.10 & k<`nv'+1 & inlist(ord,2),          mcolor(ltblue)   msymbol(Dh)  msize(medlarge))
				(rcap rcap_hi rcap_lo k if p<0.05 & k<`nv'+1 & !inlist(ord,2,6,10,14,18,22,26,30,34),           `rcap_options_95')
				(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10 & k<`nv'+1 & !inlist(ord,2,6,10,14,18,22,26,30,34), `rcap_options_90')
				(rcap rcap_hi rcap_lo k if p>=0.10 & k<`nv'+1 & !inlist(ord,2,6,10,14,18,22,26,30,34),          `rcap_options_0' )		
				(rcap rcap_hi rcap_lo k if k<`nv'+1 & inlist(ord,2),           lcolor(ltblue))		
				/* */
				(scatter beta k if p<0.05 & k>=`nv'+1 & inlist(ord,1,5,9,13,17,21,25,29,33),           `estimate_options_95' yaxis(2)) 
				(scatter beta k if p>=0.05 & p<0.10 & k>=`nv'+1 & inlist(ord,1,5,9,13,17,21,25,29,33) , `estimate_options_90' yaxis(2)) 
				(scatter beta k if p>=0.10 & k>=`nv'+1 & inlist(ord,1,5,9,13,17,21,25,29,33) ,          `estimate_options_0' yaxis(2))
				(scatter beta k if p<0.05 & k>=`nv'+1 & inlist(ord,3,7,11,15,19,23,27,31,35) ,          mcolor(black) msymbol(T)  msize(medlarge) yaxis(2)) 
				(scatter beta k if p>=0.05 & p<0.10 & k>=`nv'+1 & inlist(ord,3,7,11,15,19,23,27,31,35), mcolor(gs7)   msymbol(T)  msize(medlarge) yaxis(2)) 
				(scatter beta k if p>=0.10 & k>=`nv'+1 & inlist(ord,3,7,11,15,19,23,27,31,35),          mcolor(gs10)   msymbol(Th)  msize(medlarge) yaxis(2))
				(scatter beta k if p<0.05 & k>=`nv'+1 & inlist(ord,4,8,12,16,20,24,28,32,36) ,          mcolor(black) msymbol(S)  msize(medlarge) yaxis(2)) 
				(scatter beta k if p>=0.05 & p<0.10 & k>=`nv'+1 & inlist(ord,4,8,12,16,20,24,28,32,36), mcolor(gs7)   msymbol(S)  msize(medlarge) yaxis(2)) 
				(scatter beta k if p>=0.10 & k>=`nv'+1 & inlist(ord,4,8,12,16,20,24,28,32,36),          mcolor(gs10)   msymbol(Sh)  msize(medlarge) yaxis(2))
				(scatter beta k if p<0.10 & k>=`nv'+1 & inlist(ord,34),          mcolor(ltblue)   msymbol(D)  msize(medlarge) yaxis(2))
				(scatter beta k if p>=0.10 & k>=`nv'+1 & inlist(ord,34),          mcolor(ltblue)   msymbol(Dh)  msize(medlarge) yaxis(2))
				(rcap rcap_hi rcap_lo k if p<0.05 & k>=`nv'+1 & !inlist(ord,2,6,10,14,18,22,26,30,34),           lcolor(red) yaxis(2))
				(rcap rcap_hi rcap_lo k if p>=0.05 & p<0.10 & k>=`nv'+1 & !inlist(ord,2,6,10,14,18,22,26,30,34), lcolor(red) yaxis(2))
				(rcap rcap_hi rcap_lo k if p>=0.10 & k>=`nv'+1 & !inlist(ord,2,6,10,14,18,22,26,30,34),          lcolor(red) yaxis(2))		
				(rcap rcap_hi rcap_lo k if k>=`nv'+1 & inlist(ord,34),           lcolor(ltblue) yaxis(2))		
				, 
				title(" ", `title_options')
				yline(0, `manual_axis' axis(1))
				xtitle("", `xtitle_options')
				ytitle("Not rec. effect",axis(1))
				ytitle("Reincidence effect",axis(2))
				xscale(range(`min_xaxis' `max_xaxis'))
				xscale(noline) /* because manual axis at 0 with yline above) */
				`plotregion' `graphregion'  
				legend(order(4 "SQ" 7 "NSQ" 10 "No Choice") rows(1))
				xline(8.5, lpattern(dot) lwidth(thick) lcolor(black))
				xlabel(1(1)`=`nv'+1', valuelabel angle(vertical) labsize(small))
				;

	#delimit cr
	restore
	graph export "$directorio\Figuras\def_te_`arm'.pdf", replace
	}
