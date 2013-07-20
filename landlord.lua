-- corn by yarlesp
-- pl development 2013

landlord = {	name = "Mr. Wilcox", 
				fortune = 0, 
				manors = {}, 
				estate = {}
			}

landlord.__index = landlord

function landlord.new( manor ) 
	o = {name = "Mr. "..high_names[math.random(#high_names)], manors = { manor }, estate = {} }
	setmetatable(o, landlord)
	table.insert(game.landlords, o)
	return o
end

function landlord:update()
	
end

-- takes a tile
-- returns whether or not the landlord in question owns it
function landlord:owns(tile)
	for i = 1, #self.estate do 
		if self.estate[i] == tile then
			return true
		end
	end
	return false
end

-- takes a tile (not a landlord, check the dot)
-- returns the landlord who owns the manor closest to it (who owns it)
function landlord.check_distance(x, y)
	local closest = nil
	local closest_dist = 99
	for i = 1, #game.landlords do
		for j = 1, #game.landlords[i].manors do
			if math.sqrt( (game.landlords[i].manors[j].loc[1] - x)^2 + (game.landlords[i].manors[j].loc[2] - y)^2 ) < closest_dist then
				closest_dist = math.sqrt( (game.landlords[i].manors[j].loc[1] - x)^2 + (game.landlords[i].manors[j].loc[2] - y)^2 )
				closest = game.landlords[i].manors[j]
			end
		end
	end
	return closest
end