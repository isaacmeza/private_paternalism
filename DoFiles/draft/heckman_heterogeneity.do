
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M
* Machine:	Isaac M 											
* Date of creation:	April. 22, 2022
* Last date of modification: 
* Modifications: 		
* Files used:     
		- Master.dta
* Files created:  
* Purpose: Heckman, Smith & Clements (1997) heterogeneity analysis

*******************************************************************************/
*/
	
use "$directorio/DB/Master.dta", clear
keep if inlist(t_prod,1,2)
keep apr fc_admin t_prod 

su apr if t_prod==1
su apr if t_prod==2

