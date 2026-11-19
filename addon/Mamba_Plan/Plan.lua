-- Mamba_Plan: el plan. Con el estado del personaje (Estado.lua), sus respuestas (Inicio.lua) y los datos
-- (DatosPlan.lua, del juego y de ForeverTDB) arma:
--   M.Metas(e, r)  -> metas de dinero en el orden en que llegan: entrenar, montura, rango de profesión, bolsa
--   M.Pasos(e, r)  -> lo que conviene hacer AHORA, ya filtrado por lo que este personaje tiene
--   M.Bolsas(e)    -> plan de bolsas: la próxima mejora y de dónde sale
--   M.ProfesionesRecomendadas(e, r) -> profesiones con su porqué, su costo y su fuente
-- Nada se inventa: lo que no está en los datos no sale. Lo que es estimación lo dice.
-- Licencia: GPL-3.0-only.
local _, M = ...

M.USO_DE_ESTILO = { jce = "mazmorra", jcj = "jcj", oro = "oro" }
M.NOMBRE_RANGO = { "Aprendiz", "Oficial", "Experto", "Artesano" }
local RAZA_MONTURA = { Tauren = "Kodo", Orc = "lobo", Troll = "Raptor", Scourge = "esquel", Undead = "esquel" }

---------------------------------------------------------------- lugares
-- { zona, x, y } de un PNJ de la lista, del bando del jugador; el más cercano si Polestar sabe medir.
function M.LugarDe(lista, bando)
	local lado = (bando == "Alliance") and "A" or "H"
	local mejor
	for _, npc in ipairs(lista or {}) do
		local l = M.LUGAR and M.LUGAR[npc]
		if l and l[1]:find(lado, 1, true) then
			local zona
			if C_Map and C_Map.GetMapInfo then
				local ok, info = pcall(C_Map.GetMapInfo, l[2])
				zona = ok and info and info.name
			end
			local cand = { npc = npc, mapa = l[2], x = l[3], y = l[4], zona = zona or ("mapa " .. l[2]) }
			if not mejor then mejor = cand end
			-- preferir el que está en el mapa del jugador
			local aqui = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
			if aqui and aqui == l[2] then return cand end
		end
	end
	return mejor
end

---------------------------------------------------------------- metas de dinero
local function sumaEntrenar(clase, desde, hasta)
	local t, s = M.ENTRENAR and M.ENTRENAR[clase], 0
	if not t then return 0 end
	for n, c in pairs(t) do if n > desde and n <= hasta then s = s + c end end
	return s
end

function M.MonturaDeRaza(raza, nivel)
	local clave = RAZA_MONTURA[raza]
	local mejor
	for id, m in pairs(M.MONTURAS or {}) do
		if m.nivel == nivel and (not clave or m.nombre:find(clave)) then
			if not mejor or m.precio < mejor.precio or (m.precio == mejor.precio and id < mejor.id) then
				mejor = { id = id, nombre = m.nombre, precio = m.precio, quien = m.quien, forever = m.forever }
			end
		end
	end
	return mejor
end

