-- Mamba_Plan: el asistente de inicio. Una ventana de Mamba (con el marco de Polestar) que sale la primera vez
-- que el personaje entra con Mamba, aunque ya juegue, y desde "Mi plan › Cambiar mis respuestas". Cuatro pasos:
--   1. Rol (si la clase tiene más de uno) y para qué juegas (mazmorras, JcJ, oro).
--   2. Build: la recomendada para ese rol y las de autores conocidos, con su fuente al pasar el ratón.
--   3. Profesiones: Mamba recomienda y dice por qué (clase, rol, raza, objetivo) y lo que cuestan; tú eliges.
-- La clase y la raza las lee del juego. Lo que elijas se guarda por personaje y arma "Mi plan".
-- Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas

local ROLES_CLASE = {
	DRUID = { "sanar", "tanque", "danio" }, PALADIN = { "sanar", "tanque", "danio" }, PRIEST = { "sanar", "danio" },
	SHAMAN = { "sanar", "danio" }, WARRIOR = { "tanque", "danio" }, HUNTER = { "danio" }, MAGE = { "danio" },
	WARLOCK = { "danio" }, ROGUE = { "danio" },
}
M.ROLES_CLASE = ROLES_CLASE
local ROL = {
	sanar = { "Sanar", "Te buscan para mazmorras." },
	tanque = { "Tanque", "Grupos rápidos; pide más equipo." },
	danio = { "Daño", "El más cómodo para subir solo." },
}
local ESTILO = {
	{ "jce", "Mazmorras", "Equipo de mazmorra y bandas al 60." },
	{ "jcj", "JcJ", "Campos de batalla y mundo abierto." },
	{ "oro", "Oro", "Farmear y vender. La montura antes." },
}
local ANCHO, ALTO = 620, 520

local v, pagina, borrador = nil, 1, nil
local PASOS = 4
local filas = {}

local function limpiar()
	for _, f in ipairs(filas) do f:Hide() end
	filas = {}
end

