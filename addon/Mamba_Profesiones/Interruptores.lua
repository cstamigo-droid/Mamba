-- Mamba_Profesiones: sus interruptores en Ajustes › Mamba › «Qué se muestra» (K124: todo se enciende y se apaga
-- desde Opciones, sin comandos). set aplica en el momento. Licencia: GPL-3.0-only.
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

-- apagado = true en la base: lo que no se tocó queda encendido
local function flag(clave)
	return function() return not M.DB()["sin_" .. clave] end,
		function(v) M.DB()["sin_" .. clave] = (not v) or nil; M.Cambio() end
end

local g1, s1 = flag("vital")
publicar({ id = "profesiones.vital", addon = "Mamba_Profesiones", grupo = "Profesiones",
	nombre = "Marcar los materiales VITALES para tus profesiones",
	ayuda = "En el cuadro del objeto dice si lo necesitas para subir una profesión, y la venta automática no lo vende. Lo que nunca se vende (misión, llaves…) sigue protegido aunque lo apagues.",
	get = g1, set = s1 })
local g2, s2 = flag("medir")
publicar({ id = "profesiones.medir", addon = "Mamba_Profesiones", grupo = "Profesiones",
	nombre = "Medir lo que farmeas con «Llévame»",
	ayuda = "Cuenta cuánto juntas por hora para corregir las estimaciones de la lista de compra.",
	get = g2, set = function(v) s2(v); if not v and M.Medir then M.Medir.Parar() end end })
local g3, s3 = flag("recetas")
publicar({ id = "profesiones.recetas", addon = "Mamba_Profesiones", grupo = "Profesiones",
	nombre = "Leer tus recetas al abrir la ventana de profesión",
	ayuda = "Sirve para «Ganar oro fabricando».",
	get = g3, set = s3 })
