
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	July. 4, 2023
* Last date of modification: 
* Modifications: - 
* Files used:     
			- 
* Files created:  

* Purpose: FOSD of ECDF

*******************************************************************************/
*/

use "$directorio/DB/Master.dta", clear
replace apr = -apr
replace fc_admin = -fc_admin

foreach var of varlist fc_admin apr {
	preserve 
		*Histograms of financial cost
		xtile perc_a_d = `var', nq(100)

		*cumulative distribution of "realized financial cost" 
		*for the sq contract and the fee-forcing contract
		*ECDF
		cumul `var' if perc_a_d>=5 & pro_2==1, gen(fc_cdf_1)
		cumul `var' if perc_a_d>=5 & pro_2==0, gen(fc_cdf_0)
		*Function to obtain significance difference region
		distcomp `var' if perc_a_d>5 , by(pro_2) alpha(0.1) p noplot
		mat ranges = r(rej_ranges)

		*To plot both ECDF
		stack  fc_cdf_1 `var'  fc_cdf_0 `var', into(c fc) ///
			wide clear
		keep if !missing(fc_cdf_1) | !missing(fc_cdf_0)
		tempfile temp
		save `temp'
		*Get difference of the CDF
		duplicates drop fc _stack, force
		keep c fc _stack
		reshape wide c, i(fc) j(_stack)
		*Interpolate
		ipolate c2 fc, gen(c2_i) epolate
		ipolate c1 fc, gen(c1_i) epolate
		gen dif=c2_i-c1_i
		tempfile temp_dif
		save `temp_dif'
		use `temp', clear
		merge m:1 fc using `temp_dif', nogen 
		*Signifficant region
		gen sig_range = .
		local rr = rowsof(ranges)
		forvalues i=1/`rr' {
			local lo = ranges[`i',1]
			local hi = ranges[`i',2]
			if !missing(`lo') {
				replace sig_range = 0.01 if inrange(fc,`lo',`hi')
			}
			}
		*Plot
		local vtext : variable label `var' 
		su fc, d	
		twoway (line fc_cdf_1 fc if fc<=`r(p95)', lpattern(solid) lcolor(black) ///
			sort ylab(, grid)) ///
			(line fc_cdf_0 fc if fc<=`r(p95)', lpattern(dash) lcolor(black) ///
			sort ylab(, grid)) ///
			(line dif fc if fc<=`r(p95)' & fc>=`r(p1)', lpattern(dot) lcolor(black) ///
			sort ylab(, grid)) ///
			(scatter sig_range fc if fc<=`r(p95)', msymbol(Oh) msize(tiny) color(gs12)), ///
			ytitle("") xtitle("`vtext'") ///
			legend(order(1 "Forced commitment" 2 "Control" 3 "Control-Forced") pos(6) rows(1))graphregion(color(white)) 
		graph export "$directorio/Figuras/cdf_`var'.pdf", replace
	restore
}