-- ========================================================================
-- DSS CONFIG MODULE
-- ========================================================================

local cfg = {}

cfg.FFB_ENABLED          = true
cfg.FFB_GAIN             = 0.8
cfg.GYRO_GAIN            = 8.0
cfg.STEER_COUNTER_STEER  = 2.0
cfg.FFB_DAMPER           = 0.5
cfg.FFB_LATERAL          = 0.3
cfg.FFB_GAMMA            = 1.0
cfg.STEER_SENSI          = 65.0
cfg.STEER_LIMIT          = 1.0
cfg.STEER_GAMMA          = 1.0
cfg.STEER_FILTER         = 0.0
cfg.STEER_REVERSAL_LIMIT = 2.5
cfg.SPEED_SENSI          = 1.0
cfg.SPEED_SENSI_START    = 80
cfg.SPEED_SENSI_END      = 250
cfg.GAS_PRESS_SPEED      = 4.8
cfg.GAS_RELEASE_SPEED    = 4.4
cfg.GAS_MAX              = 100
cfg.BRAKE_PRESS_SPEED    = 4.8
cfg.BRAKE_RELEASE_SPEED  = 4.4
cfg.BRAKE_MAX            = 100
cfg.CLUTCH_PRESS_SPEED   = 4.8
cfg.CLUTCH_RELEASE_SPEED = 4.8
cfg.CLUTCH_MAX           = 100
cfg.HANDBRAKE_PRESS_SPEED    = 8.0
cfg.HANDBRAKE_RELEASE_SPEED  = 8.0
cfg.HANDBRAKE_MAX            = 100
cfg.AUTOCLUTCH_ENABLED       = true
cfg.AUTOCLUTCH_DEPTH         = 1.0
cfg.AUTOCLUTCH_PRESS_SPEED   = 10.0
cfg.AUTOCLUTCH_RELEASE_SPEED = 5.0
cfg.ANTISTALL_ENABLED         = true
cfg.ANTISTALL_FULL_SPEED      = 30.0
cfg.ANTISTALL_MIN_SPEED       = 2.0
cfg.ANTISTALL_ENGAGE_SPEED    = 1.8
cfg.ANTISTALL_DISENGAGE_SPEED = 2.5
cfg.ANTISTALL_GAMMA           = 1.0
cfg.ANTISTALL_MAX_PRESS       = 1.0
cfg.ANTISTALL_BITE_POINT      = 0.5
cfg.ANTISTALL_TARGET_SMOOTH   = 0.92
cfg.BLIP_ENABLED       = true
cfg.BLIP_INTENSITY     = 1.5
cfg.BLIP_DURATION      = 200
cfg.BLIP_MIN_RPM_DIFF  = 200
cfg.BLIP_ATTACK_SPEED  = 15.0
cfg.BLIP_RELEASE_SPEED = 4.0
cfg.NLS_ENABLED       = true
cfg.NLS_CUT_DURATION  = 150
cfg.NLS_CUT_AMOUNT    = 0.2
cfg.NLS_MIN_RPM       = 3000
cfg.NLS_RELEASE_MULT  = 2.0

-- [SCROLL GAS]
cfg.SCROLL_GAS_ENABLED        = false
cfg.SCROLL_GAS_STEP           = 0.10
cfg.SCROLL_GAS_DECAY          = 0.0
cfg.SCROLL_GAS_RESET_ON_BRAKE = true
cfg.SCROLL_GAS_MAX_SPEED      = 0.0
cfg.SCROLL_GAS_INVERT         = false
cfg.SCROLL_GAS_MODE           = 2
cfg.SCROLL_GAS_GRADUAL        = false

-- [ABS] — valores internos de física (threshold e min_brake em escala real)
cfg.ABS_ENABLED           = true
cfg.ABS_LEVEL             = 15
cfg.ABS_THRESHOLD         = 0.026   -- UI 26 × 0.001
cfg.ABS_MIN_SPEED         = 14
cfg.ABS_MIN_BRAKE         = 0.065   -- UI 65 × 0.001
cfg.ABS_INTENSITY         = 0.44
cfg.ABS_SMOOTH            = 3.0
cfg.ABS_NDSLIP_DIV        = 2.6
cfg.ABS_CURVE_FACTOR      = 5       -- inteiro 0-10, convertido em dss_abs.lua (/10)
cfg.ABS_REAR_BIAS         = 6
cfg.ABS_TRAIL_BRAKE       = 0
cfg.ABS_TRAIL_BRAKE_START = 2
cfg.ABS_BRAKE_RECOVERY    = 6

