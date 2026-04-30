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
cfg.STEER_DEADZONE       = 0.0
cfg.STEER_REVERSAL_LIMIT = 2.5
cfg.ROAD_FEEL_ENABLED    = false
cfg.ROAD_FEEL_GAIN       = 1.5
cfg.ROAD_FEEL_FRONT      = 2.1
cfg.ROAD_FEEL_REAR       = 0.9
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
	cfg.ANTISTALL_GAMMA           = 1.2
	cfg.ANTISTALL_MAX_PRESS       = 1.0
	cfg.ANTISTALL_BITE_POINT      = 0.5
	cfg.ANTISTALL_TARGET_SMOOTH   = 0.92
	cfg.ANTISTALL_RPM_MARGIN      = 0.15
	cfg.ANTISTALL_RPM_HYSTERESIS  = 0.05
	cfg.ANTISTALL_REVERSE_SPEED   = 10.0
	cfg.BLIP_ENABLED       = true
	cfg.BLIP_MODE          = 0      -- 0=Automático (Gear Ratio), 1=Manual
	cfg.BLIP_INTENSITY     = 10     -- UI 1-10  (físico: ×0.1)
	cfg.BLIP_DURATION      = 300    -- UI 50-500 ms (1:1)
	cfg.BLIP_SENSITIVITY   = 40     -- UI 1-100 (físico: ×50)
	cfg.BLIP_MIN_RPM       = 1500   -- RPM mínimo absoluto para ativar blip
	cfg.BLIP_ATTACK_SPEED  = 3      -- UI 1-10  (físico: ×5.0)
	cfg.BLIP_RELEASE_SPEED = 1      -- UI 1-10  (físico: ×4.0)
cfg.NLS_ENABLED       = true
cfg.NLS_CUT_DURATION  = 150
cfg.NLS_CUT_AMOUNT    = 0.2
cfg.NLS_MIN_RPM       = 3000
cfg.NLS_RELEASE_MULT  = 2.0
cfg.NLS_ADAPTIVE_DURATION = true

-- [SCROLL GAS]
cfg.SCROLL_GAS_ENABLED        = false
cfg.SCROLL_GAS_STEP           = 0.10
cfg.SCROLL_GAS_DECAY          = 0.0
cfg.SCROLL_GAS_RESET_ON_BRAKE = true
cfg.SCROLL_GAS_MAX_SPEED      = 0.0
cfg.SCROLL_GAS_INVERT         = false
cfg.SCROLL_GAS_MODE           = 2
cfg.SCROLL_GAS_GRADUAL        = false

-- [ABS] — valores em escala UI (inteiros)
	cfg.ABS_ENABLED      = true
	cfg.ABS_LEVEL        = 15
	cfg.ABS_THRESHOLD    = 32     -- UI: 1-100   (interno: ×0.001)
	cfg.ABS_MIN_SPEED    = 14
	cfg.ABS_MIN_BRAKE    = 14     -- UI: 0-100   (interno: ×0.001)
	cfg.ABS_INTENSITY    = 42     -- UI: 1-100   (interno: ×0.01)
	cfg.ABS_SMOOTH       = 30     -- UI: 1-100   (interno: ×0.1)
	cfg.ABS_NDSLIP_DIV   = 2.6
	cfg.ABS_CURVE_FACTOR = 5      -- UI: 0-20    (interno: ×0.1)
	cfg.ABS_TRAIL_BRAKE       = 0  -- UI: 0-10    (interno: /10)
	cfg.ABS_TRAIL_BRAKE_START = 0  -- UI: 0-10    (interno: /10*0.9)
	cfg.ABS_BRAKE_RECOVERY    = 0  -- UI: 0-100   (0=Smooth, >0=0.5+×0.05)
	cfg.ABS_REAR_BIAS         = 0  -- UI: 0-10    (interno: /10)

-- [TC]
cfg.TC_ENABLED      = true
cfg.TC_LEVEL        = 13
cfg.TC_THRESHOLD    = 0.080   -- UI 40 × 0.002
cfg.TC_MIN_SPEED    = 10
cfg.TC_MIN_GAS      = 0.58    -- UI 58 × 0.01
cfg.TC_INTENSITY    = 0.32    -- UI 32 × 0.01
cfg.TC_SMOOTH       = 2.0     -- UI 20 × 0.1
cfg.TC_NDSLIP_DIV   = 2.4     -- UI 24 × 0.1
cfg.TC_CURVE_FACTOR = 0.3     -- UI 0-10  (físico: ×0.1)  relaxa threshold proporcional ao esterço
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
cfg.KEY_FFB_GAIN_UP       = 0
cfg.KEY_FFB_GAIN_DOWN     = 0

