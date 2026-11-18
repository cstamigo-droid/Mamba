-- Mamba_Panel/Lineas.lua: QUÉ líneas van en el panel de la guía (K56) y en qué ORDEN (K62).
-- Lee lo que recomienda Mi plan (MambaPlan.Pasos y MambaPlan.Metas) sin cambiarlo. Cada línea queda así:
--   { clave, verbo, titulo, como, impacto (1-5), porque, minutos (≈, o nil), grupo, puedeYa,
--     lugar = { mapa, x, y } (0-100) | nil,   -- "Llévame" (K61): la flecha de Polestar
--     guia = { tipo = "prof" | "item" | "pasos", ... } | nil,   -- "Abrir guía" en una pestaña nueva (K57)
--     ver = "dinero" | "farmeo" | "subasta" | "macro" | nil, macro }
-- ORDEN (K62): impacto ÷ (minutos + 2), de mayor a menor; lo que hoy no se puede hacer (falta oro o nivel) va al
-- final. El impacto es una ESTIMACIÓN por tipo con su motivo a la vista ("porque"): si Mi plan trae p.impacto o
-- p.minutos, mandan esos. Los minutos de viaje salen del planificador de Polestar (Nav.API.Estimate); sin eso,
-- un ≈ por tipo, dicho como ≈. Nada se inventa: lo que Mi plan no recomienda, aquí no sale.
-- Licencia: GPL-3.0-only.
local _, N = ...
_G.MambaPanel = N
local floor, max, min, format = math.floor, math.max, math.min, string.format

function N.PJ()
	MambaPanelPJ = MambaPanelPJ or {}
	local p = MambaPanelPJ
	p.diag = p.diag or {}
	if p.abierto == nil then p.abierto = true end
	return p
end

function N.Falla(donde, err)
	local d = N.PJ().diag
	d.fallas = d.fallas or {}
	if #d.fallas < 20 then d.fallas[#d.fallas + 1] = (date and date("%d-%m %H:%M") or "") .. " " .. donde .. ": " .. tostring(err) end
	-- no se relanza: el panel nunca debe sumar errores a /errores; las pruebas leen diag.fallas
end

---------------------------------------------------------------- profesiones -> guía de Polestar
-- El nombre que usa Mi plan (el del cliente esMX) -> la guía 1-300 de Polestar.
N.GUIA_PROFESION = {
	["Alquimia"] = "forever/professions/alchemy", ["Herrería"] = "forever/professions/blacksmithing",
	["Cocina"] = "forever/professions/cooking", ["Encantamiento"] = "forever/professions/enchanting",
	["Ingeniería"] = "forever/professions/engineering", ["Primeros auxilios"] = "forever/professions/first-aid",
	["Pesca"] = "forever/professions/fishing", ["Herboristería"] = "forever/professions/herbalism",
	["Peletería"] = "forever/professions/leatherworking", ["Minería"] = "forever/professions/mining",
	["Desuello"] = "forever/professions/skinning", ["Sastrería"] = "forever/professions/tailoring",
}

---------------------------------------------------------------- minutos de viaje
local viaje, reintento = {}, false
N.alVolverACalcular = nil -- Panel.lua: vuelve a armar las líneas cuando el planificador estaba ocupado

-- Minutos hasta un lugar con el planificador de Polestar (piedra de hogar y vuelos incluidos). -> minutos | nil
function N.MinutosA(lugar)
	if not (lugar and lugar.mapa and lugar.x and lugar.y) then return nil end
	local k = lugar.mapa .. ":" .. floor(lugar.x * 10) .. ":" .. floor(lugar.y * 10)
	local c = viaje[k]
	local ahora = GetTime and GetTime() or 0
	if c and ahora - c.t < 60 then return c.min end
	local P = _G.Polestar
	local api = P and P.Nav and P.Nav.API
	if not (api and api.Estimate) then return nil end
	local ok, seg, por = pcall(api.Estimate, nil, nil, nil, lugar.mapa, lugar.x / 100, lugar.y / 100)
	if ok and seg then
		viaje[k] = { min = max(1, floor(seg / 60 + 0.5)), t = ahora }
		return viaje[k].min
	end
	if ok and por == "busy" then
		-- el planificador ya gastó sus 25 ms de este cuadro: se vuelve a preguntar enseguida, sin guardar nada
		if not reintento and C_Timer and C_Timer.After then
			reintento = true
			C_Timer.After(0.5, function() reintento = false; if N.alVolverACalcular then N.alVolverACalcular() end end)
		end
		return nil
	end
	viaje[k] = { t = ahora } -- desconocido: no se vuelve a preguntar en un minuto
	return nil
