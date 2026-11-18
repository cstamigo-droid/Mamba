-- Asistente/SecLugares.lua: las secciones «Ir a…» y «Servicios» del hub.
-- Ir a…: buscas un lugar (una mazmorra o un servicio de Orgrimmar, Cima del Trueno o Entrañas), Mamba calcula la
-- ruta más corta con el planificador de Polestar (Nav.API.Estimate: piedra de hogar, vuelos aprendidos y a pie) y
-- «Llevarme» pone la flecha. Mientras calcula dice «calculando…»: nunca un número inventado.
-- Servicios: la lista de servicios de una ciudad, el más cercano primero, con su botón «Ir».
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local Hub = A.Hub
local format, floor = string.format, math.floor

local function S() return A.modulos and A.modulos.servicios end
local function E() return A.modulos and A.modulos.equipo end
local function NAPI()
	local P = _G.Polestar
	return P and P.Nav and P.Nav.API
end

local function cargado(a) return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(a) end

local function posicion()
	local m = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if not m then return nil end
	local p = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(m, "player")
	if not p then return m end
	local x, y = p:GetXY()
	return m, x, y
end

local function minutos(seg)
	if seg < 60 then return "menos de 1 min" end
	return "unos " .. floor(seg / 60 + 0.5) .. " min"
end

---------------------------------------------------------------- los destinos
-- { tipo = "mazmorra" | "servicio", nombre, sub, ir = fn, uiMap, x, y (0-1) }
local function destinos(s, e)
	local out = {}
	if e then
		for _, m in ipairs(e.MAZMORRAS or {}) do
			out[#out + 1] = { tipo = "mazmorra", clave = "m:" .. m.clave, nombre = m.nombre, sub = format("Mazmorra · %s · niveles %d a %d", tostring(m.donde), m.min, m.max),
				ir = function() return e.FlechaA(m, true) end, m = m }
		end
	end
	if s and s.datos then
		for um, c in pairs(s.datos.ciudades or {}) do
			local ciudad = (C_Map and C_Map.GetMapInfo and (C_Map.GetMapInfo(um) or {}).name) or c.nombre
			for _, g in ipairs(s.Grupos(um, nil) or {}) do
				local l = g.mejor
				out[#out + 1] = { tipo = "servicio", clave = "s:" .. um .. ":" .. g.etiqueta, nombre = g.etiqueta, sub = "Servicio · " .. tostring(ciudad),
					grupo = g, uiMap = um, x = l.px and l.px / 100, y = l.py and l.py / 100,
					ir = function() s.IrA(l, um, g.etiqueta); return true end }
			end
		end
	end
	return out
end

local ICONO = { mazmorra = "Interface\\Minimap\\Dungeon", servicio = "Interface\\Minimap\\Tracking\\None" }
local COL = { mazmorra = "|cffa385ff", servicio = "|cff94c9ff" }

-- tiempo estimado por destino (Polestar lo calcula por partes; se vuelve a preguntar mientras diga "busy")
local estim, reintento = {}, false
local function estimar(d)
	if not (d.uiMap and d.x) then return nil, "sin" end
	local api = NAPI()
	if not (api and api.Estimate) then return nil, "sin" end
	local k = d.clave
	if estim[k] and (estim[k].seg or estim[k].no) and GetTime() - estim[k].t < 30 then return estim[k].seg, estim[k].no end
	local m, x, y = posicion()
	if not (m and x) then return nil, "sin" end
	local ok, seg, why = pcall(api.Estimate, m, x, y, d.uiMap, d.x, d.y)
	if ok and seg then estim[k] = { seg = seg, t = GetTime() } return seg end
	if ok and why ~= "busy" then estim[k] = { no = why or "sin", t = GetTime() } return nil, "sin" end
	if not reintento then
		reintento = true
		C_Timer.After(0.6, function() reintento = false; Hub.Redibujar() end)
	end
	return nil, "calculando"
end

local function normal(t)
	local s = S()
	if s and s.Normal then return s.Normal(t) end
	return tostring(t or ""):lower()
end

