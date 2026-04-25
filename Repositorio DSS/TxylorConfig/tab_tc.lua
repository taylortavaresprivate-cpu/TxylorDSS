-- ========================================================================
-- DSS TAB: TC SYSTEM
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local u    = require "cfg_ui"

local M = {}

-- ========================================================================
-- ESTADO DO MONITOR
-- ========================================================================

local activeMonitor = false
local _winPos  = vec2(0, 0)
local _winSize = vec2(0, 0)

local MONITOR_W   = 200
local MONITOR_H   = 175
local HISTORY_LEN = 120

local histSlip = {}
local histCut  = {}
for i = 1, HISTORY_LEN do histSlip[i] = 0; histCut[i] = 0 end
local histHead     = 1
local monitorTimer = 0

-- Escala de exibição do slip: 0-100 (mesma unidade do slider threshold)
-- slip físico × 1000 = slip em escala UI
local SLIP_MAX = 100.0

-- ========================================================================
-- CONSTANTES VISUAIS
-- ========================================================================

local COL_BG     = rgbm(0.08, 0.08, 0.08, 0.96)
local COL_BORDER = rgbm(0.30, 0.30, 0.30, 1)
local COL_TRACK  = rgbm(0.15, 0.15, 0.15, 1)
local COL_VALUE  = rgbm(0.95, 0.95, 0.95, 1)
local COL_TITLE  = rgbm(1.0,  0.6,  0.1,  1)
local COL_SLIP   = rgbm(1.0,  0.6,  0.1,  1)
local COL_CUT    = rgbm(0.9,  0.15, 0.15, 1)
local COL_THRESH = rgbm(1.0,  0.95, 0.2,  0.9)
local COL_FWD    = rgbm(0.3,  0.6,  1.0,  1)
local COL_RWD    = rgbm(0.9,  0.15, 0.15, 1)
local COL_AWD    = rgbm(1.0,  0.85, 0.2,  1)

-- ========================================================================
-- MONITOR EM TEMPO REAL
-- ========================================================================

local function pushHistory(slip, cut)
	histSlip[histHead] = slip
	histCut[histHead]  = cut
	histHead = (histHead % HISTORY_LEN) + 1
end

local function drawMonitor(dt)
	local tcMult = ac.load("dss_tc_mult")       or 1.0
	local tcSlip = ac.load("dss_tc_slip")       or 0.0
	local dtType = ac.load("dss_tc_drivetrain")

	local slipUI  = tcSlip * 1000.0
	local cutFrac = 1.0 - tcMult

	monitorTimer = monitorTimer + dt
	if monitorTimer >= 0.033 then
		pushHistory(slipUI / SLIP_MAX, cutFrac)
		monitorTimer = 0
	end

	local W, H   = MONITOR_W, MONITOR_H
	local barPad = 10
	local barW   = W - barPad * 2
	local barH   = 12
	local barY0  = 38

	ui.drawRectFilled(vec2(0, 0), vec2(W, H), COL_BG, 6)
	ui.drawRect(vec2(0, 0), vec2(W, H), COL_BORDER, 6, 1)

	-- Título
	ui.setCursor(vec2(8, 7))
	ui.pushStyleColor(ui.StyleColor.Text, COL_TITLE)
	ui.text('TC Monitor')
	ui.popStyleColor()

	-- Badge drivetrain
	if dtType ~= nil then
		local names = {'FWD', 'RWD', 'AWD'}
		local cols  = {COL_FWD, COL_RWD, COL_AWD}
		local idx   = math.floor(dtType) + 1
		if names[idx] then
			ui.sameLine(0, 6)
			ui.pushStyleColor(ui.StyleColor.Text, cols[idx])
			ui.text('['..names[idx]..']')
			ui.popStyleColor()
		end
	end

	-- Barra unidirecional com linha de threshold opcional
	local function drawBar(y, frac, col, label, valText, threshFrac)
		ui.drawRectFilled(vec2(barPad, y), vec2(barPad + barW, y + barH), COL_TRACK, 2)
		local fc = math.min(math.max(frac, 0), 1)
		local fillX = barPad + fc * barW
		if fc > 0 then
			ui.drawRectFilled(vec2(barPad, y + 2), vec2(fillX, y + barH - 2), col, 1)
		end
		ui.drawLine(vec2(fillX, y), vec2(fillX, y + barH), rgbm(1, 1, 1, 0.9), 2)
		if threshFrac and threshFrac > 0 and threshFrac <= 1 then
			local tx = barPad + threshFrac * barW
			ui.drawLine(vec2(tx, y - 3), vec2(tx, y + barH + 3), COL_THRESH, 1.5)
		end
		ui.setCursor(vec2(barPad, y - 14))
		ui.pushStyleColor(ui.StyleColor.Text, col)
		ui.text(label)
		ui.popStyleColor()
		ui.sameLine(0, 4)
		ui.pushStyleColor(ui.StyleColor.Text, COL_VALUE)
		ui.text(valText)
		ui.popStyleColor()
	end

	local threshFrac = (cfg.tc_threshold or 53) / SLIP_MAX
	drawBar(barY0,      slipUI / SLIP_MAX, COL_SLIP, 'Slip ',
		string.format('%.0f', slipUI), threshFrac)
	drawBar(barY0 + 32, cutFrac, COL_CUT, 'Corte',
		string.format('%d%%', math.floor(cutFrac * 100 + 0.5)), nil)

	-- Gráfico histórico
	local gx = barPad
	local gy = barY0 + 68
	local gw = barW
	local gh = H - gy - 8

	ui.drawRectFilled(vec2(gx, gy), vec2(gx + gw, gy + gh), rgbm(0.04, 0.04, 0.04, 1))

	-- Linha de threshold no gráfico
	local threshY = gy + gh - math.min(threshFrac, 1.0) * gh
	ui.drawLine(vec2(gx, threshY), vec2(gx + gw, threshY), rgbm(1.0, 0.95, 0.2, 0.3), 1)

	for i = 0, HISTORY_LEN - 2 do
		local i0 = ((histHead - 2 - i - 1) % HISTORY_LEN) + 1
		local i1 = ((histHead - 2 - i)     % HISTORY_LEN) + 1
		local x0 = gx + gw - (i + 1) * (gw / HISTORY_LEN)
		local x1 = gx + gw - i       * (gw / HISTORY_LEN)

		local sy0 = gy + gh - histSlip[i0] * gh
		local sy1 = gy + gh - histSlip[i1] * gh
		ui.drawLine(vec2(x0, sy0), vec2(x1, sy1), rgbm(1.0, 0.6, 0.1, 0.9), 1.5)

		local cy0 = gy + gh - histCut[i0] * gh
		local cy1 = gy + gh - histCut[i1] * gh
		ui.drawLine(vec2(x0, cy0), vec2(x1, cy1), rgbm(0.9, 0.2, 0.2, 0.8), 1)
	end
