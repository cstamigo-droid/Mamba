-- Mamba_Panel/Pestanas.lua: abrir una guía en una PESTAÑA NUEVA del panel de la guía (K57), sin tocar la de leveo.
-- Usa las pestañas que Polestar ya trae (Engine.OpenTab: hasta 6, cada una con su ×). Los parches P10 y P11
-- (PARCHES.md) dejan fija la pestaña de leveo y hacen que el selector de guías abra cocina, una mazmorra, etc., en
-- una pestaña nueva en vez de reemplazarla.
-- Tres clases de guía:
--   "prof"  -> la guía 1-300 de Polestar de esa profesión (forever/professions/…);
--   "item"  -> la guía de Polestar para conseguir un objeto (Lookup "item": vendedor, receta, quién lo suelta);
--   "pasos" -> una guía de Mamba con los pasos de la recomendación (ir al lugar y hacerlo), planificador "mamba".
-- Para los otros módulos: MambaAPI.AbrirGuia(id), MambaAPI.AbrirProfesion(nombre), MambaAPI.AbrirObjeto(itemID).
-- Licencia: GPL-3.0-only.
local _, N = ...
local format = string.format

local function PS() local p = _G.Polestar; return type(p) == "table" and p or nil end

local function avisar(texto)
	-- nada por el chat: el aviso va en el cuadro de error del juego (arriba, se va solo)
	if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(texto, 1, 0.82, 0.2) end
end

-- La guía `id` (registrada) en una pestaña nueva, activa; si ya está abierta, la elige. -> índice | nil
function N.AbrirGuia(id)
	local P = PS()
	local E = P and P.Engine
	if not (E and E.OpenTab and id) then return nil end
	local ok, idx = pcall(E.OpenTab, id, true)
	if not ok then N.Falla("OpenTab " .. tostring(id), idx); return nil end
	if not idx then
		local G = P.Guides
		if G and G.Get and not G.Get(id) then avisar("Esa guía no está instalada.")
		else avisar("Ya tienes 6 pestañas: cierra una con su × para abrir otra.") end
		return nil
	end
	if P.Set then pcall(P.Set, "ui.shown", true) end
	return idx
end

function N.AbrirProfesion(nombre)
	local id = N.GUIA_PROFESION[nombre or ""]
	if not id then return nil end
	return N.AbrirGuia(id)
end

-- Una guía armada por un planificador de Polestar (Lookup), registrada y abierta en una pestaña nueva.
local function abrirArmada(tipo, id)
	local P = PS()
	local Lk = P and P.Lookup
	if not (Lk and Lk.BuildGuide and P.RegisterGuide) then return nil end
	local ok, guia, por = pcall(Lk.BuildGuide, tipo, id)
	if not ok then N.Falla("BuildGuide " .. tipo, guia); return nil end
	if not guia then return nil, por end
	local okR, bien, porR = pcall(P.RegisterGuide, guia)
	if not (okR and bien) then return nil, okR and porR or bien end
	return N.AbrirGuia(guia.id)
end

function N.AbrirObjeto(itemID)
	local idx, por = abrirArmada("item", itemID)
	if not idx and por then avisar("Polestar no sabe todavía de dónde sale ese objeto.") end
	return idx
end

---------------------------------------------------------------- las guías de Mamba (planificador "mamba")
-- Una recomendación con lugar: un paso "ve allá" con su cómo. Polestar pone la flecha y marca el paso hecho al
-- llegar; el cómo queda en la nota del paso.
N.recetas = {}

