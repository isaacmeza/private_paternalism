use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_Grandota_2", clear

*Number of 'refrendos'
sort prenda fecha_mov
bysort prenda : gen num_ref = sum(refrendo)
bysort prenda : egen max_num_ref = max(num_ref)
bysort prenda : replace max_num_ref = . if _n==1

*Control group
keep if pro_2==0
tab max_num_ref
count if !missing(max_num_ref)
local tot = `r(N)'
count if max_num_ref == 1
local fr = round(`r(N)'/`tot'*100,1)
count if max_num_ref == 2
local sr = round(`r(N)'/`tot'*100,1)


collapse (sum) refrendo , by(dias_inicio num_ref)
drop if num_ref==0

gen unif = runiform()
twoway 	(scatter refrendo dias_inicio if num_ref==1 & unif<0.40, msymbol(S) color(blue)) ///
		(scatter refrendo dias_inicio if num_ref==2 & unif<0.40, msymbol(T) color(red)) ///
		, scheme(s2mono) graphregion(color(white)) ytitle("Frequency") xtitle("Days from loan") ///
		legend(order(1 "First renewal (`fr'%)" 2 "Second renewal (`sr'%)"))
graph export "$directorio\Figuras\ref_dist.pdf", replace
		

