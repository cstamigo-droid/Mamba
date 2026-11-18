-- Mamba_Profesiones: las cuentas (sin dibujar nada, se prueban fuera del juego).
--   C.Profesiones()        tus profesiones con el camino más barato (SkillUpForever.API, GPL) y su costo
--   C.ListaCompra(linea)   K60: por material, lo que falta y dos opciones con números (comprar / farmear), la
--                          elegida (R0: menor oro + tiempo) y los totales (todo comprado, todo farmeado, mixto)
--   C.Vital(item)          E8: "VITAL: lo necesitas para subir Alquimia (te faltan 6)" o nil
--   C.Fabricar()           F7/O5: qué recetas tuyas dejan ganancia (Tasador.Fabricar) ordenadas por oro
--   C.Lugares(objetivo)    O7: mejor lugar por objetivo para tu nivel, con oro/h ≈ y la siguiente (R0)
-- Todo número estimado lleva "≈" y lo corrige lo medido (C.Medido, Medir.lua). Licencia: GPL-3.0-only.
local _, M = ...
local C = {}
M.C = C

-- Zonas de inicio y de paso del otro bando: no se recomiendan (llegar cuesta y los guardias atacan).
C.ZONA_BANDO = {
	[1429] = "Alliance", [1426] = "Alliance", [1438] = "Alliance", [1436] = "Alliance", [1432] = "Alliance",
	[1439] = "Alliance", [1433] = "Alliance", [1411] = "Horde", [1412] = "Horde", [1420] = "Horde", [1421] = "Horde",
	[1413] = "Horde",
}
-- Modelos (≈, se corrigen con lo medido): criaturas muertas por hora en solitario a tu nivel, y nodos por hora.
C.MATANZAS_HORA = 90
C.NODOS_HORA_MAX = 40
C.UNIDADES_NODO = 2

local function skillUp()
	local S = _G.SkillUpForever
	return S and S.API
end

-- Nivel y bando del personaje, profesiones con su habilidad.
function C.Personaje()
	local p = { nivel = UnitLevel and UnitLevel("player") or 1, bando = UnitFactionGroup and UnitFactionGroup("player"),
		raza = UnitRace and select(2, UnitRace("player")), profs = {} }
	if GetProfessions then
		local t = { GetProfessions() }
		for i = 1, 6 do
			if t[i] and GetProfessionInfo then
				local nombre, _, rango, max = GetProfessionInfo(t[i])
				if nombre then p.profs[nombre] = { rango = rango, max = max } end
			end
		end
	end
	return p
end

local HIERB, MINE, DESU = { "Herboristería", "Herbalism" }, { "Minería", "Mining" }, { "Desuello", "Skinning" }
local function habilidad(p, nombres)
	for _, n in ipairs(nombres) do if p.profs[n] then return p.profs[n].rango end end
end

-- Lo que vale una hora del jugador, en cobre: lo MEDIDO por el Medidor si lo hay; si no ≈ por nivel.
function C.ValorHora(p)
	local api = _G.MambaAPI
	if api and api.OroPorHora then
		local ok, r = pcall(api.OroPorHora)
		if ok and type(r) == "table" and type(r.actual) == "number" and r.actual > 0 then return r.actual, true end
	end
	return math.max(1, p.nivel) * 2500, false
end

function C.Precio(id)
	local api = _G.MambaAPI
	if api and api.PrecioObjeto then
		local ok, pr, de, edad = pcall(api.PrecioObjeto, id)
		if ok and type(pr) == "number" and pr > 0 then return pr, de, edad end
	end
	local T = _G.Tasador
	if T and T.PrecioSubasta then
		local ok, pr = pcall(T.PrecioSubasta, "item:" .. id, id)
		if ok and type(pr) == "number" and pr > 0 then return pr, "subasta" end
	end
end

-- Unidades por hora medidas farmeando ese objeto en ese mapa (al menos 5 minutos medidos).
function C.Medido(id, mapa)
	local m = M.DB().medido[id .. ":" .. tostring(mapa)]
	if m and (m[2] or 0) >= 300 then return m[1] / (m[2] / 3600) end
