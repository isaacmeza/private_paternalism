*Dependent variable
global dep_var pago_frec_vol
*Independent variable (dummies)
global ind_var_dummy  dummy_prenda_tipo1-dummy_prenda_tipo4 dummy_edo_civil1-dummy_edo_civil3  /// *Categorical covariates
	dummy_choose_same1-dummy_choose_same2   /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido pb hace_presupuesto tentado low_cost low_time
*Independent variable (continuous)
global ind_var_cont  prestamo pr_recup  edad visit_number faltas /// *Continuous covariates	

********************************************************************************

	
********************************************************************************
*Data preparation		

import delimited "C:\Users\xps-seira\Downloads\heterogeneity_grf_pfv.csv", clear 

********************************************************************************

foreach var of varlist $ind_var_cont {
	qui su `var', d
	gen dummy_median_`var' = (`var'>=`r(p50)')
	}


local k = 4	
foreach var of varlist $ind_var_dummy dummy_median_* {
	di "`var'"
	qui reg $dep_var i.pb##i.tentado ///
		dummy_dow1-dummy_dow5 dummy_suc1-dummy_suc5 if `var', r 
	local df = e(df_r)	
	qui putexcel A`k'=("`var'") using "$directorio\Tables\cell_Reg.xlsx", sheet("cell_reg") modify
	qui putexcel G`k'=(_b[1.tentado]) using "$directorio\Tables\cell_Reg.xlsx", sheet("cell_reg") modify
	qui putexcel H`k'=(_b[1.pb]) using "$directorio\Tables\cell_Reg.xlsx", sheet("cell_reg") modify
	qui putexcel I`k'=(_b[1.pb#1.tentado]) using "$directorio\Tables\cell_Reg.xlsx", sheet("cell_reg") modify
	qui putexcel K`k'=(2*ttail(`df', abs(_b[1.pb]/_se[1.pb]))) using "$directorio\Tables\cell_Reg.xlsx", sheet("cell_reg") modify
	qui putexcel L`k'=(2*ttail(`df', abs(_b[1.tentado]/_se[1.tentado]))) using "$directorio\Tables\cell_Reg.xlsx", sheet("cell_reg") modify
	qui putexcel M`k'=(2*ttail(`df', abs(_b[1.pb#1.tentado]/_se[1.pb#1.tentado]))) using "$directorio\Tables\cell_Reg.xlsx", sheet("cell_reg") modify
	local k = `k'+1	
	}	
