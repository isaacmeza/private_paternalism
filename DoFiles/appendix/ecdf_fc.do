/*
Empirical Financial cost cumulative distribution
*/

use "$directorio/DB/Master.dta", clear

*Variable gen
gen fc_prestamo = (fc_admin/prestamo)*100

*Histograms of financial cost
xtile perc_a_d = fc_admin, nq(100)

*cumulative distribution of "realized financial cost" 
*for the sq contract and the fee-forcing contract
*ECDF
cumul fc_admin if perc_a_d<=99 & pro_2==1, gen(fc_cdf_1)
cumul fc_admin if perc_a_d<=99 & pro_2==0, gen(fc_cdf_0)
*Function to obtain significance difference region
distcomp fc_admin if perc_a_d<=99 , by(pro_2) alpha(0.1) p noplot
mat ranges = r(rej_ranges)

*To plot both ECDF
stack  fc_cdf_1 fc_admin  fc_cdf_0 fc_admin, into(c fc) ///
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
su fc, d	
twoway (line fc_cdf_1 fc if fc<=`r(p95)', lpattern(solid) lcolor(black) ///
	sort ylab(, grid)) ///
	(line fc_cdf_0 fc if fc<=`r(p95)', lpattern(dash) lcolor(black) ///
	sort ylab(, grid)) ///
	(line dif fc if fc<=`r(p95)', lpattern(dot) lcolor(black) ///
	sort ylab(, grid)) ///
	(scatter sig_range fc if fc<=`r(p95)', msymbol(Oh) msize(tiny) color(gs12)), ///
	ytitle("") xtitle("Pesos") ///
	legend(order(1 "Fee-forcing" 2 "SQ" 3 "SQ-Fee") pos(6) rows(1)) xtitle("Pesos") graphregion(color(white)) 
graph export "$directorio/Figuras/cdf_fc_pro_2.pdf", replace
