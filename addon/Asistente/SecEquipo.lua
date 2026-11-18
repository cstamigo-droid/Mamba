-- Asistente/SecEquipo.lua: la sección «Equipo» del hub (riel de Polestar). Pestañas: Mejorar (la mejor pieza
-- por ranura, dónde, cómo, nivel, cuándo y botón «Ir»), Lo que llevas, Mazmorras (ficha con jefes en el orden
-- del recorrido), Al 60, Contra jugadores y Tu rol. Los cálculos son los de Asistente_Equipo (Logica.lua).
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local Hub = A.Hub
local format, floor, max = string.format, math.floor, math.max

local CLAVE = "MambaEquipo"
local cache = {} -- se borra cuando cambia el equipo o el nivel

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("QUEST_TURNED_IN")
f:SetScript("OnEvent", function() cache = {} end)

local function E() return A.modulos and A.modulos.equipo end

local function hex(q)
	local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q or 1]
	return c and c.hex or "|cffffffff"
end

local function calidad(x)
	local fn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
	if not fn then return nil end
	local ok, _, _, q = pcall(fn, x)
	return ok and q or nil
end

local function nombreObj(e, id, respaldo)
	local n = e.NombreObjeto and e.NombreObjeto(id, respaldo) or respaldo or ("objeto " .. id)
	n = tostring(n):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", ""):gsub("^%[", ""):gsub("%]$", "")
	return hex(calidad(id)) .. n .. "|r"
end

local MAZCOL = "|cffa385ff"
local function maz(t) return MAZCOL .. tostring(t) .. "|r" end

---------------------------------------------------------------- los datos (una vez por cambio de equipo)
local function contexto()
	local e = E()
	if not e then return nil, "Falta el módulo de equipo de Mamba (Asistente_Equipo)." end
	if cache.ctx then return cache.ctx end
	local G, falta = e.Gear()
	if not G then return nil, "Falta el módulo de equipo de Polestar" .. (falta ~= "sin_polestar" and (" (" .. tostring(falta) .. ")") or "") .. "." end
	local DB = _G.Polestar.ItemDB
	if type(DB) == "table" and DB.Load and DB.IsLoaded then
		pcall(DB.Load)
		if not DB.IsLoaded() then
			return nil, A.EnCombate() and "Estás en combate: la lista se arma sola al salir del combate." or "Activa «Polestar_ItemDB» en la lista de accesorios."
		end
	end
	local clase, nivel, lado = e.Jugador(G)
	local rol, etiqueta, origen = G.GetSpec()
	if not (clase and rol and G.GetWeights()) then return nil, "Mamba no tiene pesos para tu clase todavía." end
	local rev = e.Revisar(G, e.EquipoPuesto(), e.SabeEquipar)
	local porRanura, total = {}, 0
	for _, r in ipairs(rev.ranuras) do
		-- Verde o azul que puntúa casi cero: atributos que no se pudieron leer. Su % no se muestra.
		local q = r.link and calidad(r.link)
		r.ilegible = r.link and (q or 0) >= 2 and (r.puntaje or 0) < 1 and r.sabe
		if not r.ilegible then total = total + (r.puntaje or 0) end
		porRanura[r.ranura] = r
	end
	local con, sin = e.MejorasMazmorras(G, nivel, lado, e.MisionHecha)
	-- valor de cada mazmorra sin las ranuras ilegibles (Logica.lua lo suma con todas)
	local tope = nivel + (e.HOLGURA or 2)
	for _, x in ipairs(con) do
		local mejor = {}
		for _, p in ipairs(x.piezas) do
			local act = porRanura[p.ranura]
			if not p.mision and not p.bichos and (p.nivelMin or 0) <= tope and not (act and act.ilegible) then
				local v = p.ganancia * (p.pct or 0) / 100
				if not mejor[p.ranura] or v > mejor[p.ranura] then mejor[p.ranura] = v end
			end
		end
		x.valorLegible = 0
		for _, v in pairs(mejor) do x.valorLegible = x.valorLegible + v end
	end
	table.sort(con, function(a, b)
		if a.valorLegible ~= b.valorLegible then return a.valorLegible > b.valorLegible end
		return a.m.min < b.m.min
	end)
	-- la mejor pieza YA por ranura, en todas las mazmorras de tu nivel
	local ya = {}
	for _, x in ipairs(con) do
		for _, p in ipairs(x.piezas) do
			if (p.nivelMin or 0) <= tope then
				local peso = p.mision and p.ganancia or p.ganancia * (p.pct or 0) / 100 * (p.bichos and 0.5 or 1)
				if not ya[p.ranura] or peso > ya[p.ranura].peso then ya[p.ranura] = { p = p, m = x.m, peso = peso } end
			end
		end
	end
	cache.ctx = { e = e, G = G, clase = clase, nivel = nivel, lado = lado, rol = rol, etiqueta = etiqueta, origen = origen,
		rev = rev, porRanura = porRanura, total = total, con = con, sin = sin, ya = ya,
		rec = con[1] and con[1].valorLegible > 0 and con[1] or nil, seg = con[2] }
	return cache.ctx
