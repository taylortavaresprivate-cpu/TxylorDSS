-- ========================================================================
-- DSS TAB: TC SYSTEM
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local u    = require "cfg_ui"

local M = {}

-- ========================================================================
-- MONITOR INLINE
-- ========================================================================

local function drawMonitor()
	local tcMult   = ac.load("dss_tc_mult")      or 1.0
	local tcSlip   = ac.load("dss_tc_slip")      or 0.0
	local tcThresh = ac.load("dss_tc_threshold") or (cfg.tc_threshold * 0.002)

	-- Escalas para exibição (0-1 para barra)
	local slipFrac  = math.min(tcSlip / 0.5, 1.0)  -- normaliza: 0.5 slip = barra cheia
	local cutFrac   = 1.0 - tcMult
	local threshFrac = math.min(tcThresh / 0.5, 1.0)

	local barW = u.getWindowWidth() - 24
	local barH = 10
	local cursor = ui.getCursor()
	cursor = vec2(cursor.x + 4, cursor.y)

	-- Barra de Slip
	ui.pushStyleColor(ui.StyleColor.Text, rgbm(1.0, 0.6, 0.1, 1))
	ui.text('Slip')
	ui.popStyleColor()
	ui.sameLine(barW - 50, 0)
	ui.text(string.format('%.0f%%', slipFrac * 100))
	ui.offsetCursorY(2)
	cursor = ui.getCursor(); cursor = vec2(cursor.x + 4, cursor.y)
	ui.drawRectFilled(cursor, cursor + vec2(barW, barH), rgbm(0.15, 0.15, 0.15, 1), 2)
	if slipFrac > 0 then
		ui.drawRectFilled(cursor, cursor + vec2(barW * math.min(slipFrac, 1), barH), rgbm(1.0, 0.6, 0.1, 1), 2)
	end
	-- Linha de threshold
	if threshFrac > 0 and threshFrac <= 1 then
		local tx = cursor.x + threshFrac * barW
		ui.drawLine(vec2(tx, cursor.y - 1), vec2(tx, cursor.y + barH + 1), rgbm(1.0, 0.95, 0.2, 0.9), 2)
	end
	ui.dummy(vec2(barW + 8, barH + 4))

	-- Barra de Corte
	ui.offsetCursorY(2)
	ui.pushStyleColor(ui.StyleColor.Text, rgbm(0.9, 0.15, 0.15, 1))
	ui.text('Corte')
	ui.popStyleColor()
	ui.sameLine(barW - 50, 0)
	ui.text(string.format('%.0f%%', cutFrac * 100))
	ui.offsetCursorY(2)
	cursor = ui.getCursor(); cursor = vec2(cursor.x + 4, cursor.y)
	ui.drawRectFilled(cursor, cursor + vec2(barW, barH), rgbm(0.15, 0.15, 0.15, 1), 2)
	if cutFrac > 0 then
		ui.drawRectFilled(cursor, cursor + vec2(barW * math.min(cutFrac, 1), barH), rgbm(0.9, 0.15, 0.15, 1), 2)
	end
	ui.dummy(vec2(barW + 8, barH + 4))

	ui.offsetCursorY(4)
end

-- Compatibilidade com TxylorConfig.lua
function M.drawGraphs(dt) end

function M.draw()
	u.cfgCheckbox('TC Ativado', 'tc_enabled')
	ui.offsetCursorY(4)
	if cfg.tc_enabled then
		ui.pushStyleColor(ui.StyleColor.Text, u.colGreen)
		ui.text('  Tração detectada automaticamente.')
		ui.popStyleColor(); ui.offsetCursorY(4)

		u.header('NÍVEL')
		local newTcLevel = u.levelSelector('tc', cfg.tc_level, 20,
			data.TC_LEVEL_NAMES, data.TC_LEVEL_DATA, u.colBlue)
		if newTcLevel ~= cfg.tc_level then cfg.tc_level = newTcLevel; data.dirty = true end
		ui.offsetCursorY(4)

		if cfg.tc_level >= 1 and cfg.tc_level <= 20 then
			local l = data.TC_LEVEL_DATA[cfg.tc_level]
			cfg.tc_threshold=l[1]; cfg.tc_min_gas=l[2]
			cfg.tc_intensity=l[3]; cfg.tc_smooth=l[4]
		end

		-- Monitor inline
		drawMonitor()

		u.header('SENSIBILIDADE')
		u.cfgSliderInt('Threshold', 'tc_threshold', 0, 100,
			'Menor = TC intervém mais cedo. (físico: valor × 0.002)')
		u.cfgSliderInt('Vel. mínima', 'tc_min_speed', 0, 100,
			'TC inativo abaixo desta velocidade.')

		u.header('INTENSIDADE')
		u.cfgSliderInt('Gás mínimo', 'tc_min_gas', 0, 100,
			'Aceleração mínima preservada pelo TC. (físico: valor × 0.01)')
		u.cfgSliderInt('Intensidade', 'tc_intensity', 1, 100,
			'Proporção de corte por excesso de deslizamento. (físico: valor × 0.01)')

		u.header('SUAVIZAÇÃO')
		u.cfgSliderInt('Smooth', 'tc_smooth', 1, 100,
			'Velocidade de resposta ao cortar gás. (físico: valor × 0.1)')

		u.header('AVANÇADO')
		u.cfgSliderInt('Divisor ndSlip', 'tc_ndslip_div', 10, 50,
			'Escala do sensor (padrão: 24 = 2.4 físico). (físico: valor × 0.1)')
		u.cfgSliderInt('Fator Curva', 'tc_curve_factor', 0, 10,
			'0 = TC igual sempre; 10 = TC relaxa 100% em curva.')
	else
		ui.offsetCursorY(8); u.hint('TC desativado.')
	end
end

return M
