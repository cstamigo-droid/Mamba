-- Mamba_Curacion: sus interruptores en Ajustes › Mamba › «Qué se muestra» (K124). Los marcos son seguros: en
-- combate no se muestran ni se esconden (M.MostrarSegun deja el cambio pendiente y se aplica al salir de
-- combate, PLAYER_REGEN_ENABLED). Licencia: GPL-3.0-only.
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

publicar({ id = "curacion.marcos", addon = "Mamba_Curacion", grupo = "Curación",
	nombre = "Marcos de grupo con clic para curar",
	ayuda = "Encendido: se ven en grupo (o como elegiste en Interfaz › Curación). En combate, el cambio se aplica al terminar la pelea.",
	get = function() return M.DB().mostrar ~= "nunca" end,
	set = function(v)
		local d = M.DB()
		if v then d.mostrar = (d.mostrarAntes and d.mostrarAntes ~= "nunca") and d.mostrarAntes or "grupo"
		else
			if d.mostrar ~= "nunca" then d.mostrarAntes = d.mostrar end
			d.mostrar = "nunca"
		end
		M.MostrarSegun()
	end })

local function ajuste(clave)
	return function() return M.DB()[clave] and true or false end,
		function(v) M.DB()[clave] = v and true or false; M.PintarTodo() end
end
for _, x in ipairs({
	{ "hots", "Mis efectos de curación con su cuenta regresiva" },
	{ "limpiar", "Marcar lo que puedo limpiar" },
	{ "rango", "Atenuar a quien está fuera de alcance" },
}) do
	local get, set = ajuste(x[1])
	publicar({ id = "curacion." .. x[1], addon = "Mamba_Curacion", grupo = "Curación", nombre = x[2], get = get, set = set })
end
