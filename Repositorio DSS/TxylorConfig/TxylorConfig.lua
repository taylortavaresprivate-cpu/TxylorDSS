-- ========================================================================
-- DSS — DYNAMIC STEERING SYSTEM — CONFIG v6.2.0
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local cio  = require "cfg_io"
local u    = require "cfg_ui"

local tabDirecao     = require "tab_direcao"
local tabPedais      = require "tab_pedais"
local tabABS         = require "tab_abs"
local tabTC          = require "tab_tc"
local tabTransmissao = require "tab_transmissao"
local tabExtras      = require "tab_extras"
local tabKeybinds    = require "tab_keybinds"
local tabPresets     = require "tab_presets"
local tabSobre       = require "tab_sobre"

local TAB_FUNCTIONS = {
	[0] = tabDirecao.draw,
	[1] = tabPedais.draw,
	[2] = tabABS.draw,
	[3] = tabTC.draw,
	[4] = tabTransmissao.draw,
	[5] = tabExtras.draw,
	[6] = tabKeybinds.draw,
	[7] = tabPresets.draw,
	[8] = tabSobre.draw,
}

local autoLoadDone = false

function windowMain(dt)
	if not autoLoadDone then cio.tryAutoLoad(); autoLoadDone = true end

	if data.dirty then
		data.saveTimer = data.saveTimer + dt
		if data.saveTimer >= 0.5 then cio.saveConfig(); data.dirty = false; data.saveTimer = 0 end
	end
	if cio.presetMsgTimer > 0 then cio.presetMsgTimer = cio.presetMsgTimer - dt end

	u.drawTabBar()

	ui.offsetCursorY(4)
	local tabFunc = TAB_FUNCTIONS[u.currentTab]
	if tabFunc then tabFunc() end

	u.drawLogo()

	ui.offsetCursorY(4)
	local footerCursor = ui.getCursor()
	local w = u.getWindowWidth() - 16
	ui.drawLine(footerCursor, footerCursor + vec2(w, 0), u.getColLine(), 1)
	ui.offsetCursorY(6)

	if ui.button('Restaurar Padrões', vec2(150, 0)) then
		for k, v in pairs(data.defaults) do cfg[k] = v end
		data.dirty = true; data.saveTimer = 0
	end
	ui.sameLine(0, 10)
	if data.dirty then
		ui.pushStyleColor(ui.StyleColor.Text, u.colChanged); ui.text('Salvando...'); ui.popStyleColor()
	elseif not data.saveOk then
		ui.pushStyleColor(ui.StyleColor.Text, u.colRed); ui.text('Erro ao salvar.'); ui.popStyleColor()
	else
		ui.pushStyleColor(ui.StyleColor.Text, u.colGreen); ui.text('Salvo.'); ui.popStyleColor()
	end
	ui.sameLine(0, 20)
	ui.pushStyleColor(ui.StyleColor.Text, u.getColHint()); ui.text('v6.2.0'); ui.popStyleColor()

	-- Overlays
	tabDirecao.drawGraphs(dt)
end