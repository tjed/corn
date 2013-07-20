-- corn by yarlesp
-- pl development 2013

game = {season = 1, 								-- season: 1 = spring, 2 = summer, 3 = fall, 4 = winter
		state = 0, 									-- state: 0 = splash, 1 = menu, 2 = land, 3 = parliament
		paused = true, 
		year = 1803, 
		tariff = true, 								-- whether or not we can import corn
		ten_hour_bill = false,						-- whether or not the working day is unrestricted
		wage_rate = 1, 								-- all three, profit, wages, and rent, are determined at the same time at the end of the season.
		profit_rate = 1,							-- p/h
		rent_rate = 1,								-- p/h
		high_fertility = 0,							-- highest fertility of all land under cultivation. used to calculate rent
		low_fertility = 0,							-- the lowest fertility of all land under cultivation. used to calculate rent
		population = 0,								-- total pops in all towns and cities, excluding landlords and the single capitalist
		labor_tech = 1, 							-- higher values reduce labor intensity in agriculture
		capital_tech = 1,							-- higher values reduce capital intensity in agriculture
		rail_network = false,						-- a rail network allows farmers/workers to migrate or work anywhere. invalidates the 'radius' thing
		options = { decay = false, max_pop = 5 }, 	-- if enabled land gradually loses fertility as it is cultivated year-over-year
		workers = {},								-- all workers
		farmers = {},								-- all farmers
		landlords = {}								-- all landlords
	}


function game.start()
	land.load()
end

function game.update( dt )
	if not game.paused then 
		if season.time > season.length[game.season] then
			season.time = 0
			game.change_season()
	    else 
	    	season.time = season.time + dt
	    	if win.check() then love.event.push("quit") end
	    end
	end

	if game.state == 2 then
		land.update( dt )
	elseif game.state == 0 then
		splash.update( dt )
	end
end

function game.change_season() -- is this right? put ur moves in and wait?
	season.update()
end

function game.draw() -- depends on state
	if game.state == 0 then
		splash.draw()
	elseif game.state == 1 then
		--menu.draw()
	elseif game.state == 2 then
		land.draw()
		land.draw_gui()
	elseif game.state == 3 then
		parliament.draw()
	end
end