end

-- ========================================================================
-- OVERLAY
-- ========================================================================

function M.drawGraphs(dt)
	if not activeMonitor then return end
	local gx = _winPos.x + _winSize.x + 8
	local gy = _winPos.y
	ui.transparentWindow('dss_tc_monitor', vec2(gx, gy), vec2(MONITOR_W, MONITOR_H), function()
		drawMonitor(dt)
	end)
end

-- ========================================================================
-- DRAW PRINCIPAL
-- ========================================================================

function M.draw()
	_winPos  = ui.windowPos()
	_winSize = ui.windowSize()

	-- Botão Monitor (sempre visível, igual à aba Direção)
	local isMonOpen = activeMonitor
	if isMonOpen then
		ui.pushStyleColor(ui.StyleColor.Button,        rgbm(0.7, 0.1, 0.1, 1))
		ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.9, 0.2, 0.2, 1))
	end
	if ui.button('⊙ Monitor##tc_monitor_btn', vec2(u.getWindowWidth() - 16, 20)) then
		activeMonitor = not activeMonitor
	end
	if isMonOpen then ui.popStyleColor(2) end
	ui.offsetCursorY(4)

	u.cfgCheckbox('TC Ativado', 'tc_enabled')
	ui.offsetCursorY(4)
	if cfg.tc_enabled then
		ui.pushStyleColor(ui.StyleColor.Text, u.colGreen)
		ui.text('  Tração detectada automaticamente.')
		ui.popStyleColor()
		ui.offsetCursorY(4)

		u.header('NÍVEL')
		local isDrift = cfg.tc_level >= 1 and cfg.tc_level <= 3
		local tcColor = isDrift and u.colPurple or u.colBlue
		local newTcLevel = u.levelSelector('tc', cfg.tc_level, 23,
			data.TC_LEVEL_NAMES, data.TC_LEVEL_DATA, tcColor)
		if newTcLevel ~= cfg.tc_level then cfg.tc_level = newTcLevel; data.dirty = true end
		isDrift = cfg.tc_level >= 1 and cfg.tc_level <= 3
		if isDrift then
			ui.pushStyleColor(ui.StyleColor.Text, u.colPurple)
			ui.text('  ZONA DRIFT'); ui.popStyleColor()
		elseif cfg.tc_level >= 4 then
			ui.pushStyleColor(ui.StyleColor.Text, u.colBlue)
			ui.text('  ZONA GRIP'); ui.popStyleColor()
		end
		ui.offsetCursorY(4)

		if cfg.tc_level >= 1 and cfg.tc_level <= 23 then
			local l = data.TC_LEVEL_DATA[cfg.tc_level]
			cfg.tc_threshold=l[1]; cfg.tc_min_gas=l[2]
			cfg.tc_intensity=l[3]; cfg.tc_smooth=l[4]
		end

		u.header('SENSIBILIDADE')
		u.cfgSliderInt('Threshold', 'tc_threshold', 0, 100,
			'Menor = TC intervém mais cedo. (físico: valor × 0.001)')
		u.cfgSlider('Vel. mínima', 'tc_min_speed', 0.0, 100.0, '%.0f km/h',
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
		u.cfgSliderInt('Slip Ratio Scale', 'tc_slip_ratio_scale', 0, 10,
			'0 = só ndSlip; 5 = detecta reta também; 10 = máximo. (físico: valor × 0.2)')
		u.cfgSliderInt('Recovery Speed', 'tc_recovery', 1, 150,
			'Velocidade de liberação do gás após slip controlado. (físico: valor × 0.1)')
	else
		ui.offsetCursorY(8); u.hint('TC desativado.')
	end
end

return M