-- ========================================================================
-- TABELAS DE NÍVEIS
-- ========================================================================
-- {threshold, min_brake, intensity, smooth, trail_brake, trail_start, brake_recovery, rear_bias}
local ABS_LEVELS = {
	[1] ={100,10, 2, 3, 0,0,0,0}, [2] ={100,10, 3, 4, 0,0,0,0}, [3] ={100,20, 4, 4, 0,0,0,0},
	[4] ={100,20, 5, 5, 0,0,0,0}, [5] ={ 92,30, 6, 5, 0,0,0,0}, [6] ={ 84,30, 7, 6, 0,0,0,0},
	[7] ={ 78,40, 8, 7, 0,0,0,0}, [8] ={ 72,40, 9, 7, 0,0,0,0}, [9] ={ 68,40, 9, 8, 0,0,0,0},
	[10]={ 64,50,10, 9, 0,0,0,0}, [11]={ 60,50,10,10, 0,0,0,0}, [12]={ 52,80,18,15, 0,0,0,0},
	[13]={ 44,100,26,20, 0,0,0,0},[14]={ 38,100,34,25, 0,0,0,0},[15]={ 32,100,42,30, 0,0,0,0},
	[16]={ 26,100,50,33, 0,0,0,0},[17]={ 21,100,60,36, 0,0,0,0},[18]={ 16,100,70,40, 0,0,0,0},
	[19]={ 10,100,82,45, 0,0,0,0},[20]={  5,100,95,50, 0,0,0,0},
}

function cfg.applyAbsLevel()
	if cfg.ABS_LEVEL >= 1 and cfg.ABS_LEVEL <= 20 then
		local l = ABS_LEVELS[cfg.ABS_LEVEL]
		cfg.ABS_THRESHOLD         = l[1]
		cfg.ABS_MIN_BRAKE         = l[2]
		cfg.ABS_INTENSITY         = l[3]
		cfg.ABS_SMOOTH            = l[4]
		cfg.ABS_TRAIL_BRAKE       = l[5]
		cfg.ABS_TRAIL_BRAKE_START = l[6]
		cfg.ABS_BRAKE_RECOVERY    = l[7]
		cfg.ABS_REAR_BIAS         = l[8]
	end
end