end

---------------------------------------------------------------- de un paso de Mi plan a una línea
-- Por tipo: verbo (ícono de Polestar), impacto base y su porqué, ≈minutos sin viaje, si es en grupo.
local TIPO = {
	montura = { "train", 5, "la montura te mueve un 60 % más rápido", 2 },
	entrenar = { "train", 3, "tus hechizos del nivel", 2 },
	rango = { "train", 2, "sin el rango nuevo tu profesión no sube", 1 },
	bolsa = { "buy", 2, "más casillas, menos viajes a vender", 3 },
	llenas = { "vendor", 3, "con las bolsas llenas pierdes el botín", 3 },
	mazmorra = { "kill", 2, "una pieza que mejora tu equipo", 25 },
	dinero = { "note", 1, "lo que falta para tu próxima meta", nil },
	macro = { "note", 1, "un clic menos en cada pelea", 1 },
	farmeo = { "collect", 1, "oro sin gastar materiales, de camino", nil },
}

local function clase(p)
	local c = p.clave or ""
	if c:find("^meta:montura") or c:find("^montura") then return "montura" end
	if c:find("^meta:entrenar") then return "entrenar" end
	if c:find("^rango:") then return "rango" end
	if c:find("^bolsa:") then return "bolsa" end
	if c:find("^mazmorra:") then return "mazmorra" end
	if c:find("^dinero:") then return "dinero" end
	if c:find("^macro:") then return "macro" end
	return nil
end

local function profesionDe(p)
	local t = p.titulo or ""
	for nombre in pairs(N.GUIA_PROFESION) do
		if t:find(nombre, 1, true) == 1 then return nombre end
	end
	return nil
end

