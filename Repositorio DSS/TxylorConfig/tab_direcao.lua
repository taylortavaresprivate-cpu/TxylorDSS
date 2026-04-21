-- ========================================================================
-- DSS TAB: DIREÇÃO
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local u    = require "cfg_ui"

local M = {}

-- ========================================================================
-- ESTADO DOS OVERLAYS
-- ========================================================================

local activeGraph = 'none'  -- 'none' | 'steer_gamma' | 'ffb_gamma' | 'monitor'

local _winPos  = vec2(0, 0)
local _winSize = vec2(0, 0)

-- ========================================================================
-- CONSTANTES VISUAIS
-- ========================================================================

local GRAPH_W   = 200
local GRAPH_H   = 200
local MONITOR_W = 200
local MONITOR_H = 175

local COL_BG     = rgbm(0.08, 0.08, 0.08, 0.96)
local COL_BORDER = rgbm(0.30, 0.30, 0.30, 1)
local COL_GRID   = rgbm(0.22, 0.22, 0.22, 1)
local COL_DIAG   = rgbm(0.32, 0.32, 0.32, 1)
local COL_CURVE  = rgbm(0.9,  0.15, 0.15, 1)
local COL_TITLE  = rgbm(0.9,  0.15, 0.15, 1)
local COL_LABEL  = rgbm(0.55, 0.55, 0.55, 1)
local COL_VALUE  = rgbm(0.95, 0.95, 0.95, 1)
local COL_MOUSE  = rgbm(0.9,  0.9,  0.9,  1)
local COL_STEER  = rgbm(0.9,  0.15, 0.15, 1)
local COL_FFB    = rgbm(0.3,  0.6,  1.0,  1)
local COL_ZERO   = rgbm(0.45, 0.45, 0.45, 1)
local COL_TRACK  = rgbm(0.15, 0.15, 0.15, 1)
local COL_REPLAY = rgbm(0.9,  0.7,  0.1,  1)

-- ========================================================================
-- GRÁFICO DE GAMMA
-- ========================================================================

local PAD_X = 24
local PAD_Y = 28
local GW    = GRAPH_W - PAD_X - 14
local GH    = GRAPH_H - PAD_Y - 30

local function drawGammaCurve(gamma, title)
	ui.drawRectFilled(vec2(0, 0), vec2(GRAPH_W, GRAPH_H), COL_BG, 6)
	ui.drawRect(vec2(0, 0), vec2(GRAPH_W, GRAPH_H), COL_BORDER, 6, 1)

	ui.setCursor(vec2(8, 7))
	ui.pushStyleColor(ui.StyleColor.Text, COL_TITLE)
	ui.text(title)
	ui.popStyleColor()

	local ox, oy = PAD_X, PAD_Y

	ui.drawRectFilled(vec2(ox, oy), vec2(ox + GW, oy + GH), rgbm(0.04, 0.04, 0.04, 1))

	for i = 1, 3 do
		local t = i / 4
		ui.drawLine(vec2(ox + t*GW, oy),  vec2(ox + t*GW, oy + GH),   COL_GRID, 1)
		ui.drawLine(vec2(ox, oy + t*GH),  vec2(ox + GW,   oy + t*GH), COL_GRID, 1)
	end

	ui.drawLine(vec2(ox, oy + GH), vec2(ox + GW, oy), COL_DIAG, 1)

	local steps = 64
	for i = 0, steps - 1 do
		local x0 = i / steps
		local x1 = (i + 1) / steps
		local y0 = math.min(math.pow(x0 + 1e-9, gamma), 1)
		local y1 = math.min(math.pow(x1 + 1e-9, gamma), 1)
		ui.drawLine(
			vec2(ox + x0*GW, oy + GH - y0*GH),
			vec2(ox + x1*GW, oy + GH - y1*GH),
			COL_CURVE, 2)
	end

	ui.drawLine(vec2(ox, oy),      vec2(ox, oy + GH),      COL_LABEL, 1)
	ui.drawLine(vec2(ox, oy + GH), vec2(ox + GW, oy + GH), COL_LABEL, 1)

	ui.setCursor(vec2(ox - 2, oy + GH + 4))
	ui.pushStyleColor(ui.StyleColor.Text, COL_LABEL)
	ui.text('0')
	ui.setCursor(vec2(ox + GW - 4, oy + GH + 4))
	ui.text('1')
	ui.setCursor(vec2(3, oy))
	ui.text('1')
	ui.popStyleColor()

	ui.setCursor(vec2(8, GRAPH_H - 18))
	ui.pushStyleColor(ui.StyleColor.Text, COL_VALUE)
	ui.text(string.format('gamma: %.2f', gamma))
	ui.popStyleColor()
