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