-- Tarjeta para elegir: fila con su título, su línea y una marca si está elegida.
local function tarjeta(padre, ancho, titulo, linea, elegida, alClic, ayuda)
	local f = P.Fila(padre, ancho, 46)
	f.marca = P.Relleno(f, "padSelect")
	if not elegida then f.marca:Hide() end
	local t = P.Texto(f, "body", elegida and "accent" or "text")
	t:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -7)
	t:SetPoint("RIGHT", f, "RIGHT", -12, 0)
	t:SetText(titulo)
	local l = P.Texto(f, "note", "textDim")
	l:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -3)
	l:SetPoint("RIGHT", f, "RIGHT", -12, 0)
	l:SetText(linea or "")
	f:SetScript("OnClick", alClic)
	if ayuda then
		f:SetScript("OnEnter", function(self)
			local A = _G.Asistente
			if A and A.CuadroAyuda then A.CuadroAyuda(self, ayuda[1], ayuda[2]) end
		end)
		f:SetScript("OnLeave", function() local A = _G.Asistente; if A and A.OcultarAyuda then A.OcultarAyuda() end end)
	end
	filas[#filas + 1] = f
	return f
end

local function titulo(padre, texto, y, x)
	local t = P.Texto(padre, "heading", "text")
	t:SetPoint("TOPLEFT", padre, "TOPLEFT", x or 0, -y)
	t:SetText(texto)
	filas[#filas + 1] = t
	return t
end

local dibujar -- adelante

local USO_TEXTO = { subir = "para subir de nivel", mazmorra = "mazmorras al 60", jcj = "JcJ al 60", banda = "bandas al 60" }
local ROL_TEXTO = { sanar = "sanar", tanque = "tanque", danio = "daño" }

-- "puntos: Equilibrio 41 · Feral 0 · Restauración 10", con los nombres de los árboles que da el juego.
function M.TextoReparto(e, reparto)
	local n = {}
	for x in tostring(reparto or ""):gmatch("%d+") do n[#n + 1] = x end
	local partes = {}
	for i, x in ipairs(n) do
		local nombre = e.talentos and e.talentos[i] and e.talentos[i].nombre
		partes[#partes + 1] = ((nombre and nombre ~= "") and nombre or ("árbol " .. i)) .. " " .. x
	end
	return #partes > 0 and ("puntos: " .. table.concat(partes, " · ")) or ""
end

local function nombreArbol(e, i)
	local t = e.talentos and e.talentos[i]
	return (t and t.nombre and t.nombre ~= "") and t.nombre or ("árbol " .. tostring(i))
end

-- Las builds para elegir, ya en grupos y en orden, con UNA recomendada (la de tu rol y tu meta).
-- -> { { grupo = "...", lista = { { clave, nombre, linea, tag, ayuda } } } }
local function buildsDe(e, r)
	r = r or {}
	local grupos = {}
	-- 1) la que tienes ahora
	local pts = {}
	for i, t in ipairs(e.talentos or {}) do pts[i] = t.puntos or 0 end
	local suma = 0
	for _, x in ipairs(pts) do suma = suma + x end
	if suma > 0 then
		grupos[#grupos + 1] = { grupo = "La que tienes", lista = { { clave = "ahora", nombre = "La que tengo ahora",
			linea = M.TextoReparto(e, table.concat(pts, "/")), tag = "" } } }
	end
	-- 2) las del addon (Asistente_Clase), en "Para subir de nivel" y "Al 60"
	local C = M.Fuentes.Clase()
	local subir, al60 = {}, {}
	local estilo = r.estilo or "jce"
	local meta = e.nivel < 60 and "subir" or (M.USO_DE_ESTILO[estilo] or "mazmorra")
	local recomendada
	if C and C.Builds then
		local ok, lista = pcall(C.Builds, e.clase)
		for _, b in ipairs(ok and lista or {}) do
			local f = type(b.fuente) == "table" and b.fuente or {}
			local item = { clave = "clase:" .. tostring(b.clave),
				nombre = nombreArbol(e, b.spec) .. " · " .. (USO_TEXTO[b.uso] or b.uso or "") .. " · " .. (ROL_TEXTO[b.rol] or ""),
				linea = M.TextoReparto(e, b.reparto), tag = "", rol = b.rol, uso = b.uso,
				ayuda = { nombreArbol(e, b.spec), { b.nota or "", (f.nombre or "") .. (f.autor and (", " .. f.autor) or ""), f.fecha or "", f.url or "" } } }
			if not recomendada and b.rol == r.rol and b.uso == meta then recomendada = item end
			if b.uso == "subir" then subir[#subir + 1] = item else al60[#al60 + 1] = item end
		end
		-- sin una exacta: la de tu rol para tu meta más cercana
		if not recomendada then
			for _, l in ipairs({ subir, al60 }) do for _, it in ipairs(l) do if not recomendada and it.rol == r.rol then recomendada = it end end end
		end
	end
	if recomendada then
		recomendada.tag = "recomendada"
		recomendada.porque = ("Es la de %s %s: lo que elegiste en el paso 1."):format(ROL_TEXTO[recomendada.rol] or "", USO_TEXTO[recomendada.uso] or "")
		recomendada.linea = recomendada.porque .. "  " .. recomendada.linea
	end
	local function primeroRecomendada(l)
		table.sort(l, function(a, b)
			if (a == recomendada) ~= (b == recomendada) then return a == recomendada end
			if (a.rol == r.rol) ~= (b.rol == r.rol) then return a.rol == r.rol end
			return a.nombre < b.nombre
		end)
	end
	primeroRecomendada(subir)
	primeroRecomendada(al60)
	if #subir > 0 then grupos[#grupos + 1] = { grupo = "Para subir de nivel", lista = subir } end
	if #al60 > 0 then grupos[#grupos + 1] = { grupo = "Al 60", lista = al60 } end
	-- 3) de jugadores conocidos, las de tu rol primero
	local palabras = { sanar = { "sana", "cura" }, tanque = { "tanque" }, danio = { "daño" } }
	local function esDeRol(b)
		for _, p in ipairs(palabras[r.rol or ""] or {}) do if b.uso:lower():find(p, 1, true) then return true end end
		return false
	end
	local conocidas = {}
	for i, b in ipairs(M.CONOCIDAS or {}) do
		if b.clase == e.clase then
			conocidas[#conocidas + 1] = { clave = "conocida:" .. i, nombre = b.uso .. " · " .. b.autor,
				linea = M.TextoReparto(e, b.reparto) .. " · " .. b.destaca, tag = "de un jugador conocido", deRol = esDeRol(b),
				ayuda = { b.autor, { b.destaca, "Talentos clave: " .. b.clave, b.url, b.fecha } } }
		end
	end
	table.sort(conocidas, function(a, b) if a.deRol ~= b.deRol then return a.deRol end return a.nombre < b.nombre end)
	if #conocidas > 0 then grupos[#grupos + 1] = { grupo = "De jugadores conocidos", lista = conocidas } end
	return grupos, recomendada
