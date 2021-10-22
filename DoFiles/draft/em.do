*EM

use "$directorio/DB/Master.dta", clear


gen choose_commitment =  (producto==5 | producto==7) if inlist(producto, 4, 5, 6, 7)
gen alt = (def_c==1 & choose_commitment==0) if inlist(producto, 4, 5, 6, 7)
*Define choices
gen choice = .
replace choice = 0 if def_c==0 & choose_commitment==0 & inlist(t_prod,4,5)
replace choice = 1 if def_c==1 & choose_commitment==0 & inlist(t_prod,4,5)
replace choice = 2 if def_c==0 & choose_commitment==1 & inlist(t_prod,4,5)
replace choice = 3 if def_c==1 & choose_commitment==1 & inlist(t_prod,4,5)


*replace choice = 2 if inlist(choice,3)


gen default = def_c if choose_commitment==0
 
fmm 2 if t_prod==4,  lcprob(genero OC pb fb   choose_commitment  prestamo faltas) emopts(iter(50))  difficult technique(nr) startvalues(randomid)  : logit def_c



keep if t_prod==4

**(1) Set the estimation framework**
global depvar des_c
global X ""
global W "genero pb fb OC choose_commitment prestamo faltas"
global nclasses "4"
global niter "500"
		global scll "0.000001"										/*percentage change of the log likelihho in order to declare convergence*/ 

		global itermin = 10
 
** Create auxiliary variables 
tab $depvar, gen(V) 
** Obtain number of choices
by $depvar, sort: gen nvals = _n == 1 
count if nvals & !missing($depvar)
global C = `r(N)'


**(2) Split the sample**
generate double _p = runiform() 
local prop 1/$nclasses
generate double _type = 1 if _p<=`prop'
forvalues k = 2/$nclasses {
	replace _type = `k' if (_p>(`k'-1)*`prop' & _p<=`k'*`prop')
}
	
**(3) Get starting values for both the beta coefficients and the class shares**
generate double _sdenom = 0

forvalues k = 1/$nclasses {
	*
	generate double _alpha_hat_i_`k' = (_type==`k')
	egen double _suma`k' = sum(_alpha_hat_i_`k')
	replace _sdenom = _sdenom + _suma`k'
	
	noi mlogit $depvar $X  [iw = _alpha_hat_i_`k'], technique(nr dfp) base(0) difficult iter(500)
	* Probability of type k of choosing _*
	predict double _prob_`k'_*
	
	**(4) Compute the density**
	forvalues c = 1/$C {
		generate double _obs_prob_`k'_`c' = _prob_`k'_`c'*V`c'
	} 
	egen double _den`k' = rowtotal(_obs_prob_`k'_*)
}
	
* Compute shares of type	
forvalues k = 1/$nclasses {	
	generate double _alpha_hat_`k' = _suma`k'/_sdenom	
}

**(5) Compute the predicted posterior probability**
generate double _denom = _alpha_hat_1*_den1
forvalues k = 2/$nclasses {
	replace _denom = _denom + _alpha_hat_`k'*_den`k'
	}	

forvalues k = 1/$nclasses {
	 generate double _alpha_tilde_`k' = (_alpha_hat_`k'*_den`k')/_denom
}	



