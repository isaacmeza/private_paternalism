
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
*Random Forest (RUN IN R)

cap drop perc
xtile perc = rf_pred, nq(100)
qui su $dep_var
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
graph export "$plot\boost_Rsquared_${dep_var}.png", replace	width(1500)


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


local t = 8
foreach method in logit swlogit rf boost {
	local Col=substr(c(ALPHA),2*`t'+1,1)
	*Expected value of predicted values
	su `method'_pred  if _n >$trainn , d
	qui putexcel `Col'14=(`r(mean)') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify
		
	*MAE	
	qui gen error_`method'=abs(`method'_pred- $dep_var) 
	su error_`method' if _n>$trainn
	qui putexcel `Col'4=(`r(mean)') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify
		
	*Accuracy
	tab `method'_pred2 $dep_var if _n>$trainn, matcell(tb)
	local acc = (tb[1,1]+tb[2,2])/(tb[1,1]+tb[2,2]+tb[1,2]+tb[2,1])
	qui putexcel `Col'10=(`acc') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify
	
	*Correlation 0-1
	corr $dep_var `method'_pred2 if _n>$trainn
	qui putexcel `Col'11=(`r(rho)') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify
		
	*Correlation predicted val
	corr $dep_var `method'_pred if _n>$trainn
	qui putexcel `Col'12=(`r(rho)') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify	
	
	*MSE
	gen `method'_eps=${dep_var}-`method'_pred 
	gen `method'_eps2= `method'_eps*`method'_eps 
	replace `method'_eps2=0 if _n<=$trainn  
	gen `method'_ss=sum(`method'_eps2)
	local mse=`method'_ss[_N] / (_N-$trainn)
	qui putexcel `Col'5=(`mse') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify
	
	sum $dep_var if _n>$trainn
	local var=r(Var)
	
	*R2
	local r2= (`var'-`mse')/`var'
	qui putexcel `Col'13=(`r2') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify

	*AUC (oos)
	roctab $dep_var `method'_pred if insample==0
	qui putexcel `Col'6=(`r(area)') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify	 
	qui putexcel `Col'7=(`r(se)') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify	
		
	*AUC (in sample)
	roctab $dep_var `method'_pred if insample==1
	qui putexcel `Col'8=(`r(area)') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify	 
	qui putexcel `Col'9=(`r(se)') using "$directorio\Tables\oos.xlsx", ///
		sheet("oos_${dep_var}") modify	
		
		
	local t = `t'+1	
	}


	
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
		(lowess $dep_var  rf_pred  in 1/$trainn, bwidth(0.2) clpattern(dash_dot)) ///
		(lfit straight $dep_var)  , xtitle("Fitted Values") ///
		legend(label(1 "Logistic Regression") label(2 "Boosting") label(3 "RF") ///
		label(4 "Fitted Values=Actual Values") )  graphregion(color(white))
graph export "$plot\boost_calibration_insample_${dep_var}.png", replace	width(1500)		

local trainm1=$trainn +1
qui count		
twoway  (lowess $dep_var  logit_pred  in `trainm1'/`r(N)', bwidth(0.2) clpattern(dot)) ///
        (lowess $dep_var boost_pred in `trainm1'/`r(N)' , bwidth(0.2) clpattern(dash)) ///
		(lowess $dep_var  rf_pred  in `trainm1'/`r(N)', bwidth(0.2) clpattern(dash_dot)) ///
		(lfit straight $dep_var)  , xtitle("Fitted Values") ///
		legend(label(1 "Logistic Regression") label(2 "Boosting") label(3 "RF") ///
		label(4 "Fitted Values=Actual Values") )  graphregion(color(white))
graph export "$plot\boost_calibration_outsample_${dep_var}.png", replace	width(1500)
********************************************************************************



********************************************************************************
*Influence plot
svmat influence
gen id=_n
replace id=. if missing(influence)


graph bar (mean) influence, over(id) ytitle(Percentage Influence) ///
	scheme(s2mono) graphregion(color(white))
graph export "$plot\boost_influence_${dep_var}.png", replace	width(1500)

********************************************************************************


********************************************************************************
*ROC curve
preserve
local sm=99
sample `sm'

capture profiler clear
profiler on
	*In sample
roccomp $dep_var logit_pred swlogit_pred rf_pred boost_pred  if insample==1 , graph summary ///
	legend(label(1 "Logit") label(2 "SW Logit") label(3 "RF") ///
		label(4 "Boosting") label(5 "Reference"))  graphregion(color(white))
profiler off
if $profiler ==1 { 
	profiler report 
	}  
graph export "$plot\ROC_curve_insample_${dep_var}.png", replace	width(1500)

capture profiler clear
profiler on
	*Out of sample
roccomp $dep_var logit_pred swlogit_pred rf_pred boost_pred if insample==0 , graph summary ///
	legend(label(1 "Logit") label(2 "SW Logit") label(3 "RF") ///
		label(4 "Boosting") label(5 "Reference"))  graphregion(color(white))
profiler off
if $profiler ==1 { 
	profiler report 
	}  
graph export "$plot\ROC_curve_outsample_${dep_var}.png", replace	width(1500)
restore
********************************************************************************



save "$directorio\DB\boost_${dep_var}.dta", replace

