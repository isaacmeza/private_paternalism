
********************************************************************************
*Logistic Regression

capture drop logit_pred logit_pred2
capture profiler clear 
profiler on
logistic $depvar $ind_var  if insample==1
profiler off
if $profiler ==1 { 
	profiler report 
	}  

predict logit_pred 
cap drop perc
xtile perc = logit_pred, nq(100)
qui su $depvar if insample==0
gen logit_pred2 = (perc>=(100*(1-`r(mean)')))

********************************************************************************

********************************************************************************
*Stepwise Logistic Regression

capture drop swlogit_pred swlogit_pred2
capture profiler clear 
profiler on
sw logistic  $depvar $ind_var  if insample==1 , pr(0.15)  
profiler off
if $profiler ==1 { 
	profiler report 
	}  

predict swlogit_pred 
cap drop perc
xtile perc = swlogit_pred, nq(100)
qui su $depvar if insample==0
gen swlogit_pred2 = (perc>=(100*(1-`r(mean)')))


********************************************************************************

********************************************************************************
*Random Forest (RUNNED IN R)

cap drop perc
xtile perc = rf_pred, nq(100)
qui su $depvar if insample==0
gen rf_pred2 = (perc>=(100*(1-`r(mean)')))


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
foreach inter of numlist 1 2 4 7 10 {
	local i=`i'+1
    replace myinter= `inter' in `i'
	boost $depvar $ind_var if insample==1, dist(logistic) train($trainf) maxiter(`tempiter') ///
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
graph export "$plot\boost_Rsquared_${depvar}.png", replace	width(1500)


********************************************************************************


********************************************************************************
*Boosting 

qui egen maxrsq=max(Rsquared)
qui gen iden=_n if Rsquared==maxrsq
qui su iden

local opt_int=`r(min)'		/*Optimum interaction according to previous process*/

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
boost $depvar $ind_var if insample==1, dist(logistic) train($trainf) maxiter(`miter') bag(0.5) ///
	interaction(`opt_int') shrink(`shrink') pred("boost_pred") influence 
profiler off
if $profiler ==1 { 
	profiler report 
	}  
	
cap drop perc
xtile perc = boost_pred, nq(100)
qui su $depvar if insample==0
gen boost_pred2 = (perc>=(100*(1-`r(mean)')))
 
matrix influence = e(influence)

********************************************************************************


********************************************************************************
*Classification*
tab $depvar

*Classification for the test data
tab $depvar if insample==0

********************************************************************************


local t = 8
foreach method in logit swlogit rf boost {
	local Col=substr(c(ALPHA),2*`t'+1,1)
	*Expected value of predicted values
	su `method'_pred  if insample==0 , d
	qui putexcel set "$directorio\Tables\\${oos}.xlsx", ///
		sheet("oos_${depvar}") modify
	qui putexcel `Col'14=(`r(mean)')  
		
	*MAE	
	qui gen error_`method'=abs(`method'_pred- $depvar) 
	su error_`method' if insample==0
	qui putexcel `Col'4=(`r(mean)')
		
	*Accuracy
	tab `method'_pred2 $depvar if insample==0, matcell(tb)
	local acc = (tb[1,1]+tb[2,2])/(tb[1,1]+tb[2,2]+tb[1,2]+tb[2,1])
	qui putexcel `Col'10=(`acc')
	
	*Correlation 0-1
	corr $depvar `method'_pred2 if insample==0
	qui putexcel `Col'11=(`r(rho)') 
		
	*Correlation predicted val
	corr $depvar `method'_pred if insample==0
	qui putexcel `Col'12=(`r(rho)') 	
	
	*MSE
	gen `method'_eps=${depvar}-`method'_pred 
	gen `method'_eps2= `method'_eps*`method'_eps 
	replace `method'_eps2=0 if insample==1
	gen `method'_ss=sum(`method'_eps2)
	count if insample==0
	local mse=`method'_ss[_N] / (`r(N)')
	qui putexcel `Col'5=(`mse') 
	
	sum $depvar if insample==0
	local var=r(Var)
	
	*R2
	local r2= (`var'-`mse')/`var'
	qui putexcel `Col'13=(`r2') 

	*AUC (oos)
	roctab $depvar `method'_pred if insample==0
	qui putexcel `Col'6=(`r(area)') 	 
	qui putexcel `Col'7=(`r(se)') 	
		
	*AUC (in sample)
	roctab $depvar `method'_pred if insample==1
	qui putexcel `Col'8=(`r(area)')  
	qui putexcel `Col'9=(`r(se)') 	
		
		
	local t = `t'+1	
	}


	
********************************************************************************



********************************************************************************
* Calibration plot
* scatter plot of predicted versus actual values of $depvar
* a straight line would indicate a perfect fit
local trainm1=$trainn +1
qui count
gen straight=.
replace straight=$depvar
twoway  (lowess $depvar  logit_pred  if insample==1, bwidth(0.2) clpattern(dot)) ///
		(lowess $depvar boost_pred if insample==1 , bwidth(0.2) clpattern(dash)) ///
		(lowess $depvar  rf_pred  if insample==1, bwidth(0.2) clpattern(dash_dot)) ///
		(lfit straight $depvar)  , xtitle("Fitted Values") ///
		legend(label(1 "Logistic Regression") label(2 "Boosting") label(3 "RF") ///
		label(4 "Fitted Values=Actual Values") )  graphregion(color(white))
graph export "$plot\boost_calibration_insample_${depvar}.png", replace	width(1500)		

local trainm1=$trainn +1
qui count		
twoway  (lowess $depvar  logit_pred  if insample==0, bwidth(0.2) clpattern(dot)) ///
        (lowess $depvar boost_pred if insample==0 , bwidth(0.2) clpattern(dash)) ///
		(lowess $depvar  rf_pred  if insample==0, bwidth(0.2) clpattern(dash_dot)) ///
		(lfit straight $depvar)  , xtitle("Fitted Values") ///
		legend(label(1 "Logistic Regression") label(2 "Boosting") label(3 "RF") ///
		label(4 "Fitted Values=Actual Values") )  graphregion(color(white))
graph export "$plot\boost_calibration_outsample_${depvar}.png", replace	width(1500)
********************************************************************************



********************************************************************************
*Influence plot
svmat influence
gen id=_n
replace id=. if missing(influence)


graph bar (mean) influence, over(id) ytitle(Percentage Influence) ///
	scheme(s2mono) graphregion(color(white))
graph export "$plot\boost_influence_${depvar}.png", replace	width(1500)

********************************************************************************


********************************************************************************
*ROC curve
preserve
discard
local sm=45
sample `sm'

capture profiler clear
profiler on
	*In sample
cap roccomp $depvar logit_pred swlogit_pred rf_pred boost_pred  if insample==1 , graph summary ///
	legend(label(1 "Logit") label(2 "SW Logit") label(3 "RF") ///
		label(4 "Boosting") label(5 "Reference"))  graphregion(color(white))
profiler off
if $profiler ==1 { 
	profiler report 
	}  
cap graph export "$plot\ROC_curve_insample_${depvar}.png", replace	width(1500)

capture profiler clear
profiler on
	*Out of sample
cap roccomp $depvar logit_pred swlogit_pred rf_pred boost_pred if insample==0 , graph summary ///
	legend(label(1 "Logit") label(2 "SW Logit") label(3 "RF") ///
		label(4 "Boosting") label(5 "Reference"))  graphregion(color(white))
profiler off
if $profiler ==1 { 
	profiler report 
	}  
cap graph export "$plot\ROC_curve_outsample_${depvar}.pdf", replace	
restore
********************************************************************************



save "$directorio\DB\boost_${depvar}.dta", replace