end

-- Formas de juntar un objeto que este personaje puede usar, con unidades/hora (≈ o medidas).
-- fila de datos: { tipo, mapa, x, y, nombre, nivelMin, nivelMax|habilidad, %, apariciones }
function C.Farmeo(id, p)
	p = p or C.Personaje()
	local out = {}
	for _, f in ipairs((M.FUENTES or {})[id] or {}) do
		local tipo, mapa, x, y, nombre, n1, n2, pct, ap = unpack(f)
		local zb = C.ZONA_BANDO[mapa]
		local sirve = not (zb and p.bando and zb ~= p.bando)
		local rate, porque
		local nodo = tipo == "hierba" or tipo == "veta"
		if sirve and nodo then
			local mia = habilidad(p, tipo == "hierba" and HIERB or MINE)
			-- Cultivo (tauren): recoge hierbas aun sin Herboristería (DatosProfesiones, bono de raza verificado)
			if not mia and tipo == "hierba" and p.raza == "Tauren" then mia = p.nivel * 5 end
			local puede = (mia or -1) >= n1
			if not puede then sirve, porque = false, "pide " .. n1 .. " de habilidad" end
			rate = math.min(C.NODOS_HORA_MAX, ap * 0.4) * pct / 100 * C.UNIDADES_NODO
		elseif sirve then
			if n1 > p.nivel + 3 then sirve, porque = false, "criaturas de nivel " .. n1 .. "-" .. n2 .. ": muy altas" end
			if tipo == "piel" and not habilidad(p, DESU) then sirve, porque = false, "necesita Desuello" end
			local kills = (n2 < p.nivel - 10) and C.MATANZAS_HORA * 1.5 or C.MATANZAS_HORA
			rate = kills * pct / 100
		end
		local medido = C.Medido(id, mapa)
		out[#out + 1] = { tipo = nodo and "nodo" or tipo, clase = tipo, mapa = mapa, x = x, y = y, nombre = nombre, nivel = { n1, n2 }, pct = pct,
			apariciones = ap, porHora = medido or rate, medido = medido ~= nil, sirve = sirve, porque = porque }
	end
	table.sort(out, function(a, b)
		if a.sirve ~= b.sirve then return a.sirve end
		return (a.porHora or 0) > (b.porHora or 0)
	end)
	return out
end

-- Tus profesiones con su camino (SkillUpForever) o nil y el motivo.
local cache, cacheT
function C.Profesiones()
	local api = skillUp()
	if not (api and api.Professions) then return nil, "Falta SkillUp Forever (viene con Mamba): actívalo en la lista de accesorios." end
	local ahora = GetTime and GetTime() or 0
	if cache and cacheT and ahora - cacheT < 5 then return cache end
	local ok, lista, motivo = pcall(api.Professions, { steps = 25, recipes = 25 })
	if not ok then M.Falla("Professions", lista); return nil, "SkillUp Forever dio un error: va al diagnóstico." end
	if not lista then return nil, motivo == "loading" and "Cargando tus profesiones…" or "Sin datos de profesiones aún." end
	cache, cacheT = lista, ahora
	return lista
end
function C.Olvidar() cache = nil end