-- [TC]
cfg.TC_ENABLED    = true
cfg.TC_LEVEL      = 13
cfg.TC_THRESHOLD  = 0.053
cfg.TC_MIN_SPEED  = 10
cfg.TC_MIN_GAS    = 0.51
cfg.TC_INTENSITY  = 0.48
cfg.TC_SMOOTH     = 3.1
cfg.TC_NDSLIP_DIV       = 2.4
cfg.TC_SLIP_RATIO_SCALE = 1.0
cfg.TC_RECOVERY         = 8.0
cfg.LAUNCH_ENABLED  = false
cfg.LAUNCH_RPM      = 4500
cfg.LAUNCH_CUT_TIME = 200
cfg.CRUISE_ENABLED    = false
cfg.CRUISE_FULL_SPEED = 30.0
cfg.CRUISE_GAS_MIN    = 0.30
cfg.CRUISE_BRAKE_MIN  = 0.25

-- [KEYBINDS]
cfg.KEY_CLUTCH            = 67
cfg.KEY_HANDBRAKE         = 32
cfg.KEY_TOGGLE_ABS        = 0
cfg.KEY_TOGGLE_TC         = 0
cfg.KEY_TOGGLE_LAUNCH     = 0
cfg.KEY_TOGGLE_CRUISE     = 0
cfg.KEY_TOGGLE_AUTOCLUTCH = 0

-- ========================================================================
-- TABELAS DE NÍVEIS
-- ========================================================================
-- {threshold(interno), min_brake(interno), intensity, smooth,
--  rear_bias, trail_brake, trail_brake_start, brake_recovery, curve_factor(0-10)}

local ABS_LEVELS = {
	[1] ={0.100,0.005,0.02,0.3, 3,0,2,3,1},
	[2] ={0.100,0.008,0.03,0.4, 3,0,2,3,1},
	[3] ={0.090,0.010,0.04,0.4, 3,0,2,3,1},
	[4] ={0.085,0.012,0.05,0.5, 3,0,2,4,2},
	[5] ={0.080,0.015,0.06,0.5, 3,0,2,4,2},
	[6] ={0.075,0.018,0.07,0.6, 4,0,2,4,2},
	[7] ={0.070,0.022,0.09,0.7, 4,0,2,4,3},
	[8] ={0.065,0.026,0.11,0.7, 4,0,2,5,3},
	[9] ={0.060,0.030,0.13,0.8, 4,0,2,5,3},
	[10]={0.055,0.035,0.16,0.9, 5,0,2,5,4},
	[11]={0.050,0.040,0.20,1.0, 5,0,2,5,4},
	[12]={0.044,0.045,0.26,1.5, 5,0,2,5,4},
	[13]={0.038,0.050,0.32,2.0, 6,0,2,6,5},
	[14]={0.032,0.060,0.38,2.5, 6,0,2,6,5},
	[15]={0.026,0.065,0.44,3.0, 6,0,2,6,5},
	[16]={0.021,0.072,0.52,3.3, 7,0,2,6,6},
	[17]={0.016,0.078,0.60,3.6, 7,0,2,7,6},
	[18]={0.012,0.084,0.70,4.0, 7,0,2,7,7},
	[19]={0.008,0.090,0.82,4.5, 8,0,2,7,7},
	[20]={0.004,0.096,0.95,5.0, 8,0,2,8,7},
}

function cfg.applyAbsLevel()
	if cfg.ABS_LEVEL >= 1 and cfg.ABS_LEVEL <= 20 then
		local l = ABS_LEVELS[cfg.ABS_LEVEL]
		cfg.ABS_THRESHOLD         = l[1]
		cfg.ABS_MIN_BRAKE         = l[2]
		cfg.ABS_INTENSITY         = l[3]
		cfg.ABS_SMOOTH            = l[4]
		cfg.ABS_REAR_BIAS         = l[5]
		cfg.ABS_TRAIL_BRAKE       = l[6]
		cfg.ABS_TRAIL_BRAKE_START = l[7]
		cfg.ABS_BRAKE_RECOVERY    = l[8]
		cfg.ABS_CURVE_FACTOR      = l[9]
	end
