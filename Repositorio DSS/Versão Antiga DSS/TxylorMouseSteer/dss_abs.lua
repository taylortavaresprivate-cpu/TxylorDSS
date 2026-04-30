-- ========================================================================
-- DSS ABS MODULE
-- ========================================================================
-- ABS v2 com multiplicadores front/rear independentes
-- ========================================================================

local cfg    = require "dss_config"
local pedals = require "dss_pedals"

local abs = {}

local multiplierF = 1.0
local multiplierR = 1.0

local function getMultiplier(ndSlipAxis, dt, currentMult, curveThreshold)
	local slip = ndSlipAxis / cfg.ABS_NDSLIP_DIV
	local target
	if slip > curveThreshold then
		local excess = (slip - curveThreshold) / (1.0 - curveThreshold)
		target = math.max(cfg.ABS_MIN_BRAKE, 1.0 - excess * cfg.ABS_INTENSITY)
	else
		target = 1.0
	end
	return pedals.approach(currentMult, target, cfg.ABS_SMOOTH, dt)
end

function abs.update(dt, data, brakeValue, steerAngle)
	if cfg.ABS_ENABLED and brakeValue > 0.01 and car.speedKmh > cfg.ABS_MIN_SPEED then
		local steerAmount    = math.abs(steerAngle)
		local curveThreshold = cfg.ABS_THRESHOLD * (1.0 + steerAmount * cfg.ABS_CURVE_FACTOR)
		local ndSlipF = (data.ndSlipL  + data.ndSlipR)  / 2.0
		local ndSlipR = (data.ndSlipRL + data.ndSlipRR) / 2.0
		multiplierF = getMultiplier(ndSlipF, dt, multiplierF, curveThreshold)
		multiplierR = getMultiplier(ndSlipR, dt, multiplierR, curveThreshold)
		local absMultiplier = math.min(multiplierF, multiplierR)
		return brakeValue * absMultiplier
	else
		multiplierF = pedals.approach(multiplierF, 1.0, cfg.ABS_SMOOTH, dt)
		multiplierR = pedals.approach(multiplierR, 1.0, cfg.ABS_SMOOTH, dt)
		return brakeValue
	end
end

return abs