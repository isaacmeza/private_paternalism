*! version 1.0.1  14may2022
* To do : Need to implement correct inference in non-parametric estimation
cap program drop rd_plot
program rd_plot, rclass
	version 17.0
	syntax varlist(min=2 max=2) [if] [, Cutoff(real 0) kernel(string) p(integer 1) q(integer 2) bwselect(string) covs(string) vce(string) xtitle(string) ytitle(string) level(integer 90)] 
	
	marksample touse
	gettoken var running_var : varlist

	tempvar res_y_r res_x_r res_y_l res_x_l xq_r xq_l mn_x_r mn_x_l mn_y_r mn_y_l  bs_l bs_c_l bs_r bs_c_r bs_se_l bs_se_r lo_bs_l hi_bs_l lo_bs_r hi_bs_r weights
	
	if ("`kernel'"=="" | "`kernel'"=="triangular") {
		local kernel = "triangular"
		local kernel1 = "triangle"
	}
	else {
		if ("`kernel'"=="uniform")	local kernel1 = "rectangle"
	}
	
	if (`q'<=`p')	local q = `p' + 1
	if ("`bwselect'"=="")	local bwselect = "mserd"
	
	tokenize `vce'	
	local vce1 = "robust"
	local w : word count `vce' 

	if `w' == 1 {
		if ("`1'"=="hc2" | "`1'"=="hc3")	local vce1 = `"`1'"'
	}
	if (`w' == 2 | `w' == 3)  {
		if ("`1'"=="cluster" | "`1'"=="nncluster") local vce1 = "cluster `2'"	
	}

