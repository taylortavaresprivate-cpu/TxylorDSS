-- ========================================================================
-- DSS CLUTCH MODULE
-- ========================================================================
-- Embreagem manual, AutoClutch e Anti-Stall v3
-- ========================================================================
-- Prioridade (de cima pra baixo):
--   1. MANUAL (C)     — controle total, cancela tudo
--   2. AUTOCLUTCH     — troca de marcha, tem prioridade sobre anti-stall
--   3. ANTI-STALL     — controle contínuo por velocidade+throttle
--   4. IDLE           — fallback quando anti-stall está desligado
-- ========================================================================

local cfg    = require "dss_config"
local pedals = require "dss_pedals"

local clutch = {}

local clutchValue       = nil
local clutchInitialized = false
local forceInitToggle   = false  -- Flag para forçar toggle na inicialização

local prevGear = -999
local acState  = 0  -- 0=inativo, 1=autoclutch pressionando, 2=autoclutch soltando

-- [ANTI-STALL] Estado interno
local antistallClutch   = 0.0
local antistallSmoothed = 0.0

function clutch.update(dt, data, manualPressed, currentGear, currentGas)

	-- ── Inicialização no primeiro frame ───────────────────────────────
	if not clutchInitialized then
		clutchValue       = data.clutch
		antistallClutch   = data.clutch
		antistallSmoothed = data.clutch
		clutchInitialized = true
		
		-- Salvar estado original e preparar para toggle forçado
		forceInitToggle = true
	end

	-- ── Toggle forçado na inicialização (gambiarra que funciona) ────
	if forceInitToggle then
		-- Salvar estados originais
		local originalAntistall = cfg.ANTISTALL_ENABLED
		local originalAutoclutch = cfg.AUTOCLUTCH_ENABLED
		
		-- Forçar ambos ligados por 1 frame
		cfg.ANTISTALL_ENABLED = true
		cfg.AUTOCLUTCH_ENABLED = true
		
		-- Processar 1 frame com tudo ligado
		local speed = math.abs(car.speedKmh)
		local speedRange = cfg.ANTISTALL_FULL_SPEED - cfg.ANTISTALL_MIN_SPEED
		local tSpeed = 0.0
		if speedRange > 0 then
			tSpeed = math.max(0, math.min((speed - cfg.ANTISTALL_MIN_SPEED) / speedRange, 1.0))
		end
		local speedTarget = math.pow(tSpeed, cfg.ANTISTALL_GAMMA)
		local throttleTarget = currentGas * cfg.ANTISTALL_BITE_POINT
		local rawTarget = speedTarget + throttleTarget * (1.0 - speedTarget)
		local minClutch = 1.0 - cfg.ANTISTALL_MAX_PRESS
		rawTarget = math.max(rawTarget, minClutch)
		rawTarget = math.min(rawTarget, 1.0)
		
		antistallSmoothed = rawTarget
		antistallClutch = rawTarget
		clutchValue = rawTarget
		
		-- Restaurar estados originais
		cfg.ANTISTALL_ENABLED = originalAntistall
		cfg.AUTOCLUTCH_ENABLED = originalAutoclutch
		
		-- Desativar flag
		forceInitToggle = false
	end

	-- ── 1. MANUAL (C): prioridade máxima ─────────────────────────────
	if manualPressed then
		acState           = 0
		clutchValue       = pedals.approach(clutchValue, 0.0, cfg.CLUTCH_PRESS_SPEED, dt)
		antistallClutch   = clutchValue
		antistallSmoothed = clutchValue
		prevGear          = currentGear
		return clutchValue
	end

	-- ── 2. ANTI-STALL: calcula o target interno (incluindo neutro) ──────────────
	if cfg.ANTISTALL_ENABLED then
		local speed = math.abs(car.speedKmh)

		-- (A) Target baseado na VELOCIDADE
		local speedRange = cfg.ANTISTALL_FULL_SPEED - cfg.ANTISTALL_MIN_SPEED
		local tSpeed = 0.0
		if speedRange > 0 then
			tSpeed = math.max(0, math.min((speed - cfg.ANTISTALL_MIN_SPEED) / speedRange, 1.0))
		end
		local speedTarget = math.pow(tSpeed, cfg.ANTISTALL_GAMMA)

		-- (B) Target baseado no THROTTLE (bite point)
		local throttleTarget = currentGas * cfg.ANTISTALL_BITE_POINT

		-- (C) BLEND SUAVE
		local rawTarget = speedTarget + throttleTarget * (1.0 - speedTarget)

		-- Limitar pela profundidade máxima
		local minClutch = 1.0 - cfg.ANTISTALL_MAX_PRESS
		rawTarget = math.max(rawTarget, minClutch)
		rawTarget = math.min(rawTarget, 1.0)

		-- (D) SMOOTHING DO TARGET
		local smoothFactor = math.pow(cfg.ANTISTALL_TARGET_SMOOTH, dt * 60)
		antistallSmoothed = antistallSmoothed * smoothFactor
		                  + rawTarget         * (1.0 - smoothFactor)

		-- (E) Approach com velocidade adaptativa
		local transitionSpeed
		if antistallSmoothed > antistallClutch then
			transitionSpeed = cfg.ANTISTALL_ENGAGE_SPEED
		else
			transitionSpeed = cfg.ANTISTALL_DISENGAGE_SPEED
		end
		antistallClutch = pedals.approach(antistallClutch, antistallSmoothed, transitionSpeed, dt)
	else
		-- Anti-stall desativado: resetar variáveis internas para evitar bugs
		antistallClutch   = 1.0
		antistallSmoothed = 1.0
	end

	-- ── 3. AUTOCLUTCH: detecta troca de marcha ──────────────────────
	if cfg.AUTOCLUTCH_ENABLED and currentGear ~= prevGear and prevGear ~= -999 then
		if clutchValue > 0.3 then
			acState = 1
		end
	end

	-- ── 4. DEFINIR clutchValue baseado no estado ────────────────────
	if acState == 1 then
		-- AutoClutch: pressionando
		local depthTarget = 1.0 - cfg.AUTOCLUTCH_DEPTH
		clutchValue = pedals.approach(clutchValue, depthTarget, cfg.AUTOCLUTCH_PRESS_SPEED, dt)
		if clutchValue <= depthTarget + 0.02 then
			acState = 2
		end

	elseif acState == 2 then
		-- AutoClutch: soltando → volta para o target do anti-stall
		local releaseTarget = cfg.ANTISTALL_ENABLED and antistallClutch or 1.0
		clutchValue = pedals.approach(clutchValue, releaseTarget, cfg.AUTOCLUTCH_RELEASE_SPEED, dt)
		if clutchValue >= releaseTarget - 0.02 then
			acState = 0
		end

	else
		-- acState == 0: nenhum autoclutch ativo
		if cfg.ANTISTALL_ENABLED then
			clutchValue = antistallClutch
		else
			clutchValue = pedals.approach(clutchValue, 1.0, cfg.CLUTCH_RELEASE_SPEED, dt)
		end
	end

	prevGear = currentGear
	return clutchValue
end

return clutch