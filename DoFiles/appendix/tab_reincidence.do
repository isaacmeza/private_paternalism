*Reincidence SS

use "$directorio/DB/Master.dta", clear

replace choose_same=. if choose_same==2

* (copy & paste in tab_reincidence.xlsx)
su visit_number more_one_arm num_arms ///
 reincidence same_prod_reincidence visit_number_75  more_one_arm_75 ///
 num_arms_75 choose_same

