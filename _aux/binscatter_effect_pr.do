insheet using C:\Users\isaac\Dropbox\Apps\ShareLaTeX\Donde2020\_aux\binscatter_effect_pr.csv

twoway (scatter tau_hat_oobpredictions rf_pred, mcolor(navy) lcolor(maroon)) (function 0*x^2+-.1414404520082493*x+-.1176046566311165, range(.0381627367212132 .3138120153601692) lcolor(maroon)), graphregion(fcolor(white))  xtitle(rf_pred) ytitle(tau_hat_oobpredictions) legend(off order())
