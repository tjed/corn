-- corn by yarlesp
-- pl development 2013

town = { 	population = {},	-- pops, mix of workers and peasants
			owner = nil,		-- capitalist, or, nobody...
			name = "sometown",	-- duh
			loc = {0, 0},		-- location of the town on the map
			radius = 5,			-- how far labor is allowed to travel from the town
			available = true,	-- if over 50% of the village is starving then they start to riot
			poor_house = false	-- whether or not there's a poor house in town. farmers can only go on relief if they live in a town with a poor house
		}

town.__index = town

function town.new(nom, location)
	local o = {}
	setmetatable(o, town)
	o.loc = location
	o.name = nom
	o.population = {}
	o.available = true
	o.poor_house = false
	return o
end

-- takes a town (implicitly) and an amount to add to the population of the town (defaults to 1 if called without arguments), as long as the population is below max
-- side fx: modifies the town, and by extension game.population and a whole bunch of other stuff. dangerous!
function town:populate( with )
	if #self.population < game.options.max_pop then
		for i = 1, with or 1 do
			table.insert(self.population, farmer:new(self.loc) )
		end
	end
end

-- called once at the end of the season
-- if people are starving the town will enter riot mode!
function town:update()
	local angry = 0
	for i = 1, #self.population do
		if self.population[i].starving then
			angry = angry + 1
		end
	end
	self.available = (angry / self.population) < .3
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

-- takes a town, implicitly, and a field or other location, could be a manor, anything with a loc table in it
-- returns whether the distance from that location (typically a field) is less than the town's travel radius, as in, will people from the town travel there
-- note that if there's a rail network radius is irrelevant
-- side fx: none
function town:check_distance(from)
	return game.rail_network or math.sqrt( (from.loc[1] - self.loc[1])^2 + (from.loc[2] - self.loc[2])^2 ) < self.radius
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
			--print("\n"..self.population[i].name.." of "..self.name)
			--print(self.population[i].utilization.." "..amt)
			if (1 - self.population[i].utilization) > amt then
				return true
			end
		end
	end
	return false
end