local function pasosDe(l)
	if not (l and l.lugar and l.lugar.mapa and l.lugar.x and l.lugar.y) then return nil end
	local goals = { { t = "goto", map = l.lugar.mapa, x = l.lugar.x, y = l.lugar.y, text = l.lugar.zona or l.titulo } }
	if l.como and l.como ~= "" then goals[#goals + 1] = { t = "note", text = l.como } end
	return { { title = l.titulo, goals = goals } }
end

local function planificar(id)
	local l = N.recetas[id] or (MambaPanelPJ and MambaPanelPJ.recetas and MambaPanelPJ.recetas[id])
	local pasos = pasosDe(l)
	if not pasos then return nil, "sin pasos" end
	return { title = "Mamba: " .. (l.titulo or "tu plan"), category = "Mamba", steps = pasos }
end

local registrado = false
local function registrar()
	if registrado then return true end
	local P = PS()
	local Lk = P and P.Lookup
	if not (Lk and Lk.RegisterPlanner) then return false end
	local ok = pcall(Lk.RegisterPlanner, "mamba", planificar)
	registrado = ok
	return ok
end
N.RegistrarPlanificador = registrar

-- La recomendación `l` como guía de Mamba en una pestaña nueva.
function N.AbrirPasos(l)
	if not registrar() then return nil end
	-- la clave de la línea, solo letras y números (el id de Polestar es lookup/mamba/<id>)
	local id = (l.clave or "x"):gsub("[^%w]", "")
	N.recetas[id] = l
	-- se guarda lo justo para rearmarla después de un /reload (Polestar reabre las pestañas guardadas)
	local pj = N.PJ()
	pj.recetas = pj.recetas or {}
	pj.recetas[id] = { titulo = l.titulo, como = l.como, lugar = l.lugar and { mapa = l.lugar.mapa, x = l.lugar.x, y = l.lugar.y, zona = l.lugar.zona } }
	-- el camino de Polestar (Lookup.Guide: arma, registra y abre; si ya está abierta la rehace en su pestaña)
	local P = PS()
	local Lk = P and P.Lookup
	if Lk and Lk.Guide then
		local ok, gid = pcall(Lk.Guide, "mamba", id)
		if ok and gid then
			if P.Set then pcall(P.Set, "ui.shown", true) end
			local tabs, activa = P.Engine.GetTabs()
			return activa
		end
	end
	-- sin el Codex cargado, Lookup.Guide no abre: lo mismo a mano
	return abrirArmada("mamba", id)
end

-- La guía que corresponde a una línea (K57/K61 "Abrir guía").
function N.AbrirGuiaDe(l)
	local g = l and l.guia
	if not g then return nil end
	if g.tipo == "prof" then return N.AbrirGuia(g.id) end
	if g.tipo == "item" then return N.AbrirObjeto(g.id) end
	if g.tipo == "pasos" then return N.AbrirPasos(l) end
	return nil
end

-- "Llévame" (K61): la flecha de Polestar al lugar. -> true | false
function N.Llevame(l)
	local lg = l and l.lugar
	-- sin coordenadas, por nombre: "subasta", "reparar", una mazmorra (Asistente/Llevame.lua resuelve el más cercano)
	if not lg and l and l.destino then
		local A = _G.MambaAPI
		if A and A.Llevame then
			local ok, hecho = pcall(A.Llevame, l.destino)
			return ok and hecho and true or false
		end
		return false
	end
	-- K58: el motor de «Ir a…» (Asistente/Llevame.lua) pone la flecha y SIGUE el viaje tramo por tramo
	local API = _G.MambaAPI
	if lg and API and API.Llevame then
		local ok, hecho = pcall(API.Llevame, { map = lg.mapa, x = lg.x, y = lg.y, nombre = l.titulo })
		if ok and hecho then return true end
	end
	local P = PS()
	local api = P and P.Nav and P.Nav.API
	if not (lg and api and api.Navigate) then return false end
	local ok, hecho = pcall(api.Navigate, "Mamba", lg.mapa, lg.x / 100, lg.y / 100, l.titulo or "Mamba")
	return ok and hecho or false
end

function N.PuedeLlevar()
	local A = _G.MambaAPI
	return A and A.Llevame and true or false
end

---------------------------------------------------------------- MambaAPI
local API = _G.MambaAPI or {}
_G.MambaAPI = API
API.AbrirGuia = function(id) return N.AbrirGuia(id) end
API.AbrirProfesion = function(nombre) return N.AbrirProfesion(nombre) end
API.AbrirObjeto = function(itemID) return N.AbrirObjeto(itemID) end
API.LineasDelPanel = function() return N.Lineas() end
