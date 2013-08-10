-- corn by yarlesp
-- pl development 2013

-- for now the player is a capitalist. this class works only with capitalist.lua

player = { class = 2 }  --1-> landlord 2-> capitalist 3-> worker 4-> peasant

function player.update( key )
	-- what anyone can do: 

	-- visit parliament
	if key == "l" and game.state ~= 0 and game.state ~= 1 then
		if game.state ~= 3 then 
			game.state = 3 
		elseif game.state == 3 then 
			game.state = 2
		end
		return
	end

	-- skip to next turn 
	if key == "return" then
		game.change_season()
		return
	end

	-- restart on a different map. for fun
	if key == "m" then
		if current_map < map_count then current_map = current_map + 1
		else current_map = 1 end
		land.load()
		capitalist.fortune, capitalist.employed_ag, capitalist.employed_ind = 10, {}, {}
		game.year, game.season = 1803, 1
		return
	end

	-- toggle d-cay
	if key == "d" then 
		game.options.decay = not game.options.decay
		return
	end

	if land.start_focus and land.end_focus then
		if player.class == 1 then 											
			landlord.keypressed( key )
		elseif player.class == 2 then	
			capitalist.keypressed( key )
		elseif player.class == 3 then								
			worker.keypressed( key )
		elseif player.class == 4 then									
			farmer.keypressed( key )
		end
	end
end
