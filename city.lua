-- corn by yarlesp
-- pl development 2013

city = { 	name = " ",
			parts = {},
			size = 0
}

city.__index = city

-- a city grows from a single town
function city.new(t)
	local o
	setmetatable(o, town)
	o = {	name = t.name, 
			owner = t.owner,
			o.parts = {},
			o.size = 1
		}
	table.insert(o.parts, t)
	return o
end

-- handles growth in a city
-- fills up all the constituent parts but if all the parts are already filled, plops down a new part in a non-water tile closest to the "city center"
-- the "city center" is the loc field of parts[1], as in, the very first 'part' added to the city
function city:update()
	if game.season == 1 then
		for i = 1, #self.parts do 
			if #self.parts[i].population >= game.options.max_pop and self.parts[i].available then

			end
		end
	end
end