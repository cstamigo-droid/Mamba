-- Mamba_Mapa: sus interruptores en Ajustes › Mamba › «Qué se muestra» (K124). Son los mismos ajustes de
-- Interfaz › Mapa (MambaMapaDB); set aplica en el momento. Licencia: GPL-3.0-only.
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

local function ajuste(clave, despues)
	return function() return M.DB()[clave] and true or false end,
		function(v)
			M.DB()[clave] = v and true or false
			if despues then pcall(despues) end
			M.Cambio()
			pcall(M.ActualizarCoords)
		end
end

for _, x in ipairs({
	{ "coords", "Coordenadas bajo el minimapa", "Tu posición en la zona. Si Polestar u otro accesorio ya las muestra, Mamba no repite las suyas." },
	{ "coordsMapa", "Coordenadas en el mapa del mundo", "La tuya y la del cursor, abajo del mapa." },
	{ "nodos", "Nodos de hierbas y vetas en el mapa", "Puntos verdes (hierbas) y dorados (vetas)." },
	{ "nodosMinimapa", "Nodos también en el minimapa" },
	{ "verHierbas", "Mostrar hierbas" },
	{ "verVetas", "Mostrar vetas" },
	{ "ocultarBotones", "Botones del minimapa solo al pasar el ratón", nil, function() M.AplicarMinimapa() end },
	{ "ruedaZoom", "Zoom del minimapa con la rueda", nil, function() M.AplicarMinimapa() end },
}) do
	local get, set = ajuste(x[1], x[4])
	publicar({ id = "mapa." .. x[1], addon = "Mamba_Mapa", grupo = "Mapa", nombre = x[2], ayuda = x[3], get = get, set = set })
end
