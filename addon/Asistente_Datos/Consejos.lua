-- Asistente_Datos: arma los consejos "sube de nivel y de profesión al mismo tiempo" y el plan de bolsas.
-- Solo LEE tablas y el estado del personaje; no automatiza nada del juego.
-- Licencia: GPL-3.0. Los datos vienen de Datos.lua (ver LICENSE-DATA.txt).
local _, ns = ...
ns = ns or {}
local D = ns.Datos or AsistenteDatos
local EN = ns.NombresEN or AsistenteNombresEN or { item = {}, npc = {}, mision = {} }

local C = {}
ns.Consejos = C
AsistenteConsejos = C

local floor, ceil, format = math.floor, math.ceil, string.format

-- ------------------------------------------------------------------ nombres (en el idioma del juego)
-- El juego da los nombres en español; el respaldo en inglés solo aparece si el juego aún no los tiene.
function C.NombreObjeto(id)
	local n
	if C_Item and C_Item.GetItemNameByID then n = C_Item.GetItemNameByID(id) end
	if not n and C_Item and C_Item.GetItemInfo then n = C_Item.GetItemInfo(id) end
	if not n and GetItemInfo then n = GetItemInfo(id) end
	return n or EN.item[id] or ("objeto " .. id)
end

function C.NombreHechizo(id)
	local n
	if C_Spell and C_Spell.GetSpellName then n = C_Spell.GetSpellName(id) end
	if not n and GetSpellInfo then n = GetSpellInfo(id) end
	return n or ("receta " .. id)
end

function C.NombreZona(uiMap)
	local i = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(uiMap)
	return (i and i.name) or ("zona " .. uiMap)
end

function C.NombreMision(id)
	local n
	if C_QuestLog and C_QuestLog.GetTitleForQuestID then n = C_QuestLog.GetTitleForQuestID(id) end
	return n or (EN.mision and EN.mision[id]) or ("misión " .. id)
end

-- El nombre de un PNJ solo se puede pedir al juego por su cuadro (si ya lo vio). NO VERIFICADO en Forever.
function C.NombrePNJ(id)
	if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
		local ok, info = pcall(C_TooltipInfo.GetHyperlink, "unit:Creature-0-0-0-0-" .. id .. "-0000000000")
		if ok and info and info.lines and info.lines[1] and info.lines[1].leftText then
			return info.lines[1].leftText
		end
	end
	return EN.npc[id] or ("PNJ " .. id)
end

-- ------------------------------------------------------------------ utilidades
-- Qué clase de % es: de diseño (tabla de botín del juego, forever-db) o de la guía de Polestar,
-- cuyo origen no está verificado. Ninguno es observado: no hay muestra todavía.
local TIPO_PCT = { fdb = "de diseño", pg = "según la guía, origen sin verificar" }

local function pct(o)
	if not o.pct then return nil end
	local p = (o.pct == floor(o.pct)) and format("%d", o.pct) or (format("%.1f", o.pct):gsub("%.", ","))
	-- Sin muestra no hay rango de confianza: se dice (ESQUEMA_Y_ACTUALIZACION.md, "Sobre el %").
	local tipo = TIPO_PCT[o.fuente] or o.fuente
	if o.muestra then return format("%s %% %s, muestra %d", p, tipo, o.muestra) end
	return format("%s %% %s, sin muestra", p, tipo)
end

local function nombreFuente(k)
	local f = D.fuentes[k]
	return f and f.nombre or k
end

-- El tramo que sirve hoy: el que contiene la habilidad actual. Si ya lo pasaste, nada.
local function tramoUtil(t, habilidad)
	if habilidad == nil then return false end
	return habilidad >= t.desde and habilidad < t.hasta
end

local function cantidadDelTramo(t, item, habilidad)
	for _, m in ipairs(t.mats) do
		if m[1] == item then
			local falta = (t.hasta - habilidad) / (t.hasta - t.desde)
			return ceil(m[2] * falta)
		end
	end
end

