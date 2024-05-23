
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	May. 22, 2024
* Last date of modification: 
* Modifications: 
* Files used:     
		- 
* Files created:  

* Purpose: Summary & balance - attrition table 

*******************************************************************************/
*/
	
*SURVEY DATA (ENTRY) 
import excel "$directorio\Raw\Muestra Aleatoria en Excel con nombres de sucursales.xlsx", ///
	sheet("Muestra Aleatoria2") cellrange(A2:G93) firstrow clear
	
reshape long t_prod, i(fecha) j(sucursal)
rename fecha f_encuesta

tempfile randomization
save `randomization'

use "$directorio/Raw/Base_Encuestas_Basales_24_05_2013.dta", clear

destring Enc, replace force

foreach var of varlist _all {
if "`var'"!="prenda"{
	bysort prenda: egen aux=max(`var')
	replace `var'=aux
	drop aux
	}	
}

*Variable elimination
drop prod regalo pres_fundacion ledara AW AX question_miss question_miss1 question_miss2 Mprep

bysort prenda: keep if _n==1
merge m:1 sucursal f_encuesta using `randomization', nogen keep(1 3)
merge 1:1 prenda using "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2.dta"
*keep if visit_number==1 | visit_number==.

*Treatment for non-takers
replace t_producto = t_prod if _merge==1
replace t_producto = 6 if f_encuesta<date("9/6/2012","MDY")
drop t_prod

*Branch-day cluster
replace fecha_inicial = f_encuesta if _merge==1
replace suc = sucursal if _merge==1
drop suc_x_dia
egen suc_x_dia = group(fecha_inicial suc)

*Response survey dummy
gen response = !missing(f_encuesta) 

*Take-up treatment
gen takeup = (_merge==3) if inlist(_merge,1,3)

* Drop irrelevant observations  (important for correct # obs count)
drop if missing(t_prod)

*Number of pledges by suc and day
preserve
sort suc fecha_movimiento HoraM NombreP prenda, stable
duplicates drop NombrePig prenda suc fecha_inicial, force
collapse (count) num_pawns = prenda, by(suc fecha_inicial t_producto) 
tempfile temp_num_pawns
save `temp_num_pawns'
restore

*Number of pawns per borrower
sort NombrePig suc fecha_inicial
by NombrePig suc fecha_inicial : gen num_pawns_borr = _N if !missing(NombrePig)
gen num_pawns_client = num_pawns_borr
replace num_pawns_client = 0 if missing(NombrePig)

*Number of borrowers by suc and day
sort suc fecha_movimiento HoraM NombreP prenda, stable
duplicates drop NombrePig prenda suc fecha_inicial if !missing(NombrePig), force
duplicates drop Enc f_encuesta if missing(NombrePig), force
duplicates drop NombrePig suc fecha_inicial if !missing(NombrePig), force
collapse (count) num_borrowers = NombreP (mean) num_pawns_borr (mean) prestamo_i (mean) takeup (mean) num_pawns_client  , by(suc fecha_inicial t_producto)

merge 1:1 suc fecha_inicial t_producto using `temp_num_pawns', nogen

*******************************BALANCE/ATTRITION********************************

foreach var of varlist num_borrowers num_pawns_borr num_pawns {
	su `var' if t_prod==4, d
	replace `var' = . if  `var'>`r(p99)'
}

gen arm = t_prod
replace arm = 2.5 if t_prod==2
egen suc_x_dia = group(suc fecha_inicial) 	

local i = 2	
qui putexcel set  "$directorio\Tables\SS_att_.xlsx", sheet("SS_att_") modify	

eststo clear
foreach var of varlist num_borrowers num_pawns_borr num_pawns prestamo_i takeup num_pawns_client {

	eststo : reghdfe `var' i.t_prod if inlist(t_prod,1,2,4), absorb(suc fecha_inicial) cluster(suc_x_dia)

	
	orth_out `var' if inlist(t_prod,1,2,4), by(t_prod) overall se vce(cluster suc) bdec(2) count
	qui putexcel B`i'=matrix(r(matrix)) 
	
	qui reg `var' ibn.t_prod if inlist(t_prod,1,2,4), nocons r cluster(suc)
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val')  
	local i = `i'+2

	qreg `var' i.t_prod if inlist(t_prod,1,2,4), q(0.5) 
	qui putexcel B`i'=matrix(_b[_cons]) 
	qui putexcel C`i'=matrix(_b[_cons]+_b[2.t_prod]) 
	qui putexcel D`i'=matrix(_b[_cons]+_b[4.t_prod]) 
	test 1.t_prod==2.t_prod==4.t_prod
	local p_val = `r(p)'
	qui putexcel L`i'=matrix(`p_val') 
	local i = `i'+1


	stripplot `var' if inlist(t_prod,1,2,4) & `var'!=0, cumul cumprob box iqr centre over(arm) refline vertical xsize(3) xlabel(1 "Control" 2.5 "Forced Commitment" 4 "Choice commitment") ytitle("") xtitle("")
	graph export "$directorio/Figuras/box_plot_`var'.pdf", replace
}
	
orth_out num_borrowers if inlist(t_prod,1,2,4), by(t_prod) count
qui putexcel B23=matrix(r(matrix)) 

esttab using "$directorio/Tables/reg_results/ss_att.csv", se r2 ${star} b(a2) ///
		keep(_cons 2.t_producto 4.t_producto) replace 
	
	