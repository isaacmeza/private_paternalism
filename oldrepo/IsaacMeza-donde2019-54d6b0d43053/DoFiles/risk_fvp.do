*Are frequent voluntary payment individuals more risky?

capture program drop boost_plugin
program boost_plugin, plugin using("$directorio\boost64.dll")

set more off
set seed 12345678
********************************************************************************
use "$directorio/DB/master.dta", clear

*Aux Dummies 
foreach var of varlist dow suc prenda_tipo edo_civil choose_same trabajo {
	tab `var', gen(dummy_`var')
	}

sort NombrePignorante fecha_inicial

*Covariates - Randomization - Outcomes
keep des_c producto  /// *Admin variables
	dummy_dow1-dummy_dow5 dummy_suc1-dummy_suc5 /// *Controls
	prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	dummy_prenda_tipo1-dummy_prenda_tipo4 dummy_edo_civil1-dummy_edo_civil3  /// *Categorical covariates
	dummy_choose_same1-dummy_choose_same2   /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time
********************************************************************************

*Dependent variable
global dep_var des_c


*Independent variable	
global ind_var dummy_dow1-dummy_dow5 dummy_suc1-dummy_suc5 /// *Controls
	prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	dummy_prenda_tipo1-dummy_prenda_tipo4 dummy_edo_civil1-dummy_edo_civil3  /// *Categorical covariates
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time
	
*Drop missing values
foreach var of varlist $ind_var {
	di "`var'"
	drop if missing(`var')
	}
		

*Estimate a model of default in control and no-choice arms and use it to measure
*riskyness in voluntary treatment arms


********************************************************************************
*Logistic Regression

capture drop logit_pred 
logistic $dep_var $ind_var if inlist(producto,1,2,3)

predict logit_pred 
********************************************************************************

********************************************************************************
gen Rsquared=.
gen bestiter=.
gen maxiter=.
gen myinter=.
local i=0
local maxiter=750
capture profiler clear 
profiler on
local tempiter=`maxiter'
foreach inter of numlist 1/6 8 10 15 20 {
	local i=`i'+1
    replace myinter= `inter' in `i'
	boost $dep_var $ind_var if inlist(producto,1,2,3), dist(logistic) train(0.9) maxiter(`tempiter') ///
		bag(0.5) interaction(`inter') shrink(0.1) 
	local maxiter=e(bestiter) 
	replace maxiter=`tempiter' in `i'
	replace bestiter=e(bestiter) in `i' 
	replace Rsquared=e(test_R2) in `i'
	* as the number of interactions increase the best number of iterations will decrease
	* to be safe I am allowing an extra 20% of iterations and in case maxiter equals bestiter we double the number of iter
	* when the number of interactions is large this can save a lot of time
	if ( maxiter[`i']-bestiter[`i']<60) {
		local tempiter= round(maxiter[`i']*2)+10
		}
	else {
		local tempiter=round( e(bestiter) * 1.2 )+10
		}
	}

rename myinter interaction
twoway connected Rsquared inter, xtitle("Number of interactions") ///
	ytitle("R-squared") scheme(s2mono) graphregion(color(white)) 
********************************************************************************


********************************************************************************
*Boosting 

qui egen maxrsq=max(Rsquared)
qui gen iden=_n if Rsquared==maxrsq
qui su iden

local opt_int=`r(mean)'		/*Optimum interaction according to previous process*/

if ( maxiter[`r(mean)']-bestiter[`r(mean)']<60) {
	local miter= round(maxiter[`r(mean)']*2.2+10)
	}
else {
	local miter=bestiter[`r(mean)']+120
	}
							/*Maximum number of iterations-if bestiter is closed to maxiter, 
							increase the number of max iter as the maximum likelihood 
							iteration may be larger*/
							
local shrink=0.05       	/*Lower shrinkage values usually improve the test R2 but 
							they increase the running time dramatically. 
							Shrinkage can be thought of as a step size*/						
						
capture drop boost_pred 
boost $dep_var $ind_var if inlist(producto,1,2,3) , dist(logistic) train(0.9) maxiter(`miter') bag(0.5) ///
	interaction(`opt_int') shrink(`shrink') pred("boost_pred") influence 
********************************************************************************

*Measures of fit (OOS)
keep if inlist(producto,4,5,6,7)


*Difference in l1 of probabilities (predicted values)
qui gen error_boost=abs(boost_pred-	$dep_var) 
	su error_boost 
qui gen error_logit=abs(logit_pred-	$dep_var) 
	su error_logit 

*Correlation
corr $dep_var boost_pred logit_pred  

*MSE
* - logit
gen regress_eps=$dep_var-logit_pred 
gen regress_eps2= regress_eps*regress_eps 
gen regress_ss=sum(regress_eps2)
count 
local mse=regress_ss[_N] / `r(N)'
di " "
di "Logit regression : mse=" `mse' 

* - boosting

gen boost_eps=$dep_var-boost_pred 
gen boost_eps2= boost_eps*boost_eps
gen boost_ss=sum(boost_eps2)
count 
local mse=boost_ss[_N] / `r(N)'
di " "
di "Boosting:  mse=" `mse' 

*ROC curve
roccomp $dep_var logit_pred  boost_pred  ,graph summary ///
	legend(label(1 "Logit") label(2 "Boosting") label(3 "Reference"))  graphregion(color(white))

********************************************************************************	

*Regression
gen pago_frec_vol=inlist(producto,5,7)
gen pago_frec_vol_fee=inlist(producto,5) if inlist(producto,4,5)
gen pago_frec_vol_promise=inlist(producto,7) if inlist(producto,6,7)
******************************************

reg logit_pred i.pago_frec_vol, r
reg boost_pred i.pago_frec_vol, r

reg logit_pred i.pago_frec_vol_fee, r
reg boost_pred i.pago_frec_vol_fee, r

reg logit_pred i.pago_frec_vol_promise, r
reg boost_pred i.pago_frec_vol_promise, r
