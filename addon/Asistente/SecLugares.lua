-- Asistente/SecLugares.lua: las secciones «Ir a…» y «Servicios» del hub.
-- Ir a…: buscas un servicio (el más cercano EN TIEMPO), una ciudad, una zona, una mazmorra o un PNJ; el motor
-- (Asistente/Llevame.lua, fila K58) arma la ruta más rápida con el planificador de Polestar, tramo por tramo y con el
-- tiempo de cada uno (piedra de hogar, vuelos, zepelines, portales, a pie), da 2-3 alternativas y «Llevarme» pone la
-- flecha. Mientras calcula dice «calculando…»: nunca un número inventado (R0: «≈» = estimado).
-- Servicios: la lista de servicios de una ciudad, el más cercano primero, con su botón «Ir» (el mismo motor).
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local Hub = A.Hub
local format = string.format

local function S() return A.modulos and A.modulos.servicios end
local function cargado(a) return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(a) end

local function posicion()
	local m = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if not m then return nil end
	local p = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(m, "player")
	if not p then return m end
	local x, y = p:GetXY()
	return m, x, y
end

---------------------------------------------------------------- los destinos
-- El motor es Asistente/Llevame.lua (K58): busca servicios (el más cercano EN TIEMPO), ciudades, zonas, mazmorras
-- y PNJ; arma la ruta tramo por tramo con el planificador de Polestar y da 2-3 alternativas.
local function LL() return A.Llevame end

-- Además de los del motor, los servicios de una ciudad en particular ("banco de Orgrimmar").
local function deCiudad(s)
	local out = {}
	if not (s and s.datos) then return out end
	for um, c in pairs(s.datos.ciudades or {}) do
		local ciudad = (C_Map and C_Map.GetMapInfo and (C_Map.GetMapInfo(um) or {}).name) or c.nombre
		for _, g in ipairs(s.Grupos(um, nil) or {}) do
			local l = g.mejor
			if l.px and l.py then
				out[#out + 1] = { tipo = "servicio", clave = "s:" .. um .. ":" .. g.etiqueta, nombre = g.etiqueta .. " de " .. tostring(ciudad),
					sub = "Servicio · " .. tostring(ciudad), grupo = g, map = um, x = l.px, y = l.py, buscar = g.nombres }
			end
		end
	end
	return out
end

local ICONO = { mazmorra = "Interface\\Minimap\\Dungeon", servicio = "Interface\\Minimap\\Tracking\\None", ciudad = "Interface\\Minimap\\Tracking\\FlightMaster",
	zona = "Interface\\Minimap\\Tracking\\FlightMaster", pnj = "Interface\\Minimap\\Tracking\\None", punto = "Interface\\Minimap\\Tracking\\None",
	mision = "Interface\\GossipFrame\\AvailableQuestIcon", objeto = "Interface\\Icons\\INV_Misc_Bag_10" }
local COL = { mazmorra = "|cffa385ff", servicio = "|cff94c9ff", ciudad = "|cfff2d27a", zona = "|cffd8c7a0", pnj = "|cff9fe0a8", punto = "|cffd0d0d0", mision = "|cfffad25a", objeto = "|cff0070dd" }

local function normal(t)
	local l = LL()
	if l then return l.Normal(t) end
	return tostring(t or ""):lower()
end

