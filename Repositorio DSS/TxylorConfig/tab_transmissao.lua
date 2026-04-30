-- ======================================================================== 
-- DSS TAB: TRANSMISSÃO 
-- ======================================================================== 

local data = require "cfg_data" 
local cfg  = data.cfg 
local u    = require "cfg_ui" 

local M = {} 
local showBlipAdvanced = false 

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
		u.cfgSlider('Vel. pressionar', 'autoclutch_press_speed', 1.0, 10.0, '%.1f', 
			'Rapidez ao pisar embreagem.') 
		u.cfgSlider('Vel. soltar', 'autoclutch_release_speed', 1.0, 10.0, '%.1f', 
			'Rapidez ao soltar embreagem.') 
	else 
		ui.offsetCursorY(4) 
		u.hint('Auto-Clutch desativado.') 
	end 

	u.header('ANTI-STALL') 
	u.cfgCheckbox('Anti-Stall', 'antistall_enabled') 
	if cfg.antistall_enabled then 
		ui.offsetCursorY(4) 
		u.hint('Gerencia a embreagem usando velocidade das rodas + acelerador + RPM.') 
		ui.offsetCursorY(4) 

		-- RPM Idle (mostrar valor detectado) 
		local idleRPM = ac.load("dss_idle_rpm") or 0 
		if idleRPM > 0 then 
			ui.text(string.format('RPM Idle detectado: %.0f', idleRPM)) 
			ui.offsetCursorY(2) 
		else 
			ui.text('RPM Idle: detectando...') 
			ui.offsetCursorY(2) 
		end 

		-- Margem RPM 
		ui.setNextItemWidth(u.getSliderWidth()) 
		local newMargin = ui.slider('##antistall_rpm_margin', 
			cfg.antistall_rpm_margin * 100, 5, 50, 'Margem RPM:  %.0f%%') 
		if ui.itemEdited() then cfg.antistall_rpm_margin = newMargin / 100.0; data.dirty = true end 
		if cfg.antistall_rpm_margin ~= data.defaults.antistall_rpm_margin then 
			ui.sameLine(0,4) 
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor() 
		end 
		ui.sameLine(0,4) 
		ui.pushStyleColor(ui.StyleColor.Text, u.getColAccent()); ui.text('?'); ui.popStyleColor() 
		if ui.itemHovered() then ui.setTooltip('Quanto abaixo do RPM idle o sistema aciona a embreagem.\n15%% = padrão | 30%% = mais conservador') end 
		ui.offsetCursorY(4) 

		u.cfgSlider('Vel. engate total', 'antistall_full_speed', 5.0, 100.0, '%.0f km/h',
			'Acima disso, embreagem 100%% solta.')
		u.cfgSlider('Vel. mínima', 'antistall_min_speed', 0.0, 10.0, '%.1f km/h', 
			'Abaixo disso (sem gás), embreagem pisada.') 
		ui.offsetCursorY(4) 
		ui.setNextItemWidth(u.getSliderWidth()) 
		local newBite = ui.slider('##antistall_bite_point',
			cfg.antistall_bite_point * 100, 10, 100, 'Bite Point:  %.0f%%')
		if ui.itemEdited() then cfg.antistall_bite_point = newBite / 100.0; data.dirty = true end 
		if cfg.antistall_bite_point ~= data.defaults.antistall_bite_point then 
			ui.sameLine(0,4) 
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor() 
		end 
		ui.sameLine(0,4) 
		ui.pushStyleColor(ui.StyleColor.Text, u.getColAccent()); ui.text('?'); ui.popStyleColor() 
		if ui.itemHovered() then ui.setTooltip('Quanto a embreagem solta ao acelerar parado.\n50%% = suave | 70%% = agressivo') end 
		ui.offsetCursorY(4) 
		u.cfgSlider('Vel. engatar', 'antistall_engage_speed', 1.0, 10.0, '%.1f',
			'Rapidez ao soltar embreagem.')
		u.cfgSlider('Vel. desengatar', 'antistall_disengage_speed', 1.0, 10.0, '%.1f',
			'Rapidez ao pisar embreagem.')
		u.cfgSlider('Vel. proteção reversa', 'antistall_reverse_speed', 1.0, 10.0, '%.1f',
			'Rapidez ao pisar embreagem quando marcha e direção são opostas.')
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
		
		-- Seletor de modo: Automático vs Manual 
		ui.text('Modo:') 
		local autoActive = cfg.blip_mode == 0 
		local manualActive = cfg.blip_mode == 1 
		
		ui.sameLine(50) 
		if autoActive then 
			ui.pushStyleColor(ui.StyleColor.Button, rgb(0.15, 0.55, 0.15)) 
		end 
		if ui.button('Automático', vec2(110, 24)) then 
			cfg.blip_mode = 0; data.dirty = true 
		end 
		if autoActive then ui.popStyleColor() end 
		
		ui.sameLine(0, 4) 
		if manualActive then 
			ui.pushStyleColor(ui.StyleColor.Button, rgb(0.15, 0.55, 0.15)) 
		end 
		if ui.button('Manual', vec2(80, 24)) then 
			cfg.blip_mode = 1; data.dirty = true 
		end 
		if manualActive then ui.popStyleColor() end 
		
		if cfg.blip_mode ~= data.defaults.blip_mode then 
			ui.sameLine(0,4) 
			ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('●'); ui.popStyleColor() 
		end 
		ui.offsetCursorY(4) 
		
		if cfg.blip_mode == 0 then 
			u.hint('Usa gear ratio real do carro. TPS, duração e curva automáticos.') 
		else 
			u.hint('Fórmula linear fixa. Ajuste manual necessário.') 
		end 
		ui.offsetCursorY(4) 
		
		-- RPM mínimo absoluto (compartilhado entre modos)
		local idleRPM = math.max(ac.load("dss_idle_rpm") or 500, 500)
		local ok, limiter = pcall(function() return car.rpmLimiter end)
		local maxRPM = (ok and limiter and limiter > 0) and limiter or 9000
		u.cfgSlider('RPM mínimo', 'blip_min_rpm', idleRPM, maxRPM, '%.0f RPM',
			'Blip só ativa quando o motor está acima deste RPM.')

		-- Modo Manual: todos os ajustes editáveis (valores inteiros)
		if cfg.blip_mode == 1 then
			u.cfgSlider('Intensidade', 'blip_intensity', 1, 10, '%.0f',
				'Multiplicador geral do throttle do blip.')
			u.cfgSlider('Duração', 'blip_duration', 50, 500, '%.0f ms',
				'Tempo fixo do blip no modo manual.')
			u.cfgSlider('Sensibilidade', 'blip_sensitivity', 1, 100, '%.0f',
				'Divisor do erro de RPM. Menor = blip mais agressivo.')
				'Diferença mínima de RPM para ativar o blip.') 
			
			-- Ajustes Avançados (colapsáveis) 
			ui.offsetCursorY(4) 
			local advLabel = showBlipAdvanced and '▼ Ocultar Avançados' or '▶ Ajustes Avançados' 
			if ui.button(advLabel, vec2(180, 24)) then 
				showBlipAdvanced = not showBlipAdvanced 
			end 
			ui.offsetCursorY(4) 
			
			if showBlipAdvanced then 
			u.cfgSlider('Vel. subida', 'blip_attack_speed', 1.0, 10.0, '%.1f', 
				'Rapidez da subida do throttle. Alto = pico instantâneo.') 
			u.cfgSlider('Vel. descida', 'blip_release_speed', 1.0, 10.0, '%.1f', 
				'Rapidez da descida do throttle. Baixo = cauda suave.') 
			end 
		end 
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

		-- Duração fixa (mostrada apenas quando adaptativa está off)
		if not cfg.nls_adaptive_duration then
			u.cfgSlider('Duração', 'nls_cut_duration', 50, 500, '%.0f ms',
				'Tempo de corte do throttle (modo fixo).')
			ui.offsetCursorY(4)
		end

		-- Teto mínimo
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
		ui.offsetCursorY(4)

		-- RPM mínimo
		u.cfgSlider('RPM mínimo', 'nls_min_rpm', 1000, 9000, '%.0f RPM',
			'Não ativa NLS abaixo deste RPM.')

		-- Release mult
		u.cfgSlider('Vel. transição', 'nls_release_mult', 1.0, 10.0, '%.1f',
			'Multiplicador da velocidade de corte/recuperação.')

		-- Duração adaptativa
		u.cfgCheckbox('Duração Adaptativa', 'nls_adaptive_duration')
		if cfg.nls_adaptive_duration then
			ui.offsetCursorY(2)
			u.hint('Duração ajusta automaticamente pelo gear ratio.')
		end
	else
		ui.offsetCursorY(4)
		u.hint('No-Lift Shift desativado.')
	end
end 

return M 
