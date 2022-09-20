
********************
version 17.0
********************
/* 
/*******************************************************************************
* Name of file:	
* Author:	Isaac M 
* Machine:	Isaac M 											
* Date of creation:	
* Last date of modification: 
* Modifications: 	
* Files used:     
		- 
* Files created:  

* Purpose : Defines the path of the project folder & some global variables

*******************************************************************************/
*/

*Directory
set more off
global directorio "C:\Users\isaac\Dropbox\Apps\Overleaf\Donde2020"

*Set covariates
global C0 = "dummy_* num_arms_d* visit_number_d*" /*Controls*/

*Set significance
global star "star(* 0.1 ** 0.05 *** 0.01)"
*global star "nostar"

*Set scheme
set scheme white_tableau, perm