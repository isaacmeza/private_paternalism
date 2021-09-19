insheet using C:\Users\isaac\Dropbox\Apps\ShareLaTeX\Donde2020\_aux\binscatter_effect_pr.csv

twoway (scatter tau_hat_oobpredictions rf_pred, mcolor(navy) lcolor(maroon)) (function 0*x^2+-.158225933273875*x+-.1182072808294028, range(.0369642072997097 .3157266904016456) lcolor(maroon)), graphregion(fcolor(white))  xtitle(rf_pred) ytitle(tau_hat_oobpredictions) legend(off order())
