-- corn by yarlesp
-- pl development 2013

season = {"Spring", "Summer", "Fall", "Winter" }  --change these values in future

function season.update() 
	if game.season < 4 then
		game.season = game.season + 1
	elseif game.season == 4 then
		game.season = 1
		game.year = game.year + 1
	end

	-- update everything
	capitalist.update()
	for i = 1, #game.farmers do 
		game.farmers[i]:update()
	end
	for i = 1, #game.landlords do
		game.landlords[i]:update()
	end
	for i = 1, #game.towns do
		game.towns[i]:update()
	end
	--worker.update() --TODO
	--sraffian_model.update()
end