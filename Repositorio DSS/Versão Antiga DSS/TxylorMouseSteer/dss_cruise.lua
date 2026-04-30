-- ========================================================================
-- DSS CRUISE MODE MODULE
-- ========================================================================
-- Modo passeio: limita acelerador e freio em baixa velocidade
-- Ativado/desativado pela checkbox na config
-- ========================================================================

local cfg = require "dss_config"

local cruise = {}

function cruise.update(dt, data)
	if not cfg.CRUISE_ENABLED then return end

	-- ── CALCULAR FATOR DE LIMITAÇÃO BASEADO NA VELOCIDADE ────────────
	local speed = math.abs(car.speedKmh)
	
	-- Fator: 0.0 = parado (máxima limitação), 1.0 = cruise_full_speed+ (sem limitação)
	local factor = 0.0
	if cfg.CRUISE_FULL_SPEED > 0 then
		factor = math.min(speed / cfg.CRUISE_FULL_SPEED, 1.0)
	end

	-- ── LIMITAR GAS ─────────────────────────────────────────────────
	local gasLimit = cfg.CRUISE_GAS_MIN + (1.0 - cfg.CRUISE_GAS_MIN) * factor
	data.gas = math.min(data.gas, gasLimit)

	-- ── LIMITAR BRAKE ───────────────────────────────────────────────
	local brakeLimit = cfg.CRUISE_BRAKE_MIN + (1.0 - cfg.CRUISE_BRAKE_MIN) * factor
	data.brake = math.min(data.brake, brakeLimit)
end

return cruise
