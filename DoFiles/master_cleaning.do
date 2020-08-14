/*

**  Isaac Meza, isaac.meza@berkeley.edu


Master do file for cleaning and processing of data 
	- Admin
	- Survey
	- Expansion
	
*/		


********************************* Admin Data ***********************************
do "$directorio\DoFiles\cleaning\cleaning_prod.do"
do "$directorio\DoFiles\cleaning\cleaning_admin.do"
*Computation of APR
do "$directorio\DoFiles\cleaning\apr_computation.do"


***************************** Survey Data & Merge ******************************
do "$directorio\DoFiles\cleaning\cleaning_master.do"


***************************** Survey Data & Merge ******************************
do "$directorio\DoFiles\cleaning\cleaning_expansion.do"

