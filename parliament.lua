-- corn by yarlesp
-- pl development 2013

parliament = {can_vote = { true, false, false} } -- class 1: landlords, class 2: bourgeoisie, class 3: peasants and workers

function parliament.draw()
	love.graphics.setBackgroundColor( 173, 150, 140)
	love.graphics.setColorMode("replace")
	love.graphics.print("WELCOME TO PARLIAMENT", 20, 25, 0, 2, 2, 0, 0)
	love.graphics.printf(season[game.season].." "..game.year, 5, 5, 90, "right")
	if game.paused then love.graphics.print("pause,", (display_w * tile_width) - 50, 5, 0, 1, 1) end
	love.graphics.printf("Here, in parliament, there are a number of issues which may be debated. Firstly the question of the tarrif applied to foreign Corns may be decided, secondly the issue of voting rights and thirdly the issue of the length of the working day. \n \n", 20, 50, 300, "left")
	love.graphics.printf("At present "..parliament.get_voters().." may vote.", 20, 150, 300, "left")
	love.graphics.printf("Working day: "..parliament.get_hours(), 20, 180, 300, "left")
	love.graphics.printf("Corn Tariff: "..parliament.get_tariff(), 20, 210, 300, "left")
end

function parliament.get_voters() -- my string fu sucks
	voters = "only "
	if parliament.can_vote[1] then voters = voters.."the nobility " end
	if parliament.can_vote[2] then voters = voters.."and the wealthy " end
	if parliament.can_vote[3] then voters = "everyone, from the lowest to the highest," end
	return voters
end

function parliament.get_hours()
	hours = " unrestricted"
	if game.ten_hour_bill then hours = " restricted to ten hours" end
	return hours
end

function parliament.get_tariff()
	tariff = " restricted to grains costing less than 70p"
	if not game.tariff then tariff = " unrestricted" end
	return tariff
end

function parliament.update(x_sel, y_sel)
	
end