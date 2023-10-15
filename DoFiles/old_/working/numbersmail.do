
********************
version 17.0
********************
/*
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	February. 16, 2021
* Last date of modification:   
* Modifications:		
* Files used:     
		- 
* Files created:  

* Purpose: numbers

*******************************************************************************/
*/


use "$directorio/DB/Master.dta", clear

*1)
tab pr_recup

su val_pren, d
replace val_pren = . if val_pren<250
gen dif = val_pren-prestamo

 hist dif if dif>-10000, scheme(s2mono) graphregion(color(white)) percent xtitle("Subjective-Loan")
 
 
 use "$directorio/DB/Master.dta", clear

 sort NombreP prenda t_prod fc_admin
 
 br NombreP prenda t_prod fc_admin visit_number num_arms
 
 drop if missing(t_prod)
 duplicates tag NombrePig, gen(tg)
 replace tg = tg+1
 duplicates drop NombreP, force
 tab tg
 rename tg number_of_loans
 tab number_of_loans
 
 
  use "$directorio/DB/Master.dta", clear
  eststo clear
  *0 - I think a more standard thing to do here would be to estimate a regression that always given clients the FIRST treatment status they were assigned. 
  preserve

  sort NombreP fecha_inicial
  by NombreP  : gen first_tr = t_prod[1] if !missing(t_prod)
  eststo: reg fc_admin i.first_tr $C0 if inlist(first_tr,1,2,4), vce(cluster suc_x_dia)
	su fc_admin if e(sample) & first_tr==1
	estadd scalar ContrMean = `r(mean)'
eststo: reg apr i.first_tr $C0 if inlist(first_tr,1,2,4), vce(cluster suc_x_dia)
	su apr if e(sample) & first_tr==1
	estadd scalar ContrMean = `r(mean)'
  restore
  
  *1-Put dummies for these cases as we are currently doing (to allow for flexibility in the regression and let them have less influence on the estimation of TE --ie the slope)
eststo: reg fc_admin i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su fc_admin if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
eststo: reg apr i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su apr if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
	
*2) Drop them, but I think there were many, can you tell us how many ISAAC?
preserve
keep if num_arms==1
eststo: reg fc_admin i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su fc_admin if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
eststo: reg apr i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su apr if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
restore

*3) Use a kind of ITT method where we use THE FIRST treatment
preserve
keep if visit_number==1
eststo: reg fc_admin i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su fc_admin if e(sample) &t_prod==1
	estadd scalar ContrMean = `r(mean)'
eststo: reg apr i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
	su apr if e(sample) & t_prod==1
	estadd scalar ContrMean = `r(mean)'
restore

*4) Have different combinations of treatment dummies if they got different arms, but this may become a mess.

esttab using "$directorio/Tables/reg_results/multiple_pawns.csv", se r2 ${star} b(a2) ///
		scalars("ContrMean Control Mean") keep(1.t_producto 2.t_producto 4.t_producto 2.first_tr 4.first_tr) replace 


	reg dias_ultimo_mov i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
		reg dias_al_desempenyo i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)
		
reg sum_inc_int_c i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	




 
 
  use "$directorio/DB/Master.dta", clear
  
  
 gen eff_cost = fc_admin/prestamo
 
 reg apr i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
 reg eff_cost i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
  reg fc_admin i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
   reg prestamo i.t_prod $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
   
   
    reg eff_cost i.t_prod  if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
  reg fc_admin i.t_prod  if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
   reg prestamo i.t_prod  if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
   
   
   
    
  use "$directorio/DB/Master.dta", clear

   gen eff_cost_s = fc_survey/prestamo
  gen eff_cost_a = fc_admin/prestamo
  
      reg eff_cost_s i.t_prod  if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
	        reg eff_cost_a i.t_prod  if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	

			
foreach var of varlist  apr apr_survey {
	* Z-score
	su `var' if inlist(t_prod,1,2,4)
	gen std_`var' = (`var'-`r(mean)')/`r(sd)'
}
	
      reg apr_survey i.t_prod  $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
      reg apr i.t_prod $C0  if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
	  
	  
	  reg std_apr_survey i.t_prod  $C0 if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
      reg std_apr i.t_prod $C0  if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	

  reg fc_survey i.t_prod  if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
   reg prestamo i.t_prod  if inlist(t_prod,1,2,4), vce(cluster suc_x_dia)	
  

   