-- K60: la lista de compra y farmeo de una profesión hasta su tope actual.
function C.ListaCompra(linea)
	local lista, motivo = C.Profesiones()
	if not lista then return nil, motivo end
	local prof
	for _, e in ipairs(lista) do if e.skillLineID == linea or not linea then prof = e; break end end
	if not prof then return nil, "No tienes esa profesión." end
	local p = C.Personaje()
	local valor, valorMedido = C.ValorHora(p)
	local filas = { prof = prof, valorHora = valor, valorMedido = valorMedido }
	local tot = { comprar = 0, sinPrecio = 0, farmMin = 0, sinFarmeo = 0, mixtoOro = 0, mixtoMin = 0 }
	for _, r in ipairs(prof.reagents or {}) do
		local falta = math.max(0, (r.need or 0) - (r.have or 0))
		local f = { id = r.itemID, nombre = M.NombreObjeto(r.itemID), necesita = r.need, tiene = r.have, falta = falta,
			fuente = r.source }
		if falta > 0 then
			local pr, de, edad = C.Precio(r.itemID)
			if pr then f.comprar = { unidad = pr, total = pr * falta, de = de, edad = edad } end
			local formas = C.Farmeo(r.itemID, p)
			local mejor = formas[1]
			if mejor and mejor.sirve and (mejor.porHora or 0) > 0 then
				local min = falta / mejor.porHora * 60
				local viaje = M.MinutosViaje(mejor.mapa, mejor.x, mejor.y)
				f.farmear = { forma = mejor, minutos = min, viaje = viaje, otras = formas }
			end
			if r.source == "vendor" then f.vendedor = true end
			-- R0: se elige por oro + tiempo (el tiempo vale lo que ganas por hora)
			local costoF = f.farmear and (f.farmear.minutos + (f.farmear.viaje or 0)) / 60 * valor
			if f.comprar and (not costoF or f.comprar.total <= costoF) then
				f.elige = "comprar"
			elseif f.farmear then
				f.elige = "farmear"
			end
			f.ahorro = (f.comprar and costoF) and math.abs(f.comprar.total - costoF) or nil
			if f.comprar then tot.comprar = tot.comprar + f.comprar.total else tot.sinPrecio = tot.sinPrecio + 1 end
			if f.farmear then tot.farmMin = tot.farmMin + f.farmear.minutos else tot.sinFarmeo = tot.sinFarmeo + 1 end
			if f.elige == "comprar" then tot.mixtoOro = tot.mixtoOro + f.comprar.total
			elseif f.elige == "farmear" then tot.mixtoMin = tot.mixtoMin + f.farmear.minutos end
		end
		filas[#filas + 1] = f
	end
	-- lo que más ahorra primero (K62)
	table.sort(filas, function(a, b)
		if (a.falta > 0) ~= (b.falta > 0) then return a.falta > 0 end
		return (a.ahorro or 0) > (b.ahorro or 0)
	end)
	filas.total = tot
	return filas
end

-- E8: ¿este material es VITAL para subir una profesión tuya? (te falta y está en el camino)
function C.Vital(id)
	local lista = C.Profesiones()
	if not (lista and id) then return nil end
	for _, e in ipairs(lista) do
		for _, r in ipairs(e.reagents or {}) do
			if r.itemID == id then
				local falta = math.max(0, (r.need or 0) - (r.have or 0))
				if falta > 0 then
					return ("VITAL: lo necesitas para subir %s (%d de %d) · te faltan %d"):format(e.name, e.rank or 0, e.maxRank or 0, falta), falta
				end
				return ("Lo pide %s: ya tienes los %d que hacen falta"):format(e.name, r.need or 0), 0
			end
		end
	end
end

-- F7/O5/K79: recetas que sabes (leídas al abrir tu ventana de profesión) con su ganancia neta.
function C.Fabricar()
	local T = _G.Tasador
	local quien = UnitName and UnitName("player") or "?"
	local mias = M.DB().recetas[quien] or {}
	local a = T and T.db and T.db.ajustes or { comision = 0.05, depositoPct = 0.15, horasPublicacion = 12 }
	a.comision = a.comision or 0.05
	local out, leidas = {}, 0
	for prof, recetas in pairs(mias) do
		for _, r in ipairs(recetas) do
			leidas = leidas + 1
			if r.id and r.reactivos then
				local receta = { producto = r.id, n = r.cantidad or 1, mats = r.reactivos }
				local res
				if T and T.Fabricar then
					local ok, x = pcall(T.Fabricar, receta, function(i) return (C.Precio(i)) end, a,
						function(i) return select(11, GetItemInfo(i)) end)
					if ok then res = x end
				end
				if not res then
					local costo, falta = 0, false
					for _, m in ipairs(receta.mats) do
						local pr = C.Precio(m[1])
						if pr then costo = costo + pr * m[2] else falta = true end
					end
					local pv = C.Precio(r.id)
					if pv and not falta then res = { costo = costo, venta = pv * receta.n * (1 - a.comision) } ; res.ganancia = res.venta - costo end
				end
				if res and res.ganancia then
					out[#out + 1] = { prof = prof, nombre = r.nombre, id = r.id, costo = res.costo, venta = res.venta,
						ganancia = res.ganancia, noSeVende = res.noSeVende, sinLiquidez = res.sinLiquidez }
				end
			end
		end
	end
	table.sort(out, function(x, y) return x.ganancia > y.ganancia end)
	return out, leidas
end

-- O7: los mejores lugares para un objetivo en tu tramo de nivel, ordenados por oro/hora ≈ (R0).
-- objetivo: "tela" | "cuero" | "carne" | "hierbas" | "minerales"
C.OBJETIVOS = {
	{ "tela", "Tela" }, { "cuero", "Cuero" }, { "carne", "Carne" }, { "hierbas", "Hierbas" }, { "minerales", "Minerales" },
}
C.OBJETOS = { -- qué objeto se vende de cada objetivo y tramo (para el oro/h ≈)
	tela = { 2589, 2592, 4306, 4338, 14047, 14047 }, cuero = { 2318, 2319, 4234, 4304, 8170, 8170 },
	carne = { 769, 3173, 3712, 12203, 12205, 12205 }, hierbas = { 2447, 2453, 3357, 3819, 8836, 13465 },
	minerales = { 2770, 2771, 2772, 3858, 10620, 10620 },
}
function C.Lugares(objetivo, p)
	p = p or C.Personaje()
	local tramo = math.max(1, math.min(6, math.floor((p.nivel + 9) / 10)))
	local nodos = objetivo == "hierbas" or objetivo == "minerales"
	if nodos then
		local hab = habilidad(p, objetivo == "hierbas" and HIERB or MINE)
		if not hab and not (objetivo == "hierbas" and p.raza == "Tauren") then
			return {}, objetivo == "hierbas" and "Necesitas Herboristería" or "Necesitas Minería"
		end
		tramo = math.max(1, math.min(6, math.floor((hab or p.nivel * 5) / 50) + 1))
	end
	local out = {}
	for _, f in ipairs(((M.LUGARES or {})[objetivo]) or {}) do
		local t, mapa, x, y, nombre, n1, n2, puntaje = unpack(f)
		local zb = C.ZONA_BANDO[mapa]
		if (t == tramo or t == tramo - 1) and not (zb and p.bando and zb ~= p.bando) and (nodos or n1 <= p.nivel + 3) then
			local item = C.OBJETOS[objetivo][t]
			local porHora
			if nodos then
				porHora = math.min(C.NODOS_HORA_MAX, puntaje * 0.4) * C.UNIDADES_NODO
			else
				porHora = C.MATANZAS_HORA * 0.3 -- ≈ si no hay fila de ese objeto en ese mapa
				for _, g in ipairs(C.Farmeo(item, p)) do
					if g.mapa == mapa and g.porHora then porHora = g.porHora; break end
				end
			end
			local medido = C.Medido(item, mapa)
			if medido then porHora = medido end
			local pr = C.Precio(item)
			if nodos and mapa then
				local cx, cy = M.CentroNodos and M.CentroNodos(objetivo, mapa)
				x, y = cx or x, cy or y
			end
			out[#out + 1] = { mapa = mapa, x = x, y = y, nombre = nombre, nivel = { n1, n2 }, item = item,
				porHora = porHora, oroHora = pr and pr * porHora, medido = medido ~= nil, tramo = t }
		end
	end
	table.sort(out, function(a, b) return (a.oroHora or a.porHora or 0) > (b.oroHora or b.porHora or 0) end)
	return out
end