local function misionesTexto(lista, nivel)
	if not lista or #lista == 0 then return nil end
	-- La lista viene ordenada por cercanía (la que más comparte terreno primero).
	-- Se quitan las que todavía no puedes tomar (nivel mínimo) o que ya son grises (10 niveles abajo).
	local orden = {}
	for _, q in ipairs(lista) do
		local m = D.misiones[q]
		if not m or ((m.nivelMin or 0) <= nivel and (m.nivel or 0) >= nivel - 9) then orden[#orden + 1] = q end
	end
	if #orden == 0 then return nil end
	local txt = C.NombreMision(orden[1])
	if #orden == 2 then txt = txt .. " y " .. C.NombreMision(orden[2])
	elseif #orden > 2 then txt = txt .. ", " .. C.NombreMision(orden[2]) .. " y " .. (#orden - 2) .. " más" end
	return txt
end

-- ------------------------------------------------------------------ consejo de una fila
-- habilidades = { [185] = 180, [171] = 160, ... } (id de profesión -> puntos; nil = no la tienes)
function C.Texto(k, nivel, habilidades)
	local partes = {}
	-- 1) tramos de profesión que este material sube hoy
	for _, ti in ipairs(k.tramos) do
		local t = D.tramos[ti]
		local h = habilidades[t.prof]
		if tramoUtil(t, h) then
			partes[#partes + 1] = { cant = cantidadDelTramo(t, k.item, h),
				texto = format("sube %s de %d a %d con %s", D.profesiones[t.prof], h, t.hasta, C.NombreHechizo(t.hechizo)) }
		end
	end
	-- 2) Herboristería: recoger la hierba sube la profesión mientras no esté gris
	local herb = habilidades[182]
	if k.tipo == "nodo" and k.hierba and herb and herb >= k.hierba and herb < k.hierba + 100 then
		partes[#partes + 1] = { texto = format("recogerla sube %s (pide %d)", D.profesiones[182], k.hierba) }
	end
	if #partes == 0 then return nil end

	local mat = C.NombreObjeto(k.item)
	local cant = partes[1].cant
	local verbo = (k.tipo == "nodo") and "recoge" or "junta"
	local lineas = {}
	local cabeza = cant and format("%s %d %s", verbo, cant, mat) or format("%s %s", verbo, mat)
	local origen = {}
	for _, o in ipairs(k.origenes) do
		if o.pnj then
			origen[#origen + 1] = format("%s (%s; %s)", C.NombrePNJ(o.pnj), pct(o) or "sin %", nombreFuente(o.fuente))
		elseif o.nodos then
			origen[#origen + 1] = format("%d puntos de recolección en la zona (%s)", o.nodos, nombreFuente(o.fuente))
		elseif o.guiaZona then
			origen[#origen + 1] = format("la ruta de Herboristería pasa por esta zona (%s)", nombreFuente(o.fuente))
		end
	end
	local que = {}
	for _, p in ipairs(partes) do que[#que + 1] = p.texto end
	lineas[1] = cabeza .. ": " .. table.concat(que, "; ") .. "."
	if #origen > 0 then lineas[#lineas + 1] = "  Sale de: " .. table.concat(origen, ", ") .. "." end
	local m = misionesTexto(k.misiones, nivel)
	if m then lineas[#lineas + 1] = "  Queda de paso con: " .. m .. "." end
	return table.concat(lineas, "\n")
end

-- Todos los consejos de una zona, para tu nivel y tus profesiones.
function C.ParaZona(uiMap, nivel, habilidades)
	local z = D.zonas[uiMap]
	if not z then return {} end
	local out = {}
	for _, k in ipairs(D.consejos) do
		if k.zona == uiMap then
			local t = C.Texto(k, nivel, habilidades)
			if t then out[#out + 1] = t end
		end
	end
	return out
end

-- Etapa 5: lo que conviene juntar mientras haces UNA misión (sirve junto a la guía de Polestar).
function C.ParaMision(questId, nivel, habilidades)
	local out = {}
	for _, i in ipairs(D.porMision[questId] or {}) do
		local t = C.Texto(D.consejos[i], nivel, habilidades)
		if t then out[#out + 1] = t end
	end
	return out
end

-- Crédito visible de cada fuente activa (ForeverDB lo exige si se usan sus datos).
function C.Creditos()
	local out = {}
	for _, k in ipairs({ "fdb", "pg", "fdbapi" }) do
		local f = D.fuentes[k]
		if f and f.activa ~= false then out[#out + 1] = f.credito .. " — " .. f.url end
	end
	return out
end

-- ------------------------------------------------------------------ bolsas (etapa 6)
local B = {}
ns.Bolsas = B
AsistenteBolsas = B

local function tieneBit(mascara, bit)
	if not mascara or mascara == 0 then return true end      -- 0 = todas
	return floor(mascara / 2 ^ (bit - 1)) % 2 == 1
end

-- Misiones que regalan bolsas y que te tocan (raza y clase), desde tu nivel - 5 en adelante.
-- El juego confirma después si el objeto es una bolsa de verdad (clase de objeto 1) y sus ranuras.
function B.Plan(nivel, razaId, claseId)
	local out = {}
	for _, b in ipairs(D.bolsas) do
		if tieneBit(b.razas, razaId) and tieneBit(b.clases, claseId) and (b.nivel or 0) >= nivel - 5 then
			out[#out + 1] = b
		end
	end
	return out
end

-- Bolsa NORMAL: clase 1 (contenedor), subclase 0. Las de almas (1), hierbas (2) y demás solo guardan
-- un tipo de objeto, y el carcaj es otra clase (11): ninguna cuenta para el plan de espacio.
function B.EsBolsa(itemId)
	if not (C_Item and C_Item.GetItemInfoInstant) then return nil end
	local _, _, _, _, _, clase, subclase = C_Item.GetItemInfoInstant(itemId)
	return clase == 1 and subclase == 0
end

-- equipadas = ranuras de tus 4 bolsas NORMALES (0 = hueco vacío; una bolsa especial o un carcaj se pasa
-- como math.huge para que nunca se elija). nueva = ranuras de la bolsa normal que conseguiste.
-- Devuelve el consejo: dónde ponerla y qué hacer con la vieja.
function B.QueHacer(equipadas, nueva, huecosBanco)
	local menor, idx = math.huge, nil
	for i = 1, 4 do
		local s = equipadas[i] or 0
		if s < menor then menor, idx = s, i end
	end
	if menor == 0 then
		return format("Ponte la bolsa nueva de %d ranuras en el hueco vacío %d.", nueva, idx), idx
	end
	if nueva <= menor then
		return format("No te sirve: tu bolsa más chica ya tiene %d ranuras. Véndela o guárdala.", menor), nil
	end
	local vieja
	if (huecosBanco or 0) > 0 then
		vieja = format("pasa la vieja de %d al banco como bolsa del banco (tienes %d hueco%s libre%s)", menor,
			huecosBanco, huecosBanco == 1 and "" or "s", huecosBanco == 1 and "" or "s")
	else
		vieja = format("la vieja de %d véndela o ponla en la subasta (no tienes huecos de bolsa libres en el banco)", menor)
	end
	return format("Cambia la bolsa %d (%d ranuras) por la nueva de %d: ganas %d ranuras; %s.", idx, menor, nueva,
		nueva - menor, vieja), idx
end

-- ------------------------------------------------------------------ comando /asistente (solo muestra texto)
function C.HabilidadesDelJugador()
	local h = {}
	-- GetProfessions() devuelve prof1, prof2, arqueología, pesca, cocina, primeros auxilios, con nil en los
	-- huecos (Forever no tiene arqueología). ipairs se cortaría en el primer nil: se recorre con select("#").
	-- Forever no tiene GetSkillLineInfo (addon/MEDIDOR_LEEME.md).
	if GetProfessions and GetProfessionInfo then
		local lista = { GetProfessions() }
		for i = 1, select("#", GetProfessions()) do
			if lista[i] then
				local _, _, rango, _, _, _, linea = GetProfessionInfo(lista[i])
				if linea then h[linea] = rango end
			end
		end
	end
	return h
end

if SlashCmdList then
	SLASH_ASISTENTE1 = "/asistente"
	SlashCmdList.ASISTENTE = function(arg)
		local say = function(t) DEFAULT_CHAT_FRAME:AddMessage("|cff66bbffAsistente:|r " .. t) end
		if arg == "fuentes" then
			for _, l in ipairs(C.Creditos()) do say(l) end
			return
		end
		if arg == "bolsas" then
			local nivel = UnitLevel and UnitLevel("player") or 1
			local _, _, raza = UnitRace("player")
			local _, _, clase = UnitClass("player")
			local plan = B.Plan(nivel, raza, clase)
			if #plan == 0 then say("No conozco misiones que te regalen bolsas desde tu nivel.") end
			for _, b in ipairs(plan) do
				local ok = B.EsBolsa(b.item)
				if ok ~= false then
					say(format("Nivel %d: %s regala %s%s.", b.nivel or 0, C.NombreMision(b.mision), C.NombreObjeto(b.item),
						b.eleccion and " (a elegir entre las recompensas)" or ""))
				end
			end
			say("Cuando tengas una bolsa más grande: cámbiala por la más chica; la vieja va al banco si tienes hueco de bolsa ahí.")
			return
		end
		local mapa = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
		local nivel = UnitLevel and UnitLevel("player") or 1
		local lista = mapa and C.ParaZona(mapa, nivel, C.HabilidadesDelJugador()) or {}
		if #lista == 0 then say("No tengo consejos de profesión para esta zona y tus puntos de hoy.") end
		for _, t in ipairs(lista) do for l in t:gmatch("[^\n]+") do say(l) end end
		say("Fuentes de estos datos: /asistente fuentes")
	end
end
