use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2.dta", clear	   
	   
keep prenda dias_inicio producto t_producto sum_porc_p desempeno des_c
drop if missing(producto)
sort prenda dias_inicio producto t_producto
fillin prenda dias_inicio

sort prenda dias_inicio

bysort prenda : replace producto = producto[_n-1] if missing(producto)
bysort prenda : replace t_producto = t_producto[_n-1] if missing(t_producto)
bysort prenda : replace sum_porc_p = sum_porc_p[_n-1] if missing(sum_porc_p)
bysort prenda : replace desempeno = desempeno[_n-1] if missing(desempeno)
bysort prenda : replace des_c = des_c[_n-1] if missing(des_c)


preserve
collapse (mean) sum_porc_p desempeno , by(dias_inicio t_producto)
xtset  t_producto dias_inicio

twoway (tsline sum_porc_p if t_producto==1, lwidth(medthick) lcolor(gs10)) ///
		(tsline sum_porc_p if t_producto==2, lwidth(medthick)) ///
		(tsline sum_porc_p if t_producto==3, lwidth(medthick)) ///
		(tsline sum_porc_p if t_producto==4, lwidth(medthick)) ///
		(tsline sum_porc_p if t_producto==5, lwidth(medthick) lcolor(gs10)) ///
		, scheme(s2mono) graphregion(color(white)) ///
		xline(30 60 90 120) ytitle("Percentage") ///
		legend(order(1 "Control" ///"Status quo"
	2 "No Choice/Fee"      	     ///"Pago frecuente con pena"
	3 "No Choice/Promise"         ///"Pago frecuente sin pena"
	4 "Choice/Fee"               ///"Escoge entre status quo y mensualidades con pena"
	5 "Choice/Promise"            ///"Escoge entre pago unico y mensualidades con promesa"
	))
graph export "$directorio/Figuras/sum_porc_evol.pdf", replace
	
twoway (tsline desempeno if t_producto==1, lwidth(medthick) lcolor(gs10)) ///
		(tsline desempeno if t_producto==2, lwidth(medthick)) ///
		(tsline desempeno if t_producto==3, lwidth(medthick)) ///
		(tsline desempeno if t_producto==4, lwidth(medthick)) ///
		(tsline desempeno if t_producto==5, lwidth(medthick) lcolor(gs10)) ///
		, scheme(s2mono) graphregion(color(white)) ///
		xline(30 60 90 120) ytitle("Percentage") ///
		legend(order(1 "Control" ///"Status quo"
	2 "No Choice/Fee"      	     ///"Pago frecuente con pena"
	3 "No Choice/Promise"         ///"Pago frecuente sin pena"
	4 "Choice/Fee"               ///"Escoge entre status quo y mensualidades con pena"
	5 "Choice/Promise"            ///"Escoge entre pago unico y mensualidades con promesa"
	))
graph export "$directorio/Figuras/desempeno_evol.pdf", replace
	
restore

********************************************************************************

preserve
collapse (mean) sum_porc_p desempeno , by(dias_inicio producto)
xtset  producto dias_inicio

twoway (tsline sum_porc_p if producto==1, lwidth(medthick) lcolor(gs10)) ///
		(tsline sum_porc_p if producto==4, lwidth(medthick)) ///
		(tsline sum_porc_p if producto==5, lwidth(medthick)) ///
		(tsline sum_porc_p if producto==6, lwidth(medthick)) ///
		(tsline sum_porc_p if producto==7, lwidth(medthick) lcolor(gs10)) ///
		, scheme(s2mono) graphregion(color(white)) ///
		xline(30 60 90 120) ytitle("Percentage") ///
		legend(order(1 "Control" ///"Status quo"
	2 "Choice/Fee - SQ"         ///"Escoge entre status quo y mensualidades con pena: elegio status quo"
	3 "Choice/Fee - NSQ"        ///"Escoge entre status quo y mensualidades con pena: eligio mensualidades con pena"
	4 "Choice/Promise - SQ"      ///"Escoge entre pago unico y mensualidades con promesa: elige status quo"
	5 "Choice/Promise - NSQ"     ///"Escoge entre pago unico y mensualidades con promesa: no elige status quo"
	))
