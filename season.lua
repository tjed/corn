-- corn by yarlesp
-- pl development 2013

season = {"Spring", "Summer", "Fall", "Winter", time = 0, length = {20, 5, 10, 5} }  --change these values in future

function season.update() --notice: the state 
	if game.season < 4 then
		game.season = game.season + 1
	elseif game.season == 4 then
		game.season = 1
		game.year = game.year + 1
	end
	capitalist.update()
	--farmer.update() --TODO
	--worker.update() --TODO
	landlord.update()
	sraffian_model.update()
end