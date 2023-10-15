
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	August. 16, 2023
* Last date of modification: 
* Modifications: - 
* Files used:     
			- 
* Files created:  

* Purpose: Distribution of TE under rank-invariance.

		Under rank invariance, the distribution of treatment effects is point identified and given by 
		\[
		F_\Delta(\delta) = \int_0^1 \mathbbm{1}\{ F_1^{-1}(u) - F_0^{-1}(u)\leq \delta\}\,\mathrm{d}u 
		\]
		where $F_1^{-1}$ and $F_0^{-1}$ are the quantile functions of $Y_1$ and $Y_0$.

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2)

foreach var of varlist apr fc_admin {
	preserve
	replace `var' = -`var'
	xtile perc_a = `var', nq(100)
	keep if perc_a>1

	xtile perc_a_0 = `var' if t_prod==1, nq(1000)
	xtile perc_a_1 = `var' if t_prod==2, nq(1000)

	sort perc* `var'
	duplicates drop perc*, force
	egen perc = rowtotal(perc*)
	gen t = 0 if t_prod==1
	replace t = 1 if t_prod==2

	keep `var' perc t
	reshape wide `var', i(perc) j(t)
	ipolate `var'0 perc, gen(`var'_0)
	ipolate `var'1 perc, gen(`var'_1)

	gen indicator = .
	gen te_rank = .
	gen deltas = .
	*Difference in quantile function
	gen dif = `var'_1-`var'_0
	su dif
	local step = (`r(max)'-`r(min)')/100
	local j = 1
	noi di " "
	noi _dots 0, title(Loop through delta values) reps(100)
	noi di " "
	forvalues delta = `r(min)'(`step')`r(max)' {
		qui {
		replace indicator = (dif<=`delta')
		su indicator
		replace te_rank = `r(mean)' in `j'
		replace deltas = `delta' in `j' 
		local j =  `j'+1
		}
		noi _dots `j' 0	
	}

	* Distribution of TE under rank-invariance
	twoway (line te_rank deltas, lwidth(medthick)), xtitle("{&delta}") ytitle("{&int}1(F{sub:1}{sup:-1}(u)-F{sub:0}{sup:-1}(u){&le}{&delta})du")
	graph export "$directorio/Figuras/te_rankinvariance_`var'.pdf", replace
	restore
}