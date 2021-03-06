
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	October. 5, 2021
* Last date of modification:  April. 22, 2022
* Modifications: ELiminate t-test difference of means in plot.		
* Files used:     
		- 
* Files created:  

* Purpose: Difference between TOT-TUT using information from the instrumental forest.

*******************************************************************************/
*/

import delimited "$directorio/_aux/tot_instr_forest.csv", clear
tempfile temp
rename inst_hat_oobpredictions inst_hat_1
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_1
save `temp'

import delimited "$directorio/_aux/tut_instr_forest.csv", clear
rename inst_hat_oobpredictions inst_hat_0
rename inst_hat_oobvarianceestimates inst_oobvarianceestimates_0
merge 1:1 prenda using `temp'


*Difference of means test
ttest inst_hat_1 == inst_hat_0
local m1 = round(`r(mu_1)', 0.01)
local m0 = round(`r(mu_2)', 0.01)

local hi1 = `r(mu_1)' + 1.96*`r(sd_1)'/sqrt(`r(N_1)')
local hi0 = `r(mu_2)' + 1.96*`r(sd_2)'/sqrt(`r(N_2)')
local lo1 = `r(mu_1)' - 1.96*`r(sd_1)'/sqrt(`r(N_1)')
local lo0 = `r(mu_2)' - 1.96*`r(sd_2)'/sqrt(`r(N_2)')

*Difference between TOT-TUT
gen dif  = inst_hat_1 - inst_hat_0
twoway (hist dif,  percent graphregion(color(white)) color(navy) lcolor(black) xtitle("TOT-TUT")) 
graph export "$directorio/Figuras/dif_tot_tut.pdf", replace



reshape long inst_hat_, i(prenda) j(tot)

*cumulative distribution of "TOT & TUT" 
*ECDF
cumul inst_hat_ if tot==1, gen(t1)
cumul inst_hat_ if tot==0, gen(t0)

*Function to obtain significance difference region
distcomp inst_hat_ , by(tot) alpha(0.1) p noplot
mat ranges = r(rej_ranges)

*To plot both ECDF
stack  t1 inst_hat_  t0 inst_hat_, into(c inst) ///
	wide clear
keep if !missing(t1) | !missing(t0)
tempfile temp
save `temp'
*Get difference of the CDF
duplicates drop inst _stack, force
keep c inst _stack
reshape wide c, i(inst) j(_stack)
*Interpolate
ipolate c2 inst, gen(c2_i) epolate
ipolate c1 inst, gen(c1_i) epolate
gen dif=c2_i-c1_i
tempfile temp_dif
save `temp_dif'
use `temp', clear
merge m:1 inst using `temp_dif', nogen 
*Significant region
gen sig_range = .
local rr = rowsof(ranges)
forvalues i=1/`rr' {
	local lo = ranges[`i',1]
	local hi = ranges[`i',2]
	if !missing(`lo') {
		replace sig_range = 0.01 if inrange(inst,`lo',`hi')
	}
	}
	

*Plot
twoway (line t1 inst , lcolor(black) lpattern(solid) sort ylab(, grid)) ///
	(line t0 inst , lcolor(black) lpattern(dash) sort ylab(, grid)) ///
	(line dif inst , lcolor(black) lpattern(dot) sort ylab(, grid)) ///
	(scatter sig_range inst , msymbol(Oh) msize(tiny) color(gs12)) ///
	, ///
	legend(order(1 "TOT" 2 "TUT" 3 "TOT-TUT") pos(6) rows(1)) xtitle("T.Effect") graphregion(color(white)) 
graph export "$directorio/Figuras/cdf_tot_tut.pdf", replace


