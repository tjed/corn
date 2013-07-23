-- corn by yarlesp
-- pl development 2013

require "game"
require "land"
require "player"
require "season"
require "splash"
require "win"         -- its required

require "capitalist"
require "worker"
require "farmer"
require "landlord"    

require "parliament"  -- where we go to debate lawes
require "manor"       -- where landlords live and where their stash is
require "town"        -- where pops (farmers) live
require "field"       -- individual productive (agricultural) tiles
require "farm"        -- farms are made of fields

require "sraffian_model"

gui = require 'gui'

--local profiler = require "ProFi" --debug

function love.load()
  -- some globals 4 yall
  display_w = 15 -- amt of tiles to display at any one time
  display_h = 15

  tile_width = 50 -- the sprites i stole from the steel panthers website are 50x50. the real steel panthers sprites are super weird hex-based lbms
  tile_height = 50

  current_map = 3 -- see /maps
  map_count = 0

  -- load all the gfx. 

  corn = love.graphics.newImage("img/corn.png") -- corn

  t_sheet = love.graphics.newImage("img/terrain_sheet.png") -- refers to terrain, below

  terrain = { water =   love.graphics.newQuad(0, 0, 50, 50, 200, 200),
              waste =   love.graphics.newQuad(50, 0, 50, 50, 200, 200 ),
              low =     love.graphics.newQuad(100, 0, 50, 50, 200, 200 ), 
              high =    love.graphics.newQuad(150, 0, 50, 50, 200, 200 ), 
              swamp =   love.graphics.newQuad(0, 50, 50, 50, 200, 200), 
              forest =  love.graphics.newQuad(50, 50, 50, 50, 200, 200), 
              road =    love.graphics.newQuad(100, 50, 50, 50, 200, 200), 
              bridge =  love.graphics.newQuad(150, 50, 50, 50, 200, 200), 
              town =    love.graphics.newQuad(0, 150, 50, 50, 200, 200), 
              port =    love.graphics.newQuad(50, 100, 50, 50, 200, 200),
              manor =   love.graphics.newQuad(0, 100, 50, 50, 200, 200),
              garrison =nil, --TODO
              factory = nil, --TODO
              fog =     love.graphics.newQuad(50, 150, 50, 50, 200, 200)
            }

  c_sheet = love.graphics.newImage("img/pops_small.bmp") -- refers to classes, below
  
  classes = { landlord =  love.graphics.newQuad(0, 0, 16, 35, 160, 35), 
              peasant =   love.graphics.newQuad(112, 0, 16, 35, 160, 35),
              capitalist =love.graphics.newQuad(48, 0, 16, 35, 160, 35),
              worker =    love.graphics.newQuad(80, 0, 16, 35, 160, 35)
            }

  -- todo: make an icon sheet
  icons =   { capital = nil,
              labor = nil,
              wage_rate = nil,
              tarrif = nil,
              labor_tech = nil,
              capital_tech = nil
            }

  -- load all the name files. feel free 2 add
  high_names = {}

  for line in love.filesystem.lines("data/names_high.txt") do
    table.insert(high_names, line)
  end

  low_names = {}

  for line in love.filesystem.lines("data/names_low.txt") do
    table.insert(low_names, line)
  end

  place_names = {}

  for line in love.filesystem.lines("data/names_place.txt") do
    table.insert(place_names, line)
  end

  -- load all the maps
  maps = love.filesystem.enumerate("maps")
  for i=1, #maps do
    maps[i] = love.image.newImageData("maps/"..i..".png")
  end
  map_count = #maps

  math.randomseed(os.time()) -- this should go before game.start or it's meaningless lol
  game.start() -- bitch!!!
  love.graphics.setMode( display_w * tile_width, display_h * tile_height, false, true, 0 )

  --profiler:start() -- only uncomment if you have ProFi.lua in the same directory
end

function love.draw()
  game.draw()
end

function love.mousepressed(x_sel, y_sel, button)
  if game.state == 2 then
    --land.update_selected(button)
  elseif game.state == 3 then
    parliament.update(x_sel, y_sel)
  end
end

function love.keypressed( key )
  if key == "escape" then
    if game.state == 0 then
      game.state = 2
      game.paused = false
    else
      love.event.push("quit")
      --profiler:stop()
      --profiler:writeReport("report.txt")
    end
  elseif key == "rctrl" then -- debug console has to be enabled first, "your_love_install_directory\love.exe" --console in the shortcut
    debug.debug();
  else
    player.update( key )
  end
end

function love.update( dt )
    game.update( dt )
end