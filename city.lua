-- corn by yarlesp
-- pl development 2013

city = { 	name = " ",
			parts = {},
			size = 0
}

city.__index = city

-- a city grows from a single town
function city.new(t)
	local o = {}
	setmetatable(o, city)
	o.name = t.name
	o.owner = t.owner
	o.parts = {}
	o.size = 1
	table.insert(o.parts, t)
	return o
end

-- handles growth in a city
-- fills up all the constituent parts but if all the parts are already filled, plops down a new part in a non-water tile closest to the "city center"
-- the "city center" is the loc field of parts[1], as in, the very first 'part' added to the city
function city:update()
	local must_populate = false
	local must_expand = false
	if game.season == 1 then
		for i = 1, #self.parts do 
			if #self.parts[i].population >= game.options.max_pop and self.parts[i].available then
				must_populate = true
				local j = 1
				while must_populate and self.parts[j] do
					if #self.parts[j].population < game.options.max_pop then
						self.parts[j].populate()
						print("added pop")
						must_populate = false
					end
					j = j + 1
				end
				if must_populate then
					self:expand()
					print("expanding... "..self.parts[1].loc[1].." "..self.parts[1].loc[2])
				end
			end
		end
	end
end

-- actually plants a physical new part of a given city on the map
-- takes a city
-- adds a new city part to the map somewhere. wicked TODO
function city:expand()
	
end