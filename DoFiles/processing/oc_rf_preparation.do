/*
Data preparation for Random Forest OC prediction
*/

********************************************************************************

use "$directorio/DB/Master.dta", clear

foreach var of varlist prenda_tipo educacion plan_gasto {
	tab `var', gen(dummy_`var')
	drop dummy_`var'1
	}
	
keep  prenda des_c dummy_prenda_tipo* val_pren prestamo genero edad dummy_educacion* pres_antes ///
	dummy_plan_gasto* ahorros cta_tanda tent rec_cel faltas 

export delimited "$directorio/_aux/data_oc.csv", replace nolabel


