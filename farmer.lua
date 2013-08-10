-- corn by yarlesp
-- pl development 2013

farmer = {	name = " family",
			savings = 1,
			class = 4,
			available = true, 
			utilization = 0,	-- a value between 0 and 1. normal fields require labor intensity of 1/3 so one dude can work 3 fields
			relief = false,
			loc = nil }

farmer.__index = farmer

function farmer:new( l )
	o = {	loc = l, 
			name = low_names[math.random(#low_names)]..farmer.name, 
			available = true, 
			utilization = 0,
			savings = 1 }
	setmetatable(o, farmer)
	table.insert(game.farmers, o)
	return o
end

-- takes an individual farmer, called at the end of the summer only
-- doesn't return anything
-- side fx: on the farmer
function farmer:update()
	if game.season == 3 then
		self.savings = self.savings - 1 -- *chomp*
		if self.available and not relief and land.get_tile(self.loc).poor_house then
			self.relief = true
		end
		if self.relief then self.savings = self.savings + 1 end
		self.available = true
		self.utilization = 0
	end
end

function farmer:to_string()
	local to = self.name
	if not self.available then
		to = to..", working"
	elseif self.available and self.utilization > 0 then
		to = to..", working "..math.floor((self.utilization / 1 * 100)).."%"
	elseif self.relief then 
		to = to..", on relief" 
	elseif not self.relief and self.available and self.savings < 1 then
		to = to..", starving"
	end
	return to
end

function farmer:type()
	return "peasant"
end