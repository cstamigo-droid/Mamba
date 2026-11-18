-- Asistente_Equipo: la pestaña «Equipo» de la ventana de Mamba (addon Asistente, Ventana.lua).
--   /equipo              abre la ventana en «Mi equipo»: lo puesto, ranura por ranura, y qué mazmorra repetir
--   /equipo mazmorras    las mazmorras de tu nivel; clic en una: sus jefes, lo que te mejora, % y pasadas,
--                        y la flecha te lleva a su entrada
--   /equipo 60           guía al 60 de JcE (mejor pieza por ranura y orden para juntarlas) · PROVISIONAL
--   /equipo jcj          guía al 60 de JcJ (conjunto de honor de tu rol y qué da cada rango) · PROVISIONAL
--   /equipo rol          qué rol se está usando (tus talentos o lo que elijas en los ajustes de Mamba)
--   /equipo fuentes      de dónde sale cada dato
-- Cada sección escribe filas (L:Fila) que la ventana dibuja: objetos con su cuadro al pasar el ratón,
-- mazmorras que se abren con clic. Sin la ventana (un Asistente viejo), las mismas filas van al chat.
-- Licencia: GPL-3.0-only.
local _, E = ...
local A = _G.Asistente

local format = string.format

-- Nombres sin traducción al español: el generador les deja un "*" al final (NO VERIFICADO).
local LEYENDA_MARCA = "* = nombre sin traducción al español en los datos del juego (NO VERIFICADO)."

local function Color(nombre, t)
	if A and A.Color then return A.Color(nombre, t) end
	return t
end

local function Pct(p)
	if not p or p <= 0 then return "% sin dato" end
	if p >= 100 then return "segura (misión)" end
	return (format("%.1f", p):gsub("%.0$", ""):gsub("%.", ",")) .. " %"
end

-- Pasadas promedio (100 / %) y horas mínimas por el tope de 5 entradas por hora.
local function TextoPasadas(pct)
	if not pct or pct <= 0 or pct >= 100 then return "" end
	local n, h = E.Pasadas(pct)
	return format(" · ~%d pasadas (%s h o más)", math.ceil(n), (format("%.1f", h):gsub("%.", ",")))
end

local function TextoMejora(p)
	if p.vacia or not p.pctMejora then return "ranura vacía" end
	if p.pctMejora >= 100 then return "mucho mejor" end -- pasado el doble, el % ya no dice mucho
	return format("+%d %%", math.floor(p.pctMejora + 0.5))
end

local function TextoDonde(p)
	if p.mision then return "misión «" .. tostring(p.jefe) .. "»", "segura, una sola vez" end
	if p.bichos then return "bichos de la mazmorra", Pct(p.pct) .. " por bicho (NO VERIFICADO)" end
	return tostring(p.jefe), Pct(p.pct) .. TextoPasadas(p.pct)
end

-- Una pieza que te mejora: "[Nombre] (Ranura, +12 %) · de Jefe · 14 % · ~8 pasadas (1,4 h o más) · nivel 37"
local function Pieza(p, conDonde)
	local donde, prob = TextoDonde(p)
	local nivel = p.nivelMin and p.nivelMin > 0 and format(" · nivel %d", p.nivelMin) or ""
	return format("%s (%s, %s)%s · %s%s", E.NombreObjeto(p.id, p.nombre), E.RANURA_NOMBRE[p.ranura] or "?", TextoMejora(p),
		conDonde == false and "" or (" " .. Color("gris", "de " .. donde)), prob, nivel)
end

