-- ========================================================================
-- DSS TAB: PEDAIS
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local u    = require "cfg_ui"

local M = {}

function M.draw()
	u.header('ACELERADOR')
	u.cfgSlider('Pressionar', 'gas_press',   1.0, 10.0, '%.1f',
		'Velocidade ao pisar o acelerador. 10.0 = instantâneo.')
	u.cfgSlider('Soltar',     'gas_release', 1.0, 10.0, '%.1f',
		'Velocidade ao soltar o acelerador. 10.0 = instantâneo.')
	u.cfgSlider('Limite',     'gas_max',       0, 100,  '%.0f%%',
		'Limite máximo do acelerador. 50%% = batente em 50%% do curso.')

	u.header('FREIO')
	u.cfgSlider('Pressionar', 'brake_press',   1.0, 10.0, '%.1f',
		'Velocidade ao pisar o freio. 10.0 = instantâneo.')
	u.cfgSlider('Soltar',     'brake_release', 1.0, 10.0, '%.1f',
		'Velocidade ao soltar o freio. 10.0 = instantâneo.')
	u.cfgSlider('Limite',     'brake_max',       0, 100,  '%.0f%%',
		'Limite máximo do freio. 50%% = batente em 50%% do curso.')

	u.header('EMBREAGEM MANUAL')
	u.hint('Tecla configurável na aba KEYBINDS.')
	ui.offsetCursorY(2)
	u.cfgSlider('Pressionar', 'clutch_press',   1.0, 10.0, '%.1f',
		'Velocidade ao pisar a embreagem. 10.0 = instantâneo.')
	u.cfgSlider('Soltar',     'clutch_release', 1.0, 10.0, '%.1f',
		'Velocidade ao soltar a embreagem. 10.0 = instantâneo.')
	u.cfgSlider('Limite',     'clutch_max',       0, 100,  '%.0f%%',
		'Limite máximo de pressão da embreagem manual.')
	u.hint('Tem prioridade máxima sobre AutoClutch e Anti-Stall.')

	u.header('FREIO DE MÃO')
	u.hint('Tecla configurável na aba KEYBINDS.')
	ui.offsetCursorY(2)
	u.cfgSlider('Pressionar', 'handbrake_press',   1.0, 10.0, '%.1f',
		'Velocidade ao puxar o freio de mão. 10.0 = instantâneo.')
	u.cfgSlider('Soltar',     'handbrake_release', 1.0, 10.0, '%.1f',
		'Velocidade ao soltar o freio de mão. 10.0 = instantâneo.')
	u.cfgSlider('Limite',     'handbrake_max',       0, 100,  '%.0f%%',
		'Limite máximo do freio de mão.')
end

return M