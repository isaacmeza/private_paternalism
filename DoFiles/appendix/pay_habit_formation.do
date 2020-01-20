*Does frequent payment develops payment habit?

use "$directorio/DB/master.dta", clear

preserve
duplicates drop NombrePignorante fecha_inicial, force
sort NombrePignorante 
* % of customers that pawn again 
bysort NombrePignorante: gen repite = (fecha_inicial[2]>=fecha_inicial[1]+75 & _N>=2 & visit_number>=2)
bysort NombrePignorante: egen repite_m = max(repite)

orth_out repite_m , by(t_prod) se  vce(cluster suc_x_dia) ///
	 bdec(2) stars pcompare
	
qui putexcel B2=matrix(r(matrix)) using "$directorio\Tables\habit_formation.xlsx", sheet("balance_hf") modify
 
local i = 2	
foreach var of varlist repite_m {
	qui reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel Q`i'=matrix(`p_val') using "$directorio\Tables\habit_formation.xlsx", sheet("balance_hf") modify
	local i = `i'+2
	}
		
		
restore

preserve
duplicates drop NombrePignorante fecha_inicial, force
sort NombrePignorante fecha_inicial
 
*Keep customers with at least 2 visit days 75 days apart 
bysort NombrePignorante: keep if _N>=2
bysort NombrePignorante: keep if fecha_inicial[2]>=fecha_inicial[1]+75

keep NombrePignorante fecha_inicial
tempfile temp_rec
save  `temp_rec'
restore
merge m:1 NombrePignorante fecha_inicial using `temp_rec', nogen keep(3)


*Frequent payment in first visit

bysort NombrePignorante : gen nochoice_fee = (visit_number[1]==1 & inlist(producto[1],2))
bysort NombrePignorante : gen nochoice_promise = (visit_number[1]==1 & inlist(producto[1],3))
bysort NombrePignorante : gen choice_fee = (visit_number[1]==1 & inlist(producto[1],4,5))
bysort NombrePignorante : gen choice_promise = (visit_number[1]==1 & inlist(producto[1],6,7))

*Impute lack arm as status-quo
replace producto = 1 if missing(producto)
replace t_producto = 1 if missing(t_prod)

keep if visit_number>=2

eststo clear

foreach var of varlist des_c  num_p  sum_porcp_c {
	eststo : reg `var' *_fee *_promise i.producto  prestamo i.dow i.suc  , r
	su `var' if e(sample)
	estadd scalar DepVarMean = `r(mean)'
	}

	esttab using "$directorio/Tables/reg_results/habit_formation.csv", se r2 star(* 0.1 ** 0.05 *** 0.01) b(a2) ///
	scalars("DepVarMean Dependent Var Mean") replace 
	
	
orth_out genero edad  val_pren pres_antes pr_recup masqueprepa , by(t_prod) se  vce(cluster suc_x_dia) ///
	 bdec(2) stars pcompare
	
qui putexcel B4=matrix(r(matrix)) using "$directorio\Tables\habit_formation.xlsx", sheet("balance_hf") modify
 
 
local i = 4	
foreach var of varlist genero edad  val_pren pres_antes pr_recup masqueprepa {
	 reg `var' i.t_prod, r cluster(suc_x_dia)
	test 1.t_prod==2.t_prod==3.t_prod==4.t_prod==5.t_prod
	local p_val = `r(p)'
	qui putexcel Q`i'=matrix(`p_val') using "$directorio\Tables\habit_formation.xlsx", sheet("balance_hf") modify
	local i = `i'+2
	}
		