end

-- ========================================================================
-- MONITOR EM TEMPO REAL
-- ========================================================================

local HISTORY_LEN  = 120
local histMouse    = {}
local histSteer    = {}
for i = 1, HISTORY_LEN do histMouse[i] = 0; histSteer[i] = 0 end
local histHead     = 1
local monitorTimer = 0

local function pushHistory(mouse, steer)
	histMouse[histHead] = mouse
	histSteer[histHead] = steer
	histHead = (histHead % HISTORY_LEN) + 1
end

local function drawMonitor(dt)
	-- ✅ ac.getCar(0) funciona tanto em jogo quanto em replay
	local myCar = ac.getCar(0)
	if myCar == nil then return end

	-- Steer: normalizado (-1 a 1) via steer e steerLock
	-- steerLock é em graus, steer também é em graus
	local steerLock = math.max(myCar.steerLock or 450, 1)
	local steerVal  = math.clamp(myCar.steer / steerLock, -1, 1)

	-- FFB: ffbFinal é o FFB final do jogo (funciona em replay!)
	local ffbVal = math.clamp(myCar.ffbFinal or 0, -1, 1)

	-- Mouse: só disponível em jogo via ac.load (escrito pelo dss_steering)
	local mouseRaw  = ac.load('dss_mouse_steer')
	local isLive    = (mouseRaw ~= nil)
	local mouseVal  = math.clamp(mouseRaw or 0, -1, 1)

	-- Atualiza histórico ~30fps
	monitorTimer = monitorTimer + dt
	if monitorTimer >= 0.033 then
		pushHistory(mouseVal, steerVal)
		monitorTimer = 0
	end

	local W, H = MONITOR_W, MONITOR_H

	ui.drawRectFilled(vec2(0, 0), vec2(W, H), COL_BG, 6)
	ui.drawRect(vec2(0, 0), vec2(W, H), COL_BORDER, 6, 1)

	-- Título + badge
	ui.setCursor(vec2(8, 7))
	ui.pushStyleColor(ui.StyleColor.Text, COL_TITLE)
	ui.text('Monitor')
	ui.popStyleColor()
	if not isLive then
		ui.sameLine(0, 6)
		ui.pushStyleColor(ui.StyleColor.Text, COL_REPLAY)
		ui.text('[Replay]')
		ui.popStyleColor()
	end

	-- ── BARRAS ──────────────────────────────────────────────
	local barY0  = 38
	local barH   = 12
	local barPad = 10
	local barW   = W - barPad * 2
	local cx     = barPad + barW / 2

	local function drawBar(y, value, col, label, disabled)
		ui.drawRectFilled(vec2(barPad, y), vec2(barPad + barW, y + barH), COL_TRACK, 2)
		ui.drawLine(vec2(cx, y - 2), vec2(cx, y + barH + 2), COL_ZERO, 1)
		if not disabled then
			local fillX = cx + value * (barW / 2)
			if value >= 0 then
				ui.drawRectFilled(vec2(cx, y + 2), vec2(fillX, y + barH - 2), col, 1)
			else
				ui.drawRectFilled(vec2(fillX, y + 2), vec2(cx, y + barH - 2), col, 1)
			end
			ui.drawLine(vec2(fillX, y), vec2(fillX, y + barH), rgbm(1, 1, 1, 0.9), 2)
		end
		ui.setCursor(vec2(barPad, y - 14))
		ui.pushStyleColor(ui.StyleColor.Text, disabled and COL_LABEL or col)
		ui.text(label)
		ui.popStyleColor()
		ui.sameLine(0, 4)
		ui.pushStyleColor(ui.StyleColor.Text, COL_VALUE)
		ui.text(disabled and 'N/A' or string.format('%.2f', value))
		ui.popStyleColor()
	end

	-- Mouse: N/A em replay (dss_steering não roda)
	drawBar(barY0,      mouseVal, COL_MOUSE, 'Mouse', not isLive)
	-- Steer e FFB: sempre disponíveis via ac.getCar(0)
	drawBar(barY0 + 32, steerVal, COL_STEER, 'Steer', false)
	drawBar(barY0 + 64, ffbVal,   COL_FFB,   'FFB  ', false)

	-- ── GRÁFICO DE LINHA (histórico) ─────────────────────────
	local gx  = barPad
	local gy  = barY0 + 95
	local gw  = barW
	local gh  = H - gy - 10

	ui.drawRectFilled(vec2(gx, gy), vec2(gx + gw, gy + gh), rgbm(0.04, 0.04, 0.04, 1))
	local midY = gy + gh / 2
	ui.drawLine(vec2(gx, midY), vec2(gx + gw, midY), COL_ZERO, 1)

	for i = 0, HISTORY_LEN - 2 do
		local i0 = ((histHead - 2 - i - 1) % HISTORY_LEN) + 1
		local i1 = ((histHead - 2 - i)     % HISTORY_LEN) + 1
		local x0 = gx + gw - (i + 1) * (gw / HISTORY_LEN)
		local x1 = gx + gw - i       * (gw / HISTORY_LEN)
		-- Mouse só em jogo
		if isLive then
			local my0 = midY - histMouse[i0] * (gh / 2)
			local my1 = midY - histMouse[i1] * (gh / 2)
			ui.drawLine(vec2(x0, my0), vec2(x1, my1), rgbm(0.8, 0.8, 0.8, 0.5), 1)
		end
		-- Steer sempre (funciona em replay)
		local sy0 = midY - histSteer[i0] * (gh / 2)
		local sy1 = midY - histSteer[i1] * (gh / 2)
		ui.drawLine(vec2(x0, sy0), vec2(x1, sy1), COL_STEER, 1.5)
	end
