-- ======================================================================== 
-- DSS AUTO-BLIP MODULE v2.0 
-- ======================================================================== 
-- Modo Automático: calcula RPM alvo via gear ratio real do carro usando 
-- ac.getCarMaxSpeedWithGear(). Sem ajustes manuais por carro. 
-- Modo Manual: fórmula linear fixa (compatibilidade fallback). 
-- ======================================================================== 

local cfg = require "dss_config" 
local pedals = require "dss_pedals" 

local blip = {} 

-- Estado interno 
local prevGear = -999 
local blipActive = false 
local blipStartTime = 0 
local targetRPM = 0 
local blipSmoothed = 0 

-- Cache de dados de transmissão 
local gearMaxSpeeds = {} 
local cachedGearCount = 0 
local cachedCarID = "" 

-- ======================================================================== 
-- CONSTANTES DO MODO AUTOMÁTICO (valores otimizados, não editáveis) 
-- ======================================================================== 
local AUTO_ATTACK_SPEED  = 20.0   -- subida rápida e precisa 
local AUTO_RELEASE_SPEED = 5.0    -- descida suave, sem tranco 
local AUTO_INTENSITY     = 1.0    -- TPS proporcional ao erro 
local AUTO_SENSITIVITY   = 2000   -- divisor padrão do erro RPM 
local AUTO_DURATION_MAX  = 300    -- timeout de segurança em ms 

-- ======================================================================== 
-- CACHE DE VELOCIDADES MÁXIMAS POR MARCHA 
-- ======================================================================== 
local function refreshGearData() 
	local carID = ac.getCarID(0) or "" 
	local gearCount = car.gearCount or 0 
	
	-- Recarrega se carro mudou ou quantidade de marchas mudou 
	if carID ~= cachedCarID or gearCount ~= cachedGearCount then 
		cachedCarID = carID 
		cachedGearCount = gearCount 
		gearMaxSpeeds = {} 
		
		for g = 1, gearCount do 
			local ok, speed = pcall(function() return ac.getCarMaxSpeedWithGear(0, g) end) 
			if ok and speed and speed > 0 then 
				gearMaxSpeeds[g] = speed 
			else 
				gearMaxSpeeds[g] = nil 
			end 
		end 
		
		ac.log('[AUTO-BLIP] Gear data refreshed. Car: ' .. carID .. ' | Gears: ' .. gearCount) 
	end 
end 

-- ======================================================================== 
-- CÁLCULO DO GEAR RATIO ENTRE DUAS MARCHAS 
-- ======================================================================== 
local function getGearRatio(fromGear, toGear) 
	refreshGearData() 
	
	local vFrom = gearMaxSpeeds[fromGear] 
	local vTo   = gearMaxSpeeds[toGear] 
	
	-- Se temos dados válidos, calcula ratio real 
	if vFrom and vTo and vFrom > 0 and vTo > 0 then 
		local ratio = vTo / vFrom 
		-- Sanity check: ratio deve estar em faixa realista (1.1x a 3.0x) 
		if ratio >= 1.05 and ratio <= 3.0 then 
			return ratio 
		end 
	end 
	
	-- Fallback: fórmula linear genérica 
	local gearDiff = fromGear - toGear 
	return 1.0 + (gearDiff * 0.4) 
end 

-- ======================================================================== 
-- DETERMINA SE O MODO AUTOMÁTICO ESTÁ DISPONÍVEL 
-- ======================================================================== 
local function isAutoModeAvailable() 
	-- Verifica se a API está disponível 
	local ok = pcall(function() ac.getCarMaxSpeedWithGear(0, 1) end) 
	return ok and cfg.BLIP_MODE == 0 
end 

-- ======================================================================== 
-- CÁLCULO DE DURAÇÃO ADAPTATIVA (modo automático) 
-- Quanto maior a diferença de ratio, mais tempo é permitido 
-- ======================================================================== 
local function getAdaptiveDuration(ratio) 
	-- Base: 100ms, adiciona até (ratio - 1.0) * 200ms 
	-- Ex: ratio 1.2 → ~140ms base | ratio 1.5 → ~200ms base 
	local adaptive = 100 + (ratio - 1.0) * 250 
	-- Clamp entre 80ms e o timeout fixo do modo automático 
	return math.max(80, math.min(adaptive, AUTO_DURATION_MAX)) 
end 

