-- ========================================================================
-- DSS TAB: SOBRE
-- ========================================================================

local data     = require "cfg_data"
local cfg      = data.cfg
local defaults = data.defaults
local u        = require "cfg_ui"

local M = {}

function M.draw()
	u.header('DYNAMIC STEERING SYSTEM')
	u.info('Versão: 6.1.0')
	u.info('Autor: Txylor')
	u.info('Discord: taylortavares_')
	ui.offsetCursorY(8)
	u.hint('Mouse steering com FFB, ABS, TC,')
	u.hint('Anti-Stall, AutoClutch, No-Lift Shift,')
	u.hint('Auto-Blip, Cruise Mode e Launch Control.')

	u.header('PERSONALIZAÇÃO DA INTERFACE')
	u.hint('Edite as cores em tempo real.')
	ui.offsetCursorY(6)

	-- Header color
	ui.text('  Cor dos Headers:')
	ui.offsetCursorY(2)
	ui.setNextItemWidth(u.getSliderWidth())
	local hr = ui.slider('##ui_hdr_r', cfg.ui_header_r, 0, 1, 'R: %.2f')
	if ui.itemEdited() then cfg.ui_header_r = hr; data.dirty = true end
	ui.setNextItemWidth(u.getSliderWidth())
	local hg = ui.slider('##ui_hdr_g', cfg.ui_header_g, 0, 1, 'G: %.2f')
	if ui.itemEdited() then cfg.ui_header_g = hg; data.dirty = true end
	ui.setNextItemWidth(u.getSliderWidth())
	local hb = ui.slider('##ui_hdr_b', cfg.ui_header_b, 0, 1, 'B: %.2f')
	if ui.itemEdited() then cfg.ui_header_b = hb; data.dirty = true end
	local prev = ui.getCursor()
	ui.drawRectFilled(prev, prev + vec2(u.getSliderWidth(), 4), u.getColHeader())
	ui.offsetCursorY(8)

	-- Accent color
	ui.text('  Cor de Destaque:')
	ui.offsetCursorY(2)
	ui.setNextItemWidth(u.getSliderWidth())
	local ar = ui.slider('##ui_acc_r', cfg.ui_accent_r, 0, 1, 'R: %.2f')
	if ui.itemEdited() then cfg.ui_accent_r = ar; data.dirty = true end
	ui.setNextItemWidth(u.getSliderWidth())
	local ag = ui.slider('##ui_acc_g', cfg.ui_accent_g, 0, 1, 'G: %.2f')
	if ui.itemEdited() then cfg.ui_accent_g = ag; data.dirty = true end
	ui.setNextItemWidth(u.getSliderWidth())
	local ab2 = ui.slider('##ui_acc_b', cfg.ui_accent_b, 0, 1, 'B: %.2f')
	if ui.itemEdited() then cfg.ui_accent_b = ab2; data.dirty = true end
	prev = ui.getCursor()
	ui.drawRectFilled(prev, prev + vec2(u.getSliderWidth(), 4), u.getColAccent())
	ui.offsetCursorY(8)

	-- Hint color
	ui.text('  Cor das Dicas:')
	ui.offsetCursorY(2)
	ui.setNextItemWidth(u.getSliderWidth())
	local ihr = ui.slider('##ui_hint_r', cfg.ui_hint_r, 0, 1, 'R: %.2f')
	if ui.itemEdited() then cfg.ui_hint_r = ihr; data.dirty = true end
	ui.setNextItemWidth(u.getSliderWidth())
	local ihg = ui.slider('##ui_hint_g', cfg.ui_hint_g, 0, 1, 'G: %.2f')
	if ui.itemEdited() then cfg.ui_hint_g = ihg; data.dirty = true end
	ui.setNextItemWidth(u.getSliderWidth())
	local ihb = ui.slider('##ui_hint_b', cfg.ui_hint_b, 0, 1, 'B: %.2f')
	if ui.itemEdited() then cfg.ui_hint_b = ihb; data.dirty = true end
	prev = ui.getCursor()
	ui.drawRectFilled(prev, prev + vec2(u.getSliderWidth(), 4), u.getColHint())
	ui.offsetCursorY(8)

	-- Line color
	ui.text('  Cor das Linhas:')
	ui.offsetCursorY(2)
	ui.setNextItemWidth(u.getSliderWidth())
	local lr = ui.slider('##ui_line_r', cfg.ui_line_r, 0, 1, 'R: %.2f')
	if ui.itemEdited() then cfg.ui_line_r = lr; data.dirty = true end
	ui.setNextItemWidth(u.getSliderWidth())
	local lg = ui.slider('##ui_line_g', cfg.ui_line_g, 0, 1, 'G: %.2f')
	if ui.itemEdited() then cfg.ui_line_g = lg; data.dirty = true end
	ui.setNextItemWidth(u.getSliderWidth())
	local lb = ui.slider('##ui_line_b', cfg.ui_line_b, 0, 1, 'B: %.2f')
	if ui.itemEdited() then cfg.ui_line_b = lb; data.dirty = true end
	prev = ui.getCursor()
	ui.drawRectFilled(prev, prev + vec2(u.getSliderWidth(), 4), u.getColLine())
	ui.offsetCursorY(8)

	if ui.button('Restaurar Cores Padrão', vec2(180,0)) then
		cfg.ui_header_r=0.9; cfg.ui_header_g=0.15; cfg.ui_header_b=0.15
		cfg.ui_accent_r=1.0; cfg.ui_accent_g=0.3;  cfg.ui_accent_b=0.3
		cfg.ui_hint_r=0.45;  cfg.ui_hint_g=0.45;   cfg.ui_hint_b=0.45
		cfg.ui_line_r=0.35;  cfg.ui_line_g=0.35;   cfg.ui_line_b=0.35
		data.dirty = true
	end
end

return M