function M.Metas(e)
	local metas = {}
	-- 1) el próximo entrenamiento (niveles pares)
	local prox = e.nivel + (e.nivel % 2 == 0 and 2 or 1)
	if prox <= 60 then
		local c = sumaEntrenar(e.clase, e.nivel, prox)
		if c > 0 then
			metas[#metas + 1] = { clave = "entrenar" .. prox, nivel = prox, costo = c,
				titulo = "Hechizos del nivel " .. prox, detalle = "En tu instructor de clase. Máximo: incluye rangos que piden talento.",
				confianza = "dato del juego" }
		end
	end
	-- 2) la montura
	for _, n in ipairs({ 40, 60 }) do
		local hechizo = n == 40 and 33388 or 33391
		local eq = M.EQUITACION and M.EQUITACION[hechizo]
		if eq and e.nivel < n + 5 and not M.Conoce(hechizo) and (n == 40 or e.nivel >= 50) then
			local mont = M.MonturaDeRaza(e.raza, n)
			local costo = eq[2] + (mont and mont.precio or 0)
			-- lo que hay que entrenar antes de esa montura también se paga antes
			local antes = sumaEntrenar(e.clase, e.nivel, n)
			local lugar = mont and M.LugarDe(mont.quien, e.bando)
			local lugarI = M.LugarDe(M.INSTRUCTORES_EQUITACION, e.bando)
			metas[#metas + 1] = { clave = "montura" .. n, nivel = n, costo = costo + antes,
				titulo = (n == 40 and "Montura al 40" or "Montura rápida al 60"),
				detalle = ("Equitación %s%s%s · más los hechizos hasta el %d (%s)"):format(M.Dinero(eq[2]),
					mont and (" + " .. mont.nombre .. " " .. M.Dinero(mont.precio)) or "",
					lugar and (" en " .. lugar.zona) or (lugarI and (" en " .. lugarI.zona) or ""), n, M.Dinero(antes)),
				lugar = lugar or lugarI, confianza = "dato del juego" }
		end
	end
	-- 3) el próximo rango de tus profesiones
	for _, p in ipairs(e.profesiones) do
		local r = M.RANGOS and M.RANGOS[p.nombre]
		if r then
			for i, rg in ipairs(r) do
				if rg.tope > p.max and i > 1 then
					if rg.instructor then
						metas[#metas + 1] = { clave = "rango" .. p.nombre .. rg.tope, nivel = rg.nivel, costo = rg.costo,
							titulo = M.NOMBRE_RANGO[i] .. " en " .. p.nombre .. " (tope " .. rg.tope .. ")",
							detalle = ("Pide habilidad %d y nivel %d."):format(r[i - 1].tope - 25, rg.nivel),
							lugar = M.LugarDe(rg.quien, e.bando), confianza = "dato del juego" }
					end
					break
				end
			end
		end
	end
	table.sort(metas, function(a, b) if a.nivel ~= b.nivel then return a.nivel < b.nivel end return a.costo < b.costo end)
	-- acumulado: cuánto falta para cada meta si se pagan en orden
	local acum = 0
	for _, m in ipairs(metas) do
		acum = acum + m.costo
		m.acumulado = acum
		m.falta = math.max(0, acum - e.oro)
	end
	return metas
end

-- ¿Comprar esto (cobre) retrasa la montura? -> true, cuánto faltaría
function M.RetrasaMontura(e, costo)
	for _, m in ipairs(M.Metas(e)) do
		if m.clave:find("^montura") then
			local antes = math.max(0, m.acumulado - e.oro)
			local despues = math.max(0, m.acumulado - (e.oro - costo))
			return despues > antes, despues
		end
	end
	return false
end

---------------------------------------------------------------- bolsas
local FAMILIA_CLASE = { carcaj = "HUNTER", canana = "HUNTER", almas = "WARLOCK" }

function M.CasillasMasChica(e)
	local menor, cual = nil, nil
	for b = 1, 4 do
		local r = e.bolsas.ranuras[b]
		local n = r and r.item and r.casillas or 0
		if not menor or n < menor then menor, cual = n, b end
	end
	return menor or 0, cual
end

-- Plan de bolsas: la mejor bolsa común que el jugador puede conseguir a su nivel, comparada con la más chica
-- que tiene (una ranura vacía cuenta como bolsa de 0). Más las especiales de su clase o profesión.
-- K119 (Cristian, 19-11): nunca una bolsa sin fuente real. Primero las que dan las MISIONES (su meta), después las
-- que se FABRICAN (quién las hace y con qué) y al final las que se COMPRAN; cada una con su lugar para "Llévame".
-- Cada fuente se filtra por el bando del jugador (misión de la Horda, vendedor de la Horda).
local LADO = { Horde = 2, Alliance = 1 }

local function misionHecha(q)
	local Q = C_QuestLog
	if Q and Q.IsQuestFlaggedCompleted then
		local ok, r = pcall(Q.IsQuestFlaggedCompleted, q)
		if ok then return r == true end
	end
	return false
end

