-- ========================================================================
-- DSS CONFIG DATA
-- ========================================================================

local M = {}

M.cfg = {
	ffb_enabled         = true,
	ffb_gain            = 0.8,
	steer_sensi         = 65.0,
	gyro_gain           = 8.0,
	steer_limit         = 1.0,
	steer_gamma         = 1.0,
	steer_filter        = 0.0,
	steer_counter_steer = 2.0,
	ffb_damper          = 1.7,
	ffb_lateral         = 1.5,
	steer_deadzone      = 0.0,
	steer_reversal_limit = 2.5,
	speed_sensi         = 1.0,
	speed_sensi_start   = 80.0,
	speed_sensi_end     = 250.0,
	gas_press           = 4.8,
	gas_release         = 4.4,
	gas_max             = 100,
	brake_press         = 4.8,
	brake_release       = 4.4,
	brake_max           = 100,
	clutch_press        = 4.8,
	clutch_release      = 4.8,
	clutch_max          = 100,
	handbrake_press     = 8.0,
	handbrake_release   = 8.0,
	handbrake_max       = 100,
	-- [SCROLL GAS]
	scroll_gas_enabled        = false,
	scroll_gas_step           = 0.10,
	scroll_gas_decay          = 0.0,
	scroll_gas_reset_on_brake = true,
	scroll_gas_max_speed      = 0.0,
	scroll_gas_invert         = false,
	scroll_gas_mode           = 2,
	scroll_gas_gradual        = false,
	autoclutch_enabled       = true,
	autoclutch_depth         = 1.0,
	autoclutch_press_speed   = 10.0,
	autoclutch_release_speed = 5.0,
	antistall_enabled         = true,
	antistall_full_speed      = 30.0,
	antistall_min_speed       = 2.0,
	antistall_engage_speed    = 1.8,
	antistall_disengage_speed = 2.5,
	antistall_gamma           = 1.0,
	antistall_max_press       = 1.0,
	antistall_bite_point      = 0.5,
	antistall_target_smooth   = 0.92,
	antistall_rpm_margin      = 15,
	antistall_rpm_hysteresis  = 5,
	antistall_reverse_speed   = 10.0,
	nls_enabled      = true,
	nls_cut_duration = 150,
	nls_cut_amount   = 0.2,
	nls_min_rpm      = 3000,
	nls_release_mult = 2.0,
	nls_adaptive_duration = true,
	blip_enabled       = true,
	blip_mode          = 0,      -- 0=Automático (Gear Ratio), 1=Manual
	blip_intensity     = 10,     -- UI 1-10  (físico: ×0.1)
	blip_duration      = 300,    -- UI 50-500 ms (1:1)
	blip_sensitivity   = 40,     -- UI 1-100 (físico: ×50)
	blip_min_rpm       = 1500,   -- UI: RPM mínimo absoluto para ativar blip
	blip_attack_speed  = 3,      -- UI 1-10  (físico: ×5.0)
	blip_release_speed = 1,      -- UI 1-10  (físico: ×4.0)
	-- [ABS] — valores em escala UI (inteiros)
	abs_enabled           = true,
	abs_level             = 15,
	abs_threshold         = 32,    -- UI: 1-100   (interno: ×0.001)
	abs_min_brake         = 14,    -- UI: 0-100   (interno: ×0.001)
	abs_min_speed         = 14.0,
	abs_intensity         = 42,    -- UI: 1-100   (interno: ×0.01)
	abs_smooth            = 30,    -- UI: 1-100   (interno: ×0.1)
	abs_ndslip_div        = 2.6,
	abs_curve_factor      = 5,     -- UI: 0-20    (interno: ×0.1)
	abs_trail_brake       = 0,     -- UI: 0-10    (interno: /10)
	abs_trail_brake_start = 0,     -- UI: 0-10    (interno: /10*0.9)
	abs_brake_recovery    = 0,     -- UI: 0-100   (interno: 0=Smooth, >0=0.5+×0.05)
	abs_rear_bias         = 0,     -- UI: 0-10    (interno: /10)
	-- [TC] — valores em escala UI (inteiros)
	tc_enabled      = true,
	tc_level        = 13,   -- 1..20 (13 = Padrão), 0 = Manual
	tc_threshold    = 40,   -- UI: 0-100   (interno: ×0.002)
	tc_min_speed    = 10,   -- UI: 0-100 km/h (1:1)
	tc_min_gas      = 58,   -- UI: 0-100   (interno: ×0.01)
	tc_intensity    = 32,   -- UI: 1-100   (interno: ×0.01)
	tc_smooth       = 20,   -- UI: 1-100   (interno: ×0.1)
	tc_ndslip_div   = 24,   -- UI: 10-50   (interno: ×0.1)
	tc_curve_factor = 3,    -- UI: 0-10    (interno: ×0.1)  relaxa threshold em curva
	launch_enabled  = false,
	launch_rpm      = 4500,
	launch_cut_time = 200,
	cruise_enabled    = false,
	cruise_full_speed = 30.0,
	cruise_gas_min    = 0.30,
	cruise_brake_min  = 0.25,
	-- [KEYBINDS]
	key_clutch            = 67,
	key_handbrake         = 32,
	key_toggle_abs        = 0,
	key_toggle_tc         = 0,
	key_toggle_launch     = 0,
	key_toggle_cruise     = 0,
	key_toggle_autoclutch = 0,
	key_ffb_gain_up       = 0,
	key_ffb_gain_down     = 0,
	-- [UI]
	ui_header_r = 0.9,  ui_header_g = 0.15, ui_header_b = 0.15,
	ui_accent_r = 1.0,  ui_accent_g = 0.3,  ui_accent_b = 0.3,
	ui_hint_r   = 0.45, ui_hint_g   = 0.45, ui_hint_b   = 0.45,
	ui_line_r   = 0.35, ui_line_g   = 0.35, ui_line_b   = 0.35,
}

