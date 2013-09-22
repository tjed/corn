-- corn by yarlesp
-- pl development 2013

field = { 	fertility = 1,																-- what comes back when you plant
			t = "field",																
			manor = "n/a", 																-- the manor closest to the field, which in turn is owned by a landlord
			worker = nil, 																-- who gets the wage
			intensity = {k = 1/(2 + game.capital_tech), l = 1/(2 + game.labor_tech) }, 	-- I only buy organically composed capital
			to_improve = 3,																-- how much it costs to improve the tile (* intensity.k)
			activity = { improving = false, planting = false},							-- what's goin on in the tile this season
			loc = {0, 0}
		}

field.__index = field

function field.new(fertility, loc)
	local o = { activity = {improving = false, planting = false} }
	setmetatable(o, field)
	o.intensity = {k = 1/(2 +  game.capital_tech), l = 1/(2 + game.labor_tech) }
	o.fertility = fertility
	o.loc = loc
	return o
end

-- implicitly takes a field
-- changes its fertility based on settings (decay) and player input (investment etc)
-- also removes everything at the end of the year
-- side fx: on the field. 
function field:update()
	if game.season == 3 and self.activity.improving then 
		self.fertility = self.fertility + 1 
	elseif game.season == 3 and self.intensity.k > 1/3 and game.options.decay then
		self.fertility = self.fertility * .95
	elseif game.season == 4 then
		self.activity.improving = false
		self.activity.planting = false
		self.worker.utilization = 0
		self.worker.available = true
	end
end

-- implicitly takes a field
-- runs through the list of towns in its radius, and returns either a town with a worker, or nil, implying nobody's available
-- side fx: none
function field:check_labor(req)
	for i = 1, #capitalist.towns do
		if capitalist.towns[i]:has_labor(req) and capitalist.towns[i]:check_distance(self) then
			return capitalist.towns[i]
		end
	end
	return nil
end

function field:to_string()
	return self.fertility.." "..self.loc[1].." "..self.loc[2].." "..self.worker.name
end

-- takes a thing to search for (either a manor or a town)
-- takes a field (implicitly)
-- returns the instance of the particular type nearest to the field
function field:nearest(t)
	local closest = nil
	local closest_dist = 99
	if t == "manor" then
		for i = 1, #game.landlords do
			for j = 1, #game.landlords[i].manors do
				if math.sqrt( (game.landlords[i].manors[j].loc[1] - x)^2 + (game.landlords[i].manors[j].loc[2] - y)^2 ) < closest_dist then
					closest_dist = math.sqrt( (game.landlords[i].manors[j].loc[1] - x)^2 + (game.landlords[i].manors[j].loc[2] - y)^2 )
					closest = game.landlords[i].manors[j]
				end
			end
		end
	elseif t == "town" then
		for i = 1, #capitalist.towns do
			--if math.sqrt(capitalist.towns[i].loc[1] - self.)
		end
	end
	return closest
end