-- Las fuentes de una bolsa que ESTE personaje puede usar: { tipo = "mision"|"fabrica"|"vendedor", texto, lugar, prio }
function M.FuentesBolsa(e, b)
	local out = {}
	local lado = LADO[e.bando] or 2
	for _, m in ipairs(b.misiones or {}) do
		local delLado = (m.lado == 0 or m.lado == 3 or m.lado == lado)
		if type(m) == "table" and delLado and not misionHecha(m.id) and (m.min or 0) <= e.nivel + 2 then
			local lugar = M.LugarDe(m.da, e.bando)
			out[#out + 1] = { tipo = "mision", prio = 1, lugar = lugar,
				texto = ("Misión «%s» (nivel %d)%s"):format(m.titulo ~= "" and m.titulo or ("#" .. m.id), m.nivel or 0,
					lugar and (" · la da alguien en " .. lugar.zona) or "") }
		end
	end
	if b.fabrica then
		local prof, hab = b.fabrica[1], b.fabrica[2]
		local mia = M.Profesion(e, prof)
		local mats = {}
		for _, r in ipairs(b.reactivos or {}) do mats[#mats + 1] = r[2] .. " " .. (r[3] ~= "" and r[3] or ("objeto " .. r[1])) end
		local quien = mia and ((mia.rango >= hab) and "la puedes hacer tú" or ("tú, con " .. prof .. " " .. hab .. " (tienes " .. mia.rango .. ")"))
			or ("un " .. prof:lower() .. " de " .. hab .. " o más (pídesela a un compañero o en el chat de comercio)")
		local donde = b.aprende == "instructor" and "la enseña el instructor" or (b.aprende ~= "" and b.aprende or "")
		local lugar
		local rg = M.RANGOS and M.RANGOS[prof]
		if mia and rg then
			for _, x in ipairs(rg) do if x.tope >= hab and x.instructor then lugar = M.LugarDe(x.quien, e.bando); break end end
		end
		out[#out + 1] = { tipo = "fabrica", prio = 2, lugar = lugar, materiales = mats,
			texto = ("Se fabrica con %s %d: %s%s. Materiales: %s"):format(prof, hab, quien, donde ~= "" and (" · " .. donde) or "",
				#mats > 0 and table.concat(mats, ", ") or "sin dato") }
	end
	if b.vendedores then
		local lugar = M.LugarDe(b.quienVende, e.bando)
		if lugar then -- solo si hay un vendedor de tu bando
			out[#out + 1] = { tipo = "vendedor", prio = 3, lugar = lugar,
				texto = ("La vende un vendedor en %s por %s"):format(lugar.zona, M.Dinero(b.precio)) }
		end
	end
	table.sort(out, function(x, y) return x.prio < y.prio end)
	return out
end

function M.Bolsas(e)
	local menor = M.CasillasMasChica(e)
	local tieneHierbas = M.Profesion(e, "Herboristería") ~= nil
	local opciones = {}
	for id, b in pairs(M.BOLSAS or {}) do
		local especial = b.familia ~= "bolsa"
		local paraMi = not especial or FAMILIA_CLASE[b.familia] == e.clase or (b.familia == "hierbas" and tieneHierbas)
		if paraMi and b.nivel <= e.nivel then
			local fuentes = M.FuentesBolsa(e, b)
			local precio, dias = M.Fuentes.Precio(id)
			if #fuentes > 0 or precio then
				local formas = {}
				for _, f in ipairs(fuentes) do formas[#formas + 1] = f.texto end
				if precio then formas[#formas + 1] = "en tu subasta: " .. M.Dinero(precio) end
				opciones[#opciones + 1] = { id = id, nombre = b.nombre, casillas = b.casillas, familia = b.familia,
					precio = precio or (b.vendedores and b.precio) or nil, precioDias = dias, formas = formas, fuentes = fuentes,
					prio = fuentes[1] and fuentes[1].prio or 4, lugar = fuentes[1] and fuentes[1].lugar,
					mejora = (not especial) and (b.casillas - menor) or nil }
			end
		end
	end
	table.sort(opciones, function(a, b)
		if (a.familia == "bolsa") ~= (b.familia == "bolsa") then return a.familia == "bolsa" end
		if a.prio ~= b.prio then return a.prio < b.prio end
		if a.casillas ~= b.casillas then return a.casillas > b.casillas end
		return (a.precio or math.huge) < (b.precio or math.huge)
	end)
	-- la recomendada: la que mejora, con fuente para ti, en el orden misión > fabricar > comprar; una que se compra
	-- no se recomienda si retrasa la montura. La subasta sola (sin fuente) nunca se recomienda.
	local rec
	for _, o in ipairs(opciones) do
		if o.familia == "bolsa" and (o.mejora or 0) > 0 and #o.fuentes > 0 then
			local compra = o.prio == 3
			if not (compra and o.precio and M.RetrasaMontura(e, o.precio)) then rec = o; break end
		end
	end
	return { opciones = opciones, recomendada = rec, menor = menor, vacias = e.bolsas.vacias }
end

---------------------------------------------------------------- profesiones recomendadas (A2)
local PRIMARIAS = { ["Alquimia"] = true, ["Herrería"] = true, ["Encantamiento"] = true, ["Ingeniería"] = true,
	["Herboristería"] = true, ["Peletería"] = true, ["Minería"] = true, ["Desuello"] = true, ["Sastrería"] = true }
M.PRIMARIAS = PRIMARIAS

function M.ProfesionesRecomendadas(e, r)
	local P = M.PROFESIONES
	if not P then return {} end
	local fuentes = M.FUENTES_PROF or {}
	local usos = {}
	if e.nivel < 60 then usos[#usos + 1] = "subir" end
	-- todas las que eligió, la principal primero (Cristian, 18-11: "juego para mazmorrear, jcj y oro")
	local elegidos = {}
	for k, prio in pairs(r and r.estilos or {}) do elegidos[#elegidos + 1] = { k, prio } end
	table.sort(elegidos, function(x, y) if x[2] ~= y[2] then return x[2] < y[2] end return x[1] < y[1] end)
	if #elegidos == 0 then elegidos[1] = { r and r.estilo or "jce", 1 } end
	for _, x in ipairs(elegidos) do usos[#usos + 1] = M.USO_DE_ESTILO[x[1]] or "mazmorra" end
	local out, visto = {}, {}
	local function agregar(par, porque, fts, uso)
		local clave = table.concat(par, " + ")
		if visto[clave] then return end
		visto[clave] = true
		local nombres = {}
		for _, f in ipairs(fts or {}) do if fuentes[f] then nombres[#nombres + 1] = fuentes[f][1] .. " (" .. fuentes[f][3] .. ")" end end
		local tiene = 0
		for _, p in ipairs(par) do if M.Profesion(e, p) then tiene = tiene + 1 end end
		out[#out + 1] = { par = par, porque = porque, fuentes = nombres, uso = uso, tiene = tiene }
	end
	for _, uso in ipairs(usos) do
		local par, porque, fts = M.Clase.Profesiones(e.clase, uso, r and r.spec)
		if par then agregar(par, porque, fts, uso) end
	end
	local bono = M.Clase.BonoRaza and M.Clase.BonoRaza(e.raza)
	for _, x in ipairs(out) do
		for _, p in ipairs(x.par) do
			if bono and bono.sugiere == p then x.raza = bono.bono; x.razaVerificada = bono.verificado end
		end
	end
	-- lo que ya tienes también entra, aunque no lo recomiende ninguna fuente
	local mias = {}
	for _, p in ipairs(e.profesiones) do if PRIMARIAS[p.nombre] then mias[#mias + 1] = p.nombre end end
	if #mias > 0 then agregar(mias, "Las que ya tienes: seguir con ellas no cuesta empezar de cero.", {}, "ya") end
	return out
end

-- Lo que cuesta llegar al tope de una profesión desde donde estás: rangos que faltan (dato) y horas (no hay
-- dato medido: no se inventa).
function M.CostoProfesion(e, nombre)
	local r = M.RANGOS and M.RANGOS[nombre]
	if not r then return nil end
	local p = M.Profesion(e, nombre)
	local max = p and p.max or 0
	local oro, nivel = 0, 0
	for _, rg in ipairs(r) do
		if rg.tope > max and rg.instructor then oro = oro + rg.costo; nivel = math.max(nivel, rg.nivel) end
	end
	return { rangosOro = oro, nivel = nivel, desde = p and p.rango or 0 }
end

---------------------------------------------------------------- pasos de "Ahora"
local function paso(t) return t end

function M.Pasos(e, r)
	local pj = M.PJ()
	local pasos = {}
	local function add(p)
		if not pj.descartados[p.clave] and not pj.hechos[p.clave] then pasos[#pasos + 1] = p end
	end
	-- la guía es la columna: siempre primero, con lo que viene ("Entrega 2 misiones → vuela a ...")
	local pp = M.Fuentes.ProximoPaso and M.Fuentes.ProximoPaso(4)
	if pp and #pp.metas > 0 then
		add(paso({ clave = "guia", tipo = "Ahora", titulo = table.concat(pp.metas, "  ›  "),
			detalle = ("%s · paso %s de %s"):format(pp.guia or "Tu guía", tostring(pp.paso), tostring(pp.total)),
			accion = "guia", fijo = true }))
	else
		add(paso({ clave = "guia", tipo = "Subir", titulo = "Abre tu guía de leveo",
			detalle = "Todavía no hay una guía abierta: elige la de tu zona y aquí sale el próximo paso.",
			accion = "guia", fijo = true }))
	end
	-- el entrenamiento y la montura del próximo nivel, en una línea, cuando ya están cerca
	for _, m in ipairs(M.Metas(e)) do
		if (m.clave:find("^entrenar") or m.clave:find("^montura")) and m.nivel - e.nivel <= 1 then
			add(paso({ clave = "meta:" .. m.clave, tipo = "Nivel " .. m.nivel, titulo = m.titulo .. ": " .. M.Dinero(m.costo),
				detalle = m.falta > 0 and ("Te faltan " .. M.Dinero(m.falta) .. ".") or "Te alcanza.", lugar = m.lugar,
				confianza = m.confianza }))
		end
	end
	-- rango de profesión que se te acaba
	for _, p in ipairs(e.profesiones) do
		local rg = M.RANGOS and M.RANGOS[p.nombre]
		if rg and p.max < 300 and p.rango >= p.max - 15 then
			for i, x in ipairs(rg) do
				if x.tope > p.max then
					local lugar = M.LugarDe(x.quien, e.bando)
					add(paso({ clave = "rango:" .. p.nombre .. x.tope, tipo = "Profesión",
						titulo = ("%s %d/%d: aprende %s"):format(p.nombre, p.rango, p.max, M.NOMBRE_RANGO[i]),
						detalle = x.instructor and (("Cuesta %s, pide nivel %d%s."):format(M.Dinero(x.costo), x.nivel, lugar and (" · " .. lugar.zona) or ""))
							or "Se aprende con un libro o una misión, no con un instructor.",
						lugar = lugar, nivel = x.nivel, confianza = "dato del juego" }))
					break
				end
			end
		end
	end
	-- montura: ya te alcanza
	for _, m in ipairs(M.Metas(e)) do
		if m.clave:find("^montura") and e.nivel >= m.nivel and m.falta == 0 then
			add(paso({ clave = m.clave, tipo = "Montura", titulo = m.titulo .. ": ya te alcanza", detalle = m.detalle,
				lugar = m.lugar, confianza = "dato del juego" }))
		end
	end
	-- bolsa
	local b = M.Bolsas(e)
	if b.recomendada and (b.recomendada.mejora or 0) >= 4 then
		local o = b.recomendada
		add(paso({ clave = "bolsa:" .. o.id, tipo = "Bolsas",
			titulo = ("Cambia tu bolsa de %d por %s (%d casillas)"):format(b.menor, o.nombre, o.casillas),
			detalle = o.formas[1] or "", item = o.id, lugar = o.lugar,
			confianza = o.precioDias and (o.precioDias <= 1 and "precio medido hoy" or ("precio de hace " .. o.precioDias .. " días")) or "dato del juego" }))
	end
	-- mazmorra que conviene repetir (de Equipo)
	local mz = M.Fuentes.Mazmorras(e.nivel)
	if mz and mz[1] and mz[1].pieza and mz[1].valor > 0 then
		local x = mz[1]
		local pz = x.pieza
		local n, horas = M.Fuentes.PasadasPara(pz.pct)
		add(paso({ clave = "mazmorra:" .. tostring(x.clave), tipo = "Mazmorra",
			titulo = x.nombre .. ": vale la pena repetirla",
			detalle = ("%s%s · %s %% por pasada%s"):format(pz.nombre or ("objeto " .. pz.id),
				pz.pctMejora and (" (mejora " .. math.floor(pz.pctMejora + 0.5) .. " %)") or "",
				tostring(pz.pct or "?"), n and (" · unas " .. math.ceil(n) .. " pasadas") or ""),
			item = pz.id, accion = "equipo", confianza = "dato de forever-db" }))
	end
	-- dinero que falta para la montura
	for _, m in ipairs(M.Metas(e)) do
		if m.clave:find("^montura") and m.falta > 0 then
			add(paso({ clave = "dinero:" .. m.clave, tipo = "Dinero",
				titulo = ("Te faltan %s para %s"):format(M.Dinero(m.falta), m.titulo:lower()),
				detalle = "Mira «Dinero» para ver cómo juntarlos con lo que tienes.", accion = "dinero" }))
			break
		end
	end
	-- macros que te sirven y no tienes
	if M.MacrosSugeridas then
		for _, mc in ipairs(M.MacrosSugeridas(e, 2)) do
			add(paso({ clave = "macro:" .. mc.clave, tipo = "Macro", titulo = mc.titulo, detalle = mc.detalle,
				accion = "macro", macro = mc.clave }))
		end
	end
	return pasos
end

---------------------------------------------------------------- para el cuadro del objeto (fila E8)
-- ¿Este objeto lo necesita tu plan? -> nil | { clase = "vital" | "plan", texto }
-- Hoy: la bolsa recomendada de tu plan. "VITAL para subir una profesión" llega con la sección Profesiones
-- (necesita las recetas). La ventana de Mamba lo muestra en el bloque "Mamba" del cuadro del objeto.
function M.MaterialDelPlan(itemID)
	if not itemID then return nil end
	local ok, e = pcall(M.Estado)
	if not ok then return nil end
	local b = M.Bolsas(e)
	if b.recomendada and b.recomendada.id == itemID then
		return { clase = "plan", texto = "Es la bolsa de tu plan: te da " .. b.recomendada.casillas .. " casillas." }
	end
	if M.MaterialVital then return M.MaterialVital(e, itemID) end
	return nil
end

---------------------------------------------------------------- dinero: cómo juntarlo
-- Ideas para juntar oro según lo que el personaje TIENE (no números inventados: el ritmo lo mide el Medidor).
function M.ComoJuntar(e)
	local ideas = {}
	local recoleccion = { ["Herboristería"] = "hierbas", ["Minería"] = "minerales", ["Desuello"] = "pieles y cuero" }
	for _, p in ipairs(e.profesiones) do
		if recoleccion[p.nombre] then
			ideas[#ideas + 1] = { titulo = "Junta " .. recoleccion[p.nombre] .. " con " .. p.nombre .. " y véndelas",
				detalle = "Recolectar no gasta materiales. La subasta (Tasador) te dice cuál vale más hoy.", accion = "farmeo" }
		end
	end
	ideas[#ideas + 1] = { titulo = "Vende lo que no usas", detalle = "Tasador › Vender lo mío: a cuánto y si conviene subasta o vendedor.", accion = "subasta" }
	ideas[#ideas + 1] = { titulo = "Mide qué te deja más oro por hora", detalle = "El Medidor compara lo que haces (misiones, farmeo, mazmorras).", accion = "medidor" }
	return ideas
end
