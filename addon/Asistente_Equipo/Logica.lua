-- Asistente_Equipo: lógica. EXTIENDE el módulo Gear de Polestar; no lo duplica.
-- Polestar.Gear ya hace (y se usa tal cual): pesos por clase, especialización y nivel, detectar el rol,
-- leer las estadísticas con sus "Equipar:" (su ItemDB), "¿lo puede usar?" y comparar con lo puesto
-- (anillos, abalorios, dos manos, mano izquierda, bolsas). Aquí se suma solo lo que Polestar no tiene:
--   * qué MAZMORRA repetir según tu nivel, ordenadas por ganancia x % de caída, con el tope de 5 por hora;
--   * revisión de TODAS las ranuras puestas (vacías y dudosas);
--   * guías al 60: mejor pieza por ranura con dónde se consigue y en qué orden (JcE), y conjuntos de honor (JcJ).
-- OJO (ARQUITECTURA §4, regla 2): Gear.* es interno de Polestar. Se usa porque este addon es un FORK de Polestar
-- (ARQUITECTURA §13). Las funciones que se llaman están en E.CONTRATO y el vigía polestar_al_dia.py las vigila.
-- Licencia: GPL-3.0-only. Autor: Cristian Amigo.
local _, E = ...
E = E or {}
_G.Asistente_Equipo = E

local pairs, ipairs, type, tonumber = pairs, ipairs, type, tonumber

-- Lo que usamos de Polestar.Gear (si falta algo, el módulo se apaga con un aviso, sin error en rojo).
E.CONTRATO = { "CompareToEquipped", "GetItemInfo", "ScoreWith", "WeightsFor", "GetSpec", "GetPlayer", "GetWeights", "Usability", "CLASSES", "PROFICIENCY" }

-- De Polestar.ItemDB: solo para marcar piezas dudosas y nombrar objetos. Si faltan, el módulo sigue
-- (marca como dudosa toda pieza con "Equipar:") y avisa una vez en el chat.
E.CONTRATO_ITEMDB = { "Get", "ItemName" }

function E.FaltaItemDB()
	local P = _G.Polestar
	local DB = type(P) == "table" and P.ItemDB
	if type(DB) ~= "table" then return "ItemDB" end
	for _, f in ipairs(E.CONTRATO_ITEMDB) do
		if DB[f] == nil then return "ItemDB." .. f end
	end
	return nil
end

function E.Gear()
	local P = _G.Polestar
	local G = type(P) == "table" and P.Gear
	if type(G) ~= "table" then return nil, "sin_polestar" end
	for _, f in ipairs(E.CONTRATO) do
		if G[f] == nil then return nil, f end
	end
	return G
end

---------------------------------------------------------------- nombres
E.RANURA_NOMBRE = {
	[1] = "Cabeza", [2] = "Cuello", [3] = "Hombros", [5] = "Pecho", [6] = "Cintura", [7] = "Piernas",
	[8] = "Pies", [9] = "Muñecas", [10] = "Manos", [11] = "Anillo 1", [12] = "Anillo 2",
	[13] = "Abalorio 1", [14] = "Abalorio 2", [15] = "Espalda", [16] = "Mano derecha",
	[17] = "Mano izquierda", [18] = "A distancia o reliquia",
}
E.RANURAS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local IZQ_INV = { [14] = true, [22] = true, [23] = true }

-- Claves de especialización de Polestar -> nombre en español.
E.NOMBRE_ROL = {
	balance = "Equilibrio", feral = "Feral", restoration = "Restauración", holy = "Sagrado",
	protection = "Protección", retribution = "Reprensión", discipline = "Disciplina", shadow = "Sombra",
	elemental = "Elemental", enhancement = "Mejora", arms = "Armas", fury = "Furia",
	assassination = "Asesinato", combat = "Combate", subtlety = "Sutileza", beastmastery = "Bestias",
	marksmanship = "Puntería", survival = "Supervivencia", arcane = "Arcano", fire = "Fuego",
	frost = "Escarcha", affliction = "Aflicción", demonology = "Demonología", destruction = "Destrucción",
}

