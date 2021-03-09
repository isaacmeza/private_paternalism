insheet using C:\Users\isaac\Dropbox\Apps\ShareLaTeX\Donde2020\_aux\binscatter_effect_pr.csv

twoway (scatter tau_hat_oobpredictions rf_pred, mcolor(navy) lcolor(maroon)) (function 0*x^2+-.1289939512030187*x+-.1161707997195615, range(.0361700403060585 .3126737895084962) lcolor(maroon)), graphregion(fcolor(white))  xtitle(rf_pred) ytitle(tau_hat_oobpredictions) legend(off order())
