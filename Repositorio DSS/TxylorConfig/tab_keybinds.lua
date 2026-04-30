-- ========================================================================
-- DSS TAB: KEYBINDS
-- ========================================================================

local data = require "cfg_data"
local cfg  = data.cfg
local u    = require "cfg_ui"

local M = {}

-- ========================================================================
-- TABELA DE NOMES DE TECLAS (VK codes → string)
-- ========================================================================

local KEY_NAMES = {
	[0]  = '—',
	[8]  = 'Backspace', [9]  = 'Tab',     [13] = 'Enter',
	[16] = 'Shift',     [17] = 'Ctrl',    [18] = 'Alt',
	[19] = 'Pause',     [20] = 'CapsLck', [27] = 'Esc',
	[32] = 'Space',
	[33] = 'PgUp',  [34] = 'PgDn',  [35] = 'End',   [36] = 'Home',
	[37] = '←',     [38] = '↑',     [39] = '→',     [40] = '↓',
	[45] = 'Insert',[46] = 'Delete',
	[186]= ';', [187]= '=', [188]= ',', [189]= '-', [190]= '.', [191]= '/',
	[192]= '`', [219]= '[', [220]= '\\', [221]= ']', [222]= "'",
}
for i = 65,  90  do KEY_NAMES[i] = string.char(i) end
for i = 48,  57  do KEY_NAMES[i] = string.char(i) end
for i = 112, 123 do KEY_NAMES[i] = 'F'..(i - 111) end
for i = 96,  105 do KEY_NAMES[i] = 'Num'..(i - 96) end

local function keyName(vk)
	return KEY_NAMES[vk] or ('VK '..tostring(vk))
end

-- ========================================================================
-- TECLAS SCANEÁVEIS
-- ========================================================================

local SCANNABLE = {}
for i = 65,  90  do table.insert(SCANNABLE, i) end
for i = 48,  57  do table.insert(SCANNABLE, i) end
for i = 112, 123 do table.insert(SCANNABLE, i) end
for i = 96,  105 do table.insert(SCANNABLE, i) end
for _, v in ipairs({32,13,8,9,20,27,33,34,35,36,37,38,39,40,45,46,
                    186,187,188,189,190,191,192,219,220,221,222}) do
	table.insert(SCANNABLE, v)
end

-- ========================================================================
-- ESTADO DE CAPTURA
-- ========================================================================

local capturingKey = nil
local prevState    = {}

-- ========================================================================
-- DEFINIÇÃO DAS SEÇÕES E AÇÕES
-- ========================================================================

local SECTIONS = {
	{
		title = 'CONTROLES DIRETOS',
		hint  = 'Teclas que ficam SEGURADAS durante o uso.',
		actions = {
			{ label = 'Embreagem Manual',  key = 'key_clutch',    hint = 'Segure para pisar a embreagem.' },
			{ label = 'Freio de Mão',      key = 'key_handbrake', hint = 'Segure para puxar o freio de mão.' },
		},
	},
	{
		title = 'TOGGLES',
		hint  = 'Pressione uma vez para ligar/desligar o sistema.',
		actions = {
			{ label = 'Toggle ABS',         key = 'key_toggle_abs',        hint = 'Liga/desliga o ABS do DSS.' },
			{ label = 'Toggle TC',          key = 'key_toggle_tc',         hint = 'Liga/desliga o TC do DSS.' },
			{ label = 'Toggle Launch Ctrl', key = 'key_toggle_launch',     hint = 'Liga/desliga o Launch Control.' },
			{ label = 'Toggle Cruise Ctrl', key = 'key_toggle_cruise',     hint = 'Liga/desliga o Cruise Control.' },
			{ label = 'Toggle AutoClutch',  key = 'key_toggle_autoclutch', hint = 'Liga/desliga o AutoClutch.' },
		},
	},
	{
		title = 'DIREÇÃO',
		hint  = 'Ajustes rápidos de FFB durante a pilotagem.',
		actions = {
			{ label = 'FFB Gain +', key = 'key_ffb_gain_up',   hint = 'Aumenta o FFB Gain em 0.1' },
			{ label = 'FFB Gain -', key = 'key_ffb_gain_down', hint = 'Diminui o FFB Gain em 0.1' },
		},
	},
}

-- ========================================================================
-- CAPTURA DE TECLA
-- ========================================================================

local function updateCapture()
	if not capturingKey then return end
	for _, vk in ipairs(SCANNABLE) do
		local down    = ac.isKeyDown(vk)
		local wasDown = prevState[vk] or false
		if down and not wasDown then
			if vk == 27 then
				capturingKey = nil
			else
				cfg[capturingKey] = vk
				data.dirty        = true
				capturingKey      = nil
			end
			break
		end
		prevState[vk] = down
	end
