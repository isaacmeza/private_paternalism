* Present-bias characteristics

use "$directorio/DB/Master.dta", clear


*****************************
*        Regressions 		*
*****************************

eststo clear

eststo : reg pb genero edad ///
		faltas fam_pide ///
		tentado rec_cel pr_recup hace_presupuesto ///
		pres_antes cta_tanda  ///
		, r
		
eststo : reg pb  edad ///
		faltas fam_pide ///
		tentado rec_cel pr_recup hace_presupuesto ///
		pres_antes cta_tanda  ///
		if genero == 1, r

eststo : reg pb  edad ///
		faltas fam_pide ///
		tentado rec_cel pr_recup hace_presupuesto ///
		pres_antes cta_tanda  ///
		if genero == 0, r
	
******************************************************

eststo : reg fb genero edad ///
		faltas fam_pide ///
		tentado rec_cel pr_recup hace_presupuesto ///
		pres_antes cta_tanda  ///
		, r
	
eststo : reg fb  edad ///
		faltas fam_pide ///
		tentado rec_cel pr_recup hace_presupuesto ///
		pres_antes cta_tanda  ///
		if genero == 1, r

eststo : reg fb  edad ///
		faltas fam_pide ///
		tentado rec_cel pr_recup hace_presupuesto ///
		pres_antes cta_tanda  ///
		if genero == 0, r	

	
*************************
	esttab using "$directorio/Tables/reg_results/pb_chars.csv", se r2 star(* 0.1 ** 0.05 *** 0.01) b(a2) ///
	 replace 

		
