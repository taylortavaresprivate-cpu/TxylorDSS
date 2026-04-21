-- ========================================================================
-- DSS TAB: EXTRAS
-- ========================================================================

local data     = require "cfg_data"
local cfg      = data.cfg
local defaults = data.defaults
local u        = require "cfg_ui"

local M = {}

local SCROLL_MODE_NAMES = { [0]='Só Gás', [1]='Só Freio', [2]='Ambos' }

function M.draw()

	u.header('SCROLL GAS')
	u.cfgCheckbox('Scroll Gas', 'scroll_gas_enabled')

	if cfg.scroll_gas_enabled then
		ui.offsetCursorY(6)

		local mode = cfg.scroll_gas_mode
		local up   = cfg.scroll_gas_invert and '↓' or '↑'
		local down = cfg.scroll_gas_invert and '↑' or '↓'
		if mode == 0 then
			u.hint('Scroll '..up..' e '..down..' = gás')
		elseif mode == 1 then
			u.hint('Scroll '..up..' e '..down..' = freio')
		elseif cfg.scroll_gas_gradual then
			u.hint('Scroll '..up..' = +gás / '..down..' = +freio  (gradual)')
		else
			u.hint('Scroll '..up..' = gás   Scroll '..down..' = freio')
		end
		ui.offsetCursorY(6)

		-- Botões de modo
		ui.text('Modo:')
		ui.sameLine(0, 8)
		for i = 0, 2 do
			local isActive = (cfg.scroll_gas_mode == i)
			if isActive then
				ui.pushStyleColor(ui.StyleColor.Button,        rgbm(0.7, 0.1, 0.1, 1))
				ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.9, 0.2, 0.2, 1))
			end
			if ui.button(SCROLL_MODE_NAMES[i]..'##mode'..i, vec2(70, 0)) then
				cfg.scroll_gas_mode = i
				data.dirty = true
			end
			if isActive then ui.popStyleColor(2) end
			if i < 2 then ui.sameLine(0, 4) end
		end
		if cfg.scroll_gas_mode ~= defaults.scroll_gas_mode then
			ui.sameLine(0, 4)
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end

		-- ✅ Gradual — só aparece no modo Ambos
		if cfg.scroll_gas_mode == 2 then
			ui.offsetCursorY(4)
			u.cfgCheckbox('Gradual', 'scroll_gas_gradual')
			u.hint('O scroll atravessa o zero: 100%→90%→...→0→...→10% freio.')
		end

		ui.offsetCursorY(6)

		u.cfgSlider('Step', 'scroll_gas_step', 0.01, 0.5, '%.2f',
			'Quanto cada tick de scroll adiciona.\n0.05 = suave | 0.10 = padrão | 0.30 = agressivo')
		u.hint('Incremento por tick de scroll.')

		u.cfgSlider('Decay', 'scroll_gas_decay', 0.0, 2.0, '%.2f',
			'Decaimento por segundo em direção ao zero.\n0.0 = mantém | 0.5 = ~2s | 2.0 = rápido')
		u.hint('0.0 = mantém posição | >0 = volta ao neutro sozinho.')

		u.cfgSlider('Vel. máxima', 'scroll_gas_max_speed', 0.0, 300.0, '%.0f km/h',
			'Zera o scroll acima desta velocidade.\n0 = sem limite.')
		u.hint('0 km/h = sem limite de velocidade.')

		ui.offsetCursorY(4)
		if cfg.scroll_gas_mode ~= 1 then
			u.cfgCheckbox('Reset ao frear', 'scroll_gas_reset_on_brake')
			u.hint('Zera o gás do scroll ao pressionar o freio.')
		end
		u.cfgCheckbox('Inverter scroll', 'scroll_gas_invert')
		u.hint(cfg.scroll_gas_invert and 'Scroll ↑ = freio | ↓ = gás' or 'Scroll ↑ = gás | ↓ = freio')

		-- Preview visual
		ui.offsetCursorY(8)
		local scrollVal = ac.load('dss_scroll_gas_value') or 0
		local barW = u.getWindowWidth() - 32
		local cur  = ui.getCursor()

		if cfg.scroll_gas_mode == 0 then
			ui.drawRectFilled(cur, cur + vec2(barW, 10), rgbm(0.12, 0.12, 0.12, 1), 2)
			ui.drawRectFilled(cur, cur + vec2(barW * math.max(scrollVal, 0), 10), rgbm(0.2, 0.85, 0.2, 1), 1)
			ui.offsetCursorY(14)
			u.hint(string.format('Gás: %.0f%%', math.max(scrollVal, 0) * 100))

		elseif cfg.scroll_gas_mode == 1 then
			ui.drawRectFilled(cur, cur + vec2(barW, 10), rgbm(0.12, 0.12, 0.12, 1), 2)
			ui.drawRectFilled(cur, cur + vec2(barW * math.max(-scrollVal, 0), 10), rgbm(0.9, 0.15, 0.15, 1), 1)
			ui.offsetCursorY(14)
			u.hint(string.format('Freio: %.0f%%', math.max(-scrollVal, 0) * 100))

		else
			-- Ambos: barra bidirecional
			local cx = barW / 2
			ui.drawRectFilled(cur, cur + vec2(barW, 10), rgbm(0.12, 0.12, 0.12, 1), 2)
			ui.drawLine(cur + vec2(cx, 0), cur + vec2(cx, 10), rgbm(0.5, 0.5, 0.5, 1), 1)
			if scrollVal > 0 then
				ui.drawRectFilled(cur + vec2(cx, 1), cur + vec2(cx + scrollVal * cx, 9), rgbm(0.2, 0.85, 0.2, 1), 1)
				ui.offsetCursorY(14)
				u.hint(string.format('Gás: %.0f%%', scrollVal * 100))
			elseif scrollVal < 0 then
				ui.drawRectFilled(cur + vec2(cx + scrollVal * cx, 1), cur + vec2(cx, 9), rgbm(0.9, 0.15, 0.15, 1), 1)
				ui.offsetCursorY(14)
				u.hint(string.format('Freio: %.0f%%', -scrollVal * 100))
			else
				ui.offsetCursorY(14)
				u.hint('Neutro')
			end
		end
	else
		ui.offsetCursorY(4)
		u.hint('Scroll Gas desativado.')
	end

	-- ── CRUISE MODE ─────────────────────────────────────────
	u.header('MODO PASSEIO (CRUISE)')
	u.cfgCheckbox('Cruise Mode', 'cruise_enabled')
	if cfg.cruise_enabled then
		ui.offsetCursorY(4)
		u.hint('Suaviza acelerador e freio em baixa velocidade.')
		ui.offsetCursorY(4)
		u.cfgSlider('Vel. normal', 'cruise_full_speed', 10.0, 120.0, '%.0f km/h',
			'Acima disso, pedais voltam ao normal.')
		ui.offsetCursorY(4)
		ui.setNextItemWidth(u.getSliderWidth())
		local newGasMin = ui.slider('##cruise_gas_min', cfg.cruise_gas_min * 100, 10, 100, 'Gás mínimo:  %.0f%%')
		if ui.itemEdited() then cfg.cruise_gas_min = newGasMin / 100.0; data.dirty = true end
		if cfg.cruise_gas_min ~= defaults.cruise_gas_min then
			ui.sameLine(0, 4); ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
		ui.setNextItemWidth(u.getSliderWidth())
		local newBrkMin = ui.slider('##cruise_brake_min', cfg.cruise_brake_min * 100, 10, 100, 'Freio mínimo:  %.0f%%')
		if ui.itemEdited() then cfg.cruise_brake_min = newBrkMin / 100.0; data.dirty = true end
		if cfg.cruise_brake_min ~= defaults.cruise_brake_min then
			ui.sameLine(0, 4); ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
	else
		ui.offsetCursorY(4); u.hint('Cruise Mode desativado.')
	end

	-- ── LAUNCH CONTROL ──────────────────────────────────────
	u.header('LAUNCH CONTROL')
	u.cfgCheckbox('Launch Control', 'launch_enabled')
	if cfg.launch_enabled then
		ui.offsetCursorY(4)
		ui.setNextItemWidth(u.getSliderWidth())
		local newRpm = ui.slider('##launch_rpm', cfg.launch_rpm, 1000, 20000, 'RPM alvo:  %.0f')
		if ui.itemEdited() then cfg.launch_rpm = math.floor(newRpm / 100 + 0.5) * 100; data.dirty = true end
		if cfg.launch_rpm ~= defaults.launch_rpm then
			ui.sameLine(0, 4); ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
		ui.sameLine(0, 4)
		ui.pushStyleColor(ui.StyleColor.Text, u.getColAccent()); ui.text('?'); ui.popStyleColor()
		if ui.itemHovered() then ui.setTooltip('RPM onde o corte é ativado.') end
		ui.offsetCursorY(4)
		ui.setNextItemWidth(u.getSliderWidth())
		local newCut = ui.slider('##launch_cut_time', cfg.launch_cut_time, 130, 500, 'Tempo de corte:  %.0f ms')
		if ui.itemEdited() then cfg.launch_cut_time = math.floor(newCut + 0.5); data.dirty = true end
		if cfg.launch_cut_time ~= defaults.launch_cut_time then
			ui.sameLine(0, 4); ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
		ui.offsetCursorY(6)
		ui.pushStyleColor(ui.StyleColor.Text, u.colOrange)
		ui.text('  Pressione X para armar (carro parado).')
		ui.popStyleColor()
		u.hint('Desarma automaticamente ao arrancar (> 2 km/h).')
	else
		ui.offsetCursorY(4); u.hint('Launch Control desativado.')
	end
end

return M