end

-- ========================================================================
-- SLIDER COM BOTÃO DE OVERLAY
-- ========================================================================

local function graphButton(key)
	ui.sameLine(0, 6)
	local isOpen = (activeGraph == key)
	if isOpen then
		ui.pushStyleColor(ui.StyleColor.Button,        rgbm(0.7, 0.1, 0.1, 1))
		ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.9, 0.2, 0.2, 1))
	end
	if ui.button('~##graph_'..key, vec2(20, 0)) then
		activeGraph = isOpen and 'none' or key
	end
	if isOpen then ui.popStyleColor(2) end
end

local function gammaSlider(label, key, tooltip)
	local sliderW = math.max(u.getWindowWidth() - 112, 140)
	ui.setNextItemWidth(sliderW)
	local newVal = ui.slider('##'..key, cfg[key], 0.0, 10.0, label..':  %.1f')
	if ui.itemEdited() then cfg[key] = newVal; data.dirty = true end
	if cfg[key] ~= data.defaults[key] then
		ui.sameLine(0, 4)
		ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
	end
	if tooltip then
		ui.sameLine(0, 4)
		ui.pushStyleColor(ui.StyleColor.Text, u.getColAccent()); ui.text('?'); ui.popStyleColor()
		if ui.itemHovered() then ui.setTooltip(tooltip) end
	end
	graphButton(key)
end

-- ========================================================================
-- OVERLAY (chamado do TxylorConfig.lua com dt)
-- ========================================================================

function M.drawGraphs(dt)
	if activeGraph == 'none' then return end

	local gx = _winPos.x + _winSize.x + 8
	local gy = _winPos.y

	if activeGraph == 'steer_gamma' then
		local gamma = 0.5 + cfg.steer_gamma * 0.1
		ui.transparentWindow('dss_graph_steer', vec2(gx, gy), vec2(GRAPH_W, GRAPH_H), function()
			drawGammaCurve(gamma, 'Steer Gamma')
		end)

	elseif activeGraph == 'ffb_gamma' then
		local gamma = 0.5 + cfg.ffb_gamma * 0.1
		ui.transparentWindow('dss_graph_ffb', vec2(gx, gy), vec2(GRAPH_W, GRAPH_H), function()
			drawGammaCurve(gamma, 'FFB Gamma')
		end)

	elseif activeGraph == 'monitor' then
		ui.transparentWindow('dss_monitor', vec2(gx, gy), vec2(MONITOR_W, MONITOR_H), function()
			drawMonitor(dt)
		end)
	end
end

-- ========================================================================
-- DRAW PRINCIPAL
-- ========================================================================