**(7) Provide Stata with the ML command for the grouped-data model**
cap program drop logit_lf
program logit_lf
	args lnf tt2 tt3 tt4 tt5 tt6 tt7 tt8 tt9 tt10 
	tempvar denom   
	* Computation of likelihood
	generate double `denom' = 1   
	forvalues k = 2/$nclasses {
		replace `denom' = `denom' + exp(`tt`k'')
	}
	di "aqui"
	replace `lnf' = _alpha_tilde_1*ln(1/`denom') 

	forvalues k = 2/$nclasses  {
	replace `lnf' = `lnf' + _alpha_tilde_`k'*ln(exp(`tt`k'')/`denom')
	}
	replace `lnf' = 0 if `lnf'==.
end

qui {
local i = 1
while `i'<=$niter {
	**(8) Update the probability of the agent choice**
	capture drop _prob_* _obs_prob_* _den* 
	forvalues k = 1/$nclasses {
		di "hola"
		 mlogit $depvar $X [iw = _alpha_tilde_`k'], technique(nr dfp) base(0) difficult iter(500)
		* Probability of type k of choosing _*
		predict double _prob_`k'_*
		
		* Compute the density
		forvalues c = 1/$C {
			generate double _obs_prob_`k'_`c' = _prob_`k'_`c'*V`c'
		} 
		egen double _den`k' = rowtotal(_obs_prob_`k'_*)
		}
	
	**(9) Update the class share probabilities:
	global variables="($W)"
	forvalues k = 3/$nclasses  {
		global variables="$variables ($W)"
		}
		di "que"
	 ml model lf logit_lf $variables, max search(on) difficult iter(500) technique(nr dfp)
	di "pedo"
	cap drop  _tt*
	generate double _denom_= 1
	di "si"
	forvalues k = 2/$nclasses {
		local s = `k' - 1  
		predict double _tt`k', eq(eq`s')
		replace _denom_ = _denom_ + exp(_tt`k')
	}
	* Update the predicted probability for individual i, type k
	replace _alpha_hat_i_1 = 1/_denom_ 
	forvalues k = 2/$nclasses {
		replace _alpha_hat_i_`k'=exp(_tt`k')/(_denom_)
	}
di "aqui esta"	
	* Update the shares of types
	capture drop _sdenom _suma*
	generate double _sdenom = 0
	forvalues k = 1/$nclasses {
		egen double _suma`k' = sum(_alpha_hat_i_`k')
		replace _sdenom = _sdenom + _suma`k'	
	}
	forvalues k = 1/$nclasses {	
		replace _alpha_hat_`k' = _suma`k'/_sdenom	
	}

	**(10)  Compute the predicted posterior probability**
	generate double _denom = _alpha_hat_1*_den1
	forvalues k = 2/$nclasses {
		replace _denom = _denom + _alpha_hat_`k'*_den`k'
	}	

	forvalues k = 1/$nclasses {
		 replace _alpha_tilde_`k' = (_alpha_hat_`k'*_den`k')/_denom
	}	
	
	di "ya mero"
	**(12) Update the log likelihood**
	capture drop _sumll
	egen double _sumll = sum(ln(_denom))
	**(13) Check for convergence**
	sum _sumll
	global double z = `r(mean)'
	local _sl`i' = $z
	if `i'>=$itermin {
		local a = `i'-5
		if (-(`_sl`i'' - `_sl`a'')/`_sl`a''<= $scll) {
			continue, break
		}
	}
	**(14) If not converged, display the log likelihood and restart the loop**
	di "ya no?"
	noi display as green "Iteration " `i' ": log likelihood = " as yellow  $z 
	local i = `i' + 1
}
}	
	di "`i'"
	
   *-------------------------------------
    * Show results and clean up the data |
    *-------------------------------------
set more off
forvalues k = 1/$nclasses{ 
di ""
di as white "Results for type `k':"
 mlogit $depvar $X [iw = _alpha_tilde_`k'], technique(nr dfp) base(0) difficult iter(500)
}

su _alpha_tilde_*


	* Update the shares of types
	capture drop _sdenom _suma*
	generate double _sdenom = 0
	forvalues k = 1/$nclasses {
		egen double _suma`k' = sum(_alpha_tilde_`k')
		replace _sdenom = _sdenom + _suma`k'	
	}
	forvalues k = 1/$nclasses {	
		generate double _share`k' = _suma`k'/_sdenom	
	}
	
	su _share*
	
 ml model lf logit_lf $variables
 ml maximize	
	
	
	
	
	
	
	
	
	
	
