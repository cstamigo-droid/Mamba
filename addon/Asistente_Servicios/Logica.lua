-- Asistente_Servicios: lógica (sin pantalla). Qué servicios hay en la ciudad, búsqueda en
-- español, el más cercano, el ángulo de la flecha y el punto del minimapa.
-- Licencia: GPL-3.0-only. Datos: Ciudades.lua (forever-db de Polestar, GPL-3.0).
local _, ns = ...
local S = {}
ns.S = S
_G.Asistente_Servicios = S

local D = _G.Asistente_ServiciosDatos
S.datos = D

local sqrt, atan2, sin, cos, pi, floor = math.sqrt, math.atan2, math.sin, math.cos, math.pi, math.floor
local lower, gsub, find, format = string.lower, string.gsub, string.find, string.format

---------------------------------------------------------------- categorías
-- orden en la lista, nombre en español, icono del minimapa del juego y palabras para buscar
S.CATEGORIAS = {
	{ clave = "banco", nombre = "Banco", icono = "Interface\\Minimap\\Tracking\\Banker", buscar = "banco banquero guardar" },
	{ clave = "subasta", nombre = "Casa de subastas", icono = "Interface\\Minimap\\Tracking\\Auctioneer", buscar = "subasta subastas subastador casa" },
	{ clave = "buzon", nombre = "Buzón", icono = "Interface\\Minimap\\Tracking\\Mailbox", buscar = "buzon correo carta" },
	{ clave = "posada", nombre = "Posada", icono = "Interface\\Minimap\\Tracking\\Innkeeper", buscar = "posada posadero piedra hogar descansar" },
	{ clave = "vuelo", nombre = "Maestro de vuelo", icono = "Interface\\Minimap\\Tracking\\FlightMaster", buscar = "vuelo volar maestro jinete viento" },
	{ clave = "establo", nombre = "Maestro de establos", icono = "Interface\\Minimap\\Tracking\\StableMaster", buscar = "establo establos mascota" },
	{ clave = "reparar", nombre = "Reparar", icono = "Interface\\Minimap\\Tracking\\Repair", buscar = "reparar reparacion arreglar herrero" },
	{ clave = "clase", nombre = "Instructor de clase", icono = "Interface\\Minimap\\Tracking\\Class", buscar = "instructor clase entrenador hechizos" },
	{ clave = "profesion", nombre = "Instructor de profesión", icono = "Interface\\Minimap\\Tracking\\Profession", buscar = "instructor profesion entrenador oficio" },
	{ clave = "vendedor", nombre = "Vendedor", icono = "Interface\\Minimap\\Tracking\\Food", buscar = "vendedor tienda comprar vender" },
	{ clave = "otros", nombre = "Otros", icono = "Interface\\Minimap\\Tracking\\None", buscar = "otros" },
}
S.CAT = {}
for i, c in ipairs(S.CATEGORIAS) do c.orden = i; S.CAT[c.clave] = c end

S.CLASES = {
	DRUID = "druida", HUNTER = "cazador", MAGE = "mago", PALADIN = "paladín", PRIEST = "sacerdote",
	ROGUE = "pícaro", SHAMAN = "chamán", WARLOCK = "brujo", WARRIOR = "guerrero",
}
S.PROFESIONES = {
	alquimia = "Alquimia", herreria = "Herrería", encantamiento = "Encantamiento", ingenieria = "Ingeniería",
	herboristeria = "Herboristería", mineria = "Minería", desuello = "Desuello", peleteria = "Peletería",
	sastreria = "Sastrería", cocina = "Cocina", primeros_auxilios = "Primeros auxilios", pesca = "Pesca",
}
S.VENDEDORES = {
	reactivos = "de reactivos", venenos = "de venenos", bolsas = "de bolsas", comida = "de comida y bebida",
	general = "de artículos generales", comercio = "de materiales de comercio", recetas = "de recetas",
	pesca = "de pesca", municion = "de munición, arcos y armas de fuego", armaduras = "de armaduras",
	armas = "de armas", suministros = "de suministros de profesión", tabardos = "de tabardos", otros = "otros",
}
S.OTROS = {
	hermandad = "Maestro de hermandad", maestro_armas = "Maestro de armas", zepelin = "Maestro de zepelines",
	campo_batalla = "Maestro de batalla (JcJ)", monta = "Instructor de monta", mascotas = "Instructor de mascotas",
	portales = "Instructor de portales", demonios = "Instructor de demonios", barbero = "Barbero",
}

