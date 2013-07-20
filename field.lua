-- corn by yarlesp
-- pl development 2013

field = { 	fertility = 1,																-- what comes back when you plant
			manor = "n/a", 																-- the manor closest to the field, which in turn is owned by a landlord
			worker = nil, 																-- who gets the wage
			intensity = {k = 1/(2 + game.capital_tech), l = 1/(2 + game.labor_tech) }, -- I only buy organically composed capital
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
-- side fx: on the field. 
function field:update(season)
	if season == 3 and self.activity.improving then 
		self.fertility = self.fertility + 1 
	elseif season == 3 and self.intensity.k > 1/3 and game.options.decay then
		self.fertility = self.fertility * .95
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