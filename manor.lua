-- corn by yarlesp
-- pl development 2013

manor = { 	owner = nil,
			loc = {0, 0},
			store = 0,
			guards = 0}

manor.__index = manor

function manor.new(loc)
	o = { loc = loc, store = math.random(10), guards = math.random(5), owner = nil }
	setmetatable(o, manor)
	return o
end