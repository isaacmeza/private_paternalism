use "$directorio/DB/Master.dta", clear

reg prestamo def_c
reg prestamo def_c ${C0}, r 

su *_ciclo if pro_2==0
su *_ciclo if pro_2==1
*los incrementos son mayores

*Cambiar la definición con - Pagar al menos un tercio


*
gen learn = (pago_primer_ciclo & pago_seg_ciclo & pago_ter_ciclo) | ///
	(pago_primer_ciclo==0 & pago_seg_ciclo & pago_ter_ciclo) | ///
	(pago_primer_ciclo==0 & pago_seg_ciclo==0 & pago_ter_ciclo)
	
	
reg learn pro_2 ${C0}, r cluster(suc_x_dia) 	


*
reg pago_periodo l.pago_periodo##i.pro_2, r
