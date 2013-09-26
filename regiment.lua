-- corn by yarlesp
-- pl development 2013

regiment = 	{ 	name = "",			-- name
				loc = {},			-- precise location
				dest = nil,			-- precise destination
				last_move = 0,		-- time at which movement was last updated. 
				discipline = 1,		-- ability to withstand damage, attack
				speed = 25,			-- pixels per second
				attack = 1,			-- damage inflicted per successful attack
				defense = 1,		-- ability to resist damage
				in_supply = true
			}

regiment.__index = regiment

function regiment.new( loc )
	o = {}
	nameSuffix = ""
	nameSuffix = nameSuffix..(#game.regiments + 1)
	nameSuffix = nameSuffix:sub(-1)
	if	nameSuffix == "1" then nameSuffix = "st" elseif
		nameSuffix == "2" then nameSuffix = "nd" elseif
		nameSuffix == "3" then nameSuffix = "rd" else nameSuffix = "th"
	end
	o.name = (#game.regiments + 1)..nameSuffix.." Regiment of Foot"
	o.in_supply = true
	o.discipline = 1
	o.selected = false
	o.loc = {loc[1] * tile_width - 30, loc[2] * tile_height + 10}
	o.dest = nil
	setmetatable(o, regiment)
	table.insert(game.regiments, o)
	return o
end

-- update function, right now it only changes discipline and position
-- this function is supposed to be called every second
function regiment:update( dt )
	if not game.paused then
		if not self.in_supply then self.discipline = self.discipline * .999 end
		if self.dest and ( not (math.abs(self.dest[1] - self.loc[1]) < 2) or not (math.abs(self.dest[2] - self.loc[2]) < 2) ) then
			local length = math.sqrt( (self.dest[1] - self.loc[1])^2 + (self.dest[2] - self.loc[2])^2 )
			local unit_vector = { (self.dest[1] - self.loc[1]) / length, (self.dest[2] - self.loc[2]) / length }
			self.loc = { self.loc[1] + (unit_vector[1] * dt * self.speed), self.loc[2] + (unit_vector[2] * dt * self.speed) }
		elseif self.dest and math.abs(self.dest[1] - self.loc[1]) < 10 and math.abs(self.dest[2] - self.loc[2]) < 10 then
			self.dest = nil
		end
	end
end

-- takes a regiment
-- finds out where its nearest garrison is, as in, where it's supposed to be based
function regiment:nearest_garrison()

end

function regiment:is_in_supply()
	if self.in_supply then return "In supply" 
	else return "Not in supply" end
end
