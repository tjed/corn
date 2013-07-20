-- corn by yarlesp
-- pl development 2013
splash = {inter = 0}

function splash.draw()
	love.graphics.setBackgroundColor( 0, 0, 0) --whoo hoo!
	love.graphics.setColor(255, 255, 255)
	love.graphics.print("PL Development Presents:", display_w * tile_width / 2 - 80, 30, 0, 1, 1, 0, 0)
	love.graphics.draw( love.graphics.newImage("img/splash.png"), display_w * tile_width / 2 - 100, display_h * tile_width / 2 - 150, 0, 1, 1, 0, 0)
	love.graphics.print("The game of classical political economy", display_w * tile_width / 2 - 128, 400, 0, 1, 1, 0, 0)
	--love.graphics.draw(corn, display_w * tile_width / 2 + 15 - (splash.inter / 2), 0 - splash.inter, math.pi / 4, 5 + (splash.inter / 20), 5 + (splash.inter / 20), 0, 0)
end

function splash.update( dt )
	splash.inter = splash.inter + dt
end