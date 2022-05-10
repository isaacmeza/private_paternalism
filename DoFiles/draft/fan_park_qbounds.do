
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
* Purpose:  Fan & Park (2010) quantile bounds 

*******************************************************************************/
*/
	
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2)
keep apr fc_admin t_prod 

local var fc_admin

* F^L^{-1}(q) = inf_{u\in [q,1]} {F_1^{-1}(u)-F_0^{-1}(u-q)}
* F^U^{-1}(q) = sup_{u\in [0,q]} {F_1^{-1}(u)-F_0^{-1}(1+u-q)}

*Quantile function
xtile quant_1 = `var' if t_prod==2, nq(1000)
xtile quant_0 = `var' if t_prod==1, nq(1000)

*Properly define quantile function
collapse (max) `var', by(quant_1 quant_0)
gen quant_0_ls = .
gen quant_0_us = .


matrix bounds_q = J(1000, 3, .) 
	
local i = 1
forvalues q = 1(1)1000 {
	di `i'
	qui {
	preserve
	
	*Quantile function
	replace quant_0_ls = quant_0 + `q'
	replace quant_0_us = quant_0_ls - 1000

	stack quant_1 `var' quant_0_ls `var' quant_0_us `var', into(q_ `var'_) wide clear
	keep if !missing(q_)	
	keep `var'_ _stack q_
	reshape wide `var'_ , i(q_) j(_stack)
	
	* Interpolate
	ipolate `var'_1 q_ , gen(F_1) epolate
	ipolate `var'_2 q_ , gen(F_0_ls) epolate
	ipolate `var'_3 q_ , gen(F_0_us) epolate
	
	* F_1^{-1}(u)-F_0^{-1}(u-q)
	gen dif1 = F_1-F_0_ls
	* F_1^{-1}(u)-F_0^{-1}(1+u-q)
	gen dif2 = F_1-F_0_us	
	
	* inf_{u\in [q,1]} {F_1^{-1}(u)-F_0^{-1}(u-q)}
	su dif1 if inrange(q_,`q',1000)
	*F^L^{-1}(q)
	cap matrix bounds_q[`i',1] = `r(min)'
	
	* sup_{u\in [0,q]} {F_1^{-1}(u)-F_0^{-1}(1+u-q)}
	su dif2 if inrange(q_,0,`q')
	*F^U^{-1}(q)
	cap matrix bounds_q[`i',2] = `r(max)'
	
	matrix bounds_q[`i',3] = `q'/1000
	restore
	
	local i = `i' + 1
	}
}

	
svmat bounds_q

twoway (line bounds_q1 bounds_q3) (line bounds_q2 bounds_q3), graphregion(color(white)) ///
legend(order(1 "UB" 2 "LB"))
graph export "$directorio/Figuras/fan_park_qbounds_fc_admin.pdf", replace