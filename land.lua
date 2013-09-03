-- corn by yarlesp
-- pl development 2013

land = {  map = {},                     -- current map
          hover = nil,                  -- tile under the player's cursor
          start_focus = nil,            -- where to start drawing land as if it were selected
          end_focus = nil,              -- where to end
          erase = true,                 -- whether or not to overwrite the start_drag and end_drag
          view_open = nil,              -- whether or not a view of a town or manor or whatever is open      
          mode = nil}                   -- mapmode. manor view, labor radius view, whatever

local display_y = 0   -- the exact pixels, on the abstract map, at which we're starting the render cycle, e.g. 0, 0 if we're in the extreme upper left corner
local display_x = 0
local first_x = 1     -- the exact tiles which we're beginning the render cycle on. the portion of these tiles we display is determined by display_x and _y
local first_y = 1
local offset_x = 0
local offset_y = 0

local gui_shift = 25  -- height of the gui bar (top and bottom have to be the same)

local inter = 0       -- for the soft pulsing that goes on lol

width = 0             --see land.load()
height = 0

-- TODO NXT: put all these locals in different closues somehow
local minimap = nil
local minimap_x = 0
local minimap_y = 0
local minimap_w = 0
local minimap_h = 0

function land.load()
  width = maps[current_map]:getWidth()
  height = maps[current_map]:getHeight()
  minimap = love.graphics.newImage(maps[current_map])
  minimap_x = (tile_width * display_w) - (width * 5)
  minimap_y = (tile_height * display_h) - ( (height * 5) + gui_shift )
  minimap_w = width * 5
  minimap_h = height * 5

  for y = 1, height do
    land.map[y] = {}
    for x = 1, width do
      local z = land.get_type( maps[current_map]:getPixel(x - 1, y - 1) )
      if z == "town" then 
        land.map[y][x] = town.new( {x, y} )
        land.map[y][x]:populate(math.random(game.options.max_pop))
        game.population = game.population + #land.map[y][x].population
        capitalist.towns[#capitalist.towns + 1] = land.map[y][x]
      elseif z == "capital" then
        land.map[y][x] = { t = z, focus = false}
      elseif z == "forest" then
        land.map[y][x] = { t = z, thickness = 2, growth = 1, clear_cut = false, prune = false, manor = nil, focus = false, to_improve = 6, loc = {x, y}}
      elseif z == "road" then
        land.map[y][x] = { t = z, blocked = false, focus = false, manor = nil, loc = {x, y} }
      elseif z == "water" then
        land.map[y][x] = { t = z , focus = false}
      elseif z == "swamp" then
        land.map[y][x] = { t = z, depth = 2, draining = false, focus = false, to_improve = 6, manor = nil}
      elseif z == "manor" then
        land.map[y][x] = manor.new( {x, y} )
        land.map[y][x].owner = landlord.new( land.map[y][x] )
      elseif z == "port" then
        land.map[y][x] = {t = z, focus = false, open = game.tariff }
      elseif type(z) == "number" then 
        land.map[y][x] = field.new( z, {x, y} )
        if z > game.high_fertility then game.high_fertility = z end 
        if z < game.low_fertility then game.low_fertility = z end
      end
    end
  end

  -- assign land
  for y = 1, height do
    for x = 1, width do
      if land.map[y][x].fertility or land.map[y][x].t == "forest" or land.map[y][x].t == "swamp" or land.map[y][x].t == "road" then
        land.map[y][x].manor = landlord.check_distance(x, y)
      end 
    end 
  end 
end

function land.draw()
  love.graphics.setBackgroundColor(0, 0, 0)
  love.graphics.setColor(255, 255, 255) 
  love.graphics.setColorMode("modulate")
  offset_x = display_x % tile_width
  offset_y = display_y % tile_height

  first_x = math.floor(display_x / tile_width)
  first_y = math.floor(display_y / tile_height)

	for y = 1, (display_h) do
		for x = 1, (display_w + 1) do
      if y + first_y >= 1 and y + first_y <= height and x + first_x >= 1 and x + first_x <= width then
        local draw_x = ((x-1)*tile_width) - offset_x -- 4 readability
        local draw_y = ((y-1)*tile_height) - offset_y + gui_shift
        local cur = land.map[first_y + y][first_x + x]

        -- handing tile drawing in the case of fields
        -- first draw the appropriate field, then shade it to indicate its status
        if cur.t == "swamp" then
          love.graphics.drawq( t_sheet, terrain.swamp, draw_x, draw_y )
        elseif cur.population then -- if the tile has population then its a town
          love.graphics.drawq( t_sheet, terrain.town, draw_x, draw_y )
        elseif cur.t == "road" then love.graphics.drawq( t_sheet, terrain.road, draw_x, draw_y )
        elseif cur.t == "water" then love.graphics.drawq( t_sheet, terrain.water, draw_x, draw_y )
        elseif cur.t == "forest" then love.graphics.drawq( t_sheet, terrain.forest, draw_x, draw_y )
        elseif cur.t == "port" then love.graphics.drawq( t_sheet, terrain.port, draw_x, draw_y )
        elseif cur.store then love.graphics.drawq( t_sheet, terrain.manor, draw_x, draw_y )
        elseif cur.fertility then           
          if cur.fertility > 4 then 
            love.graphics.drawq( t_sheet, terrain.high, draw_x, draw_y )
          elseif 
            cur.fertility > 2 then love.graphics.drawq( t_sheet, terrain.low, draw_x, draw_y ) 
          else 
            love.graphics.drawq( t_sheet, terrain.waste, draw_x, draw_y ) 
          end
        end

        -- draw selected
        if land.start_focus and land.end_focus then
          if first_y + y >= math.min(land.start_focus[2], land.end_focus[2]) and first_x + x >= math.min(land.start_focus[1], land.end_focus[1]) and first_y + y <= math.max(land.end_focus[2], land.start_focus[2]) and first_x + x <= math.max(land.end_focus[1], land.start_focus[1]) then
            love.graphics.setColor(0, 0, 255, 50 * math.abs(math.sin(inter)))
            love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
            love.graphics.setColor(255, 255, 255)
          end
        end

        -- shade to indicate ownership
        -- manor view
        if land.mode == "manor" or (land.view_open and land.view_open.store) then
          if cur.manor then
            if land.mode == "manor" then
              for i = 1, #game.landlords do
                if cur.manor.owner == game.landlords[i] then
                  love.graphics.setColor(0 , 255 - (i * (255 / #game.landlords)), 0 + (i * (255 / #game.landlords)), 100)
                  love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
                end
              end
            elseif land.view_open then
              if cur.manor ~= land.view_open then
                love.graphics.setColor(0 , 0, 0, 100)
                love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
              end 
            end
          end
        end

        -- shade to indicate town proximity
        -- town view
        if land.mode == "town" or (land.view_open and land.view_open.population) then
          if land.mode == "town" then
            for i = 1, #capitalist.towns do
              if cur.loc and capitalist.towns[i]:check_distance(cur) then
                love.graphics.setColor(0 , 255 - (i * (255 / #game.landlords)), 255, 50)
                love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
              end
            end
          elseif land.view_open then
            if not land.view_open:check_distance(cur) then
              love.graphics.setColor(0 , 0, 0, 100)
              love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
            end
          end
        end

        -- shade to indicate fertility
        -- fertility view
        if land.mode == "fertility" and cur.fertility then
          love.graphics.setColor(0, (cur.fertility - game.low_fertility) / (game.high_fertility - game.low_fertility) * 255, 0, 50)
          love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
          love.graphics.setColor(0, 0, 0)
          love.graphics.print(cur.fertility, draw_x + 20, draw_y + 10, 0, 2, 2, 0, 0)
        end

        love.graphics.setColor(255, 255, 255) 

        -- shade to indicate status
        -- red for investment
        -- green for planting
        if cur.fertility then
          if cur.activity.improving then
            love.graphics.setColor(255, 0, 0, 50 * math.abs(math.sin(inter)))
            love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
            love.graphics.setColor(255, 255, 255)
          elseif cur.activity.planting then
            love.graphics.setColor(0, 255, 0, 50 * math.abs(math.cos(inter)))
            love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
            love.graphics.setColor(255, 255, 255)
          end
        end
      end
		end
	end
end

function land.draw_gui()
  love.graphics.setColorMode("replace")
  
  for i = 1, #capitalist.towns do
    if capitalist.towns[i].selected then
      local l = capitalist.towns[i]
      local draw_x = (l.loc[1] - first_x - 1) * tile_width - offset_x
      local draw_y = (l.loc[2] - first_y - 1) * tile_height - offset_y + gui_shift
      love.graphics.setColor(0, 0, 0)
      love.graphics.rectangle("line", draw_x, draw_y, 50, 50)
      love.graphics.rectangle("fill", draw_x + (tile_width / 2), draw_y + (tile_height / 2), 220, 60)
      love.graphics.setColor(255, 255, 255)
      love.graphics.print(l:get_status().." of "..l.name, draw_x + (tile_width / 2 ), draw_y + tile_height / 2, 0, 1, 1, 0, 0)
      love.graphics.print("Population: "..#l.population..", "..(math.floor(l:get_employment()*100) ).."% employed, ".." "..l:get_availability(), draw_x + (tile_width/2 ), draw_y + tile_height / 2 + 20, 0, 1, 1, 0, 0)
      love.graphics.print("Poor House: "..l:get_relief(), draw_x + (tile_width / 2 ), draw_y + tile_height / 2 + 40, 0, 1, 1, 1, 0, 0)
    end
  end

  for i = 1, #game.landlords do
    for j = 1, #game.landlords[i].manors do
      if game.landlords[i].manors[j].selected then
        local l = game.landlords[i].manors[j]
        local draw_x = (l.loc[1] - first_x - 1) * tile_width - offset_x
        local draw_y = (l.loc[2] - first_y - 1) * tile_height - offset_y + gui_shift
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", draw_x, draw_y, 50, 50)
        love.graphics.rectangle("fill", draw_x + (tile_width / 2), draw_y + (tile_height / 2), 200, 35)
        love.graphics.setColor(255, 255, 255)
        love.graphics.print(game.landlords[i].manors[j].owner.name.."'s Manor", draw_x + (tile_width / 2) + 20, draw_y + (tile_height / 2) + 5, 0, 1, 1, 0, 0)
        love.graphics.print("Store: "..game.landlords[i].manors[j].store.." Guards: "..game.landlords[i].manors[j].guards, draw_x + (tile_width / 2) + 20, draw_y + (tile_height / 2) + 20, 0, 1, 1, 0, 0)
        love.graphics.drawq(c_sheet, classes.landlord, draw_x + (tile_width / 2), draw_y + ( (tile_height / 2) ) )
      end
    end
  end

  love.graphics.setColor(0, 0, 0)
  
  love.graphics.rectangle("fill", 0, 0, tile_width * display_w, 25)
  love.graphics.rectangle("fill", 0, tile_height * display_h - gui_shift, tile_width * display_w, 25)
  love.graphics.rectangle("fill", minimap_x - 5, minimap_y - 5, minimap_w + 5, minimap_h + 5)
  love.graphics.draw(minimap, minimap_x, minimap_y, 0, 5, 5, 0, 0)
  love.graphics.rectangle("line", minimap_x + ( display_x / 10), minimap_y + (display_y / 10), display_w * 5, (display_h * 5) - 5)
  love.graphics.rectangle("fill", minimap_x - 5, minimap_y - 20, 20, 15)
  love.graphics.rectangle("fill", minimap_x + 25, minimap_y - 20, 20, 15)
  love.graphics.rectangle("fill", minimap_x + 55, minimap_y - 20, 20, 15)
  love.graphics.setColorMode("modulate")

  if land.mode == "manor" then
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Manor View", minimap_x + 1, minimap_y - 17, math.pi / -6, 1.2, 1.2, 0, 0)
    --love.graphics.print("M", minimap_x + 1, minimap_y - 17, 0, 1, 1, 0, 0)
    love.graphics.setColor(0, 0, 0)
  else
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("M", minimap_x + 1, minimap_y - 17, 0, 1, 1, 0, 0)
  end

  if land.mode == "town" then
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Town View", minimap_x + 31, minimap_y - 17, math.pi / -6, 1.2, 1.2, 0, 0)
    love.graphics.setColor(0, 0, 0)
  else
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("T", minimap_x + 31, minimap_y - 17, 0, 1, 1, 0, 0)
  end

  if land.mode == "fertility" then
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Fertility View", minimap_x + 61, minimap_y - 17, math.pi / -6, 1.2, 1.2, 0, 0)
    love.graphics.setColor(0, 0, 0)
  else
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("F", minimap_x + 61, minimap_y - 17, 0, 1, 1, 0, 0)
  end

  love.graphics.setColor(255, 0, 0)

  love.graphics.setColor(255, 255, 255)
  
  love.graphics.printf(season[game.season].." "..game.year, 5, 5, 90, "right")

  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Corn: "..math.floor(capitalist.fortune), 110, 5, 0, 1, 1, 0, 0)
  love.graphics.print("Labor: "..math.floor(capitalist.employed).." / "..game.population, 180, 5, 0, 1, 1, 0, 0)  -- utilization
  love.graphics.print("Wage: "..game.wage_rate, 280, 5, 0, 1, 1, 0, 0)
  if game.tariff then
    love.graphics.print("Importation Restricted", 350, 5, 0, 1, 1, 0, 0)
  else
    love.graphics.setColor(255, 0, 0)
    love.graphics.print("Importation Unrestricted", 350, 5, 0, 1, 1, 0, 0)
    love.graphics.setColor(255, 255, 255)
  end
  love.graphics.print("K Tech: "..game.capital_tech, 540, 5, 0, 1, 1, 0, 0)
  love.graphics.print("L Tech: "..game.labor_tech, 640, 5, 0, 1, 1, 0, 0)

  if land.hover then
    local l = land.hover
    if l.fertility then -- if the land selected is a field (and if only one field is selected)
      local to_print = " FERTILITY: "
      if l.activity.planting then
        to_print = to_print..l.fertility
      elseif l.activity.improving then
        to_print = to_print.."*BEING IMPROVED*"
      else 
        to_print = to_print..l.fertility..", fallow "
      end
      love.graphics.print(to_print, 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
    else 
      if l.t == "road" then
        love.graphics.print(l.t, 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
      elseif l.t == "forest" then
        love.graphics.print("forest", 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
      elseif l.t == "swamp" then
        love.graphics.print("swamp", 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
      elseif l.population then
        love.graphics.print(l.name..", "..(l:get_employment()*100 ).."% employment", 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
        for i = 1, #capitalist.towns do
          capitalist.towns[i].selected = false
        end
        l.selected = true
        land.view_open = l
      elseif l.t == "water" then
        love.graphics.print("water", 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
      elseif l.t == "port" then
        local to_print = ""
        if l.t.open then to_print = to_print.."open to foreign grains" 
        else to_print = to_print.."closed to foreign grains" end
        love.graphics.print("Wharf status: "..to_print, 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
      elseif l.t == "capital" then -- send em to tha capital
        player.update("l")
      elseif l.store then -- send em to tha manor
        love.graphics.print("a manor", 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
        for i = 1, #game.landlords do
          for j = 1,  #game.landlords[i].manors do
            game.landlords[i].manors[j].selected = false
          end
        end
        l.selected = true
        land.view_open = l
      end
    end
  end
  
  if game.options.decay then love.graphics.print("decay activated", display_w * tile_width - 105, display_h * tile_height - 20, 0, 1, 1, 0, 0) end
end

function land.update_display(force_x, force_y)
  if force_x and force_y then -- if the minimap is telling us to set display directly 
    display_x, display_y = force_x * tile_width, force_y * tile_height
  else -- if we don't have values from the minimap, then poll keyboard input as usual
    if love.keyboard.isDown("up") then
      display_y = display_y-8
    elseif love.keyboard.isDown("down") then
      display_y = display_y+8
    end

    if love.keyboard.isDown("left")  then
      display_x = display_x-8
    elseif love.keyboard.isDown("right")  then
      display_x = display_x+8
    end
  end

  -- bounds checking, less than
  if display_x < 0 then
    display_x = 0
  end

  if display_y < 0 then
    display_y = 0
  end 
  --bounds checking, greater than
  local max_display_x = tile_width * (width - display_w) 
  local max_display_y = tile_height * (height - display_h) + gui_shift * 2 

  if display_x > max_display_x then
    display_x = max_display_x
  end
      
  if display_y > max_display_y then
    display_y = max_display_y
  end
end

function land.update( dt ) 
  if game.state == 2 then
    local x = first_x + math.ceil( (offset_x + love.mouse.getX()) / tile_width)
    local y = first_y + math.ceil( (offset_y + love.mouse.getY() - gui_shift) / tile_height)
    local t_x = love.mouse.getX()
    local t_y = love.mouse.getY()
    if land.map[y] and land.map[y][x] and not love.mouse.isDown("l") then
      if not(t_y > minimap_y - 20 and t_x > minimap_x) then
        land.hover = land.map[y][x]
        land.map[y][x].hover = true
        land.mode = nil
      else
        land.hover = nil
        if (t_y > minimap_y - 20 and t_x > minimap_x - 5) and (t_y < minimap_y and t_x < minimap_x + 15) then
          land.mode = "manor"
        elseif (t_y > minimap_y - 20 and t_x > minimap_x + 25) and (t_y < minimap_y and t_x < minimap_x + 45) then
          land.mode = "town"
        elseif (t_y > minimap_y - 20 and t_x > minimap_x + 55) and (t_y < minimap_y and t_x < minimap_x + 75) then
          land.mode = "fertility"
        else
          land.mode = nil
        end
      end
    end
    if love.mouse.isDown("r") then
      land.start_focus, land.end_focus = nil, nil
      for i = 1, #capitalist.towns do
        capitalist.towns[i].selected = false
      end
      for i = 1, #game.landlords do
        for j = 1,  #game.landlords[i].manors do
          game.landlords[i].manors[j].selected = false
        end
      end
      land.view_open = nil
    elseif love.mouse.isDown("l") then
      if t_y > minimap_y - 20 and t_x > minimap_x  then -- minimap
        t_y = ( ( t_y - minimap_y ) / 5 ) - (display_h / 2) -- places the minimap click in the right scale, and centers the map display on the click
        t_x = ( ( t_x - minimap_x ) / 5 ) - (display_w / 2)
        land.update_display(t_x, t_y)
      elseif land.view_open and land.start_focus then
        --if land.start_focus < 
      elseif not land.view_open and not land.start_focus or land.erase then
        if x > width then x = width end 
        if y > height  then y = height end 
        land.start_focus = { x, y }
        land.erase = false
      elseif land.start_focus then
        if x > width then x = width end 
        if y > height  then y = height end 
        land.end_focus = { x, y }
      end
    elseif not love.mouse.isDown("l") then
      land.erase = true
    end
    inter = dt + inter
    land.update_display()
  end
end

-- helper functions:

function land.get_type( r, g, b )  -- alpha ignored, for now. idk what its purpose would be with a max of like 10 tiles total
  if r == 0 and g == 0 and b == 0 then -- town
    return "town"
  elseif r == 255 and g == 255 and b == 255 then -- waste land
    return 1
  elseif r == 128 and g == 64 and b == 0 then -- forest
    return "forest"
  elseif r == 255 and g == 0 and b == 0 then -- slightly better waste land
    return 2
  elseif r == 0 and g == 255 and b == 0 then -- productive land
    return 3
  elseif r == 0 and g == 0 and b == 255 then -- ocean
    return "water"
  elseif r == 195 and g == 195 and b == 195 then -- road
    return "road"
  elseif r == 255 and g == 255 and b == 128 then -- swamp
    return "swamp"
  elseif r == 127 and g == 127 and b == 127 then -- manors...
    return "manor"
  elseif r == 200 and g == 191 and b == 231 then
    return "port"
  else
    return 1
  end
end

-- helper functions

-- obvs
function land.get_tile( loc )
  return land.map[loc[2]][loc[1]]
end

-- also obvs
-- this probably doesn't even have to be in the land file. lol
function land.get_distance(from, to)
  return math.sqrt( math.abs(from.loc[1] - to.loc[1]) + math.abs(from.loc[2] - to.loc[2]) )
end