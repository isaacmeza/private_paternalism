*Orthogonality of FP supply
use "${directorio}\DB\base_expansion.dta", clear

global trainf=0.85
set seed 9834623

*Weekly date
gen week = week(fechamov)
gen year = year(fechamov)
tostring week, replace
tostring year, replace
gen date = weekly(week+"-"+year,"wY")
format date %tw

*Monthly date
gen mes = month(fechamov)
tostring mes, replace
gen month = monthly(mes+"-"+year,"MY")
format month %tm

*Jewels
gen jewels =  (linea2==" Alhajas ")

*Age
gen edad = round((date("`c(current_date)'","DMY")-fechanacimiento)/365)

*Recovered pawn
gen rec_p = missing(estadovta)


*FP contract was active in the past (instrument)
collapse (max) pf_suc = pago_fijo (mean) perc_demand = pago_fijo ///
	(count) num_pawns = pago_fijo ///
	(mean) sexo (mean) edad (first) week (mean) importepercibido ///
	(mean) rec_p (mean) jewels (mean) porcvaluacion (first) month ///
 , by(idsuc date)
xtset idsuc date

*Identify branches with both FP and Traditional
preserve
collapse (max) pf_month = pf_suc, by(idsuc month)
bysort idsuc : egen flag = mean(pf_month)
bysort idsuc : gen both_regimes = (flag!=0 & flag !=1) if _n==1
keep if both_regimes==1
keep idsuc both_regimes 
tempfile temp
save `temp'
restore
merge m:1 idsuc using `temp', nogen keep(3)
sort idsuc date

*Week of yr
destring week, replace

*Dummies
tab week, gen(dummy_week)
tab idsuc, gen(dummy_idsuc)
drop dummy_week1
drop dummy_idsuc1


********************************************
*				REGRESSIONS				   *
********************************************
*Instrument looks random?
eststo clear


eststo: reg pf_suc i.week i.idsuc, r
su pf_suc if e(sample) 
estadd scalar DepVarMean = `r(mean)'
estadd scalar adj_r2 = e(r2_a)
testparm i.idsuc
estadd scalar p_suc = `r(p)'
testparm i.week
estadd scalar p_week = `r(p)'

*Dataset for prediction
preserve
keep pf_suc dummy_*
rename pf_suc pf_suc_1

*Drop missing values
	foreach var of varlist * {
		drop if missing(`var')
		}
		
	*Randomize order of data set
	gen u=uniform()
	sort u
	forvalues i=1/2 {
		replace u=uniform()
		sort u
		}
	qui count
	drop u

	local trainn= round($trainf *`r(N)'+1)	
	gen insample=1 in 1/`trainn'
	replace insample=0 if missing(insample)
	
export delimited "$directorio/_aux/instrument_1.csv", replace nolabel
restore	
	
	
********************************************************************************
********************************************************************************


eststo: reg pf_suc l.sexo l.edad l.importepercibido ///
	l.num_pawns l.jewels l(4/8).rec_p l.porcvaluacion ///
	i.week i.idsuc, r
su pf_suc if e(sample) 
estadd scalar DepVarMean = `r(mean)'	
estadd scalar adj_r2 = e(r2_a)
testparm i.idsuc
estadd scalar p_suc = `r(p)'
testparm i.week
estadd scalar p_week = `r(p)'
testparm l.sexo l.edad l.importepercibido ///
	l.num_pawns l.jewels l(4/8).rec_p l.porcvaluacion
estadd scalar p_obs = `r(p)'

*Dataset for prediction
preserve
foreach var of varlist sexo edad importepercibido ///
	num_pawns jewels porcvaluacion {
	gen lag_`var' = l.`var'
	}
forvalues i=4/8 {
	gen lag_`i'_rec_p = l`i'.rec_p
	}	
keep pf_suc dummy_* lag_*
rename pf_suc pf_suc_2

*Drop missing values
	foreach var of varlist * {
		drop if missing(`var')
		}
		
	*Randomize order of data set
	gen u=uniform()
	sort u
	forvalues i=1/2 {
		replace u=uniform()
		sort u
		}
	qui count
	drop u

	local trainn= round($trainf *`r(N)'+1)	
	gen insample=1 in 1/`trainn'
	replace insample=0 if missing(insample)
	
export delimited "$directorio/_aux/instrument_2.csv", replace nolabel
restore	


********************************************************************************
********************************************************************************


eststo: reg pf_suc l4.sexo l4.edad l4.importepercibido ///
	l4.num_pawns l4.jewels l(8/12).rec_p l4.porcvaluacion ///
	i.week i.idsuc, r
su pf_suc if e(sample) 
estadd scalar DepVarMean = `r(mean)'	
estadd scalar adj_r2 = e(r2_a)
testparm i.idsuc
estadd scalar p_suc = `r(p)'
testparm i.week
estadd scalar p_week = `r(p)'
testparm l4.sexo l4.edad l4.importepercibido ///
	l4.num_pawns l4.jewels l(8/12).rec_p l4.porcvaluacion
estadd scalar p_obs = `r(p)'
	
*Dataset for prediction
preserve
foreach var of varlist sexo edad importepercibido ///
	num_pawns jewels porcvaluacion {
	gen lag_`var' = l4.`var'
	}
forvalues i=8/12 {
	gen lag_`i'_rec_p = l`i'.rec_p
	}		
keep pf_suc dummy_* lag_*
rename pf_suc pf_suc_3

*Drop missing values
	foreach var of varlist * {
		drop if missing(`var')
		}
		
	*Randomize order of data set
	gen u=uniform()
	sort u
	forvalues i=1/2 {
		replace u=uniform()
		sort u
		}
	qui count
	drop u

	local trainn= round($trainf *`r(N)'+1)	
	gen insample=1 in 1/`trainn'
	replace insample=0 if missing(insample)
	
export delimited "$directorio/_aux/instrument_3.csv", replace nolabel
restore	


esttab using "$directorio/Tables/reg_results/instrument_random.csv", se r2 ${star} b(a2) ///
		scalars("adj_r2 adj_r2" "p_suc p_suc" "p_week p_week" "p_obs p_obs" "DepVarMean DepVarMean") replace 