end

-- Más adelante: lo mejor por ranura en las mazmorras que todavía no son de tu nivel (se calcula al pedirlo).
local function masAdelante(c)
	if cache.luego then return cache.luego end
	local luego = {}
	local tope = c.nivel + (c.e.HOLGURA or 2)
	for _, m in ipairs(c.e.MAZMORRAS or {}) do
		if m.min > tope and not (m.lado and c.lado and m.lado ~= c.lado) then
			local ok, x = pcall(c.e.MejorasDe, c.G, m, c.nivel, c.lado, c.e.MisionHecha, 60)
			if ok and x then
				for _, p in ipairs(x.piezas) do
					local peso = p.mision and p.ganancia or p.ganancia * (p.pct or 0) / 100
					local cuando = max(p.nivelMin or 0, m.min - (c.e.HOLGURA or 2))
					-- se prefiere lo que llega antes: entre dos parecidas, la de menor nivel
					local s = peso / (1 + max(0, cuando - c.nivel) * 0.05)
					if not luego[p.ranura] or s > luego[p.ranura].s then luego[p.ranura] = { p = p, m = m, s = s, cuando = cuando } end
				end
			end
		end
	end
	cache.luego = luego
	return luego
end

---------------------------------------------------------------- piezas de texto
local function ranuraNombre(c, r) return c.e.RANURA_NOMBRE and c.e.RANURA_NOMBRE[r] or tostring(r) end

local function textoMejora(c, p)
	local act = c.porRanura[p.ranura]
	if act and act.ilegible then return "|cff9ba2b9mejora: sin datos aún (atributos de tu pieza sin leer)|r" end
	if p.vacia or not (act and act.link) then return "|cff6bd999llena una ranura vacía|r" end
	if act and not act.sabe then return "|cff6bd999mejor|r |cff9ba2b9que la tuya (la tuya, sin datos)|r" end
	return "|cff6bd999+" .. A.Pct(p.pctMejora, 0) .. "|r |cff9ba2b9sobre|r " .. tostring(act.link):gsub("[%[%]]", "")
end

local function dondeComo(p)
	if p.mision then return "misión «" .. tostring(p.jefe) .. "»", "100 %", "recompensa de misión" end
	if p.bichos then return "enemigos comunes", A.Pct(p.pct), "por enemigo" end
	local n = p.pct and p.pct > 0 and math.ceil(100 / p.pct)
	return tostring(p.jefe), p.pct and A.Pct(p.pct) or "sin datos aún", n and ("~" .. n .. " entradas") or "caída desconocida"
end

local function flecha(c, m)
	local ok, motivo = c.e.FlechaA(m, true)
	cache.flecha = { clave = m.clave, ok = ok, motivo = motivo }
end

local MOTIVO = {
	combate = "Estás en combate: sal de combate y vuelve a apretar «Llevarme a la entrada».",
	sin_entrada = "Mamba todavía no conoce la entrada de esta mazmorra (es nueva de Forever): búscala en el mapa del mundo.",
	sin_base = "Falta la base de mazmorras: activa «Polestar_Codex» en la lista de accesorios.",
}

-- La mazmorra que recomienda «Mejorar» (la usa «Ir a…» para sugerirla: la misma en todas las pantallas).
function A.MazmorraRecomendada()
	local ok, c = pcall(contexto)
	return ok and c and c.rec and c.rec.m or nil
end

