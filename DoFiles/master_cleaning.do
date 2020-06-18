/*

**  Isaac Meza, isaac.meza@berkeley.edu


Master do file for cleaning and processing of data 
	- Admin
	- Survey
	
*/		


********************************* Admin Data ***********************************
do "$directorio\DoFiles\cleaning\cleaning_prod.do"
do "$directorio\DoFiles\cleaning\cleaning_admin.do"


***************************** Survey Data & Merge ******************************
do "$directorio\DoFiles\cleaning\cleaning_master.do"


