-- K124: los interruptores del Tasador en Ajustes › Mamba › Qué se muestra (registro: Asistente/Interruptores.lua).
-- Sin Asistente quedan en _G.MambaInterruptoresPendientes y no se ven (el Tasador sigue igual, todo encendido).
-- Licencia: GPL-3.0.
local _, T = ...

local function fijar(clave, v)
	TasadorDB = TasadorDB or {}
	TasadorDB.ajustes = TasadorDB.ajustes or {}
	T.db = T.db or TasadorDB
	-- encendido = nil (lo de siempre); apagado = false. (Ojo: «(not v) and false or nil» da siempre nil.)
	if v then T.db.ajustes[clave] = nil else T.db.ajustes[clave] = false end
end

local function publicar(spec)
	spec.addon = "Tasador"
	local api = _G.MambaAPI
	if type(api) == "table" and api.Interruptor then
		local ok, err = api.Interruptor(spec)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	else
		_G.MambaInterruptoresPendientes = _G.MambaInterruptoresPendientes or {}
		table.insert(_G.MambaInterruptoresPendientes, spec)
	end
end

publicar({ id = "tasador.cuadro", nombre = "Bloque «Mamba» en el cuadro de los objetos", grupo = "Objetos y subasta",
	ayuda = "Al pasar el ratón por un objeto: si te sirve, qué hacer con él y cuánto vale.",
	get = function() return T.Encendido("cuadro") end, set = function(v) fijar("cuadro", v) end })

publicar({ id = "tasador.escanear", nombre = "Botón «Escanear (Tasador)» en la subasta", grupo = "Objetos y subasta",
	ayuda = "El botón que lee los precios de la casa de subastas.",
	get = function() return T.Encendido("escanear") end,
	set = function(v) fijar("escanear", v); if T.AplicarBotonEscanear then T.AplicarBotonEscanear() end end })

publicar({ id = "tasador.recompensa", nombre = "Recompensa recomendada al entregar una misión", grupo = "Misiones",
	ayuda = "Marca la recompensa que más te conviene y dice por qué. El clic sigue siendo tuyo.",
	get = function() return T.Encendido("recompensa") end,
	set = function(v) fijar("recompensa", v); if not v and T.OcultarFranjaRecompensa then T.OcultarFranjaRecompensa() end end })

publicar({ id = "tasador.alerta", nombre = "Aviso de enemigos cerca (fuera de mazmorras)", grupo = "Avisos",
	ayuda = "Avisa cuando ves a un jugador de la otra facción. Solo avisa: no apunta ni ataca.",
	get = function() return T.Encendido("alerta") end, set = function(v) fijar("alerta", v) end })
