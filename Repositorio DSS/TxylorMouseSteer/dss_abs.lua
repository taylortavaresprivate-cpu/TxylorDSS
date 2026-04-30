-- ========================================================================
-- DSS ABS MODULE
-- ========================================================================
-- ABS v3 com Trail Brake, Brake Recovery, Rear Bias e Monitor
-- ========================================================================

local cfg    = require "dss_config"
local pedals = require "dss_pedals"

local abs = {}

local multiplierF = 1.0
local multiplierR = 1.0

-- Conversão da escala UI para física
local function thresholdPhys() return cfg.ABS_THRESHOLD * 0.001 end
local function minBrakePhys()  return cfg.ABS_MIN_BRAKE  * 0.001 end
local function intensityPhys() return cfg.ABS_INTENSITY  * 0.01  end
local function smoothPhys()    return cfg.ABS_SMOOTH     * 0.1   end
local function curvePhys()     return cfg.ABS_CURVE_FACTOR * 0.1 end
local function trailBrakePhys()  return cfg.ABS_TRAIL_BRAKE / 10.0 end
local function trailStartPhys()  return cfg.ABS_TRAIL_BRAKE_START / 10.0 * 0.9 end
local function rearBiasPhys()    return cfg.ABS_REAR_BIAS / 10.0 end

local function recoveryPhys()
	if cfg.ABS_BRAKE_RECOVERY == 0 then return smoothPhys() end
	return 0.5 + cfg.ABS_BRAKE_RECOVERY * 0.05
end

-- Estado para o monitor
abs.state = {
	ndSlipFL = 0, ndSlipFR = 0, ndSlipRL = 0, ndSlipRR = 0,
	brakeCut = 0,
	isActive = false,
}

local function getMultiplier(ndSlipAxis, dt, currentMult, curveThreshold)
	local slip = ndSlipAxis / cfg.ABS_NDSLIP_DIV
	local target
	if slip > curveThreshold then
		local excess = (slip - curveThreshold) / (1.0 - curveThreshold)
		target = math.max(minBrakePhys(), 1.0 - excess * intensityPhys())
	else
		target = 1.0
	end
	return pedals.approach(currentMult, target, smoothPhys(), dt)
end

function abs.update(dt, data, brakeValue, steerAngle)
	local steerAmount = math.abs(steerAngle)
	local outBrake = brakeValue

	-- Trail Brake: reduz o freio ao virar o volante
	if cfg.ABS_TRAIL_BRAKE > 0 and brakeValue > 0.01 then
		local tStart  = trailStartPhys()
		local tFactor = math.max(0.0, (steerAmount - tStart) / math.max(0.01, 1.0 - tStart))
		local reduction = tFactor * trailBrakePhys()
		outBrake = outBrake * (1.0 - reduction)
	end

	-- Atualiza estado do monitor (deslizamento sempre visível)
	abs.state.ndSlipFL = data.ndSlipL
	abs.state.ndSlipFR = data.ndSlipR
	abs.state.ndSlipRL = data.ndSlipRL
	abs.state.ndSlipRR = data.ndSlipRR

	if cfg.ABS_ENABLED and outBrake > 0.01 and car.speedKmh > cfg.ABS_MIN_SPEED then
		local curveThreshold = thresholdPhys() * (1.0 + steerAmount * curvePhys())
		local ndSlipF = (data.ndSlipL  + data.ndSlipR)  / 2.0
		local ndSlipR = (data.ndSlipRL + data.ndSlipRR) / 2.0

		multiplierF = getMultiplier(ndSlipF, dt, multiplierF, curveThreshold)
		multiplierR = getMultiplier(ndSlipR, dt, multiplierR, curveThreshold)

		-- Rear Bias: blend entre math.min (0) e média ponderada (10)
		local absMultiplier
		local bias = rearBiasPhys()
		if bias == 0 then
			absMultiplier = math.min(multiplierF, multiplierR)
		else
			local minMult = math.min(multiplierF, multiplierR)
			local rearWeight = 0.5 + bias * 0.5
			local weighted = multiplierF * (1.0 - rearWeight) + multiplierR * rearWeight
			absMultiplier = minMult * (1.0 - bias) + weighted * bias
		end

		local result = outBrake * absMultiplier

		abs.state.brakeCut = 1.0 - absMultiplier
		abs.state.isActive = true

		return result
	else
		local recovery = recoveryPhys()
		multiplierF = pedals.approach(multiplierF, 1.0, recovery, dt)
		multiplierR = pedals.approach(multiplierR, 1.0, recovery, dt)

		abs.state.brakeCut = 0
		abs.state.isActive = false

		return outBrake
	end
end

return abs
