args depvar treat vrlist vrlistnames familia ingreso self_control ///
 experiencia otros familianames ingresonames self_controlnames ///
 experiencianames otrosnames
 
local alpha = .05 // for 95% confidence intervals 
*Matriz para las variables de Familia
local fam = 0
foreach var of varlist `familia'{
	local fam = `fam'+1
}
matrix family = J(`fam', 6, .)
local row = 1
foreach var of varlist `familia'{
	qui reg tau_hat_oobpredictions `var' if !missing(`treat'), r
	
	local rownms `rownms' tau_hat_oobpredictions:`var'
	
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
matrix rownames family = `rownms'
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
	qui reg tau_hat_oobpredictions `var' if !missing(`treat'), r
	local rownames `rownames' tau_hat_oobpredictions:`var'
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
matrix rownames income = `rownames'
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
	qui reg tau_hat_oobpredictions `var' if !missing(`treat'), r
	local rownms1 `rownms1' tau_hat_oobpredictions:`var'
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
matrix rownames selfc = `rownms1'
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
	qui reg tau_hat_oobpredictions `var' if !missing(`treat'), r
	local rownms2 `rownms2' tau_hat_oobpredictions:`var'
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
matrix rownames experience = `rownms2'
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
	qui reg tau_hat_oobpredictions `var' if !missing(`treat'), r
	local rownms3 `rownms3' tau_hat_oobpredictions:`var'
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
matrix rownames other = `rownms3'
matsort other 2 "down"
mat l other
 

*Matriz para toda la gráfica
local nv = 0	
foreach var of varlist `vrlist' {
	local nv = `nv'+1
}

matrix results = J(`nv', 6, .) // empty matrix for results
//  4 cols are: (1) Treatment arm, (2) beta, (3) std error, (4) pvalue 
 
*Pasamos los valores de una matriz a la otra.
forvalues i = 1/`fam'{
	forvalues j = 1/6{
		mat results[`i',`j'] = family[`i',`j']
	}
}

forvalues i = `=`fam'+1'/`=`fam'+`ing''{
	local k = `i'-`fam'
	forvalues j = 1/6{
		mat results[`i',`j'] = income[`k',`j']
	}
}


forvalues i = `=`fam'+`ing'+1'/`=`fam'+`ing'+`self''{
	local k = `i'-`fam'-`ing'
	forvalues j = 1/6{
		mat results[`i',`j'] = selfc[`k',`j']
	}
}

