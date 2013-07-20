local core = require 'core'

local function default_draw(state, fraction, x,y,w,h, vertical)
	local c = core.color[state]
	if state ~= 'normal' then
		love.graphics.setColor(c.fg)
		love.graphics.rectangle('fill', x+3,y+3,w,h)
	end
	love.graphics.setColor(c.bg)
	love.graphics.rectangle('fill', x,y,w,h)

	love.graphics.setColor(c.fg)
	local hw,hh = w,h
	if vertical then
		hh = h * fraction
	else
		hw = w * fraction
	end
	love.graphics.rectangle('fill', x,y,hw,hh)
end

-- the widget
return function(info, x,y,w,h, draw)
	assert(type(info) == 'table' and info.value, "Incomplete slider value info")
	info.min = info.min or 0
	info.max = info.max or math.max(info.value, 1)
	local fraction = (info.value - info.min) / (info.max - info.min)

	local id = core.generateID()
	core.updateState(id, x,y,w,h)
	core.registerDraw(id,draw or default_draw, fraction, x,y,w,h, info.vertical)

	-- update value
	if core.isActive(id) then
		if info.vertical then
			fraction = math.min(1, math.max(0, (core.mouse.y - y) / h))
		else
			fraction = math.min(1, math.max(0, (core.mouse.x - x) / w))
		end
		local v = fraction * (info.max - info.min) + info.min
		if v ~= info.value then
			info.value = v
			return true
		end
	end
	return false
end
