-- Mamba_Plan: sus interruptores en Opciones (K124: todo se prende y se apaga desde Opciones, sin comandos).
--   plan.inicio  "Mi plan: preguntar al entrar"  el asistente de inicio la primera vez (por personaje)
--   plan.cuadro  "Mi plan en el cuadro del objeto"  la línea "Es la bolsa de tu plan" / "VITAL…"
-- Cada uno se aplica en el momento, sin recargar. Licencia: GPL-3.0-only.
local _, M = ...

local function publicar(spec)
	local api = _G.MambaAPI
	if type(api) == "table" and api.Interruptor then
		local ok, err = api.Interruptor(spec)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	else
		_G.MambaInterruptoresPendientes = _G.MambaInterruptoresPendientes or {}
		table.insert(_G.MambaInterruptoresPendientes, spec)
	end
end

publicar({ id = "plan.inicio", addon = "Mamba_Plan", nombre = "Mi plan: preguntar al entrar", grupo = "Mi plan",
	ayuda = "La primera vez que el personaje entra con Mamba, abre las preguntas de inicio (rol, para qué juegas, build y profesiones).",
	get = function() return not M.PJ().noPreguntar end,
	set = function(v) M.PJ().noPreguntar = (not v) or nil end })

publicar({ id = "plan.cuadro", addon = "Mamba_Plan", nombre = "Mi plan en el cuadro del objeto", grupo = "Mi plan",
	ayuda = "Dice en el cuadro del objeto si tu plan lo necesita (por ejemplo, la bolsa que te recomienda).",
	get = function() return not M.PJ().sinCuadro end,
	set = function(v) M.PJ().sinCuadro = (not v) or nil end })