function E.NombreRol(rol, etiqueta)
	if type(rol) == "string" and rol:find("^custom:") then return etiqueta or "escala propia" end
	return E.NOMBRE_ROL[rol] or etiqueta or tostring(rol)
end

-- Roles de una clase en el orden de Polestar: { {clave, nombre}, ... }
function E.Roles(G, clase)
	local out = {}
	local c = G.CLASSES[clase]
	for _, s in ipairs(c and c.specs or {}) do out[#out + 1] = { clave = s.key, nombre = E.NombreRol(s.key, s.label) } end
	return out
end

-- ¿La pieza aporta algo de verdad a este rol (no solo armadura o el DPS que Polestar usa para desempatar)?
function E.Aporta(stats, w)
	for k, v in pairs(stats or {}) do
		if type(v) == "number" and v > 0 then
			if k == "dps" or k == "rdps" then
				if (w[k] or 0) >= 1 then return true end
			elseif (k ~= "armor" or (w[k] or 0) >= 0.03) and (w[k] or 0) > 0 then -- la armadura solo cuenta para quien la pesa (tanques)
				return true
			end
		end
	end
	return false
end

---------------------------------------------------------------- revisión de lo puesto
-- puestos[ranura] = link. sabeEquipar(link, id) -> false si tiene un "Equipar:" que nadie pudo medir.
-- Devuelve { ranuras = { {ranura, puntaje, vacia, sabe, link} }, vacias, desconocidas, total }.
function E.Revisar(G, puestos, sabeEquipar)
	local w = G.GetWeights()
	local out = { ranuras = {}, total = 0, desconocidas = 0, vacias = 0 }
	if not w then return out end
	local dosManos = false
	for _, r in ipairs(E.RANURAS) do
		local link = puestos[r]
		local fila = { ranura = r, link = link, vacia = not link, sabe = true, puntaje = 0 }
		if link then
			local info = G.GetItemInfo(link)
			if info then
				fila.puntaje = G.ScoreWith(info, w, r == 17)
				if r == 16 and info.inv == 17 then dosManos = true end
				if sabeEquipar and sabeEquipar(link, info.id) == false then fila.sabe = false end
			else
				fila.sabe = false
			end
		end
		if r == 17 and fila.vacia and dosManos then fila.vacia, fila.dosManos = false, true end
		if fila.vacia and r ~= 18 then out.vacias = out.vacias + 1 end
		if not fila.sabe then out.desconocidas = out.desconocidas + 1 end
		out.total = out.total + fila.puntaje
		out.ranuras[#out.ranuras + 1] = fila
	end
	return out
end

---------------------------------------------------------------- mazmorras
-- Una mazmorra "te sirve" desde 2 niveles antes de su mínimo hasta su máximo.
E.HOLGURA = 2
E.RESETEOS_POR_HORA = 5 -- Warcraft Tavern: "Resets are capped at five per hour" (leída el 16-11-2026)
E.GANANCIA_MINIMA = 0.5

function E.MazmorrasParaNivel(nivel, lado)
	local out = {}
	for _, m in ipairs(E.MAZMORRAS or {}) do
		if m.min <= nivel + E.HOLGURA and m.max >= nivel and not (m.lado and lado and m.lado ~= lado) then
			out[#out + 1] = m
		end
	end
	return out
end

-- Pasadas promedio para que caiga (100 / %) y horas mínimas por el tope de entradas por hora.
function E.Pasadas(pct)
	if not pct or pct <= 0 then return nil end
	local n = 100 / pct
	return n, n / E.RESETEOS_POR_HORA
end

-- side de los datos: 1 Alianza, 2 Horda, nil ambas
local function LadoOk(fLado, lado)
	return not (fLado and lado and ((fLado == 1 and lado ~= "A") or (fLado == 2 and lado ~= "H")))
end

-- Lo que cada mazmorra de tu rango te mejora, comparado con lo puesto POR POLESTAR (Gear.CompareToEquipped).
-- -> con = { { m, valor, piezas = { {id, nombre, jefe, pct, ganancia, pctMejora, ranura, vacia, nivelMin, mision} } } }
--    (ordenadas por valor = suma, por ranura, de la mejor ganancia x % de caída), sin = mazmorras sin datos.
-- Una misión se hace una vez: su recompensa se muestra, pero NO suma al valor de "qué mazmorra repetir".
-- Tampoco suma el botín de "bichos": su % es por bicho, no por pasada (NO VERIFICADO), así que no se puede
-- convertir en pasadas. misionHecha(q) -> true si ya la completaste (la da el juego).
local function TieneBit(mask, b)
	return math.floor(mask / b) % 2 == 1
end

-- Lo que UNA mazmorra te mejora: { m, valor, piezas } o nil si no hay datos abiertos de su botín.
-- nivelTope: hasta qué nivel de objeto se muestran piezas (por defecto tu nivel + la holgura; en la ficha de
-- una mazmorra que todavía no es de tu nivel, 60, y cada pieza dice su nivel).
function E.MejorasDe(G, m, nivel, lado, misionHecha, nivelTope)
	local filas = E.BOTIN and E.BOTIN[m.clave]
	if not filas then return nil end
	local w = G.GetWeights()
	if not w then return nil end
	local p = G.GetPlayer()
	local bit = p and p.class and G.CLASSES[p.class] and G.CLASSES[p.class].bit
	nivelTope = nivelTope or (nivel + E.HOLGURA)
	local mejor, piezas, vistos = {}, {}, {}
	for _, f in ipairs(filas) do
		local claseOk = not (f.rc and bit and not TieneBit(f.rc, bit))
		local hecha = f.mision and misionHecha and misionHecha(f.mision)
		if LadoOk(f.lado, lado) and claseOk and not hecha and not vistos[f.id] then
			local r = G.CompareToEquipped("item:" .. f.id)
			local info = r and r.usable and G.GetItemInfo("item:" .. f.id)
			if info and not r.equipped and r.delta and r.delta > E.GANANCIA_MINIMA
				and (r.minLevel or 0) <= nivelTope and E.Aporta(info.stats, w) then
				vistos[f.id] = true
				piezas[#piezas + 1] = { id = f.id, nombre = f.n, jefe = f.jefe, pct = f.pct, mision = f.mision, bichos = f.bichos,
					ganancia = r.delta, pctMejora = r.pct, ranura = r.slot, vacia = r.empty, nivelMin = r.minLevel }
				if not f.mision and not f.bichos and (r.minLevel or 0) <= nivel + E.HOLGURA then
					local esperado = r.delta * (f.pct or 0) / 100
					if not mejor[r.slot] or esperado > mejor[r.slot] then mejor[r.slot] = esperado end
				end
			end
		end
	end
	local valor = 0
	for _, x in pairs(mejor) do valor = valor + x end
	-- Primero lo que se repite (jefes), por ganancia x %; después misiones y bichos.
	local function peso(x) return (x.mision or x.bichos) and 0 or x.ganancia * (x.pct or 0) end
	table.sort(piezas, function(a, b)
		local ea, eb = peso(a), peso(b)
		if ea == eb then ea, eb = a.ganancia, b.ganancia end
		if ea ~= eb then return ea > eb end
		return a.id < b.id
	end)
	return { m = m, valor = valor, piezas = piezas }
end

function E.MejorasMazmorras(G, nivel, lado, misionHecha)
	if not G.GetWeights() then return {}, {} end
	local con, sin = {}, {}
	for _, m in ipairs(E.MazmorrasParaNivel(nivel, lado)) do
		local x = E.MejorasDe(G, m, nivel, lado, misionHecha)
		if x then con[#con + 1] = x else sin[#sin + 1] = m end
	end
	table.sort(con, function(a, b)
		if a.valor ~= b.valor then return a.valor > b.valor end
		return a.m.min < b.m.min
	end)
	return con, sin
end

-- Jefes de una mazmorra, en el orden de los datos (sin los "bichos").
function E.JefesDe(clave)
	local out, visto = {}, {}
	for _, f in ipairs(E.BOTIN and E.BOTIN[clave] or {}) do
		if not f.mision and f.jefe and f.jefe ~= "" and not visto[f.jefe] then
			visto[f.jefe] = true
			out[#out + 1] = f.jefe
		end
	end
	return out
end

function E.Mazmorra(clave)
	for _, m in ipairs(E.MAZMORRAS or {}) do
		if m.clave == clave then return m end
	end
end

-- La mazmorra en la base de mazmorras de Polestar (que tiene su entrada): clave nuestra -> clave de Polestar.
-- Las nuevas de Forever sin entrada en esa base quedan fuera (la ficha lo dice).
E.CLAVE_POLESTAR = {
	rfc = "ragefire-chasm", thanes = "the-hall-of-thanes", lordaeron = "ruins-of-lordaeron", wc = "wailing-caverns",
	vc = "deadmines", sfk = "shadowfang-keep", bfd = "blackfathom-deeps", stocks = "stormwind-stockade",
	excavacion = "excavation-site-wetlands", dalaran = "city-of-dalaran", rfk = "razorfen-kraul", gnomer = "gnomeregan",
	smcem = "scarlet-monastery", smbib = "scarlet-monastery", smarm = "scarlet-monastery", smcat = "scarlet-monastery",
	rfd = "razorfen-downs", ulda = "uldaman", zf = "zulfarrak", mara = "maraudon", st = "sunken-temple",
	brd = "blackrock-depths", dme = "dire-maul", dmw = "dire-maul", dmn = "dire-maul", lbrs = "blackrock-spire",
	ubrs = "blackrock-spire", stratv = "stratholme", stratm = "stratholme", scholo = "scholomance",
}

---------------------------------------------------------------- guía al 60 (JcE)
-- Mejor pieza por ranura al 60 entre lo que tiene fuente en los datos, con los pesos de Polestar para tu rol
-- AL 60. PROVISIONAL: sin bandas (abren el 9-12-2026) y con datos de la beta.
-- La pieza PRINCIPAL siempre se puede conseguir (misión o botín). Lo fabricado solo sale como alternativa
-- ("fabricado"): algunas recetas pueden pedir materiales de banda (NO VERIFICADO receta por receta).
-- Si la principal no sale de una mazmorra, se agrega la mejor que sí sale ("mazmorra").
local ORDEN_RANURA = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 13, 16, 17, 18 }

-- 100 = misión; botín = su %; 0 = solo fabricado (o nada de tu facción).
local function Certeza(fuentes, lado)
	local mejor = 0
	for _, f in ipairs(fuentes) do
		if LadoOk(f.lado, lado) then
			-- Bichos: su % es por bicho (NO VERIFICADO), no se compara con el de un jefe; van detrás de cualquier jefe.
			local c = (f.tipo == "mision" and 100) or (f.tipo == "botin" and f.jefe ~= "" and (f.pct or 0))
				or (f.tipo == "botin" and (f.pct or 0) / 100) or 0
			if c > mejor then mejor = c end
		end
	end
	return mejor
end

local function Fabricable(fuentes)
	for _, f in ipairs(fuentes) do
		if f.tipo == "profesion" then return true end
	end
	return false
end

-- Fuentes que valen para tu facción, en orden: misión, jefe, bichos, fabricado.
function E.FuentesPara(fuentes, lado)
	local out = {}
	local function orden(f)
		return (f.tipo == "mision" and 1) or (f.tipo == "botin" and f.jefe ~= "" and 2) or (f.tipo == "botin" and 3) or 4
	end
	for _, f in ipairs(fuentes or {}) do
		if LadoOk(f.lado, lado) then out[#out + 1] = f end
	end
	table.sort(out, function(a, b)
		if orden(a) ~= orden(b) then return orden(a) < orden(b) end
		return (a.pct or 0) > (b.pct or 0)
	end)
	return out
end

local function EsDeMazmorra(x)
	for _, f in ipairs(x.fuentes) do
		if f.tipo == "botin" and (f.pct or 0) > 0 then return true end
	end
	return false
end

function E.BiS60(G, clase, rol, lado)
	local w = G.WeightsFor(clase, rol, 60)
	if not w then return {}, {} end
	local porTipo, fabricados = {}, {}
	local prof = G.PROFICIENCY and G.PROFICIENCY[clase]
	local dosArmas = prof and prof.dualWield ~= nil -- la clase aprende a usar dos armas (al 60 ya lo sabe)
	local ids = {}
	for id in pairs(E.ORIGEN60 or {}) do ids[#ids + 1] = id end
	table.sort(ids)
	local function meter(tabla, clave, x)
		tabla[clave] = tabla[clave] or {}
		table.insert(tabla[clave], x)
	end
	for _, id in ipairs(ids) do
		local fuentes = E.FuentesPara(E.ORIGEN60[id], lado)
		local certeza = Certeza(fuentes, lado)
		local info = #fuentes > 0 and G.GetItemInfo("item:" .. id)
		if info and (info.req or 0) <= 60 and E.Aporta(info.stats, w) then
			local ok, motivo = G.Usability(info)
			if ok or motivo == "dualwield" or motivo == "skill" then -- al 60 ya se aprende
				local i = info.inv
				local clave = (i == 17 and "2m") or ((i == 13 or i == 21) and "derecha") or (IZQ_INV[i] and "izquierda")
					or (i == 11 and "anillo") or (i == 12 and "abalorio") or ({ [20] = 5, [25] = 18, [26] = 18, [15] = 18, [28] = 18, [16] = 15 })[i] or i
				local destino = (certeza > 0 and porTipo) or (Fabricable(fuentes) and fabricados) or nil
				if destino then
					meter(destino, clave, { id = id, s = G.ScoreWith(info, w, IZQ_INV[i] and true or false), fuentes = fuentes, certeza = certeza })
					-- Un arma de una mano también puede ir en la izquierda si la clase usa dos armas (como Polestar, Gear.lua).
					if i == 13 and dosArmas then
						meter(destino, "izquierda", { id = id, s = G.ScoreWith(info, w, true), fuentes = fuentes, certeza = certeza })
					end
				end
			end
		end
	end
	for _, t in ipairs({ porTipo, fabricados }) do
		for _, l in pairs(t) do
			table.sort(l, function(a, b) if a.s ~= b.s then return a.s > b.s end return a.id < b.id end)
		end
	end
	local filas = {}
	local function poner(ranura, x, alt)
		if x then filas[#filas + 1] = { ranura = ranura, id = x.id, puntaje = x.s, fuentes = x.fuentes, certeza = x.certeza, alternativa = alt } end
	end
	-- Alternativas de una ranura: la mejor de mazmorra (si la principal no lo es) y la mejor fabricada (si supera a la principal).
	local function alternativas(ranura, clave, principal, saltar)
		saltar = saltar or {}
		if principal and not EsDeMazmorra(principal) then
			for _, x in ipairs(porTipo[clave] or {}) do
				if x.id ~= principal.id and not saltar[x.id] and EsDeMazmorra(x) then
					poner(ranura, x, "mazmorra")
					saltar[x.id] = true
					break
				end
			end
		end
		for _, x in ipairs(fabricados[clave] or {}) do
			if not saltar[x.id] then
				if not principal or x.s > principal.s then
					poner(ranura, x, "fabricado")
					saltar[x.id] = true
				end
				break
			end
		end
	end
	for _, r in ipairs(ORDEN_RANURA) do
		if r == 11 or r == 13 then
			local clave = r == 11 and "anillo" or "abalorio"
			local ya, puestos = {}, {}
			for _, x in ipairs(porTipo[clave] or {}) do
				if #puestos < 2 then
					poner(r + #puestos, x)
					puestos[#puestos + 1] = x
					ya[x.id] = true
				end
			end
			for i = 1, 2 do alternativas(r + i - 1, clave, puestos[i], ya) end
		elseif r == 16 then
			local dos = (porTipo["2m"] or {})[1]
			local der = (porTipo["derecha"] or {})[1]
			local izq
			for _, x in ipairs(porTipo["izquierda"] or {}) do -- la misma arma no va en las dos manos
				if not (der and x.id == der.id) then izq = x break end
			end
			local sumaUna = (der and der.s or 0) + (izq and izq.s or 0)
			-- Las alternativas de las dos manos comparten la lista de "ya usadas": la misma arma no va en las dos.
			local armas = { [der and der.id or 0] = true, [izq and izq.id or 0] = true }
			if dos and dos.s >= sumaUna then
				poner(16, dos)
				alternativas(16, "2m", dos, armas)
				if der then poner(16, der, true) end
				if izq then poner(17, izq, true) end
			else
				poner(16, der)
				alternativas(16, "derecha", der, armas)
				poner(17, izq)
				if izq or dosArmas or (porTipo["izquierda"] or fabricados["izquierda"]) then
					alternativas(17, "izquierda", izq, armas)
				end
				if dos then poner(16, dos, true) end
			end
		elseif r ~= 17 then
			local l = porTipo[r] or {}
			poner(r, l[1])
			alternativas(r, r, l[1])
		end
	end
	-- Ranuras sin ninguna pieza que se pueda conseguir (se le dice al jugador).
	local hay, faltan = {}, {}
	local dosManos = false
	for _, f in ipairs(filas) do
		if not f.alternativa then
			hay[f.ranura] = true
			if f.ranura == 16 then
				local info = G.GetItemInfo("item:" .. f.id)
				dosManos = info and info.inv == 17
			end
		end
	end
	for _, r in ipairs(E.RANURAS) do
		if not hay[r] and not (r == 17 and dosManos) then faltan[#faltan + 1] = r end
	end
	return filas, faltan
end

-- Alternativas de una ranura ("mazmorra" y "fabricado"), para mostrarlas junto a la principal.
function E.AlternativasDe(filas, ranura)
	local out = {}
	for _, f in ipairs(filas) do
		if f.ranura == ranura and (f.alternativa == "mazmorra" or f.alternativa == "fabricado") then out[#out + 1] = f end
	end
	return out
end

-- Orden para juntarlas: primero lo seguro (misiones), después lo que más cae en mazmorras.
function E.OrdenBiS(filas)
	local l = {}
	for _, f in ipairs(filas) do
		if not f.alternativa then l[#l + 1] = f end
	end
	table.sort(l, function(a, b)
		if a.certeza ~= b.certeza then return a.certeza > b.certeza end
		return a.id < b.id
	end)
	return l
end

---------------------------------------------------------------- guía al 60 (JcJ)
-- Blizzard, "How PvP Progression in World of Warcraft: Forever Works" (7-10-2026):
-- https://worldofwarcraft.blizzard.com/en-us/news/24303316
E.RANGOS_JCJ = {
	{ 1, "Tabardo" }, { 2, "Abalorio JcJ" }, { 3, "Capas" }, { 4, "Collar" }, { 5, "Pociones de combate" },
	{ 6, "Tabardo" }, { 7, "Estandarte de batalla" }, { 8, "Ficha épica de muñecas o cintura" },
	{ 9, "Ficha épica de pies" }, { 10, "Ficha épica de manos" }, { 11, "Monturas" },
	{ 12, "Ficha épica de piernas u hombros" }, { 13, "Ficha épica de pecho o cabeza" }, { 14, "Armas épicas" },
}

function E.JcJ(clase, rol, lado)
	local c = E.JCJ and E.JCJ[clase] and E.JCJ[clase][rol]
	return c and c[lado or "H"] or nil
end
