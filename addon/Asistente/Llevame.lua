-- Asistente/Llevame.lua: el motor de «Llévame» (fila K58 de MAMBA_ACEPTACION, y K61: cada botón «Llévame»).
-- Cristian, 18-11: "si estoy en un continente y quiero llegar a un mercado, banco o llegar a una ciudad en
-- particular poder ponérselo a mamba y que me diga la forma más rápida de llegar".
--
-- Qué hace:
--   * Resuelve un destino escrito como lo diría Cristian: un servicio ("banco", "subasta", "posada",
--     "instructor de druida", "alquimia", "maestro de vuelo"), una ciudad o zona ("Cima del Trueno"), una
--     mazmorra ("Zahúrda"), un PNJ (por su nombre, con el Codex de Polestar) o un punto { map, x, y }.
--   * En los servicios elige el MÁS CERCANO EN TIEMPO (no en distancia): cada candidato se mide con el
--     planificador de Polestar, con la piedra de hogar, los vuelos, zepelines, barcos y portales.
--   * Da la ruta TRAMO POR TRAMO, con el tiempo de cada uno y el total, y 2-3 alternativas: la más rápida,
--     sin piedra de hogar (si la usa: así la guardas, o está en espera) y sin pagar vuelos (si vuela).
--   * Pone la flecha de Polestar y sigue el viaje: el tramo en curso, y al terminar cada tramo guarda cuánto
--     tardó de verdad para corregir las estimaciones siguientes (regla R0).
-- R0: todo tiempo sale con "≈" si es estimado; sin "≈" solo lo medido (un vuelo que este personaje ya hizo,
-- que Polestar guarda al aterrizar). Mientras Polestar calcula, dice «calculando…»: nunca un número inventado.
--
-- Usa de Polestar (todo con pcall y con respaldo):
--   Polestar.Nav.EstimateTravel(from, to, budgeted, noHearth, noFlights) -> seconds, why, legs  (PARCHES.md P8)
--   Polestar.Nav.API (Navigate, Cancel, Follow, Unfollow), Polestar.Nav.GetRoute(), Polestar.Nav.travel.SkipLeg,
--   Polestar.Nav.GetTravelData() (posadas y maestros de vuelo del mundo), Polestar.Maps.LearnedFlight,
--   Polestar.Compat (MapToWorld / WorldToMap / GetPlayerWorldPosition), Polestar.Search + Polestar.Codex (PNJ),
--   Polestar.Dungeons (la entrada de una mazmorra).
-- API pública: MambaAPI.Llevame(destino, opciones), MambaAPI.RutasA(destino), MambaAPI.RutaActual(),
-- MambaAPI.AlCambiarRuta(fn), MambaAPI.Destinos(texto) (ver Grupos.lua).
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local LL = {}
A.Llevame = LL

local format, floor, sqrt, huge = string.format, math.floor, math.sqrt, math.huge
local type, pairs, ipairs, tostring, tonumber, pcall = type, pairs, ipairs, tostring, tonumber, pcall

LL.DUENO = "Mamba"           -- dueño de la flecha en la API de Polestar
LL.CACHE = 20                -- segundos que vale una ruta calculada (desde el mismo lugar)
LL.CELDA = 40                -- yardas: moverse menos que esto no invalida la ruta guardada
LL.MAX_CANDIDATOS = 8        -- servicios medidos por búsqueda (cada uno es un plan de Polestar)
LL.MIN_MEDIDAS = 3           -- tramos medidos de un tipo antes de corregir con ellos
LL.PIEDRA = 6948

---------------------------------------------------------------- Polestar
local function P() local p = _G.Polestar return type(p) == "table" and p or nil end
local function Nav() local p = P() return p and type(p.Nav) == "table" and p.Nav or nil end
local function Compat() local p = P() return p and p.Compat or nil end
local function NAPI()
	local N = Nav()
	local api = N and N.API
	if type(api) == "table" and api.version == 1 and type(api.Navigate) == "function" then return api end
	return nil
end

-- ¿Polestar trae los tramos? (PARCHES.md P8). Sin P8 el motor da solo el total (Nav.API.Estimate).
function LL.ConTramos()
	local N = Nav()
	return N and type(N.EstimateTravel) == "function" or false
end

local function aMundo(map, x, y, f)
	local C = Compat()
	if not (C and C.MapToWorld and map and x and y) then return nil end
	local ok, c, wx, wy = pcall(C.MapToWorld, map, x, y, f)
	if ok and c then return c, wx, wy end
	return nil
end

-- Un punto del mapa de la era ("e") al marco vivo del mismo mapa (el que usa la API pública de Polestar).
local function vivo(map, x, y, f)
	if not f then return map, x, y end
	local c, wx, wy = aMundo(map, x, y, f)
	local C = Compat()
	if c and C and C.WorldToMap then
		local ok, lx, ly = pcall(C.WorldToMap, c, wx, wy, map)
		if ok and lx and ly then return map, lx, ly end
	end
	return map, x, y
end

local function jugadorMundo()
	local C = Compat()
	if not (C and C.GetPlayerWorldPosition) then return nil end
	local ok, c, wx, wy = pcall(C.GetPlayerWorldPosition)
	if ok and c then return c, wx, wy end
	return nil
end

