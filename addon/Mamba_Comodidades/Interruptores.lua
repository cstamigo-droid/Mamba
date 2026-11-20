-- Mamba_Comodidades: sus interruptores en Ajustes › Mamba › Qué se muestra (K124, regla de Cristian: todo se
-- enciende y se apaga desde Opciones, sin comandos). Registro: Asistente/Interruptores.lua (MambaAPI.Interruptor).
-- Cada set aplica en el momento, sin recargar. Se publican al entrar (PLAYER_LOGIN, Inicio.lua): los que dependen
-- de Polestar, de una opción del juego o de ForeverLootSparkles solo si están (un interruptor que no puede hacer
-- nada no se muestra). Licencia: GPL-3.0-only.
local _, M = ...

local ADDON, GRUPO = "Mamba_Comodidades", "Comodidades"

local function publicar(spec)
	spec.addon = ADDON
	local api = _G.MambaAPI
	if type(api) == "table" and api.Interruptor then
		local ok, err = api.Interruptor(spec)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	else
		_G.MambaInterruptoresPendientes = _G.MambaInterruptoresPendientes or {}
		table.insert(_G.MambaInterruptoresPendientes, spec)
	end
end

function M.PublicarInterruptores()
	local R, C = M.Raros, M.Comodidades
	local o = R.Opciones()
	publicar({ id = "comodidades.raro_cara", grupo = "Avisos", nombre = "La cara del raro en el aviso",
		ayuda = "Cuando Polestar avisa de un raro, su cara sale a la izquierda del aviso.",
		get = function() return R.Opciones().miniatura and true or false end,
		set = function(v)
			R.Opciones().miniatura = v and true or false
			local mini = _G.MambaRaroMiniatura
			if not v and mini then mini:Hide() end
			if M.RefrescarPanel then pcall(M.RefrescarPanel) end
		end })
	publicar({ id = "comodidades.macro_raros", grupo = GRUPO, nombre = "Macro de raros al día solo",
		ayuda = "Al cambiar de zona y al ver un raro, Mamba reescribe el macro MambaRaros con los raros de la zona.",
		get = function() return R.Opciones().macro and true or false end,
		set = function(v)
			R.Opciones().macro = v and true or false
			if v then pcall(R.ActualizarMacro) end
			if M.RefrescarPanel then pcall(M.RefrescarPanel) end
		end })
	local items = {}
	for _, it in ipairs(C.LISTA) do items[#items + 1] = it end
	for _, it in ipairs(C.Sonidos()) do
		it.titulo = "Silenciar: " .. it.titulo:sub(1, 1):lower() .. it.titulo:sub(2)
		items[#items + 1] = it
	end
	for _, it in ipairs(items) do
		if C.Disponible(it) then
			local clave = it.clave:gsub("[^%w]", "_")
			publicar({ id = "comodidades." .. clave, grupo = GRUPO, nombre = it.titulo, ayuda = it.ayuda,
				get = function() return C.Valor(it) and true or false end,
				set = function(v)
					C.Poner(it, v)
					if M.RefrescarPanel then pcall(M.RefrescarPanel) end
				end })
		end
	end
	return o
end
