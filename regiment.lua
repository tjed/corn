-- corn by yarlesp
-- pl development 2013

regiment = 	{ 	name = "",			-- name
				loc = {},			-- precise location
				discipline = 0,		-- amount of actions a unit can execute per season? 
				speed = 1,			-- tiles per season
				attack = 1,			-- damage inflicted per successful attack
				defense = 1			-- ability to resist damage
			}

regiment.__index = regiment

function regiment.new( loc )
	o = {}
	setmetatable(o, regiment)
	return o
end