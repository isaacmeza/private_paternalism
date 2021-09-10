
import excel "$directorio/Raw/BASEMAESTRA-19-06-2013.xlsx", sheet("Base") firstrow clear
	
rename NúmPrenda prenda
keep ProductoLetra Producto prenda

*TIPO DE PRODUCTO

gen producto = ProductoLetra
replace producto = 6 if producto==5
replace producto = 5 if producto==4 & Producto=="B"
replace producto = 7 if producto==6 & Producto=="B"




label define lab_prod ///
	1 "Control"            		///"Status quo"
	2 "No Choice/Fee"           ///"Pago frecuente con pena"
	3 "No Choice/Promise"        ///"Pago frecuente sin pena"
	4 "Choice/Fee - SQ"         ///"Escoge entre status quo y mensualidades con pena: elegio status quo"
	5 "Choice/Fee - NSQ"        ///"Escoge entre status quo y mensualidades con pena: eligio mensualidades con pena"
	6 "Choice/Promise - SQ"      ///"Escoge entre pago unico y mensualidades con promesa: elige status quo"
	7 "Choice/Promise - NSQ"     ///"Escoge entre pago unico y mensualidades con promesa: no elige status quo"

	
label var producto "Product"

label values producto lab_prod


gen t_producto = producto if producto<=3
replace t_producto =4 if producto>3 & producto<=5
replace t_producto =5 if producto>5 & producto<=7

label define lab_t_prod ///
	1 "Control"           		 ///"Status quo"
	2 "No Choice/Fee"      	     ///"Pago frecuente con pena"
	3 "No Choice/Promise"         ///"Pago frecuente sin pena"
	4 "Choice/Fee"               ///"Escoge entre status quo y mensualidades con pena"
	5 "Choice/Promise"            ///"Escoge entre pago unico y mensualidades con promesa"
	

label var t_producto "Product type without choice"
label values t_producto lab_t_prod	

keep prenda producto t_producto

duplicates drop prenda, force

save "$directorio/Raw/db_product.dta", replace

