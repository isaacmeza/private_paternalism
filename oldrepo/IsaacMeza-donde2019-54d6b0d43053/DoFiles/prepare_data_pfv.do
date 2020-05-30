use "$directorio/DB/Master.dta", clear


cap drop tentado
gen tentado=(tempt>=3) if tempt!=.


*Aux Dummies 
foreach var of varlist dow suc prenda_tipo edo_civil choose_same trabajo {
	tab `var', gen(dummy_`var')
	}

sort NombrePignorante fecha_inicial

*Covariates - Randomization - Outcomes
keep NombrePignorante prenda suc_x_dia producto /// *Admin variables
	dummy_dow* dummy_suc* /// *Controls
	prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	dummy_prenda_tipo* dummy_edo_civil*  /// *Categorical covariates
	dummy_choose_same* dummy_trabajo*  /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time ///
	rec_cel
	
	
order NombrePignorante prenda suc_x_dia /// *Admin variables
	dummy_dow* dummy_suc* /// *Controls
	prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	dummy_prenda_tipo* dummy_edo_civil*  /// *Categorical covariates
	dummy_choose_same1 dummy_choose_same2 dummy_trabajo1-dummy_trabajo8  /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	renta comida medicina luz gas telefono agua  ///
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time ///
	rec_cel

	
	
keep if inrange(producto,4,7)
*Frequent voluntary payment        
gen pago_frec_vol_fee=(producto==5) if (producto==4 | producto==5)
gen pago_frec_vol_promise=(producto==7) if (producto==6 | producto==7)
gen pago_frec_vol=inlist(producto,5,7)
drop producto
		
export delimited "$directorio/_aux/data_pfv.csv", replace nolabel



eststo clear														  


***************************
* 	Linear Regression 	  *
***************************


*Demographic of frequent voluntarily payment 
eststo: reg pago_frec_vol i.pb##i.tentado prestamo pr_recup ///
	edad visit_number faltas genero dummy_dow* dummy_suc*, cluster(suc_x_dia) 
qui sum pago_frec_vol if e(sample)
local media_dep=r(mean)
estadd scalar MDep = `media_dep'

eststo: reg pago_frec_vol_fee i.pb##i.tentado prestamo pr_recup ///
	edad visit_number faltas genero dummy_dow* dummy_suc*, cluster(suc_x_dia) 
qui sum pago_frec_vol_fee if e(sample)
local media_dep=r(mean)
estadd scalar MDep = `media_dep'

eststo: reg pago_frec_vol_promise i.pb##i.tentado prestamo pr_recup ///
	edad visit_number faltas genero dummy_dow* dummy_suc*, cluster(suc_x_dia) 
qui sum pago_frec_vol_promise if e(sample)
local media_dep=r(mean)
estadd scalar MDep = `media_dep'
	   

esttab using "$directorio/Tables/reg_results/demographic_fvp.csv", se r2 star(* 0.1 ** 0.05 *** 0.01) b(a2) ///
	scalars("MDep Dependent Var Mean") replace 

			
	

** RUN R CODE HERE

