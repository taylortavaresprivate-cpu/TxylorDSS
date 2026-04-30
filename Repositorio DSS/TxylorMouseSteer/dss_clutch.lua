-- ======================================================================== 
-- DSS CLUTCH MODULE
-- ======================================================================== 
-- Embreagem manual, AutoClutch e Anti-Stall v6
-- ======================================================================== 
-- Prioridade (de cima pra baixo):
--   1. MANUAL (tecla configurável em KEYBINDS, padrão: C)
--   2. REVERSE ROTATION — proteção contra marcha x direção opostas
--   3. AUTOCLUTCH     — troca de marcha, tem prioridade sobre anti-stall
--   4. ANTI-STALL     — controle contínuo por velocidade+throttle+RPM
--   5. IDLE           — fallback quando anti-stall está desligado
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

-- [AUTOCLUTCH] Timer para garantir tempo mínimo de pressão
local acPressTimer      = 0.0
local AC_MIN_PRESS_TIME = 0.05  -- 50ms mínimo mesmo com snap

-- [ANTI-STALL v6] Estado interno
local detectedIdleRPM     = nil
local rpmSamplingSum      = 0.0
local rpmSamplingCount    = 0
local rpmSamplingActive   = false
local rpmSamplingTimer    = 0.0
local rpmClutchEngaged    = false
local rpmClutchSmoothed   = 1.0
local rpmLockoutTimer     = 0.0

-- Proteção contra rotação reversa (marcha x direção opostas)
local reverseProtectionSmoothed = 1.0

-- Converte angularSpeed (rad/s) para km/h
local WHEEL_RADIUS = 0.33
local function angularToKmh(angularSpeed)
	return math.abs(angularSpeed) * WHEEL_RADIUS * 3.6
end

-- Obtém velocidade média de todas as rodas
local function getWheelSpeed()
	local sum = 0
	for i = 0, 3 do
		sum = sum + angularToKmh(car.wheels[i].angularSpeed)
	end
	return sum / 4
end

-- Calcula velocidade efetiva para o anti-stall
-- Sempre usa wheel speed, mas limita quando o carro está quase parado
-- para evitar que patinação extrema solte a embreagem totalmente
local function getEffectiveSpeed()
	local carSpeed = math.abs(car.speedKmh)
	local wheelSpeed = getWheelSpeed()

	-- Quando o carro está praticamente parado, limita wheel speed
	-- para não deixar a embreagem ir totalmente solta só por patinação
	if carSpeed < 3.0 then
		wheelSpeed = math.min(wheelSpeed, 20.0)
	end

	return wheelSpeed
end

-- Detecta se a roda está girando em sentido contrário à marcha
-- Apenas para marchas pra frente (1, 2, 3...): protege se carro rola pra trás
-- Ré: proteção DESATIVADA — permite dar ré normalmente
local function isReverseRotation(currentGear)
	local carSpeed = car.speedKmh
	if currentGear > 0 and carSpeed < -2.0 then
		-- Marcha pra frente, carro indo pra trás → PROTEGE
		return true
	end
	-- Ré: sem proteção reversa
	return false
end

-- Detecta RPM idle uma única vez: espera 0.01s no neutro (tela de pit)
-- e captura o valor diretamente, sem média.
local function updateIdleRPMSampling(dt)
	if detectedIdleRPM ~= nil then return end

	if not rpmSamplingActive then
		-- Condições: neutro, parado, sem acelerar
		if car.gear == 0 and math.abs(car.speedKmh) < 1.0 and car.gas < 0.05 then
			rpmSamplingActive = true
			rpmSamplingTimer = 0.0
		end
		return
	end

	-- Mantém contagem enquanto estiver no neutro parado
	if car.gear == 0 and math.abs(car.speedKmh) < 1.0 and car.gas < 0.05 then
		rpmSamplingTimer = rpmSamplingTimer + dt

		-- Após 0.01 segundos, captura o RPM diretamente (sem média)
		if rpmSamplingTimer >= 0.01 then
			detectedIdleRPM = car.rpm
			if detectedIdleRPM < 400 then detectedIdleRPM = 400 end
			ac.store("dss_idle_rpm", detectedIdleRPM)
		end
	else
		-- Perdeu as condições, reseta
		rpmSamplingActive = false
		rpmSamplingTimer = 0.0
	end
end

-- Calcula target de embreagem baseado no RPM (proteção anti-stall)
local function getRPMClutchTarget(dt)
	if detectedIdleRPM == nil then return 1.0 end

	local margin = cfg.ANTISTALL_RPM_MARGIN
	local hyst   = cfg.ANTISTALL_RPM_HYSTERESIS

	local thresholdEngage  = detectedIdleRPM * (1.0 - margin)
	local thresholdRelease = detectedIdleRPM * (1.0 - margin + hyst)

	if car.rpm < thresholdEngage then
		rpmClutchEngaged = true
		rpmLockoutTimer = 0.5
	end

	if car.rpm > thresholdRelease then
		if rpmLockoutTimer > 0 then
			rpmLockoutTimer = math.max(0, rpmLockoutTimer - dt)
		else
			rpmClutchEngaged = false
		end
	end

	local target = rpmClutchEngaged and 0.0 or 1.0

	if rpmClutchEngaged then
		rpmClutchSmoothed = pedals.approach(rpmClutchSmoothed, 0.0, 50.0, dt)
	else
		local smoothFactor = math.pow(0.90, dt * 60)
		rpmClutchSmoothed = rpmClutchSmoothed * smoothFactor + target * (1.0 - smoothFactor)
	end

	return rpmClutchSmoothed
