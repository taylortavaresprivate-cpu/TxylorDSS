-- ========================================================================
-- DSS PEDALS MODULE
-- ========================================================================

local cfg = require "dss_config"

local pedals = {}

pedals.gasValue          = 0
pedals.brakeValue        = 0
pedals.handbrakeValue    = 0
pedals.scrollBrakeTarget = 0

local scrollGas        = 0.0
local scrollBrake      = 0.0
local scrollContinuous = 0.0

-- ========================================================================
-- FUNÇÕES DE APROXIMAÇÃO
-- ========================================================================

-- Uso geral (clutch module, etc.) — sem snap
function pedals.approach(current, target, speed, dt)
	if current < target then
		return math.min(current + speed * dt, target)
	else
		return math.max(current - speed * dt, target)
	end
end

-- Uso exclusivo dos pedais — snap instantâneo quando speed >= 10.0
local function approachPedal(current, target, speed, dt)
	if speed >= 10.0 then return target end
	if current < target then
		return math.min(current + speed * dt, target)
	else
		return math.max(current - speed * dt, target)
	end
end

-- ========================================================================

function pedals.updateGas(dt, gasTarget, ui)
	if cfg.SCROLL_GAS_ENABLED then
		local wheel = (ui and ui.mouseWheel) or 0
		if cfg.SCROLL_GAS_INVERT then wheel = -wheel end

		if cfg.SCROLL_GAS_MAX_SPEED > 0 and car.speedKmh > cfg.SCROLL_GAS_MAX_SPEED then
			scrollGas        = 0.0
			scrollBrake      = 0.0
			scrollContinuous = 0.0

		elseif wheel ~= 0 then
			local step = cfg.SCROLL_GAS_STEP
			local mode = cfg.SCROLL_GAS_MODE

			if mode == 0 then
				scrollGas        = math.clamp(scrollGas + wheel * step, 0.0, 1.0)
				scrollBrake      = 0.0
				scrollContinuous = 0.0
			elseif mode == 1 then
				scrollBrake      = math.clamp(scrollBrake + (-wheel) * step, 0.0, 1.0)
				scrollGas        = 0.0
				scrollContinuous = 0.0
			else
				if cfg.SCROLL_GAS_GRADUAL then
					scrollContinuous = math.clamp(scrollContinuous + wheel * step, -1.0, 1.0)
					scrollGas   = 0.0
					scrollBrake = 0.0
				else
					if wheel > 0 then
						scrollGas   = math.clamp(scrollGas + wheel * step, 0.0, 1.0)
						scrollBrake = 0.0
					else
						scrollBrake = math.clamp(scrollBrake + (-wheel) * step, 0.0, 1.0)
						scrollGas   = 0.0
					end
					scrollContinuous = 0.0
				end
			end
		end

		if cfg.SCROLL_GAS_DECAY > 0 then
			scrollGas   = math.max(scrollGas   - cfg.SCROLL_GAS_DECAY * dt, 0.0)
			scrollBrake = math.max(scrollBrake - cfg.SCROLL_GAS_DECAY * dt, 0.0)
			if scrollContinuous > 0 then
				scrollContinuous = math.max(scrollContinuous - cfg.SCROLL_GAS_DECAY * dt, 0.0)
			elseif scrollContinuous < 0 then
				scrollContinuous = math.min(scrollContinuous + cfg.SCROLL_GAS_DECAY * dt, 0.0)
			end
		end

		local finalGas, finalBrake
		if cfg.SCROLL_GAS_MODE == 2 and cfg.SCROLL_GAS_GRADUAL then
			finalGas   = math.max(scrollContinuous, 0.0)
			finalBrake = math.max(-scrollContinuous, 0.0)
		else
			finalGas   = scrollGas
			finalBrake = scrollBrake
		end

		if cfg.SCROLL_GAS_RESET_ON_BRAKE and pedals.brakeValue > 0.1 then
			scrollGas        = 0.0
			scrollContinuous = math.min(scrollContinuous, 0.0)
			finalGas         = 0.0
		end

		gasTarget                = math.max(gasTarget, finalGas)
		pedals.scrollBrakeTarget = finalBrake

		local displayVal
		if cfg.SCROLL_GAS_MODE == 2 and cfg.SCROLL_GAS_GRADUAL then
			displayVal = scrollContinuous
		else
			displayVal = finalGas > 0 and finalGas or -finalBrake
		end
		ac.store('dss_scroll_gas_value', displayVal)
	else
		pedals.scrollBrakeTarget = 0
		ac.store('dss_scroll_gas_value', 0)
	end

	local speed = gasTarget > pedals.gasValue and cfg.GAS_PRESS_SPEED or cfg.GAS_RELEASE_SPEED
	local maxGas = cfg.GAS_MAX / 100.0
	pedals.gasValue = math.min(approachPedal(pedals.gasValue, gasTarget, speed, dt), maxGas)
	return pedals.gasValue
end

function pedals.updateBrake(dt, brakeTarget)
	brakeTarget = math.max(brakeTarget, pedals.scrollBrakeTarget or 0)
	local speed = brakeTarget > pedals.brakeValue and cfg.BRAKE_PRESS_SPEED or cfg.BRAKE_RELEASE_SPEED
	local maxBrake = cfg.BRAKE_MAX / 100.0
	pedals.brakeValue = math.min(approachPedal(pedals.brakeValue, brakeTarget, speed, dt), maxBrake)
	return pedals.brakeValue
end

function pedals.updateHandbrake(dt, handbrakeTarget)
	local speed = handbrakeTarget > pedals.handbrakeValue and cfg.HANDBRAKE_PRESS_SPEED or cfg.HANDBRAKE_RELEASE_SPEED
	local maxHandbrake = cfg.HANDBRAKE_MAX / 100.0
	pedals.handbrakeValue = math.min(approachPedal(pedals.handbrakeValue, handbrakeTarget, speed, dt), maxHandbrake)
	return pedals.handbrakeValue
end

return pedals