---------------------------------------------------------------- pestañas
local function panelRec(c, V)
	local r, s = c.rec, c.seg
	if not r then
		V:Panel({ titulo = "Tu equipo ya está al día", texto = "En las mazmorras de tu nivel con datos no hay piezas mejores que las tuyas. Mira «Más adelante»." })
		return
	end
	local piezas = {}
	for _, p in ipairs(r.piezas) do
		local act = c.porRanura[p.ranura]
		if #piezas < 3 and not p.mision and not p.bichos and not (act and act.ilegible) then
			piezas[#piezas + 1] = nombreObj(c.e, p.id, p.nombre) .. " (" .. ranuraNombre(c, p.ranura):lower() .. ", " .. A.Pct(p.pct) .. ")"
		end
	end
	local pct = c.total > 0 and A.Pct(r.valorLegible / c.total * 100) or "sin datos aún"
	local txt = "Es la mazmorra de tu nivel que más te sube el equipo: en promedio |cfff7f8fd+" .. pct .. "|r por cada entrada"
	if s and s.valorLegible > 0 and c.total > 0 then txt = txt .. " (la que sigue, " .. s.m.nombre .. ": +" .. A.Pct(s.valorLegible / c.total * 100) .. ")" end
	if #piezas > 0 then txt = txt .. ". Ahí te caen " .. table.concat(piezas, ", ") .. "." end
	local fl = cache.flecha
	if fl and fl.clave == r.m.clave then
		txt = txt .. "\n" .. (fl.ok and "|cff6bd999La flecha te lleva a la entrada.|r" or ("|cfffabf4d" .. (MOTIVO[fl.motivo] or "No pude poner la flecha.") .. "|r"))
	end
	V:Panel({ titulo = "Ve a " .. maz(r.m.nombre), texto = txt,
		boton = { "Llevarme a la entrada", function() flecha(c, r.m) end },
		boton2 = { "Ver la mazmorra", function() local est = Hub.Est(CLAVE); est.pestana = "mazmorras"; est.maz = r.m.clave end } })
end

local function pestanaMejorar(est, V, c)
	panelRec(c, V)
	est.cuando = est.cuando or "ya"
	local filas = {}
	local luego = (est.cuando ~= "ya") and masAdelante(c) or {}
	for _, r in ipairs(c.e.RANURAS or {}) do
		if not est.filtro or est.filtro == "todas" or tonumber(est.filtro) == r then
			if est.cuando ~= "luego" and c.ya[r] then filas[#filas + 1] = { r = r, x = c.ya[r], ya = true } end
			if est.cuando ~= "ya" and luego[r] then filas[#filas + 1] = { r = r, x = luego[r], ya = false } end
		end
	end
	local recNombre = c.rec and c.rec.m.nombre
	V:Segmentos({ { key = "ya", label = "Ya" }, { key = "luego", label = "Más adelante" }, { key = "todo", label = "Todo" } }, est.cuando,
		function(k) est.cuando = k end,
		est.cuando == "ya" and ("La mejor pieza que ya puedes conseguir para cada ranura" .. (recNombre and (" · el punto violeta: sale de " .. recNombre) or "")) or "Ordenado por ranura")
	if #filas == 0 then
		V:Vacio(est.cuando == "ya" and "Nada que mejorar ya" or "Sin resultados", est.cuando == "ya" and "No encontré piezas mejores que las tuyas en las mazmorras de tu nivel con datos." or "No hay piezas para esta ranura en los datos.")
		return
	end
	local cols = { { "Ranura", 96 }, { "Mejora", 330 }, { "Dónde", 200 }, { "Probabilidad", 110 }, { "Nivel", 50 } }
	if est.cuando ~= "ya" then cols[#cols + 1] = { "Cuándo", 90 } end
	V:Columnas(cols)
	for _, fi in ipairs(filas) do
		local p, m = fi.x.p, fi.x.m
		local d1, prob, prob2 = dondeComo(p)
		local cel = {
			{ ranuraNombre(c, fi.r), nil, col = "textDim" },
			{ nombreObj(c.e, p.id, p.nombre), textoMejora(c, p) },
			{ maz(m.nombre), d1 },
			{ prob, prob2 },
			{ p.nivelMin and p.nivelMin > 0 and tostring(p.nivelMin) or "—" },
		}
		if est.cuando ~= "ya" then cel[#cel + 1] = { fi.ya and "|cff6bd999ya|r" or ("a nivel " .. (fi.x.cuando or m.min)) } end
		V:Fila({ icono = p.id, item = p.id, iconoEnCol2 = true, celdas = cel,
			marca = (fi.ya and recNombre and m.nombre == recNombre) and "dungeon" or nil,
			ir = function() flecha(c, m) end,
			tipExtra = { "Mamba: " .. textoMejora(c, p), tostring(p.jefe) .. " · " .. m.nombre .. " · " .. prob } })
	end
	V:Nota("El % de caída es de la beta (13-10-2026). «~3 entradas»: cuántas veces, en promedio, hay que entrar para que caiga. Máximo 5 entradas a mazmorras por hora.")
end

local function pestanaLlevas(est, V, c)
	V:Columnas({ { "Ranura", 120 }, { "Lo que llevas", 420 }, { "Nota", 300 } })
	for _, r in ipairs(c.rev.ranuras) do
		if r.ranura ~= 18 or r.link then
			local nota
			if r.vacia then nota = "|cfffabf4dvacía: cualquier pieza que sirva a tu rol ya es mejora|r"
			elseif r.dosManos then nota = "ocupada por tu arma de dos manos"
			elseif r.ilegible then nota = "atributos sin leer: compárala tú"
			elseif not r.sabe then nota = "tiene un «Equipar:» que no se pudo medir" end
			local mejor = c.ya[r.ranura]
			V:Fila({ icono = r.link and (GetInventoryItemTexture and GetInventoryItemTexture("player", r.ranura)) or nil, item = r.link, iconoEnCol2 = true,
				celdas = { { ranuraNombre(c, r.ranura), nil, col = "textDim" }, { r.link and tostring(r.link):gsub("[%[%]]", "") or "|cff9ba2b9vacía|r" },
					{ nota or (mejor and ("puedes mejorarla: " .. nombreObj(c.e, mejor.p.id, mejor.p.nombre)) or "|cff6bd999lo mejor que hay a tu nivel|r") } } })
		end
	end
end

local function ordenJefes(c, m)
	local jefes = c.e.JefesDe(m.clave)
	local P = _G.Polestar
	local D = P and P.Dungeons
	local clave = c.e.CLAVE_POLESTAR and c.e.CLAVE_POLESTAR[m.clave]
	if not (D and D.Bosses and clave) then return jefes end
	local ok, b = pcall(D.Bosses, clave)
	if not (ok and type(b) == "table") then return jefes end
	local lista = b.order or b
	local pos = {}
	for i, x in ipairs(lista) do
		local id = type(x) == "table" and (x.npc or x.id) or x
		local n = id and P.Names and P.Names.Npc and P.Names.Npc(id)
		if type(n) == "string" then pos[n] = i end
	end
	local orden = {}
	for i, j in ipairs(jefes) do orden[i] = { j = j, i = pos[j] or (100 + i) } end
	table.sort(orden, function(a, b2) return a.i < b2.i end)
	local out = {}
	for i, x in ipairs(orden) do out[i] = x.j end
	return out
end

local function pestanaMazmorras(est, V, c)
	local m = est.maz and c.e.Mazmorra(est.maz) or (c.rec and c.rec.m) or (c.con[1] and c.con[1].m)
	if not m then V:Vacio("Sin mazmorras de tu nivel", "No hay mazmorras con datos para tu nivel.") return end
	local x = c.e.MejorasDe(c.G, m, c.nivel, c.lado, c.e.MisionHecha, 60)
	local fl = cache.flecha
	local txt = format("Niveles %d a %d · %s", m.min, m.max, tostring(m.donde))
	if c.rec and c.rec.m.clave == m.clave and c.total > 0 then txt = txt .. " · la recomendada: +" .. A.Pct(c.rec.valorLegible / c.total * 100) .. " de equipo por entrada" end
	if m.min > c.nivel + 2 then txt = txt .. "\n|cfffabf4dTodavía no es de tu nivel: desde nivel " .. (m.min - 2) .. ".|r" end
	if fl and fl.clave == m.clave then txt = txt .. "\n" .. (fl.ok and "|cff6bd999La flecha te lleva a la entrada.|r" or ("|cfffabf4d" .. (MOTIVO[fl.motivo] or "No pude poner la flecha.") .. "|r")) end
	V:Panel({ titulo = maz(m.nombre), texto = txt, boton = { "Llevarme a la entrada", function() flecha(c, m) end } })
	if not x then V:Vacio("Sin datos de botín", "No hay datos abiertos del botín de esta mazmorra: no sé qué te puede dar.") return end
	local porJefe, misiones, bichos = {}, {}, {}
	for _, p in ipairs(x.piezas) do
		if p.mision then misiones[#misiones + 1] = p
		elseif p.bichos then bichos[#bichos + 1] = p
		else porJefe[p.jefe] = porJefe[p.jefe] or {}; table.insert(porJefe[p.jefe], p) end
	end
	V:Titulo("Jefes que te dan algo", "en el orden del recorrido")
	local vacios = {}
	local function filaPieza(p)
		local _, prob, prob2 = dondeComo(p)
		V:Fila({ icono = p.id, item = p.id, celdas = { { nombreObj(c.e, p.id, p.nombre), ranuraNombre(c, p.ranura) .. (p.nivelMin and (" · nivel " .. p.nivelMin) or "") }, { prob, prob2 }, { textoMejora(c, p) } } })
	end
	V:Columnas({ { "", 360 }, { "", 130 }, { "", 300 } }, true)
	for i, j in ipairs(ordenJefes(c, m)) do
		local l = porJefe[j]
		if l then
			V:Nota(i .. ". " .. j, "npc")
			for _, p in ipairs(l) do filaPieza(p) end
		else
			vacios[#vacios + 1] = i .. ". " .. j
		end
	end
	if #vacios > 0 then V:Nota("Sin nada para ti: " .. table.concat(vacios, " · ")) end
	if #misiones > 0 then V:Titulo("Misiones de esta mazmorra", "premio seguro, una vez"); for _, p in ipairs(misiones) do filaPieza(p) end end
	if #bichos > 0 then V:Titulo("Enemigos comunes de la mazmorra"); for _, p in ipairs(bichos) do filaPieza(p) end end
	local cp = c.e.CLAVE_POLESTAR and c.e.CLAVE_POLESTAR[m.clave]
	if cp and _G.Polestar.Fire then
		V:Botones({ { "Ver las misiones de esta mazmorra", function() _G.Polestar.Fire("SHOW_DUNGEON", cp) end } })
	end
end

-- Al 60, Contra jugadores y Tu rol: las filas del módulo, dibujadas con las piezas del hub.
local function pestanaFilas(est, V, c, seccion)
	local L = A.NuevaLista()
	local ok, err = pcall(c.e.Seccion, seccion, L)
	if not ok then V:Vacio("Algo falló", "Abre «Errores» en el riel: ahí está el detalle.") ; if geterrorhandler then geterrorhandler()(err) end return end
	for _, o in ipairs(L.filas) do
		if o.blanco then V:Espacio(6)
		elseif o.tipo == "titulo" then V:Titulo(o.texto)
		elseif o.tipo == "nota" then V:Nota(o.texto)
		elseif o.item then
			local link = o.item
			local id = type(link) == "number" and link or tonumber(tostring(link):match("item:(%d+)"))
			V:Columnas({ { "", 840 } }, true)
			V:Fila({ icono = id, item = link, celdas = { { o.texto } } })
		else V:Nota(o.texto, "text") end
	end
end

local PESTANAS = {
	{ key = "mejorar", label = "Mejorar" }, { key = "llevas", label = "Lo que llevas" }, { key = "mazmorras", label = "Mazmorras" },
	{ key = "60", label = "Al 60" }, { key = "jcj", label = "Contra jugadores" }, { key = "rol", label = "Tu rol" }, { key = "fuentes", label = "De dónde salen los datos" },
}

Hub.Seccion({
	clave = CLAVE, nombre = "Equipo", icono = "qol-upgrade", orden = 100, addon = "Asistente_Equipo",
	pestanas = PESTANAS,
	titulo = function()
		local c = contexto()
		if not c then return "Mejorar mi equipo", "" end
		local nombre = UnitName and UnitName("player") or ""
		return "Mejorar mi equipo", format("%s · %s · nivel %d", nombre, c.e.NombreRol(c.rol, c.etiqueta), c.nivel)
	end,
	nav = function(est)
		local c = contexto()
		if not c then return {}, nil end
		if est.pestana == "mazmorras" then
			local items = {}
			for _, x in ipairs(c.con) do items[#items + 1] = { key = x.m.clave, label = x.m.nombre, count = #x.piezas > 0 and #x.piezas or nil } end
			for _, m in ipairs(c.sin) do items[#items + 1] = { key = m.clave, label = m.nombre .. " (sin datos)" } end
			return items, est.maz or (c.rec and c.rec.m.clave)
		end
		if est.pestana == "mejorar" or est.pestana == nil then
			local items = { { key = "todas", label = "Todas las ranuras" } }
			for _, r in ipairs(c.e.RANURAS or {}) do
				if c.ya[r] then items[#items + 1] = { key = tostring(r), label = ranuraNombre(c, r) } end
			end
			return items, est.filtro or "todas"
		end
		return {}, nil
	end,
	onNav = function(est, key)
		if est.pestana == "mazmorras" then est.maz = key else est.filtro = key end
	end,
	dibujar = function(est, V)
		local c, motivo = contexto()
		if not c then V:Vacio("Todavía no", motivo or "Falta un dato.") return end
		local p = est.pestana or "mejorar"
		if p == "mejorar" then pestanaMejorar(est, V, c)
		elseif p == "llevas" then pestanaLlevas(est, V, c)
		elseif p == "mazmorras" then pestanaMazmorras(est, V, c)
		elseif p == "60" then pestanaFilas(est, V, c, "60")
		elseif p == "jcj" then pestanaFilas(est, V, c, "jcj")
		elseif p == "rol" then pestanaFilas(est, V, c, "rol")
		else pestanaFilas(est, V, c, "fuentes") end
	end,
})
