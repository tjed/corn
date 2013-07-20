-- corn by yarlesp
-- pl development 2013

worker = { 	name = " family", 
			savings = 1,
			class = 3,
			employed = false,
			relief = false,
			needs = nil,
			loc = nil}

worker.__index = worker

function worker.new(loc)
	o = { 	name = low_names[math.random(#low_names)]..worker.name, 
			loc = loc,
			needs = worker.employed or worker.relief or worker.savings > 0 }
	setmetatable(o, worker)
	return o
end

function worker:update()
end