-- Lo que se necesita para cualquier sección: Gear, la base de objetos y el rol. Si falta algo, lo escribe en L.
local function Contexto(L)
	local G, falta = E.Gear()
	if not G then
		L:Fila("Necesito Mamba con su módulo de equipo" .. (falta ~= "sin_polestar" and (" (falta Gear." .. tostring(falta) .. ": ¿cambió de versión?)") or "") .. ".", { tipo = "nota" })
		return nil
	end
	local faltaDB = E.FaltaItemDB()
	if faltaDB then
		L:Fila(Color("dudoso", "Aviso: ") .. "Mamba no trae " .. faltaDB .. " (¿cambió de versión?). Sigo, pero toda pieza con «Equipar:» saldrá como dudosa.")
	end
	local DB = _G.Polestar.ItemDB
	if type(DB) == "table" and DB.Load and DB.IsLoaded then
		pcall(DB.Load) -- no se carga en combate
		if not DB.IsLoaded() then
			L:Fila("La base de objetos de Mamba no está cargada"
				.. (A and A.EnCombate and A.EnCombate() and ": sal de combate y vuelve a abrir esta pestaña." or ": revisa que «Polestar_ItemDB» esté activado en la lista de accesorios."), { tipo = "nota" })
			return nil
		end
	end
	local clase, nivel, lado = E.Jugador(G)
	local rol, etiqueta, origen = G.GetSpec()
	if not (clase and rol and G.GetWeights()) then
		L:Fila("Mamba no tiene pesos para tu clase.", { tipo = "nota" })
		return nil
	end
	return G, clase, nivel, lado, rol, etiqueta, origen
end

local ORIGEN = { setting = "elegido en los ajustes de Mamba", talents = "tus talentos", default = "el de subida por defecto", custom = "tu escala propia" }

local function TextoMazmorra(m)
	return format("%s (niveles %d-%d, %s)", m.nombre, m.min, m.max, tostring(m.donde))
end

local function Leyenda(L)
	for _, o in ipairs(L.filas) do
		if o.texto:find("*", 1, true) then
			L:Blanco()
			L:Fila(LEYENDA_MARCA, { tipo = "nota" })
			return
		end
	end
end

