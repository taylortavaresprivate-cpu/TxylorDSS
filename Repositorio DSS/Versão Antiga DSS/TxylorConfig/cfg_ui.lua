-- ========================================================================
-- DSS CONFIG UI HELPERS
-- ========================================================================

local data = require "cfg_data"
local cfg      = data.cfg
local defaults = data.defaults

local M = {}

-- ========================================================================
-- CORES
-- ========================================================================

M.colChanged = rgbm(1.0,0.4,0.15,1)
M.colGreen   = rgbm(0.3,0.85,0.3,1)
M.colBlue    = rgbm(0.4,0.65,1.0,1)
M.colPurple  = rgbm(0.7,0.3,0.9,1)
M.colYellow  = rgbm(1.0,0.85,0.2,1)
M.colRed     = rgbm(1.0,0.2,0.2,1)
M.colWhite   = rgbm(0.95,0.95,0.95,1)
M.colCyan    = rgbm(0.2,0.9,0.9,1)
M.colOrange  = rgbm(1.0,0.6,0.1,1)

function M.getColHeader() return rgbm(cfg.ui_header_r, cfg.ui_header_g, cfg.ui_header_b, 1) end
function M.getColAccent() return rgbm(cfg.ui_accent_r, cfg.ui_accent_g, cfg.ui_accent_b, 1) end
function M.getColHint()   return rgbm(cfg.ui_hint_r,   cfg.ui_hint_g,   cfg.ui_hint_b,   1) end
function M.getColLine()   return rgbm(cfg.ui_line_r,   cfg.ui_line_g,   cfg.ui_line_b,   1) end

-- ========================================================================
-- LAYOUT
-- ========================================================================

function M.getWindowWidth()
	local ok, size = pcall(function() return ui.windowSize() end)
	if ok and size then return size.x end
	return 530
end

function M.getSliderWidth()
	return math.max(M.getWindowWidth() - 80, 200)
end

-- ========================================================================
-- WIDGETS
-- ========================================================================

function M.cfgSlider(label, key, vmin, vmax, fmt, tooltip)
	ui.setNextItemWidth(M.getSliderWidth())
	local newVal = ui.slider('##'..key, cfg[key], vmin, vmax, label..':  '..fmt)
	if ui.itemEdited() then cfg[key] = newVal; data.dirty = true end
	if cfg[key] ~= defaults[key] then
		ui.sameLine(0, 4)
		ui.pushStyleColor(ui.StyleColor.Text, M.colChanged); ui.text('●'); ui.popStyleColor()
	end
	if tooltip then
		ui.sameLine(0, 4)
		ui.pushStyleColor(ui.StyleColor.Text, M.getColAccent())
		ui.text('?')
		ui.popStyleColor()
		if ui.itemHovered() then ui.setTooltip(tooltip) end
	end
end

function M.cfgCheckbox(label, key)
	if ui.checkbox(label, cfg[key]) then cfg[key] = not cfg[key]; data.dirty = true end
end

function M.header(text)
	ui.offsetCursorY(6)
	ui.pushStyleColor(ui.StyleColor.Text, M.getColHeader())
	ui.text(text)
	ui.popStyleColor()
	local cursor = ui.getCursor()
	local w = M.getWindowWidth() - 16
	ui.drawLine(cursor, cursor + vec2(w, 0), M.getColLine(), 1)
	ui.offsetCursorY(6)
end

function M.hint(text)
	ui.pushStyleColor(ui.StyleColor.Text, M.getColHint())
	ui.text('  '..text)
	ui.popStyleColor()
end

function M.info(text)
	ui.pushStyleColor(ui.StyleColor.Text, M.getColAccent())
	ui.text('  '..text)
	ui.popStyleColor()
end

