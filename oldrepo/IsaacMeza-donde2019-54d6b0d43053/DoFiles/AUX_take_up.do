args x

local familia fam_pide fam_comun faltas
local ingreso renta comida medicina luz gas telefono agua 
local self_control pb  hace_presupuesto tentado rec_cel
local experiencia pres_antes cta_tanda pr_recup visit_number 
local otros prestamo edad genero masqueprepa estresado_seguido low_cost low_time
	
local familianames fam.asks common.asks lack 
local ingresonames rent food medicine electricity gas phone water  saves
local self_controlnames pb fb makes.budget tempt reminder
local experiencianames pawn.before Rosca pr.recovery visits
local otrosnames loan.amt age gender more.high.school stressed low.cost low.time

local alpha = .05 // for 95% confidence intervals 
*Matriz para las variables de Familia
local fam = 0
foreach var of varlist `familia'{
	local fam = `fam'+1
}
matrix family = J(`fam', 6, .)
local row = 1
foreach var of varlist `familia'{
	qui reg rf_pred `var', r
	local row1 `row1' tau_hat_oobpredictions:`var'
	local df = e(df_r)	
	matrix family[`row',1] = `row'
	// Beta 
	matrix family[`row',2] = _b[`var']
	// Standard error
	matrix family[`row',3] = _se[`var']
	// P-value
	matrix family[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix family[`row',5] =  _b[`var'] - invttail(`df',`=`alpha'/2')*_se[`var']
	matrix family[`row',6] =  _b[`var'] + invttail(`df',`=`alpha'/2')*_se[`var']
	
	local row = `row' + 1
}
matrix colnames family = "k" "beta" "se" "p" 
matrix rownames family = `row1'
matsort family 2 "down"
mat l family

*Matriz para las variables de Ingreso
local ing = 0
foreach var of varlist `ingreso'{
	local ing = `ing'+1
}
matrix income = J(`ing', 6, .)
local row = 1
foreach var of varlist `ingreso'{
	qui reg rf_pred `var', r
	local row2 `row2' tau_hat_oobpredictions:`var'
	local df = e(df_r)	
	
	matrix income[`row',1] = `row'
	// Beta 
	matrix income[`row',2] = _b[`var']
	// Standard error
	matrix income[`row',3] = _se[`var']
	// P-value
	matrix income[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix income[`row',5] =  _b[`var'] - invttail(`df',`=`alpha'/2')*_se[`var']
	matrix income[`row',6] =  _b[`var'] + invttail(`df',`=`alpha'/2')*_se[`var']
	
	local row = `row' + 1
}
matrix colnames income = "k" "beta" "se" "p"
matrix rownames income = `row2'
matsort income 2 "down"
mat l income


*Matriz para las variables de Self Control
local self = 0
foreach var of varlist `self_control'{
	local self = `self'+1
}
matrix selfc = J(`self', 6, .)
local row = 1
foreach var of varlist `self_control'{
	qui reg rf_pred `var', r
	local row3 `row3' tau_hat_oobpredictions:`var'
	local df = e(df_r)	
	
	matrix selfc[`row',1] = `row'
	// Beta 
	matrix selfc[`row',2] = _b[`var']
	// Standard error
	matrix selfc[`row',3] = _se[`var']
	// P-value
	matrix selfc[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix selfc[`row',5] =  _b[`var'] - invttail(`df',`=`alpha'/2')*_se[`var']
	matrix selfc[`row',6] =  _b[`var'] + invttail(`df',`=`alpha'/2')*_se[`var']
	
	local row = `row' + 1
}
matrix colnames selfc = "k" "beta" "se" "p"
matrix rownames selfc = `row3'
matsort selfc 2 "down"

mat l selfc

*Matriz para las variables de Experiencia
local exp = 0
foreach var of varlist `experiencia'{
	local exp = `exp'+1
}
matrix experience = J(`exp', 6, .)
local row = 1
foreach var of varlist `experiencia'{
	qui reg rf_pred `var', r
	local row4 `row4' tau_hat_oobpredictions:`var'
	local df = e(df_r)	
	
	matrix experience[`row',1] = `row'
	// Beta 
	matrix experience[`row',2] = _b[`var']
	// Standard error
	matrix experience[`row',3] = _se[`var']
	// P-value
	matrix experience[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix experience[`row',5] =  _b[`var'] - invttail(`df',`=`alpha'/2')*_se[`var']
	matrix experience[`row',6] =  _b[`var'] + invttail(`df',`=`alpha'/2')*_se[`var']
	
	local row = `row' + 1
}
matrix colnames experience = "k" "beta" "se" "p"
matrix rownames experience = `row4'
matsort experience 2 "down"

mat l experience

*Matriz para las variables de Otros
local ot = 0
foreach var of varlist `otros'{
	local ot = `ot'+1
}
matrix other = J(`ot', 6, .)
local row = 1
foreach var of varlist `otros'{
	qui reg rf_pred `var', r
	local row5 `row5' tau_hat_oobpredictions:`var'
	local df = e(df_r)	
	
	matrix other[`row',1] = `row'
	// Beta 
	matrix other[`row',2] = _b[`var']
	// Standard error
	matrix other[`row',3] = _se[`var']
	// P-value
	matrix other[`row',4] = 2*ttail(`df', abs(_b[`var']/_se[`var']))
	// Confidence Intervals
	matrix other[`row',5] =  _b[`var'] - invttail(`df',`=`alpha'/2')*_se[`var']
	matrix other[`row',6] =  _b[`var'] + invttail(`df',`=`alpha'/2')*_se[`var']
	
	local row = `row' + 1
}
matrix colnames other = "k" "beta" "se" "p"
matrix rownames other = `row5'
matsort other 2 "down"
mat l other

local options1 mcolor(gs11) msymbol(O)  msize(small) color(gs11)
local options2 mcolor(gs10) msymbol(O)  msize(small) color(gs10)
local options3 mcolor(gs8) msymbol(O)  msize(small) color(gs8)
local options4 mcolor(gs6) msymbol(O)  msize(small) color(gs6)
local options5 mcolor(gs4) msymbol(O)  msize(small) color(gs4)
local graphregion graphregion(fcolor(white) lstyle(none) color(white)) 
local plotregion plotregion(margin(sides) fcolor(white) lstyle(none) lcolor(white)) 


if "`x'" == "pago_frec_vol_fee" {

disp in red "`x'"


mat rownames family = "Common_asks" "Fam_asks" "Lack"
mat rownames income = "Electricity" "Gas" ///
	"Food" "Phone"  "Medicine" "Water"  "Rent"  
mat rownames selfc = "Present_bias" "Tempt" ///
 "Reminder" "Makes_budget" 
mat rownames experience = "Rosca" "Prob_recovery" ///
  "Visits"  "Pawn_before" 
mat rownames other = "More_high_school" "Low_cost" ///
 "Gender" "Low_time" "Loan_amt" "Age" "Stressed" 
mat l family


	coefplot (matrix(family[,2]), ci((family[,5] family[,6])) `options1' ciopts(lcolor(gs11))) /// 
	(matrix(income[,2]), ci((income[,5] income[,6])) `options2' ciopts(lcolor(gs10))) ///
	(matrix(selfc[,2]), ci((selfc[,5] selfc[,6])) `options3' ciopts(lcolor(gs8))) ///
	(matrix(experience[,2]), ci((experience[,5] experience[,6])) `options4' ciopts(lcolor(gs6))) ///
	(matrix(other[,2]), ci((other[,5] other[,6])) `options5' ciopts(lcolor(gs4))), ///
	legend(off) offset(0) xline(0) `graphregion' `plotregion' ylabel(,labsize( small )) ///	
	headings("Common_asks" = "{bf:Family}" "Electricity" = "{bf:Income}" ///
	"Present_bias" = "{bf:Self Control}" "Rosca" = "{bf:Experience}" "More_high_school" = "{bf:Other}",labsize(vsmall)) ///
	legend(off) xline(0) `graphregion' `plotregion' ylabel(,labsize( small )) 

}

if "`x'" == "pago_frec_vol" {

disp in red "`x'"

mat rownames family = "Common_asks" "Fam_asks" "Lack"
mat rownames income = "Gas"  "Electricity" "Phone" ///
"Medicine" "Water" "Food" "Rent"    
mat rownames selfc = "Makes_budget" ///
"Reminder" "Present_bias"  "Tempt" 
mat rownames experience = "Rosca" "Prob_recovery" ///
  "Visits"  "Pawn_before" 
mat rownames other = "More_high_school" "Low_time" ///
 "Low_cost" "Age" "Loan_amt" "Gender" "Stressed" 



	coefplot (matrix(family[,2]), ci((family[,5] family[,6])) `options1' ciopts(lcolor(gs11))) /// 
	(matrix(income[,2]), ci((income[,5] income[,6])) `options2' ciopts(lcolor(gs10))) ///
	(matrix(selfc[,2]), ci((selfc[,5] selfc[,6])) `options3' ciopts(lcolor(gs8))) ///
	(matrix(experience[,2]), ci((experience[,5] experience[,6])) `options4' ciopts(lcolor(gs6))) ///
	(matrix(other[,2]), ci((other[,5] other[,6])) `options5' ciopts(lcolor(gs4))), ///
	legend(off) offset(0) xline(0) `graphregion' `plotregion' ylabel(,labsize( small )) ///
	headings("Common_asks" = "{bf:Family}" "Gas" = "{bf:Income}" ///
	"Makes_budget" = "{bf:Self Control}" "Rosca" = "{bf:Experience}" "More_high_school" = "{bf:Other}",labsize(vsmall)) ///
	legend(off) xline(0) `graphregion' `plotregion' ylabel(,labsize( small )) 

}

if "`x'" == "pago_frec_vol_promise" {
disp in red "`x'"

mat rownames family = "Common_asks" "Fam_asks" "Lack"
mat rownames income = "Electricity" "Gas"  "Medicine" "Phone" ///
 "Water" "Rent"  "Food"
mat rownames selfc =  "Makes_budget" ///
"Present_bias" "Reminder" "Tempt" 
mat rownames experience = "Rosca" "Prob_recovery" ///
  "Pawn_before" "Visits"   
mat rownames other = "Low_time" "More_high_school" "Low_cost"  ///
  "Age" "Loan_amt" "Gender" "Stressed" 


	coefplot (matrix(family[,2]), ci((family[,5] family[,6])) `options1' ciopts(lcolor(gs11))) /// 
	(matrix(income[,2]), ci((income[,5] income[,6])) `options2' ciopts(lcolor(gs10))) ///
	(matrix(selfc[,2]), ci((selfc[,5] selfc[,6])) `options3' ciopts(lcolor(gs8))) ///
	(matrix(experience[,2]), ci((experience[,5] experience[,6])) `options4' ciopts(lcolor(gs6))) ///
	(matrix(other[,2]), ci((other[,5] other[,6])) `options5' ciopts(lcolor(gs4))), ///
	legend(off) offset(0) xline(0) `graphregion' `plotregion' ylabel(,labsize( small )) ///
	headings("Common_asks" = "{bf:Family}" "Electricity" = "{bf:Income}" ///
	"Makes_budget" = "{bf:Self Control}" "Rosca" = "{bf:Experience}" "Low_time" = "{bf:Other}",labsize(vsmall)) ///
	legend(off) xline(0) `graphregion' `plotregion' ylabel(,labsize( small )) 
}


graph export "$directorio/Figuras/`x'_interactions_rf.pdf", replace
