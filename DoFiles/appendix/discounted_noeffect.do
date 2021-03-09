

use "$directorio/_aux/pre_admin.dta", clear

*This first part of the code is a verbatim copy of the cleaning_admin.do file in order to 
*create a replica of the main dataset.

gen desempeno=(clave_movimiento==3)


*Recidivism
preserve
bysort prenda: egen des_c=max(desempeno)
bysort prenda: egen dias_ultimo_mov = max(dias_inicio)
gen dias_inicio_d=dias_inicio if des_c
bysort prenda: egen dias_al_desempenyo=max(dias_inicio_d)
duplicates drop NombrePignorante fecha_inicial, force
sort NombrePignorante fecha_inicial
*Number of visits to pawn 
bysort NombrePignorante: gen visit_number = _n
qui su visit_number, d
local tr99 = `r(p99)'
replace visit_number = `tr99' if visit_number>=`tr99'

*Dummy indicating if customer received more than one treatment arm
bysort NombrePignorante t_prod : gen unique_arms = _n==1
replace unique_arms = 0 if missing(t_prod)
bysort NombrePignorante : egen num_arms = sum(unique_arms)
gen more_one_arm = (num_arms>1)


keep NombrePignorante fecha_inicial visit_number num_arms 
tempfile temp_rec
save  `temp_rec'
restore
merge m:1 NombrePignorante fecha_inicial using `temp_rec', nogen


*Recover pawn
bysort prenda: egen des_c=max(desempeno)

*Days to recover
gen dias_inicio_d=dias_inicio if des_c
bysort prenda: egen dias_al_desempenyo=max(dias_inicio_d)
replace dias_al_desempenyo = 1 if dias_al_desempenyo==0

*Suc by day
egen suc_x_dia=group(suc fecha_inicial)


*Number of pledges by suc and day
gen dow=dow(fecha_inicial)


*Aux Dummies (Fixed effects)
tab num_arms, gen(num_arms_d)
tab visit_number, gen(visit_number_d)
foreach var of varlist dow suc /*prenda_tipo edo_civil choose_same trabajo*/  {
	tab `var', gen(dummy_`var')
	}
drop num_arms_d1 num_arms_d2 visit_number_d1
	
	
matrix results = J(101, 3, .)

local i = 1
forvalues d = 0(1)100 {	
	di `d'
	qui {
	preserve
	local dd = (1+`d'/100)^(1/30)-1

	* DISCOUNTED with daily interest rate equivalent to a d% monthly rate.
	gen pagos_disc=importe/((1+`dd')^dias_inicio) if clave_movimiento <= 3 | clave_movimiento==5
	replace pagos_disc=0 if pagos_disc==.

	*'sum_p_disc' is the cumulative discounted sum of payments
	sort prenda fecha_movimiento
	by prenda: gen sum_p_disc=sum(pagos_disc)
	bysort prenda: egen sum_pdisc_c=max(sum_p_disc)

	*Trimming
	xtile perc_sum_pdisc_c = sum_pdisc_c , nq(100)
	replace sum_pdisc_c= . if perc_sum_pdisc_c>99
	drop perc_sum_pdisc_c
		
	*Financial cost
		*discounted
	gen fc_admin_disc = sum_pdisc_c + prestamo/(0.7)
	replace fc_admin_disc = fc_admin_disc - prestamo/(0.7*(1+`dd')^dias_al_desempenyo) if des_c == 1


	bysort prenda fecha_inicial: gen esample =  (_n==1)
	reg fc_admin_disc pro_2  $C0 if esample , r cluster(suc_x_dia)
	local df = e(df_r)	
	matrix results[`i',1] = `d'
	matrix results[`i',2] = _b[pro_2]
	matrix results[`i',3] = _se[pro_2]
	
	*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	*reg prestamo pro_2
	*matrix results[`i',2] = results[`i',2] - _b[pro_2]
	
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


*Exponential Fit
gen wt = 3+1/(d+1)
nl (beta = {c=-300} + {k=1}*log({a=1}*d+{b=1})) [iweight=wt]
gen y = _b[/c] + _b[/k]*log(_b[/a]*d+_b[/b])

nl (rcap_lo_5 = {c=-300} + {k=1}*log({a=1}*d+{b=1})) [iweight=wt]
gen ylo5 = _b[/c] + _b[/k]*log(_b[/a]*d+_b[/b])

nl (rcap_hi_5 = {c=-300} + {k=1}*log({a=1}*d+{b=1})) [iweight=wt]
gen yhi5 = _b[/c] + _b[/k]*log(_b[/a]*d+_b[/b])



*plot random points of beta
gen u = (runiform()<0.2)

twoway 	(line y d, lpattern(solid) lwidth(medthick) lcolor(black))  ///
		(line ylo5 d, lpattern(dot) lwidth(medthick) lcolor(black))  ///
		(line yhi5 d, lpattern(dot) lwidth(medthick) lcolor(black))  ///
		(scatter beta d if u, color(ltblue)) ///
	, scheme(s2mono) graphregion(color(white)) ///
	xtitle("Monthly interest rate") ytitle("FC Effect") legend(off) yline(0)
graph export "$directorio\Figuras\discount_effect.pdf", replace
	
	
