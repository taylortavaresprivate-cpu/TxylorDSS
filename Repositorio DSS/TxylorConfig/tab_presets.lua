-- ========================================================================
-- DSS TAB: PRESETS
-- ========================================================================

local u   = require "cfg_ui"
local cio = require "cfg_io"

local M = {}

function M.draw()
	local carId = cio.getCarId()
	ui.pushStyleColor(ui.StyleColor.Text, u.colBlue)
	ui.text('  Veículo: '..carId); ui.popStyleColor()
	ui.offsetCursorY(4)

	u.header('SALVAR CONFIGURAÇÃO')
	u.hint('Vincula automaticamente ao veículo atual.')
	ui.offsetCursorY(4)
	ui.setNextItemWidth(u.getSliderWidth() - 90)
	local newName = ui.inputText('##presetname', cio.presetNameInput, ui.InputTextFlags.None)
	if newName ~= cio.presetNameInput then cio.presetNameInput = newName end
	ui.sameLine(0,6)
	if ui.button('Salvar', vec2(80,0)) then
		if cio.presetNameInput ~= "" then
			cio.savePreset(cio.presetNameInput); cio.presetNameInput = ""
		else
			cio.presetMsg = "Informe um nome."; cio.presetMsgColor = rgbm(1,0.7,0.3,1); cio.presetMsgTimer = 2
		end
	end
	ui.offsetCursorY(4)

	u.header('PRESETS DISPONÍVEIS')
	if #cio.presetList == 0 then
		ui.offsetCursorY(8); u.hint('Nenhum preset salvo.')
	else
		for i, preset in ipairs(cio.presetList) do
			ui.pushStyleColor(ui.StyleColor.Text,
				preset.car_id == carId and u.colGreen or u.colWhite)
			ui.text('  '..preset.name); ui.popStyleColor()
			if preset.car_id ~= "" then
				ui.sameLine(0,6)
				ui.pushStyleColor(ui.StyleColor.Text, u.getColHint())
				ui.text('('..preset.car_id..')'); ui.popStyleColor()
			end
			ui.sameLine(0,6)
			if ui.button('Carregar##load'..i, vec2(65,0)) then cio.loadPreset(preset) end
			ui.sameLine(0,4)
			if cio.deleteConfirm == i then
				ui.pushStyleColor(ui.StyleColor.Text, u.colRed)
				ui.text('Confirmar?'); ui.popStyleColor()
				ui.sameLine(0,4)
				if ui.button('Sim##dy'..i, vec2(30,0)) then cio.deletePreset(preset) end
				ui.sameLine(0,2)
				if ui.button('Não##dn'..i, vec2(35,0)) then cio.deleteConfirm = -1 end
			else
				if ui.button('X##del'..i, vec2(22,0)) then cio.deleteConfirm = i end
			end
			ui.offsetCursorY(2)
		end
	end
	if cio.presetMsgTimer > 0 then
		ui.offsetCursorY(8)
		ui.pushStyleColor(ui.StyleColor.Text, cio.presetMsgColor)
		ui.text('  '..cio.presetMsg); ui.popStyleColor()
	end
	ui.offsetCursorY(12)
	u.hint('Diretório: apps/lua/TxylorConfig/presets/')
end

return M