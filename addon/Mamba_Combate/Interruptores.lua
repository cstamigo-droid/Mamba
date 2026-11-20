-- Mamba_Combate: K124 (regla de Cristian: todo se enciende y se apaga desde Opciones, sin comandos). Cada parte
-- de combate que muestra o avisa algo publica su interruptor en Ajustes › Mamba › «Qué se muestra»
-- (MambaAPI.Interruptor; si Asistente todavía no cargó, queda en _G.MambaInterruptoresPendientes). set aplica en
-- el momento, sin recargar: guarda el ajuste y avisa a todos los módulos (M.Cambio). Ningún marco de Mamba_Combate
-- es seguro: esconderlos en combate no da «acción bloqueada». Los mismos ajustes están en Combate › Avisos y barras.
-- Licencia: GPL-3.0-only.
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

-- Lo que se redibuja al cambiar un interruptor (además de M.Cambio, que ya refresca rotación, placas, medidor,
-- ficha, marcadores, barra Cerca y transparencia).
local function refrescar()
	M.Cambio()
	if M.Amenaza and M.Amenaza.Dibujar then M.Proteger("amenaza", M.Amenaza.Dibujar) end
	if M.Agro and M.Agro.Dibujar then M.Proteger("agro", M.Agro.Dibujar) end
	if M.Disparo and M.Disparo.Refrescar then M.Proteger("disparo", M.Disparo.Refrescar) end
end

-- Interruptores de sí/no: { id, clave en MambaCombateDB, nombre, ayuda }
M.INTERRUPTORES = {
	{ "combate.sugerencia", "sugerencia", "Sugerencia del próximo hechizo", "Un recuadro con el próximo hechizo de tu prioridad y su tecla. Solo muestra: tú decides y lanzas." },
	{ "combate.resaltar", "resaltar", "Marcar el próximo hechizo en tus barras", "Un borde dorado en el botón." },
	{ "combate.medidor", "medidor", "Medidor de combate en pantalla", "Daño, curación o daño recibido del medidor del juego." },
	{ "combate.amenaza", "amenaza", "Amenaza del grupo", "Tu amenaza y la del grupo sobre tu objetivo (solo en grupo)." },
	{ "combate.placas", "placas", "Placas de nombre compactas", "Barra fina en los enemigos; apagadas vuelven las del juego." },
	{ "combate.ficha", "ficha", "Ficha del enemigo (contra jugadores)", "Clase, controles, defensas y qué guardar para responder." },
	{ "combate.agro", "agro", "Indicador de agro al acercarte", "Fuera de combate: de verde a rojo cuando estás por atraer un bicho hostil." },
	{ "combate.avisos", "avisos", "Avisos en pantalla", "Te controlaron, un enemigo usó un control o una defensa, maná bajo, amenaza alta." },
	{ "combate.sonido", "sonido", "Sonido cuando te controlan", nil },
	{ "combate.disparo", "disparo", "Temporizador del disparo y del golpe", "Cazador: rojo el último medio segundo antes del disparo automático." },
	{ "combate.lanzamiento", "lanzamiento", "Barra de lanzamiento", "Con tu retraso de conexión y la espera entre hechizos." },
	{ "combate.cercanosSola", "cercanosSola", "Abrir sola la ventana grande de enemigos cerca", "Apagado: basta la barrita «Cerca: N»." },
}
-- Los de varias opciones se publican como sí/no: encendido = «siempre», apagado = «nunca».
M.INTERRUPTORES_MODO = {
	{ "combate.cercaBarra", "cercaBarra", "Barrita «Cerca: N» (enemigos cerca)", "Como la barra de Spy. En Combate › Avisos y barras también se puede dejar «solo cuando hay enemigos»." },
	{ "combate.marcadores", "marcadores", "Barra de marcadores de banda", "Calavera, cruz, luna… Clic: marca a tu objetivo." },
}

for _, x in ipairs(M.INTERRUPTORES) do
	local id, clave, nombre, ayuda = x[1], x[2], x[3], x[4]
	publicar({ id = id, addon = "Mamba_Combate", grupo = "Combate", nombre = nombre, ayuda = ayuda,
		get = function() return M.DB()[clave] == true end,
		set = function(v) M.DB()[clave] = v and true or false; refrescar() end })
end
for _, x in ipairs(M.INTERRUPTORES_MODO) do
	local id, clave, nombre, ayuda = x[1], x[2], x[3], x[4]
	publicar({ id = id, addon = "Mamba_Combate", grupo = "Combate", nombre = nombre, ayuda = ayuda,
		get = function() return M.DB()[clave] ~= "nunca" end,
		set = function(v)
			local d = M.DB()
			if v then if d[clave] == "nunca" then d[clave] = "siempre" end else d[clave] = "nunca" end
			refrescar()
		end })
end
