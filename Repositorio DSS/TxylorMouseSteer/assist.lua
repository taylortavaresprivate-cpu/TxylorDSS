local cfg      = require "dss_config"
local pedals   = require "dss_pedals"
local steering = require "dss_steering"
local clutchM  = require "dss_clutch"
local abs      = require "dss_abs"
local tc       = require "dss_tc"
local launch   = require "dss_launch"
local blip     = require "dss_blip"
local nls      = require "dss_nls"
local cruise   = require "dss_cruise"
local keybinds = require "dss_keybinds"

local mouseEnabled          = true
local keyboardMode          = 0
local wasToggleDown         = false
local wasKeyboardToggleDown = false
local wasFFBUp              = false
local wasFFBDown            = false
local configTimer           = 0

function script.update(dt)
	local data = ac.getJoypadState()
	local ui   = ac.getUI()

	tc.detectDrivetrain()

	configTimer = configTimer + dt
	if configTimer >= 1.0 then
		configTimer = 0
		cfg.loadConfig()
	end

	-- Toggles via keybinds configuráveis (ABS, TC, Launch, Cruise, AutoClutch)
	keybinds.update(dt)

	local toggleDown = ac.isKeyDown(ac.KeyIndex.N)
	if toggleDown and not wasToggleDown then
		mouseEnabled = not mouseEnabled
		ac.setSystemMessage(
			mouseEnabled and 'Mouse Ativado'            or 'Mouse Desativado',
			mouseEnabled and 'Controle via mouse ativo' or 'Controle via mouse inativo')
	end
	wasToggleDown = toggleDown

	local ffbUpDown   = ac.isKeyDown(ac.KeyIndex.OemPlus)  and not wasFFBUp
	local ffbDownDown = ac.isKeyDown(ac.KeyIndex.OemMinus) and not wasFFBDown
	if ffbUpDown then
		cfg.FFB_GAIN = math.min(cfg.FFB_GAIN + 0.1, 10.0)
		ac.setSystemMessage('FFB Gain: '..string.format("%.1f", cfg.FFB_GAIN), 'Pressione - para diminuir')
	end
	if ffbDownDown then
		cfg.FFB_GAIN = math.max(cfg.FFB_GAIN - 0.1, 0.0)
		ac.setSystemMessage('FFB Gain: '..string.format("%.1f", cfg.FFB_GAIN), 'Pressione = para aumentar')
	end
	wasFFBUp   = ac.isKeyDown(ac.KeyIndex.OemPlus)
	wasFFBDown = ac.isKeyDown(ac.KeyIndex.OemMinus)

	local keyboardToggleDown = ac.isKeyDown(ac.KeyIndex.M)
	if keyboardToggleDown and not wasKeyboardToggleDown then
		keyboardMode = (keyboardMode + 1) % 3
		local msgs = {
			[0]={'Modo Mouse',   'Acelerador e freio no mouse'},
			[1]={'Modo Teclado', 'Acelerador e freio no teclado'},
			[2]={'Modo Híbrido', 'Acelerador e freio no mouse + teclado'},
		}
		ac.setSystemMessage(msgs[keyboardMode][1], msgs[keyboardMode][2])
	end
	wasKeyboardToggleDown = keyboardToggleDown

	local gasTarget = (
		(mouseEnabled and keyboardMode == 0 and ac.isKeyDown(1)) or
		(keyboardMode == 1 and ac.isKeyDown(ac.KeyIndex.W))      or
		(keyboardMode == 2 and (ac.isKeyDown(1) or ac.isKeyDown(ac.KeyIndex.W)))
	) and 1 or 0

	-- Passa o ui para o updateGas ter acesso ao mouseWheel
	pedals.updateGas(dt, gasTarget, ui)

	-- ── PROCESSAMENTO DE GAS (ordem importa!) ─────────────
	local currentGear = car.gear

	pedals.gasValue = nls.update(dt, data, currentGear, pedals.gasValue)
	pedals.gasValue = blip.update(dt, data, currentGear, pedals.gasValue)
	pedals.gasValue = tc.update(dt, data, pedals.gasValue)

	data.gas = pedals.gasValue

	launch.update(dt, data)

	local brakeTarget = (
		(mouseEnabled and keyboardMode == 0 and ac.isKeyDown(2)) or
		(keyboardMode == 1 and ac.isKeyDown(ac.KeyIndex.S))      or
		(keyboardMode == 2 and (ac.isKeyDown(2) or ac.isKeyDown(ac.KeyIndex.S)))
	) and 1 or 0

	pedals.updateBrake(dt, brakeTarget)
	pedals.brakeValue = abs.update(dt, data, pedals.brakeValue, steering.steerAngle)
	data.brake = pedals.brakeValue

	cruise.update(dt, data)

	local gearUpPressed   = ac.isKeyDown(ac.KeyIndex.E) or ac.isKeyDown(6)
	local gearDownPressed = ac.isKeyDown(ac.KeyIndex.Q) or ac.isKeyDown(5)
	data.gearUp   = gearUpPressed   and 1 or 0
	data.gearDown = gearDownPressed and 1 or 0

	-- Embreagem manual via tecla configurável (padrão: C)
	local manualPressed = cfg.KEY_CLUTCH > 0 and ac.isKeyDown(cfg.KEY_CLUTCH) or false
	data.clutch = clutchM.update(dt, data, manualPressed, currentGear, pedals.gasValue)

	-- Freio de mão via tecla configurável (padrão: Space)
	local handbrakeTarget = (cfg.KEY_HANDBRAKE > 0 and ac.isKeyDown(cfg.KEY_HANDBRAKE)) and 1 or 0
	pedals.updateHandbrake(dt, handbrakeTarget)
	data.handbrake = pedals.handbrakeValue

	if mouseEnabled then
		steering.update(dt, data, ui)
	end

	steering.sanitize(data)
end