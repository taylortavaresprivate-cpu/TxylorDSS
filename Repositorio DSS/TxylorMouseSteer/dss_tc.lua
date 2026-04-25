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

local function getSlipRatioSignal()
	if detectedDrivetrain == 0 then
		return (math.abs(car.wheels[0].slipRatio) + math.abs(car.wheels[1].slipRatio)) / 2
	elseif detectedDrivetrain == 1 then
		return (math.abs(car.wheels[2].slipRatio) + math.abs(car.wheels[3].slipRatio)) / 2
	else
		return (math.abs(car.wheels[0].slipRatio) + math.abs(car.wheels[1].slipRatio) +
		        math.abs(car.wheels[2].slipRatio) + math.abs(car.wheels[3].slipRatio)) / 4
	end
end

local function getNdSlip(data)
	local ndSlipF = (data.ndSlipL  + data.ndSlipR)  / 2.6
	local ndSlipR = (data.ndSlipRL + data.ndSlipRR) / 2.6
	local ndSig
	if detectedDrivetrain == 0 then
		ndSig = ndSlipF / cfg.TC_NDSLIP_DIV
	elseif detectedDrivetrain == 1 then
		ndSig = ndSlipR / cfg.TC_NDSLIP_DIV
	else
		ndSig = ((ndSlipF * 0.3) + (ndSlipR * 0.7)) / cfg.TC_NDSLIP_DIV
	end
	local srSig = getSlipRatioSignal() * cfg.TC_SLIP_RATIO_SCALE
	return math.max(ndSig, srSig)
end

function tc.update(dt, data, gasValue)
	local slip = 0.0
	if cfg.TC_ENABLED and car.speedKmh > cfg.TC_MIN_SPEED then
		slip = getNdSlip(data)
		local tcTarget
		if slip > cfg.TC_THRESHOLD then
			local excess = (slip - cfg.TC_THRESHOLD) / (1.0 - cfg.TC_THRESHOLD)
			tcTarget = math.max(cfg.TC_MIN_GAS, 1.0 - excess * cfg.TC_INTENSITY)
		else
			tcTarget = 1.0
		end
		local speed = tcMultiplier > tcTarget and cfg.TC_SMOOTH or cfg.TC_RECOVERY
		tcMultiplier = pedals.approach(tcMultiplier, tcTarget, speed, dt)
	else
		tcMultiplier = pedals.approach(tcMultiplier, 1.0, cfg.TC_RECOVERY, dt)
	end
	ac.store("dss_tc_mult",       tcMultiplier)
	ac.store("dss_tc_slip",       slip)
	ac.store("dss_tc_drivetrain", detectedDrivetrain)
	return gasValue * tcMultiplier
end

return tc