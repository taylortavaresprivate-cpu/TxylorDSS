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

		-- ── NÍVEL ────────────────────────────────────────────────────────
		u.header('NÍVEL')
		local newAbsLevel = u.levelSelector('abs', cfg.abs_level, 20,
			data.ABS_LEVEL_NAMES, data.ABS_LEVEL_DATA, u.getColAccent())
		if newAbsLevel ~= cfg.abs_level then cfg.abs_level = newAbsLevel; data.dirty = true end
		if cfg.abs_level >= 1 and cfg.abs_level <= 20 then
			local l = data.ABS_LEVEL_DATA[cfg.abs_level]
			cfg.abs_threshold         = l[1]
			cfg.abs_min_brake         = l[2]
			cfg.abs_intensity         = l[3]
			cfg.abs_smooth            = l[4]
			cfg.abs_rear_bias         = l[5]
			cfg.abs_trail_brake       = l[6]
			cfg.abs_trail_brake_start = l[7]
			cfg.abs_brake_recovery    = l[8]
			cfg.abs_curve_factor      = l[9]
		end

		-- ── SENSIBILIDADE ─────────────────────────────────────────────────
		u.header('SENSIBILIDADE')
		u.cfgSliderInt('Threshold', 'abs_threshold', 1, 100,
			'Quando o ABS começa a agir.\n1 = muito sensível (ativa com pouco deslizamento).\n100 = muito tolerante (só age com deslizamento extremo).')
		u.cfgSlider('Vel. mínima', 'abs_min_speed', 0.0, 100.0, '%.0f km/h',
			'ABS inativo abaixo desta velocidade.')

		-- ── INTENSIDADE ───────────────────────────────────────────────────
		u.header('INTENSIDADE')
		u.cfgSliderInt('Freio mínimo', 'abs_min_brake', 0, 100,
			'O máximo que o ABS pode cortar o freio.\n0 = pode cortar tudo.\n100 = nunca corta mais que 10% do freio.')
		u.cfgSlider('Intensidade', 'abs_intensity', 0.01, 1.0, '%.2f',
			'Proporção de corte por excesso de deslizamento.\nMaior = corte mais forte ao travar.')

		-- ── SUAVIZAÇÃO ────────────────────────────────────────────────────
		u.header('SUAVIZAÇÃO')
		u.cfgSlider('Smooth', 'abs_smooth', 0.3, 10.0, '%.1f',
			'Velocidade de transição do ABS.\nMaior = reage mais rápido.')

		-- ── COMPORTAMENTO EM CURVA ────────────────────────────────────────
		u.header('COMPORTAMENTO EM CURVA')
		u.cfgSliderInt('Fator de Curva', 'abs_curve_factor', 0, 10,
			'Relaxa o Threshold e a Intensidade do ABS em curvas.\n0 = ABS igual em reta e curva.\n10 = ABS muito mais tolerante em curvas.')
		if cfg.abs_curve_factor > 0 then
			ui.offsetCursorY(4)
			-- garante inteiro antes de formatar com %d
			local tBase  = math.floor(cfg.abs_threshold + 0.5)
			local factor = cfg.abs_curve_factor / 10.0
			ui.pushStyleColor(ui.StyleColor.Text, u.colYellow)
			ui.text(string.format('  Reta:       Threshold %d', tBase))
			ui.text(string.format('  Curva 50%%:  Threshold %d', math.floor(tBase * (1.0 + 0.5 * factor * 2.0) + 0.5)))
			ui.text(string.format('  Curva 100%%: Threshold %d', math.floor(tBase * (1.0 + 1.0 * factor * 2.0) + 0.5)))
			ui.popStyleColor()
		end

		-- ── ESTABILIDADE ──────────────────────────────────────────────────
		u.header('ESTABILIDADE')
		u.cfgSliderInt('Rear Bias', 'abs_rear_bias', 0, 10,
			'Quanto a traseira influencia o corte do ABS.\n0 = frente e trás valem igual.\n10 = traseira manda no corte.')

		-- ── TRAIL BRAKE ───────────────────────────────────────────────────
		u.header('TRAIL BRAKE')
		u.cfgSliderInt('Trail Brake', 'abs_trail_brake', 0, 10,
			'Reduz o freio automaticamente ao virar.\n0 = desligado.\n10 = redução forte.\nPermite simular trail braking.')
		if cfg.abs_trail_brake > 0 then
			u.cfgSliderInt('Início do Trail Brake', 'abs_trail_brake_start', 0, 10,
				'Quanto de esterçamento aciona o Trail Brake.\n0 = age desde o início da curva.\n10 = só em curvas muito fechadas.')
		end

		-- ── RECUPERAÇÃO ───────────────────────────────────────────────────
		u.header('RECUPERAÇÃO')
		u.cfgSliderInt('Brake Recovery', 'abs_brake_recovery', 0, 10,
			'Velocidade que o freio volta ao normal após o ABS cortar.\n0 = recuperação suave e lenta.\n10 = recuperação rápida e direta.')

		-- ── AVANÇADO ──────────────────────────────────────────────────────
		u.header('AVANÇADO')
		u.cfgSlider('Divisor ndSlip', 'abs_ndslip_div', 1.0, 5.0, '%.1f',
			'Calibração do sensor de deslizamento.\nAumente se o ABS age o tempo todo.\nDiminua se as rodas travam mesmo com ABS. (padrão: 2.6)')
	else
		ui.offsetCursorY(8); u.hint('ABS desativado.')
	end
end

return M