function M.levelSelector(id, level, maxLevel, names, levelData, labelColor)
	ui.offsetCursorY(2)
	local levelLabel = level==0 and '  Manual  '
		or ('  '..level..'/'..maxLevel..' — '..names[level]..'  ')
	if ui.button('◄##'..id..'down', vec2(28,0)) then level = math.max(0, level-1) end
	ui.sameLine(0,6)
	ui.pushStyleColor(ui.StyleColor.Text, labelColor); ui.text(levelLabel); ui.popStyleColor()
	ui.sameLine(0,6)
	if ui.button('►##'..id..'up', vec2(28,0)) then level = math.min(maxLevel, level+1) end
	ui.offsetCursorY(4)
	if level >= 1 and level <= maxLevel then
		local l = levelData[level]
		M.hint(string.format('Threshold: %.3f   Min: %.2f', l[1], l[2]))
		M.hint(string.format('Intensidade: %.2f  Smooth: %.1f', l[3], l[4]))
		ui.offsetCursorY(4); M.hint('Selecione Manual (0) para ajuste individual.')
	else
		M.hint('Modo manual — utilize os controles abaixo.')
	end
	ui.offsetCursorY(2); return level
end

-- ========================================================================
-- LOGO
-- ========================================================================

local LOGO_PATH = "logo_dss.png"

function M.drawLogo()
	ui.offsetCursorY(12)
	local cursor = ui.getCursor()
	local w = M.getWindowWidth() - 16
	local logoW = math.min(w * 0.7, 300)
	local logoH = logoW * 0.2
	local logoX = (w - logoW) / 2
	ui.drawImage(LOGO_PATH, cursor + vec2(logoX, 0), cursor + vec2(logoX + logoW, logoH))
	ui.setCursor(cursor + vec2(0, logoH + 8))
end

-- ========================================================================
-- TAB BAR
-- ========================================================================

M.currentTab = 0

local TAB_NAMES = {
	[0] = 'DIREÇÃO',    [1] = 'PEDAIS',     [2] = 'ABS SYSTEM',  [3] = 'TC SYSTEM',
	[4] = 'TRANSMISSÃO',[5] = 'EXTRAS',     [6] = 'PRESETS',     [7] = 'SOBRE',
}

function M.drawTabBar()
	local winW = M.getWindowWidth() - 16
	local tabW = math.floor(winW / 4)
	local tabH = 24

	local colTabBg       = rgbm(0.15, 0.15, 0.15, 1)
	local colTabActive   = M.getColHeader()
	local colTabHover    = rgbm(0.25, 0.25, 0.25, 1)
	local colTabText     = rgbm(0.85, 0.85, 0.85, 1)
	local colTabTextAct  = rgbm(1, 1, 1, 1)

	local startCursor = ui.getCursor()

	for row = 0, 1 do
		for col = 0, 3 do
			local tabIdx = row * 4 + col
			local x = col * tabW
			local y = row * (tabH + 2)
			local p1 = startCursor + vec2(x, y)
			local p2 = p1 + vec2(tabW - 2, tabH)

			local isActive  = (M.currentTab == tabIdx)
			local isHovered = ui.rectHovered(p1, p2)

			if isActive then
				ui.drawRectFilled(p1, p2, colTabActive)
			elseif isHovered then
				ui.drawRectFilled(p1, p2, colTabHover)
			else
				ui.drawRectFilled(p1, p2, colTabBg)
			end

			if isActive then
				ui.drawLine(vec2(p1.x, p2.y), p2, colTabActive, 2)
			end

			local name = TAB_NAMES[tabIdx]
			local textColor = isActive and colTabTextAct or colTabText
			local textSize = ui.measureText(name)
			local textPos = p1 + vec2((tabW - 2 - textSize.x) / 2, (tabH - textSize.y) / 2)

			ui.setCursor(textPos)
			ui.pushStyleColor(ui.StyleColor.Text, textColor)
			ui.text(name)
			ui.popStyleColor()

			if isHovered and ui.mouseClicked(0) then
				M.currentTab = tabIdx
			end
		end
	end

	ui.setCursor(startCursor + vec2(0, 2 * (tabH + 2) + 4))
end

return M