-- Nombre visible de un grupo (categoría + detalle)
function S.Etiqueta(cat, det)
	if cat == "clase" then return "Instructor de " .. (S.CLASES[det] or tostring(det)) end
	if cat == "profesion" then return "Instructor de " .. (S.PROFESIONES[det] or tostring(det)) end
	if cat == "vendedor" then return "Vendedor " .. (S.VENDEDORES[det] or tostring(det)) end
	if cat == "otros" then return S.OTROS[det] or tostring(det) end
	return S.CAT[cat] and S.CAT[cat].nombre or tostring(cat)
end

---------------------------------------------------------------- texto
local TILDES = { ["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n",
	["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u", ["Ñ"] = "n" }
function S.Normal(t)
	t = lower(tostring(t or ""))
	for con, sin_ in pairs(TILDES) do t = gsub(t, con, sin_) end
	return (gsub(gsub(t, "^%s+", ""), "%s+$", ""))
end

-- Palabras que se ignoran al buscar ("instructor de alquimia" = "alquimia")
local VACIAS = { de = true, del = true, la = true, el = true, los = true, las = true, un = true, una = true, ["y"] = true,
	instructor = true, entrenador = true, maestro = true, donde = true, esta = true, ir = true }

-- ¿Este grupo responde a la búsqueda? Todas las palabras útiles deben aparecer.
function S.Coincide(grupo, texto)
	local q = S.Normal(texto)
	if q == "" then return true end
	local base = S.Normal(grupo.etiqueta .. " " .. (S.CAT[grupo.cat] and S.CAT[grupo.cat].buscar or "") .. " " ..
		(grupo.nombres or ""))
	local utiles, todas = {}, {}
	for palabra in q:gmatch("%S+") do
		todas[#todas + 1] = palabra
		if not VACIAS[palabra] then utiles[#utiles + 1] = palabra end
	end
	if #utiles == 0 then utiles = todas end -- "instructor" a secas: se busca tal cual
	for _, palabra in ipairs(utiles) do
		if not find(base, palabra, 1, true) then return false end
	end
	return true
end

---------------------------------------------------------------- distancias
function S.Distancia(x1, y1, x2, y2)
	local dx, dy = x2 - x1, y2 - y1
	return sqrt(dx * dx + dy * dy)
end

-- Mundo (x norte, y oeste, yardas) <-> % del mapa de la ciudad, con el marco del uiMap
function S.APorcentaje(marco, x, y)
	return (y - marco.left) / (marco.right - marco.left) * 100, (x - marco.top) / (marco.bottom - marco.top) * 100
end

---------------------------------------------------------------- la ciudad
-- Agrupa los lugares de la ciudad por (categoría, detalle). Con la posición del jugador (px, py en
-- yardas del mundo) ordena cada grupo por cercanía; sin ella, por nombre.
function S.Grupos(uiMap, claseJugador, px, py)
	local c = D and D.ciudades and D.ciudades[uiMap]
	if not c then return nil end
	local por, lista = {}, {}
	for _, l in ipairs(c.lugares) do
		local k = l.cat .. "|" .. tostring(l.det or "")
		local g = por[k]
		if not g then
			g = { cat = l.cat, det = l.det, etiqueta = S.Etiqueta(l.cat, l.det), lugares = {}, conf = l.conf }
			por[k] = g
			lista[#lista + 1] = g
		end
		g.lugares[#g.lugares + 1] = l
	end
	for _, g in ipairs(lista) do
		local nombres = {}
		for _, l in ipairs(g.lugares) do
			nombres[#nombres + 1] = l.nombre
			if l.titulo then nombres[#nombres + 1] = l.titulo end
			l.dist = (px and py) and S.Distancia(px, py, l.x, l.y) or nil
		end
		g.nombres = table.concat(nombres, " ")
		table.sort(g.lugares, function(a, b)
			if a.dist and b.dist and a.dist ~= b.dist then return a.dist < b.dist end
			return a.nombre < b.nombre
		end)
		g.mejor = g.lugares[1]
		-- la clase del jugador va arriba dentro de "Instructor de clase"; las otras clases, más abajo
		g.tuya = (g.cat == "clase" and g.det == claseJugador) or nil
	end
	table.sort(lista, function(a, b)
		local oa, ob = S.CAT[a.cat].orden, S.CAT[b.cat].orden
		if a.cat == "clase" and not a.tuya then oa = 10.5 end
		if b.cat == "clase" and not b.tuya then ob = 10.5 end
		if oa ~= ob then return oa < ob end
		return a.etiqueta < b.etiqueta
	end)
	return lista, c
end

-- Filtra los grupos con el texto de búsqueda
function S.Buscar(grupos, texto)
	local out = {}
	for _, g in ipairs(grupos or {}) do
		if S.Coincide(g, texto) then out[#out + 1] = g end
	end
	return out
end

-- ¿En qué ciudad hay instructor de esta clase? (para decir "no hay aquí, ve a ...")
function S.CiudadConClase(clase)
	local out = {}
	for um, c in pairs(D and D.ciudades or {}) do
		for _, l in ipairs(c.lugares) do
			if l.cat == "clase" and l.det == clase then out[#out + 1] = c.nombre; break end
		end
	end
	table.sort(out)
	return out
end

---------------------------------------------------------------- flecha
-- Ángulo (radianes, contra reloj, 0 = adelante) para girar una flecha que apunta hacia arriba.
-- facing: GetPlayerFacing() (0 = norte, contra reloj). x norte, y oeste.
function S.AnguloFlecha(px, py, facing, tx, ty)
	local rumbo = atan2(ty - py, tx - px) -- desde el norte hacia el oeste = contra reloj
	local a = rumbo - (facing or 0)
	while a > pi do a = a - 2 * pi end
	while a <= -pi do a = a + 2 * pi end
	return a
end

-- Avanza por el camino: devuelve el índice del próximo punto a seguir.
-- puntos = { {x=,y=}, ... }; se salta cada punto ya alcanzado (a menos de `cerca` yardas).
function S.Avanzar(puntos, idx, px, py, cerca)
	cerca = cerca or 6
	idx = idx or 1
	while idx < #puntos do
		local p = puntos[idx]
		if S.Distancia(px, py, p.x, p.y) > cerca then
			-- si el siguiente ya está más cerca que este, este quedó atrás
			local q = puntos[idx + 1]
			if S.Distancia(px, py, q.x, q.y) >= S.Distancia(px, py, p.x, p.y) then break end
		end
		idx = idx + 1
	end
	return idx
end

-- Texto de la distancia
function S.TextoDistancia(yardas)
	if not yardas then return "" end
	if yardas < 10 then return "aquí" end
	return format("%d yardas", floor(yardas + 0.5))
end

---------------------------------------------------------------- minimapa
-- Dónde dibujar la marca en el minimapa: devuelve (dx, dy) en píxeles desde el centro (dy hacia arriba)
-- y si quedó en el borde. radio = yardas que muestra el minimapa del centro al borde; ancho = píxeles.
-- giraMapa = el minimapa gira con el jugador (CVar rotateMinimap).
function S.PuntoMinimapa(px, py, tx, ty, radio, ancho, giraMapa, facing)
	local norte, oeste = tx - px, ty - py
	local sx, sy = -oeste, norte -- pantalla: derecha = este, arriba = norte
	if giraMapa and facing then
		local c, s = cos(facing), sin(facing)
		sx, sy = sx * c + sy * s, -sx * s + sy * c
	end
	local escala = (ancho / 2) / radio
	sx, sy = sx * escala, sy * escala
	local d = sqrt(sx * sx + sy * sy)
	local maximo = ancho / 2 - 6
	if d > maximo then
		return sx / d * maximo, sy / d * maximo, true
	end
	return sx, sy, false
end

-- Radio del minimapa en yardas cuando el juego no lo dice (zoom 0..5, afuera y adentro).
S.RADIO_AFUERA = { [0] = 233.3, 200, 166.7, 133.3, 100, 66.7 }
S.RADIO_ADENTRO = { [0] = 150, 120, 90, 60, 40, 25 }
function S.RadioMinimapa(zoom, adentro, delJuego)
	if type(delJuego) == "number" and delJuego > 0 then return delJuego end
	local t = adentro and S.RADIO_ADENTRO or S.RADIO_AFUERA
	return t[zoom or 0] or t[0]
end
