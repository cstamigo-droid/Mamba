-- Mamba_Panel/Calabozos.lua: Calabozos con TODAS las mazmorras de Forever y un buscador que encuentra por cualquier
-- palabra, sin importar tildes ni mayúsculas (K122). Cristian: "busco Ciudad Anegada, ese calabozo, y no sale nada".
--   * El Codex de Polestar (Polestar_Codex/Dungeons1.lua) trae 30 instancias y no las propias de Forever. Mamba
--     registra las que faltan (Datos_Calabozos.lua, de las tablas del cliente) con la MISMA puerta que usa el Codex,
--     Polestar.Dungeons.Register("dungeon"), justo después de él y solo las que él no trae (ni por clave ni por
--     mapa): si una versión nueva de Polestar las suma, manda la de Polestar. Sin tocar archivos de Polestar.
--   * Cada una con su nombre esMX, niveles, zona y entrada: el botón de la página («Llévame a la entrada» de
--     Polestar, Dungeons.GuideTo) pone la flecha. Sin datos de misiones, jefes o entrada: "datos en camino".
--   * El buscador de Calabozos (parche P17 en UI/Dungeons.lua) llama a Polestar.UI.MambaCalce; /polestar dungeons
--     <nombre> (Dungeons.Find) también pliega tildes.
-- Licencia: GPL-3.0-only.
local _, N = ...

local type, pairs, ipairs, pcall, tostring = type, pairs, ipairs, pcall, tostring

---------------------------------------------------------------- texto
-- Igual que Asistente/Llevame.lua (LL.Normal): primero las tildes y después solo A-Z, porque string.lower con un
-- locale Latin-1 rompe los bytes de UTF-8. Además saca apóstrofos y guiones ("Krol'dok" = "kroldok").
local TILDES = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n",
	["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u", ["Ü"] = "u", ["Ñ"] = "n", ["’"] = "" }
