clear all
set more off

********************************************************************************

* a plugin has to be explicitly loaded (unlike an ado file)
* "capture" means that if it's loaded already this line won't give an error

*Directory for .\boost64.dll 
cd "$directorio"
*cd D:\WKDir-Stata
capture program drop boost_plugin
program boost_plugin, plugin using("$directorio\boost64.dll")

set more off
set seed 12345678

********************************************************************************
*Dependent variable
global dep_var pago_frec_voluntario
*Independent variable (not factor variables)
global ind_var dummy_dow1-dummy_dow5 dummy_suc1-dummy_suc5 /// *Controls
	prestamo pr_recup  edad visit_number faltas /// *Continuous covariates
	dummy_prenda_tipo1-dummy_prenda_tipo4 dummy_edo_civil1-dummy_edo_civil3  /// *Categorical covariates
	dummy_choose_same1-dummy_choose_same2   /// 
	genero pres_antes fam_pide fam_comun ahorros cta_tanda /// *Dummy variables
	masqueprepa estresado_seguido pb fb hace_presupuesto tentado low_cost low_time
	
*Independent variables (factor variables)
global ind_var_factor 
*Train fraction
global trainf=0.90
*Directory for plots
global plot "$directorio/Figuras/Boost"
*Activate profiler (=1)
global profiler=0
********************************************************************************


	
********************************************************************************
*Data preparation		

import delimited "C:\Users\xps-seira\Downloads\data_pfv.csv", clear 

********************************************************************************

********************************************************************************

