
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	April. 21, 2022
* Last date of modification: April. 28, 2022
* Modifications: Add Inference Bounds	
* Files used:     
		- Master.dta
* Files created:  
* Purpose:  Fan & Park (2010) bounds 

*******************************************************************************/
*/
	
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2)
keep apr def_c fc_admin t_prod $C0 edad  faltas val_pren_std genero masqueprepa
replace fc_admin =log(fc_admin)

local cov_partition = 6
local delta_partition = 100
local var apr

* Partition of covariate space
cluster kmedians $C0 edad  faltas val_pren_std genero masqueprepa , k(`cov_partition') gen(_clus_1)
tab _clus_1, matcell(freq)
count if !missing(_clus_1)
forvalues c = 1/`cov_partition' {
	mat freq[`c',1] = freq[`c',1]/`r(N)'
}

* Y_1 = [a,b], Y_0 = [c, d]
su `var' if t_prod==2
global n1 = r(N)
global a_ = r(min)
global b_ = r(max)
su `var' if t_prod==1
global n0 = r(N)
global c_ = r(min)
global d_ = r(max)
* Define a partition of [a-d, b-c] 
*range delta_range `=${a_}-${d_}' `=${b_}-${c_}' `=`delta_partition'+1'
*replace delta_range = . if _n==`=`delta_partition'+1'
gen delta_range = -10 in 1
replace delta_range = 0 in 2
replace delta_range = 10 in 3


* For any \delta\in [a-d, b-c] we define Y_\delta = [a,b] \cap [c+\delta, d+\delta]
* F^L(\delta) = max {sup_{Y_\delta} {F_1(y)-F_0(y-\delta)} , 0}
* F^U(\delta) = 1 + min {inf_{Y_\delta} {F_1(y)-F_0(y-\delta)} , 0}

matrix bounds = J(`delta_partition', 2, .) 
matrix sigma_2 = J(`delta_partition', 2, .) 
matrix M_delta = J(`delta_partition', 2, .) 

matrix bounds_cond = J(`delta_partition', 2, 0) 
matrix sigma_2_cond = J(`delta_partition', 2, 0) 

local i = 1
levelsof delta_range, local(levels) 
foreach delta of local levels {
	di `i'
	qui {
	preserve
	gen `var'_s = `var' + `delta' if t_prod==1
	
	*ECDF
	cumul `var' if t_prod==2, gen(`var'_1)
	cumul `var'_s if t_prod==1, gen(`var'_0_s)
	stack  `var'_1 `var'  `var'_0_s `var'_s, into(c `var'_) wide clear
	keep if !missing(`var'_1) | !missing(`var'_0_s)	
	sort `var'_
	
	* Interpolate
	ipolate `var'_1 `var'_, gen(F_1) epolate
	ipolate `var'_0_s `var'_, gen(F_0_s) epolate
	
	replace F_0_s = 0 if F_0_s<0
	replace F_1 = 0 if F_1<0
	replace F_0_s = 1 if F_0_s>1
	replace F_1 = 1 if F_1>1
	
	* F_1(y)-F_0(y-\delta)
	gen double dif = F_1-F_0_s
	* Y_\delta = [a,b] \cap [c+\delta, d+\delta]
	local mn = max(${a_}, ${c_}+`delta')
	local Mx = min(${b_}, ${d_}+ `delta')

	* sup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  (resp. inf)
	cap drop nobs
	gen nobs = _n
	su dif if inrange(`var'_,`mn',`Mx')
	
	if `r(N)'!=0 {
		gen double Mdelta = `r(max)'
		gen double mdelta = `r(min)'
		
		* M(delta) = sup_{Y_\delta} {F_1(y)-F_0(y-\delta)}
		matrix M_delta[`i',1] = Mdelta[1]
		* m(delta) = inf_{Y_\delta} {F_1(y)-F_0(y-\delta)}
		matrix M_delta[`i',2] = mdelta[1]
			
		* ysup_d = argsup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  
		su nobs if abs(dif-Mdelta)<1e-10
		local ysup_d = `r(min)'
		* sigma^L^2 = F_1(ysup_d)[1-F_1(ysup_d)]+(n1/n0)F_0(ysup_d-delta)[1-F_0(ysup_d-delta)]
		matrix sigma_2[`i',1] = F_1[`ysup_d']*(1-F_1[`ysup_d'])+(${n1}/${n0})*F_0_s[`ysup_d']*(1-F_0_s[`ysup_d'])
		
		* yinf_d = argsinf_{Y_\delta} {F_1(y)-F_0(y-\delta)}  
		su nobs if abs(dif-mdelta)<1e-10
		local yinf_d = `r(min)'
		* sigma^U^2 = F_1(yinf_d)[1-F_1(yinf_d)]+(n1/n0)F_0(yinf_d-delta)[1-F_0(yinf_d-delta)]
		matrix sigma_2[`i',2] = F_1[`yinf_d']*(1-F_1[`yinf_d'])+(${n1}/${n0})*F_0_s[`yinf_d']*(1-F_0_s[`yinf_d'])
		
		*F^L(\delta)
		cap matrix bounds[`i',1] = max(Mdelta[1],0)
		*F^U(\delta)
		cap matrix bounds[`i',2] = 1 + min(mdelta[1],0)
		}
	restore

	*___________________________________________________________________________
	*___________________________________________________________________________
	
	
		* conditional
	forvalues c = 1/`cov_partition' {
		preserve
		gen `var'_s = `var' + `delta' if t_prod==1
		
		*ECDF
		cumul `var' if t_prod==2 & _clus_1==`c', gen(`var'_1_`c')
		cumul `var'_s if t_prod==1 & _clus_1==`c', gen(`var'_0_s_`c')
		stack  `var'_1_`c' `var'  `var'_0_s_`c' `var'_s, into(c_c`c' `var'_c`c') wide clear
		keep if !missing(`var'_1_`c') | !missing(`var'_0_s_`c')	
		sort `var'_c`c'
		
		* Interpolate
		ipolate `var'_1_`c' `var'_c`c', gen(F_1_c`c') epolate
		ipolate `var'_0_s_`c' `var'_c`c', gen(F_0_s_c`c') epolate
		
		replace F_0_s_c`c' = 0 if F_0_s_c`c'<0
		replace F_1_c`c' = 0 if F_1_c`c'<0
		replace F_0_s_c`c' = 1 if F_0_s_c`c'>1
		replace F_1_c`c' = 1 if F_1_c`c'>1
		
		* Lambda calculation from Assumption 1
		count if _stack==1
		local n1_c = `r(N)'
		count if _stack==2
		local n0_c = `r(N)'
		
		* F_1(y)-F_0(y-\delta)
		gen double dif = F_1_c`c'-F_0_s_c`c'
		* Y_\delta = [a,b] \cap [c+\delta, d+\delta]
		local mn = max(${a_}, ${c_}+`delta')
		local Mx = min(${b_}, ${d_}+ `delta')

		* sup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  (resp. inf)
		cap drop nobs
		gen nobs = _n
		su dif if inrange(`var'_c`c',`mn',`Mx')
		
		if `r(N)'!=0 {
			gen double Mdelta = `r(max)'
			gen double mdelta = `r(min)'
			
			* ysup_d = argsup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  
			su nobs if abs(dif-Mdelta)<1e-10
			local ysup_d = `r(min)'
			* sigma^L^2 = F_1(ysup_d)[1-F_1(ysup_d)]+(n1/n0)F_0(ysup_d-delta)[1-F_0(ysup_d-delta)]
			matrix sigma_2_cond[`i',1] = sigma_2_cond[`i',1] + freq[`c',1]*(F_1_c`c'[`ysup_d']*(1-F_1_c`c'[`ysup_d'])+(`n1_c'/`n0_c')*F_0_s_c`c'[`ysup_d']*(1-F_0_s_c`c'[`ysup_d']))
			
			* yinf_d = argsinf_{Y_\delta} {F_1(y)-F_0(y-\delta)}  
			su nobs if abs(dif-mdelta)<1e-10
			local yinf_d = `r(min)'
			* sigma^U^2 = F_1(yinf_d)[1-F_1(yinf_d)]+(n1/n0)F_0(yinf_d-delta)[1-F_0(yinf_d-delta)]
			matrix sigma_2_cond[`i',2] = sigma_2_cond[`i',2] + freq[`c',1]*(F_1_c`c'[`yinf_d']*(1-F_1_c`c'[`yinf_d'])+(`n1_c'/`n0_c')*F_0_s_c`c'[`yinf_d']*(1-F_0_s_c`c'[`yinf_d']))
		
			*F^L(\delta)
			cap matrix bounds_cond[`i',1] = bounds_cond[`i',1] + freq[`c',1]*max(Mdelta[1],0)
			*F^U(\delta)
			cap matrix bounds_cond[`i',2] = bounds_cond[`i',2] + freq[`c',1]*(1 + min(mdelta[1],0))
		}
		restore
		}
		
	local i = `i' + 1
	}
}

	
svmat bounds
svmat sigma_2
svmat M_delta
svmat bounds_cond
svmat sigma_2_cond

*Bounds
gen lb = max(bounds1, bounds_cond1) if !missing(bounds1) & !missing(bounds_cond1)
replace lb = 1 if lb[_n-1]==1 & !missing(lb)
gen ub = min(bounds2, bounds_cond2) if !missing(bounds2) & !missing(bounds_cond2)
replace ub = 1 if ub[_n-1]==1 & !missing(ub)

gen sigma_l = min(sqrt(sigma_21),sqrt(sigma_2_cond1)) if !missing(sigma_21) & !missing(sigma_2_cond1)
gen sigma_u = min(sqrt(sigma_22),sqrt(sigma_2_cond2)) if !missing(sigma_22) & !missing(sigma_2_cond2)

count if t_prod==2
local n1 = `r(N)'

foreach signif in 5 10 {
	
*Lower CI
gen lb_l`signif' = lb
replace lb_l`signif' = lb_l`signif' - invnormal(1-`signif'/100)*sigma_l/sqrt(`n1') if M_delta1<=0
replace lb_l`signif' = lb_l`signif' - invnormal(1-`signif'/200)*sigma_l/sqrt(`n1') if M_delta1>0
replace lb_l`signif' = 0 if lb_l`signif'<0
replace lb_l`signif' = 1 if lb_l`signif'>1

gen ub_l`signif' = ub
replace ub_l`signif' = ub_l`signif' - invnormal(1-`signif'/100)*sigma_u/sqrt(`n1') if M_delta2>=0
replace ub_l`signif' = ub_l`signif' - invnormal(1-`signif'/200)*sigma_u/sqrt(`n1') if M_delta2<0
replace ub_l`signif' = 0 if ub_l`signif'<0
replace ub_l`signif' = 1 if ub_l`signif'>1

*Higher CI
gen lb_h`signif' = lb
replace lb_h`signif' = lb_h`signif' + invnormal(1-`signif'/100)*sigma_l/sqrt(`n1') if M_delta1<=0
replace lb_h`signif' = lb_h`signif' + invnormal(1-`signif'/200)*sigma_l/sqrt(`n1') if M_delta1>0
replace lb_h`signif' = 0 if lb_h`signif'<0
replace lb_h`signif' = 1 if lb_h`signif'>1

gen ub_h`signif' = ub
replace ub_h`signif' = ub_h`signif' + invnormal(1-`signif'/100)*sigma_u/sqrt(`n1') if M_delta2>=0
replace ub_h`signif' = ub_h`signif' + invnormal(1-`signif'/200)*sigma_u/sqrt(`n1') if M_delta2<0
replace ub_h`signif' = 0 if ub_h`signif'<0
replace ub_h`signif' = 1 if ub_h`signif'>1

}

if "`var'"=="des_c" {
	twoway (rarea lb_l5 lb_h5 delta_range, color(navy%25)) ///
		(rarea ub_l5 ub_h5 delta_range, color(maroon%25)) ///
		(rarea lb_l10 lb_h10 delta_range, color(navy%35)) ///
		(rarea ub_l10 ub_h10 delta_range, color(maroon%35)) ///
		(line lb delta_range, xline(0, lpattern(dot) lcolor(gs5)) color(navy)) ///
		(line ub delta_range, color(maroon)) ///
		, graphregion(color(white)) legend(order(5 "Lower bound" 6 "Upper bound")) ///
		xtitle("{&Delta} Default")
	graph export "$directorio/Figuras/fan_park_bounds_`var'.pdf", replace
}

if "`var'"=="apr" {
	twoway (rarea lb_l5 lb_h5 delta_range, color(navy%25)) ///
		(rarea ub_l5 ub_h5 delta_range, color(maroon%25)) ///
		(rarea lb_l10 lb_h10 delta_range, color(navy%35)) ///
		(rarea ub_l10 ub_h10 delta_range, color(maroon%35)) ///
		(line lb delta_range, xline(0, lpattern(dot) lcolor(gs5)) color(navy)) ///
		(line ub delta_range, color(maroon)) ///
		, graphregion(color(white)) legend(order(5 "Lower bound" 6 "Upper bound")) ///
		xtitle("{&Delta} APR")
	*graph export "$directorio/Figuras/fan_park_bounds_`var'.pdf", replace
}

if "`var'"=="fc_admin" {
	twoway (rarea lb_l5 lb_h5 delta_range, color(navy%25)) ///
		(rarea ub_l5 ub_h5 delta_range, color(maroon%25)) ///
		(rarea lb_l10 lb_h10 delta_range, color(navy%35)) ///
		(rarea ub_l10 ub_h10 delta_range, color(maroon%35)) ///
		(line lb delta_range, xline(0, lpattern(dot) lcolor(gs5)) color(navy)) ///
		(line ub delta_range, color(maroon)) ///
		, graphregion(color(white)) legend(order(5 "Lower bound" 6 "Upper bound")) ///
		xtitle("{&Delta} log(FC)")
	graph export "$directorio/Figuras/fan_park_bounds_`var'.pdf", replace
}