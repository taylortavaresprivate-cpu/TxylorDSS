-- ========================================================================
-- DSS STEERING MODULE
-- ========================================================================
-- Direção via mouse, FFB, gyro, speed sensitivity, gamma, filter
-- ========================================================================

local cfg = require "dss_config"

local steering = {}

steering.steerAngle    = 0
steering.steerVelocity = 0

local filteredSteer = 0

function steering.update(dt, data, ui)
	local tyreSpeed0 = car.wheels[0].angularSpeed * car.wheels[0].tyreRadius
	local tyreSpeed1 = car.wheels[1].angularSpeed * car.wheels[1].tyreRadius
	local isDrive    = math.min(data.speedKmh / 36, 1)
	local isForward  = math.clamp(tyreSpeed0 + tyreSpeed1, 0, 10) / 10

	local mouseSteer = (ui.mousePos.x - ui.windowSize.x / 2) / ui.windowSize.x * 2
	mouseSteer = mouseSteer * cfg.STEER_LIMIT

	local sign = mouseSteer >= 0 and 1 or -1
	mouseSteer = sign * math.pow(math.abs(mouseSteer), cfg.STEER_GAMMA)

	local effSensi = cfg.STEER_SENSI
	if cfg.SPEED_SENSI < 1.0 and car.speedKmh > cfg.SPEED_SENSI_START then
		local range = cfg.SPEED_SENSI_END - cfg.SPEED_SENSI_START
		if range > 0 then
			local t = math.min((car.speedKmh - cfg.SPEED_SENSI_START) / range, 1.0)
			effSensi = cfg.STEER_SENSI * (1.0 - t * (1.0 - cfg.SPEED_SENSI))
		end
	end

	if cfg.FFB_ENABLED then
		local velocityAngle = math.atan2(car.localVelocity.x, car.localVelocity.z)
			/ (math.pi / 2) * isDrive * isForward
		local effVelocityAngle = math.clamp(velocityAngle, -cfg.STEER_COUNTER_STEER, cfg.STEER_COUNTER_STEER)
		steering.steerVelocity = (mouseSteer - effVelocityAngle - steering.steerAngle) * effSensi
			- data.ffb * cfg.FFB_GAIN
			+ data.localAngularVelocity.y * cfg.GYRO_GAIN * isForward
	else
		steering.steerVelocity = (mouseSteer - steering.steerAngle) * effSensi
	end

	local targetSteer = math.clamp(
		steering.steerAngle + steering.steerVelocity * 450 / data.steerLock * dt, -1, 1)

	local steerDelta = targetSteer - steering.steerAngle
	if steering.steerAngle * targetSteer < 0 then
		steerDelta = math.clamp(steerDelta,
			-cfg.STEER_REVERSAL_LIMIT * dt, cfg.STEER_REVERSAL_LIMIT * dt)
	end

	local rawSteer = math.clamp(steering.steerAngle + steerDelta, -1, 1)

	if cfg.STEER_FILTER > 0 then
		filteredSteer        = filteredSteer * cfg.STEER_FILTER + rawSteer * (1 - cfg.STEER_FILTER)
		steering.steerAngle  = filteredSteer
	else
		steering.steerAngle  = rawSteer
		filteredSteer        = rawSteer
	end
end

function steering.sanitize(data)
	if steering.steerAngle ~= steering.steerAngle then
		steering.steerAngle    = 0
		steering.steerVelocity = 0
		filteredSteer          = 0
	end
	data.steer = steering.steerAngle
end

return steering