graph export "$directorio/Figuras/sum_porc_evol_choice.pdf", replace
	
twoway (tsline desempeno if producto==1, lwidth(medthick) lcolor(gs10)) ///
		(tsline desempeno if producto==4, lwidth(medthick)) ///
		(tsline desempeno if producto==5, lwidth(medthick)) ///
		(tsline desempeno if producto==6, lwidth(medthick)) ///
		(tsline desempeno if producto==7, lwidth(medthick) lcolor(gs10)) ///
		, scheme(s2mono) graphregion(color(white)) ///
		xline(30 60 90 120) ytitle("Percentage") ///
		legend(order(1 "Control" ///"Status quo"
	2 "Choice/Fee - SQ"         ///"Escoge entre status quo y mensualidades con pena: elegio status quo"
	3 "Choice/Fee - NSQ"        ///"Escoge entre status quo y mensualidades con pena: eligio mensualidades con pena"
	4 "Choice/Promise - SQ"      ///"Escoge entre pago unico y mensualidades con promesa: elige status quo"
	5 "Choice/Promise - NSQ"     ///"Escoge entre pago unico y mensualidades con promesa: no elige status quo"
	))
graph export "$directorio/Figuras/desempeno_evol_choice.pdf", replace
	
restore

********************************************************************************

preserve
keep if des_c==1
collapse (mean) sum_porc_p  , by(dias_inicio t_producto)
xtset  t_producto dias_inicio

twoway (tsline sum_porc_p if t_producto==1, lwidth(medthick) lcolor(gs10)) ///
		(tsline sum_porc_p if t_producto==2, lwidth(medthick)) ///
		(tsline sum_porc_p if t_producto==3, lwidth(medthick)) ///
		(tsline sum_porc_p if t_producto==4, lwidth(medthick)) ///
		(tsline sum_porc_p if t_producto==5, lwidth(medthick) lcolor(gs10)) ///
		, scheme(s2mono) graphregion(color(white)) ///
		xline(30 60 90 120) ytitle("Percentage") ///
		legend(order(1 "Control" ///"Status quo"
	2 "No Choice/Fee"      	     ///"Pago frecuente con pena"
	3 "No Choice/Promise"         ///"Pago frecuente sin pena"
	4 "Choice/Fee"               ///"Escoge entre status quo y mensualidades con pena"
	5 "Choice/Promise"            ///"Escoge entre pago unico y mensualidades con promesa"
	))
graph export "$directorio/Figuras/sum_porc_cond_evol.pdf", replace

restore

preserve
keep if des_c==1
collapse (mean) sum_porc_p  , by(dias_inicio producto)
xtset  producto dias_inicio

twoway (tsline sum_porc_p if producto==1, lwidth(medthick) lcolor(gs10)) ///
		(tsline sum_porc_p if producto==4, lwidth(medthick)) ///
		(tsline sum_porc_p if producto==5, lwidth(medthick)) ///
		(tsline sum_porc_p if producto==6, lwidth(medthick)) ///
		(tsline sum_porc_p if producto==7, lwidth(medthick) lcolor(gs10)) ///
		, scheme(s2mono) graphregion(color(white)) ///
		xline(30 60 90 120) ytitle("Percentage") ///
		legend(order(1 "Control" ///"Status quo"
	2 "Choice/Fee - SQ"         ///"Escoge entre status quo y mensualidades con pena: elegio status quo"
	3 "Choice/Fee - NSQ"        ///"Escoge entre status quo y mensualidades con pena: eligio mensualidades con pena"
	4 "Choice/Promise - SQ"      ///"Escoge entre pago unico y mensualidades con promesa: elige status quo"
	5 "Choice/Promise - NSQ"     ///"Escoge entre pago unico y mensualidades con promesa: no elige status quo"
	))
graph export "$directorio/Figuras/sum_porc_cond_evol_choice.pdf", replace

restore
