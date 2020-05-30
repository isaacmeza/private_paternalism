insheet using C:\Users\xps-seira\Dropbox\Apps\ShareLaTeX\Donde2019\_aux\binscatter_effect_pr.csv

twoway (scatter tau_hat_oobpredictions rf_pred, mcolor(navy) lcolor(maroon)) (function 0*x^2+-.1405818067065735*x+-.1146115962981827, range(.0375432719748199 .316765436280919) lcolor(maroon)), graphregion(fcolor(white))  xtitle(rf_pred) ytitle(tau_hat_oobpredictions) legend(off order())