---------------------------------------------------------------- «Ir a…»
local function sugeridos(lista)
	local out, quiero = {}, {}
	local rec = A.MazmorraRecomendada and A.MazmorraRecomendada()
	if rec then quiero["m:" .. rec.clave] = 1 end
	for _, k in ipairs({ "c:banco", "c:subasta", "c:posada", "c:vuelo", "c:clase", "z:1454", "z:1456", "z:1458" }) do quiero[k] = 1 end
	for _, d in ipairs(lista) do
		if quiero[d.clave] then out[#out + 1] = d end
	end
	return out
end

local recientes = {}
local MOTIVO = {
	combate = "Estás en combate: sal de combate y vuelve a apretar «Llevarme».",
	no_encontrado = "No encontré ese lugar.",
	sin_entrada = "No conozco la entrada de este lugar: búscalo en el mapa del mundo.",
	sin_ruta = "Polestar no encontró una ruta hasta ahí desde donde estás.",
	sin_polestar = "Falta Polestar (la base de Mamba): sin él no hay flecha.",
}
local function llevar(est, d, clave)
	local l = LL()
	local ok, info = false, "sin_polestar"
	if l then ok, info = l.Llevame(d, { ruta = clave }) end
	if ok then
		local r = info.ruta
		est.aviso = "La flecha te guía" .. (r and (" por «" .. r.nombre .. "»") or "") .. ". Los tramos siguen en el panel de la guía."
	else
		est.aviso = MOTIVO[info] or MOTIVO.sin_ruta
	end
	for i = #recientes, 1, -1 do if recientes[i].clave == d.clave then table.remove(recientes, i) end end
	table.insert(recientes, 1, d)
	while #recientes > 8 do table.remove(recientes) end
end

-- La ruta, tramo por tramo: "1. Piedra de hogar a Cima del Trueno · 15 s"
local function textoTramos(l, r)
	if r.sinTramos then return "Tiempo total " .. l.Tiempo(r.total, true) .. " (esta versión de Polestar no da los tramos)." end
	if #r.tramos == 0 then return "Ya estás ahí." end
	local t, ajustado = {}, false
	for i, x in ipairs(r.tramos) do
		local tiempo = l.Tiempo(x.seg, x.estimado)
		if x.medido then tiempo = "|cff9fe0a8" .. tiempo .. " medido|r" end
		t[#t + 1] = format("%d. %s  |cff9ba2b9·|r  %s", i, x.texto, tiempo)
		ajustado = ajustado or x.ajustado
	end
	local pie = "|cffffffffTotal " .. l.Tiempo(r.total, r.estimado) .. "|r"
	if r.estimado then pie = pie .. "  |cff9ba2b9(≈ estimado por Polestar" .. (ajustado and ", corregido con tus viajes" or "") .. ")|r" end
	t[#t + 1] = pie
	return table.concat(t, "\n")
end

local reintento = false
local function otraVez()
	if reintento then return end
	reintento = true
	C_Timer.After(0.3, function() reintento = false; Hub.Redibujar() end)
end

Hub.Seccion({
	clave = "MambaIrA", nombre = "Ir a…", icono = "icon-goto", orden = 120, addon = "Asistente_Servicios",
	pestanas = { { key = "buscar", label = "Buscar" }, { key = "recientes", label = "Recientes" } },
	titulo = function() return "Ir a…", "Elige un lugar: Mamba te da la ruta más rápida, tramo por tramo, y pone la flecha" end,
	buscar = { "Un servicio, una ciudad, un poblado, una mazmorra, un PNJ, una misión o un objeto", "Buscar un lugar", "Buscar" },
	nav = function(est)
		return { { key = "todo", label = "Todo" }, { key = "servicio", label = "Servicios" }, { key = "ciudad", label = "Ciudades" },
			{ key = "zona", label = "Zonas y lugares" }, { key = "mazmorra", label = "Mazmorras" }, { key = "pnj", label = "PNJ" },
			{ key = "mision", label = "Misiones" }, { key = "objeto", label = "Objetos" } }, est.filtro or "todo"
	end,
	dibujar = function(est, V)
		if not cargado("Asistente_Equipo") and A.Cargar then A.Cargar("Asistente_Equipo", function() Hub.Redibujar() end) end
		local l = LL()
		if not l then V:Vacio("Falta el motor de rutas", "Reinstala Mamba: falta Asistente/Llevame.lua.") return end
		local q = normal(est.busqueda or "")
		local vis = {}
		if est.pestana == "recientes" then
			vis = recientes
		elseif q ~= "" then
			vis = {}
			for _, d in ipairs(l.Buscar(est.busqueda)) do vis[#vis + 1] = d end -- copia: la búsqueda queda guardada en el motor
			for _, d in ipairs(deCiudad(S())) do
				local c = l.Calce(d, q)
				if c > 0 then d.calce = c - 5; vis[#vis + 1] = d end
			end
			table.sort(vis, function(a, b) if (a.calce or 0) ~= (b.calce or 0) then return (a.calce or 0) > (b.calce or 0) end return tostring(a.nombre or "") < tostring(b.nombre or "") end)
		else
			vis = sugeridos(l.Destinos())
		end
		if est.filtro and est.filtro ~= "todo" then
			local f = {}
			for _, d in ipairs(vis) do if d.tipo == est.filtro then f[#f + 1] = d end end
			vis = f
		end
		-- la ruta del elegido, arriba: tramo por tramo, con su tiempo (R0) y las otras formas de llegar
		local sel
		for _, d in ipairs(vis) do if d.clave == est.sel then sel = d end end
		sel = sel or vis[1]
		if sel then
			local punto, no = l.Punto(sel, true)
			local res = punto and (punto.rutas or l.Rutas(punto, true)) or { estado = no or "sin", rutas = {} }
			local r1 = res.rutas[1]
			local txt
			if r1 then
				txt = ""
				if sel.tipo == "servicio" and sel.cat and punto then
					-- mientras falte medir algún candidato no se afirma cuál es el más cercano
					txt = (no == "calculando" and "Por ahora el más rápido: |cffffffff" or "El más cercano en tiempo: |cffffffff") .. tostring(punto.nombre) .. "|r"
						.. (punto.sub and (" · " .. punto.sub) or "") .. (no == "calculando" and "  |cff9ba2b9(midiendo los demás…)|r" or "") .. "\n"
				end
				txt = txt .. textoTramos(l, r1)
			elseif res.estado == "calculando" or no == "calculando" then
				txt = "calculando… Mamba mide cada camino con tu piedra de hogar, tus vuelos, zepelines y portales."
			else
				txt = sel.tipo == "mazmorra" and "No conozco la ruta hasta la entrada: la flecha te lleva desde donde estés."
					or "Polestar no encontró una ruta hasta ahí desde donde estás."
			end
			if res.estado == "calculando" or no == "calculando" or res.incompleto then otraVez() end
			if est.aviso then txt = txt .. "\n|cfffabf4d" .. est.aviso .. "|r"; est.aviso = nil end
			V:Panel({ titulo = "Ruta a " .. (COL[sel.tipo] or "") .. sel.nombre .. "|r", texto = txt, boton = { "Llevarme", function() llevar(est, sel, "rapida") end } })
			if #res.rutas > 1 then
				V:Titulo("Otras formas de llegar")
				V:Columnas({ { "", 520 }, { "", 200 } }, true)
				for i, r in ipairs(res.rutas) do
					V:Fila({ icono = l.ICONO[r.tramos[1] and r.tramos[1].tipo or "walk"], celdas = {
						{ (i == 1 and "|cffffffff" or "") .. r.nombre .. (i == 1 and "|r" or ""), r.nota or l.Resumen(r) },
						{ l.Tiempo(r.total, r.estimado), i == 1 and "la más rápida" or "" } },
						ir = function() llevar(est, sel, r.clave) end, irTexto = "Por aquí" })
				end
			end
		end
		V:Titulo(est.pestana == "recientes" and "Adonde fuiste" or (q ~= "" and "Resultados" or "Sugeridos para ti"))
		if #vis == 0 then
			if est.pestana == "recientes" then V:Vacio("Todavía nada", "Los lugares a los que vayas con «Llevarme» quedan aquí.")
			else V:Vacio("Sin resultados", "No encontré «" .. tostring(est.busqueda or "") .. "». Prueba con menos palabras.") end
			return
		end
		V:Columnas({ { "", 600 }, { "", 200 } }, true)
		for i, d in ipairs(vis) do
			if i > 40 then V:Nota((#vis - 40) .. " más: escribe más palabras para afinar."); break end
			-- cada resultado con su «Llévame», aunque la guía no lo recomiende (K118); un objeto sin lugar conocido, sin botón
			local puede = not (d.tipo == "objeto" and not d.spawns)
			V:Fila({ icono = ICONO[d.tipo], celdas = { { (COL[d.tipo] or "") .. d.nombre .. "|r" .. (d.clave == (sel and sel.clave) and "  |cff9ba2b9‹ elegido|r" or ""), d.sub } },
				clic = function() est.sel = d.clave end, ir = puede and function() est.sel = d.clave; llevar(est, d, "rapida") end or nil, irTexto = puede and "Llévame" or nil })
		end
	end,
})

---------------------------------------------------------------- «Servicios»
Hub.Seccion({
	clave = "MambaServicios", nombre = "Servicios", icono = "icon-talk", orden = 140, addon = "Asistente_Servicios",
	pestanas = { { key = "lista", label = "Servicios" } },
	titulo = function(est)
		local s = S()
		local um = est.ciudad
		local c = s and um and s.datos.ciudades[um]
		return "Servicios" .. (c and (" de " .. (((C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(um)) or {}).name or c.nombre)) or ""),
			"El más cercano primero · «Ir» pone la flecha"
	end,
	buscar = { "Busca un servicio: banco, vuelo, instructor…", "Buscar un servicio", "Buscar" },
	nav = function(est)
		local s = S()
		if not s then return {}, nil end
		local items = {}
		for um, c in pairs(s.datos.ciudades or {}) do
			items[#items + 1] = { key = tostring(um), label = ((C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(um)) or {}).name or c.nombre }
		end
		table.sort(items, function(a, b) return a.label < b.label end)
		return items, est.ciudad and tostring(est.ciudad)
	end,
	onNav = function(est, key) est.ciudad = tonumber(key) end,
	dibujar = function(est, V)
		local s = S()
		if not s then V:Vacio("Falta el módulo de servicios", "Activa «Asistente_Servicios» en la lista de accesorios.") return end
		if not est.ciudad then
			local m = posicion()
			if m and s.datos.ciudades[m] then est.ciudad = m end
			if not est.ciudad then for um in pairs(s.datos.ciudades) do est.ciudad = est.ciudad or um end end
		end
		-- (no "a and f()": eso corta a un solo valor y "y" quedaba nil: la columna Distancia salía vacía, 18-11)
		local x, y
		if s.PosicionJugador then x, y = s.PosicionJugador() end
		local enCiudad = posicion() == est.ciudad or (A.MapaActual and A.MapaActual() == est.ciudad)
		local clase = UnitClass and select(2, UnitClass("player")) or nil
		local grupos = s.Grupos(est.ciudad, clase, enCiudad and x or nil, enCiudad and y or nil) or {}
		if est.busqueda and est.busqueda ~= "" then grupos = s.Buscar(grupos, est.busqueda) end
		if #grupos == 0 then V:Vacio("Sin resultados", "No encontré «" .. tostring(est.busqueda or "") .. "». Prueba con menos palabras.") return end
		V:Botones({ { "Abrir la ventana de servicios", function() if _G.MambaAPI and _G.MambaAPI.AbrirServicios then _G.MambaAPI.AbrirServicios(est.ciudad) end end } },
			"La ventana chica con la lista de esta ciudad, que se queda abierta mientras caminas.")
		V:Interruptor("Abrirla sola al entrar a una ciudad", A.Ajuste("servicios", "abrirAlEntrar"),
			function(v) A.FijarAjuste("servicios", "abrirAlEntrar", v and true or false) end)
		if not enCiudad then V:Nota("No estás en esta ciudad: «Ir» te lleva desde donde estés, con la ruta de Polestar.") end
		V:Columnas({ { "Servicio", 330 }, { "Quién", 300 }, { "Distancia", 150 } })
		for _, g in ipairs(grupos) do
			local l = g.mejor
			local icono = s.CAT[g.cat] and s.CAT[g.cat].icono
			V:Fila({ icono = icono, celdas = {
				{ "|cff94c9ff" .. g.etiqueta .. "|r", g.conf == "titulo" and "por su título: puede no ser exacto" or "" },
				{ tostring(l.nombre), l.titulo or "" },
				{ enCiudad and s.TextoDistancia(l.dist) or "—" } },
				ir = function()
					-- el mismo motor que «Ir a…» (K58): la flecha, los tramos en el panel de la guía y lo que tardó de verdad
					local LLm = A.Llevame
					local ok = LLm and l.px and LLm.Llevame({ map = est.ciudad, x = l.px, y = l.py, nombre = g.etiqueta .. ": " .. tostring(l.nombre) })
					if not ok then s.IrA(l, est.ciudad, g.etiqueta) end
				end })
		end
	end,
})
