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
			cfg.abs_trail_brake=l[5]; cfg.abs_trail_brake_start=l[6]
			cfg.abs_brake_recovery=l[7]; cfg.abs_rear_bias=l[8]
		end

		u.header('SENSIBILIDADE')
		u.cfgSliderInt('Threshold', 'abs_threshold', 1, 100,
			'Quando o ABS começa a agir.\n1 = muito sensível (ativa com pouco deslizamento).\n100 = muito tolerante (só age com deslizamento extremo).')
		u.cfgSlider('Vel. mínima', 'abs_min_speed', 0.0, 50.0, '%.0f km/h',
			'ABS inativo abaixo desta velocidade.')

		u.header('INTENSIDADE')
		u.cfgSliderInt('Freio mínimo', 'abs_min_brake', 0, 100,
			'O máximo que o ABS pode cortar o freio.\n0 = pode cortar tudo.\n100 = nunca corta mais que 10% do freio.')
		u.cfgSliderInt('Intensidade', 'abs_intensity', 1, 100,
			'Proporção de corte por excesso de deslizamento.\nMaior = corte mais forte ao travar.')

		u.header('SUAVIZAÇÃO')
		u.cfgSliderInt('Smooth', 'abs_smooth', 1, 100,
			'Velocidade de transição do ABS.\nMaior = reage mais rápido.')

		u.header('COMPORTAMENTO EM CURVA')
		u.cfgSliderInt('Fator de Curva', 'abs_curve_factor', 0, 20,
			'Relaxa o Threshold do ABS em curvas.\n0 = ABS igual em reta e curva.\n20 = ABS muito mais tolerante em curvas.')
		if cfg.abs_curve_factor > 0 then
			ui.offsetCursorY(4)
			local tBase  = math.floor(cfg.abs_threshold + 0.5)
			local factor = cfg.abs_curve_factor / 10.0
			ui.pushStyleColor(ui.StyleColor.Text, u.colYellow)
			ui.text(string.format('  Reta:       Threshold %d', tBase))
			ui.text(string.format('  Curva 50%%:  Threshold %d', math.floor(tBase * (1.0 + 0.5 * factor * 2.0) + 0.5)))
			ui.text(string.format('  Curva 100%%: Threshold %d', math.floor(tBase * (1.0 + 1.0 * factor * 2.0) + 0.5)))
			ui.popStyleColor()
		end

		-- ── TRAIL BRAKE ───────────────────────────────────────────────────
		u.header('TRAIL BRAKE')
		u.cfgSliderInt('Trail Brake', 'abs_trail_brake', 0, 10,
			'Reduz o freio automaticamente ao virar.\n0 = desligado.\n10 = redução forte.')
		if cfg.abs_trail_brake > 0 then
			u.cfgSliderInt('Início do Trail Brake', 'abs_trail_brake_start', 0, 10,
				'Quanto de esterçamento aciona o Trail Brake.\n0 = age desde o início da curva.\n10 = só em curvas muito fechadas.')
		end

		-- ── ESTABILIDADE ──────────────────────────────────────────────────
		u.header('ESTABILIDADE')
		u.cfgSliderInt('Rear Bias', 'abs_rear_bias', 0, 10,
			'Quanto a traseira influencia o corte do ABS.\n0 = frente e trás valem igual (math.min).\n10 = traseira manda no corte.')

		-- ── RECUPERAÇÃO ───────────────────────────────────────────────────
		u.header('RECUPERAÇÃO')
		u.cfgSliderInt('Brake Recovery', 'abs_brake_recovery', 0, 100,
			'Velocidade que o freio volta ao normal após o ABS cortar.\n0 = usa o valor do Smooth (padrão antigo).\n>0 = recuperação independente.')

		-- ── AVANÇADO ──────────────────────────────────────────────────────
		u.header('AVANÇADO')
		u.cfgSlider('Divisor ndSlip', 'abs_ndslip_div', 1.0, 5.0, '%.1f',
			'Calibração do sensor de deslizamento.\nAumente se o ABS age o tempo todo.\nDiminua se as rodas travam mesmo com ABS. (padrão: 2.6)')
	else
		ui.offsetCursorY(8); u.hint('ABS desativado.')
	end
end

return M