end
M.BuildsDe = buildsDe

-- El rol de cada árbol de talentos, en el orden del juego (para "Como juego ahora").
local ROL_DE_ARBOL = {
	DRUID = { "danio", "danio", "sanar" }, PALADIN = { "sanar", "tanque", "danio" }, PRIEST = { "sanar", "sanar", "danio" },
	SHAMAN = { "danio", "danio", "sanar" }, WARRIOR = { "danio", "danio", "tanque" },
}
-- Lo que se ve hoy: el árbol con más puntos (y su rol). El combate feral del druida es gato y oso: daño con
-- tanque de segundo. -> { arbol, nombre, rol, rol2 } | nil sin puntos
function M.ComoJuegaAhora(e)
	local mejor, idx = 0, nil
	for i, t in ipairs(e.talentos or {}) do if (t.puntos or 0) > mejor then mejor, idx = t.puntos, i end end
	if not idx then return nil end
	local rol = (ROL_DE_ARBOL[e.clase] or {})[idx] or "danio"
	local rol2 = (e.clase == "DRUID" and idx == 2) and "tanque" or nil
	return { arbol = idx, nombre = e.talentos[idx].nombre, rol = rol, rol2 = rol2 }
end

local function pasoRol(cuerpo, ancho, e)
	local y = 0
	local roles = ROLES_CLASE[e.clase] or { "danio" }
	local ahora = M.ComoJuegaAhora(e)
	titulo(cuerpo, "Rol", y); y = y + 24
	local function fijar(r, r2, modo) borrador.rol, borrador.rol2, borrador.modoRol = r, r2, modo; dibujar() end
	if ahora then
		local f = tarjeta(cuerpo, ancho, "Como juego ahora: " .. ahora.nombre,
			"Lo leí de tus talentos: " .. ROL[ahora.rol][1]:lower() .. (ahora.rol2 and (" y " .. ROL[ahora.rol2][1]:lower()) or "") .. ".",
			borrador.modoRol == "ahora", function() borrador.spec = ahora.nombre; fijar(ahora.rol, ahora.rol2, "ahora") end)
		f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
	end
	for _, r in ipairs(roles) do
		local f = tarjeta(cuerpo, ancho, ROL[r][1], ROL[r][2], borrador.modoRol == "uno" and borrador.rol == r,
			function() fijar(r, nil, "uno") end)
		f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
	end
	if #roles > 1 then
		local f = tarjeta(cuerpo, ancho, "Mixto", "Uno principal y otro de segundo (por ejemplo, oso y gato, o daño con algo de curación).",
			borrador.modoRol == "mixto", function()
				local r2 = borrador.rol2
				if not r2 or r2 == borrador.rol then for _, x in ipairs(roles) do if x ~= borrador.rol then r2 = x; break end end end
				fijar(borrador.rol or roles[1], r2, "mixto")
			end)
		f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
		if borrador.modoRol == "mixto" then
			-- principal y de segundo: dos filas de botones
			for k, cual in ipairs({ "rol", "rol2" }) do
				local t = P.Texto(cuerpo, "label", "textDim")
				t:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 12, -(y + 4))
				t:SetText(k == 1 and "Principal:" or "De segundo:")
				filas[#filas + 1] = t
				local x = 110
				for _, r in ipairs(roles) do
					local b = P.Boton(cuerpo, ROL[r][1] .. (borrador[cual] == r and "  ✓" or ""), function()
						borrador[cual] = r
						if borrador.rol == borrador.rol2 then for _, o in ipairs(roles) do if o ~= r then borrador[cual == "rol" and "rol2" or "rol"] = o; break end end end
						dibujar()
					end, borrador[cual] == r)
					b:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", x, -y)
					x = x + b:GetWidth() + 6
					filas[#filas + 1] = b
				end
				y = y + 28
			end
		end
	elseif not borrador.rol then
		borrador.rol, borrador.modoRol = roles[1], "uno"
	end
	-- especialización por nombre (los árboles de tu clase, como los nombra el juego)
	y = y + 6
	local t = P.Texto(cuerpo, "label", "textDim")
	t:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -(y + 4))
	t:SetText("Especialización:")
	filas[#filas + 1] = t
	local x = 110
	for _, ar in ipairs(e.talentos or {}) do
		if ar.nombre and ar.nombre ~= "" then
			local b = P.Boton(cuerpo, ar.nombre .. (borrador.spec == ar.nombre and "  ✓" or ""), function()
				borrador.spec = (borrador.spec ~= ar.nombre) and ar.nombre or nil
				dibujar()
			end, borrador.spec == ar.nombre)
			b:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", x, -y)
			x = x + b:GetWidth() + 6
			filas[#filas + 1] = b
		end
	end
	return y + 34
end

-- Varias a la vez, cada una principal o de segundo: un clic la suma como principal, otro la pasa a
-- segunda, otro la saca. Siempre queda al menos una.
local function pasoEstilo(cuerpo, ancho)
	local y = 0
	titulo(cuerpo, "Para qué juegas (elige todas las que quieras)", y); y = y + 24
	borrador.estilos = borrador.estilos or {}
	local ES = borrador.estilos
	for _, s in ipairs(ESTILO) do
		local p = ES[s[1]]
		local tag = p == 1 and "  ·  principal" or (p == 2 and "  ·  de segundo" or "")
		local f = tarjeta(cuerpo, ancho, s[2] .. tag, s[3], p ~= nil, function()
			if p == nil then ES[s[1]] = 1 elseif p == 1 then ES[s[1]] = 2 else ES[s[1]] = nil end
			if not next(ES) then ES[s[1]] = 1 end
			dibujar()
		end)
		f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
	end
	local n = P.Texto(cuerpo, "note", "textMuted")
	n:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -(y + 6))
	n:SetWidth(ancho)
	n:SetText("Un clic: principal. Otro: de segundo. Otro: la quitas. El plan junta todas: el equipo que sirve para mazmorras y JcJ, y profesiones que también dan oro.")
	filas[#filas + 1] = n
	-- compatibilidad: estilo = la principal (la primera de las principales)
	borrador.estilo = nil
	for _, s in ipairs(ESTILO) do if ES[s[1]] == 1 and not borrador.estilo then borrador.estilo = s[1] end end
	if not borrador.estilo then for _, s in ipairs(ESTILO) do if ES[s[1]] and not borrador.estilo then borrador.estilo = s[1] end end end
	return y + 60
end

local function subtitulo(cuerpo, texto, y)
	local t = P.Texto(cuerpo, "label", "accent")
	t:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y)
	t:SetText(texto)
	filas[#filas + 1] = t
end

local function paso2(cuerpo, ancho, e)
	local y = 0
	local grupos, rec = buildsDe(e, borrador)
	if #grupos == 0 then
		local t = P.Texto(cuerpo, "body", "textDim")
		t:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y)
		t:SetWidth(ancho)
		t:SetText("Todavía no hay builds para tu clase en Mamba. Sigue sin elegir: el plan usa tu rol.")
		filas[#filas + 1] = t
		return y + 20
	end
	if not borrador.build and rec then borrador.build = rec.clave end
	for _, g in ipairs(grupos) do
		subtitulo(cuerpo, g.grupo, y); y = y + 20
		for _, b in ipairs(g.lista) do
			local f = tarjeta(cuerpo, ancho, b.nombre .. ((b.tag ~= "") and ("  ·  " .. b.tag) or ""), b.linea,
				borrador.build == b.clave, function() borrador.build = b.clave; dibujar() end, b.ayuda)
			f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
		end
		y = y + 6
	end
	return y
end

local function paso3(cuerpo, ancho, e)
	local y = 0
	local tiene = {}
	for _, p in ipairs(e.profesiones) do
		if M.PRIMARIAS[p.nombre] then tiene[#tiene + 1] = p.nombre .. " " .. p.rango end
	end
	titulo(cuerpo, #tiene > 0 and ("Tienes " .. table.concat(tiene, " y ") .. ". Elige tu pareja:") or "Elige tu pareja de profesiones:", y)
	y = y + 26
	local USO = { subir = "para subir de nivel", mazmorra = "para mazmorras", jcj = "para JcJ", oro = "para ganar oro", ya = "las que tienes" }
	local lista = M.ProfesionesRecomendadas(e, borrador)
	-- UNA recomendada: la de tu meta principal (paso 2); si no hay, la primera
	local principal = M.USO_DE_ESTILO[borrador.estilo or "jce"] or "mazmorra"
	local rec
	for _, x in ipairs(lista) do if x.uso == principal then rec = x end end
	rec = rec or lista[1]
	if not borrador.profesiones and rec then borrador.profesiones = table.concat(rec.par, " + ") end
	for _, x in ipairs(lista) do
		local clave = table.concat(x.par, " + ")
		local costo = {}
		for _, pr in ipairs(x.par) do
			local c = M.CostoProfesion(e, pr)
			if c and c.rangosOro > 0 then costo[#costo + 1] = pr .. ": instructores " .. M.Dinero(c.rangosOro) end
		end
		local porque = x == rec and ("Recomendada " .. (USO[x.uso] or "") .. ", tu meta principal: ") or ((USO[x.uso] or "") .. ": ")
		local linea = porque .. x.porque .. (x.raza and ("  Tu raza: " .. x.raza) or "")
		local ayuda = { clave, {} }
		for _, fte in ipairs(x.fuentes) do table.insert(ayuda[2], fte) end
		if #costo > 0 then table.insert(ayuda[2], table.concat(costo, " · ")) end
		if x.tiene > 0 then table.insert(ayuda[2], "Ya tienes " .. x.tiene .. " de las dos.") end
		local etiqueta = (x == rec and "  ·  recomendada" or "") .. (x.tiene == #x.par and "  ·  ya las tienes" or "")
		local f = tarjeta(cuerpo, ancho, clave .. etiqueta, linea, borrador.profesiones == clave,
			function() borrador.profesiones = clave; dibujar() end, ayuda)
		f:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -y); y = y + 50
	end
	local nota = P.Texto(cuerpo, "note", "textMuted")
	nota:SetPoint("TOPLEFT", cuerpo, "TOPLEFT", 0, -(y + 6))
	nota:SetWidth(ancho)
	nota:SetText("Pasa el ratón por una opción: de dónde sale el consejo y lo que cuestan los instructores.")
	filas[#filas + 1] = nota
	return y + 30
end

function dibujar()
	if not v then return end
	limpiar()
	local e = M.Estado()
	local ancho = ANCHO - 2 * (v.margen or 16)
	v.titulo:SetText(pagina == 1 and ("¿Qué quieres que sea " .. (e.nombre or "tu personaje") .. "?")
		or pagina == 2 and "Para qué juegas" or pagina == 3 and "Tu build" or "Tus profesiones")
	v.sub:SetText(("%s %s, nivel %d. Mamba arma tu plan con esto; lo cambias cuando quieras."):format(
		(e.claseNombre or ""), (e.razaNombre or ""):lower(), e.nivel))
	local alto
	if pagina == 1 then alto = pasoRol(v.cuerpoF, ancho, e)
	elseif pagina == 2 then alto = pasoEstilo(v.cuerpoF, ancho)
	elseif pagina == 3 then alto = paso2(v.cuerpoF, ancho, e)
	else alto = paso3(v.cuerpoF, ancho, e) end
	if v.sf then
		local _, _, W = P.Polestar()
		v.cuerpoF:SetHeight(math.max(1, alto or 400))
		if W and W.SetScrollContent then W.SetScrollContent(v.sf, (alto or 400) + 8, v.sf:GetHeight()) end
		if W and W.ScrollTo then W.ScrollTo(v.sf, 0) end
	end
	v.paso:SetText(("Paso %d de %d"):format(pagina, PASOS))
	v.atras:SetShown(pagina > 1)
	if v.siguiente.Label then v.siguiente.Label:SetText(pagina < PASOS and "Siguiente" or "Listo")
	elseif v.siguiente.SetText then v.siguiente:SetText(pagina < PASOS and "Siguiente" or "Listo") end
end

local function terminar()
	local pj = M.PJ()
	pj.respuestas = borrador
	pj.respondido = true
	v:Hide()
	M.Cambio()
	if M.AbrirPlan then M.AbrirPlan() end
end

local function crear()
	v = P.Ventana("MambaPlanInicio", "Mamba", ANCHO, ALTO)
	local m, top = v.margen or 16, v.cuerpo or 26
	v.sub = P.Texto(v, "body", "textDim")
	v.sub:SetPoint("TOPLEFT", v, "TOPLEFT", m, -(top + 4))
	v.sub:SetPoint("RIGHT", v, "RIGHT", -m, 0)
	local _, _, W = P.Polestar()
	if W and W.Scroll then
		v.sf = W.Scroll(v)
		v.sf:SetPoint("TOPLEFT", v, "TOPLEFT", m, -(top + 30))
		v.sf:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -m + 8, 56)
		v.cuerpoF = v.sf.Child
		v.cuerpoF:SetWidth(ANCHO - 2 * m - 10)
	else
		v.cuerpoF = CreateFrame("Frame", nil, v)
		v.cuerpoF:SetPoint("TOPLEFT", v, "TOPLEFT", m, -(top + 30))
		v.cuerpoF:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -m, 56)
	end
	v.atras = P.Boton(v, "Atrás", function() pagina = math.max(1, pagina - 1); dibujar() end)
	v.atras:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", m, 14)
	v.siguiente = P.Boton(v, "Siguiente", function()
		if pagina < PASOS then pagina = pagina + 1; dibujar() else terminar() end
	end, true)
	v.siguiente:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -m, 14)
	v.paso = P.Texto(v, "note", "textMuted")
	v.paso:SetPoint("BOTTOM", v, "BOTTOM", 0, 20)
end

function M.AbrirInicio()
	if not v then crear() end
	local pj = M.PJ()
	borrador = {}
	for k, x in pairs(pj.respuestas or {}) do borrador[k] = x end
	if not borrador.estilos then borrador.estilos = { [borrador.estilo or "jce"] = 1 } end
	if not borrador.modoRol and borrador.rol then borrador.modoRol = borrador.rol2 and "mixto" or "uno" end
	-- sin respuesta todavía: de entrada, "como juego ahora" (nunca obliga a elegir algo que no lo representa)
	if not borrador.rol then
		local ahora = M.ComoJuegaAhora(M.Estado())
		if ahora then
			borrador.rol, borrador.rol2, borrador.modoRol, borrador.spec = ahora.rol, ahora.rol2, "ahora", ahora.nombre
		end
	end
	pagina = 1
	v:Show()
	dibujar()
end

-- Primera vez con Mamba: se abre sola, fuera de combate, unos segundos después de entrar (no encima del
-- asistente de Polestar si está a la vista).
local ev = CreateFrame("Frame")
M.Escuchar(ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
	if M.PJ().respondido then return end
	local function intentar(n)
		if (InCombatLockdown and InCombatLockdown()) or (_G.PolestarWelcome and _G.PolestarWelcome:IsShown()) then
			if n < 20 then C_Timer.After(15, function() intentar(n + 1) end) end
			return
		end
		M.Proteger("inicio", M.AbrirInicio)
	end
	C_Timer.After(6, function() intentar(0) end)
end)
