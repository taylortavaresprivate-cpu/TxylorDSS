-- ========================================================================
-- DSS CONFIG DATA
-- ========================================================================
-- Tabela cfg, defaults, level tables, SAVE_KEYS, BOOL_KEYS
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
	speed_sensi         = 1.0,
	speed_sensi_start   = 80.0,
	speed_sensi_end     = 250.0,
	gas_press           = 4.8,
	gas_release         = 4.4,
	brake_press         = 4.8,
	brake_release       = 4.4,
	clutch_press        = 4.8,
	clutch_release      = 4.8,
	scroll_gas_enabled       = false,
	scroll_gas_step          = 0.10,
	scroll_gas_decay         = 0.0,
	scroll_gas_reset_on_brake = true,
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
	nls_enabled = true,
	nls_cut_duration = 150,
	nls_cut_amount = 0.2,
	nls_min_rpm = 3000,
	nls_release_mult = 2.0,
	blip_enabled = true,
	blip_intensity = 1.5,
	blip_duration = 200,
	blip_min_rpm_diff = 200,
	blip_attack_speed = 15.0,
	blip_release_speed = 4.0,
	abs_enabled         = true,
	abs_level           = 15,
	abs_threshold       = 0.032,
	abs_min_brake       = 0.14,
	abs_min_speed       = 14.0,
	abs_intensity       = 0.42,
	abs_smooth          = 3.0,
	abs_ndslip_div      = 2.6,
	abs_curve_factor    = 0.5,
	tc_enabled          = true,
	tc_level            = 13,
	tc_threshold        = 0.053,
	tc_min_speed        = 10.0,
	tc_min_gas          = 0.51,
	tc_intensity        = 0.48,
	tc_smooth           = 3.1,
	tc_ndslip_div       = 2.4,
	launch_enabled      = false,
	launch_rpm          = 4500,
	launch_cut_time     = 200,
	cruise_enabled       = false,
	cruise_full_speed    = 30.0,
	cruise_gas_min       = 0.30,
	cruise_brake_min     = 0.25,
	ui_header_r = 0.9,  ui_header_g = 0.15, ui_header_b = 0.15,
	ui_accent_r = 1.0,  ui_accent_g = 0.3,  ui_accent_b = 0.3,
	ui_hint_r   = 0.45, ui_hint_g   = 0.45, ui_hint_b   = 0.45,
	ui_line_r   = 0.35, ui_line_g   = 0.35, ui_line_b   = 0.35,
}

M.defaults = {}
for k, v in pairs(M.cfg) do M.defaults[k] = v end

-- Estado mutável compartilhado
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
M.ABS_LEVEL_DATA = {
	[1]={0.120,0.01,0.02,0.3},[2]={0.114,0.01,0.03,0.4},[3]={0.108,0.02,0.04,0.4},
	[4]={0.100,0.02,0.05,0.5},[5]={0.092,0.03,0.06,0.5},[6]={0.084,0.03,0.07,0.6},
	[7]={0.078,0.04,0.08,0.7},[8]={0.072,0.04,0.09,0.7},[9]={0.068,0.04,0.09,0.8},
	[10]={0.064,0.05,0.10,0.9},[11]={0.060,0.05,0.10,1.0},[12]={0.052,0.08,0.18,1.5},
	[13]={0.044,0.10,0.26,2.0},[14]={0.038,0.12,0.34,2.5},[15]={0.032,0.14,0.42,3.0},
	[16]={0.026,0.16,0.50,3.3},[17]={0.021,0.18,0.60,3.6},[18]={0.016,0.20,0.70,4.0},
	[19]={0.010,0.22,0.82,4.5},[20]={0.005,0.25,0.95,5.0},
}

M.TC_LEVEL_NAMES = {
	'VDC 1000hp','Drift Semi Pro','Drift Slip Angle',
	'Quase Off','Mínimo','Muito Fraco','Fraco','Leve',
	'Leve+','Suave','Suave+','Moderado','Médio',
	'Médio+','Firme','Firme+','Forte','Forte+',
	'Agressivo','Muito Forte','Extremo','Máximo','Full',
}
M.TC_LEVEL_DATA = {
	[1]={0.200,0.92,0.04,0.4},[2]={0.155,0.85,0.08,0.6},[3]={0.120,0.78,0.14,0.9},
	[4]={0.100,0.95,0.03,1.0},[5]={0.095,0.90,0.08,1.2},[6]={0.090,0.85,0.13,1.5},
	[7]={0.085,0.80,0.18,1.7},[8]={0.079,0.76,0.23,1.9},[9]={0.074,0.71,0.28,2.2},
	[10]={0.069,0.66,0.33,2.4},[11]={0.064,0.61,0.38,2.6},[12]={0.058,0.56,0.43,2.9},
	[13]={0.053,0.51,0.48,3.1},[14]={0.048,0.46,0.53,3.3},[15]={0.043,0.41,0.58,3.6},
	[16]={0.037,0.37,0.63,3.8},[17]={0.032,0.32,0.68,4.0},[18]={0.027,0.27,0.73,4.3},
	[19]={0.022,0.22,0.78,4.5},[20]={0.016,0.17,0.83,4.7},[21]={0.011,0.12,0.88,5.0},
	[22]={0.006,0.07,0.93,5.2},[23]={0.001,0.02,0.98,5.5},
}

-- ========================================================================
-- SAVE KEYS / BOOL KEYS
-- ========================================================================

M.SAVE_KEYS = {
	'ffb_enabled','ffb_gain','steer_sensi','gyro_gain',
	'steer_limit','steer_gamma','steer_filter','steer_counter_steer',
	'speed_sensi','speed_sensi_start','speed_sensi_end',
	'gas_press','gas_release','brake_press','brake_release',
	'clutch_press','clutch_release',
	'scroll_gas_enabled','scroll_gas_step','scroll_gas_decay','scroll_gas_reset_on_brake',
	'autoclutch_enabled','autoclutch_depth',
	'autoclutch_press_speed','autoclutch_release_speed',
	'antistall_enabled','antistall_full_speed','antistall_min_speed',
	'antistall_engage_speed','antistall_disengage_speed',
	'antistall_gamma','antistall_max_press',
	'antistall_bite_point','antistall_target_smooth',
	'nls_enabled','nls_cut_duration','nls_cut_amount','nls_min_rpm','nls_release_mult',
	'blip_enabled','blip_intensity','blip_duration','blip_min_rpm_diff',
	'blip_attack_speed','blip_release_speed',
	'abs_enabled','abs_level','abs_threshold','abs_min_brake',
	'abs_min_speed','abs_intensity','abs_smooth','abs_ndslip_div','abs_curve_factor',
	'tc_enabled','tc_level','tc_threshold','tc_min_speed',
	'tc_min_gas','tc_intensity','tc_smooth','tc_ndslip_div',
	'launch_enabled','launch_rpm','launch_cut_time',
	'cruise_enabled','cruise_full_speed','cruise_gas_min','cruise_brake_min',
	'ui_header_r','ui_header_g','ui_header_b',
	'ui_accent_r','ui_accent_g','ui_accent_b',
	'ui_hint_r','ui_hint_g','ui_hint_b',
	'ui_line_r','ui_line_g','ui_line_b',
}

M.BOOL_KEYS = {
	abs_enabled=true, tc_enabled=true, ffb_enabled=true,
	autoclutch_enabled=true, launch_enabled=true,
	antistall_enabled=true, nls_enabled = true, nls_only_upshift=true,
	blip_enabled = true, blip_only_braking=true,
	cruise_enabled=true, scroll_gas_enabled=true, scroll_gas_reset_on_brake=true,
}

return M