---------------------------------------------------------------- «Ir a…»
local function sugeridos(lista)
	local out, quiero = {}, {}
	local rec = A.MazmorraRecomendada and A.MazmorraRecomendada()
	if rec then quiero["m:" .. rec.clave] = 1 end
	local _, clase = UnitClass and UnitClass("player")
	local s = S()
	local etClase = s and s.Etiqueta("clase", clase)
	local m = posicion()
	for _, d in ipairs(lista) do
		local en = d.uiMap == m
		if quiero[d.clave] then out[#out + 1] = d end
		if d.tipo == "servicio" and (en or not m) and (d.nombre == etClase or d.grupo.cat == "subasta" or d.grupo.cat == "vuelo" or d.grupo.cat == "buzon") then out[#out + 1] = d end
	end
	return out
end

local recientes = {}
local function llevar(est, d)
	local ok, motivo = d.ir()
	est.aviso = ok and "La flecha te guía. Síguela." or (motivo == "combate" and "Estás en combate: sal de combate y vuelve a apretar «Llevarme»." or "No conozco la entrada de este lugar: búscalo en el mapa del mundo.")
	for i = #recientes, 1, -1 do if recientes[i].clave == d.clave then table.remove(recientes, i) end end
	table.insert(recientes, 1, d)
	while #recientes > 8 do table.remove(recientes) end
end

Hub.Seccion({
	clave = "MambaIrA", nombre = "Ir a…", icono = "icon-goto", orden = 120, addon = "Asistente_Servicios",
	pestanas = { { key = "buscar", label = "Buscar" }, { key = "recientes", label = "Recientes" } },
	titulo = function() return "Ir a…", "Elige un lugar: Mamba traza la ruta más corta y pone la flecha" end,
	buscar = { "Escribe una mazmorra o un servicio", "Buscar un lugar", "Buscar" },
	nav = function(est)
		return { { key = "todo", label = "Todo" }, { key = "mazmorra", label = "Mazmorras" }, { key = "servicio", label = "Servicios" } }, est.filtro or "todo"
	end,
	dibujar = function(est, V)
		if not cargado("Asistente_Equipo") and A.Cargar then A.Cargar("Asistente_Equipo", function() Hub.Redibujar() end) end
		local lista = destinos(S(), E())
		local q = normal(est.busqueda or "")
		local vis = {}
		if est.pestana == "recientes" then
			vis = recientes
		elseif q ~= "" then
			for _, d in ipairs(lista) do
				local base = normal(d.nombre .. " " .. d.sub .. " " .. (d.grupo and d.grupo.nombres or ""))
				local todo = true
				for w in q:gmatch("%S+") do if not base:find(w, 1, true) then todo = false end end
				if todo then vis[#vis + 1] = d end
			end
		else
			vis = sugeridos(lista)
		end
		if est.filtro and est.filtro ~= "todo" then
			local f = {}
			for _, d in ipairs(vis) do if d.tipo == est.filtro then f[#f + 1] = d end end
			vis = f
		end
		-- la ruta del elegido, arriba
		local sel
		for _, d in ipairs(vis) do if d.clave == est.sel then sel = d end end
		sel = sel or vis[1]
		if sel then
			local seg, no = estimar(sel)
			local txt
			if seg then txt = "Ruta más corta: " .. minutos(seg) .. ", con tu piedra de hogar, tus vuelos aprendidos y el camino a pie."
			elseif no == "calculando" then txt = "calculando… Mamba busca la ruta más corta con tu piedra de hogar, tus vuelos aprendidos y el camino a pie."
			else txt = sel.tipo == "mazmorra" and "La flecha te lleva hasta la entrada desde donde estés." or "La flecha te lleva desde donde estés." end
			if est.aviso then txt = txt .. "\n|cfffabf4d" .. est.aviso .. "|r"; est.aviso = nil end
			V:Panel({ titulo = "Ruta a " .. COL[sel.tipo] .. sel.nombre .. "|r", texto = txt, boton = { "Llevarme", function() llevar(est, sel) end } })
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
			V:Fila({ icono = ICONO[d.tipo], celdas = { { COL[d.tipo] .. d.nombre .. "|r" .. (d.clave == (sel and sel.clave) and "  |cff9ba2b9‹ elegido|r" or ""), d.sub } },
				clic = function() est.sel = d.clave end })
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
		local x, y = s.PosicionJugador and s.PosicionJugador()
		local enCiudad = posicion() == est.ciudad
		local _, clase = UnitClass and UnitClass("player")
		local grupos = s.Grupos(est.ciudad, clase, enCiudad and x or nil, enCiudad and y or nil) or {}
		if est.busqueda and est.busqueda ~= "" then grupos = s.Buscar(grupos, est.busqueda) end
		if #grupos == 0 then V:Vacio("Sin resultados", "No encontré «" .. tostring(est.busqueda or "") .. "». Prueba con menos palabras.") return end
		if not enCiudad then V:Nota("No estás en esta ciudad: «Ir» te lleva desde donde estés, con la ruta de Polestar.") end
		V:Columnas({ { "Servicio", 330 }, { "Quién", 300 }, { "Distancia", 150 } })
		for _, g in ipairs(grupos) do
			local l = g.mejor
			local icono = s.CAT[g.cat] and s.CAT[g.cat].icono
			V:Fila({ icono = icono, celdas = {
				{ "|cff94c9ff" .. g.etiqueta .. "|r", g.conf == "titulo" and "por su título: puede no ser exacto" or "" },
				{ tostring(l.nombre), l.titulo or "" },
				{ enCiudad and s.TextoDistancia(l.dist) or "—" } },
				ir = function() s.IrA(l, est.ciudad, g.etiqueta) end })
		end
	end,
})
