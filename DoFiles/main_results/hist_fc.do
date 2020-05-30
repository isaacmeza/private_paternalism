/*
Financial cost distribution
*/

use "$directorio/DB/Master.dta", clear

*Variable gen
gen fc_prestamo = (fc_admin_disc/prestamo)*100

*Histograms of financial cost
xtile perc_a = fc_admin, nq(100)
xtile perc_a_d = fc_admin_d, nq(100)
xtile perc_s = fc_survey, nq(100)
xtile perc_p = fc_prestamo, nq(100)


twoway (hist fc_admin_disc if perc_a<=99 & des_c==0, w(500) percent lwidth(medthick) lcolor(ltblue) color(ltblue)) ///
		(hist fc_admin_disc if perc_a<=99 & des_c==1, w(500) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec." )) xtitle("Financial Cost") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_fc.pdf", replace

*cumulative distribution of "realized financial cost" 
*for the sq contract and the fee-forcing contract
*ECDF
cumul fc_admin_disc if perc_a<=99 & pro_2==1, gen(fc_cdf_1)
cumul fc_admin_disc if perc_a<=99 & pro_2==0, gen(fc_cdf_0)
*Function to obtain significance difference region
distcomp fc_admin_disc if perc_a<=99 , by(pro_2) alpha(0.1) p noplot
mat ranges = r(rej_ranges)
preserve
*To plot both ECDF
stack  fc_cdf_1 fc_admin_disc  fc_cdf_0 fc_admin_disc, into(c fc) ///
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
	replace sig_range = 0.01 if inrange(fc,`lo',`hi')
	}
*Plot
su fc, d	
twoway (line fc_cdf_1 fc_cdf_0 dif fc if fc<=`r(p95)', ///
	sort ylab(, grid)) ///
	(line sig_range fc if fc<=`r(p95)', lcolor(navy)), ///
	ytitle("") xtitle("Pesos") ///
	legend(order(1 "Fee-forcing" 2 "SQ" 3 "Difference") rows(1)) xtitle("Pesos") scheme(s2mono) graphregion(color(white)) 
graph export "$directorio/Figuras/cdf_fc_pro_2.pdf", replace
restore

twoway (hist fc_admin_disc if perc_a<=99 & pro_2==1, percent lwidth(medthick) lcolor(ltblue) color(ltblue)) ///
		(hist fc_admin_disc if perc_a<=99 & pro_2==0, percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Fee-forcing" 2 "SQ")) xtitle("Pesos") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_fc_pro_2.pdf", replace

twoway (hist fc_admin_disc if perc_a<=99, percent lwidth(medthick) lcolor(ltblue) color(ltblue)) ///
		(hist sum_p_c if perc_a<=99 , percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "FC" 2 "Payment")) xtitle("Pesos") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_fc_pay.pdf", replace

twoway (hist fc_prestamo if perc_p<=99 & des_c==0 , w(10) percent lwidth(medthick) lcolor(ltblue) color(ltblue)) ///
		(hist fc_prestamo if perc_p<=99 & des_c==1, w(10) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec.")) xtitle("FC as % of loan") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_fc_perc_loan.pdf", replace



*For better visualization
xtile perc_sum = sum_p_c, nq(100)
keep if perc_a<=75 & perc_sum<=75
replace sum_p_c = sum_p_c-10 if des_c==0 & ref_c==0 & pam_c==0

twoway (scatter fc_admin_disc sum_p_c if des_c==1, msymbol(Oh) msize(small) color(ltblue)) ///
	(scatter fc_admin_disc sum_p_c if des_c==0 & ref_c==1 & pam_c==0, msymbol(Oh) msize(small) color(green)) ///
	(scatter fc_admin_disc sum_p_c if des_c==0 & ref_c==1 & pam_c==1, msymbol(Oh) msize(small) color(blue)) ///
	(scatter fc_admin_disc sum_p_c if des_c==0 & ref_c==0 & pam_c==1, msymbol(Oh) msize(small) color(red)) ///
	(scatter fc_admin_disc sum_p_c if des_c==0 & ref_c==0 & pam_c==0, msymbol(Oh) msize(small) color(black)), ///
	legend(order(1 "Paid loan" 2 "Refrendum & PAM = 0" 3 "Refrendum & PAM = 1" ///
		4 "No Refrendum & PAM = 1" 5 "No Refrendum & PAM = 0")) scheme(s2mono) graphregion(color(white)) ///
		xtitle("Total payment") ytitle("Financial Cost")
graph export "$directorio/Figuras/scatter_fc_pay.pdf", replace



