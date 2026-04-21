-- ========================================================================
-- DSS ABS MODULE
-- ========================================================================

local cfg    = require "dss_config"
local pedals = require "dss_pedals"

local abs = {}

local multiplierF = 1.0
local multiplierR = 1.0

local function getMultiplier(ndSlipAxis, dt, currentMult, curveThreshold, intensityMult)
	local slip = ndSlipAxis / cfg.ABS_NDSLIP_DIV
	local target
	if slip > curveThreshold then
		local excess = (slip - curveThreshold) / (1.0 - curveThreshold)
		target = math.max(cfg.ABS_MIN_BRAKE, 1.0 - excess * cfg.ABS_INTENSITY * intensityMult)
	else
		target = 1.0
	end
	return pedals.approach(currentMult, target, cfg.ABS_SMOOTH, dt)
end

function abs.update(dt, data, brakeValue, steerAngle)
	local steerAmount = math.abs(steerAngle)

	-- Trail Brake: reduz o freio automaticamente conforme o volante vira
	if cfg.ABS_TRAIL_BRAKE > 0 and brakeValue > 0.01 then
		local trailStart  = (cfg.ABS_TRAIL_BRAKE_START / 10.0) * 0.9
		local trailFactor = math.max(0.0, (steerAmount - trailStart) / math.max(0.01, 1.0 - trailStart))
		local reduction   = trailFactor * (cfg.ABS_TRAIL_BRAKE / 10.0)
		brakeValue = brakeValue * (1.0 - reduction)
	end

	if cfg.ABS_ENABLED and brakeValue > 0.01 and car.speedKmh > cfg.ABS_MIN_SPEED then
		-- Fator de Curva (0-10 → 0-1): relaxa threshold E intensidade em curva
		local curveFactor    = cfg.ABS_CURVE_FACTOR / 10.0
		local curveThreshold = cfg.ABS_THRESHOLD * (1.0 + steerAmount * curveFactor * 2.0)
		local intensityMult  = math.max(0.2, 1.0 - steerAmount * curveFactor * 0.5)

		local ndSlipF = (data.ndSlipL  + data.ndSlipR)  / 2.0
		local ndSlipR = (data.ndSlipRL + data.ndSlipRR) / 2.0

		multiplierF = getMultiplier(ndSlipF, dt, multiplierF, curveThreshold, intensityMult)
		multiplierR = getMultiplier(ndSlipR, dt, multiplierR, curveThreshold, intensityMult)

		-- Rear Bias: quanto a traseira influencia o corte
		local rearWeight    = 0.5 + (cfg.ABS_REAR_BIAS / 10.0) * 0.5
		local absMultiplier = multiplierF * (1.0 - rearWeight) + multiplierR * rearWeight

		return brakeValue * absMultiplier
	else
		-- Brake Recovery: velocidade de retorno ao normal
		local recoverySpeed = 0.5 + cfg.ABS_BRAKE_RECOVERY * 0.95
		multiplierF = pedals.approach(multiplierF, 1.0, recoverySpeed, dt)
		multiplierR = pedals.approach(multiplierR, 1.0, recoverySpeed, dt)
		return brakeValue
	end
end

return abs