---------------------------------------------------------------- Mi equipo
local function SeccionRevisar(L)
	local G, clase, nivel, lado, rol, etiqueta, origen = Contexto(L)
	if not G then return end
	local rev = E.Revisar(G, E.EquipoPuesto(), E.SabeEquipar)
	L:Fila(format("Tu equipo para %s, nivel %d (rol según %s). Pesos de Mamba.", E.NombreRol(rol, etiqueta), nivel, ORIGEN[origen] or tostring(origen)), { tipo = "titulo" })
	for _, f in ipairs(rev.ranuras) do
		local nombre = E.RANURA_NOMBRE[f.ranura] or "?"
		if f.vacia then
			if f.ranura ~= 18 then
				L:Fila(nombre .. ": " .. Color("dudoso", "vacía · cualquier pieza que sirva a tu rol ya es mejora"), { sangria = 1 })
			end
		elseif f.dosManos then
			L:Fila(nombre .. ": " .. Color("gris", "ocupada por tu arma de dos manos"), { sangria = 1 })
		else
			local marca = f.sabe and "" or ("  " .. Color("gris", "(tiene un «Equipar:» que no se pudo medir: compárala tú)"))
			L:Fila(nombre .. ": " .. tostring(f.link) .. marca, { sangria = 1, item = f.link })
		end
	end
	L:Blanco()
	L:Fila("Qué mazmorra repetir (clic para ver sus jefes y lo que te da)", { tipo = "titulo" })
	local con, sin = E.MejorasMazmorras(G, nivel, lado, E.MisionHecha)
	local n = 0
	for _, x in ipairs(con) do
		if n >= 3 or x.valor <= 0 then break end
		n = n + 1
		L:Fila(format("%d. %s: %d pieza(s) que te mejoran", n, TextoMazmorra(x.m), #x.piezas),
			{ sangria = 1, ir = "mazmorra:" .. x.m.clave, clic = function() E.FlechaA(x.m, true) end })
		for i = 1, math.min(2, #x.piezas) do
			L:Fila(Pieza(x.piezas[i]), { sangria = 2, item = x.piezas[i].id })
		end
	end
	if n == 0 then L:Fila("En las mazmorras de tu nivel con datos no encontré piezas mejores que las tuyas.", { sangria = 1 }) end
	if #sin > 0 then
		local t = {}
		for _, m in ipairs(sin) do t[#t + 1] = m.nombre end
		L:Fila("Sin datos abiertos de botín: " .. table.concat(t, ", "), { sangria = 1, tipo = "nota" })
	end
	L:Blanco()
	L:Fila("Ojo: el % de caída es de la beta (ForeverLevelingBiS, 13-10-2026). Máximo 5 entradas a mazmorras por hora.", { tipo = "nota" })
	Leyenda(L)
end

---------------------------------------------------------------- Mazmorras
-- La flecha a la entrada. silencio: no escribir en el chat si funcionó.
function E.FlechaA(m, silencio)
	-- Con el motor de «Llévame» (Asistente/Llevame.lua, K58): la misma flecha, más los tramos en el panel de la guía.
	local LL = A and A.Llevame
	local ok, motivo
	if LL and LL.Llevame then
		ok, motivo = LL.Llevame({ tipo = "mazmorra", clave = "m:" .. m.clave, nombre = m.nombre, m = m })
		if not ok and motivo == "sin_ruta" then motivo = "sin_entrada" end
	else
		ok, motivo = E.GuiarEntrada(m)
	end
	E.ultimaFlecha = { clave = m.clave, ok = ok, motivo = motivo }
	if not ok and not silencio and A and A.Decir then
		A.Decir(m.nombre .. ": " .. (motivo == "combate" and "sal de combate para poner la flecha." or "no conozco su entrada."))
	end
	return ok, motivo
end

local MOTIVO_FLECHA = {
	combate = "Estás en combate: sal de combate y aprieta «Llevarme a la entrada».",
	sin_entrada = "Mamba todavía no conoce la entrada de esta mazmorra (es nueva de Forever): búscala en el mapa del mundo.",
	sin_base = "No pude abrir la base de mazmorras de Mamba (¿«Polestar_Codex» desactivado en la lista de accesorios?).",
}

local function SeccionMazmorras(L, todas)
	local G, clase, nivel, lado, rol, etiqueta = Contexto(L)
	if not G then return end
	if todas then
		L:Fila("Todas las mazmorras, por nivel (clic para ver sus jefes y lo que te da):", { tipo = "titulo" })
		for _, m in ipairs(E.MAZMORRAS or {}) do
			local ajena = m.lado and lado and m.lado ~= lado
			L:Fila(TextoMazmorra(m) .. (ajena and Color("gris", " · entrada en tierra enemiga") or "") .. (E.BOTIN[m.clave] and "" or Color("gris", " · sin datos de botín")),
				{ sangria = 1, ir = "mazmorra:" .. m.clave, clic = function() E.FlechaA(m, true) end })
		end
		Leyenda(L)
		return
	end
	L:Fila(format("Mazmorras para %s de nivel %d, de la que más te mejora a la que menos. Clic: sus jefes, lo que te da y la flecha a la entrada.", E.NombreRol(rol, etiqueta), nivel), { tipo = "titulo" })
	local con, sin = E.MejorasMazmorras(G, nivel, lado, E.MisionHecha)
	for i, x in ipairs(con) do
		L:Fila(format("%d. %s · %s", i, TextoMazmorra(x.m), #x.piezas == 0 and Color("gris", "nada mejor que lo tuyo") or (#x.piezas .. " pieza(s) que te mejoran")),
			{ sangria = 1, ir = "mazmorra:" .. x.m.clave, clic = function() E.FlechaA(x.m, true) end })
	end
	for _, m in ipairs(sin) do
		L:Fila(TextoMazmorra(m) .. " · " .. Color("gris", "sin datos abiertos de botín"),
			{ sangria = 1, ir = "mazmorra:" .. m.clave, clic = function() E.FlechaA(m, true) end })
	end
	L:Blanco()
	L:Fila("Ver todas las mazmorras (1 a 60)", { ir = "mazmorras:todas" })
	Leyenda(L)
end

local function SeccionMazmorra(L, clave)
	local m = E.Mazmorra(clave)
	if not m then
		L:Fila("No conozco esa mazmorra.", { tipo = "nota" })
		return
	end
	L:Fila(TextoMazmorra(m), { tipo = "titulo" })
	local f = E.ultimaFlecha
	if f and f.clave == clave then
		L:Fila(f.ok and Color("bueno", "La flecha te lleva a la entrada.") or Color("dudoso", MOTIVO_FLECHA[f.motivo] or "No pude poner la flecha."), { sangria = 1 })
	end
	L:Fila("Llevarme a la entrada (flecha)", { sangria = 1, clic = function() E.FlechaA(m); if A.Redibujar then A.Redibujar(true) end end })
	if m.lado then
		L:Fila(Color("gris", m.lado == "H" and "La entrada está en una ciudad de la Horda." or "La entrada está en una ciudad de la Alianza."), { sangria = 1 })
	end
	local G, clase, nivel, lado = Contexto(L)
	if not G then return end
	local x = E.MejorasDe(G, m, nivel, lado, E.MisionHecha, 60)
	if not x then
		L:Blanco()
		L:Fila("Sin datos abiertos de botín para esta mazmorra: no sé qué te puede dar.", { tipo = "nota" })
		return
	end
	-- Por jefe, en el orden de los datos; después misiones y bichos.
	local porJefe, misiones, bichos = {}, {}, {}
	for _, p in ipairs(x.piezas) do
		if p.mision then misiones[#misiones + 1] = p
		elseif p.bichos then bichos[#bichos + 1] = p
		else
			porJefe[p.jefe] = porJefe[p.jefe] or {}
			table.insert(porJefe[p.jefe], p)
		end
	end
	L:Blanco()
	L:Fila(format("Jefes y lo que te mejora (nivel %d; el %% es la chance de que caiga en una pasada):", nivel), { tipo = "titulo" })
	for _, jefe in ipairs(E.JefesDe(clave)) do
		local lista = porJefe[jefe]
		if lista then
			L:Fila(jefe, { sangria = 1 })
			for _, p in ipairs(lista) do L:Fila(Pieza(p, false), { sangria = 2, item = p.id }) end
		else
			L:Fila(jefe .. Color("gris", ": nada que te mejore"), { sangria = 1 })
		end
	end
	if #misiones > 0 then
		L:Fila("Misiones de esta mazmorra (premio seguro, una sola vez)", { sangria = 1 })
		for _, p in ipairs(misiones) do L:Fila(Pieza(p), { sangria = 2, item = p.id }) end
	end
	if #bichos > 0 then
		L:Fila("Bichos de la mazmorra (cualquier enemigo)", { sangria = 1 })
		for _, p in ipairs(bichos) do L:Fila(Pieza(p, false), { sangria = 2, item = p.id }) end
	end
	L:Blanco()
	L:Fila("Pasadas = cuántas veces, en promedio, hay que entrar para que caiga. Máximo 5 entradas por hora.", { tipo = "nota" })
	Leyenda(L)
end

---------------------------------------------------------------- guías al 60
local function TextoFuente(f)
	if f.tipo == "mision" then return "misión «" .. tostring(f.n) .. "»" .. (f.zona and (" (" .. f.zona .. ")") or "") end
	if f.tipo == "botin" then
		if not f.jefe or f.jefe == "" then return format("bichos en %s · %s por bicho (NO VERIFICADO)", tostring(f.zona), Pct(f.pct)) end
		return format("%s en %s · %s", f.jefe, tostring(f.zona), Pct(f.pct)) .. TextoPasadas(f.pct)
	end
	if f.tipo == "profesion" then return format("fabricado: %s %s (NO VERIFICADO: la receta puede pedir materiales de banda)", tostring(f.prof), tostring(f.nivel or "")) end
	return "?"
end

local function SeccionBiS(L)
	local G, clase, nivel, lado, rol, etiqueta = Contexto(L)
	if not G then return end
	if rol:find("^custom:") then
		L:Fila("Usas una escala propia: la guía al 60 usa los pesos de las especializaciones. Elige una en los ajustes de equipo de Mamba.", { tipo = "nota" })
		return
	end
	local filas, faltan = E.BiS60(G, clase, rol, lado)
	L:Fila(Color("dudoso", "PROVISIONAL") .. format(": mejor equipo al 60 de JcE para %s, sin bandas (abren el 9-12-2026) y con datos de la beta. En orden: primero lo seguro.", E.NombreRol(rol, etiqueta)), { tipo = "titulo" })
	for i, f in ipairs(E.OrdenBiS(filas)) do
		L:Fila(format("%d. %s: %s", i, E.RANURA_NOMBRE[f.ranura] or "?", E.NombreObjeto(f.id)), { item = f.id })
		for j = 1, math.min(2, #f.fuentes) do L:Fila(TextoFuente(f.fuentes[j]), { sangria = 2, tipo = "nota" }) end
		for _, a in ipairs(E.AlternativasDe(filas, f.ranura)) do
			L:Fila((a.alternativa == "fabricado" and "o fabricada (mejor, pero NO VERIFICADO): " or "o de mazmorra: ") .. E.NombreObjeto(a.id)
				.. " · " .. TextoFuente(a.fuentes[1]), { sangria = 1, item = a.id })
		end
	end
	if faltan and #faltan > 0 then
		local t = {}
		for _, r in ipairs(faltan) do t[#t + 1] = E.RANURA_NOMBRE[r] end
		L:Blanco()
		L:Fila(Color("dudoso", "Sin pieza de misión o mazmorra en los datos para: ") .. table.concat(t, ", ") .. ".")
		for _, r in ipairs(faltan) do
			for _, a in ipairs(E.AlternativasDe(filas, r)) do
				L:Fila((E.RANURA_NOMBRE[r] or "?") .. ", fabricada (NO VERIFICADO): " .. E.NombreObjeto(a.id) .. " · " .. TextoFuente(a.fuentes[1]), { sangria = 1, item = a.id })
			end
		end
	end
	if not lado then L:Fila("No pude leer tu facción: hay misiones de las dos facciones en la lista.", { tipo = "nota" }) end
	L:Blanco()
	L:Fila("Lo fabricado solo sale como alternativa. Faltan las mazmorras sin datos abiertos (Profundidades de Roca Negra, La Masacre, Maraudon, Templo Sumergido y las nuevas de 35-60).", { tipo = "nota" })
	Leyenda(L)
end

local function SeccionJcJ(L)
	local G, clase, nivel, lado, rol, etiqueta = Contexto(L)
	if not G then return end
	if not lado then
		L:Fila("No pude leer tu facción: los conjuntos de honor cambian de nombre entre Horda y Alianza.", { tipo = "nota" })
		return
	end
	local j = E.JcJ(clase, rol, lado)
	L:Fila(Color("dudoso", "PROVISIONAL") .. format(": JcJ al 60 para %s (conjuntos de la beta del cliente, 22-10-2026).", E.NombreRol(rol, etiqueta)), { tipo = "titulo" })
	if j and j.azul then
		L:Fila(format("1) Conjunto azul (se compra con honor): %s.%s", j.azul.nombre, j.azul.nota and (" " .. j.azul.nota) or ""))
		for _, id in ipairs(j.azul.piezas) do L:Fila(E.NombreObjeto(id, E.JCJ_NOMBRES[id]), { sangria = 1, item = id }) end
	end
	if j and j.epico then
		L:Fila(format("2) Conjunto épico: %s. Cada pieza = la azul + un Sello Envalentonado del rango que pide.", j.epico.nombre))
		for _, id in ipairs(j.epico.piezas or {}) do L:Fila(E.NombreObjeto(id, E.JCJ_NOMBRES[id]), { sangria = 1, item = id }) end
	end
	L:Blanco()
	L:Fila("Qué da cada rango (Blizzard, 7-10-2026):", { tipo = "titulo" })
	for _, r in ipairs(E.RANGOS_JCJ) do L:Fila(format("Rango %d: %s", r[1], r[2]), { sangria = 1 }) end
	L:Blanco()
	L:Fila("Orden sugerido: abalorio JcJ (rango 2), capa (3) y collar (4) primero; después el conjunto azul con honor; y las fichas épicas a medida que subes de rango (8 a 14). Los puntos de rango tienen tope semanal.")
	Leyenda(L)
end

local function SeccionRol(L)
	local G, clase, nivel, lado, rol, etiqueta, origen = Contexto(L)
	if not G then return end
	L:Fila(format("Rol en uso: %s (según %s).", E.NombreRol(rol, etiqueta), ORIGEN[origen] or tostring(origen)), { tipo = "titulo" })
	L:Fila("Lo decide Mamba: tus talentos, o el que elijas en los ajustes de equipo de Mamba. Así esta ventana y la guía nunca opinan distinto.")
	local roles = E.Roles(G, clase)
	if #roles > 0 then
		L:Blanco()
		L:Fila("Roles de tu clase:", { tipo = "titulo" })
		for _, r in ipairs(roles) do
			L:Fila(r.nombre .. (r.clave == rol and Color("bueno", "  ← el que se usa") or ""), { sangria = 1 })
		end
	end
end

local function SeccionFuentes(L)
	L:Fila("De dónde sale cada dato", { tipo = "titulo" })
	L:Fila("Pesos, rol, estadísticas y comparación con lo puesto: Mamba (GPL-3.0), con simulaciones de wowsims (MIT).")
	L:Fila("Botín, % de caída y misiones: ForeverLevelingBiS de Thunder (MIT), datos de la beta del 13-10-2026.")
	L:Fila("Niveles de mazmorra y tope de 5 entradas por hora: Warcraft Tavern (16-11-2026).")
	L:Fila("Conjuntos JcJ: tablas del cliente de Forever 1.60.1.70532 (wago.tools). Rangos: Blizzard, 7-10-2026.")
	L:Fila("Nombres en español: los del propio juego (caché del cliente, sus tablas en esMX y ForeverTDB). Con «*», sin traducción.")
	L:Fila("Entradas de las mazmorras y la flecha: la base de mazmorras de Mamba.")
	L:Fila("Créditos completos: archivos LICENSE y LICENSE-DATA.txt del addon. Este addon no está hecho ni respaldado por Blizzard.", { tipo = "nota" })
end

---------------------------------------------------------------- lo que lee la ventana
E.Secciones = {
	{ clave = "revisar", nombre = "Mi equipo" },
	{ clave = "mazmorras", nombre = "Mazmorras" },
	{ clave = "60", nombre = "Al 60 (JcE)" },
	{ clave = "jcj", nombre = "JcJ" },
	{ clave = "rol", nombre = "Rol" },
	{ clave = "fuentes", nombre = "Fuentes" },
}

-- Lo que se escribe después de /equipo -> la sección.
function E.Alias(arg)
	local bajo = (arg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if bajo == "" or bajo == "revisar" then return "revisar" end
	if bajo:find("^mazmorra:") or bajo == "mazmorras:todas" then return bajo end
	if bajo:find("^mazmorra") or bajo == "dg" then return "mazmorras" end
	if bajo == "60" or bajo == "bis" or bajo == "jce" or bajo == "pve" then return "60" end
	if bajo == "jcj" or bajo == "pvp" then return "jcj" end
	if bajo:find("^rol") then return "rol" end
	if bajo:find("^fuente") or bajo:find("^credito") then return "fuentes" end
	return "revisar"
end

function E.Seccion(seccion, L)
	local base, detalle = (seccion or "revisar"):match("^([^:]*):?(.*)$")
	if base == "mazmorra" then SeccionMazmorra(L, detalle)
	elseif base == "mazmorras" then SeccionMazmorras(L, detalle == "todas")
	elseif base == "60" then SeccionBiS(L)
	elseif base == "jcj" then SeccionJcJ(L)
	elseif base == "rol" then SeccionRol(L)
	elseif base == "fuentes" then SeccionFuentes(L)
	else SeccionRevisar(L) end
end

-- /equipo [sección]: abre la ventana. Sin la ventana (Asistente viejo), las filas van al chat.
function E.Comando(arg)
	if A and A.AbrirVentana then
		A.AbrirVentana("equipo", E.Alias(arg))
		return
	end
	local L = { filas = {} }
	function L:Fila(t, o) o = o or {}; o.texto = t or ""; self.filas[#self.filas + 1] = o; return o end
	function L:Blanco() return self:Fila("", { blanco = true }) end
	local ok, err = pcall(E.Seccion, E.Alias(arg), L)
	if not ok then L:Fila("algo cambió en Mamba y no pude terminar (" .. tostring(err):sub(1, 120) .. "). Avísale a Claude con este texto.") end
	for _, o in ipairs(L.filas) do
		if not o.blanco then
			local t = string.rep("   ", o.sangria or 0) .. o.texto
			if A and A.Decir then A.Decir(t) elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("Equipo: " .. t) end
		end
	end
end

if A and A.Registrar then A.Registrar("equipo", E) end
