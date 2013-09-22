-- corn by yarlesp
-- pl development 2013

regiment = 	{ 	name = "",			-- name
				loc = {},			-- precise location
				discipline = 1,		-- ability to withstand damage, attack
				speed = 1,			-- tiles per season
				attack = 1,			-- damage inflicted per successful attack
				defense = 1,		-- ability to resist damage
				in_supply = true
			}

regiment.__index = regiment

function regiment.new( loc )
	o = {}
	setmetatable(o, regiment)
	return o
end

function regiment:update()
	if not self.in_supply then self.discipline = self.discipline / 2 end
end