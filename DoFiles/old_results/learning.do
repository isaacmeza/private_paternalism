		
*Learning 				
use "$directorio/DB/Master.dta", clear

reg prestamo def_c
reg prestamo def_c $C0, r

su *ciclo if pro_2==0
su *ciclo if pro_2==1
*los incrementos son mayores

gen learn = (pago_primer_ciclo & pago_seg_ciclo & pago_ter_ciclo) | ///
	(pago_primer_ciclo==0 & pago_seg_ciclo & pago_ter_ciclo) | ///
	(pago_primer_ciclo==0 & pago_seg_ciclo==0 & pago_ter_ciclo)
		
reg learn pro_2 $C0, r cluster(suc_x_dia)		



/* Schilbach hypothesis: "To test it we would ideally need to give choice to a 
group of people that randomly experienced the fee-commitment vs those that did not,
and test if the former demand it more"*/
use "$directorio/DB/Master.dta", clear

sort NombrePignorante visit_number
duplicates drop NombrePignorante visit_number, force


gen learn_ctrl_0 = .
gen learn_ctrl_1 = .
gen learn_arm_0 = .
gen learn_arm_1 = .

*Control and Fee-forcing observations that fall in choice arm in next visit
forvalues i = 1/6 { 
	bysort NombrePignorante : replace learn_ctrl_0 = 1 if (visit_number==`i' & producto==1 & visit_number[_n+1]==`i'+1 & producto[_n+1]==4)
	bysort NombrePignorante : replace learn_ctrl_1 = 1 if (visit_number==`i' & producto==1 & visit_number[_n+1]==`i'+1 & producto[_n+1]==5)
	bysort NombrePignorante : replace learn_arm_0 = 1 if (visit_number==`i' & producto==2 & visit_number[_n+1]==`i'+1 & producto[_n+1]==4)
	bysort NombrePignorante : replace learn_arm_1 =1 if (visit_number==`i' & producto==2 & visit_number[_n+1]==`i'+1 & producto[_n+1]==5)
	}

*Manual verification
keep if learn_ctrl_0==1 | learn_ctrl_0[_n-1]==1 ///
		| learn_ctrl_1==1 | learn_ctrl_1[_n-1]==1 ///
		| learn_arm_0==1 | learn_arm_0[_n-1]==1 ///
		| learn_arm_1==1 | learn_arm_1[_n-1]==1 

*Relevant observations
drop if learn_ctrl_0==. & ///
	learn_ctrl_1==. & ///
	learn_arm_0==. & ///
	learn_arm_1==. 
 
*Test
gen learn_tr = (learn_arm_0==1 | learn_arm_1==1)
gen choice_fee = (learn_ctrl_1==1 | learn_arm_1==1)

orth_out choice_fee, by(learn_tr) pcompare se vce(cluster suc_x_dia) stars count overall
