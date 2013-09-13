-- corn by yarlesp
-- pl development 2013

-- all of this stuff should be overwritten by either the constructor function or somewhere in the land file (where the towns are created)
-- but i keep this here to make it clearer for me whats goin on
town = { 	population = {},		-- pops, mix of workers and peasants
			parts = {},
			owner = nil,			-- capitalist, or, nobody...
			name = "Town of ",		-- duh
			loc = {0, 0},			-- location of the center of the town on the map
			city = false,			-- whether or not the things a city
			radius = 5,				-- how far labor is allowed to travel from the town
			available = true,		-- if over 30% of the village is starving then they start to riot
			poor_house = false,		-- obvs
		}

town.__index = town

function town.new(location)
	local o = {loc = location}
	setmetatable(o, town)
	local named = false
	while not named do -- not that effecient but it works
		o.name = place_names[math.random(#place_names)]
		named = true
		for i = 1, #game.towns do
			if o.name == game.towns[i].name then named = false end
		end
	end
	o.population = {}
	o.available = true
	o.poor_house = false
	o.parts = {}
	table.insert(o.parts, location)
	table.insert(game.towns, o)
	return o
end

-- takes a town (implicitly) and an amount to add to the population of the town (defaults to 1 if called without arguments), as long as the population is below max
-- side fx: modifies the town, and by extension game.population and a whole bunch of other stuff. dangerous!
function town:populate( with , t )
	for i = 1, with or 1 do
		if t == nil or t == "farmer" then
			table.insert(self.population, farmer:new(self.loc) )
		elseif t == "worker" then
			table.insert(self.population, worker:new(self.loc) )
		end
	end
end

-- called once at the end of the season
-- if people are starving the town will enter riot mode!
-- if people are happy another family will form. 
-- if the town has reached its maximum population it will form a city
-- unless it's already part of a city in which case the city handles the expansion
function town:update()
	-- da na, da na, town looks like a ci-tay
	-- I guess this means towns can become cities and vice versa
	if #self.parts > 2 then 
		self.city = true
	else
		self.city = false
	end

	-- determine riot/growth eilgibility status
	local angry = 0
	for i = 1, #self.population do
		if self.population[i].starving then
			angry = angry + 1
		end
	end
	self.available = (angry / #self.population) < .3

	-- if the population is growing, but there's enough room in the city, then just add pop
	-- if the population has grown beyond the ability of the city to contain it, spawn a new city tile adjacent
	if game.season == 3 then 
		if self.available then
			self:populate()
			if (#self.parts * game.options.max_pop) < #self.population then
				self:grow()
			end
		end
	end
end

-- takes a town implicitly
-- returns what the employment percentage is, from 0 to 1
-- side fx: none
function town:get_employment()
	local working = 0
	for i = 1, #self.population do 
		working = working + self.population[i].utilization
	end
	return working / #self.population
end

-- getters. has to be a better way to do this. TODO

-- takes a town implicitly
-- returns whether or not labor can be marshalled from there
function town:get_availability()
	if self.available then return "calm" else return "rioting!" end
end

-- takes a town
-- returns its status (independent town or part of a city)
function town:get_status() 
	if #self.parts > 2 then return "City" else return "Town" end
end

-- this is so janky
function town:get_relief()
	if self.poor_house then return "yes" else return "no" end
end

-- takes a town, implicitly, and a field or other location, could be a manor, anything with a loc table in it
-- returns whether the distance from that location (typically a field) is less than the town's travel radius, as in, will people from the town travel there
-- note that if there's a rail network radius is irrelevant
-- side fx: none
function town:check_distance(from)
	return not from.loc or game.rail_network or math.sqrt( (from.loc[1] - self.loc[1])^2 + (from.loc[2] - self.loc[2])^2 ) < self.radius
end

-- takes a town, implicitly
-- !!! Assumes that the town has available labor, which it should 
-- returns: the worker that will be assigned
-- side fx: tons
function town:get_labor(amt)
	for i = 1, #self.population do
		if (1 - self.population[i].utilization) >= amt then return self.population[i] end
	end
end

-- takes a town and an amount of labor
-- returns whether or not the town has that much labor remaining among its pops, and whether people can be hired out of the town at all
-- side fx: none
function town:has_labor(amt)
	if self.available then
		for i = 1, #self.population do
			if (1 - self.population[i].utilization) > amt then
				return true
			end
		end
	end
	return false
end

function town:grow()
	print("growing "..self.name)
	local grown = false
	while not grown do
		local x, y = math.random(-1, 1), math.random(-1, 1)
		local j = math.random(#self.parts)
		print(self.parts[j][1] + x)
		print(self.parts[j][2] + y)
		print(j)
		local current = land.get_tile( { self.parts[j][1] + x, self.parts[j][2] + y } ).t
		local cannot_be = ("water" or "swamp" or "port" or "town")
		print((current == cannot_be))
		if not (current == cannot_be) then
			land.map[self.parts[j][2] + y][self.parts[j][1] + x] = nil
			land.map[self.parts[j][2] + y][self.parts[j][1] + x] = {t = "town", part_of = self}
			table.insert(self.parts, { self.parts[j][1] + x, self.parts[j][2] + y } )
			print("new type: "..land.get_tile( { self.parts[j][1] + x, self.parts[j][2] + y } ).t)
		end
		grown = true
	end
end