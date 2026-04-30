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
	elseif key=='tc_level' or key=='abs_level'
	    or key=='launch_rpm' or key=='launch_cut_time'
	    or key=='nls_cut_duration' or key=='nls_min_rpm'
	    or key=='blip_duration' then
		return string.format("%d", val)
	elseif key=='steer_sensi' or key=='abs_min_speed' or key=='tc_min_speed'
	    or key=='abs_smooth' or key=='tc_smooth'
	    or key=='speed_sensi_start' or key=='speed_sensi_end'
	    or key=='antistall_full_speed' or key=='antistall_min_speed'
	    or key=='cruise_full_speed' then
		return string.format("%.1f", val)
	elseif key=='abs_threshold' or key=='abs_min_brake' then
		return string.format("%.3f", val)
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

function M.saveConfig()
	data.saveOk = writeIni(CONFIG_PATH, "mousesteer", cfg)
end

function M.loadConfig()
	local ini = readIni(CONFIG_PATH)
	if not ini then return end
	for _, key in ipairs(SAVE_KEYS) do
		if ini[key] then
			if BOOL_KEYS[key] then cfg[key] = (ini[key]=="1" or ini[key]=="true")
			else cfg[key] = tonumber(ini[key]) or cfg[key] end
		end
	end
end

-- ========================================================================
-- PRESETS
-- ========================================================================

M.presetList     = {}
M.presetNameInput = ""
M.presetMsg      = ""
M.presetMsgTimer = 0
M.presetMsgColor = rgbm(1,1,1,1)
M.deleteConfirm  = -1

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
	local extras = {car_id=getCarId(), author="Txylor", version="6.1.0"}
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

-- Inicialização
M.loadConfig()
M.refreshPresetList()

return M