end

local TC_LEVELS = {
	[1]={0.100,0.92,0.04,0.4},[2]={0.085,0.85,0.08,0.6},[3]={0.065,0.78,0.14,0.9},
	[4]={0.100,0.95,0.03,1.0},[5]={0.095,0.90,0.08,1.2},[6]={0.090,0.85,0.13,1.5},
	[7]={0.085,0.80,0.18,1.7},[8]={0.079,0.76,0.23,1.9},[9]={0.074,0.71,0.28,2.2},
	[10]={0.069,0.66,0.33,2.4},[11]={0.064,0.61,0.38,2.6},[12]={0.058,0.56,0.43,2.9},
	[13]={0.053,0.51,0.48,3.1},[14]={0.048,0.46,0.53,3.3},[15]={0.043,0.41,0.58,3.6},
	[16]={0.037,0.37,0.63,3.8},[17]={0.032,0.32,0.68,4.0},[18]={0.027,0.27,0.73,4.3},
	[19]={0.022,0.22,0.78,4.5},[20]={0.016,0.17,0.83,4.7},[21]={0.011,0.12,0.88,5.0},
	[22]={0.006,0.07,0.93,5.2},[23]={0.001,0.02,0.98,5.5},
}
function cfg.applyTcLevel()
	if cfg.TC_LEVEL >= 1 and cfg.TC_LEVEL <= 23 then
		local l = TC_LEVELS[cfg.TC_LEVEL]
		cfg.TC_THRESHOLD = l[1]; cfg.TC_MIN_GAS   = l[2]
		cfg.TC_INTENSITY = l[3]; cfg.TC_SMOOTH    = l[4]
	end
end

-- ========================================================================
-- LEITURA DO CONFIG.INI
-- ========================================================================

local CONFIG_PATH = "apps/lua/TxylorConfig/config.ini"

local function parseIni(path)
	local result = {}
	local file = io.open(path, "r")
	if not file then return nil end
	for line in file:lines() do
		local key, val = line:match("^%s*([%w_]+)%s*=%s*(.+)%s*$")
		if key and val then result[key:lower()] = val end
	end
	file:close()
	return result
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