end

-- Snap instantâneo se speed >= 10.0 (para embreagem manual)
local function approachClutchManual(current, target, speed, dt)
	if speed >= 10.0 then return target end
	return pedals.approach(current, target, speed, dt)
end

function clutch.update(dt, data, manualPressed, currentGear, currentGas)

	-- ── Atualizar amostragem de RPM idle ─────────────────────────────
	updateIdleRPMSampling(dt)

	-- ── Inicialização no primeiro frame ───────────────────────────────
	if not clutchInitialized then
		clutchValue       = data.clutch
		antistallClutch   = data.clutch
		antistallSmoothed = data.clutch
		reverseProtectionSmoothed = 1.0
		clutchInitialized = true
		forceInitToggle   = true
	end

	-- ── Toggle forçado na inicialização ──────────────────────────────
	if forceInitToggle then
		local originalAntistall  = cfg.ANTISTALL_ENABLED
		local originalAutoclutch = cfg.AUTOCLUTCH_ENABLED
		cfg.ANTISTALL_ENABLED  = true
		cfg.AUTOCLUTCH_ENABLED = true

		local speed = getEffectiveSpeed()
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
		local pressFloor = 1.0 - (cfg.CLUTCH_MAX / 100.0)
		clutchValue       = math.max(
			approachClutchManual(clutchValue, 0.0, cfg.CLUTCH_PRESS_SPEED, dt),
			pressFloor
		)
		antistallClutch   = clutchValue
		antistallSmoothed = clutchValue
		reverseProtectionSmoothed = 1.0
		prevGear          = currentGear
		return clutchValue
	end

	-- ── 2. ANTI-STALL ────────────────────────────────────────────────
	if cfg.ANTISTALL_ENABLED then
		-- Bite point: 100% no neutro (silencioso), valor do jogador nas outras marchas
		local effectiveBitePoint = (currentGear == 0) and 1.0 or cfg.ANTISTALL_BITE_POINT

		local speed = getEffectiveSpeed()
		local speedRange = cfg.ANTISTALL_FULL_SPEED - cfg.ANTISTALL_MIN_SPEED
		local tSpeed = 0.0
		if speedRange > 0 then
			tSpeed = math.max(0, math.min((speed - cfg.ANTISTALL_MIN_SPEED) / speedRange, 1.0))
		end
		local speedTarget    = math.pow(tSpeed, cfg.ANTISTALL_GAMMA)
		local throttleTarget = currentGas * effectiveBitePoint
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

		-- Proteção contra rotação reversa (marcha x direção opostas)
		if isReverseRotation(currentGear) then
			reverseProtectionSmoothed = pedals.approach(
				reverseProtectionSmoothed, 0.0, cfg.ANTISTALL_REVERSE_SPEED, dt)
		else
			reverseProtectionSmoothed = pedals.approach(
				reverseProtectionSmoothed, 1.0, cfg.ANTISTALL_REVERSE_SPEED, dt)
		end
		-- A proteção reversa é a mais restritiva (menor valor)
		antistallClutch = math.min(antistallClutch, reverseProtectionSmoothed)
	else
		antistallClutch   = 1.0
		antistallSmoothed = 1.0
		reverseProtectionSmoothed = 1.0
	end

	-- ── 2.5. RPM ANTI-STALL (proteção adicional) ─────────────────────
	local rpmTarget = getRPMClutchTarget(dt)

	-- Combinar targets: o MAIS PROTEGIDO ganha (menor valor)
	local combinedTarget = math.min(antistallClutch, rpmTarget)

	-- ── 3. AUTOCLUTCH ────────────────────────────────────────────────
	if cfg.AUTOCLUTCH_ENABLED and currentGear ~= prevGear and prevGear ~= -999 then
		if clutchValue > 0.3 then acState = 1 end
	end

	-- ── 4. APLICAR clutchValue ───────────────────────────────────────
	if acState == 1 then
		local depthTarget = 1.0 - cfg.AUTOCLUTCH_DEPTH
		clutchValue = approachClutchManual(clutchValue, depthTarget, cfg.AUTOCLUTCH_PRESS_SPEED, dt)
		acPressTimer = acPressTimer + dt
		if clutchValue <= depthTarget + 0.02 and acPressTimer >= AC_MIN_PRESS_TIME then
			acState = 2
			acPressTimer = 0
		end

	elseif acState == 2 then
		local releaseTarget = cfg.ANTISTALL_ENABLED and combinedTarget or 1.0
		clutchValue = approachClutchManual(clutchValue, releaseTarget, cfg.AUTOCLUTCH_RELEASE_SPEED, dt)
		if clutchValue >= releaseTarget - 0.02 then acState = 0 end

	else
		if cfg.ANTISTALL_ENABLED then
			clutchValue = combinedTarget
		else
			clutchValue = approachClutchManual(clutchValue, 1.0, cfg.CLUTCH_RELEASE_SPEED, dt)
		end
	end

	-- Debug stores
	ac.store("dss_as_speed", getEffectiveSpeed())
	ac.store("dss_as_wheel_speed", getWheelSpeed())
	ac.store("dss_as_rpm_target", rpmTarget)
	ac.store("dss_as_idle_rpm", detectedIdleRPM or 0)
	ac.store("dss_as_reverse_prot", reverseProtectionSmoothed)

	prevGear = currentGear
	return clutchValue
end

return clutch
