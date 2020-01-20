use "$directorio/DB/Base_Boleta_230dias_Seguimiento_Ago2013_ByPrenda_2", clear

bysort suc: gen contador = _N

*Multinomial
local obs = 1
forvalues i = 2/`=_N'{
	local obs = `i'*(`i'-1)
}

local aux1 = 2
local aux2 = 2
local aux3 = 2
local aux4 = 2
local aux5 = 2
local aux6 = 2

local p1 = .9
local p2 = .02
local p3 = .02
local p4 = .02
local p5 = .02
local p6 = .02

local j = 1
foreach x in 3 5 42 78 80 104 {
	sum contador if suc == `x'
		forvalues i = 2/`r(N)'{
			local aux`j' = `i'*(`i'-1)
		}
	local p`j' = ln(`p`j'')*(`r(N)')-ln(`aux`j'')
	disp `p`j''
	local j = `j'+1
	
}

disp in red "Probability:"

local probability = `p1'+`p2'+`p3'+`p4'+`p5'+`p6'+ln(`obs')
disp `probability'


local resultado = exp(`probability')

disp in red "`resultado'"
