-- ========================================================================
-- DSS TAB: TC SYSTEM
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local u    = require "cfg_ui"

local M = {}

function M.draw()
	u.cfgCheckbox('TC Ativado', 'tc_enabled')
	ui.offsetCursorY(4)
	if cfg.tc_enabled then
		ui.pushStyleColor(ui.StyleColor.Text, u.colGreen)
		ui.text('  Tração detectada automaticamente.')
		ui.popStyleColor(); ui.offsetCursorY(4)

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
		u.cfgSlider('Threshold', 'tc_threshold', 0.001, 0.200, '%.3f',
			'Menor = TC intervém com menos deslizamento.')
		u.cfgSlider('Vel. mínima', 'tc_min_speed', 0.0, 50.0, '%.0f km/h',
			'TC inativo abaixo desta velocidade.')

		u.header('INTENSIDADE')
		u.cfgSlider('Gás mínimo', 'tc_min_gas', 0.0, 0.99, '%.2f',
			'Aceleração mínima preservada.')
		u.cfgSlider('Intensidade', 'tc_intensity', 0.01, 1.0, '%.2f',
			'Proporção de corte por excesso de deslizamento.')

		u.header('SUAVIZAÇÃO')
		u.cfgSlider('Smooth', 'tc_smooth', 0.3, 10.0, '%.1f',
			'Transição entre estados do TC.')

		u.header('AVANÇADO')
		u.cfgSlider('Divisor ndSlip', 'tc_ndslip_div', 1.0, 5.0, '%.1f',
			'Escala do sensor (padrão: 2.4).')
	else
		ui.offsetCursorY(8); u.hint('TC desativado.')
	end
end

return M