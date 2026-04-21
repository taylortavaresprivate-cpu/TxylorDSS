-- ========================================================================
-- DSS CONFIG I/O + PRESETS
-- ========================================================================

local data = require "cfg_data"
local cfg       = data.cfg
local SAVE_KEYS = data.SAVE_KEYS
local BOOL_KEYS = data.BOOL_KEYS

local M = {}

local CONFIG_PATH  = "apps/lua/TxylorConfig/config.ini"
local PRESETS_PATH = "apps/lua/TxylorConfig/presets/"

-- ========================================================================
-- FORMAT / READ / WRITE
-- ========================================================================

local function formatValue(key, val)
	if BOOL_KEYS[key] then return val and "1" or "0"
	elseif key:sub(1,4) == 'key_' then
		return string.format("%d", val)
	elseif key:sub(-4) == '_max' then
		return string.format("%d", val)
	elseif key=='tc_level' or key=='abs_level'
	    or key=='launch_rpm' or key=='launch_cut_time'
	    or key=='nls_cut_duration' or key=='nls_min_rpm'
	    or key=='blip_duration' then
		return string.format("%d", val)
	elseif key=='abs_threshold' or key=='abs_min_brake' or key=='abs_curve_factor' then
		return string.format("%d", math.floor(val + 0.5))
	elseif key=='abs_rear_bias' or key=='abs_trail_brake'
	    or key=='abs_trail_brake_start' or key=='abs_brake_recovery' then
		return string.format("%d", math.floor(val + 0.5))
	elseif key=='steer_sensi' or key=='abs_min_speed' or key=='tc_min_speed'
	    or key=='abs_smooth' or key=='tc_smooth'
	    or key=='speed_sensi_start' or key=='speed_sensi_end'
	    or key=='antistall_full_speed' or key=='antistall_min_speed'
	    or key=='cruise_full_speed' then
		return string.format("%.1f", val)
	elseif key=='tc_threshold' then
		return string.format("%.4f", val)
	else
		return string.format("%.2f", val)
	end
end

local function writeIni(path, section, cfgData, extras)
	local lines = {"["..section.."]"}
	for _, key in ipairs(SAVE_KEYS) do
		if cfgData[key] ~= nil then
			table.insert(lines, key.." = "..formatValue(key, cfgData[key]))
		end
	end
	if extras then
		for k, v in pairs(extras) do table.insert(lines, k.." = "..v) end
	end
	local f = io.open(path, "w")
	if f then f:write(table.concat(lines, "\n")); f:close(); return true end
	return false
end

local function readIni(path)
	local result = {}
	local f = io.open(path, "r")
	if not f then return nil end
	for line in f:lines() do
		local key, val = line:match("^%s*([%w_]+)%s*=%s*(.+)%s*$")
		if key and val then result[key:lower()] = val end
	end
	f:close(); return result
end

-- Converte abs_threshold e abs_min_brake do formato antigo (float 0.032)
-- para o formato novo (inteiro 32) automaticamente
local function loadAbsInt(ini, key, default)
	local raw = tonumber(ini[key])
	if raw == nil then return default end
	if raw < 1 then
		-- formato antigo: float como 0.032 → converte para inteiro 32
		return math.max(1, math.floor(raw * 1000 + 0.5))
	end
	return math.floor(raw + 0.5)
end

function M.saveConfig()
	data.saveOk = writeIni(CONFIG_PATH, "mousesteer", cfg)
end

function M.loadConfig()
	local ini = readIni(CONFIG_PATH)
	if not ini then return end
	for _, key in ipairs(SAVE_KEYS) do
		if ini[key] then
			if BOOL_KEYS[key] then
				cfg[key] = (ini[key]=="1" or ini[key]=="true")
			elseif key == 'abs_threshold' then
				cfg[key] = loadAbsInt(ini, key, cfg[key])
			elseif key == 'abs_min_brake' then
				-- formato antigo: 0.00-0.50 → novo: 0-100 (escala ×0.001, max 0.100)
				local raw = tonumber(ini[key])
				if raw == nil then
					-- mantém default
				elseif raw < 1 then
					-- antigo: ex 0.14 → converte proporcionalmente para 0-100
					-- 0.14 / 0.50 * 100 = 28... mas agora max interno é 0.100
					-- se raw <= 0.100, mapeia 1:1000; se > 0.100 (antigo range), clamp a 100
					cfg[key] = math.min(100, math.floor(raw * 1000 + 0.5))
				else
					cfg[key] = math.min(100, math.floor(raw + 0.5))
				end
			elseif key == 'abs_curve_factor' then
				local raw = tonumber(ini[key])
				if raw == nil then
					-- mantém default
				elseif raw < 1 and raw > 0 then
					-- formato antigo (0.0-2.0) → novo (0-10): raw/2.0*10
					cfg[key] = math.floor(raw / 2.0 * 10.0 + 0.5)
				else
					cfg[key] = math.min(10, math.floor(raw + 0.5))
				end
			elseif key == 'abs_rear_bias' or key == 'abs_trail_brake'
			    or key == 'abs_trail_brake_start' or key == 'abs_brake_recovery' then
				cfg[key] = math.min(10, math.floor((tonumber(ini[key]) or cfg[key]) + 0.5))
			else
				cfg[key] = tonumber(ini[key]) or cfg[key]
			end
		end
	end
