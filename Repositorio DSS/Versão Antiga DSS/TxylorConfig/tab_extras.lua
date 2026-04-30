-- ========================================================================
-- DSS TAB: EXTRAS
-- ========================================================================

local data     = require "cfg_data"
local cfg      = data.cfg
local defaults = data.defaults
local u        = require "cfg_ui"

local M = {}

function M.draw()
	-- Cruise Mode
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
		local newGasMin = ui.slider('##cruise_gas_min',
			cfg.cruise_gas_min * 100, 10, 100, 'Gás mínimo:  %.0f%%')
		if ui.itemEdited() then cfg.cruise_gas_min = newGasMin / 100.0; data.dirty = true end
		if cfg.cruise_gas_min ~= defaults.cruise_gas_min then
			ui.sameLine(0,4)
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
		ui.setNextItemWidth(u.getSliderWidth())
		local newBrkMin = ui.slider('##cruise_brake_min',
			cfg.cruise_brake_min * 100, 10, 100, 'Freio mínimo:  %.0f%%')
		if ui.itemEdited() then cfg.cruise_brake_min = newBrkMin / 100.0; data.dirty = true end
		if cfg.cruise_brake_min ~= defaults.cruise_brake_min then
			ui.sameLine(0,4)
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
	else
		ui.offsetCursorY(4); u.hint('Cruise Mode desativado.')
	end

	-- Launch Control
	u.header('LAUNCH CONTROL')
	u.cfgCheckbox('Launch Control', 'launch_enabled')
	if cfg.launch_enabled then
		ui.offsetCursorY(4)
		ui.setNextItemWidth(u.getSliderWidth())
		local newRpm = ui.slider('##launch_rpm', cfg.launch_rpm, 1000, 20000, 'RPM alvo:  %.0f')
		if ui.itemEdited() then
			cfg.launch_rpm = math.floor(newRpm / 100 + 0.5) * 100; data.dirty = true
		end
		if cfg.launch_rpm ~= defaults.launch_rpm then
			ui.sameLine(0,4)
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
		ui.sameLine(0,4)
		ui.pushStyleColor(ui.StyleColor.Text, u.getColAccent()); ui.text('?'); ui.popStyleColor()
		if ui.itemHovered() then ui.setTooltip('RPM onde o corte é ativado.') end
		ui.offsetCursorY(4)
		ui.setNextItemWidth(u.getSliderWidth())
		local newCut = ui.slider('##launch_cut_time', cfg.launch_cut_time, 130, 500, 'Tempo de corte:  %.0f ms')
		if ui.itemEdited() then
			cfg.launch_cut_time = math.floor(newCut + 0.5); data.dirty = true
		end
		if cfg.launch_cut_time ~= defaults.launch_cut_time then
			ui.sameLine(0,4)
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
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