local function enCombate() return (A.EnCombate and A.EnCombate()) or (InCombatLockdown and InCombatLockdown()) or false end
local function ahora() return GetTime and GetTime() or 0 end

---------------------------------------------------------------- texto
local TILDES = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n",
	["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u", ["Ñ"] = "n" }
function LL.Normal(t)
	-- primero las tildes y después solo A-Z: string.lower con un locale Latin-1 rompe los bytes de UTF-8
	t = tostring(t or "")
	for con, sin_ in pairs(TILDES) do t = t:gsub(con, sin_) end
	t = t:gsub("[A-Z]", string.lower)
	return (t:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- R0: "10 s", "≈ 4:18", "≈ 1 h 05 min". estimado: con "≈".
function LL.Tiempo(seg, estimado)
	if type(seg) ~= "number" then return "—" end
	seg = floor(seg + 0.5)
	local t
	if seg < 60 then t = seg .. " s"
	elseif seg < 3600 then t = format("%d:%02d", floor(seg / 60), seg % 60)
	else t = format("%d h %02d min", floor(seg / 3600), floor(seg % 3600 / 60)) end
	return (estimado and "≈ " or "") .. t
end

---------------------------------------------------------------- tramos
LL.TIPO = {
	walk = "Caminar", fly = "Vuelo", boat = "Barco", zeppelin = "Zepelín", airship = "Dirigible", tram = "Tranvía",
	portal = "Portal", hearth = "Piedra de hogar", teleport = "Hechizo", lift = "Ascensor",
}
LL.ICONO = {
	walk = "Interface\\Icons\\Ability_Tracking", fly = "Interface\\Icons\\Ability_Mount_Wyvern_01",
	boat = "Interface\\Icons\\INV_Misc_Anchor", zeppelin = "Interface\\Icons\\INV_Misc_Anchor", airship = "Interface\\Icons\\INV_Misc_Anchor",
	tram = "Interface\\Icons\\INV_Misc_Gear_01", portal = "Interface\\Icons\\Spell_Arcane_PortalOrgrimmar",
	hearth = "Interface\\Icons\\INV_Misc_Rune_01", teleport = "Interface\\Icons\\Spell_Arcane_TeleportOrgrimmar",
	lift = "Interface\\Icons\\INV_Misc_Gear_01",
}

-- Medidas propias (AsistenteDB.viajes[tipo] = { n, real, est }): cuánto tardan de verdad los tramos de ese tipo
-- comparado con lo que dijo el planificador. Corrigen las caminatas y los transportes (no la piedra: es fija).
local function medidas()
	if type(AsistenteDB) ~= "table" then return nil end
	AsistenteDB.viajes = AsistenteDB.viajes or {}
	return AsistenteDB.viajes
end

function LL.Factor(tipo)
	local m = medidas()
	local x = m and m[tipo]
	if not (x and x.n and x.n >= LL.MIN_MEDIDAS and x.est and x.est > 0) then return nil end
	local f = x.real / x.est
	if f < 0.5 then f = 0.5 elseif f > 2 then f = 2 end
	return f
end

function LL.Medir(tipo, estimado, real)
	local m = medidas()
	if not (m and tipo and tipo ~= "hearth" and type(estimado) == "number" and estimado >= 5 and type(real) == "number") then return false end
	if real < estimado * 0.25 or real > estimado * 4 then return false end -- se paró, murió o tomó otro camino
	local x = m[tipo] or { n = 0, real = 0, est = 0 }
	x.n, x.real, x.est = x.n + 1, x.real + real, x.est + estimado
	if x.n > 50 then x.real, x.est, x.n = x.real * 50 / x.n, x.est * 50 / x.n, 50 end -- pesan más las recientes
	m[tipo] = x
	return true
end

local function nombreTaxi(nodo)
	local p = P()
	local T = p and p.Nav and p.Nav.travel
	if T and T.TaxiName then
		local ok, n = pcall(T.TaxiName, nodo, true)
		if ok and n then return n end
	end
	return nodo and (nodo.short or nodo.name) or nil
end

-- Un tramo de Polestar -> { tipo, texto, seg, estimado, yardas, medido, hasta = { map, x, y } }
local function tramo(leg)
	local t = { tipo = leg.kind, texto = leg.label or LL.TIPO[leg.kind] or tostring(leg.kind), seg = leg.seconds or 0, estimado = true,
		yardas = leg.yards, via = leg.via }
	if leg.kind == "hearth" then
		t.estimado = false -- 10 s de lanzamiento + la pantalla de carga: lo da el juego, no es una ruta
		t.espera = (leg.seconds or 0) > 20 and (leg.seconds - 15) or nil
		if t.espera then t.estimado = true end
	elseif leg.kind == "fly" and type(leg.stops) == "table" and #leg.stops >= 2 then
		local a, b = leg.stops[1], leg.stops[#leg.stops]
		local M = P() and P().Maps
		if M and M.LearnedFlight and a and b then
			local ok, s = pcall(M.LearnedFlight, a.id, b.id, a.name, b.name)
			if ok and type(s) == "number" then t.seg, t.estimado, t.medido = s, false, true end
		end
		t.hasta = b
	end
	if t.estimado and not t.medido then
		local f = LL.Factor(leg.kind)
		if f and leg.kind ~= "hearth" then t.seg, t.ajustado = t.seg * f, true end
	end
	return t
end

-- Une caminatas seguidas (los puntos de paso de Polestar) en un solo tramo "Caminar N yd".
function LL.Tramos(legs)
	local out = {}
	for _, leg in ipairs(legs or {}) do
		local t = tramo(leg)
		local u = out[#out]
		if u and u.tipo == "walk" and t.tipo == "walk" and (u.via or t.via) then
			u.seg = u.seg + t.seg
			u.yardas = (u.yardas or 0) + (t.yardas or 0)
			if not t.via then u.texto, u.via = t.texto, nil end
			u.ajustado = u.ajustado or t.ajustado
		else
			out[#out + 1] = t
		end
	end
	for _, t in ipairs(out) do
		local camina = (P() and P().L and P().L["Walk"]) or "Walk"
		if t.tipo == "walk" and t.yardas and (t.via or t.texto == camina or t.texto == "Walk" or t.texto == LL.TIPO.walk) then
			t.texto = format("Caminar %d yd", floor(t.yardas + 0.5))
		elseif t.tipo == "walk" and t.yardas and t.yardas > 0 then
			t.texto = format("%s (%d yd)", t.texto, floor(t.yardas + 0.5))
		end
	end
	return out
end

-- Una ruta: { clave, nombre, tramos, total, estimado, usa = { hearth = true, fly = true, ... }, nota }
local function ruta(legs, clave, nombre)
	local tr = LL.Tramos(legs)
	local total, est, usa = 0, false, {}
	for _, t in ipairs(tr) do
		total = total + (t.seg or 0)
		est = est or t.estimado
		usa[t.tipo] = true
	end
	return { clave = clave, nombre = nombre, tramos = tr, total = total, estimado = est, usa = usa }
end

-- "Piedra de hogar a Cima del Trueno 15 s → Vuelo a Orgrimmar ≈ 4:18 → Caminar 382 yd ≈ 45 s"
function LL.Resumen(r)
	local t = {}
	for _, x in ipairs(r and r.tramos or {}) do t[#t + 1] = x.texto .. " " .. LL.Tiempo(x.seg, x.estimado) end
	return table.concat(t, " → ")
end

---------------------------------------------------------------- planificar
-- Un plan de Polestar desde el jugador a { map, x, y, f } (x, y en %). -> seconds, legs | nil, "calculando" | nil, "sin"
local function planear(dest, sinPiedra, sinVuelos, presupuesto)
	local N = Nav()
	if not (N and N.EstimateTravel) then return nil, "sin" end
	local ok, s, why, legs = pcall(N.EstimateTravel, nil, { map = dest.map, x = dest.x, y = dest.y, f = dest.f }, presupuesto, sinPiedra or nil, sinVuelos or nil)
	if not ok then return nil, "sin" end
	if s then return s, legs end
	if why == "busy" then return nil, "calculando" end
	return nil, "sin"
end

-- Respaldo sin el parche P8: solo el total, con la API pública (sin tramos).
local function soloTotal(dest)
	local api = NAPI()
	if not (api and api.Estimate) then return nil, "sin" end
	local m, x, y = vivo(dest.map, dest.x, dest.y, dest.f)
	local ok, s, why = pcall(api.Estimate, nil, nil, nil, m, x / 100, y / 100)
	if ok and s then return s end
	return nil, (ok and why == "busy") and "calculando" or "sin"
end

local cache = {}
local function claveCache(dest)
	local c, wx, wy = jugadorMundo()
	return format("%s:%.1f:%.1f:%s|%s:%d:%d", tostring(dest.map), dest.x or 0, dest.y or 0, tostring(dest.f),
		tostring(c), floor((wx or 0) / LL.CELDA), floor((wy or 0) / LL.CELDA))
end

-- Las rutas a un punto: 1 a 3, la más rápida primero. -> { estado = "ok" | "calculando" | "sin", rutas = {...} }
-- presupuesto = true: respeta el tope por cuadro de Polestar (lo que redibuja la ventana); false: un clic.
-- soloRapida = true: solo la más rápida (para comparar candidatos sin gastar 3 planes en cada uno).
function LL.Rutas(dest, presupuesto, soloRapida)
	if not (dest and dest.map and dest.x and dest.y) then return { estado = "sin", rutas = {} } end
	local k = claveCache(dest) .. (soloRapida and ":1" or "")
	local c = cache[k]
	if c and ahora() - c.t < LL.CACHE then return c.r end
	local res = { estado = "ok", rutas = {} }
	if not LL.ConTramos() then
		local s, no = soloTotal(dest)
		if s then
			res.rutas[1] = { clave = "rapida", nombre = "La más rápida", tramos = {}, total = s, estimado = true, usa = {}, sinTramos = true }
		else
			res.estado = no
		end
		if res.estado ~= "calculando" then cache[k] = { t = ahora(), r = res } end
		return res
	end
	local s1, l1 = planear(dest, false, false, presupuesto)
	if not s1 then res.estado = l1 return res end
	local r1 = ruta(l1, "rapida", "La más rápida")
	res.rutas[1] = r1
	if soloRapida then cache[k] = { t = ahora(), r = res } return res end
	local function otra(sinPiedra, sinVuelos, clave, nombre)
		local s, l = planear(dest, sinPiedra, sinVuelos, presupuesto)
		if not s then return l end
		local r = ruta(l, clave, nombre)
		for _, x in ipairs(res.rutas) do
			if LL.Resumen(x) == LL.Resumen(r) then return "igual" end
		end
		res.rutas[#res.rutas + 1] = r
		return "ok"
	end
	local pend = false
	if r1.usa.hearth or r1.usa.teleport then
		if otra(true, false, "sinPiedra", "Sin piedra de hogar") == "calculando" then pend = true end
	end
	local alguna = false
	for _, x in ipairs(res.rutas) do alguna = alguna or x.usa.fly end
	if alguna then
		if otra(true, true, "sinVuelos", "Sin pagar vuelos") == "calculando" then pend = true end
	end
	if pend then res.incompleto = true else cache[k] = { t = ahora(), r = res } end
	-- notas que explican la alternativa (R0: con su número)
	for _, x in ipairs(res.rutas) do
		if x.clave == "sinPiedra" and r1.tramos[1] and r1.tramos[1].espera then
			x.nota = "tu piedra de hogar está en espera " .. LL.Tiempo(r1.tramos[1].espera, false)
		elseif x.clave == "sinPiedra" then
			x.nota = "guardas la piedra para después · " .. LL.Tiempo(x.total - r1.total, x.estimado) .. " más"
		elseif x.clave == "sinVuelos" then
			x.nota = "sin gastar oro en vuelos · " .. LL.Tiempo(x.total - r1.total, x.estimado) .. " más"
		end
	end
	return res
end

function LL.OlvidarCache() cache = {} end

---------------------------------------------------------------- destinos
-- destino = { tipo = "servicio"|"ciudad"|"zona"|"mazmorra"|"pnj"|"punto", nombre, sub, clave,
--             map, x, y, f (el punto; nil en los que se resuelven al elegir), cat/det (servicio), mazmorra }

local function S()
	local s = A.modulos and A.modulos.servicios
	if s then return s end
	return _G.Asistente_Servicios
end

local function cargar(addon)
	local C = C_AddOns
	if C and C.IsAddOnLoaded and C.IsAddOnLoaded(addon) then return true end
	if enCombate() then return false end
	if C and C.LoadAddOn then pcall(C.LoadAddOn, addon) end
	return C and C.IsAddOnLoaded and C.IsAddOnLoaded(addon) or false
end

local function bando()
	local f = UnitFactionGroup and UnitFactionGroup("player")
	return f == "Alliance" and 1 or f == "Horde" and 2 or 0
end

-- Los servicios que se buscan "el más cercano": categoría -> cómo juntar candidatos.
LL.SERVICIOS = {
	{ cat = "banco", nombre = "Banco", buscar = "banco banquero guardar" },
	{ cat = "subasta", nombre = "Casa de subastas", buscar = "subasta subastas subastador mercado casa" },
	{ cat = "buzon", nombre = "Buzón", buscar = "buzon correo carta" },
	{ cat = "posada", nombre = "Posada", buscar = "posada posadero piedra hogar descansar taberna" },
	{ cat = "vuelo", nombre = "Maestro de vuelo", buscar = "vuelo volar maestro jinete viento grifo" },
	{ cat = "reparar", nombre = "Reparar", buscar = "reparar reparacion arreglar" },
	{ cat = "establo", nombre = "Maestro de establos", buscar = "establo establos mascota" },
	{ cat = "clase", nombre = "Instructor de tu clase", buscar = "instructor clase entrenador hechizos entrenar" },
}

-- Candidatos de un servicio en todo el mundo: { nombre, sub, map, x, y, f, c, wx, wy } (guardados: no se mueven)
local candCache = {}
function LL.Candidatos(cat, det)
	local ck = tostring(cat) .. ":" .. tostring(det)
	if candCache[ck] and #candCache[ck] > 0 then return candCache[ck] end
	local out = {}
	local s = S()
	if s and s.datos and s.Grupos then
		local clase = UnitClass and select(2, UnitClass("player")) or nil
		if cat == "clase" and not det then det = clase end
		for um, c in pairs(s.datos.ciudades or {}) do
			local ciudad = (C_Map and C_Map.GetMapInfo and (C_Map.GetMapInfo(um) or {}).name) or c.nombre or tostring(um)
			for _, l in ipairs(c.lugares or {}) do
				if l.cat == cat and (det == nil or l.det == det) and l.px and l.py then
					out[#out + 1] = { nombre = l.nombre, sub = ciudad, map = um, x = l.px, y = l.py, ciudad = ciudad,
						etiqueta = s.Etiqueta and s.Etiqueta(l.cat, l.det) or cat }
				end
			end
		end
	end
	-- Fuera de las capitales: las posadas y los maestros de vuelo de Polestar (todo el mundo, de tu bando)
	local N = Nav()
	if N and N.GetTravelData and (cat == "posada" or cat == "vuelo") then
		local ok, d = pcall(N.GetTravelData)
		local mio = bando()
		if ok and d then
			if cat == "posada" then
				for _, inn in ipairs(d.inns or {}) do
					local nom = inn.names and inn.names[1] or inn.name
					if inn.map and inn.x then
						out[#out + 1] = { nombre = "Posada", sub = (N.travel and N.travel.PlaceName and N.travel.PlaceName(inn)) or nom, map = inn.map, x = inn.x, y = inn.y, f = inn.f, etiqueta = "Posada" }
					end
				end
			else
				local conocidos = N.GetKnownTaxiNodes and select(2, pcall(N.GetKnownTaxiNodes)) or nil
				for _, n in ipairs(d.taxi or {}) do
					if n.map and n.x and (n.faction == 3 or n.faction == mio) and not n.class then
						local sabido = type(conocidos) == "table" and conocidos[n.id]
						out[#out + 1] = { nombre = nombreTaxi(n) or "Maestro de vuelo", sub = sabido and "ruta aprendida" or "ruta sin aprender", map = n.map, x = n.x, y = n.y, f = n.f, etiqueta = "Maestro de vuelo" }
					end
				end
			end
		end
	end
	-- las posadas de las capitales vienen dos veces (Servicios y Polestar): queda la primera
	local vistos, unicos = {}, {}
	for _, c in ipairs(out) do
		local w, wx, wy = aMundo(c.map, c.x, c.y, c.f)
		local k = w and format("%d:%d:%d", w, floor(wx / 30), floor(wy / 30)) or (c.map .. ":" .. c.x)
		if not vistos[k] then vistos[k] = true; c.c, c.wx, c.wy = w, wx, wy; unicos[#unicos + 1] = c end
	end
	candCache[ck] = unicos
	return unicos
end

-- Los candidatos que vale la pena medir: los más cercanos en línea recta de tu continente, el mejor de cada
-- ciudad de otro continente y el que está junto a tu piedra de hogar. Máximo LL.MAX_CANDIDATOS.
function LL.Preseleccion(cands)
	local pc, px, py = jugadorMundo()
	local mismo, otros, porCiudad = {}, {}, {}
	for _, c in ipairs(cands) do
		if pc and c.c == pc then
			c.recta = sqrt((c.wx - px) ^ 2 + (c.wy - py) ^ 2)
			mismo[#mismo + 1] = c
		else
			local k = c.ciudad or (c.map .. "")
			if not porCiudad[k] then porCiudad[k] = true; otros[#otros + 1] = c end
		end
	end
	table.sort(mismo, function(a, b) return a.recta < b.recta end)
	local out = {}
	for i = 1, math.min(#mismo, LL.MAX_CANDIDATOS - math.min(#otros, 3)) do out[#out + 1] = mismo[i] end
	for _, c in ipairs(otros) do
		if #out >= LL.MAX_CANDIDATOS then break end
		out[#out + 1] = c
	end
	return out
end

-- El servicio más cercano EN TIEMPO. -> candidato (con .rutas) | nil, "calculando" | "sin"
function LL.MasCercano(cat, det, presupuesto)
	if not LL.ConTramos() and not NAPI() then return nil, "sin" end
	local cands = LL.Preseleccion(LL.Candidatos(cat, det))
	if #cands == 0 then return nil, "sin" end
	local mejor, falta = nil, false
	for _, c in ipairs(cands) do
		c.rutas = nil
		local r = LL.Rutas(c, presupuesto, true)
		if r.estado == "calculando" then falta = true
		elseif r.rutas[1] and (not mejor or r.rutas[1].total < mejor.rutas.rutas[1].total) then
			mejor = c; c.rutas = r
		end
	end
	if falta and presupuesto then return mejor, "calculando" end
	if not mejor then return nil, falta and "calculando" or "sin" end
	-- las alternativas, solo para el ganador
	local full = LL.Rutas(mejor, presupuesto)
	if full.rutas[1] then mejor.rutas = full end
	return mejor
end

-- Las ciudades y zonas del juego (C_Map), con el punto de llegada: su maestro de vuelo de tu bando si lo hay,
-- si no el centro de la zona.
local zonas
local CONTINENTES = { 1414, 1415 } -- Kalimdor, Reinos del Este
LL.CAPITALES = { [1454] = true, [1456] = true, [1458] = true, [1453] = true, [1455] = true, [1457] = true }
function LL.Zonas()
	if zonas then return zonas end
	local out = {}
	if not (C_Map and C_Map.GetMapChildrenInfo) then return out end
	local vuelos = {}
	local N = Nav()
	if N and N.GetTravelData then
		local ok, d = pcall(N.GetTravelData)
		local mio = bando()
		for _, n in ipairs(ok and d and d.taxi or {}) do
			if n.map and (n.faction == 3 or n.faction == mio) and not n.class and not vuelos[n.map] then vuelos[n.map] = n end
		end
	end
	for _, cont in ipairs(CONTINENTES) do
		local ok, hijos = pcall(C_Map.GetMapChildrenInfo, cont, 3, true) -- Enum.UIMapType.Zone
		for _, h in ipairs(ok and hijos or {}) do
			if h.mapID and h.name then
				local v = vuelos[h.mapID]
				local capital = LL.CAPITALES[h.mapID]
				out[#out + 1] = { tipo = capital and "ciudad" or "zona", clave = "z:" .. h.mapID, nombre = h.name,
					sub = (capital and "Ciudad" or "Zona") .. (v and (" · llegas al maestro de vuelo") or ""),
					map = h.mapID, x = v and v.x or 50, y = v and v.y or 50, f = v and v.f or nil }
			end
		end
	end
	zonas = out
	return out
end
function LL.OlvidarZonas() zonas = nil end

-- PNJ por su nombre, con el buscador de Polestar (el Codex). -> { destino, ... }
function LL.BuscarPNJ(texto, max)
	local p = P()
	local Sr, Cx = p and p.Search, p and p.Codex
	if not (Sr and Sr.Query and Cx and Cx.Npc) or #(texto or "") < 3 then return {} end
	if Cx.IsLoaded and not Cx.IsLoaded() and Cx.Load and not enCombate() then pcall(Cx.Load) end
	local ok, res = pcall(Sr.Query, texto, { kinds = { npc = true }, limit = max or 6, subtitles = false })
	local out = {}
	for _, r in ipairs(ok and res or {}) do
		local okn, rec = pcall(Cx.Npc, r.id)
		local spawns = okn and rec and rec.spawns
		if spawns and #spawns > 0 then
			out[#out + 1] = { tipo = "pnj", clave = "n:" .. tostring(r.id), nombre = r.title or rec.name, sub = "PNJ" .. (rec.subname and (" · " .. rec.subname) or ""),
				spawns = spawns, id = r.id }
		end
	end
	return out
end

-- El punto de un PNJ: de sus apariciones, la más cercana (en línea recta en tu continente; si no, la primera).
local function puntoPNJ(d)
	local pc, px, py = jugadorMundo()
	local mejor, dm = nil, huge
	for _, s in ipairs(d.spawns or {}) do
		local c, wx, wy = aMundo(s.map, s.x, s.y, s.f)
		local dist = (c and pc and c == pc) and sqrt((wx - px) ^ 2 + (wy - py) ^ 2) or huge / 2
		if not mejor or dist < dm then mejor, dm = s, dist end
	end
	return mejor
end

-- La entrada de una mazmorra de Mamba (Asistente_Equipo) con Polestar.Dungeons.
local function puntoMazmorra(d)
	local p = P()
	local D = p and p.Dungeons
	local E = A.modulos and A.modulos.equipo
	local clave = d.m and E and E.CLAVE_POLESTAR and E.CLAVE_POLESTAR[d.m.clave] or d.claveP
	if not (D and D.Entrance and clave) then return nil end
	if D.Load then pcall(D.Load) end
	local ok, map, x, y, f = pcall(D.Entrance, clave)
	if ok and map and x then return { map = map, x = x, y = y, f = f } end
	return nil
end

-- El punto de cualquier destino (los servicios "más cercano" se resuelven midiendo). -> punto | nil, motivo
function LL.Punto(d, presupuesto)
	if not d then return nil, "sin" end
	if d.tipo == "servicio" and d.cat and not d.map then
		local c, no = LL.MasCercano(d.cat, d.det, presupuesto)
		if not c then return nil, no end
		return c, no
	elseif d.tipo == "pnj" then
		local s = puntoPNJ(d)
		return s and { map = s.map, x = s.x, y = s.y, f = s.f } or nil, s and nil or "sin"
	elseif d.tipo == "mazmorra" and not d.map then
		local e = puntoMazmorra(d)
		return e, e and nil or "sin"
	end
	if d.map and d.x then return d end
	return nil, "sin"
end

-- Los destinos fijos: servicios "más cercano", ciudades y zonas, mazmorras (si Asistente_Equipo está).
function LL.Destinos()
	local out = {}
	local clase = UnitClass and select(2, UnitClass("player")) or nil
	local s = S()
	for _, x in ipairs(LL.SERVICIOS) do
		local nombre = x.nombre
		if x.cat == "clase" and s and s.Etiqueta and clase then nombre = s.Etiqueta("clase", clase) end
		out[#out + 1] = { tipo = "servicio", clave = "c:" .. x.cat, cat = x.cat, det = x.cat == "clase" and clase or nil,
			nombre = nombre .. " más cercano", sub = "Servicio · el más cercano en tiempo", buscar = x.buscar }
	end
	if s and s.PROFESIONES then
		for det, nom in pairs(s.PROFESIONES) do
			out[#out + 1] = { tipo = "servicio", clave = "c:profesion:" .. det, cat = "profesion", det = det,
				nombre = "Instructor de " .. nom .. " más cercano", sub = "Servicio · el más cercano en tiempo", buscar = "instructor profesion " .. nom }
		end
	end
	for _, z in ipairs(LL.Zonas()) do out[#out + 1] = z end
	local E = A.modulos and A.modulos.equipo
	for _, m in ipairs(E and E.MAZMORRAS or {}) do
		out[#out + 1] = { tipo = "mazmorra", clave = "m:" .. m.clave, nombre = m.nombre, m = m,
			sub = format("Mazmorra · %s · niveles %d a %d", tostring(m.donde), m.min or 0, m.max or 0) }
	end
	return out
end

local VACIAS = { de = true, del = true, la = true, el = true, los = true, las = true, a = true, al = true, ir = true, llevame = true, mas = true, cercano = true, cercana = true }
-- ¿Cuánto calza el texto con el destino? 0 = no calza. Exacto > empieza igual > todas las palabras.
function LL.Calce(d, q)
	q = LL.Normal(q)
	if q == "" then return 0 end
	local nombre = LL.Normal(d.nombre)
	if nombre == q or nombre == q .. " mas cercano" then return 100 end
	local base = LL.Normal(d.nombre .. " " .. (d.sub or "") .. " " .. (d.buscar or ""))
	local util = 0
	for w in q:gmatch("%S+") do
		if not VACIAS[w] then
			util = util + 1
			if not base:find(w, 1, true) then return 0 end
		end
	end
	if util == 0 then return 0 end
	if nombre:sub(1, #q) == q then return 80 end
	return d.tipo == "servicio" and 60 or 50
end

-- Busca destinos por texto: los fijos + los PNJ de Polestar. -> lista ordenada por calce
function LL.Buscar(texto)
	local q = LL.Normal(texto)
	local out = {}
	if q == "" then return out end
	for _, d in ipairs(LL.Destinos()) do
		local c = LL.Calce(d, q)
		if c > 0 then d.calce = c; out[#out + 1] = d end
	end
	if #out < 6 then
		for _, d in ipairs(LL.BuscarPNJ(texto, 6)) do d.calce = 40; out[#out + 1] = d end
	end
	local orden = { servicio = 1, ciudad = 2, zona = 3, mazmorra = 4, pnj = 5, punto = 6 }
	table.sort(out, function(a, b)
		if a.calce ~= b.calce then return a.calce > b.calce end
		if orden[a.tipo] ~= orden[b.tipo] then return (orden[a.tipo] or 9) < (orden[b.tipo] or 9) end
		return a.nombre < b.nombre
	end)
	return out
end

-- Un destino desde lo que entregue quien llama: texto, { map, x, y } (x, y en 0-1 o en %), o un destino ya armado.
function LL.Resolver(destino)
	if type(destino) == "string" then
		if destino:find("%S") == nil then return nil end
		cargar("Asistente_Servicios")
		return LL.Buscar(destino)[1]
	end
	if type(destino) ~= "table" then return nil end
	if destino.tipo then return destino end
	local map, x, y = tonumber(destino.map or destino[1]), tonumber(destino.x or destino[2]), tonumber(destino.y or destino[3])
	if not (map and x and y) then return nil end
	if x <= 1 and y <= 1 then x, y = x * 100, y * 100 end
	return { tipo = "punto", clave = format("p:%d:%.1f:%.1f", map, x, y), nombre = destino.nombre or destino.titulo or "Punto del mapa",
		sub = "Punto del mapa", map = map, x = x, y = y, f = destino.f }
end

---------------------------------------------------------------- el viaje en curso
-- viaje = { destino, punto, ruta (la elegida), rutas, desde (GetTime), tramo (índice de Polestar), tramoDesde, tramoEst }
local viaje
local oyentes = {}
local function avisar()
	for _, fn in ipairs(oyentes) do pcall(fn, viaje) end
end
function LL.AlCambiar(fn) if type(fn) == "function" then oyentes[#oyentes + 1] = fn end end

local function rutaViva()
	local N = Nav()
	if not (N and N.GetRoute) then return nil end
	local ok, legs, ci = pcall(N.GetRoute)
	if ok then return legs, ci end
	return nil
end

-- La alternativa elegida se cumple: si la ruta viva de Polestar va a usar lo que se pidió evitar (la piedra,
-- un vuelo), se salta ese tramo con el mismo «Saltar» de Polestar (Nav.travel.SkipLeg), que planea de nuevo.
local function cumplirAlternativa(legs, ci)
	if not (viaje and viaje.ruta and legs and ci and legs[ci]) then return false end
	local k = legs[ci].kind
	local evita = (viaje.ruta.clave == "sinPiedra" or viaje.ruta.clave == "sinVuelos") and (k == "hearth" or (k == "teleport" and legs[ci].bind))
		or (viaje.ruta.clave == "sinVuelos" and k == "fly")
	if not evita then return false end
	viaje.saltos = (viaje.saltos or 0) + 1
	if viaje.saltos > 6 then return false end
	local N = Nav()
	local T = N and N.travel
	if T and T.SkipLeg then return pcall(T.SkipLeg) end
	return false
end

local function alSeguir()
	if not viaje then return end
	local api = NAPI()
	local activo, dueno = false, nil
	if api and api.Active then activo, dueno = api.Active() end
	if not activo or (dueno ~= LL.DUENO and not viaje.mazmorra) then
		-- el viaje terminó (llegó, lo soltó o alguien puso otro destino)
		LL.Terminar(true)
		return
	end
	local legs, ci = rutaViva()
	if cumplirAlternativa(legs, ci) then return end
	if legs and ci and ci ~= viaje.tramo then
		-- terminó un tramo: lo que tardó de verdad corrige las próximas estimaciones (R0)
		if viaje.tramo and viaje.tramoTipo and viaje.tramoDesde then
			LL.Medir(viaje.tramoTipo, viaje.tramoEst, ahora() - viaje.tramoDesde)
		end
		viaje.tramo, viaje.tramoDesde = ci, ahora()
		viaje.tramoTipo, viaje.tramoEst = legs[ci].kind, legs[ci].seconds
		viaje.vivo = LL.Tramos({ unpack(legs, ci) })
	end
	avisar()
end

function LL.Terminar(llego)
	if not viaje then return end
	local api = NAPI()
	if api and api.Unfollow then pcall(api.Unfollow, LL.DUENO) end
	viaje.fin = ahora()
	LL.ultimo = viaje
	viaje = nil
	avisar()
end

-- La ruta que sigue la flecha ahora: { destino, nombre, ruta, tramos (lo que falta, de Polestar), total, estimado }
function LL.Actual()
	if not viaje then return nil end
	local tr = viaje.vivo or (viaje.ruta and viaje.ruta.tramos) or {}
	local total, est = 0, false
	for _, t in ipairs(tr) do total = total + (t.seg or 0); est = est or t.estimado end
	return { destino = viaje.destino, nombre = viaje.destino.nombre, ruta = viaje.ruta, tramos = tr, total = total, estimado = est,
		alternativa = viaje.ruta and viaje.ruta.clave, desde = viaje.desde }
end

-- Llévame: resuelve el destino, elige la ruta (la más rápida o la alternativa pedida) y pone la flecha.
-- opciones = { ruta = "rapida" | "sinPiedra" | "sinVuelos" }
-- -> true, info { destino, punto, rutas, ruta } | false, motivo ("combate" | "no_encontrado" | "sin_ruta" | "sin_polestar")
function LL.Llevame(destino, opciones)
	opciones = opciones or {}
	if enCombate() then return false, "combate" end
	local d = LL.Resolver(destino)
	if not d then return false, "no_encontrado" end
	local punto = LL.Punto(d, false)
	local E = A.modulos and A.modulos.equipo
	local esMazmorra = d.tipo == "mazmorra" and d.m and E and E.GuiarEntrada
	if not punto and not esMazmorra then return false, "sin_ruta" end
	local rutas = punto and (punto.rutas or LL.Rutas(punto, false)) or { estado = "sin", rutas = {} }
	local elegida = rutas.rutas[1]
	for _, r in ipairs(rutas.rutas) do if r.clave == opciones.ruta then elegida = r end end
	-- la flecha: las mazmorras por Polestar.Dungeons (con «Volver a la guía»); lo demás por la API de Polestar
	local ok = false
	if esMazmorra then
		local okm, hecho, motivo = pcall(E.GuiarEntrada, d.m)
		if not (okm and hecho) then return false, okm and motivo or "sin_entrada" end
		ok = true
	end
	if not ok then
		local api = NAPI()
		if not api then return false, "sin_polestar" end
		local m, x, y = vivo(punto.map, punto.x, punto.y, punto.f)
		local titulo = d.nombre .. ((punto.nombre and punto.nombre ~= d.nombre) and (": " .. punto.nombre) or "")
		local okc, hecho = pcall(api.Navigate, LL.DUENO, m, x / 100, y / 100, titulo)
		ok = okc and hecho or false
	end
	if not ok then return false, "sin_ruta" end
	if viaje then local api = NAPI(); if api and api.Unfollow then pcall(api.Unfollow, LL.DUENO) end end
	viaje = { destino = d, punto = punto, rutas = rutas, ruta = elegida, desde = ahora(), mazmorra = d.tipo == "mazmorra" or nil }
	local api = NAPI()
	if api and api.Follow then pcall(api.Follow, LL.DUENO, alSeguir) end
	local legs, ci = rutaViva()
	if legs and ci then
		viaje.tramo, viaje.tramoDesde, viaje.tramoTipo, viaje.tramoEst = ci, ahora(), legs[ci].kind, legs[ci].seconds
		cumplirAlternativa(legs, ci)
	end
	avisar()
	return true, { destino = d, punto = punto, rutas = rutas, ruta = elegida }
end

LL._viaje = function() return viaje end -- para las pruebas

---------------------------------------------------------------- API pública (MambaAPI, Grupos.lua la crea)
-- Para todas las secciones (Servicios, Mazmorras, Equipo, Mi plan, el panel de la guía):
--   MambaAPI.Llevame(destino, { ruta = "rapida"|"sinPiedra"|"sinVuelos" }) -> true, info | false, motivo
--       destino: "banco", "Cima del Trueno", "Zahúrda", el nombre de un PNJ, { map, x, y[, nombre] } (x, y en 0-1 o %)
--   MambaAPI.RutasA(destino) -> { estado = "ok"|"calculando"|"sin", destino, punto, rutas = { { clave, nombre, total,
--       estimado, nota, tramos = { { tipo, texto, seg, estimado, medido, yardas } } } } }   (sin poner la flecha)
--   MambaAPI.RutaActual() -> { nombre, tramos (lo que falta), total, estimado, alternativa } | nil
--   MambaAPI.AlCambiarRuta(fn)   fn(actual | nil) cada vez que la ruta avanza, cambia o termina
--   MambaAPI.TiempoTexto(seg, estimado) -> "≈ 4:18" (R0)
local API = _G.MambaAPI
if API then
	function API.Llevame(destino, opciones) return LL.Llevame(destino, opciones) end
	function API.RutasA(destino)
		local d = LL.Resolver(destino)
		if not d then return { estado = "sin", rutas = {} } end
		local punto, no = LL.Punto(d, true)
		if not punto then return { estado = no or "sin", destino = d, rutas = {} } end
		local r = punto.rutas or LL.Rutas(punto, true)
		return { estado = r.estado, destino = d, punto = punto, rutas = r.rutas, incompleto = r.incompleto }
	end
	function API.RutaActual() return LL.Actual() end
	function API.AlCambiarRuta(fn) LL.AlCambiar(function() pcall(fn, LL.Actual()) end) end
	function API.TiempoTexto(seg, estimado) return LL.Tiempo(seg, estimado) end
end