*-------------------------------------------------------------------------------	

	qui {
		
	if "`covs'"!="" {	
	*Bandwidth optimal selection.
	rdbwselect `var' `running_var' if `touse', c(`cutoff') kernel("`kernel'") vce("`vce'") p(`p') q(`q') bwselect("`bwselect'") covs(`covs') 
	local h_r = `e(h_mserd)'
	local h_l = `e(h_mserd)'
	local b_r = `e(b_mserd)'
	local b_l = `e(b_mserd)' 

	
	*Weights for kernel
	if ("`kernel'"=="uniform") {
		gen `weights' = 1 if `touse'
	}
	
	if ("`kernel'"=="triangular") {
		gen `weights' = .
		replace `weights' = (1/(3*`h_l'))*(1 - abs((`running_var'-`cutoff')/(3*`h_l'))) if `touse' & inrange(`running_var', `=`cutoff'-3*`h_l'', `cutoff')
		replace `weights' = (1/(3*`h_r'))*(1 - abs((`running_var'-`cutoff')/(3*`h_r'))) if `touse' &inrange(`running_var', `cutoff', `=`cutoff'+3*`h_r'')
	}
	
	if ("`kernel'"=="epanechnikov") {
		gen `weights' = . if `touse'
		replace `weights' = (1/(3*`h_l'))*3/4*(1 - ((`running_var'-`cutoff')/(3*`h_l'))^2) if `touse' & inrange(`running_var', `=`cutoff'-3*`h_l'', `cutoff')
		replace `weights' = (1/(3*`h_r'))*3/4*(1 - ((`running_var'-`cutoff')/(3*`h_r'))^2) if `touse' & inrange(`running_var', `cutoff', `=`cutoff'+3*`h_r'')	
	}	
	

	*Residual computation 
		*Above threshold
	reg `var' `covs' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r'')
	predict `res_y_r' if e(sample), residual
	su `var' if e(sample) 
	replace `res_y_r' = `res_y_r' + `r(mean)'

	reg `running_var' `covs' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r'')
	predict `res_x_r' if e(sample), residual 
	su `running_var' if e(sample) 
	replace `res_x_r' = `res_x_r' + `r(mean)'
		*Below threshold
	reg `var' `covs' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff')
	predict `res_y_l' if e(sample), residual
	su `var' if e(sample) 
	replace `res_y_l' = `res_y_l' + `r(mean)'

	reg `running_var' `covs' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff')
	predict `res_x_l' if e(sample), residual 
	su `running_var' if e(sample) 
	replace `res_x_l' = `res_x_l' + `r(mean)'


	*Binning computation for binscatter
		*Above threshold
	xtile `xq_r' = `res_x_r', nq(20)
	bysort `xq_r' : egen `mn_x_r' = mean(`res_x_r')  if !missing(`xq_r')
	bysort `xq_r' : egen `mn_y_r' = mean(`res_y_r') if !missing(`xq_r')
		*Below threshold
	xtile `xq_l' = `res_x_l', nq(20)
	bysort `xq_l' : egen `mn_x_l' = mean(`res_x_l')  if !missing(`xq_l')
	bysort `xq_l' : egen `mn_y_l' = mean(`res_y_l')  if !missing(`xq_l')


	*Bspline fitting
		*Above threshold
	cap drop _bs_r*		
	bspline if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), xvar(`running_var') knots(`cutoff' `=`cutoff'+`h_r'' `=`cutoff'+2*`h_r'' `=`cutoff'+3*`h_r'') p(`p') gen(_bs_r)
			*Simple
	reg `var' _bs_r* if `touse' & inrange(`running_var',`cutoff', `=`cutoff'+3*`h_r'') [aw = `weights'] , noconstant vce(`vce1')
	cap drop `bs_r'
	predict `bs_r' if e(sample)
	predict `bs_se_r' if e(sample), stdp
			*CI
	gen `hi_bs_r' = `bs_r' + invnormal(1-`=(100-`level')'/200)*`bs_se_r'
	gen `lo_bs_r' = `bs_r' - invnormal(1-`=(100-`level')'/200)*`bs_se_r'
			*Covariates
	reg `var' _bs_r* `covs' if `touse' & inrange(`running_var',`cutoff', `=`cutoff'+3*`h_r'') [aw = `weights'] , noconstant vce(`vce1')
	cap drop `bs_c_r'
	gen `bs_c_r' = _bs_r1*e(b)[1,1] + _bs_r2*e(b)[1,2] + _bs_r3*e(b)[1,3] + _bs_r4*e(b)[1,4]  if e(sample)
	local j = 5
	foreach varc of varlist `covs' {
		su `varc' if e(sample), meanonly
		local pr`j' = `r(mean)'*e(b)[1,`j']
		replace `bs_c_r' = `bs_c_r' + `pr`j''
		local j = `j' + 1
	}
	cap drop _bs_r*	

		
		*Below threshold
	cap drop _bs_l*	
	bspline if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), xvar(`running_var') knots(`=`cutoff'-3*`h_l'' `=`cutoff'-2*`h_l'' `=`cutoff'-`h_l'' `cutoff') p(`p') gen(_bs_l)
			*Simple
	reg `var' _bs_l* if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff') [aw = `weights'] , noconstant vce(`vce1')
	cap drop `bs_l'
	predict `bs_l' if e(sample)
	predict `bs_se_l' if e(sample), stdp
			*CI
	gen `hi_bs_l' = `bs_l' + invnormal(1-`=(100-`level')'/200)*`bs_se_l'
	gen `lo_bs_l' = `bs_l' - invnormal(1-`=(100-`level')'/200)*`bs_se_l'
			*Covariates
	reg `var' _bs_l* `covs' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff') [aw = `weights'] , noconstant vce(`vce1')
	cap drop `bs_c_l'
	gen `bs_c_l' = _bs_l1*e(b)[1,1] + _bs_l2*e(b)[1,2] + _bs_l3*e(b)[1,3] + _bs_l4*e(b)[1,4] if e(sample)
	local j = 5
	foreach varc of varlist `covs' {
		su `varc' if e(sample), meanonly
		local pr`j' = `r(mean)'*e(b)[1,`j']
		replace `bs_c_l' = `bs_c_l' + `pr`j''
		local j = `j' + 1
	}
	cap drop _bs_l*

	


*-------------------------------------------------------------------------------
	*	RD graph
	noi twoway (scatter `mn_y_l' `mn_x_l', msymbol(O) msize(small) color(navy%70) xline(`cutoff', lcolor(black))) ///
			(scatter `mn_y_r' `mn_x_r' , msymbol(O) msize(small) color(maroon%70)) ///
			(lpoly  `mn_y_l' `mn_x_l' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff') , kernel(`kernel1') deg(`p') bw(`=`h_l'/2') lpattern(dot) lcolor(navy)) ///
			(lpoly  `mn_y_r' `mn_x_r' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r'') , kernel(`kernel1') deg(`p') bw(`=`h_r'/2') lpattern(dot) lcolor(maroon)) ///
			(lpolyci `var' `running_var' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), kernel(`kernel1') deg(`p') bw(`=`h_l'/2') lpattern(dash) lcolor(navy) level(`level') ciplot(rarea) acolor(navy%10) fintensity(inten70)) ///
			(lpolyci `var' `running_var' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), kernel(`kernel1') deg(`p') bw(`=`h_r'/2') lpattern(dash) lcolor(maroon) level(`level') ciplot(rarea) acolor(maroon%10) fintensity(inten70)) ///
			(rarea `lo_bs_l' `hi_bs_l' `running_var' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), sort color(navy%15)) ///
			(rarea `lo_bs_r' `hi_bs_r' `running_var' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), sort color(maroon%15)) ///		
			(line `bs_l' `running_var' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), sort lpattern(solid) lcolor(navy)) ///
			(line `bs_r' `running_var' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), sort lpattern(solid) lcolor(maroon)) ///		
			(line `bs_c_l' `running_var' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), sort lpattern(dash_dot) lcolor(navy)) ///
			(line `bs_c_r' `running_var' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), sort lpattern(dash_dot) lcolor(maroon)) ///
			, graphregion(color(white)) xtitle("`xtitle'") ytitle("`ytitle'") legend(off) 
	}
	else {
	*Bandwidth optimal selection.
	rdbwselect `var' `running_var' if `touse', c(`cutoff') kernel("`kernel'") vce("`vce'") p(`p') q(`q') bwselect("`bwselect'") 
	local h_r = `e(h_mserd)'
	local h_l = `e(h_mserd)'
	local b_r = `e(b_mserd)'
	local b_l = `e(b_mserd)' 

	
	*Weights for kernel
	if ("`kernel'"=="uniform") {
		gen `weights' = 1
	}
	
	if ("`kernel'"=="triangular") {
		gen `weights' = .
		replace `weights' = (1/(3*`h_l'))*(1 - abs((`running_var'-`cutoff')/(3*`h_l'))) if inrange(`running_var', `=`cutoff'-3*`h_l'', `cutoff')
		replace `weights' = (1/(3*`h_r'))*(1 - abs((`running_var'-`cutoff')/(3*`h_r'))) if inrange(`running_var', `cutoff', `=`cutoff'+3*`h_r'')
	}
	
	if ("`kernel'"=="epanechnikov") {
		gen `weights' = .
		replace `weights' = (1/(3*`h_l'))*3/4*(1 - ((`running_var'-`cutoff')/(3*`h_l'))^2) if inrange(`running_var', `=`cutoff'-3*`h_l'', `cutoff')
		replace `weights' = (1/(3*`h_r'))*3/4*(1 - ((`running_var'-`cutoff')/(3*`h_r'))^2) if inrange(`running_var', `cutoff', `=`cutoff'+3*`h_r'')	
	}	


	*Binning computation for binscatter
		*Above threshold
	xtile `xq_r' = `running_var' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), nq(20)
	bysort `xq_r' : egen `mn_x_r' = mean(`running_var')  if !missing(`xq_r')
	bysort `xq_r' : egen `mn_y_r' = mean(`var') if !missing(`xq_r')
		*Below threshold
	xtile `xq_l' = `running_var' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), nq(20)
	bysort `xq_l' : egen `mn_x_l' = mean(`running_var')  if !missing(`xq_l')
	bysort `xq_l' : egen `mn_y_l' = mean(`var')  if !missing(`xq_l')


	*Bspline fitting
		*Above threshold
	cap drop _bs_r*		
	bspline if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), xvar(`running_var') knots(`cutoff' `=`cutoff'+`h_r'' `=`cutoff'+2*`h_r'' `=`cutoff'+3*`h_r'') p(`p') gen(_bs_r)
			*Simple
	reg `var' _bs_r* if `touse' & inrange(`running_var',`cutoff', `=`cutoff'+3*`h_r'') [aw = `weights'] , noconstant vce(`vce1')
	cap drop `bs_r'
	predict `bs_r' if e(sample)
	predict `bs_se_r' if e(sample), stdp
			*CI
	gen `hi_bs_r' = `bs_r' + invnormal(1-`=(100-`level')'/200)*`bs_se_r'
	gen `lo_bs_r' = `bs_r' - invnormal(1-`=(100-`level')'/200)*`bs_se_r'
	cap drop _bs_r*	

		
		*Below threshold
	cap drop _bs_l*	
	bspline if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), xvar(`running_var') knots(`=`cutoff'-3*`h_l'' `=`cutoff'-2*`h_l'' `=`cutoff'-`h_l'' `cutoff') p(`p') gen(_bs_l)
			*Simple
	reg `var' _bs_l* if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff') [aw = `weights'] , noconstant vce(`vce1')
	cap drop `bs_l'
	predict `bs_l' if e(sample)
	predict `bs_se_l' if e(sample), stdp
			*CI
	gen `hi_bs_l' = `bs_l' + invnormal(1-`=(100-`level')'/200)*`bs_se_l'
	gen `lo_bs_l' = `bs_l' - invnormal(1-`=(100-`level')'/200)*`bs_se_l'
	cap drop _bs_l*

	


*-------------------------------------------------------------------------------
	*	RD graph
	noi twoway (scatter `mn_y_l' `mn_x_l', msymbol(O) msize(small) color(navy%70) xline(`cutoff', lcolor(black))) ///
			(scatter `mn_y_r' `mn_x_r' , msymbol(O) msize(small) color(maroon%70)) ///
			(lpolyci `var' `running_var' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), kernel(`kernel1') deg(`p') bw(`=`h_l'/2') lpattern(dash) lcolor(navy) level(`level') ciplot(rarea) acolor(navy%10) fintensity(inten70)) ///
			(lpolyci `var' `running_var' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), kernel(`kernel1') deg(`p') bw(`=`h_r'/2') lpattern(dash) lcolor(maroon) level(`level') ciplot(rarea) acolor(maroon%10) fintensity(inten70)) ///
			(rarea `lo_bs_l' `hi_bs_l' `running_var' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), sort color(navy%15)) ///
			(rarea `lo_bs_r' `hi_bs_r' `running_var' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), sort color(maroon%15)) ///		
			(line `bs_l' `running_var' if `touse' & inrange(`running_var',`=`cutoff'-3*`h_l'',`cutoff'), sort lpattern(solid) lcolor(navy)) ///
			(line `bs_r' `running_var' if `touse' & inrange(`running_var',`cutoff',`=`cutoff'+3*`h_r''), sort lpattern(solid) lcolor(maroon)) ///		
			, graphregion(color(white)) xtitle("`xtitle'") ytitle("`ytitle'") legend(off) 
					
	}
	
	}
	
end
