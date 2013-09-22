-- corn by yarlesp
-- pl development 2013

garrison = {loc = nil,			-- obvs
			name = "barracks",	-- name of the garrison, if any
			t = "garrison",
			design = "star",	-- design. star or old school? idk. this might be too much to worry about
			contains = {},		-- which regiments are based/supplied out of here
			strength = 10,		-- resistance to seigeing, represents the physical status of the defenses, magazine, etc. prolonged seiges ruin the fort
			supply_radius = 10,	-- how far supplies can travel from a particular fort. 
			supplies = 0		-- physical amt of supplies which can be disbursed
			}

garrison.__index = garrison

function garrison.new(loc)
	local o = {}
	o.loc = loc
	o.strength = 10
	o.contains = {}
	table.insert(o.contains, regiment.new(loc) )
	setmetatable(o, garrison)
	return o
end

-- called each season
-- each season every garrison must send its units supplies
-- if a 
function garrison:update()
	for i = 1, #self.contains do 
		if not math.sqrt( (self.contains[i].loc[1] - self.loc[1])^2 + (self.contains[i].loc[2] - self.loc[1])^2 ) < self.supply_radius then
			if self.supplies > 1 then 
				self.supplies = self.supplies - 1
			end
		end
	end
end

-- takes a garrison implicitly
-- takes a location
-- returns whether or not the location is within the supply range of the garrison
function garrison:in_radius(from)
	local length = math.sqrt( (from[1] - self.loc[1])^2 + (from[2] - self.loc[2])^2 )
	return length < self.supply_radius 
end