function N.Pliega(t)
	t = tostring(t or "")
	for con, sin_ in pairs(TILDES) do t = t:gsub(con, sin_) end
	t = t:gsub("[A-Z]", string.lower):gsub("'", ""):gsub("[%-:%(%),%.]", " "):gsub("%s+", " ")
	return (t:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function raiz(w)
	if #w > 5 and w:sub(-2) == "es" then return w:sub(1, -3) end
	if #w > 4 and w:sub(-1) == "s" then return w:sub(1, -2) end
	return w
end

local VACIAS = { de = true, del = true, la = true, el = true, los = true, las = true, a = true, al = true, y = true, the = true, of = true }

-- ¿El texto t (ya plegado) calza con q? Cada palabra útil de q tiene que estar en t (o su raíz, sin plural).
-- Sin palabras útiles ("la"), q entera. q vacía: sí.
function N.CalzaTexto(t, q)
	q = N.Pliega(q)
	if q == "" then return true end
	local util = 0
	for w in q:gmatch("%S+") do
		if not VACIAS[w] then
			util = util + 1
			if not (t:find(w, 1, true) or t:find(raiz(w), 1, true)) then return false end
		end
	end
	if util == 0 then return t:find(q, 1, true) ~= nil end
	return true
end

---------------------------------------------------------------- las que faltan
local EXTRA = {} -- clave -> fila de N.CALABOZOS registrada por Mamba
local INGLES = {} -- clave -> nombre en inglés (el del Codex o el del cliente)
local cubiertas = { clave = {}, mapa = {} } -- lo que ya trae el Codex

for _, d in ipairs(N.CALABOZOS or {}) do INGLES[d.key] = d.en end

local function resumen(d)
	return { name = d.name, map = d.map, kind = d.kind, forever = true, minLevel = d.minLevel, maxLevel = d.maxLevel,
		floor = d.floor, players = d.players, playersMax = d.playersMax, zone = d.zone, zoneName = d.zoneName,
		entrance = d.entrance and { map = d.entrance.map, x = d.entrance.x, y = d.entrance.y } or nil,
		quests = { A = 0, H = 0 }, bosses = 0 }
end

-- Las del Codex sin zona (Ciudad de Dalaran): la que dicen las tablas del cliente, si el Codex no trae otra.
local HUECO = {}
for _, h in ipairs(N.CALABOZOS_HUECOS or {}) do HUECO[h.key] = h end
local function completar(k, s)
	local h = HUECO[k]
	if not h then return end
	if s.zone == nil and s.zoneName == nil and h.zone then s.zone, s.zoneName = h.zone, h.zoneName end
	if s.entrance == nil and h.entrance then s.entrance = { map = h.entrance.map, x = h.entrance.x, y = h.entrance.y } end
end

local registrando = false
local function registrarFaltantes(D, registro)
	local nuevas = {}
	for _, d in ipairs(N.CALABOZOS or {}) do
		if not (cubiertas.clave[d.key] or cubiertas.mapa[d.map]) then
			nuevas[d.key] = resumen(d)
			EXTRA[d.key] = d
		else
			EXTRA[d.key] = nil
		end
	end
	if next(nuevas) then
		registrando = true
		pcall(registro, "dungeon", nuevas, nil)
		registrando = false
	end
end

-- Envuelve Dungeons.Register: cada vez que el Codex registra mazmorras, se anotan las suyas y después se suman las
-- de Forever que siguen faltando. -> true si quedó puesto.
function N.EngancharCalabozos()
	local P = _G.Polestar
	local D = type(P) == "table" and P.Dungeons
	if not (type(D) == "table" and type(D.Register) == "function") or D.MambaK122 then return D and D.MambaK122 or false end
	local original = D.Register
	D.Register = function(group, a, b, ...)
		if group == "dungeon" and not registrando and type(a) == "table" then
			for k, s in pairs(a) do
				if type(s) == "table" then
					cubiertas.clave[k] = true
					if s.map then cubiertas.mapa[s.map] = true end
					if type(s.name) == "string" and not EXTRA[k] then INGLES[k] = s.name end
					completar(k, s)
				end
			end
		end
		local r = original(group, a, b, ...)
		if group == "dungeon" and not registrando then registrarFaltantes(D, original) end
		return r
	end
	D.MambaK122 = true
	-- El Codex ya estaba cargado (otro addon lo pidió antes): lo que trae se mira por mapa.
	if D.Meta and D.Meta() and D.ForMap then
		for _, d in ipairs(N.CALABOZOS or {}) do
			local ok, k = pcall(D.ForMap, d.map)
			if ok and k and not EXTRA[k] then cubiertas.mapa[d.map] = true; cubiertas.clave[k] = true end
		end
		registrarFaltantes(D, original)
	end
	-- /polestar dungeons <nombre>: si Polestar no la encuentra, sin tildes y por cualquier palabra.
	local find = D.Find
	if type(find) == "function" then
		D.Find = function(text, ...)
			local k = find(text, ...)
			if k or type(text) ~= "string" or not D.List then return k end
			for _, d in ipairs(D.List()) do
				if N.Calce(d, text) then return d.key end
			end
			return nil
		end
	end
	return true
end

---------------------------------------------------------------- lo que llama Polestar (P17)
-- ¿La mazmorra d (de Dungeons.List) calza con la búsqueda q? Por su nombre en el idioma del cliente, en inglés y su clave.
function N.Calce(d, q)
	if type(d) ~= "table" then return false end
	local key = tostring(d.key or "")
	local t = N.Pliega((d.name or "") .. " " .. (INGLES[key] or "") .. " " .. key)
	return N.CalzaTexto(t, q)
end

-- "Datos en camino" de una mazmorra que registró Mamba (que = "quests" | "bosses"); nil: la de Polestar.
-- que = "entrance": la línea de la cabecera de CUALQUIER página sin entrada conocida (Polestar solo la llama así).
function N.SinDatos(key, que)
	if que == "entrance" then
		local P = _G.Polestar
		local D = type(P) == "table" and P.Dungeons
		local g = D and D.Get and D.Get(key)
		if g and g.entrance then return nil end
		if g and (g.zone or g.zoneName) then return "Entrada: datos en camino" end
		return "Zona y entrada: datos en camino"
	end
	local d = key and EXTRA[key]
	if not d then return nil end
	local t
	if que == "bosses" then
		t = "Datos en camino: los jefes y el botín de esta mazmorra nueva de Forever todavía no están en los datos de Mamba."
	elseif (d.misiones or 0) > 0 then
		t = ("Datos en camino: se conocen %d misiones de esta mazmorra nueva de Forever, pero su detalle (quién las da, qué piden y qué dan) todavía no está en los datos de Mamba."):format(d.misiones)
	else
		t = "Datos en camino: las misiones de esta mazmorra nueva de Forever todavía no están en los datos de Mamba."
	end
	if not d.entrance then
		t = t .. " La entrada tampoco" .. (d.zoneName and (" (está en " .. d.zoneName .. ")") or "") .. ", así que no hay «Llévame» todavía."
	elseif d.entradaFuente and d.entradaFuente:find("^aprox") then
		t = t .. " La entrada es aproximada: " .. d.entradaFuente:gsub("^aprox%.:%s*", "") .. "."
	end
	return t
end

function N.EsDeMamba(key) return key ~= nil and EXTRA[key] ~= nil end

local function publicar()
	local P = _G.Polestar
	local UI = type(P) == "table" and P.UI
	if type(UI) ~= "table" then return false end
	UI.MambaCalce = N.Calce
	UI.MambaSinDatos = N.SinDatos
	return true
end

N.EngancharCalabozos()
publicar()
