
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	April. 21, 2022
* Last date of modification: 
* Modifications: 		
* Files used:     
		- Master.dta
* Files created:  
* Purpose:  Fan & Park (2010) bounds 

*******************************************************************************/
*/
	
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2)
keep apr des_c fc_admin t_prod $C0 edad  faltas val_pren_std genero masqueprepa

local cov_partition = 5
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
global a_ = r(min)
global b_ = r(max)
su `var' if t_prod==1
global c_ = r(min)
global d_ = r(max)
* Define a partition of [a-d, b-c] 
range delta_range `=${a_}-${d_}' `=${b_}-${c_}' `=`delta_partition'+1'
replace delta_range = . if _n==`=`delta_partition'+1'

* For any \delta\in [a-d, b-c] we define Y_\delta = [a,b] \cap [c+\delta, d+\delta]
* F^L(\delta) = max {sup_{Y_\delta} {F_1(y)-F_0(y-\delta)} , 0}
* F^U(\delta) = 1 + min {inf_{Y_\delta} {F_1(y)-F_0(y-\delta)} , 0}

matrix bounds = J(`delta_partition', 2, .) 
matrix bounds_cond = J(`delta_partition', 2, 0) 

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
	gen dif = F_1-F_0_s
	* Y_\delta = [a,b] \cap [c+\delta, d+\delta]
	local mn = max(${a_}, ${c_}+`delta')
	local Mx = min(${b_}, ${d_}+ `delta')

	* sup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  (resp. inf)
	su dif if inrange(`var'_,`mn',`Mx')

	*F^L(\delta)
	cap matrix bounds[`i',1] = max(`r(max)',0)
	*F^U(\delta)
	cap matrix bounds[`i',2] = 1 + min(`r(min)',0)
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
		
		* F_1(y)-F_0(y-\delta)
		gen dif = F_1_c`c'-F_0_s_c`c'
		* Y_\delta = [a,b] \cap [c+\delta, d+\delta]
		local mn = max(${a_}, ${c_}+`delta')
		local Mx = min(${b_}, ${d_}+ `delta')

		* sup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  (resp. inf)
		su dif if inrange(`var'_c`c',`mn',`Mx')

		*F^L(\delta)
		cap matrix bounds_cond[`i',1] = bounds_cond[`i',1] + freq[`c',1]*max(`r(max)',0)
		*F^U(\delta)
		cap matrix bounds_cond[`i',2] = bounds_cond[`i',2] + freq[`c',1]*(1 + min(`r(min)',0))
		restore
		}
		
	local i = `i' + 1
	}
}

	
svmat bounds
svmat bounds_cond


twoway (line bounds1 delta_range, xline(0)) (line bounds2 delta_range) ///
(line bounds_cond1 delta_range, xline(0)) (line bounds_cond2 delta_range), graphregion(color(white)) ///
legend(order( 1 "LB" 2 "UB"  3 "LB covariates" 4 "UB covariates"  ))
graph export "$directorio/Figuras/fan_park_bounds_apr.pdf", replace