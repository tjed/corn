local core = require 'core'

local function default_draw(state, fraction, x,y,w,h, vertical)
	local c = core.color[state]
	if state ~= 'normal' then
		love.graphics.setColor(c.fg)
		love.graphics.rectangle('fill', x+3,y+3,w,h)
	end
	love.graphics.setColor(c.bg)
	love.graphics.rectangle('fill', x,y,w,h)

	-- draw quadrants
	love.graphics.setColor(c.fg[1], c.fg[2], c.fg[3], math.min(c.fg[4], 127))
	love.graphics.line(x+w/2,y, x+w/2,y+h)
	love.graphics.line(x,y+h/2, x+w,y+h/2)

	-- draw cursor
	local xx = x + fraction.x * w
	local yy = y + fraction.y * h
	love.graphics.setColor(c.fg)
	love.graphics.circle('fill', xx,yy,4,4)
end

-- the widget
return function(info, x,y,w,h, draw)
	assert(type(info) == 'table' and type(info.value) == "table", "Incomplete slider value info")
	info.min = info.min or {x = 0, y = 0}
	info.max = info.max or {x = math.max(info.value.x or 0, 1), y = math.max(info.value.y or 0, 1)}
	local fraction = {
		x = (info.value.x - info.min.x) / (info.max.x - info.min.x),
		y = (info.value.y - info.min.y) / (info.max.y - info.min.y),
	}

	local id = core.generateID()
	core.updateState(id, x,y,w,h)
	core.registerDraw(id,draw or default_draw, fraction, x,y,w,h)

	-- update value
	if core.isActive(id) then
		fraction = {
			x = (core.mouse.x - x) / w,
			y = (core.mouse.y - y) / h,
		}
		fraction.x = math.min(1, math.max(0, fraction.x))
		fraction.y = math.min(1, math.max(0, fraction.y))
		local v = {
			x = fraction.x * (info.max.x - info.min.x) + info.min.x,
			y = fraction.y * (info.max.y - info.min.y) + info.min.y,
		}
		if v.x ~= info.value.x or v.y ~= info.value.y then
			info.value = v
			return true
		end
	end
	return false
end