local function aLinea(p, e)
	local k = clase(p)
	if not k then return nil end -- "guia" y lo que no se reconoce: la guía ya es el panel
	local t = TIPO[k]
	local l = { clave = p.clave, tipo = k, verbo = t[1], impacto = t[2], porque = t[3], minutos = t[4],
		titulo = p.titulo, como = p.detalle, lugar = p.lugar, item = p.item, puedeYa = true, grupo = false }
	-- "Nivel 40" en el tipo de las metas de Mi plan: hasta ese nivel no se puede entrenar
	local nivelMeta = tonumber(tostring(p.tipo or ""):match("^Nivel (%d+)"))
	if nivelMeta and e and e.nivel < nivelMeta then l.puedeYa = false end
	-- la montura del 40 sale dos veces en Mi plan (la meta y "ya te alcanza"): una sola línea
	if k == "montura" then l.unica = "montura" .. (tostring(p.clave):match("(%d+)$") or "") end
	if k == "montura" or k == "entrenar" then
		-- "Te faltan X." en el detalle: hoy no alcanza el oro
		if (p.detalle or ""):find("^Te faltan") then l.puedeYa = false end
		if p.nivel and e and e.nivel < p.nivel then l.puedeYa = false end
	elseif k == "rango" then
		local prof = profesionDe(p)
		if prof then l.guia = { tipo = "prof", id = N.GUIA_PROFESION[prof], nombre = prof } end
		if p.nivel and e and e.nivel < p.nivel then l.puedeYa = false end
	elseif k == "bolsa" then
		local n = tonumber((p.titulo or ""):match("%((%d+) casillas%)"))
		local de = tonumber((p.titulo or ""):match("bolsa de (%d+)"))
		if n and de then l.impacto = min(4, max(1, floor((n - de) / 4 + 0.5))); l.porque = format("+%d casillas", n - de) end
		if p.item then l.guia = { tipo = "item", id = p.item } end
		l.ver, l.destino = "subasta", "subasta"
	elseif k == "mazmorra" then
		l.grupo = true
		local pct = tonumber((p.detalle or ""):match("mejora (%d+) %%"))
		if pct then l.impacto = min(5, max(1, floor(pct / 10 + 0.5))); l.porque = format("mejora tu equipo un %d %%", pct) end
		local pasadas = tonumber((p.detalle or ""):match("unas (%d+) pasadas"))
		l.minutos = (pasadas or 1) * 25
		-- "Llévame a la entrada": el motor de Ir a… resuelve la mazmorra por su nombre (K58)
		l.destino = (p.titulo or ""):match("^(.-):") 
		if p.item then l.guia = { tipo = "item", id = p.item } end
	elseif k == "dinero" then
		l.ver = "dinero"
	elseif k == "macro" then
		l.ver, l.macro = "macro", p.macro
	end
	-- Mi plan manda si trae sus números
	if type(p.impacto) == "table" and tonumber(p.impacto[1]) then l.impacto = tonumber(p.impacto[1]); l.porque = p.impacto[2] or l.porque end
	if tonumber(p.minutos) then l.minutos = tonumber(p.minutos) end
	if p.grupo ~= nil then l.grupo = p.grupo and true or false end
	-- con un lugar, el viaje se suma (Ir a…)
	local v = l.lugar and N.MinutosA(l.lugar)
	if v then l.minutos = (l.minutos or 0) + v; l.viaje = v end
	-- con pasos que seguir (y sin otra guía), Mamba arma la suya: ir y hacerlo
	if not l.guia and l.lugar then l.guia = { tipo = "pasos" } end
	return l
end

-- Bolsas casi llenas: vender o guardar (no está en Mi plan como paso).
local function lineaLlenas(e)
	local b = e and e.bolsas
	if not (b and b.total and b.total > 0 and b.libres and b.libres <= 2) then return nil end
	local t = TIPO.llenas
	return { clave = "llenas", tipo = "llenas", verbo = t[1], impacto = t[2], porque = t[3], minutos = t[4],
		titulo = b.libres == 0 and "Bolsas llenas: vende o guarda" or format("Te quedan %d casillas: vende o guarda", b.libres),
		como = "Vende la basura en cualquier vendedor; el Tasador te dice qué conviene subastar y qué guardar en el banco.",
		ver = "vender", destino = "reparar", puedeYa = true, grupo = false }
end

