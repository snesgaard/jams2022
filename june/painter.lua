local painter = {}

local function compute_vertical_offset(valign, font_h, h)
    if valign == "top" then
		return 0
	elseif valign == "bottom" then
		return h - font_h
    else
        return (h - font_h) / 2
	end
end

function painter.text(text, x, y, w, h, opt, sx, sy)
    local opt = opt or {}
    if opt.font then gfx.setFont(opt.font) end

    local sx = sx or 1
    local sy = sy or sx

    local dy = compute_vertical_offset(
        opt.valign, gfx.getFont():getHeight() * sy, h
    )

    gfx.printf(text, x, y + dy, w / sx, opt.align or "left", 0, sx, sy)
end

return painter
