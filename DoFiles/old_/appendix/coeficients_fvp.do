args depvar  familia ingreso self_control ///
 experiencia otros 
 
local alpha = .05 // for 95% confidence intervals 
*Matriz para las variables de Familia
local fam = 0
foreach var of varlist `familia'{
	local fam = `fam'+1
}
matrix family = J(`fam', 6, .)
local row = 1
foreach var of varlist `familia'{
	qui reg rf_pred `var' if !missing(`treat'), r
	
	local rownms `rownms' rf_pred:`var'
	
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
*matsort family 2 "down"
mat l family

*Matriz para las variables de Ingreso
local ing = 0
foreach var of varlist `ingreso'{
	local ing = `ing'+1
}
matrix income = J(`ing', 6, .)
local row = 1
foreach var of varlist `ingreso'{
	qui reg rf_pred `var' if !missing(`treat'), r
	local rownames `rownames' rf_pred:`var'
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
*matsort income 2 "down"
mat l income


*Matriz para las variables de Self Control
local self = 0
foreach var of varlist `self_control'{
	local self = `self'+1
}
matrix selfc = J(`self', 6, .)
local row = 1
foreach var of varlist `self_control'{
	qui reg rf_pred `var' if !missing(`treat'), r
	local rownms1 `rownms1' rf_pred:`var'
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
*matsort selfc 2 "down"
mat l selfc

*Matriz para las variables de Experiencia
local exp = 0
foreach var of varlist `experiencia'{
	local exp = `exp'+1
}
matrix experience = J(`exp', 6, .)
local row = 1
foreach var of varlist `experiencia'{
	qui reg rf_pred `var' if !missing(`treat'), r
	local rownms2 `rownms2' rf_pred:`var'
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
*matsort experience 2 "down"
mat l experience

*Matriz para las variables de Otros
local ot = 0
foreach var of varlist `otros'{
	local ot = `ot'+1
}
matrix other = J(`ot', 6, .)
local row = 1
foreach var of varlist `otros'{
	qui reg rf_pred `var' if !missing(`treat'), r
	local rownms3 `rownms3' rf_pred:`var'
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
*matsort other 2 "down"
mat l other


local options1 mcolor(gs11) msymbol(O)  msize(small) color(gs11)
local options2 mcolor(gs10) msymbol(O)  msize(small) color(gs10)
local options3 mcolor(gs8) msymbol(O)  msize(small) color(gs8)
local options4 mcolor(gs6) msymbol(O)  msize(small) color(gs6)
local options5 mcolor(gs4) msymbol(O)  msize(small) color(gs4)
local graphregion graphregion(fcolor(white) lstyle(none) color(white)) 
local plotregion plotregion(margin(sides) fcolor(white) lstyle(none) lcolor(white)) 


mat rownames family =  "Fam asks" "Common asks"
mat rownames income = "Income index" "Savings"
mat rownames selfc =  "Present bias"  "Makes budget" "Tempt" "Reminder"
mat rownames experience = "Pawn before" "Rosca" "Prob recovery" "Visits"
mat rownames other =  "Age"  "Gender" ///
	"More high school" "Stressed" "Low time" "Low cost"	
	 
	coefplot (matrix(family[,2]), ci((family[,5] family[,6])) `options1' ciopts(lcolor(gs11))) /// 
	(matrix(income[,2]), ci((income[,5] income[,6])) `options2' ciopts(lcolor(gs10))) ///
	(matrix(selfc[,2]), ci((selfc[,5] selfc[,6])) `options3' ciopts(lcolor(gs8))) ///
	(matrix(experience[,2]), ci((experience[,5] experience[,6])) `options4' ciopts(lcolor(gs6))) ///
	(matrix(other[,2]), ci((other[,5] other[,6])) `options5' ciopts(lcolor(gs4))), ///
	headings("Fam asks" = "{bf:Family}" "Income index" = "{bf:Income}" ///
	"Present bias" = "{bf:Self Control}" "Pawn before" = "{bf:Experience}" "Age" = "{bf:Other}",labsize(medium)) ///
	legend(off) offset(0) xline(0) `graphregion' `plotregion'  
graph export "$directorio\Figuras\\`depvar'_interactions_rf.pdf", replace
