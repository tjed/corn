-- corn by yarlesp
-- pl development 2013

town = { 	population = {},		-- pops, mix of workers and peasants
			urban = false,			-- whether or not it's a city. if it is maxpop is way larger and factories can be built there. and everyone turns into a worker. 
			owner = nil,			-- capitalist, or, nobody...
			name = "Town of ",		-- duh
			loc = {0, 0},			-- location of the town on the map
			radius = 5,				-- how far labor is allowed to travel from the town
			available = true,		-- if over 50% of the village is starving then they start to riot
			poor_house = false,		-- first value is whether or not there is a poor house. second value is the amount of corn it has to share out
			part_of = nil			-- the city the town is part of (if any)
		}

town.__index = town

function town.new(location)
	local o = {loc = location}
	setmetatable(o, town)
	local named = false
	while not named do -- not that effecient but it works
		o.name = place_names[math.random(#place_names)]
		named = true
		for i = 1, #capitalist.towns do
			if o.name == capitalist.towns[i].name then named = false end
		end
	end
	o.population = {}
	o.available = true
	o.poor_house = false
	table.insert(game.towns, o)
	return o
end

-- takes a town (implicitly) and an amount to add to the population of the town (defaults to 1 if called without arguments), as long as the population is below max
-- side fx: modifies the town, and by extension game.population and a whole bunch of other stuff. dangerous!
function town:populate( with, t )
	if #self.population < game.options.max_pop then
		for i = 1, with or 1 do
			if t == nil or t == "farmer" then
				table.insert(self.population, farmer:new(self.loc) )
			elseif t == "worker" then
				table.insert(self.population, worker:new(self.loc) )
			end
		end
	end
end

-- called once at the end of the season
-- if people are starving the town will enter riot mode!
-- if people are happy another family will form. 
-- if the town has reached its maximum population it will form a city
-- unless it's already part of a city in which case the city handles the expansion
function town:update()
	local angry = 0
	for i = 1, #self.population do
		if self.population[i].starving then
			angry = angry + 1
		end
	end
	self.available = (angry / #self.population) < .3
	if game.season == 3 then 
		if self.available and #self.population < game.options.max_pop then 
			self:populate()
		elseif self.available and #self.population >= game.options.max_pop then
			if not self.part_of then
				self:to_city()
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

-- takes a town implicitly
-- returns whether or not labor can be marshalled from there
function town:get_availability()
	if self.available then return "calm" else return "agitated" end
end

-- takes a town
-- returns its status (independent town or part of a city)
function town:get_status() 
	if self.part_of then return "City" else return "Town" end
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

-- makes a town a city
function town:to_city()
	table.insert( game.cities, city.new(self) )
end