M.defaults = {}
for k, v in pairs(M.cfg) do M.defaults[k] = v end

M.dirty     = false
M.saveOk    = true
M.saveTimer = 0

-- ========================================================================
-- TABELAS DE NÍVEIS
-- ========================================================================

M.ABS_LEVEL_NAMES = {
	'Off','Quase Off','Ultra Fraco','Muito Fraco','Bem Fraco',
	'Fraco','Fraco+','Leve','Leve+','Suave',
	'Livre','Mínimo','Moderado','Médio','Médio+',
	'Firme','Forte','Agressivo','Máximo','Full',
}

-- {threshold, min_brake, intensity, smooth, trail_brake, trail_start, brake_recovery, rear_bias}
M.ABS_LEVEL_DATA = {
	[1] ={100,10, 2, 3, 0,0,0,0}, [2] ={100,10, 3, 4, 0,0,0,0}, [3] ={100,20, 4, 4, 0,0,0,0},
	[4] ={100,20, 5, 5, 0,0,0,0}, [5] ={ 92,30, 6, 5, 0,0,0,0}, [6] ={ 84,30, 7, 6, 0,0,0,0},
	[7] ={ 78,40, 8, 7, 0,0,0,0}, [8] ={ 72,40, 9, 7, 0,0,0,0}, [9] ={ 68,40, 9, 8, 0,0,0,0},
	[10]={ 64,50,10, 9, 0,0,0,0}, [11]={ 60,50,10,10, 0,0,0,0}, [12]={ 52,80,18,15, 0,0,0,0},
	[13]={ 44,100,26,20, 0,0,0,0},[14]={ 38,100,34,25, 0,0,0,0},[15]={ 32,100,42,30, 0,0,0,0},
	[16]={ 26,100,50,33, 0,0,0,0},[17]={ 21,100,60,36, 0,0,0,0},[18]={ 16,100,70,40, 0,0,0,0},
	[19]={ 10,100,82,45, 0,0,0,0},[20]={  5,100,95,50, 0,0,0,0},
}

