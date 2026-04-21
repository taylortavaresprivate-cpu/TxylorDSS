-- ========================================================================
-- DSS TAB: TRANSMISSÃO
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local u    = require "cfg_ui"

local M = {}

function M.draw()
	u.header('AUTO-CLUTCH')
	u.cfgCheckbox('Auto-Clutch', 'autoclutch_enabled')
	if cfg.autoclutch_enabled then
		ui.offsetCursorY(4)
		u.hint('Embreagem automática ao trocar de marcha.')
		ui.offsetCursorY(4)
		ui.setNextItemWidth(u.getSliderWidth())
		local newDepth = ui.slider('##autoclutch_depth',
			cfg.autoclutch_depth * 100, 0, 100, 'Profundidade:  %.0f%%')
		if ui.itemEdited() then cfg.autoclutch_depth = newDepth / 100.0; data.dirty = true end
		if cfg.autoclutch_depth ~= data.defaults.autoclutch_depth then
			ui.sameLine(0,4)
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
		ui.sameLine(0,4)
		ui.pushStyleColor(ui.StyleColor.Text, u.getColAccent()); ui.text('?'); ui.popStyleColor()
		if ui.itemHovered() then ui.setTooltip('0%% = sem pressionar | 100%% = embreagem totalmente pressionada') end
		ui.offsetCursorY(4)
		u.cfgSlider('Vel. pressionar', 'autoclutch_press_speed', 1.0, 20.0, '%.1f',
			'Rapidez ao pisar embreagem.')
		u.cfgSlider('Vel. soltar', 'autoclutch_release_speed', 1.0, 20.0, '%.1f',
			'Rapidez ao soltar embreagem.')
	else
		ui.offsetCursorY(4)
		u.hint('Auto-Clutch desativado.')
	end

	u.header('ANTI-STALL')
	u.cfgCheckbox('Anti-Stall', 'antistall_enabled')
	if cfg.antistall_enabled then
		ui.offsetCursorY(4)
		u.hint('Gerencia a embreagem usando velocidade + acelerador.')
		ui.offsetCursorY(4)
		u.cfgSlider('Vel. engate total', 'antistall_full_speed', 10.0, 80.0, '%.0f km/h',
			'Acima disso, embreagem 100%% solta.')
		u.cfgSlider('Vel. mínima', 'antistall_min_speed', 0.0, 10.0, '%.1f km/h',
			'Abaixo disso (sem gás), embreagem pisada.')
		ui.offsetCursorY(4)
		ui.setNextItemWidth(u.getSliderWidth())
		local newBite = ui.slider('##antistall_bite_point',
			cfg.antistall_bite_point * 100, 10, 90, 'Bite Point:  %.0f%%')
		if ui.itemEdited() then cfg.antistall_bite_point = newBite / 100.0; data.dirty = true end
		if cfg.antistall_bite_point ~= data.defaults.antistall_bite_point then
			ui.sameLine(0,4)
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
		ui.sameLine(0,4)
		ui.pushStyleColor(ui.StyleColor.Text, u.getColAccent()); ui.text('?'); ui.popStyleColor()
		if ui.itemHovered() then ui.setTooltip('Quanto a embreagem solta ao acelerar parado.\n50%% = suave | 70%% = agressivo') end
		ui.offsetCursorY(4)
		u.cfgSlider('Vel. engatar', 'antistall_engage_speed', 0.5, 15.0, '%.1f',
			'Rapidez ao soltar embreagem.')
		u.cfgSlider('Vel. desengatar', 'antistall_disengage_speed', 0.5, 15.0, '%.1f',
			'Rapidez ao pisar embreagem.')
		u.cfgSlider('Gamma', 'antistall_gamma', 0.3, 3.0, '%.2f',
			'1.0 = linear | >1.0 = segura mais em baixa vel.')
		u.cfgSlider('Suavização', 'antistall_target_smooth', 0.0, 0.99, '%.2f',
			'0.0 = reativo | 0.92 = suave')
		ui.offsetCursorY(4)
		ui.setNextItemWidth(u.getSliderWidth())
		local newPress = ui.slider('##antistall_max_press',
			cfg.antistall_max_press * 100, 0, 100, 'Prof. máx:  %.0f%%')
		if ui.itemEdited() then cfg.antistall_max_press = newPress / 100.0; data.dirty = true end
		if cfg.antistall_max_press ~= data.defaults.antistall_max_press then
			ui.sameLine(0,4)
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
	else
		ui.offsetCursorY(4)
		u.hint('Anti-Stall desativado.')
	end

	u.header('AUTO-BLIP')
	u.cfgCheckbox('Auto-Blip', 'blip_enabled')
	if cfg.blip_enabled then
		ui.offsetCursorY(4)
		u.hint('Acelera automaticamente ao reduzir marcha para RPM ideal.')
		ui.offsetCursorY(4)
		u.cfgSlider('Intensidade', 'blip_intensity', 0.5, 3.0, '%.2f',
			'Multiplicador do throttle calculado.')
		u.cfgSlider('Duração', 'blip_duration', 50, 500, '%.0f ms',
			'Tempo máximo do blip.')
		u.cfgSlider('RPM mínimo diff', 'blip_min_rpm_diff', 0, 2000, '%.0f RPM',
			'Diferença mínima de RPM para ativar.')
		u.cfgSlider('Vel. subida', 'blip_attack_speed', 1.0, 50.0, '%.1f',
			'Rapidez da subida do throttle. Alto = pico instantâneo.')
		u.cfgSlider('Vel. descida', 'blip_release_speed', 0.5, 30.0, '%.1f',
			'Rapidez da descida do throttle. Baixo = cauda suave.')
	else
		ui.offsetCursorY(4)
		u.hint('Auto-Blip desativado.')
	end

	u.header('NO-LIFT SHIFT')
	u.cfgCheckbox('No-Lift Shift', 'nls_enabled')
	if cfg.nls_enabled then
		ui.offsetCursorY(4)
		u.hint('Corta throttle suavemente ao passar marcha.')
		ui.offsetCursorY(4)
		u.cfgSlider('Duração', 'nls_cut_duration', 50, 500, '%.0f ms',
			'Tempo de corte do throttle.')
		ui.offsetCursorY(4)
		ui.setNextItemWidth(u.getSliderWidth())
		local newCutAmount = ui.slider('##nls_cut_amount',
			cfg.nls_cut_amount * 100, 0, 100, 'Teto mínimo:  %.0f%%')
		if ui.itemEdited() then cfg.nls_cut_amount = newCutAmount / 100.0; data.dirty = true end
		if cfg.nls_cut_amount ~= data.defaults.nls_cut_amount then
			ui.sameLine(0,4)
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor()
		end
		ui.sameLine(0,4)
		ui.pushStyleColor(ui.StyleColor.Text, u.getColAccent()); ui.text('?'); ui.popStyleColor()
		if ui.itemHovered() then ui.setTooltip('Quanto throttle manter durante o corte.\n0%% = corte total | 20%% = mantém 20%%') end
	else
		ui.offsetCursorY(4)
		u.hint('No-Lift Shift desativado.')
	end
end

return M