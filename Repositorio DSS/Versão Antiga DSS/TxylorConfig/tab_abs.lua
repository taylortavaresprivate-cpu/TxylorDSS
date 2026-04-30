-- ========================================================================
-- DSS TAB: ABS SYSTEM
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local u    = require "cfg_ui"

local M = {}

function M.draw()
	u.cfgCheckbox('ABS Ativado', 'abs_enabled')
	ui.offsetCursorY(4)
	if cfg.abs_enabled then
		u.header('NÍVEL')
		local newAbsLevel = u.levelSelector('abs', cfg.abs_level, 20,
			data.ABS_LEVEL_NAMES, data.ABS_LEVEL_DATA, u.getColAccent())
		if newAbsLevel ~= cfg.abs_level then cfg.abs_level = newAbsLevel; data.dirty = true end
		if cfg.abs_level >= 1 and cfg.abs_level <= 20 then
			local l = data.ABS_LEVEL_DATA[cfg.abs_level]
			cfg.abs_threshold=l[1]; cfg.abs_min_brake=l[2]
			cfg.abs_intensity=l[3]; cfg.abs_smooth=l[4]
		end

		u.header('SENSIBILIDADE')
		u.cfgSlider('Threshold', 'abs_threshold', 0.003, 0.150, '%.3f',
			'Menor = ABS atua com menos deslizamento.')
		u.cfgSlider('Vel. mínima', 'abs_min_speed', 0.0, 50.0, '%.0f km/h',
			'ABS inativo abaixo desta velocidade.')

		u.header('INTENSIDADE')
		u.cfgSlider('Freio mínimo', 'abs_min_brake', 0.0, 0.50, '%.2f',
			'Força mínima de frenagem preservada.')
		u.cfgSlider('Intensidade', 'abs_intensity', 0.01, 1.0, '%.2f',
			'Proporção de corte por excesso de deslizamento.')

		u.header('SUAVIZAÇÃO')
		u.cfgSlider('Smooth', 'abs_smooth', 0.3, 10.0, '%.1f',
			'Transição entre estados do ABS.')

		u.header('COMPORTAMENTO EM CURVA')
		u.cfgSlider('Fator de Curva', 'abs_curve_factor', 0.0, 2.0, '%.2f',
			'Ajusta threshold em curvas.')
		ui.offsetCursorY(4)
		ui.pushStyleColor(ui.StyleColor.Text, u.colYellow)
		local tBase = cfg.abs_threshold
		ui.text(string.format('  Reta: %.3f', tBase))
		ui.text(string.format('  Curva 50%%: %.3f', tBase*(1.0+0.5*cfg.abs_curve_factor)))
		ui.text(string.format('  Curva 100%%: %.3f', tBase*(1.0+1.0*cfg.abs_curve_factor)))
		ui.popStyleColor()

		u.header('AVANÇADO')
		u.cfgSlider('Divisor ndSlip', 'abs_ndslip_div', 1.0, 5.0, '%.1f',
			'Escala do sensor de deslizamento (padrão: 2.6).')
	else
		ui.offsetCursorY(8); u.hint('ABS desativado.')
	end
end

return M