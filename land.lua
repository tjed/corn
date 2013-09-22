-- corn by yarlesp
-- pl development 2013

land = {  map = {},                     -- current map
          selected = nil,               -- tile clicked
          hover = nil,                  -- tile under the cursor
          start_focus = nil,            -- where to start drawing land as if it were selected
          end_focus = nil,              -- where to end   
          mode = nil}                   -- mapmode. manor view, labor radius view, whatever

local display_y = 0   -- the exact pixels, on the abstract map, at which we're starting the render cycle, e.g. 0, 0 if we're in the extreme upper left corner
local display_x = 0
local first_x = 1     -- the exact tiles which we're beginning the render cycle on. the portion of these tiles we display is determined by display_x and _y
local first_y = 1
local offset_x = 0
local offset_y = 0

local gui_shift = 25  -- height of the gui bar (top and bottom have to be the same)

local inter = 0       -- for the soft pulsing that goes on lol

local focus_rect = nil -- rectum? hardly even knew em

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
        game.towns[#game.towns + 1] = town.new( {x, y} )
        game.towns[#game.towns]:populate(math.random(game.options.max_pop))
        game.population = game.population + #game.towns[#game.towns].population
        capitalist.towns[#capitalist.towns + 1] = game.towns[#game.towns] -- the two lists are the same at game start, they might diverge though!!!
        land.map[y][x] = { t = "town", part_of = game.towns[#game.towns] }
      elseif z == "capital" then -- TODO
        land.map[y][x] = { t = z, focus = false}
      elseif z == "forest" then -- TODO
        land.map[y][x] = { t = z, thickness = 2, growth = 1, clear_cut = false, prune = false, loc = {x, y}, to_improve = 6}
      elseif z == "road" then -- need to make roads dynamic
        land.map[y][x] = { t = z, blocked = false, loc = {x, y} }
      elseif z == "water" then
        land.map[y][x] = { t = z, loc = {x, y} }
      elseif z == "swamp" then
        land.map[y][x] = { t = z, depth = 2, draining = false, to_improve = 6, manor = nil}
      elseif z == "manor" then
        land.map[y][x] = manor.new( {x, y} )
        land.map[y][x].owner = landlord.new( land.map[y][x] )
      elseif z == "port" then
        land.map[y][x] = {t = z, open = game.tariff }
      elseif type(z) == "number" then 
        land.map[y][x] = field.new( z, {x, y} )
        if z > game.high_fertility then game.high_fertility = z end 
        if z < game.low_fertility then game.low_fertility = z end
      elseif z == "garrison" then
        land.map[y][x] = garrison.new( {x, y} )
        table.insert(game.garrisons, land.map[y][x])
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
  -- TODO: quadtree
  -- game.lookup_tree.rebuild()
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
        if cur.t == "swamp" then love.graphics.drawq( t_sheet, terrain.swamp, draw_x, draw_y )
        elseif cur.t == "town" then love.graphics.drawq( t_sheet, terrain.town, draw_x, draw_y )
        elseif cur.t == "road" then love.graphics.drawq( t_sheet, terrain.road, draw_x, draw_y )
        elseif cur.t == "water" then love.graphics.drawq( t_sheet, terrain.water, draw_x, draw_y )
        elseif cur.t == "forest" then love.graphics.drawq( t_sheet, terrain.forest, draw_x, draw_y )
        elseif cur.t == "port" then love.graphics.drawq( t_sheet, terrain.port, draw_x, draw_y )
        elseif cur.contains then love.graphics.drawq( t_sheet, terrain.garrison, draw_x, draw_y )
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
        if land.start_focus and land.end_focus and not land.selected.discipline then
          if first_y + y >= math.min(land.start_focus[2], land.end_focus[2]) and first_x + x >= math.min(land.start_focus[1], land.end_focus[1]) and first_y + y <= math.max(land.end_focus[2], land.start_focus[2]) and first_x + x <= math.max(land.end_focus[1], land.start_focus[1]) then
            love.graphics.setColor(0, 0, 255, 50 * math.abs(math.sin(inter)))
            love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
            love.graphics.setColor(255, 255, 255)
          end
        end

        if land.selected and land.selected.contains and cur.loc then
          if not land.selected:in_radius( cur.loc ) then
            love.graphics.setColor(0 , 0, 0, 100)
            love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)            
          end
        end

        -- shade to indicate ownership
        -- manor view
        if land.selected and land.selected.store then
          if cur.manor ~= land.selected then 
            love.graphics.setColor(0 , 0, 0, 100)
            love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
          end
        elseif land.mode == "manor" then
          for i = 1, #game.landlords do
            if cur.manor and cur.manor.owner == game.landlords[i] then
              love.graphics.setColor(0 , 255 - (i * (255 / #game.landlords)), 0 + (i * (255 / #game.landlords)), 100)
              love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
            end
          end          
        end

        -- shade to indicate town proximity
        -- town view
        if land.selected and land.selected.part_of then
          if not land.selected.part_of:check_distance(cur) then
            love.graphics.setColor(0 , 0, 0, 100)
            love.graphics.rectangle("fill", draw_x, draw_y, tile_width, tile_height)
          end
        elseif land.mode == "town" then
          for i = 1, #capitalist.towns do
            if cur.loc and capitalist.towns[i]:check_distance(cur) then
              love.graphics.setColor(0 , 255 - (i * (255 / #game.towns)), 255, 50)
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

  if focus_rect then
    love.graphics.rectangle("line", focus_rect[1], focus_rect[2], focus_rect[3] - focus_rect[1] , focus_rect[4] - focus_rect[2])
  end

  for i = 1, #game.garrisons do
    for j = 1, #game.garrisons[i].contains do 
      if (first_x * tile_width) + offset_x < game.garrisons[i].contains[j].loc[1] and first_y * tile_height + offset_y < game.garrisons[i].contains[j].loc[2] then
        local l = game.garrisons[i].contains[j]
        local draw_x = l.loc[1] - (first_x * tile_width) - offset_x -- 4 readability
        local draw_y = l.loc[2] - (first_y * tile_height) - (offset_y + gui_shift)
        love.graphics.drawq(c_sheet, classes.soldier, draw_x - 8, draw_y - 17)
        if land.selected == game.garrisons[i].contains[j] then 
          love.graphics.rectangle("line", draw_x - 8, draw_y - 17, 16, 35) 
          if land.selected.dest then
            love.graphics.circle("fill", land.selected.dest[1] - offset_x - (first_x * tile_width), land.selected.dest[2]- gui_shift - offset_y - (first_y * tile_height), 5, 20)
          end
        end
      end
    end
  end

  -- AAAAAAAAAAAAAAA
  if land.selected and land.focus_size() < 1 and not focus_rect and not land.selected.discipline then
    local l = land.selected
    if land.selected.part_of then l = land.selected.part_of end
    local draw_x = (l.loc[1] - first_x - 1) * tile_width - offset_x
    local draw_y = (l.loc[2] - first_y - 1) * tile_height - offset_y + gui_shift
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", draw_x, draw_y, 50, 50)
    love.graphics.rectangle("fill", draw_x + (tile_width / 2), draw_y + (tile_height / 2), 250, 60)
    love.graphics.setColor(255, 255, 255)
    if l.population then
      if l.available then
        love.graphics.setColor(0, 0, 255)
      else 
        love.graphics.setColor(255, 0, 0)
      end
      love.graphics.rectangle("fill", draw_x + tile_width / 2, draw_y + tile_height / 2, 250, 20 )
      love.graphics.setColor(255, 255, 255)
      love.graphics.print(l.name, draw_x + (tile_width / 2 ) + 5, draw_y + (tile_height / 2) + 5, 0, 1, 1, 0, 0)
      love.graphics.print("Population: "..#l.population..", "..(math.floor(l:get_employment()*100) ).."% employed, "..l:get_availability(), draw_x + ( tile_width / 2 ) + 5, draw_y + tile_height / 2 + 20, 0, 1, 1, 0, 0)
      love.graphics.print("Poor House: "..l:get_relief(), draw_x + (tile_width / 2 ) + 6, draw_y + tile_height / 2 + 35, 0, 1, 1, 1, 0, 0)
    elseif l.store then
      love.graphics.print(l.owner.name.."'s Manor", draw_x + (tile_width / 2) + 20, draw_y + (tile_height / 2) + 5, 0, 1, 1, 0, 0)
      love.graphics.print("Store: "..l.store.." Guards: "..l.guards, draw_x + (tile_width / 2) + 20, draw_y + (tile_height / 2) + 20, 0, 1, 1, 0, 0)
      love.graphics.drawq(c_sheet, classes.landlord, draw_x + (tile_width / 2), draw_y + ( (tile_height / 2) ) )
    elseif land.selected and land.selected.fertility then
      local to_print = "Fertility: "..l.fertility.." Status: "
      if land.selected.activity.improving then 
        to_print = to_print.." Improving to "..(land.selected.fertility + 1)
      elseif land.selected.activity.planting then 
        to_print = to_print.." Planting" 
      end
      love.graphics.print(to_print, draw_x + (tile_width / 2)+ 5, draw_y + (tile_height / 2) + 5, 0, 1, 1, 0, 0)
      love.graphics.print("Intensity: K: 1/"..math.floor(l.intensity.k * 10).." L: 1/"..math.floor(l.intensity.k * 10), draw_x + (tile_width / 2)+ 5, draw_y + (tile_height / 2) + 25, 0, 1, 1, 0, 0)
      love.graphics.print("Part of the estate of "..l.manor.owner.name, draw_x + (tile_width / 2) + 5, draw_y + (tile_height / 2) + 45, 0, 1, 1, 0, 0)
    elseif land.selected and land.selected.contains then
      love.graphics.print("barracks, "..#land.selected.contains.." regiment(s) based here", draw_x + (tile_width / 2)+ 5, draw_y + (tile_height / 2) + 5, 0, 1, 1, 0, 0)
    end
  elseif land.selected and land.selected.discipline then
    local l = land.selected
    local draw_x = l.loc[1] - offset_x - (first_x * tile_width)
    local draw_y = l.loc[2] - offset_y - gui_shift - (first_y * tile_height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setColor(255, 255, 255)
    love.graphics.print(l.name, draw_x - 30, draw_y + 35, 0, 1, 1, 0, 0)
    love.graphics.print(land.get_tile(l.loc, true).t, draw_x - 30, draw_y + 55, 0, 1, 1, 0, 0)
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
  love.graphics.rectangle("fill", 0, 0, (game.time / season.length[game.season]) * 90, 25)

  love.graphics.setColor(255, 255, 255)
  

  if not game.paused then 
    love.graphics.printf(season[game.season].." "..game.year, 5, 5, 90, "right")
  else
    if math.sin(inter) > 0 then
      love.graphics.printf(season[game.season].." "..game.year, 5, 5, 90, "right")
    else 
      love.graphics.printf("paused   ", 5, 5, 90, "right")
    end
  end

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
      local to_print = "Field"
      if l.fertility > 4 then 
        to_print = "High Fertility "..to_print
      elseif l.fertility > 2 then 
        to_print = "Low Fertility "..to_print
      else
        to_print = "Waste Land"
      end
      love.graphics.print(to_print, 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
    else 
      if l.t == "road" then
        love.graphics.print(l.t, 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
      elseif l.t == "forest" then
        love.graphics.print("forest", 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
      elseif l.t == "swamp" then
        love.graphics.print("swamp", 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
      elseif l.t == "town" then
        local to_print = l.part_of.name..", "..l.part_of:get_availability()
        love.graphics.print(to_print, 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
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
        love.graphics.print(l.owner.name.."'s manor.", 10, (display_h * tile_height) - 20, 0, 1, 1, 0, 0)
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
  local x = first_x + math.ceil( (offset_x + love.mouse.getX()) / tile_width)
  local y = first_y + math.ceil( (offset_y + love.mouse.getY() - gui_shift) / tile_height)
  local t_x = love.mouse.getX()
  local t_y = love.mouse.getY()
  if land.map[y] and land.map[y][x] then
    if not(t_y > minimap_y - 20 and t_x > minimap_x) then
      land.hover = land.map[y][x]
    end
  end

  -- if the mouse is down but it's in the minimap area
  if love.mouse.isDown("l") and (t_y > minimap_y and t_x > minimap_x) then
    t_y = ( ( t_y - minimap_y ) / 5 ) - (display_h / 2) -- places the minimap click in the right scale, and centers the map display on the click
    t_x = ( ( t_x - minimap_x ) / 5 ) - (display_w / 2)
    land.update_display(t_x, t_y)
  -- if the mouse is down outside of the minimap area
  elseif love.mouse.isDown("l") and not (t_y > minimap_y - 20 and t_x > minimap_x) then
    if not focus_rect then 
      focus_rect = {love.mouse.getX(), love.mouse.getY(), love.mouse.getX(), love.mouse.getY()} 
    elseif focus_rect then 
      focus_rect[3] = love.mouse.getX()
      focus_rect[4] = love.mouse.getY()
    end
  end
  inter = dt + inter
  land.update_display()
end


-- see main.lua (callback comes here if game state is land view)
-- takes all relevant mouse input
function land.handle_mouse(x, y, button, action)
  local tile_x = first_x + math.ceil( (offset_x + x) / tile_width)
  local tile_y = first_y + math.ceil( (offset_y + y - gui_shift) / tile_height)
  local total_x = (first_x * tile_width) + offset_x + x
  local total_y = (first_y * tile_height) + offset_y + y + gui_shift

  -- mouse release actions
  -- note that pressing the mouse can not move the map
  -- this is handled in land.update above, where the love.mouse.isDown function is used instead. this allows dragging the map
  if action == "released" and button == "l" then
    if not(y > minimap_y - 20 and x > minimap_x) then
      land.end_focus = {tile_x, tile_y}
      land.start_focus = { first_x + math.ceil( (offset_x + focus_rect[1]) / tile_width), first_y + math.ceil( (offset_y + focus_rect[2] - gui_shift) / tile_height) }
      focus_rect = nil
    end
  end

  -- mouse pressing actions
  if action == "pressed" and button == "l" then
    -- clicking on stuff selects it
    if land.map[tile_y] and land.map[tile_y][tile_x] and not(y > minimap_y - 20 and x > minimap_x) then
      if land.selected and land.selected.discipline then land.selected = nil end
      local selected_army = false
      for i = 1, #game.regiments do
        if total_x > game.regiments[i].loc[1] - 8 and total_x < game.regiments[i].loc[1] + 8 then
          if total_y > game.regiments[i].loc[2] - 17 and total_y < game.regiments[i].loc[2] + 18 then
            land.selected = game.regiments[i]
            selected_army = true
          end 
        end 
      end
      if not selected_army then land.selected = land.map[tile_y][tile_x] end
    end
    -- clicking on the map modes activates/deactivates them
    if (y > minimap_y - 20 and x > minimap_x - 5) and (y < minimap_y and x < minimap_x + 15) then
      if land.mode ~= "manor" then
        land.mode = "manor"
      else 
        land.mode = nil
      end
    elseif (y > minimap_y - 20 and x > minimap_x + 25) and (y < minimap_y and x < minimap_x + 45) then
      if land.mode ~= "town" then
        land.mode = "town"
      else 
        land.mode = nil
      end
    elseif (y > minimap_y - 20 and x > minimap_x + 55) and (y < minimap_y and x < minimap_x + 75) then
      if land.mode ~= "fertility" then
        land.mode = "fertility"
      else 
        land.mode = nil
      end
    end
  end
  -- right clicking erases everything
  if action == "pressed" and button == "r" and not land.selected.discipline then
    if land.selected and not land.selected.discipline then land.selected = nil end
    land.start_focus = nil
    land.end_focus = nil
    land.mode = nil
    focus_rect = nil
  elseif action == "pressed" and button == "r" and land.selected.discipline then
    land.selected.dest = {total_x, total_y}
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
  elseif r == 239 and g == 228 and b == 176 then -- garrison! where regiments are
    return "garrison"
  else
    return 1
  end
end

-- obvs
-- "scale" tells the function to treat the values in loc as raw pixel values and not tile vaules (e.g. <545, 62> instead of <11, 2>)
function land.get_tile( loc, scale )
  if not scale then
    return land.map[loc[2]][loc[1]]
  else 
    return land.map[math.ceil( (loc[2] - offset_y - tile_height) / tile_height)][math.ceil( (loc[1] - offset_x) / tile_height)]
  end
end

-- also obvs
-- this probably doesn't even have to be in the land file. lol
function land.get_distance(from, to)
  return math.sqrt( math.abs(from.loc[1] - to.loc[1]) + math.abs(from.loc[2] - to.loc[2]) )
end

-- finds out how large the size of the selected area is (if it's more than 1 is all I care about)
function land.focus_size()
  if land.start_focus and land.end_focus then
    return math.abs(land.start_focus[1] - land.end_focus[1]) *  math.abs(land.start_focus[2] - land.end_focus[2])
  else return 0 end
end