*Drop missing values
foreach var of varlist $ind_var {
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
global trainn= round($trainf *`r(N)'+1)	


********************************************************************************
*Summary statistics for independent variables

su $ind_var


*Summary statistics for independent variables IN SAMPLE

qui reg $dep_var $ind_var  in 1/$trainn

su $ind_var if e(sample)


	
********************************************************************************
*Logistic Regression

capture drop logit_pred logit_pred2
capture profiler clear 
profiler on
logistic $dep_var $ind_var  in 1/$trainn
profiler off
if $profiler ==1 { 
	profiler report 
	}  

predict logit_pred 
cap drop perc
xtile perc = logit_pred, nq(100)
qui su $dep_var
gen logit_pred2w = (perc>=(100*(1-`r(mean)')))

********************************************************************************

********************************************************************************
*Stepwise Logistic Regression

capture drop swlogit_pred swlogit_pred2
capture profiler clear 
profiler on
sw logistic  $dep_var $ind_var $ind_var_factor  in 1/$trainn , pr(0.15)  
profiler off
if $profiler ==1 { 
	profiler report 
	}  

predict swlogit_pred 
cap drop perc
xtile perc = swlogit_pred, nq(100)
qui su $dep_var
gen swlogit_pred2 = (perc>=(100*(1-`r(mean)')))


********************************************************************************

********************************************************************************
*Kernel Regression Least Squares

capture drop krls_pred krls_pred2
capture profiler clear 
profiler on
krls  $dep_var $ind_var   in 1/$trainn   
profiler off
if $profiler ==1 { 
	profiler report 
	}  

predict krls_pred 
cap drop perc
xtile perc = krls_pred, nq(100)
qui su $dep_var
gen krls_pred2 = (perc>=(100*(1-`r(mean)')))


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
	boost $dep_var $ind_var , dist(logistic) train($trainf) maxiter(`tempiter') ///
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
profiler off 
if $profiler ==1 { 
	profiler report 
	}  
rename myinter interaction
twoway connected Rsquared inter, xtitle("Number of interactions") ///
	ytitle("R-squared") scheme(s2mono) graphregion(color(white)) 
graph export "$plot\boost_Rsquared.png", replace	width(1500)


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
						
capture drop boost_pred boost_pred2
capture profiler clear
profiler on
boost $dep_var $ind_var , dist(logistic) train($trainf) maxiter(`miter') bag(0.5) ///
	interaction(`opt_int') shrink(`shrink') pred("boost_pred") influence 
profiler off
if $profiler ==1 { 
	profiler report 
	}  
	
cap drop perc
xtile perc = boost_pred, nq(100)
qui su $dep_var
gen boost_pred2 = (perc>=(100*(1-`r(mean)')))
 
matrix influence = e(influence)

********************************************************************************


********************************************************************************
*Classification*
tab $dep_var

*Classification for the test data
tab $dep_var if _n>$trainn

********************************************************************************

*Expected value of predicted values
su $dep_var boost_pred logit_pred swlogit_pred krls_pred if _n >$trainn , d


*Difference in l1 of probabilities (predicted values)
qui gen error_boost=abs(boost_pred-	$dep_var) 
	su error_boost if _n>$trainn
qui gen error_logit=abs(logit_pred-	$dep_var) 
	su error_logit if _n>$trainn
qui gen error_swlogit=abs(swlogit_pred-	$dep_var) 
	su error_swlogit if _n>$trainn
qui gen error_krls=abs(krls_pred-	$dep_var) 
	su error_krls if _n>$trainn
	
*Fitness
tab boost_pred2 $dep_var if _n>$trainn, cell
tab logit_pred2 $dep_var  if _n > $trainn, cell
tab swlogit_pred2 $dep_var  if _n > $trainn, cell
tab krls_pred2 $dep_var  if _n > $trainn, cell

*Correlation
corr $dep_var boost_pred2 logit_pred2 swlogit_pred2 krls_pred2 if _n>$trainn
corr $dep_var boost_pred logit_pred swlogit_pred krls_pred if _n>$trainn

********************************************************************************


********************************************************************************
*Compare the R^2 of boosted and linear models on test data

* compute Rsquared on test data - logit

gen regress_eps=$dep_var-logit_pred 
gen regress_eps2= regress_eps*regress_eps 
replace regress_eps2=0 if _n<=$trainn  
gen regress_ss=sum(regress_eps2)
local mse=regress_ss[_N] / (_N-$trainn)
sum $dep_var if _n>$trainn
local var=r(Var)
local regress_r2= (`var'-`mse')/`var'
di " "
di "Logit regression : mse=" `mse' " var=" `var'  " regress r2="  `regress_r2'

* compute Rsquared on test data - stepwise logit

gen swregress_eps=$dep_var-swlogit_pred 
gen swregress_eps2= swregress_eps*swregress_eps 
replace swregress_eps2=0 if _n<=$trainn  
gen swregress_ss=sum(swregress_eps2)
local mse=swregress_ss[_N] / (_N-$trainn)
sum $dep_var if _n>$trainn
local var=r(Var)
local swregress_r2= (`var'-`mse')/`var'
di " "
di "Stepwise Logit regression : mse=" `mse' " var=" `var'  " regress r2="  `swregress_r2'

* compute Rsquared on test data - krls

gen krlsregress_eps=$dep_var-krls_pred 
gen krlsregress_eps2= krlsregress_eps*krlsregress_eps 
replace krlsregress_eps2=0 if _n<=$trainn  
gen krlsregress_ss=sum(krlsregress_eps2)
local mse=krlsregress_ss[_N] / (_N-$trainn)
sum $dep_var if _n>$trainn
local var=r(Var)
local krlsregress_r2= (`var'-`mse')/`var'
di " "
di "KRLS: mse=" `mse' " var=" `var'  " regress r2="  `krlsregress_r2'

* compute Rsquared on test data - boosting

gen boost_eps=$dep_var-boost_pred 
gen boost_eps2= boost_eps*boost_eps 
replace boost_eps2=0 if _n<=$trainn  
gen boost_ss=sum(boost_eps2)
local mse=boost_ss[_N] / (_N-$trainn)
sum $dep_var if _n>$trainn
local var=r(Var)
local boost_r2= (`var'-`mse')/`var'
di " "
di "Boosting:  mse=" `mse' " var=" `var'  " boost r2="  `boost_r2'

********************************************************************************


********************************************************************************
* Calibration plot
* scatter plot of predicted versus actual values of $dep_var
* a straight line would indicate a perfect fit
local trainm1=$trainn +1
qui count
gen straight=.
replace straight=$dep_var
twoway  (lowess $dep_var  logit_pred  in 1/$trainn, bwidth(0.2) clpattern(dot)) ///
		(lowess $dep_var boost_pred in 1/$trainn , bwidth(0.2) clpattern(dash)) ///
		(lowess $dep_var  krls_pred  in 1/$trainn, bwidth(0.2) clpattern(dash_dot)) ///
		(lfit straight $dep_var)  , xtitle("Fitted Values") ///
		legend(label(1 "Logistic Regression") label(2 "Boosting") label(3 "KRLS") ///
		label(4 "Fitted Values=Actual Values") )  graphregion(color(white))
graph export "$plot\boost_calibration_insample.png", replace	width(1500)		

local trainm1=$trainn +1
qui count		
twoway  (lowess $dep_var  logit_pred  in `trainm1'/`r(N)', bwidth(0.2) clpattern(dot)) ///
        (lowess $dep_var boost_pred in `trainm1'/`r(N)' , bwidth(0.2) clpattern(dash)) ///
		(lowess $dep_var  krls_pred  in `trainm1'/`r(N)', bwidth(0.2) clpattern(dash_dot)) ///
		(lfit straight $dep_var)  , xtitle("Fitted Values") ///
		legend(label(1 "Logistic Regression") label(2 "Boosting") label(3 "KRLS") ///
		label(4 "Fitted Values=Actual Values") )  graphregion(color(white))
graph export "$plot\boost_calibration_outsample.png", replace	width(1500)
********************************************************************************



********************************************************************************
*Influence plot
svmat influence
gen id=_n
replace id=. if missing(influence)


graph bar (mean) influence, over(id) ytitle(Percentage Influence) ///
	scheme(s2mono) graphregion(color(white))
graph export "$plot\boost_influence.png", replace	width(1500)

********************************************************************************


********************************************************************************
*ROC curve
gen insample=1 in 1/$trainn
replace insample=0 if missing(insample)

preserve

local sm=90
sample `sm'

capture profiler clear
profiler on
	*In sample
roccomp $dep_var logit_pred swlogit_pred krls_pred boost_pred  if insample==1 , graph summary ///
	legend(label(1 "Logit") label(2 "SW Logit") label(3 "KRLS") ///
		label(4 "Boosting") label(5 "Reference"))  graphregion(color(white))
profiler off
if $profiler ==1 { 
	profiler report 
	}  
graph export "$plot\ROC_curve_insample.png", replace	width(1500)

capture profiler clear
profiler on
	*Out of sample
roccomp $dep_var logit_pred swlogit_pred krls_pred boost_pred if insample==0 , graph summary ///
	legend(label(1 "Logit") label(2 "SW Logit") label(3 "KRLS") ///
		label(4 "Boosting") label(5 "Reference"))  graphregion(color(white))
profiler off
if $profiler ==1 { 
	profiler report 
	}  
graph export "$plot\ROC_curve_outsample.png", replace	width(1500)
restore
********************************************************************************



save "$directorio\DB\boost.dta", replace

