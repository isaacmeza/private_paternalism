/*
Financial cost distribution
*/

use "$directorio/DB/Master.dta", clear

*Variable gen
gen fc_prestamo = (fc_admin_disc/prestamo)*100

*Histograms of financial cost
xtile perc_a_d = fc_admin_d, nq(100)
xtile perc_p = fc_prestamo, nq(100)


twoway (hist fc_admin_disc if perc_a_d<=99 & des_c==0, w(500) percent lwidth(medthick) lcolor(ltblue) color(ltblue)) ///
		(hist fc_admin_disc if perc_a_d<=99 & des_c==1, w(500) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec." )) xtitle("Financial Cost") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_fc.pdf", replace


twoway (hist fc_prestamo if perc_p<=99 & des_c==0 , w(10) percent lwidth(medthick) lcolor(ltblue) color(ltblue)) ///
		(hist fc_prestamo if perc_p<=99 & des_c==1, w(10) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec.")) xtitle("FC as % of loan") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_fc_perc_loan.pdf", replace