-- {TC_THRESHOLD, TC_MIN_GAS, TC_INTENSITY, TC_SMOOTH} — escala física (espelha cfg_data.TC_LEVEL_DATA × escala)
local TC_LEVELS = {
	[1] ={0.200,0.99,0.01,0.3}, [2] ={0.190,0.98,0.03,0.4}, [3] ={0.180,0.96,0.05,0.5},
	[4] ={0.170,0.93,0.08,0.6}, [5] ={0.160,0.90,0.10,0.7}, [6] ={0.150,0.86,0.12,0.8},
	[7] ={0.140,0.82,0.15,0.9}, [8] ={0.130,0.78,0.17,1.1}, [9] ={0.120,0.74,0.20,1.3},
	[10]={0.110,0.70,0.22,1.4}, [11]={0.100,0.66,0.25,1.6}, [12]={0.090,0.62,0.28,1.8},
	[13]={0.080,0.58,0.32,2.0}, [14]={0.070,0.54,0.36,2.2}, [15]={0.060,0.50,0.40,2.4},
	[16]={0.050,0.46,0.45,2.6}, [17]={0.040,0.42,0.50,2.8}, [18]={0.030,0.38,0.55,3.0},
	[19]={0.020,0.32,0.60,3.3}, [20]={0.010,0.26,0.65,3.6},
}
function cfg.applyTcLevel()
	if cfg.TC_LEVEL >= 1 and cfg.TC_LEVEL <= 20 then
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
	cfg.STEER_DEADZONE       = clamp(getf("steer_deadzone", 0.0), 0.0, 10.0) * 0.03
	cfg.STEER_REVERSAL_LIMIT = clamp(getf("steer_reversal_limit", 2.5), 0.5, 10.0)
	cfg.ROAD_FEEL_ENABLED    = getb("road_feel_enabled", cfg.ROAD_FEEL_ENABLED)
	cfg.ROAD_FEEL_GAIN       = clamp(getf("road_feel_gain",  5.0), 0.0, 10.0) * 0.3
	cfg.ROAD_FEEL_FRONT      = clamp(getf("road_feel_front", 7.0), 0.0, 10.0) * 0.3
	cfg.ROAD_FEEL_REAR       = clamp(getf("road_feel_rear",  3.0), 0.0, 10.0) * 0.3
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
	cfg.ANTISTALL_ENGAGE_SPEED    = clamp(getf("antistall_engage_speed",    cfg.ANTISTALL_ENGAGE_SPEED),    0.5,  10.0)
	cfg.ANTISTALL_DISENGAGE_SPEED = clamp(getf("antistall_disengage_speed", cfg.ANTISTALL_DISENGAGE_SPEED), 0.5,  10.0)
	cfg.ANTISTALL_GAMMA           = getf("antistall_gamma",           cfg.ANTISTALL_GAMMA)
	cfg.ANTISTALL_MAX_PRESS       = getf("antistall_max_press",       cfg.ANTISTALL_MAX_PRESS)
	cfg.ANTISTALL_BITE_POINT      = getf("antistall_bite_point",      cfg.ANTISTALL_BITE_POINT)
	cfg.ANTISTALL_TARGET_SMOOTH   = getf("antistall_target_smooth",   cfg.ANTISTALL_TARGET_SMOOTH)
	cfg.ANTISTALL_RPM_MARGIN      = clamp(getf("antistall_rpm_margin",      cfg.ANTISTALL_RPM_MARGIN),      0.05, 0.50)
	cfg.ANTISTALL_RPM_HYSTERESIS  = clamp(getf("antistall_rpm_hysteresis",  cfg.ANTISTALL_RPM_HYSTERESIS),  0.0,  0.20)
	cfg.ANTISTALL_REVERSE_SPEED   = clamp(getf("antistall_reverse_speed",   cfg.ANTISTALL_REVERSE_SPEED),   0.5,  10.0)
	if cfg.ANTISTALL_FULL_SPEED <= cfg.ANTISTALL_MIN_SPEED then cfg.ANTISTALL_FULL_SPEED = cfg.ANTISTALL_MIN_SPEED + 5.0 end
	cfg.ANTISTALL_GAMMA         = clamp(cfg.ANTISTALL_GAMMA,         0.1,  10.0)
	cfg.ANTISTALL_MAX_PRESS     = clamp(cfg.ANTISTALL_MAX_PRESS,     0.0,  1.0)
	cfg.ANTISTALL_BITE_POINT    = clamp(cfg.ANTISTALL_BITE_POINT,    0.1,  1.0)
	cfg.ANTISTALL_TARGET_SMOOTH = clamp(cfg.ANTISTALL_TARGET_SMOOTH, 0.0,  0.99)
	cfg.NLS_ENABLED      = getb("nls_enabled",      cfg.NLS_ENABLED)
	cfg.NLS_CUT_DURATION = clamp(getf("nls_cut_duration", cfg.NLS_CUT_DURATION), 50,   500)
	cfg.NLS_CUT_AMOUNT   = clamp(getf("nls_cut_amount",   cfg.NLS_CUT_AMOUNT),   0.0,  1.0)
	cfg.NLS_MIN_RPM      = clamp(getf("nls_min_rpm",      cfg.NLS_MIN_RPM),      1000, 9000)
	cfg.NLS_RELEASE_MULT = clamp(getf("nls_release_mult", cfg.NLS_RELEASE_MULT), 1.0,  10.0)
	cfg.NLS_ADAPTIVE_DURATION = getb("nls_adaptive_duration", cfg.NLS_ADAPTIVE_DURATION)
	cfg.BLIP_ENABLED       = getb("blip_enabled",       cfg.BLIP_ENABLED)
	cfg.BLIP_MODE          = clamp(geti("blip_mode",          cfg.BLIP_MODE),          0,    1)
	-- Conversão de valores antigos (float) para novos (inteiros)
	local rawIntensity = getf("blip_intensity", cfg.BLIP_INTENSITY)
	if rawIntensity < 1 then rawIntensity = math.floor(rawIntensity * 10 + 0.5) end
	cfg.BLIP_INTENSITY     = clamp(rawIntensity, 1, 10)
	cfg.BLIP_DURATION      = clamp(geti("blip_duration",      cfg.BLIP_DURATION),      50,   500)
	local rawSensitivity = getf("blip_sensitivity", cfg.BLIP_SENSITIVITY)
	if rawSensitivity > 100 then rawSensitivity = math.floor(rawSensitivity / 50 + 0.5) end
	cfg.BLIP_SENSITIVITY   = clamp(rawSensitivity, 1, 100)
	cfg.BLIP_MIN_RPM       = clamp(geti("blip_min_rpm",       cfg.BLIP_MIN_RPM),       500,  20000)
	local rawAttack = getf("blip_attack_speed", cfg.BLIP_ATTACK_SPEED)
	if rawAttack > 10 then rawAttack = math.floor(rawAttack / 5.0 + 0.5) end
	cfg.BLIP_ATTACK_SPEED  = clamp(rawAttack, 1, 10)
	local rawRelease = getf("blip_release_speed", cfg.BLIP_RELEASE_SPEED)
	if rawRelease > 10 then rawRelease = math.floor(rawRelease / 4.0 + 0.5) end
	cfg.BLIP_RELEASE_SPEED = clamp(rawRelease, 1, 10)
	cfg.SCROLL_GAS_ENABLED        = getb("scroll_gas_enabled",        cfg.SCROLL_GAS_ENABLED)
	cfg.SCROLL_GAS_STEP           = getf("scroll_gas_step",           cfg.SCROLL_GAS_STEP)
	cfg.SCROLL_GAS_DECAY          = getf("scroll_gas_decay",          cfg.SCROLL_GAS_DECAY)
	cfg.SCROLL_GAS_RESET_ON_BRAKE = getb("scroll_gas_reset_on_brake", cfg.SCROLL_GAS_RESET_ON_BRAKE)
	cfg.SCROLL_GAS_MAX_SPEED      = getf("scroll_gas_max_speed",      cfg.SCROLL_GAS_MAX_SPEED)
	cfg.SCROLL_GAS_INVERT         = getb("scroll_gas_invert",         cfg.SCROLL_GAS_INVERT)
	cfg.SCROLL_GAS_MODE           = clamp(getf("scroll_gas_mode",     cfg.SCROLL_GAS_MODE), 0, 2)
	cfg.SCROLL_GAS_GRADUAL        = getb("scroll_gas_gradual",        cfg.SCROLL_GAS_GRADUAL)

	-- [ABS]
	cfg.ABS_ENABLED      = getb("abs_enabled",      cfg.ABS_ENABLED)
	cfg.ABS_MIN_SPEED    = getf("abs_min_speed",    cfg.ABS_MIN_SPEED)
	cfg.ABS_LEVEL        = geti("abs_level",        cfg.ABS_LEVEL)
	cfg.ABS_NDSLIP_DIV   = getf("abs_ndslip_div",   cfg.ABS_NDSLIP_DIV)
	cfg.ABS_CURVE_FACTOR = clamp(geti("abs_curve_factor", cfg.ABS_CURVE_FACTOR), 0, 20)
	cfg.ABS_TRAIL_BRAKE       = clamp(geti("abs_trail_brake",       cfg.ABS_TRAIL_BRAKE),       0, 10)
	cfg.ABS_TRAIL_BRAKE_START = clamp(geti("abs_trail_brake_start", cfg.ABS_TRAIL_BRAKE_START), 0, 10)
	cfg.ABS_BRAKE_RECOVERY    = clamp(geti("abs_brake_recovery",    cfg.ABS_BRAKE_RECOVERY),    0, 100)
	cfg.ABS_REAR_BIAS         = clamp(geti("abs_rear_bias",         cfg.ABS_REAR_BIAS),         0, 10)
	if cfg.ABS_LEVEL == 0 then
		cfg.ABS_THRESHOLD = clamp(geti("abs_threshold", cfg.ABS_THRESHOLD), 1, 100)
		cfg.ABS_MIN_BRAKE = clamp(geti("abs_min_brake", cfg.ABS_MIN_BRAKE), 0, 100)
		cfg.ABS_INTENSITY = clamp(geti("abs_intensity", cfg.ABS_INTENSITY), 1, 100)
		cfg.ABS_SMOOTH    = clamp(geti("abs_smooth",    cfg.ABS_SMOOTH),    1, 100)
	else
		cfg.applyAbsLevel()
	end

	-- [TC]
	cfg.TC_ENABLED   = getb("tc_enabled",  cfg.TC_ENABLED)
	cfg.TC_MIN_SPEED = clamp(geti("tc_min_speed", 10), 0, 100)
	cfg.TC_LEVEL     = clamp(geti("tc_level", cfg.TC_LEVEL), 0, 20)
	cfg.TC_NDSLIP_DIV   = clamp(geti("tc_ndslip_div",   24), 10, 50) * 0.1
	cfg.TC_CURVE_FACTOR = clamp(geti("tc_curve_factor",  3),  0,  10) * 0.1
	if cfg.TC_LEVEL == 0 then
		cfg.TC_THRESHOLD = clamp(geti("tc_threshold", 40), 0, 100) * 0.002
		cfg.TC_MIN_GAS   = clamp(geti("tc_min_gas",   58), 0, 100) * 0.01
		cfg.TC_INTENSITY = clamp(geti("tc_intensity", 32), 1, 100) * 0.01
		cfg.TC_SMOOTH    = clamp(geti("tc_smooth",    20), 1, 100) * 0.1
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
	cfg.KEY_FFB_GAIN_UP       = geti("key_ffb_gain_up",       cfg.KEY_FFB_GAIN_UP)
	cfg.KEY_FFB_GAIN_DOWN     = geti("key_ffb_gain_down",     cfg.KEY_FFB_GAIN_DOWN)
end

cfg.loadConfig()

return cfg