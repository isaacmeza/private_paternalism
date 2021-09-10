/*
Effective cost/loan ratio distribution
*/

use "$directorio/DB/Master.dta", clear


xtile perc_eff_d = eff_cost_loan, nq(100)

*Histograms of effective cost
twoway (hist eff_cost_loan if perc_eff_d<=99 & des_c==0 , w(0.05) percent lwidth(medthick) lcolor(ltblue) color(ltblue)) ///
		(hist eff_cost_loan if perc_eff_d<=99 & des_c==1, w(0.05) percent lwidth(medthick) lcolor(black) color(none)), ///
		legend(order(1 "Cond. on not rec." 2 "Cond. on rec.")) xtitle("Effective cost-loan") scheme(s2mono) graphregion(color(white))
graph export "$directorio/Figuras/hist_eff.pdf", replace


