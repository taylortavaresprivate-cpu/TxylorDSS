-- ========================================================================
-- DSS STEERING MODULE
-- ========================================================================
-- Direção via mouse, FFB, gyro, speed sensitivity, gamma, filter
-- ========================================================================

local cfg = require "dss_config"

local steering = {}

steering.steerAngle    = 0
steering.steerVelocity = 0

local filteredSteer  = 0
local prevSteerAngle = 0
local roadFeelSmoothed = 0

function steering.update(dt, data, ui)
	local tyreSpeed0 = car.wheels[0].angularSpeed * car.wheels[0].tyreRadius
	local tyreSpeed1 = car.wheels[1].angularSpeed * car.wheels[1].tyreRadius
	local isDrive    = math.min(data.speedKmh / 36, 1)
	local isForward  = math.clamp(tyreSpeed0 + tyreSpeed1, 0, 10) / 10

	-- Posição normalizada do mouse (-1 a 1)
	local mouseRaw = (ui.mousePos.x - ui.windowSize.x / 2) / ui.windowSize.x * 2
	local mouseSteer = mouseRaw * cfg.STEER_LIMIT

	-- Deadzone de mouse: zona morta no centro
	if cfg.STEER_DEADZONE > 0 then
		local absSteer = math.abs(mouseSteer)
		if absSteer < cfg.STEER_DEADZONE then
			mouseSteer = 0
		else
			-- Remapeia suavemente: remove a deadzone e reescala para [-1, 1]
			local sign = mouseSteer >= 0 and 1 or -1
			mouseSteer = sign * (absSteer - cfg.STEER_DEADZONE) / (1.0 - cfg.STEER_DEADZONE)
		end
	end

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

	local steerRate = (steering.steerAngle - prevSteerAngle) / math.max(dt, 1e-4)

	if cfg.FFB_ENABLED then
		local velocityAngle = math.atan2(car.localVelocity.x, car.localVelocity.z)
			/ (math.pi / 2) * isDrive * isForward
		local effVelocityAngle = math.clamp(velocityAngle, -cfg.STEER_COUNTER_STEER, cfg.STEER_COUNTER_STEER)

		local rawFfb   = data.ffb * cfg.FFB_GAIN
		local ffbSign  = rawFfb >= 0 and 1 or -1
		local ffbForce = ffbSign * math.pow(math.abs(rawFfb) + 1e-9, cfg.FFB_GAMMA)

		local totalSpeed   = math.max(math.sqrt(car.localVelocity.x^2 + car.localVelocity.z^2), 0.1)
		local lateralForce = (car.localVelocity.x / totalSpeed) * cfg.FFB_LATERAL * isDrive * isForward

		local damperForce = steerRate * cfg.FFB_DAMPER

		-- Road Feel: vibração da textura da pista
		local roadFeelForce = 0
		if cfg.ROAD_FEEL_ENABLED then
			local w0 = car.wheels[0]
			local w1 = car.wheels[1]
			local w2 = car.wheels[2]
			local w3 = car.wheels[3]
			local frontVib = (
				(w0.suspensionTravel or 0) * (w0.angularSpeed or 0) +
				(w1.suspensionTravel or 0) * (w1.angularSpeed or 0)
			) * cfg.ROAD_FEEL_FRONT
			local rearVib = (
				(w2.suspensionTravel or 0) * (w2.angularSpeed or 0) +
				(w3.suspensionTravel or 0) * (w3.angularSpeed or 0)
			) * cfg.ROAD_FEEL_REAR
			local rawRoadFeel = (frontVib + rearVib) * cfg.ROAD_FEEL_GAIN * isDrive
			-- Suavização leve (filtro passa-baixa ~20Hz)
			roadFeelSmoothed = roadFeelSmoothed * 0.7 + rawRoadFeel * 0.3
			-- Limita a vibração para não dominar o FFB
			roadFeelForce = math.clamp(roadFeelSmoothed, -0.5, 0.5)
		end

		steering.steerVelocity = (mouseSteer - effVelocityAngle - steering.steerAngle) * effSensi
			- ffbForce
			+ data.localAngularVelocity.y * cfg.GYRO_GAIN * isForward
			- lateralForce
			- damperForce
			+ roadFeelForce
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
		filteredSteer       = filteredSteer * cfg.STEER_FILTER + rawSteer * (1 - cfg.STEER_FILTER)
		steering.steerAngle = filteredSteer
	else
		steering.steerAngle = rawSteer
		filteredSteer       = rawSteer
	end

	prevSteerAngle = steering.steerAngle

	-- Exporta para o monitor em tempo real (lido pelo TxylorConfig)
	ac.store('dss_steer_angle', steering.steerAngle)
	ac.store('dss_mouse_steer', math.clamp(mouseSteer, -1, 1))
	ac.store('dss_ffb_raw',     math.clamp(data.ffb, -1, 1))
end

function steering.sanitize(data)
	if steering.steerAngle ~= steering.steerAngle then
		steering.steerAngle    = 0
		steering.steerVelocity = 0
		filteredSteer          = 0
		prevSteerAngle         = 0
	end
	data.steer = steering.steerAngle
end

return steering