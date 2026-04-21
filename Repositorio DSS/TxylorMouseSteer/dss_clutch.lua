-- ========================================================================
-- DSS CLUTCH MODULE
-- ========================================================================
-- Embreagem manual, AutoClutch e Anti-Stall v3
-- ========================================================================
-- Prioridade (de cima pra baixo):
--   1. MANUAL (tecla configurável em KEYBINDS, padrão: C)
--   2. AUTOCLUTCH     — troca de marcha, tem prioridade sobre anti-stall
--   3. ANTI-STALL     — controle contínuo por velocidade+throttle
--   4. IDLE           — fallback quando anti-stall está desligado
-- ========================================================================

local cfg    = require "dss_config"
local pedals = require "dss_pedals"

local clutch = {}

local clutchValue       = nil
local clutchInitialized = false
local forceInitToggle   = false

local prevGear = -999
local acState  = 0

local antistallClutch   = 0.0
local antistallSmoothed = 0.0

-- Snap instantâneo se speed >= 10.0 (para embreagem manual)
local function approachClutchManual(current, target, speed, dt)
	if speed >= 10.0 then return target end
	return pedals.approach(current, target, speed, dt)
end

function clutch.update(dt, data, manualPressed, currentGear, currentGas)

	if not clutchInitialized then
		clutchValue       = data.clutch
		antistallClutch   = data.clutch
		antistallSmoothed = data.clutch
		clutchInitialized = true
		forceInitToggle   = true
	end

	if forceInitToggle then
		local originalAntistall  = cfg.ANTISTALL_ENABLED
		local originalAutoclutch = cfg.AUTOCLUTCH_ENABLED
		cfg.ANTISTALL_ENABLED  = true
		cfg.AUTOCLUTCH_ENABLED = true

		local speed = math.abs(car.speedKmh)
		local speedRange = cfg.ANTISTALL_FULL_SPEED - cfg.ANTISTALL_MIN_SPEED
		local tSpeed = 0.0
		if speedRange > 0 then
			tSpeed = math.max(0, math.min((speed - cfg.ANTISTALL_MIN_SPEED) / speedRange, 1.0))
		end
		local speedTarget    = math.pow(tSpeed, cfg.ANTISTALL_GAMMA)
		local throttleTarget = currentGas * cfg.ANTISTALL_BITE_POINT
		local rawTarget      = speedTarget + throttleTarget * (1.0 - speedTarget)
		local minClutch      = 1.0 - cfg.ANTISTALL_MAX_PRESS
		rawTarget = math.max(rawTarget, minClutch)
		rawTarget = math.min(rawTarget, 1.0)

		antistallSmoothed = rawTarget
		antistallClutch   = rawTarget
		clutchValue       = rawTarget

		cfg.ANTISTALL_ENABLED  = originalAntistall
		cfg.AUTOCLUTCH_ENABLED = originalAutoclutch
		forceInitToggle = false
	end

	-- ── 1. MANUAL: prioridade máxima ─────────────────────────────────
	if manualPressed then
		acState = 0
		-- Limite: clutch_max = 80% → valor AC mínimo = 1.0 - 0.80 = 0.20
		local pressFloor = 1.0 - (cfg.CLUTCH_MAX / 100.0)
		clutchValue       = math.max(
			approachClutchManual(clutchValue, 0.0, cfg.CLUTCH_PRESS_SPEED, dt),
			pressFloor
		)
		antistallClutch   = clutchValue
		antistallSmoothed = clutchValue
		prevGear          = currentGear
		return clutchValue
	end

	-- ── 2. ANTI-STALL ────────────────────────────────────────────────
	if cfg.ANTISTALL_ENABLED then
		local speed = math.abs(car.speedKmh)
		local speedRange = cfg.ANTISTALL_FULL_SPEED - cfg.ANTISTALL_MIN_SPEED
		local tSpeed = 0.0
		if speedRange > 0 then
			tSpeed = math.max(0, math.min((speed - cfg.ANTISTALL_MIN_SPEED) / speedRange, 1.0))
		end
		local speedTarget    = math.pow(tSpeed, cfg.ANTISTALL_GAMMA)
		local throttleTarget = currentGas * cfg.ANTISTALL_BITE_POINT
		local rawTarget      = speedTarget + throttleTarget * (1.0 - speedTarget)
		local minClutch      = 1.0 - cfg.ANTISTALL_MAX_PRESS
		rawTarget = math.max(rawTarget, minClutch)
		rawTarget = math.min(rawTarget, 1.0)

		local smoothFactor = math.pow(cfg.ANTISTALL_TARGET_SMOOTH, dt * 60)
		antistallSmoothed = antistallSmoothed * smoothFactor
		                  + rawTarget         * (1.0 - smoothFactor)

		local transitionSpeed = antistallSmoothed > antistallClutch
			and cfg.ANTISTALL_ENGAGE_SPEED
			or  cfg.ANTISTALL_DISENGAGE_SPEED
		antistallClutch = pedals.approach(antistallClutch, antistallSmoothed, transitionSpeed, dt)
	else
		antistallClutch   = 1.0
		antistallSmoothed = 1.0
	end

	-- ── 3. AUTOCLUTCH ────────────────────────────────────────────────
	if cfg.AUTOCLUTCH_ENABLED and currentGear ~= prevGear and prevGear ~= -999 then
		if clutchValue > 0.3 then acState = 1 end
	end

	-- ── 4. APLICAR clutchValue ───────────────────────────────────────
	if acState == 1 then
		local depthTarget = 1.0 - cfg.AUTOCLUTCH_DEPTH
		clutchValue = pedals.approach(clutchValue, depthTarget, cfg.AUTOCLUTCH_PRESS_SPEED, dt)
		if clutchValue <= depthTarget + 0.02 then acState = 2 end

	elseif acState == 2 then
		local releaseTarget = cfg.ANTISTALL_ENABLED and antistallClutch or 1.0
		clutchValue = pedals.approach(clutchValue, releaseTarget, cfg.AUTOCLUTCH_RELEASE_SPEED, dt)
		if clutchValue >= releaseTarget - 0.02 then acState = 0 end

	else
		if cfg.ANTISTALL_ENABLED then
			clutchValue = antistallClutch
		else
			clutchValue = approachClutchManual(clutchValue, 1.0, cfg.CLUTCH_RELEASE_SPEED, dt)
		end
	end

	prevGear = currentGear
	return clutchValue
end

return clutch