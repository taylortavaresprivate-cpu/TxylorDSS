-- ========================================================================
-- DSS PEDALS MODULE
-- ========================================================================
-- Função approach() + lógica de gas, brake e handbrake
-- ========================================================================

local cfg = require "dss_config"

-- DEBUG: Log ao carregar o módulo
ac.log('[DSS PEDALS] Módulo carregado!')
ac.log('[DSS PEDALS] SCROLL_GAS_ENABLED: ' .. tostring(cfg.SCROLL_GAS_ENABLED))

local pedals = {}

pedals.gasValue       = 0
pedals.brakeValue     = 0
pedals.handbrakeValue = 0

-- [SCROLL GAS] Estado interno
local scrollGasValue = 0.0

function pedals.approach(current, target, speed, dt)
	if current < target then
		return math.min(current + speed * dt, target)
	else
		return math.max(current - speed * dt, target)
	end
end

function pedals.updateGas(dt, gasTarget)
	-- ── SCROLL GAS: processa input do scroll ────────────────────────
	if cfg.SCROLL_GAS_ENABLED then
		-- Tentar capturar o mouseWheel
		local mouseWheelValue = 0
		if ui and ui.mouseWheel then
			mouseWheelValue = ui.mouseWheel()
			if mouseWheelValue ~= 0 then
				ac.log('[SCROLL GAS] mouseWheel: ' .. tostring(mouseWheelValue))
			end
		end
		
		-- Detecta scroll up/down e ajusta o valor
		if mouseWheelValue > 0 then
			-- Scroll Up = adicionar gás
			scrollGasValue = math.min(scrollGasValue + cfg.SCROLL_GAS_STEP, 1.0)
			ac.log('[SCROLL GAS] UP - scrollGasValue: ' .. tostring(scrollGasValue))
		elseif mouseWheelValue < 0 then
			-- Scroll Down = remover gás
			scrollGasValue = math.max(scrollGasValue - cfg.SCROLL_GAS_STEP, 0.0)
			ac.log('[SCROLL GAS] DOWN - scrollGasValue: ' .. tostring(scrollGasValue))
		end
		
		-- Aplicar decay (decaimento gradual)
		if cfg.SCROLL_GAS_DECAY > 0 and scrollGasValue > 0 then
			scrollGasValue = math.max(scrollGasValue - cfg.SCROLL_GAS_DECAY * dt, 0.0)
		end
		
		-- Reset ao frear (se habilitado)
		if cfg.SCROLL_GAS_RESET_ON_BRAKE and pedals.brakeValue > 0.1 then
			scrollGasValue = 0.0
		end
		
		-- Combinar scroll gas com o target do botão
		-- Botão do mouse = prioridade (vai direto para 100%)
		gasTarget = math.max(gasTarget, scrollGasValue)
	end
	
	local speed = gasTarget > pedals.gasValue and cfg.GAS_PRESS_SPEED or cfg.GAS_RELEASE_SPEED
	pedals.gasValue = pedals.approach(pedals.gasValue, gasTarget, speed, dt)
	return pedals.gasValue
end

function pedals.updateBrake(dt, brakeTarget)
	local speed = brakeTarget > pedals.brakeValue and cfg.BRAKE_PRESS_SPEED or cfg.BRAKE_RELEASE_SPEED
	pedals.brakeValue = pedals.approach(pedals.brakeValue, brakeTarget, speed, dt)
	return pedals.brakeValue
end

function pedals.updateHandbrake(dt, handbrakeTarget)
	local speed = handbrakeTarget > pedals.handbrakeValue and cfg.HANDBRAKE_PRESS_SPEED or cfg.HANDBRAKE_RELEASE_SPEED
	pedals.handbrakeValue = pedals.approach(pedals.handbrakeValue, handbrakeTarget, speed, dt)
	return pedals.handbrakeValue
end

return pedals