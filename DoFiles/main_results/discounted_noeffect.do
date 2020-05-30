

use "$directorio/_aux/pre_admin.dta", clear


gen desempeno=(clave_movimiento==3)
bysort prenda: egen des_c=max(desempeno)

gen dias_inicio_d=dias_inicio if des_c
bysort prenda: egen dias_al_desempenyo=max(dias_inicio_d)
replace dias_al_desempenyo = 1 if dias_al_desempenyo==0

*Suc by day
egen suc_x_dia=group(suc fecha_inicial)

*Number of pledges by suc and day
gen dow=dow(fecha_inicial)

foreach var of varlist dow suc /*prenda_tipo edo_civil choose_same trabajo*/  {
	tab `var', gen(dummy_`var')
	}
	
	
set matsize 2000
matrix results = J(2000, 3, .)

local i = 1
forvalues d = 0(100)10000 {	
	qui {
	preserve
	local dd = (1+`d'/100)^(1/365)-1

	* DISCOUNTED with daily interest rate equivalent to a d% monthly rate.
	gen pagos_disc=importe/((1+`dd')^dias_inicio) if clave_movimiento <= 3 | clave_movimiento==5
	replace pagos_disc=0 if pagos_disc==.

	*'sum_p_disc' is the cumulative discounted sum of payments
	sort prenda fecha_movimiento
	by prenda: gen sum_p_disc=sum(pagos_disc)
	bysort prenda: egen sum_pdisc_c=max(sum_p_disc)

	*Trimming
	*xtile perc_sum_pdisc_c = sum_pdisc_c , nq(100)
	*replace sum_pdisc_c= . if perc_sum_pdisc_c>99
	*drop perc_sum_pdisc_c
		
	*Financial cost
		*discounted
	gen fc_admin_disc = sum_pdisc_c + prestamo/(0.7)
	replace fc_admin_disc = fc_admin_disc - prestamo/(0.7*(1+`dd')^dias_al_desempenyo) if des_c == 1


	bysort prenda fecha_inicial: gen esample =  _n==1
	su fc_admin_disc, d
	reg fc_admin_disc pro_2 dummy* if esample & fc_admin_disc<=`r(p99)', r cluster(suc_x_dia)
	local df = e(df_r)	
	matrix results[`i',1] = `d'
	matrix results[`i',2] = _b[pro_2]
	matrix results[`i',3] = _se[pro_2]
	
	reg prestamo pro_2
	matrix results[`i',2] = results[`i',2] - _b[pro_2]
	
	local i = `i' + 1
	restore
	}
	}

	
matrix colnames results = "d" "beta" "se"
clear
svmat results, names(col) 
gen rcap_lo_5 = beta - invttail(`df',.025)*se
gen rcap_hi_5 = beta + invttail(`df',.025)*se	
gen rcap_lo_10 = beta - invttail(`df',.05)*se
gen rcap_hi_10 = beta + invttail(`df',.05)*se	

replace d = d/100

*Exponential Fit
nl (beta = {c=-100} + {k=1}*log({a=1}*d+{b=1}))
gen y = _b[/c] + _b[/k]*log(_b[/a]*d+_b[/b])

twoway 	(line y d, lpattern(solid) lwidth(medthick) lcolor(black))  ///
	, scheme(s2mono) graphregion(color(white)) ///
	xtitle("Discount rate x100%") ytitle("FC Effect") legend(off) yline(0)
graph export "$directorio\Figuras\discount_effect.pdf", replace
	
	
