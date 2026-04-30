-- ======================================================================== 
-- DSS NO-LIFT SHIFT MODULE v2.0
-- ======================================================================== 
-- Corta o throttle suavemente ao trocar marcha para cima.
-- Correções v2:
--   - Usa cfg.NLS_MIN_RPM (antes hardcoded 3000)
--   - Usa cfg.NLS_RELEASE_MULT (antes hardcoded ×2.0)
--   - Duração adaptativa por gear ratio (opcional)
--   - Ramp-up suave pós-corte (evita jump instantâneo)
--   - Detecção de miss-shift (cancela se marcha falhar)
--   - Expõe nls.isShifting() para integração com clutch
-- ======================================================================== 

local cfg = require "dss_config"
local pedals = require "dss_pedals"

local nls = {}

-- Estado interno
local prevGear = -999
local nlsActive = false
local nlsStartTime = 0
local nlsCurrentThrottle = 0
local nlsDuration = 0          -- duração fixa do corte atual
local expectedGear = 0         -- marcha esperada (para miss-shift detection)
local missShiftTimer = 0       -- tempo de graça para confirmar a troca

-- Cache de gear ratios (copiado do dss_blip para independência)
local gearMaxSpeeds = {}
local cachedGearCount = 0
local cachedCarID = ""

-- ======================================================================== 
-- CACHE DE VELOCIDADES MÁXIMAS POR MARCHA
-- ======================================================================== 
local function refreshGearData()
	local carID = ac.getCarID(0) or ""
	local gearCount = car.gearCount or 0
	
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
	end
end

-- ======================================================================== 
-- CÁLCULO DO GEAR RATIO ENTRE DUAS MARCHAS
-- ======================================================================== 
local function getGearRatio(fromGear, toGear)
	refreshGearData()
	
	local vFrom = gearMaxSpeeds[fromGear]
	local vTo   = gearMaxSpeeds[toGear]
	
	if vFrom and vTo and vFrom > 0 and vTo > 0 then
		local ratio = vTo / vFrom
		if ratio >= 1.05 and ratio <= 3.0 then
			return ratio
		end
	end
	
	-- Fallback: fórmula linear genérica
	local gearDiff = fromGear - toGear
	return 1.0 + (gearDiff * 0.4)
end

-- ======================================================================== 
-- DURAÇÃO ADAPTATIVA POR GEAR RATIO
-- Quanto maior o gap entre marchas, mais tempo de corte é necessário
-- ======================================================================== 
local function getAdaptiveDuration(fromGear, toGear)
	local ratio = getGearRatio(fromGear, toGear)
	-- Base: 80ms, adiciona até (ratio - 1.0) × 150ms
	-- Ex: ratio 1.2 → ~110ms | ratio 1.5 → ~155ms | ratio 2.0 → ~230ms
	local adaptive = 80 + (ratio - 1.0) * 150
	return math.max(60, math.min(adaptive, 400))
end

-- ======================================================================== 
-- API PÚBLICA: integração com outros módulos
-- ======================================================================== 
function nls.isShifting()
	return nlsActive
end

-- ======================================================================== 
-- MAIN UPDATE
-- ======================================================================== 
function nls.update(dt, data, currentGear, currentGas)
	
	-- Verificar se está habilitado
	if not cfg.NLS_ENABLED then
		prevGear = currentGear
		nlsActive = false
		return currentGas
	end
	
	-- ── 1. DETECTAR TROCA DE MARCHA PARA CIMA ────────────────────────
	if currentGear > prevGear and prevGear > 0 and prevGear ~= -999 then
		local shouldActivate = true
		
		-- Verificar RPM mínimo (CORREÇÃO: usa cfg.NLS_MIN_RPM)
		if car.rpm < cfg.NLS_MIN_RPM then
			shouldActivate = false
		end
		
		if shouldActivate then
			nlsActive = true
			nlsStartTime = os.preciseClock()
			nlsCurrentThrottle = currentGas
			expectedGear = currentGear
			missShiftTimer = 0.08  -- 80ms de graça para confirmar troca
			
			-- Duração: adaptativa ou fixa
			if cfg.NLS_ADAPTIVE_DURATION then
				nlsDuration = getAdaptiveDuration(prevGear, currentGear)
			else
				nlsDuration = cfg.NLS_CUT_DURATION
			end
			
			ac.log('[NLS] Ativado! Marcha: ' .. tostring(prevGear) .. ' -> ' .. tostring(currentGear) .. 
			       ' | RPM: ' .. tostring(math.floor(car.rpm)) .. 
			       ' | TPS inicial: ' .. tostring(math.floor(currentGas * 100)) .. '%' ..
			       ' | Duração: ' .. tostring(math.floor(nlsDuration)) .. 'ms')
		end
	end
	
	prevGear = currentGear
	
	-- ── 2. PROCESSAR NO-LIFT SHIFT ATIVO ─────────────────────────────
	if nlsActive then
		local elapsedTime = (os.preciseClock() - nlsStartTime) * 1000  -- em ms
		
		-- Verificar miss-shift
		if missShiftTimer > 0 then
			missShiftTimer = missShiftTimer - dt
			-- Se marcha voltou pra anterior ou foi pra uma menor, cancela IMEDIATAMENTE
			if currentGear < expectedGear then
				nlsActive = false
				ac.log('[NLS] Miss-shift detectado! Marcha voltou. Cancelando corte.')
				return currentGas
			end
		else
			-- Timer expirou e marcha ainda não é a esperada (neutro, etc)
			if currentGear ~= expectedGear then
				nlsActive = false
				ac.log('[NLS] Miss-shift detectado! Marcha não confirmada. Cancelando corte.')
				return currentGas
			end
		end
		
		-- Verificar se o tempo de corte expirou
		if elapsedTime > nlsDuration then
			nlsActive = false
			ac.log('[NLS] Corte finalizado. Iniciando ramp-up suave.')
			-- NÃO retorna aqui! Cai pro bloco de ramp-up pós-corte abaixo.
		else
			-- Ainda no corte: aproxima do teto mínimo
			local targetThrottle = currentGas * cfg.NLS_CUT_AMOUNT
			-- CORREÇÃO: usa cfg.NLS_RELEASE_MULT (antes hardcoded ×2.0)
			local releaseSpeed = cfg.GAS_RELEASE_SPEED * cfg.NLS_RELEASE_MULT
			nlsCurrentThrottle = pedals.approach(nlsCurrentThrottle, targetThrottle, releaseSpeed, dt)
			return nlsCurrentThrottle
		end
	end
	
	-- ── 3. RAMP-UP / RAMP-DOWN SUAVE PÓS-CORTE ───────────────────────
	-- Mesmo depois de desativar, suaviza o retorno ao throttle do jogador
	-- Isso evita o "jump" instantâneo quando o corte termina
	local throttleDelta = math.abs(nlsCurrentThrottle - currentGas)
	if throttleDelta > 0.001 then
		local speed
		if nlsCurrentThrottle < currentGas then
			-- Subindo: usar press speed × release mult
			speed = cfg.GAS_PRESS_SPEED * cfg.NLS_RELEASE_MULT
		else
			-- Descendo: usar release speed × release mult
			speed = cfg.GAS_RELEASE_SPEED * cfg.NLS_RELEASE_MULT
		end
		nlsCurrentThrottle = pedals.approach(nlsCurrentThrottle, currentGas, speed, dt)
		return nlsCurrentThrottle
	end
	
	return currentGas
end

return nls
