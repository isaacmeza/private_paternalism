use "$directorio/DB/Master.dta", clear


*Survival graph by days (for control group)
cumul dias_ultimo_mov if concluyo_c==1 & pro_2==0 , gen(ecd)
*Normalize by the ended contracts
su concluyo_c if pro_2==0
replace ecd = ecd*`r(mean)'*100

*Graph
sort ecd
line ecd dias_ultimo if concluyo_c==1 & pro_2==0, xline(110, lpattern(dot)) graphregion(color(white)) ///
	scheme(s2mono) xtitle("Elapsed days") ytitle("Percentage (%)")
graph export "$directorio\Figuras\survival_graph_ended.pdf", replace


*Survival graph (probability of recovery) by treatment arm
cap drop ecdf_d
forvalues i = 1/5 {
	cumul dias_al_desempenyo if t_prod==`i', gen(ecdf_t`i') 
	su des_c if t_prod==`i'
	replace ecdf_t`i' = ecdf_t`i'*`r(mean)'*100
	}

	
sort t_producto dias_al_dese	
twoway (line ecdf_t1 dias_al_desempenyo, lwidth(medthick) lpattern(solid) lcolor(black) ) ///
	(line ecdf_t2 dias_al_desempenyo, lwidth(medthick) lpattern(solid) lcolor(blue) ) ///
	(line ecdf_t3 dias_al_desempenyo, lwidth(medthick) lpattern(dash) lcolor(red) ) ///
	(line ecdf_t4 dias_al_desempenyo, lwidth(medthick) lpattern(dash) lcolor(ltblue) ) ///
	(line ecdf_t5 dias_al_desempenyo, lwidth(medthick) lpattern(dash) lcolor(dkgreen) ) ///
		 , scheme(s2mono) graphregion(color(white)) xtitle("Elapsed days to un-pledge") ytitle("Percentage %") ///
		 legend(order( 1 "Control" 2 "Fee-forcing" 3 "Promise-forcing" 4 "Choice-fee" 5 "Choice-promise"))
graph export "$directorio\Figuras\survival_graph_unpledge.pdf", replace
		