end

-- ========================================================================
-- LAYOUT
-- ========================================================================

local COL_LABEL_W = 170
local COL_KEY_W   = 90
local COL_BTN_W   = 60
local COL_CLR_W   = 24

-- ========================================================================
-- DESENHO DE UMA LINHA DE AÇÃO
-- ========================================================================
-- ATENÇÃO: esta função NÃO termina com ui.sameLine.
-- O último elemento é sempre ui.dummy ou ui.button sem sameLine posterior,
-- garantindo que o cursor avance corretamente para a próxima linha.
-- ========================================================================

local function drawAction(action)
	local vk     = cfg[action.key] or 0
	local name   = keyName(vk)
	local isThis = (capturingKey == action.key)

	-- ── Label (tooltip no próprio label) ────────────────────────────
	ui.pushStyleColor(ui.StyleColor.Text, u.colWhite)
	ui.text(action.label)
	ui.popStyleColor()
	if ui.itemHovered() then ui.setTooltip(action.hint) end

	-- ── Caixa da tecla ───────────────────────────────────────────────
	ui.sameLine(COL_LABEL_W, 0)
	if isThis then
		ui.pushStyleColor(ui.StyleColor.Text,          rgbm(0.1,0.1,0.1,1))
		ui.pushStyleColor(ui.StyleColor.Button,        u.getColAccent())
		ui.pushStyleColor(ui.StyleColor.ButtonHovered, u.getColAccent())
		ui.button('Pressione...##k_'..action.key, vec2(COL_KEY_W, 0))
		ui.popStyleColor(3)
	else
		local col = vk == 0 and u.getColHint() or u.getColAccent()
		ui.pushStyleColor(ui.StyleColor.Text,          col)
		ui.pushStyleColor(ui.StyleColor.Button,        rgbm(0.18,0.18,0.18,1))
		ui.pushStyleColor(ui.StyleColor.ButtonHovered, rgbm(0.25,0.25,0.25,1))
		ui.button(name..'##k_'..action.key, vec2(COL_KEY_W, 0))
		ui.popStyleColor(3)
	end

	-- ── Botão Alterar ────────────────────────────────────────────────
	ui.sameLine(0, 6)
	if capturingKey == nil then
		if ui.button('Alterar##alt_'..action.key, vec2(COL_BTN_W, 0)) then
			capturingKey = action.key
			prevState    = {}
		end
	else
		ui.pushStyleColor(ui.StyleColor.Button, rgbm(0.15,0.15,0.15,1))
		ui.pushStyleColor(ui.StyleColor.Text,   u.getColHint())
		ui.button('Alterar##alt_'..action.key, vec2(COL_BTN_W, 0))
		ui.popStyleColor(2)
	end

	-- ── Botão Limpar (ou dummy para manter alinhamento) ──────────────
	-- NÃO há ui.sameLine após este bloco — cursor avança para próxima linha.
	ui.sameLine(0, 4)
	if vk ~= 0 then
		ui.pushStyleColor(ui.StyleColor.Text, u.colRed)
		if ui.button('x##clr_'..action.key, vec2(COL_CLR_W, 0)) then
			cfg[action.key] = 0
			data.dirty      = true
			if capturingKey == action.key then capturingKey = nil end
		end
		ui.popStyleColor()
	else
		-- dummy mantém o espaço mas NÃO usa sameLine, forçando nova linha
		ui.dummy(vec2(COL_CLR_W, 0))
	end
end

-- ========================================================================
-- DRAW PRINCIPAL
-- ========================================================================

function M.draw()
	updateCapture()

	-- Banner de captura ativa
	if capturingKey then
		ui.offsetCursorY(2)
		ui.pushStyleColor(ui.StyleColor.Text, u.colYellow)
		ui.text('  Pressione a tecla desejada... (ESC para cancelar)')
		ui.popStyleColor()
		ui.sameLine(0, 10)
		if ui.button('Cancelar##capcancel', vec2(70, 0)) then
			capturingKey = nil
		end
		ui.offsetCursorY(4)
	else
		u.hint('Clique em [Alterar] e pressione a tecla desejada.')
		u.hint('Os binds sao usados pelo script TxylorMouseSteer.')
		ui.offsetCursorY(4)
	end

	-- Seções e ações
	for _, section in ipairs(SECTIONS) do
		u.header(section.title)
		u.hint(section.hint)
		ui.offsetCursorY(6)

		for _, action in ipairs(section.actions) do
			drawAction(action)
			ui.offsetCursorY(4)
		end
	end
end

return M