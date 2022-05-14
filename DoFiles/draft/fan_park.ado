*! version 1.0.1  30apr2022
program fan_park, rclass
	version 17.0
	syntax varlist(min=2) [, delta_partition(integer 100) Delta_values(numlist ascending) cov_partition(integer 6) level(integer 5) Nograph seed(integer 1) Qbounds num_quantiles(integer 100)] 
	
	gettoken var rest : varlist
	gettoken treat indeps : rest
	
	*Check factor variable
    _fv_check_depvar `var'
	
	tempname bounds sigma_2 M_delta bounds_cond sigma_2_cond delta_val _clus_1 lb ub sigma_l_2 sigma_u_2 bounds_q bounds_q_cond q_val
	tempvar delta_range 
	

	qui {
	
	if "`indeps'"!="" {
			if `seed'==1 {
				local seed = runiformint(10, 2^31-1)
			}
			* Partition of covariate space
			cluster kmedians `indeps' , k(`cov_partition') gen(`_clus_1') start(krandom(`seed'))
			tab `_clus_1', matcell(freq)
			count if !missing(`_clus_1')
			forvalues c = 1/`cov_partition' {
				mat freq[`c',1] = freq[`c',1]/`r(N)'
			}
		}
		
	if "`qbounds'"=="" {	

		* Y_1 = [a,b], Y_0 = [c, d]
		su `var' if `treat'==1
		local n1_ = r(N)
		local a_ = r(min)
		local b_ = r(max)
		su `var' if `treat'==0
		local n0_ = r(N)
		local c_ = r(min)
		local d_ = r(max)
		
		* Define a partition of [a-d, b-c] 
		if "`delta_values'"=="" {
			range `delta_range' `=`a_'-`d_'' `=`b_'-`c_'' `=`delta_partition'+1'
			replace `delta_range' = . if _n==`=`delta_partition'+1'
			levelsof `delta_range', local(delta_vals) 
			mkmat `delta_range' if `delta_range'!=., matrix(`delta_val')
		}
		else {
			*Validate numlist is in [a-d, b-c] 
			local delta_vals  
			foreach delta of local delta_values {
				if `delta'>= `=`a_'-`d_'' & `delta' <=`=`b_'-`c_'' {
				local delta_vals  `delta_vals' `delta'	
				}
			}
			
			local delta_partition = 0
			foreach delta of local delta_vals {
				local delta_partition = `delta_partition' + 1
			}
			
			matrix `delta_val' = J(`delta_partition',1,.)
			local i = 1
			foreach delta of local delta_vals {
				matrix `delta_val'[`i',1] = `delta'
				local i = `i' + 1 
			}
		}

		* For any \delta\in [a-d, b-c] we define Y_\delta = [a,b] \cap [c+\delta, d+\delta]
		* F^L(\delta) = max {sup_{Y_\delta} {F_1(y)-F_0(y-\delta)} , 0}
		* F^U(\delta) = 1 + min {inf_{Y_\delta} {F_1(y)-F_0(y-\delta)} , 0}

		matrix `bounds' = J(`delta_partition', 2, .) 
		matrix `sigma_2' = J(`delta_partition', 2, .) 
		matrix `M_delta' = J(`delta_partition', 2, .) 

		matrix `bounds_cond' = J(`delta_partition', 2, 0) 
		matrix `sigma_2_cond' = J(`delta_partition', 2, 0) 

		noi di " "
		noi _dots 0, title(Loop through delta values) reps(`delta_partition')
		noi di " "
		
		local i = 1
		
		foreach delta of local delta_vals {
			preserve
			gen `var'_s = `var' + `delta' if `treat'==0
			
			*ECDF
			cumul `var' if `treat'==1, gen(`var'_1)
			cumul `var'_s if `treat'==0, gen(`var'_0_s)
			stack  `var'_1 `var'  `var'_0_s `var'_s, into(c `var'_) wide clear
			keep if !missing(`var'_1) | !missing(`var'_0_s)	
			sort `var'_
			
			* Interpolate
			ipolate `var'_1 `var'_, gen(F_1) epolate
			ipolate `var'_0_s `var'_, gen(F_0_s) epolate
			
			replace F_0_s = 0 if F_0_s<0
			replace F_1 = 0 if F_1<0
			replace F_0_s = 1 if F_0_s>1
			replace F_1 = 1 if F_1>1
			
			* F_1(y)-F_0(y-\delta)
			gen double dif = F_1-F_0_s
			* Y_\delta = [a,b] \cap [c+\delta, d+\delta]
			local mn = max(`a_', `c_'+`delta')
			local Mx = min(`b_', `d_'+ `delta')

			* sup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  (resp. inf)
			cap drop nobs
			gen nobs = _n
			su dif if inrange(`var'_,`mn',`Mx')
			
			if `r(N)'!=0 {
				gen double Mdelta = `r(max)'
				gen double mdelta = `r(min)'
				
				* M(delta) = sup_{Y_\delta} {F_1(y)-F_0(y-\delta)}
				matrix `M_delta'[`i',1] = Mdelta[1]
				* m(delta) = inf_{Y_\delta} {F_1(y)-F_0(y-\delta)}
				matrix `M_delta'[`i',2] = mdelta[1]
					
				* ysup_d = argsup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  
				su nobs if abs(dif-Mdelta)<1e-10
				local ysup_d = `r(min)'
				* sigma^L^2 = F_1(ysup_d)[1-F_1(ysup_d)]+(n1/n0)F_0(ysup_d-delta)[1-F_0(ysup_d-delta)]
				matrix `sigma_2'[`i',1] = F_1[`ysup_d']*(1-F_1[`ysup_d'])+(`n1_'/`n0_')*F_0_s[`ysup_d']*(1-F_0_s[`ysup_d'])
				
				* yinf_d = argsinf_{Y_\delta} {F_1(y)-F_0(y-\delta)}  
				su nobs if abs(dif-mdelta)<1e-10
				local yinf_d = `r(min)'
				* sigma^U^2 = F_1(yinf_d)[1-F_1(yinf_d)]+(n1/n0)F_0(yinf_d-delta)[1-F_0(yinf_d-delta)]
				matrix `sigma_2'[`i',2] = F_1[`yinf_d']*(1-F_1[`yinf_d'])+(`n1_'/`n0_')*F_0_s[`yinf_d']*(1-F_0_s[`yinf_d'])
				
				*F^L(\delta)
				cap matrix `bounds'[`i',1] = max(Mdelta[1],0)
				*F^U(\delta)
				cap matrix `bounds'[`i',2] = 1 + min(mdelta[1],0)
				}
			restore

			*___________________________________________________________________________
			*___________________________________________________________________________
			
			if "`indeps'"!="" {
					* conditional
				forvalues c = 1/`cov_partition' {
					preserve
					gen `var'_s = `var' + `delta' if `treat'==0
					
					*ECDF
					cumul `var' if `treat'==1 & `_clus_1'==`c', gen(`var'_1)
					cumul `var'_s if `treat'==0 & `_clus_1'==`c', gen(`var'_0_s)
					stack  `var'_1 `var'  `var'_0_s `var'_s, into(c `var'_) wide clear
					keep if !missing(`var'_1) | !missing(`var'_0_s)	
					sort `var'_
					
					* Interpolate
					ipolate `var'_1 `var'_, gen(F_1) epolate
					ipolate `var'_0_s `var'_, gen(F_0_s) epolate
					
					replace F_0_s = 0 if F_0_s<0
					replace F_1 = 0 if F_1<0
					replace F_0_s = 1 if F_0_s>1
					replace F_1 = 1 if F_1>1
					
					* Lambda calculation from Assumption 1
					count if _stack==1
					local n1_c = `r(N)'
					count if _stack==2
					local n0_c = `r(N)'
					
					* F_1(y)-F_0(y-\delta)
					gen double dif = F_1-F_0_s
					* Y_\delta = [a,b] \cap [c+\delta, d+\delta]
					local mn = max(`a_', `c_'+`delta')
					local Mx = min(`b_', `d_'+ `delta')

					* sup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  (resp. inf)
					cap drop nobs
					gen nobs = _n
					su dif if inrange(`var'_,`mn',`Mx')
					
					if `r(N)'!=0 {
						gen double Mdelta = `r(max)'
						gen double mdelta = `r(min)'
						
					* ysup_d = argsup_{Y_\delta} {F_1(y)-F_0(y-\delta)}  
					su nobs if abs(dif-Mdelta)<1e-10
					local ysup_d = `r(min)'
					* sigma^L^2 = F_1(ysup_d)[1-F_1(ysup_d)]+(n1/n0)F_0(ysup_d-delta)[1-F_0(ysup_d-delta)]
					matrix `sigma_2_cond'[`i',1] = `sigma_2_cond'[`i',1] + freq[`c',1]*(F_1[`ysup_d']*(1-F_1[`ysup_d'])+(`n1_c'/`n0_c')*F_0_s[`ysup_d']*(1-F_0_s[`ysup_d']))
					
					* yinf_d = argsinf_{Y_\delta} {F_1(y)-F_0(y-\delta)}  
					su nobs if abs(dif-mdelta)<1e-10
					local yinf_d = `r(min)'
					* sigma^U^2 = F_1(yinf_d)[1-F_1(yinf_d)]+(n1/n0)F_0(yinf_d-delta)[1-F_0(yinf_d-delta)]
					matrix `sigma_2_cond'[`i',2] = `sigma_2_cond'[`i',2] + freq[`c',1]*(F_1[`yinf_d']*(1-F_1[`yinf_d'])+(`n1_c'/`n0_c')*F_0_s[`yinf_d']*(1-F_0_s[`yinf_d']))
					
						*F^L(\delta)
						cap matrix `bounds_cond'[`i',1] = `bounds_cond'[`i',1] + freq[`c',1]*max(Mdelta[1],0)
						*F^U(\delta)
						cap matrix `bounds_cond'[`i',2] = `bounds_cond'[`i',2] + freq[`c',1]*(1 + min(mdelta[1],0))
					}
					restore
				}
			}
				
			noi _dots `i' 0	
			local i = `i' + 1
		}
		
		svmat `bounds'
		svmat `sigma_2'
		svmat `M_delta'
		svmat `bounds_cond'
		svmat `sigma_2_cond'
		svmat `delta_val'
			
		if "`indeps'"!="" {
			*Bounds
			gen `lb' = max(`bounds'1, `bounds_cond'1) if !missing(`bounds'1) & !missing(`bounds_cond'1)
			replace `lb' = 1 if `lb'[_n-1]==1 & !missing(`lb')
			gen `ub' = min(`bounds'2, `bounds_cond'2) if !missing(`bounds'2) & !missing(`bounds_cond'2)
			replace `ub' = 1 if `ub'[_n-1]==1 & !missing(`ub')

			gen `sigma_l_2' = min(`sigma_2'1,`sigma_2_cond'1) if !missing(`sigma_2'1) & !missing(`sigma_2_cond'1)
			gen `sigma_u_2' = min(`sigma_2'2,`sigma_2_cond'2) if !missing(`sigma_2'2) & !missing(`sigma_2_cond'2)

			mkmat `lb' `ub' if `delta_val'1!=., matrix(`bounds')
			mkmat `sigma_l_2' `sigma_u_2' if `delta_val'1!=., matrix(`sigma_2')
		}
		else {
			gen `lb' = `bounds'1
			replace `lb' = 1 if `lb'[_n-1]==1 & !missing(`lb')
			gen `ub' = `bounds'2
			replace `ub' = 1 if `ub'[_n-1]==1 & !missing(`ub')
			gen `sigma_l_2' = `sigma_2'1
			gen `sigma_u_2' = `sigma_2'2
		}

		if "`nograph'"=="" {
			preserve
			count if `treat'==1
			local n1 = `r(N)'

			foreach signif in `level' `=2*`level'' {
				*Lower CI
				gen lb_l`signif' = `lb'
				replace lb_l`signif' = lb_l`signif' - invnormal(1-`signif'/100)*sqrt(`sigma_l_2')/sqrt(`n1') if `M_delta'1<=0
				replace lb_l`signif' = lb_l`signif' - invnormal(1-`signif'/200)*sqrt(`sigma_l_2')/sqrt(`n1') if `M_delta'1>0
				replace lb_l`signif' = 0 if lb_l`signif'<0
				replace lb_l`signif' = 1 if lb_l`signif'>1

				gen ub_l`signif' = `ub'
				replace ub_l`signif' = ub_l`signif' - invnormal(1-`signif'/100)*sqrt(`sigma_u_2')/sqrt(`n1') if `M_delta'2>=0
				replace ub_l`signif' = ub_l`signif' - invnormal(1-`signif'/200)*sqrt(`sigma_u_2')/sqrt(`n1') if `M_delta'2<0
				replace ub_l`signif' = 0 if ub_l`signif'<0
				replace ub_l`signif' = 1 if ub_l`signif'>1

				*Higher CI
				gen lb_h`signif' = `lb'
				replace lb_h`signif' = lb_h`signif' + invnormal(1-`signif'/100)*sqrt(`sigma_l_2')/sqrt(`n1') if `M_delta'1<=0
				replace lb_h`signif' = lb_h`signif' + invnormal(1-`signif'/200)*sqrt(`sigma_l_2')/sqrt(`n1') if `M_delta'1>0
				replace lb_h`signif' = 0 if lb_h`signif'<0
				replace lb_h`signif' = 1 if lb_h`signif'>1

				gen ub_h`signif' = `ub'
				replace ub_h`signif' = ub_h`signif' + invnormal(1-`signif'/100)*sqrt(`sigma_u_2')/sqrt(`n1') if `M_delta'2>=0
				replace ub_h`signif' = ub_h`signif' + invnormal(1-`signif'/200)*sqrt(`sigma_u_2')/sqrt(`n1') if `M_delta'2<0
				replace ub_h`signif' = 0 if ub_h`signif'<0
				replace ub_h`signif' = 1 if ub_h`signif'>1
			}
			
			noi twoway (rarea lb_l5 lb_h5 `delta_val'1, color(navy%25)) ///
				(rarea ub_l5 ub_h5 `delta_val'1, color(maroon%25)) ///
				(rarea lb_l10 lb_h10 `delta_val'1, color(navy%35)) ///
				(rarea ub_l10 ub_h10 `delta_val'1, color(maroon%35)) ///
				(line `lb' `delta_val'1, xline(0, lpattern(dot) lcolor(gs5)) color(navy)) ///
				(line `ub' `delta_val'1, color(maroon)) ///
				, graphregion(color(white)) legend(order(5 "Lower bound" 6 "Upper bound")) ///
				xtitle("{&Delta} : Treatment effect")
			
			restore
		}
		
		*Return
		return matrix bounds = `bounds'
		return matrix sigma_2 = `sigma_2'
		return matrix M_delta = `M_delta'
		return matrix delta_val = `delta_val'
	}
	
	else {
		
		* F^L^{-1}(q) = inf_{u\in [q,1]} {F_1^{-1}(u)-F_0^{-1}(u-q)}
		* F^U^{-1}(q) = sup_{u\in [0,q]} {F_1^{-1}(u)-F_0^{-1}(1+u-q)}

		tempfile temp_fan_park
		save `temp_fan_park'

		*Quantile function
		count if `treat'==1
		if `r(N)'<100 {
			xtile quant_1 = `var' if `treat'==1, nq(`r(N)')
			replace quant_1 = round(quant_1*(100/`r(N)'))
		}
		else {
			xtile quant_1 = `var' if `treat'==1, nq(`num_quantiles')
		}
		count if `treat'==0
		if `r(N)'<100 {
			xtile quant_0 = `var' if `treat'==0, nq(`r(N)')
			replace quant_0 = round(quant_0*(100/`r(N)'))
		}
		else {
			xtile quant_0 = `var' if `treat'==0, nq(`num_quantiles')
		}
		
		*Properly define quantile function
		sort quant_1 apr
		by quant_1 : replace quant_1 = . if _n!=_N
		sort quant_0 apr
		by quant_0 : replace quant_0 = . if _n!=_N
		
		gen quant_0_ls = .
		gen quant_0_us = .
		
		if "`indeps'"!="" {
			forvalues c = 1/`cov_partition' {
				count if `treat'==1 & `_clus_1'==`c'
				if `r(N)'<100 {
					xtile quant_1_`c' = `var' if `treat'==1 & `_clus_1'==`c', nq(`r(N)')
					replace quant_1_`c' = round(quant_1_`c'*(100/`r(N)'))
				}
				else {
					xtile quant_1_`c' = `var' if `treat'==1 & `_clus_1'==`c', nq(`num_quantiles')
				}
				count if `treat'==0 & `_clus_1'==`c'
				if `r(N)'<100 {
					xtile quant_0_`c' = `var' if `treat'==0 & `_clus_1'==`c', nq(`r(N)')
					replace quant_0_`c' = round(quant_0_`c'*(100/`r(N)'))
				}
				else {
					xtile quant_0_`c' = `var' if `treat'==0 & `_clus_1'==`c', nq(`num_quantiles')
				}

				*Properly define quantile function
				sort quant_1_`c' `var'
				by quant_1_`c' : replace quant_1_`c' = . if _n!=_N
				sort quant_0_`c' `var'
				by quant_0_`c' : replace quant_0_`c' = . if _n!=_N
				
				gen quant_0_ls_`c' = .
				gen quant_0_us_`c' = .
			}
		}

		matrix `bounds_q' = J(`num_quantiles', 2, .) 
		matrix `bounds_q_cond' = J(`num_quantiles', 2, 0) 
		matrix `q_val' = J(`num_quantiles', 1, .) 
			
		noi di " "
		noi _dots 0, title(Loop through quantiles) reps(`num_quantiles')
		noi di " "
		
		local i = 1
		forvalues q = 1/`num_quantiles' {
			preserve
			
			keep if quant_1!=. | quant_0!=.
			*Quantile function
			replace quant_0_ls = quant_0 + `q'
			replace quant_0_us = quant_0_ls - `num_quantiles'

			stack quant_1 `var' quant_0_ls `var' quant_0_us `var', into(q_ `var'_) wide clear
			keep if !missing(q_)	
			keep `var'_ _stack q_
			reshape wide `var'_ , i(q_) j(_stack)
			
			* Interpolate
			ipolate `var'_1 q_ , gen(F_1) epolate
			ipolate `var'_2 q_ , gen(F_0_ls) epolate
			ipolate `var'_3 q_ , gen(F_0_us) epolate
			
			* F_1^{-1}(u)-F_0^{-1}(u-q)
			gen dif1 = F_1-F_0_ls
			* F_1^{-1}(u)-F_0^{-1}(1+u-q)
			gen dif2 = F_1-F_0_us	
			
			* inf_{u\in [q,1]} {F_1^{-1}(u)-F_0^{-1}(u-q)}
			su dif1 if inrange(q_,`q',`num_quantiles')
			*F^L^{-1}(q)
			cap matrix `bounds_q'[`i',1] = `r(min)'
			
			* sup_{u\in [0,q]} {F_1^{-1}(u)-F_0^{-1}(1+u-q)}
			su dif2 if inrange(q_,0,`q')
			*F^U^{-1}(q)
			cap matrix `bounds_q'[`i',2] = `r(max)'
			
			matrix `q_val'[`i',1] = `q'/`num_quantiles'
			restore
			
			
			*___________________________________________________________________________
			*___________________________________________________________________________
			
			if "`indeps'"!="" {
					* conditional
				forvalues c = 1/`cov_partition' {
					preserve
				
					keep if quant_1_`c'!=. | quant_0_`c'!=.
					*Quantile function
					replace quant_0_ls_`c' = quant_0_`c' + `q'
					replace quant_0_us_`c' = quant_0_ls_`c' - `num_quantiles'

					stack quant_1_`c' `var' quant_0_ls_`c' `var' quant_0_us_`c' `var', into(q_ `var'_) wide clear
					keep if !missing(q_)	
					keep `var'_ _stack q_
					reshape wide `var'_ , i(q_) j(_stack)
					
					* Interpolate
					ipolate `var'_1 q_ , gen(F_1) epolate
					ipolate `var'_2 q_ , gen(F_0_ls) epolate
					ipolate `var'_3 q_ , gen(F_0_us) epolate
					
					* F_1^{-1}(u)-F_0^{-1}(u-q)
					gen dif1 = F_1-F_0_ls
					* F_1^{-1}(u)-F_0^{-1}(1+u-q)
					gen dif2 = F_1-F_0_us	
					
					* inf_{u\in [q,1]} {F_1^{-1}(u)-F_0^{-1}(u-q)}
					su dif1 if inrange(q_,`q',`num_quantiles')
					*F^L^{-1}(q)
					cap matrix `bounds_q_cond'[`i',1] = `bounds_q_cond'[`i',1] + freq[`c',1]*(`r(min)')
					
					* sup_{u\in [0,q]} {F_1^{-1}(u)-F_0^{-1}(1+u-q)}
					su dif2 if inrange(q_,0,`q')
					*F^U^{-1}(q)
					cap matrix `bounds_q_cond'[`i',2] = `bounds_q_cond'[`i',2] + freq[`c',1]*(`r(max)')
					
					restore	
				}	
			}		
					
			noi _dots `i' 0	
			local i = `i' + 1
			}
		
		svmat `bounds_q'
		svmat `bounds_q_cond'
		svmat `q_val'
			
		if "`indeps'"!="" {
			*Bounds
			gen `lb' = max(`bounds_q'2, `bounds_q_cond'2) if !missing(`bounds_q'2) & !missing(`bounds_q_cond'2)
			gen `ub' = min(`bounds_q'1, `bounds_q_cond'1) if !missing(`bounds_q'1) & !missing(`bounds_q_cond'1)

			mkmat `lb' `ub' if `q_val'1!=., matrix(`bounds_q')
		}
		else {
			gen `lb' = `bounds_q'2
			gen `ub' = `bounds_q'1
		}
		
		
		if "`nograph'"=="" {	

			noi twoway (line `ub' `q_val'1, color(navy) lwidth(medthick) yline(0, lpattern(dot) lcolor(gs5))) (line `lb' `q_val'1, color(maroon) lwidth(medthick)) ///
				, graphregion(color(white)) legend(order(1 "Upper bound" 2 "Lower bound")) ///
				ytitle("{&Delta} : Treatment effect") xtitle("Quantiles")
		}	
		
		*Return
		return matrix bounds = `bounds_q'
		return matrix q_val = `q_val'	
		
		use `temp_fan_park', clear	
	}
	
	}

end	