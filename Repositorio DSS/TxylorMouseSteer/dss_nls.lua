-- ========================================================================
-- DSS NO-LIFT SHIFT MODULE
-- ========================================================================
-- Corta o throttle SUAVEMENTE ao trocar marcha para cima
-- ========================================================================

local cfg = require "dss_config"
local pedals = require "dss_pedals"

local nls = {}

-- Estado interno
local prevGear = -999
local nlsActive = false
local nlsStartTime = 0
local nlsCurrentThrottle = 0

function nls.update(dt, data, currentGear, currentGas)
	
	-- *** FIX: Verificar se está habilitado ANTES de tudo ***
	if not cfg.NLS_ENABLED then
		prevGear = currentGear
		nlsActive = false
		return currentGas
	end
	
	-- ── 1. DETECTAR TROCA DE MARCHA PARA CIMA ────────────────────────
	if currentGear > prevGear and prevGear > 0 and prevGear ~= -999 then
		-- Troca para cima detectada!
		
		-- Verificar RPM mínimo (evita ativar em RPM muito baixo)
		local shouldActivate = true
		if car.rpm < 3000 then  -- Hardcoded 3000 RPM (simplificado)
			shouldActivate = false
		end
		
		if shouldActivate then
			nlsActive = true
			nlsStartTime = os.preciseClock()
			nlsCurrentThrottle = currentGas
			ac.log('[NLS] Ativado! Marcha: ' .. tostring(prevGear) .. ' -> ' .. tostring(currentGear) .. 
			       ' | RPM: ' .. tostring(math.floor(car.rpm)) .. 
			       ' | TPS inicial: ' .. tostring(math.floor(currentGas * 100)) .. '%')
		end
	end
	
	prevGear = currentGear
	
	-- ── 2. PROCESSAR NO-LIFT SHIFT ATIVO ─────────────────────────────
	if nlsActive then
		local elapsedTime = (os.preciseClock() - nlsStartTime) * 1000  -- em ms
		
		-- Verificar se o tempo expirou
		if elapsedTime > cfg.NLS_CUT_DURATION then
			nlsActive = false
			ac.log('[NLS] Desativado! Tempo: ' .. tostring(math.floor(elapsedTime)) .. 'ms')
			return currentGas
		end
		
		-- Calcular target de throttle
		local targetThrottle = currentGas * cfg.NLS_CUT_AMOUNT
		
		-- Approach suave (2x mais r��pido que GAS_RELEASE_SPEED)
		local releaseSpeed = cfg.GAS_RELEASE_SPEED * 2.0
		nlsCurrentThrottle = pedals.approach(nlsCurrentThrottle, targetThrottle, releaseSpeed, dt)
		
		return nlsCurrentThrottle
	end
	
	return currentGas
end

return nls