end

-- ========================================================================
-- PRESETS
-- ========================================================================

M.presetList      = {}
M.presetNameInput = ""
M.presetMsg       = ""
M.presetMsgTimer  = 0
M.presetMsgColor  = rgbm(1,1,1,1)
M.deleteConfirm   = -1

local autoLoadedCar = ""

local function getCarId()
	local ok, id = pcall(function() return ac.getCarID(0) end)
	if ok and id then return id end
	local ok2, id2 = pcall(function() return car.id end)
	if ok2 and id2 then return id2 end
	return "unknown"
end
M.getCarId = getCarId

local function sanitizeFilename(name)
	return name:gsub('[<>:"/\\|%?%*]','_'):gsub('^%s+',''):gsub('%s+$','')
end

function M.refreshPresetList()
	M.presetList = {}
	local ok, files = pcall(function() return io.scanDir(PRESETS_PATH, "*.ini") end)
	if not ok or not files then return end
	for _, filename in ipairs(files) do
		local name = filename:match("^(.+)%.ini$")
		if name then
			local ini = readIni(PRESETS_PATH..filename)
			table.insert(M.presetList, {
				name     = name,
				filename = filename,
				car_id   = ini and ini["car_id"] or "",
				author   = ini and ini["author"]  or "",
			})
		end
	end
	table.sort(M.presetList, function(a,b) return a.name:lower() < b.name:lower() end)
end

function M.savePreset(name)
	local safeName = sanitizeFilename(name)
	if safeName == "" then
		M.presetMsg = "Nome inválido."; M.presetMsgColor = rgbm(1,0.3,0.3,1); M.presetMsgTimer = 3; return false
	end
	pcall(function() io.createDir(PRESETS_PATH) end)
	local extras = {car_id=getCarId(), author="Txylor", version="6.3.0"}
	if writeIni(PRESETS_PATH..safeName..".ini", "preset", cfg, extras) then
		M.presetMsg = 'Preset "'..safeName..'" salvo.'
		M.presetMsgColor = rgbm(0.3,0.9,0.3,1); M.presetMsgTimer = 3; M.refreshPresetList(); return true
	else
		M.presetMsg = "Erro ao salvar."; M.presetMsgColor = rgbm(1,0.3,0.3,1); M.presetMsgTimer = 3; return false
	end
end

function M.loadPreset(preset)
	local ini = readIni(PRESETS_PATH..preset.filename)
	if not ini then
		M.presetMsg = "Erro ao carregar."; M.presetMsgColor = rgbm(1,0.3,0.3,1); M.presetMsgTimer = 3; return
	end
	for _, key in ipairs(SAVE_KEYS) do
		if ini[key] then
			if BOOL_KEYS[key] then cfg[key] = (ini[key]=="1" or ini[key]=="true")
			else cfg[key] = tonumber(ini[key]) or cfg[key] end
		end
	end
	data.dirty = true; data.saveTimer = 0
	M.presetMsg = 'Preset "'..preset.name..'" carregado.'
	M.presetMsgColor = rgbm(0.3,0.9,0.3,1); M.presetMsgTimer = 3
end

function M.deletePreset(preset)
	local ok = pcall(function() os.remove(PRESETS_PATH..preset.filename) end)
	M.presetMsg = ok and ('"'..preset.name..'" removido.') or "Erro ao remover."
	M.presetMsgColor = ok and rgbm(1,0.7,0.3,1) or rgbm(1,0.3,0.3,1)
	M.presetMsgTimer = 3; M.deleteConfirm = -1; M.refreshPresetList()
end

function M.tryAutoLoad()
	local carId = getCarId()
	if carId == "unknown" or carId == autoLoadedCar then return end
	for _, preset in ipairs(M.presetList) do
		if preset.car_id == carId then
			M.loadPreset(preset); autoLoadedCar = carId
			M.presetMsg = 'Auto-load: "'..preset.name..'"'
			M.presetMsgColor = rgbm(0.4,0.7,1.0,1); M.presetMsgTimer = 4
			return
		end
	end
	autoLoadedCar = carId
end

M.loadConfig()
M.refreshPresetList()

return M