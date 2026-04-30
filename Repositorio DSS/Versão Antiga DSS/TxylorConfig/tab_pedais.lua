-- ========================================================================
-- DSS TAB: PEDAIS
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local u    = require "cfg_ui"

local M = {}

function M.draw()
	u.header('ACELERADOR')
	u.cfgSlider('Pressionar', 'gas_press', 0.5, 10.0, '%.1f',
		'Velocidade ao pisar o acelerador.')
	u.cfgSlider('Soltar', 'gas_release', 0.5, 10.0, '%.1f',
		'Velocidade ao soltar o acelerador.')

	u.header('FREIO')
	u.cfgSlider('Pressionar', 'brake_press', 0.5, 10.0, '%.1f',
		'Velocidade ao pisar o freio.')
	u.cfgSlider('Soltar', 'brake_release', 0.5, 10.0, '%.1f',
		'Velocidade ao soltar o freio.')

	u.header('EMBREAGEM MANUAL')
	u.hint('Controle via tecla C.')
	ui.offsetCursorY(2)
	u.cfgSlider('Pressionar', 'clutch_press', 0.5, 10.0, '%.1f',
		'Velocidade ao pisar a embreagem.')
	u.cfgSlider('Soltar', 'clutch_release', 0.5, 10.0, '%.1f',
		'Velocidade ao soltar a embreagem.')
	u.hint('C tem prioridade máxima sobre AutoClutch e Anti-Stall.')
end

return M