-- ======================================================================== 
-- MAIN UPDATE 
-- ======================================================================== 
function blip.update(dt, data, currentGear, currentGas) 
	
	-- ── 1. DETECTAR REDUÇÃO DE MARCHA ──────────────────────────────── 
	if cfg.BLIP_ENABLED and currentGear > 0 and prevGear > currentGear and prevGear ~= -999 then 
		local currentRPM = car.rpm 
		local speedKmh = math.abs(car.speedKmh) 
		local gearDiff = prevGear - currentGear 
		
		local blipFactor 
		local ratio 
		local modeStr 
		
		if isAutoModeAvailable() then 
			-- MODO AUTOMÁTICO: gear ratio real do carro 
			ratio = getGearRatio(prevGear, currentGear) 
			blipFactor = ratio 
			modeStr = 'AUTO' 
		else 
			-- MODO MANUAL: fórmula linear fixa 
			blipFactor = 1.0 + (gearDiff * 0.4) 
			ratio = blipFactor 
			modeStr = 'MANUAL' 
		end 
		
		targetRPM = currentRPM * blipFactor 
		
		-- Limitar ao RPM do limiter (segurança) 
		if car.rpmLimiter and car.rpmLimiter > 0 then 
			targetRPM = math.min(targetRPM, car.rpmLimiter * 0.95) 
		else 
			targetRPM = math.min(targetRPM, 9000) 
		end 
		
		-- Só ativar se RPM atual estiver acima do mínimo configurado
		if car.rpm >= cfg.BLIP_MIN_RPM then
			blipActive = true 
			blipStartTime = os.preciseClock() 
			
			-- No modo auto, calcula duração adaptativa 
			local durationMs 
			if isAutoModeAvailable() then 
				durationMs = getAdaptiveDuration(ratio) 
			else 
				durationMs = cfg.BLIP_DURATION 
			end 
			
			ac.log('[AUTO-BLIP] Ativado! Modo: ' .. modeStr .. 
			       ' | Marcha: ' .. tostring(prevGear) .. ' -> ' .. tostring(currentGear) .. 
			       ' | Ratio: ' .. string.format("%.2f", ratio) .. 
			       ' | RPM atual: ' .. tostring(math.floor(currentRPM)) .. 
			       ' | RPM alvo: ' .. tostring(math.floor(targetRPM)) .. 
			       ' | Duração: ' .. tostring(math.floor(durationMs)) .. 'ms') 
		end 
	end 
	
	prevGear = currentGear 
	
	-- *** FIX: Desativar se o blip foi desligado durante execução *** 
	if not cfg.BLIP_ENABLED and blipActive then 
		blipActive = false 
		blipSmoothed = 0 
		ac.log('[AUTO-BLIP] Cancelado - desativado manualmente') 
		return currentGas 
	end 
	
	-- ── 2. PROCESSAR AUTO-BLIP ATIVO ───────────────────────────────── 
	if blipActive then 
		local currentRPM = car.rpm 
		local elapsedTime = (os.preciseClock() - blipStartTime) * 1000 
		
		-- Determina se estamos no modo automático (cache para este frame) 
		local autoMode = isAutoModeAvailable() 
		
		-- Calcular erro de RPM 
		local rpmError = targetRPM - currentRPM 
		
		-- Calcular throttle TARGET proporcional ao erro 
		local blipTarget = 0 
		if rpmError > 0 then 
			-- Modo auto: constantes fixas otimizadas | Modo manual: configs escaladas 
			local sensitivity = autoMode and AUTO_SENSITIVITY or (cfg.BLIP_SENSITIVITY * 50) 
			local intensity   = autoMode and AUTO_INTENSITY or (cfg.BLIP_INTENSITY * 0.1) 
			blipTarget = (rpmError / sensitivity) * intensity 
			
			-- Garantir um mínimo de throttle 
			blipTarget = math.max(blipTarget, 0.15) 
			
			-- Clamp entre 0 e 1 
			blipTarget = math.min(math.max(blipTarget, 0), 1.0) 
		end 
		
		-- Calcular duração efetiva para este blip 
		local effectiveDuration 
		if autoMode then 
			local ratio = targetRPM / (currentRPM + 0.001) 
			effectiveDuration = getAdaptiveDuration(ratio) 
		else 
			effectiveDuration = cfg.BLIP_DURATION 
		end 
		
		-- Condições para desativar o blip 
		local rpmReached = math.abs(rpmError) < 100 	-- tolerância de ±100 RPM 
		local timeExpired = elapsedTime > effectiveDuration 
		
		if rpmReached or timeExpired then 
			blipActive = false 
			ac.log('[AUTO-BLIP] Desativado! Tempo: ' .. tostring(math.floor(elapsedTime)) .. 
			       'ms | RPM final: ' .. tostring(math.floor(currentRPM)) .. 
			       ' | Alvo: ' .. tostring(math.floor(targetRPM))) 
		end 
		
		-- Suavizar com attack speed (subindo) 
		local attackSpeed  = autoMode and AUTO_ATTACK_SPEED or (cfg.BLIP_ATTACK_SPEED * 5.0) 
		local releaseSpeed = autoMode and AUTO_RELEASE_SPEED or (cfg.BLIP_RELEASE_SPEED * 4.0) 
		local speed = blipTarget > blipSmoothed and attackSpeed or releaseSpeed 
		blipSmoothed = pedals.approach(blipSmoothed, blipTarget, speed, dt) 
		
		-- Retornar o maior entre o gás do jogador e o blip suavizado 
		return math.max(currentGas, blipSmoothed) 
	end 
	
	-- ── 3. RELEASE SUAVE PÓS-BLIP ─────────────────────────────────── 
	if blipSmoothed > 0.001 then 
		local releaseSpeed = isAutoModeAvailable() and AUTO_RELEASE_SPEED or (cfg.BLIP_RELEASE_SPEED * 4.0) 
		blipSmoothed = pedals.approach(blipSmoothed, 0, releaseSpeed, dt) 
		return math.max(currentGas, blipSmoothed) 
	end 
	
	blipSmoothed = 0 
	
	-- Sem blip ativo, retorna o gás normal 
	return currentGas 
end 

return blip 
