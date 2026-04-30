-- ========================================================================
-- DSS AUTO-BLIP MODULE
-- ========================================================================
-- Auto-blip inteligente que calcula o RPM ideal da marcha inferior
-- Com suavização attack/release para curva realista de throttle
-- ========================================================================

local cfg = require "dss_config"
local pedals = require "dss_pedals"

local blip = {}

-- Estado interno
local prevGear = -999
local blipActive = false
local blipStartTime = 0
local targetRPM = 0
local blipSmoothed = 0  -- valor suavizado do throttle do blip

function blip.update(dt, data, currentGear, currentGas)
	
	-- ── 1. DETECTAR REDUÇÃO DE MARCHA ────────────────────────────────
	if cfg.BLIP_ENABLED and currentGear > 0 and prevGear > currentGear and prevGear ~= -999 then
		-- Redução detectada! Calcular RPM alvo
		
		-- Pegar dados do carro
		local currentRPM = car.rpm
		local speedKmh = math.abs(car.speedKmh)
		
		-- Calcular fator baseado na diferença de marchas
		local gearDiff = prevGear - currentGear
		local blipFactor = 1.0 + (gearDiff * 0.4)  -- cada marcha = +40% de RPM
		
		targetRPM = currentRPM * blipFactor
		
		-- Limitar ao RPM do limiter (segurança)
		if car.rpmLimiter and car.rpmLimiter > 0 then
			targetRPM = math.min(targetRPM, car.rpmLimiter * 0.95)  -- 95% do limiter
		else
			targetRPM = math.min(targetRPM, 9000)  -- fallback seguro
		end
		
		-- Só ativar se a diferença for significativa
		local rpmDiff = targetRPM - currentRPM
		if rpmDiff > cfg.BLIP_MIN_RPM_DIFF then
			blipActive = true
			blipStartTime = os.preciseClock()
			ac.log('[AUTO-BLIP] Ativado! Marcha: ' .. tostring(prevGear) .. ' -> ' .. tostring(currentGear) .. 
			       ' | RPM atual: ' .. tostring(math.floor(currentRPM)) .. 
			       ' | RPM alvo: ' .. tostring(math.floor(targetRPM)) .. 
			       ' | Diferença: ' .. tostring(math.floor(rpmDiff)))
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
		local elapsedTime = (os.preciseClock() - blipStartTime) * 1000  -- em ms
		
		-- Calcular erro de RPM
		local rpmError = targetRPM - currentRPM
		
		-- Calcular throttle TARGET proporcional ao erro
		local blipTarget = 0
		if rpmError > 0 then
			-- Fórmula agressiva para dar mais gás
			blipTarget = (rpmError / 2000.0) * cfg.BLIP_INTENSITY
			
			-- Garantir um mínimo de 30% de throttle sempre
			blipTarget = math.max(blipTarget, 0.3)
			
			-- Clamp entre 0 e 1
			blipTarget = math.min(math.max(blipTarget, 0), 1.0)
		end
		
		-- Condições para desativar o blip
		local rpmReached = math.abs(rpmError) < 100  -- tolerância de ±100 RPM
		local timeExpired = elapsedTime > cfg.BLIP_DURATION
		
		if rpmReached or timeExpired then
			blipActive = false
			-- NÃO zera blipSmoothed aqui! Deixa o release suavizar naturalmente
			ac.log('[AUTO-BLIP] Desativado! Tempo: ' .. tostring(math.floor(elapsedTime)) .. 
			       'ms | RPM final: ' .. tostring(math.floor(currentRPM)) .. 
			       ' | Alvo: ' .. tostring(math.floor(targetRPM)))
		end
		
		-- Suavizar com attack speed (subindo)
		local speed = blipTarget > blipSmoothed and cfg.BLIP_ATTACK_SPEED or cfg.BLIP_RELEASE_SPEED
		blipSmoothed = pedals.approach(blipSmoothed, blipTarget, speed, dt)
		
		-- Retornar o maior entre o gás do jogador e o blip suavizado
		return math.max(currentGas, blipSmoothed)
	end
	
	-- ── 3. RELEASE SUAVE PÓS-BLIP ───────────────────────────────────
	-- Mesmo depois de desativar, suaviza o blipSmoothed até 0
	if blipSmoothed > 0.001 then
		blipSmoothed = pedals.approach(blipSmoothed, 0, cfg.BLIP_RELEASE_SPEED, dt)
		return math.max(currentGas, blipSmoothed)
	end
	
	blipSmoothed = 0
	
	-- Sem blip ativo, retorna o gás normal
	return currentGas
end

return blip