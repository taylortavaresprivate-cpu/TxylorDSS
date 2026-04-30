-- ========================================================================
-- DSS KEYBINDS MODULE
-- Gerencia toggles de sistemas via teclas configuráveis.
-- Chame M.update(dt) no loop principal do TxylorMouseSteer.
-- ========================================================================

local cfg = require "dss_config"

local M = {}

local prevState = {}

local function justPressed(vk)
	if vk == 0 then return false end
	local down = ac.isKeyDown(vk)
	local was  = prevState[vk] or false
	prevState[vk] = down
	return down and not was
end

function M.update(dt)
	-- Toggles de sistemas
	if justPressed(cfg.KEY_TOGGLE_ABS) then
		cfg.ABS_ENABLED = not cfg.ABS_ENABLED
	end
	if justPressed(cfg.KEY_TOGGLE_TC) then
		cfg.TC_ENABLED = not cfg.TC_ENABLED
	end
	if justPressed(cfg.KEY_TOGGLE_LAUNCH) then
		cfg.LAUNCH_ENABLED = not cfg.LAUNCH_ENABLED
	end
	if justPressed(cfg.KEY_TOGGLE_CRUISE) then
		cfg.CRUISE_ENABLED = not cfg.CRUISE_ENABLED
	end
	if justPressed(cfg.KEY_TOGGLE_AUTOCLUTCH) then
		cfg.AUTOCLUTCH_ENABLED = not cfg.AUTOCLUTCH_ENABLED
	end

	-- FFB Gain ajustável em tempo real
	if justPressed(cfg.KEY_FFB_GAIN_UP) then
		cfg.FFB_GAIN = math.min(cfg.FFB_GAIN + 0.1, 10.0)
		ac.setSystemMessage('FFB Gain: '..string.format("%.1f", cfg.FFB_GAIN), 'Pressione a tecla de diminuir para reduzir')
	end
	if justPressed(cfg.KEY_FFB_GAIN_DOWN) then
		cfg.FFB_GAIN = math.max(cfg.FFB_GAIN - 0.1, 0.0)
		ac.setSystemMessage('FFB Gain: '..string.format("%.1f", cfg.FFB_GAIN), 'Pressione a tecla de aumentar para subir')
	end
end

return M