-- Subir una profesión: MambaProfesiones.Recomendaciones (Mamba_Profesiones, bc0c332dd) ya viene ordenada por
-- impacto ÷ costo, con su cómo (el próximo paso de SkillUp, con PNJ y zona), sus minutos y su Llévame al farmeo.
local IMPACTO_ESTRELLAS = { ["Conviene mucho"] = 4, ["Conviene"] = 2, ["Conviene poco"] = 1 }
local function lineasProfesion(maximo)
	local P = _G.MambaProfesiones
	local out = {}
	if not (P and P.Recomendaciones) then return out end
	local ok, recs = pcall(P.Recomendaciones)
	if not ok or type(recs) ~= "table" then return out end
	for i = 1, math.min(maximo, #recs) do
		local r = recs[i]
		if type(r) == "table" and r.texto then
			local nombre = tostring(r.texto):match("^Sube (.-) de %d")
			out[#out + 1] = { clave = "prof:" .. tostring(nombre or r.texto), tipo = "profesion", verbo = "craft",
				impacto = IMPACTO_ESTRELLAS[r.estrellas] or 1, porque = r.impacto, minutos = tonumber(r.minutos) and math.floor(r.minutos + 0.5) or nil,
				titulo = r.texto, como = r.como, grupo = r.solo == false, puedeYa = true,
				llevar = type(r.llevame) == "function" and r.llevame or nil, abrir = type(r.abrir) == "function" and r.abrir or nil,
				guia = nombre and N.GUIA_PROFESION[nombre] and { tipo = "prof", id = N.GUIA_PROFESION[nombre], nombre = nombre } or nil }
		end
	end
	return out
end

-- Farmear de camino: lo que dice Mi plan › Dinero cuando tienes una profesión de recolección.
local function lineasFarmeo(M, e)
	local out = {}
	if not (M.ComoJuntar and e) then return out end
	local ok, ideas = pcall(M.ComoJuntar, e)
	if not ok or type(ideas) ~= "table" then return out end
	for _, i in ipairs(ideas) do
		if i.accion == "farmeo" then
			local t = TIPO.farmeo
			out[#out + 1] = { clave = "farmeo:" .. (i.titulo or ""), tipo = "farmeo", verbo = t[1], impacto = t[2], porque = t[3],
				titulo = i.titulo, como = (i.detalle or "") .. " Hazlo de camino: no te desvía de la guía.", ver = "farmeo",
				puedeYa = true, grupo = false }
		end
	end
	return out
end

function N.Puntaje(l)
	return (l.impacto or 1) / ((l.minutos or 10) + 2)
end

-- Las líneas ordenadas, ya sin lo que el jugador marcó como hecho o descartó. -> lista
function N.Lineas()
	local M = _G.MambaPlan
	if not (M and M.Pasos and M.Estado and M.PJ) then return {} end
	local okE, e = pcall(M.Estado)
	if not okE then N.Falla("Estado", e); return {} end
	local pj = M.PJ()
	local okP, pasos = pcall(M.Pasos, e, pj.respuestas or {})
	if not okP then N.Falla("Pasos", pasos); return {} end
	local out, visto, unicas = {}, {}, {}
	local function add(l)
		if l and l.unica then
			if unicas[l.unica] then return end
			unicas[l.unica] = true
		end
		if l and l.clave and not visto[l.clave] and not (pj.hechos and pj.hechos[l.clave]) and not (pj.descartados and pj.descartados[l.clave]) then
			visto[l.clave] = true
			out[#out + 1] = l
		end
	end
	for _, p in ipairs(pasos or {}) do add(aLinea(p, e)) end
	add(lineaLlenas(e))
	for _, l in ipairs(lineasProfesion(2)) do add(l) end
	for _, l in ipairs(lineasFarmeo(M, e)) do add(l) end
	-- K103: los avisos de oportunidad (Avisos.lua), ordenados con lo demás
	if N.AplicarAvisos then
		local ok, err = pcall(N.AplicarAvisos, out, e)
		if not ok then N.Falla("Avisos", err) end
	end
	if N.PJ().soloSolo then
		for i = #out, 1, -1 do if out[i].grupo then table.remove(out, i) end end
	end
	table.sort(out, function(a, b)
		if a.puedeYa ~= b.puedeYa then return a.puedeYa end
		local pa, pb = N.Puntaje(a), N.Puntaje(b)
		if pa ~= pb then return pa > pb end
		return (a.clave or "") < (b.clave or "")
	end)
	return out
end

---------------------------------------------------------------- texto de la puntuación (K62)
-- "★★★ · ≈10 min · solo" (el ≈ dice que es estimación; sin minutos, no se inventan).
function N.Puntuacion(l)
	local i = l.impacto or 1
	local estrellas = i >= 4 and "★★★" or i >= 2 and "★★" or "★"
	local partes = { estrellas }
	if l.minutos then partes[#partes + 1] = "≈" .. l.minutos .. " min" end
	partes[#partes + 1] = l.grupo and "en grupo" or "solo"
	if not l.puedeYa then partes[#partes + 1] = "todavía no" end
	return table.concat(partes, " · ")
end

function N.Hecho(l, descartar)
	local M = _G.MambaPlan
	if not (M and M.PJ and l and l.clave) then return end
	local pj = M.PJ()
	local t = descartar and "descartados" or "hechos"
	pj[t] = pj[t] or {}
	pj[t][l.clave] = true
	if M.Cambio then pcall(M.Cambio) end
end
