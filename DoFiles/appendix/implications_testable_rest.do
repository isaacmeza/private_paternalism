/*
********************
version 17.0
********************
 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	Nov. 18, 2023
* Last date of modification: 
* Modifications: 
* Files used:     
		- Master.dta
* Files created:  

* Purpose: Testable implications of Exclusion restriction 

\begin{equation}
\mathbb{E}\left(Y|Z=0, Y\leq y^0_{1-p}\right)\leq \mathbb{E}(Y|D=0,Z=2) \leq \mathbb{E}\left(Y|Z=0, Y \geq y^0_p\right).
\label{eq:testable0}
\end{equation}

\begin{equation}
\mathbbm{E}\left(Y|Z=1,Y\leq y^1_{p}\right) \leq \mathbbm{E}(Y|D=1,Z=2) \leq \mathbbm{E}\left(Y|Z=1,Y \geq y^1_{1-p}\right).
\label{eq:testable1}
\end{equation}
*******************************************************************************/
*/

clear all
set maxvar 100000
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2,4)

local var fc_admin

*-------------------------------------------------------------------------------
cumul `var' if t_prod==1, gen(perc_1)
cumul `var' if t_prod==2, gen(perc_2)
su choose_
local p = `r(mean)'
gen perc_1_p = abs(`p'-perc_1)
gen perc_1_1p = abs(1-`p'-perc_1)
gen perc_2_p = abs(`p'-perc_2)
gen perc_2_1p = abs(1-`p'-perc_2)


foreach percentile in 1_p 1_1p 2_p 2_1p {
	sort perc_`percentile'
	local y_`percentile' = `var'[1]
}


*\mathbb{E}\left(Y|Z=0, Y\leq y^0_{1-p}\right)\leq \mathbb{E}(Y|D=0,Z=2) \leq \mathbb{E}\left(Y|Z=0, Y \geq y^0_p\right)
su `var' if t_prod==1 & `var'<= `y_1_1p'
su `var' if choose_==0 & t_prod==4
su `var' if t_prod==1 & `var'>= `y_1_p'


*\mathbbm{E}\left(Y|Z=1,Y\leq y^1_{p}\right) \leq \mathbbm{E}(Y|D=1,Z=2) \leq \mathbbm{E}\left(Y|Z=1,Y \geq y^1_{1-p}\right).
su `var' if t_prod==2 & `var'<= `y_2_p'
su `var' if choose_==1 & t_prod==4
su `var' if t_prod==2 & `var'>= `y_2_1p'



