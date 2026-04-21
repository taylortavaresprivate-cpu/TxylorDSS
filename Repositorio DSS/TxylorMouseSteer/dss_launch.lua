-- ========================================================================
-- DSS LAUNCH CONTROL MODULE
-- ========================================================================
-- Launch control com cut de RPM
-- ========================================================================

local cfg = require "dss_config"

local launch = {}

local armed      = false
local active     = false
local wasKeyDown = false
local cutTimer   = 0
local cutting    = false

function launch.update(dt, data)
	if not cfg.LAUNCH_ENABLED then
		armed   = false
		active  = false
		cutting = false
		return
	end

	local keyDown = ac.isKeyDown(ac.KeyIndex.X)
	if keyDown and not wasKeyDown then
		if car.speedKmh < 1 then
			armed    = not armed
			cutTimer = 0
			cutting  = false
			if armed then
				ac.setSystemMessage('Launch Control ARMADO',
					'RPM alvo: ' .. cfg.LAUNCH_RPM .. ' | Corte: ' .. cfg.LAUNCH_CUT_TIME .. ' ms')
			else
				ac.setSystemMessage('Launch Control DESARMADO', '')
				active = false
			end
		end
	end
	wasKeyDown = keyDown

	if armed and car.speedKmh > 2 then
		armed   = false
		active  = false
		cutting = false
	end

	if armed and data.gas > 0.8 then active = true end
	if not armed then active = false end

	if not active then
		cutting  = false
		cutTimer = 0
		return
	end

	if cutting then
		cutTimer = cutTimer - dt
		data.gas = 0
		if cutTimer <= 0 then cutting = false end
	else
		if car.rpm >= cfg.LAUNCH_RPM then
			cutting  = true
			cutTimer = cfg.LAUNCH_CUT_TIME / 1000.0
			data.gas = 0
		end
	end
end

return launch