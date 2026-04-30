-- ========================================================================
-- DSS TRACTION CONTROL MODULE
-- ========================================================================
-- TC + detecção automática de tração (FWD/RWD/AWD)
-- ========================================================================

local cfg    = require "dss_config"
local pedals = require "dss_pedals"

local tc = {}

local detectedDrivetrain = 1
local drivetrainDetected = false
local tcMultiplier       = 1.0

function tc.detectDrivetrain()
	if drivetrainDetected then return end

	local ok, dt = pcall(function() return car.drivetrainType end)
	if ok and dt ~= nil then
		if     dt == 1 then detectedDrivetrain = 0
		elseif dt == 0 then detectedDrivetrain = 1
		elseif dt == 2 then detectedDrivetrain = 2
		end
		drivetrainDetected = true
		return
	end

	local ok2, _ = pcall(function() return car.wheels[0].angularSpeed end)
	if not ok2 then return end

	local frontAvg = (math.abs(car.wheels[0].slipRatio) + math.abs(car.wheels[1].slipRatio)) / 2
	local rearAvg  = (math.abs(car.wheels[2].slipRatio) + math.abs(car.wheels[3].slipRatio)) / 2

	if frontAvg > 0.05 or rearAvg > 0.05 then
		if frontAvg > 0.03 and rearAvg > 0.03 then
			detectedDrivetrain = 2
		elseif frontAvg > rearAvg then
			detectedDrivetrain = 0
		else
			detectedDrivetrain = 1
		end
		drivetrainDetected = true
	end
end

local function getNdSlip(data)
	local ndSlipF = (data.ndSlipL  + data.ndSlipR)  / 2.6
	local ndSlipR = (data.ndSlipRL + data.ndSlipRR) / 2.6
	if detectedDrivetrain == 0 then
		return ndSlipF / cfg.TC_NDSLIP_DIV
	elseif detectedDrivetrain == 1 then
		return ndSlipR / cfg.TC_NDSLIP_DIV
	else
		return ((ndSlipF * 0.3) + (ndSlipR * 0.7)) / cfg.TC_NDSLIP_DIV
	end
end

function tc.update(dt, data, gasValue)
	if cfg.TC_ENABLED and car.speedKmh > cfg.TC_MIN_SPEED then
		local slip = getNdSlip(data)
		local tcTarget
		if slip > cfg.TC_THRESHOLD then
			local excess = (slip - cfg.TC_THRESHOLD) / (1.0 - cfg.TC_THRESHOLD)
			tcTarget = math.max(cfg.TC_MIN_GAS, 1.0 - excess * cfg.TC_INTENSITY)
		else
			tcTarget = 1.0
		end
		tcMultiplier = pedals.approach(tcMultiplier, tcTarget, cfg.TC_SMOOTH, dt)
	else
		tcMultiplier = pedals.approach(tcMultiplier, 1.0, cfg.TC_SMOOTH, dt)
	end
	return gasValue * tcMultiplier
end

return tc