function M.draw()
	_winPos  = ui.windowPos()
	_winSize = ui.windowSize()

	local isMonOpen = (activeGraph == 'monitor')
	if isMonOpen then
		ui.pushStyleColor(ui.StyleColor.Button,        rgbm(0.7, 0.1, 0.1, 1))
		ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.9, 0.2, 0.2, 1))
	end
	if ui.button('⊙ Monitor##monitor_btn', vec2(u.getWindowWidth() - 16, 20)) then
		activeGraph = isMonOpen and 'none' or 'monitor'
	end
	if isMonOpen then ui.popStyleColor(2) end
	ui.offsetCursorY(4)

	u.header('FORCE FEEDBACK')
	u.cfgCheckbox('FFB Ativado', 'ffb_enabled')
	if cfg.ffb_enabled then
		ui.offsetCursorY(4)
		u.cfgSlider('FFB Gain', 'ffb_gain', 0.0, 10.0, '%.1f',
			'Intensidade da resistência do volante.\n0.0 = sem FFB | 0.8 = padrão | 10.0 = máximo')
		u.hint('Intensidade da resistência do volante.')
		u.cfgSlider('Gyro Gain', 'gyro_gain', 0.0, 10.0, '%.1f',
			'Influência da rotação do carro no volante.\n0.0 = desativado | 4.0 = padrão | 10.0 = máximo')
		u.hint('Influência da rotação do carro no volante.')
		u.cfgSlider('Steer Align', 'steer_counter_steer', 0.0, 10.0, '%.1f',
			'Contra-esterço automático do volante.\n0.0 = desativado | 10.0 = máximo')
		u.hint('Contra-esterço do volante.')
		u.cfgSlider('FFB Damper', 'ffb_damper', 0.0, 10.0, '%.1f',
			'Amortece oscilações bruscas do volante.\n0.0 = sem amortecimento | 1.7 = padrão | 10.0 = máximo')
		u.hint('Amortece oscilações bruscas do volante.')
		u.cfgSlider('FFB Lateral', 'ffb_lateral', 0.0, 10.0, '%.1f',
			'Força G lateral nas curvas.\n0.0 = desativado | 1.5 = padrão | 10.0 = intenso')
		u.hint('Força lateral nas curvas.')
		gammaSlider('FFB Gamma', 'ffb_gamma',
			'Curva de resposta do FFB.\n5.0 = linear | >5.0 = suave no centro | <5.0 = agressivo')
		u.hint('Curva de resposta do FFB.')
	else
		ui.offsetCursorY(4)
		u.info('FFB desativado — volante controlado apenas pelo mouse.')
	end

	u.header('SENSIBILIDADE')
	u.cfgSlider('Steer Sensi', 'steer_sensi', 1.0, 10.0, '%.1f',
		'Velocidade de resposta do volante ao mouse.\n1.0 = lento | 4.5 = padrão | 10.0 = máximo')
	u.hint('Velocidade de resposta do volante ao mouse.')

	u.header('LIMITE DE ESTERÇO')
	u.cfgSlider('Steer Limit', 'steer_limit', 0.0, 10.0, '%.1f',
		'Limita a rotação máxima do volante.\n10.0 = 900° | 5.0 = 450° | 3.0 = 270°')
	local deg = math.floor(cfg.steer_limit * 90 + 0.5)
	u.hint('Rotação máxima: '..deg..'°')

	u.header('CURVA DE RESPOSTA')
	gammaSlider('Steer Gamma', 'steer_gamma',
		'5.0 = linear | >5.0 = suave no centro | <5.0 = agressivo no centro')

	u.header('SUAVIZAÇÃO')
	u.cfgSlider('Steer Filter', 'steer_filter', 0.0, 10.0, '%.1f',
		'0.0 = sem filtro | 6.0 = moderado | 8.0+ = lento')

	u.header('SENSIBILIDADE POR VELOCIDADE')
	u.cfgSlider('Steer Speed Scale', 'speed_sensi', 0.0, 10.0, '%.1f',
		'Reduz sensibilidade em alta velocidade.\n10.0 = sem redução | 0.0 = mínimo')
	if cfg.speed_sensi < 10.0 then
		ui.offsetCursorY(4)
		u.cfgSlider('Vel. início', 'speed_sensi_start', 20.0, 200.0, '%.0f km/h',
			'Velocidade onde a redução começa.')
		u.cfgSlider('Vel. máxima', 'speed_sensi_end', 100.0, 350.0, '%.0f km/h',
			'Velocidade onde a redução atinge o mínimo.')
	end
end

return M