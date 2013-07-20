local core = require 'core'

local function default_draw(state, text, x,y,w,h,align)
	local c = core.color[state]
	love.graphics.setColor(c.fg)
	local f = assert(love.graphics.getFont())
	if align == 'center' then
		x = x + (w - f:getWidth(text))/2
		y = y + (h - f:getHeight(text))/2
	elseif align == 'right' then
		x = x + w - f:getWidth(text)
		y = y + h - f:getHeight(text)
	end
	love.graphics.print(text, x,y)
end

-- the widget
return function(text, x,y,w,h, align, draw)
	local id = core.generateID()
	w = w or 0
	h = h or 0
	align = align or 'left'
	core.registerDraw(id, draw or default_draw,  text,x,y,w,h,align)
	return false
end