forvalues i = `=`fam'+`ing'+`self'+1'/`=`fam'+`ing'+`self'+`exp''{
	local k = `i'-`fam'-`ing'-`self'
	forvalues j = 1/6{
		mat results[`i',`j'] = experience[`k',`j']
	}
}

forvalues i = `=`fam'+`ing'+`self'+`exp'+1'/`=`fam'+`ing'+`self'+`exp'+`ot''{
	local k = `i'-`fam'-`ing'-`self'- `exp'
	forvalues j = 1/6{
		mat results[`i',`j'] = other[`k',`j']
	}
}

matrix colnames results = "k" "beta" "se" "p"

/*
	local familianames fam.asks common.asks lack 
	local ingresonames loan.amt low.cost low.time saves
	local self_controlnames pb fb makes.budget tempt
	local experiencianames pawn.before relay pr.recovery visits
	local otrosnames rent food medicine electricity gas phone water age gender more.high.school stressed
	
*/

local options1 mcolor(gs12) msymbol(O)  msize(small) color(gs12)
local options2 mcolor(gs10) msymbol(O)  msize(small) color(gs10)
local options3 mcolor(gs8) msymbol(O)  msize(small) color(gs8)
local options4 mcolor(gs6) msymbol(O)  msize(small) color(gs6)
local options5 mcolor(gs4) msymbol(O)  msize(small) color(gs4)
local graphregion graphregion(fcolor(white) lstyle(none) color(white)) 
local plotregion plotregion(margin(sides) fcolor(white) lstyle(none) lcolor(white)) 

if "`depvar'" == "des_c" & "`treat'" == "pro_2"{
	mat rownames family = "common_asks" "lack" "fam_asks"
	mat rownames income = "loan_amt" "saves" "low_time" "low_cost"
	mat rownames selfc = "pb" "fb" "makes_budget" "tempt"
	mat rownames experience = "pawn_before" "pr_recovery" "visits" "relay"
	mat rownames other = "water" "electricity" "gas" "medicine" ///
	"phone" "rent" "stressed" "food" "age" "gender" "more_high_school"
	
	coefplot (matrix(family[,2]), ci((family[,5] family[,6])) `options1' ciopts(lcolor(gs12))) /// 
	(matrix(income[,2]), ci((income[,5] income[,6])) `options2' ciopts(lcolor(gs10))) ///
	(matrix(selfc[,2]), ci((selfc[,5] selfc[,6])) `options3' ciopts(lcolor(gs8))) ///
	(matrix(experience[,2]), ci((experience[,5] experience[,6])) `options4' ciopts(lcolor(gs6))) ///
	(matrix(other[,2]), ci((other[,5] other[,6])) `options5' ciopts(lcolor(gs4))), ///
	headings("common_asks" = "{bf:Family}" "loan_amt" = "{bf:Income}" ///
	"pb" = "{bf:Self Control}" "pawn_before" = "{bf:Experience}" "water" = "{bf:Other}",labsize(vsmall)) ///
	legend(off) offset(0) xline(0) `graphregion' `plotregion' ylabel(,labsize( tiny ))	
}
if "`depvar'" == "des_c" & "`treat'" == "pro_3"{
	mat rownames family = "lack"  "common_asks" "fam_asks"
	mat rownames income = "loan_amt" "saves" "low_time" "low_cost"
	mat rownames selfc = "fb" "tempt" "makes_budget" "pb" 
	mat rownames experience = "pr_recovery" "pawn_before" "visits" "relay"
	mat rownames other = "food" "water" "gas"  "electricity" "stressed" "medicine" ///
	"rent" "phone" "gender" "age" "more_high_school"

coefplot (matrix(family[,2]), ci((family[,5] family[,6])) `options1' ciopts(lcolor(gs12))) /// 
	(matrix(income[,2]), ci((income[,5] income[,6])) `options2' ciopts(lcolor(gs10))) ///
	(matrix(selfc[,2]), ci((selfc[,5] selfc[,6])) `options3' ciopts(lcolor(gs8))) ///
	(matrix(experience[,2]), ci((experience[,5] experience[,6])) `options4' ciopts(lcolor(gs6))) ///
	(matrix(other[,2]), ci((other[,5] other[,6])) `options5' ciopts(lcolor(gs4))), ///
	headings("lack" = "{bf:Family}" "loan_amt" = "{bf:Income}" ///
	"fb" = "{bf:Self Control}" "pr_recovery" = "{bf:Experience}" "food" = "{bf:Other}",labsize(vsmall)) ///
	legend(off) offset(0) xline(0) `graphregion' `plotregion' ylabel(,labsize( tiny ))	
}
if "`depvar'" == "des_c" & "`treat'" == "pro_4"{
	mat rownames family = "lack" "fam_asks" "common_asks"
	mat rownames income = "low_time" "loan_amt" "low_cost" "saves"  
	mat rownames selfc = "pb"  "tempt" "makes_budget" "fb" 
	mat rownames experience = "pr_recovery" "pawn_before" "relay" "visits" 
	mat rownames other = "phone" "medicine" "electricity" "gas" ///
	"food" "water" "gender" "stressed" "rent"  "age" "more_high_school"
	
coefplot (matrix(family[,2]), ci((family[,5] family[,6])) `options1' ciopts(lcolor(gs12))) /// 
	(matrix(income[,2]), ci((income[,5] income[,6])) `options2' ciopts(lcolor(gs10))) ///
	(matrix(selfc[,2]), ci((selfc[,5] selfc[,6])) `options3' ciopts(lcolor(gs8))) ///
	(matrix(experience[,2]), ci((experience[,5] experience[,6])) `options4' ciopts(lcolor(gs6))) ///
	(matrix(other[,2]), ci((other[,5] other[,6])) `options5' ciopts(lcolor(gs4))), ///
	headings("lack" = "{bf:Family}" "low_time" = "{bf:Income}" ///
	"pb" = "{bf:Self Control}" "pr_recovery" = "{bf:Experience}" "phone" = "{bf:Other}",labsize(vsmall)) ///
	legend(off) offset(0) xline(0) `graphregion' `plotregion' ylabel(,labsize( tiny ))	
}
if "`depvar'" == "des_c" & "`treat'" == "pro_5"{
	mat rownames family = "lack" "common_asks" "fam_asks" 
	mat rownames income = "saves" "loan_amt" "low_cost" "low_time"  
	mat rownames selfc = "fb"  "tempt" "fb" "makes_budget"  
	mat rownames experience = "relay" "pr_recovery" "visits" "pawn_before" 
	mat rownames other = "phone" "rent" "food" "medicine" "water" ///
	"gas" "electricity" "stressed" "gender" "age" "more_high_school"
	
coefplot (matrix(family[,2]), ci((family[,5] family[,6])) `options1' ciopts(lcolor(gs12))) /// 
	(matrix(income[,2]), ci((income[,5] income[,6])) `options2' ciopts(lcolor(gs10))) ///
	(matrix(selfc[,2]), ci((selfc[,5] selfc[,6])) `options3' ciopts(lcolor(gs8))) ///
	(matrix(experience[,2]), ci((experience[,5] experience[,6])) `options4' ciopts(lcolor(gs6))) ///
	(matrix(other[,2]), ci((other[,5] other[,6])) `options5' ciopts(lcolor(gs4))), ///
	headings("lack" = "{bf:Family}" "saves" = "{bf:Income}" ///
	"fb" = "{bf:Self Control}" "phone" = "{bf:Experience}" "phone" = "{bf:Other}",labsize(vsmall)) ///
	legend(off) offset(0) xline(0) `graphregion' `plotregion' ylabel(,labsize( tiny ))	
}
graph export "$directorio\Figuras\HE\he_int_vertical_`depvar'_`treat'.pdf", replace







