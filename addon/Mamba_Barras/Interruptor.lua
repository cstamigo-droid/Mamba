-- Mamba_Barras: su interruptor en Opciones (K124, regla de Cristian: todo se prende y se apaga desde Opciones,
-- sin comandos). "Usar las barras de Mamba": apagado, las barras de Mamba se esconden y vuelven las del juego,
-- con tus teclas de siempre; prendido, vuelven las de Mamba. Son marcos seguros: en combate el cambio espera a
-- que termine la pelea. Licencia: GPL-3.0-only.
local _, M = ...

local function aplicar()
	local apagado = M.PJ().apagado
	if apagado then
		for _, h in pairs(M.marcos) do
			UnregisterStateDriver(h, "visibility")
			h:Hide()
		end
		if M.TerminarMover then M.TerminarMover() end
		if M.TerminarTeclas and M.asignando then M.TerminarTeclas() end
		M.MostrarJuego()
		M.AplicarTeclas() -- con apagado solo quita los atajos de Mamba
	elseif not M.listo then
		M.Construir()
	else
		M.EsconderJuego()
		for id, h in pairs(M.marcos) do if M.Config(id).mostrar then h:Show() end end
		M.DisponerTodo() -- su condición de visibilidad vuelve a mandar
		M.AplicarTeclas()
	end
end
M.AplicarInterruptor = aplicar

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

publicar({ id = "barras.usar", addon = "Mamba_Barras", nombre = "Usar las barras de Mamba", grupo = "Interfaz",
	ayuda = "Apagado: vuelven las barras del juego, con tus mismas teclas. En combate, el cambio se hace al terminar la pelea.",
	get = function() return not M.PJ().apagado end,
	set = function(v)
		M.PJ().apagado = (not v) or nil
		M.FueraDeCombate("interruptor", aplicar)
	end })