M.TC_LEVEL_NAMES = {
	'Quase Off','Mínimo','Leve','Fraco','Fraco+',
	'Suave','Suave+','Moderado','Moderado+','Médio-',
	'Médio','Médio+','Firme-','Firme','Firme+',
	'Forte','Forte+','Seguro','Seguro+','Máximo',
}
-- {tc_threshold(UI 0-100), tc_min_gas(UI 0-100), tc_intensity(UI 1-100), tc_smooth(UI 1-100)}
M.TC_LEVEL_DATA = {
	[1] ={100,99, 1, 3}, [2] ={ 95,98, 3, 4}, [3] ={ 90,96, 5, 5},
	[4] ={ 85,93, 8, 6}, [5] ={ 80,90,10, 7}, [6] ={ 75,86,12, 8},
	[7] ={ 70,82,15, 9}, [8] ={ 65,78,17,11}, [9] ={ 60,74,20,13},
	[10]={ 55,70,22,14}, [11]={ 50,66,25,16}, [12]={ 45,62,28,18},
	[13]={ 40,58,32,20}, [14]={ 35,54,36,22}, [15]={ 30,50,40,24},
	[16]={ 25,46,45,26}, [17]={ 20,42,50,28}, [18]={ 15,38,55,30},
	[19]={ 10,32,60,33}, [20]={  5,26,65,36},
}

-- ========================================================================
-- SAVE KEYS / BOOL KEYS
-- ========================================================================

M.SAVE_KEYS = {
	'ffb_enabled','ffb_gain','steer_sensi','gyro_gain',
	'steer_limit','steer_gamma','steer_filter','steer_counter_steer',
	'ffb_damper','ffb_lateral','steer_deadzone','steer_reversal_limit',
	'speed_sensi','speed_sensi_start','speed_sensi_end',
	'gas_press','gas_release','gas_max',
	'brake_press','brake_release','brake_max',
	'clutch_press','clutch_release','clutch_max',
	'handbrake_press','handbrake_release','handbrake_max',
	'scroll_gas_enabled','scroll_gas_step','scroll_gas_decay',
	'scroll_gas_reset_on_brake','scroll_gas_max_speed',
	'scroll_gas_invert','scroll_gas_mode','scroll_gas_gradual',
	'autoclutch_enabled','autoclutch_depth',
	'autoclutch_press_speed','autoclutch_release_speed',
	'antistall_enabled','antistall_full_speed','antistall_min_speed',
	'antistall_engage_speed','antistall_disengage_speed',
	'antistall_gamma','antistall_max_press',
	'antistall_bite_point','antistall_target_smooth',
	'antistall_rpm_margin','antistall_rpm_hysteresis','antistall_reverse_speed',
	'nls_enabled','nls_cut_duration','nls_cut_amount','nls_min_rpm','nls_release_mult','nls_adaptive_duration',
	'blip_enabled','blip_mode','blip_intensity','blip_duration','blip_sensitivity',
	'blip_min_rpm','blip_attack_speed','blip_release_speed',
	'abs_enabled','abs_level','abs_threshold','abs_min_brake',
	'abs_min_speed','abs_intensity','abs_smooth','abs_ndslip_div','abs_curve_factor',
	'abs_trail_brake','abs_trail_brake_start','abs_brake_recovery','abs_rear_bias',
	'tc_enabled','tc_level','tc_threshold','tc_min_speed',
	'tc_min_gas','tc_intensity','tc_smooth','tc_ndslip_div','tc_curve_factor',
	'launch_enabled','launch_rpm','launch_cut_time',
	'cruise_enabled','cruise_full_speed','cruise_gas_min','cruise_brake_min',
	'key_clutch','key_handbrake',
	'key_toggle_abs','key_toggle_tc','key_toggle_launch',
	'key_toggle_cruise','key_toggle_autoclutch',
	'key_ffb_gain_up','key_ffb_gain_down',
	'ui_header_r','ui_header_g','ui_header_b',
	'ui_accent_r','ui_accent_g','ui_accent_b',
	'ui_hint_r','ui_hint_g','ui_hint_b',
	'ui_line_r','ui_line_g','ui_line_b',
}

M.BOOL_KEYS = {
	abs_enabled=true, tc_enabled=true, ffb_enabled=true,
	autoclutch_enabled=true, launch_enabled=true,
	antistall_enabled=true,
	nls_enabled=true, nls_adaptive_duration=true, nls_only_upshift=true,
	blip_enabled=true, blip_only_braking=true,
	cruise_enabled=true, scroll_gas_enabled=true,
	scroll_gas_reset_on_brake=true, scroll_gas_invert=true,
	scroll_gas_gradual=true,
	road_feel_enabled=true,
}

return M