function cfg.loadConfig()
	local ini = parseIni(CONFIG_PATH)
	if not ini then return end
	local function getf(key, default) return ini[key] and tonumber(ini[key]) or default end
	local function getb(key, default)
		if ini[key] == nil then return default end
		return ini[key] == "1" or ini[key] == "true"
	end
	local function geti(key, default) return ini[key] and math.floor(tonumber(ini[key]) or default) or default end

	cfg.FFB_ENABLED         = getb("ffb_enabled", cfg.FFB_ENABLED)
	cfg.FFB_GAIN            = clamp(getf("ffb_gain",            0.8),  0.0, 10.0)
	cfg.GYRO_GAIN           = clamp(getf("gyro_gain",           4.0),  0.0, 10.0) * 2.0
	cfg.STEER_COUNTER_STEER = clamp(getf("steer_counter_steer", 10.0), 0.0, 10.0) * 0.2
	cfg.FFB_DAMPER          = clamp(getf("ffb_damper",          1.7),  0.0, 10.0) * 0.3
	cfg.FFB_LATERAL         = clamp(getf("ffb_lateral",         1.5),  0.0, 10.0) * 0.2
	cfg.FFB_GAMMA           = 0.5 + clamp(getf("ffb_gamma",     5.0),  0.0, 10.0) * 0.1
	cfg.STEER_SENSI  = clamp(getf("steer_sensi",  4.5),  1.0, 10.0) * 15.0
	cfg.STEER_LIMIT  = clamp(getf("steer_limit",  10.0), 0.0, 10.0) * 0.1
	cfg.STEER_GAMMA  = 0.5 + clamp(getf("steer_gamma", 5.0), 0.0, 10.0) * 0.1
	cfg.STEER_FILTER = clamp(getf("steer_filter", 0.0),  0.0, 10.0) * 0.095
	cfg.SPEED_SENSI       = clamp(getf("speed_sensi", 10.0), 0.0, 10.0) * 0.1
	cfg.SPEED_SENSI_START = getf("speed_sensi_start", cfg.SPEED_SENSI_START)
	cfg.SPEED_SENSI_END   = getf("speed_sensi_end",   cfg.SPEED_SENSI_END)
	cfg.GAS_PRESS_SPEED      = getf("gas_press",     cfg.GAS_PRESS_SPEED)
	cfg.GAS_RELEASE_SPEED    = getf("gas_release",   cfg.GAS_RELEASE_SPEED)
	cfg.GAS_MAX              = clamp(geti("gas_max", cfg.GAS_MAX), 0, 100)
	cfg.BRAKE_PRESS_SPEED    = getf("brake_press",   cfg.BRAKE_PRESS_SPEED)
	cfg.BRAKE_RELEASE_SPEED  = getf("brake_release", cfg.BRAKE_RELEASE_SPEED)
	cfg.BRAKE_MAX            = clamp(geti("brake_max", cfg.BRAKE_MAX), 0, 100)
	cfg.CLUTCH_PRESS_SPEED   = getf("clutch_press",  cfg.CLUTCH_PRESS_SPEED)
	cfg.CLUTCH_RELEASE_SPEED = getf("clutch_release",cfg.CLUTCH_RELEASE_SPEED)
	cfg.CLUTCH_MAX           = clamp(geti("clutch_max", cfg.CLUTCH_MAX), 0, 100)
	cfg.HANDBRAKE_PRESS_SPEED    = getf("handbrake_press",   cfg.HANDBRAKE_PRESS_SPEED)
	cfg.HANDBRAKE_RELEASE_SPEED  = getf("handbrake_release", cfg.HANDBRAKE_RELEASE_SPEED)
	cfg.HANDBRAKE_MAX            = clamp(geti("handbrake_max", cfg.HANDBRAKE_MAX), 0, 100)
	cfg.AUTOCLUTCH_ENABLED       = getb("autoclutch_enabled",       cfg.AUTOCLUTCH_ENABLED)
	cfg.AUTOCLUTCH_DEPTH         = getf("autoclutch_depth",         cfg.AUTOCLUTCH_DEPTH)
	cfg.AUTOCLUTCH_PRESS_SPEED   = getf("autoclutch_press_speed",   cfg.AUTOCLUTCH_PRESS_SPEED)
	cfg.AUTOCLUTCH_RELEASE_SPEED = getf("autoclutch_release_speed", cfg.AUTOCLUTCH_RELEASE_SPEED)
	cfg.ANTISTALL_ENABLED         = getb("antistall_enabled",         cfg.ANTISTALL_ENABLED)
	cfg.ANTISTALL_FULL_SPEED      = getf("antistall_full_speed",      cfg.ANTISTALL_FULL_SPEED)
	cfg.ANTISTALL_MIN_SPEED       = getf("antistall_min_speed",       cfg.ANTISTALL_MIN_SPEED)
	cfg.ANTISTALL_ENGAGE_SPEED    = getf("antistall_engage_speed",    cfg.ANTISTALL_ENGAGE_SPEED)
	cfg.ANTISTALL_DISENGAGE_SPEED = getf("antistall_disengage_speed", cfg.ANTISTALL_DISENGAGE_SPEED)
	cfg.ANTISTALL_GAMMA           = getf("antistall_gamma",           cfg.ANTISTALL_GAMMA)
	cfg.ANTISTALL_MAX_PRESS       = getf("antistall_max_press",       cfg.ANTISTALL_MAX_PRESS)
	cfg.ANTISTALL_BITE_POINT      = getf("antistall_bite_point",      cfg.ANTISTALL_BITE_POINT)
	cfg.ANTISTALL_TARGET_SMOOTH   = getf("antistall_target_smooth",   cfg.ANTISTALL_TARGET_SMOOTH)
	if cfg.ANTISTALL_FULL_SPEED <= cfg.ANTISTALL_MIN_SPEED then cfg.ANTISTALL_FULL_SPEED = cfg.ANTISTALL_MIN_SPEED + 5.0 end
	cfg.ANTISTALL_GAMMA         = clamp(cfg.ANTISTALL_GAMMA,         0.1,  10.0)
	cfg.ANTISTALL_MAX_PRESS     = clamp(cfg.ANTISTALL_MAX_PRESS,     0.0,  1.0)
	cfg.ANTISTALL_BITE_POINT    = clamp(cfg.ANTISTALL_BITE_POINT,    0.1,  0.9)
	cfg.ANTISTALL_TARGET_SMOOTH = clamp(cfg.ANTISTALL_TARGET_SMOOTH, 0.0,  0.99)
	cfg.NLS_ENABLED      = getb("nls_enabled",      cfg.NLS_ENABLED)
	cfg.NLS_CUT_DURATION = clamp(getf("nls_cut_duration", cfg.NLS_CUT_DURATION), 50,   500)
	cfg.NLS_CUT_AMOUNT   = clamp(getf("nls_cut_amount",   cfg.NLS_CUT_AMOUNT),   0.0,  1.0)
	cfg.NLS_MIN_RPM      = clamp(getf("nls_min_rpm",      cfg.NLS_MIN_RPM),      1000, 9000)
	cfg.NLS_RELEASE_MULT = clamp(getf("nls_release_mult", cfg.NLS_RELEASE_MULT), 0.5,  5.0)
	cfg.BLIP_ENABLED       = getb("blip_enabled",       cfg.BLIP_ENABLED)
	cfg.BLIP_INTENSITY     = clamp(getf("blip_intensity",     cfg.BLIP_INTENSITY),     0.5,  3.0)
	cfg.BLIP_DURATION      = clamp(getf("blip_duration",      cfg.BLIP_DURATION),      50,   500)
	cfg.BLIP_MIN_RPM_DIFF  = clamp(getf("blip_min_rpm_diff",  cfg.BLIP_MIN_RPM_DIFF),  0,    2000)
	cfg.BLIP_ATTACK_SPEED  = clamp(getf("blip_attack_speed",  cfg.BLIP_ATTACK_SPEED),  1.0,  50.0)
	cfg.BLIP_RELEASE_SPEED = clamp(getf("blip_release_speed", cfg.BLIP_RELEASE_SPEED), 0.5,  30.0)
	cfg.SCROLL_GAS_ENABLED        = getb("scroll_gas_enabled",        cfg.SCROLL_GAS_ENABLED)
	cfg.SCROLL_GAS_STEP           = getf("scroll_gas_step",           cfg.SCROLL_GAS_STEP)
	cfg.SCROLL_GAS_DECAY          = getf("scroll_gas_decay",          cfg.SCROLL_GAS_DECAY)
	cfg.SCROLL_GAS_RESET_ON_BRAKE = getb("scroll_gas_reset_on_brake", cfg.SCROLL_GAS_RESET_ON_BRAKE)
	cfg.SCROLL_GAS_MAX_SPEED      = getf("scroll_gas_max_speed",      cfg.SCROLL_GAS_MAX_SPEED)
	cfg.SCROLL_GAS_INVERT         = getb("scroll_gas_invert",         cfg.SCROLL_GAS_INVERT)
	cfg.SCROLL_GAS_MODE           = clamp(getf("scroll_gas_mode",     cfg.SCROLL_GAS_MODE), 0, 2)
	cfg.SCROLL_GAS_GRADUAL        = getb("scroll_gas_gradual",        cfg.SCROLL_GAS_GRADUAL)

	-- [ABS]
	cfg.ABS_ENABLED   = getb("abs_enabled",  cfg.ABS_ENABLED)
	cfg.ABS_MIN_SPEED = getf("abs_min_speed", cfg.ABS_MIN_SPEED)
	cfg.ABS_LEVEL     = geti("abs_level",     cfg.ABS_LEVEL)
	cfg.ABS_NDSLIP_DIV = getf("abs_ndslip_div", cfg.ABS_NDSLIP_DIV)

	if cfg.ABS_LEVEL == 0 then
		-- Modo manual: lê da ini e converte para escala interna
		cfg.ABS_THRESHOLD    = clamp(geti("abs_threshold", 26), 1,  100) * 0.001
		cfg.ABS_MIN_BRAKE    = clamp(geti("abs_min_brake",  65), 0,  100) * 0.001
		cfg.ABS_INTENSITY    = getf("abs_intensity", cfg.ABS_INTENSITY)
		cfg.ABS_SMOOTH       = getf("abs_smooth",    cfg.ABS_SMOOTH)
		cfg.ABS_CURVE_FACTOR = clamp(geti("abs_curve_factor", cfg.ABS_CURVE_FACTOR), 0, 10)
	else
		cfg.applyAbsLevel()
	end
	-- Estes sempre lidos da ini (podem sobrescrever o preset)
	cfg.ABS_REAR_BIAS         = clamp(geti("abs_rear_bias",         cfg.ABS_REAR_BIAS),         0, 10)
	cfg.ABS_TRAIL_BRAKE       = clamp(geti("abs_trail_brake",       cfg.ABS_TRAIL_BRAKE),       0, 10)
	cfg.ABS_TRAIL_BRAKE_START = clamp(geti("abs_trail_brake_start", cfg.ABS_TRAIL_BRAKE_START), 0, 10)
	cfg.ABS_BRAKE_RECOVERY    = clamp(geti("abs_brake_recovery",    cfg.ABS_BRAKE_RECOVERY),    0, 10)

	-- [TC]
	cfg.TC_ENABLED   = getb("tc_enabled",  cfg.TC_ENABLED)
	cfg.TC_MIN_SPEED = clamp(geti("tc_min_speed", 10), 0, 100)
	cfg.TC_LEVEL     = geti("tc_level",    cfg.TC_LEVEL)
	cfg.TC_NDSLIP_DIV       = clamp(geti("tc_ndslip_div",        24), 10, 50) * 0.1
	cfg.TC_SLIP_RATIO_SCALE = clamp(geti("tc_slip_ratio_scale",   5),  0, 10) * 0.2
	cfg.TC_RECOVERY         = clamp(geti("tc_recovery",          80),  1,150) * 0.1
	if cfg.TC_LEVEL == 0 then
		cfg.TC_THRESHOLD = clamp(geti("tc_threshold", 53), 0, 100) * 0.001
		cfg.TC_MIN_GAS   = clamp(geti("tc_min_gas",   51), 0, 100) * 0.01
		cfg.TC_INTENSITY = clamp(geti("tc_intensity", 48), 1, 100) * 0.01
		cfg.TC_SMOOTH    = clamp(geti("tc_smooth",    31), 1, 100) * 0.1
	else cfg.applyTcLevel() end
	cfg.LAUNCH_ENABLED  = getb("launch_enabled",  cfg.LAUNCH_ENABLED)
	cfg.LAUNCH_RPM      = clamp(getf("launch_rpm",      cfg.LAUNCH_RPM),      1000, 20000)
	cfg.LAUNCH_CUT_TIME = clamp(getf("launch_cut_time", cfg.LAUNCH_CUT_TIME), 130,  500)
	cfg.CRUISE_ENABLED    = getb("cruise_enabled",    cfg.CRUISE_ENABLED)
	cfg.CRUISE_FULL_SPEED = clamp(getf("cruise_full_speed", cfg.CRUISE_FULL_SPEED), 10.0, 120.0)
	cfg.CRUISE_GAS_MIN    = clamp(getf("cruise_gas_min",    cfg.CRUISE_GAS_MIN),    0.10,  1.00)
	cfg.CRUISE_BRAKE_MIN  = clamp(getf("cruise_brake_min",  cfg.CRUISE_BRAKE_MIN),  0.10,  1.00)
	-- [KEYBINDS]
	cfg.KEY_CLUTCH            = geti("key_clutch",            cfg.KEY_CLUTCH)
	cfg.KEY_HANDBRAKE         = geti("key_handbrake",         cfg.KEY_HANDBRAKE)
	cfg.KEY_TOGGLE_ABS        = geti("key_toggle_abs",        cfg.KEY_TOGGLE_ABS)
	cfg.KEY_TOGGLE_TC         = geti("key_toggle_tc",         cfg.KEY_TOGGLE_TC)
	cfg.KEY_TOGGLE_LAUNCH     = geti("key_toggle_launch",     cfg.KEY_TOGGLE_LAUNCH)
	cfg.KEY_TOGGLE_CRUISE     = geti("key_toggle_cruise",     cfg.KEY_TOGGLE_CRUISE)
	cfg.KEY_TOGGLE_AUTOCLUTCH = geti("key_toggle_autoclutch", cfg.KEY_TOGGLE_AUTOCLUTCH)
end

cfg.loadConfig()

return cfg