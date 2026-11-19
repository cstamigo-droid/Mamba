-- Asistente/SecTalentos.lua (K109): el planificador visual de talentos y las tarjetas de profesiones.
--   · Clase › Talentos y la entrada «Talentos» del riel de Polestar muestran LO MISMO: los 3 árboles como en el
--     juego (íconos reales, puntos de la build, flechas), una regla de niveles que se puede tocar, «Comparar con
--     mis talentos» y, al pasar el ratón, qué hace cada talento y por qué la build lo toma.
--     La entrada «Talentos» reemplaza la de Polestar, que decía «Próximamente» (T.SOON): un solo planificador.
--   · Clase › Profesiones: una tarjeta por objetivo con su porqué, su costo y «Elegir» (va a Mi plan).
-- Datos: Asistente_Clase (Datos_Builds, Datos_Arbol, Datos_Profesiones). Solo aconseja: no cambia talentos.
-- Colores por su nombre en la apariencia de Polestar (E3); el cuadro de ayuda es el del juego, con TipColor.
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local Hub = A.Hub
local floor, min, max, format = math.floor, math.min, math.max, string.format

local CV = {}
A.ClaseVista = CV

local function PS() local p = _G.Polestar; return type(p) == "table" and p or nil end
local function W() local p = PS(); return p and p.Widgets end
local function Theme() local p = PS(); return p and p.Theme end
local function M() return A.modulos and A.modulos.clase end
local function Cl() local m = M(); return m and m.C end

-- El nivel puede venir secreto en Forever (K110): nunca `UnitLevel() or 1` ni comparaciones sobre un secreto.
local function legible(v)
	if issecretvalue and issecretvalue(v) then return nil end
	return type(v) == "number" and v or nil
end
local function miNivel() return legible(UnitLevel and UnitLevel("player")) or 60 end
local function miClase() local _, c = UnitClass("player"); return c end

-- Una pieza propia dentro del constructor V del hub, con el mismo reciclado que las suyas (Hub.lua: pool).
local function pieza(V, tipo, crear)
	local p = V.pools[tipo]
	if not p then p = { n = 0 }; V.pools[tipo] = p end
	p.n = p.n + 1
	local o = p[p.n]
	if not o then o = crear(V.child); p[p.n] = o end
	o:ClearAllPoints()
	o:Show()
	return o
end

local function tex(padre, capa, color, alpha)
	local t = padre:CreateTexture(nil, capa or "ARTWORK")
	local T = Theme()
	t:SetTexture(T and T.Media and T.Media("white") or "Interface\\Buttons\\WHITE8X8")
	if color then W().Color(t, color, alpha) end
	return t
end

local function texto(padre, rol, col)
	local fs = W().Text(padre, rol, col)
	return fs
end

local function tipColor(nombre)
	local T = Theme()
	if T and T.TipColor then return T.TipColor(nombre) end
	return 0.8, 0.8, 0.8
end

---------------------------------------------------------------- talentos: nombres, íconos y hechizos
local hechizos = {}
local function hechizoDe(clase, nodo, n)
	if n[1] and n[1] > 0 then return n[1] end
	if hechizos[nodo] ~= nil then return hechizos[nodo] or nil end
	local id, supo = false, false
	-- los 6 talentos nuevos que Polestar no trae: el juego da su hechizo por la entrada (solo tu clase)
	if clase == miClase() and C_ClassTalents and C_Traits then
		pcall(function()
			local config = C_ClassTalents.GetActiveConfigID()
			if not config then return end
			supo = true
			local e = C_Traits.GetEntryInfo(config, n[6])
			local def = e and e.definitionID and C_Traits.GetDefinitionInfo(e.definitionID)
			if def and def.spellID then id = def.spellID end
		end)
	end
	-- se recuerda solo si el juego ya tenía tus talentos cargados (si no, se vuelve a preguntar en el próximo dibujo)
	if supo or clase ~= miClase() then hechizos[nodo] = id end
	return id or nil
end

local function nombreHechizo(id)
	if not id then return nil end
	local ok, n = pcall(function()
		if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
		return GetSpellInfo and (GetSpellInfo(id))
	end)
	return ok and type(n) == "string" and n ~= "" and n or nil
end

local function iconoHechizo(id)
	local t
	if id then
		pcall(function()
			t = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)) or (GetSpellTexture and GetSpellTexture(id))
		end)
	end
	return t or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function CV.NombreTalento(clase, nodo)
	local C = Cl()
	local Ar = C and C.Arbol(clase)
	local n = Ar and Ar.nodos[nodo]
	if not n then return tostring(nodo) end
	return nombreHechizo(hechizoDe(clase, nodo, n)) or n[7]
end

---------------------------------------------------------------- estado de la vista
local function buildsDe(clase)
	local C = Cl()
	return C and C.Builds(clase) or {}
end

-- La build elegida (o la primera que calza con tus talentos, o la primera de la lista).
local function buildElegida(est, clase)
	local lista = buildsDe(clase)
	for _, b in ipairs(lista) do if b.clave == est.build then return b end end
	local C = Cl()
	if clase == miClase() and C then
		local ok, rangos = pcall(C.LeerTalentos, clase)
		local spec = ok and rangos and C.SpecPrincipal(clase, rangos)
		local datos = C.Arbol(clase)
		if spec and datos then
			for _, b in ipairs(lista) do
				if datos.specs[b.spec] == spec then est.build = b.clave; return b end
			end
		end
	end
	if lista[1] then est.build = lista[1].clave end
	return lista[1]
end

local function claseVista(est)
	local C = Cl()
	local c = est.clase or miClase()
	if not (C and C.Arbol(c)) then c = miClase() end
	return c
end

-- La barra lateral: las builds de la clase que se mira, con su nombre corto y lo que las diferencia.
function CV.Nav(est)
	local C = Cl()
	if not C then return {}, nil end
	local clase = claseVista(est)
	local b = buildElegida(est, clase)
	local items = {}
	for _, x in ipairs(buildsDe(clase)) do
		local corto, dif = C.NombreCortoBuild(clase, x)
		items[#items + 1] = { key = x.clave, label = corto, count = dif }
	end
	return items, b and b.clave
end

function CV.OnNav(est, key)
	est.build = key
	est.nivel = nil
end

---------------------------------------------------------------- la regla de niveles (51 marcas que se tocan)
local function regla(V, est, b, n, alCambiar)
	local o = pieza(V, "talRegla", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.M, f.N = {}, {}
		for i = 1, 6 do f.N[i] = texto(f, "small", "textMuted") end
		return f
	end)
	local ancho = V.ancho
	local total = #b.picks
	local paso = ancho / max(1, total)
	for i = 1, max(total, #o.M) do
		local m = o.M[i]
		if i <= total then
			if not m then
				m = CreateFrame("Button", nil, o)
				m.T = tex(m, "ARTWORK")
				m.T:SetPoint("TOPLEFT", m, "TOPLEFT", 0, 0)
				m.T:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT", -2, 0)
				o.M[i] = m
			end
			m:ClearAllPoints()
			m:SetPoint("TOPLEFT", o, "TOPLEFT", floor((i - 1) * paso), -16)
			m:SetSize(max(3, floor(paso)), 12)
			if i == n then W().Color(m.T, "accent")
			elseif i < n then W().Color(m.T, "textDim", 0.75)
			else W().Color(m.T, "textMuted", 0.3) end
			local nivel = 9 + i
			m:SetScript("OnClick", function() alCambiar(nivel); Hub.Redibujar() end)
			m:SetScript("OnEnter", function(self)
				if not GameTooltip then return end
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:SetText("Nivel " .. nivel, 1, 1, 1)
				local r, g, bb = tipColor("textDim")
				GameTooltip:AddLine(CV.NombreTalento(est.claseMostrada, b.picks[i]), r, g, bb, true)
				GameTooltip:Show()
			end)
			m:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
			m:Show()
		elseif m then
			m:Hide()
		end
	end
	for j, nv in ipairs({ 10, 20, 30, 40, 50, 60 }) do
		local fs = o.N[j]
		local i = nv - 9
		fs:ClearAllPoints()
		fs:SetPoint("TOPLEFT", o, "TOPLEFT", min(ancho - 14, floor((i - 1) * paso)), 0)
		fs:SetText(tostring(nv))
		W().Color(fs, (9 + n >= nv and 9 + n < nv + 10) and "text" or "textMuted")
	end
	V:_colocar(o, 34)
end

---------------------------------------------------------------- el árbol
local function crearArbolPanel(p)
	local f = CreateFrame("Frame", nil, p)
	W().Fill(f, "panelAlt")
	f.Nombre = texto(f, "label", "text")
	f.Nombre:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
	f.Puntos = texto(f, "number", "textMuted")
	f.Puntos:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -8)
	f.Linea = W().Divider(f)
	f.Linea:ClearAllPoints()
	f.Linea:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -28)
	f.Linea:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -28)
	f.nodos, f.flechas = {}, {}
	return f
end

local function nodoBoton(panel, i)
	local b = panel.nodos[i]
	if b then return b end
	b = CreateFrame("Button", nil, panel)
	b.Borde = tex(b, "BACKGROUND")
	b.Borde:SetPoint("TOPLEFT", b, "TOPLEFT", -2, 2)
	b.Borde:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, -2)
	b.Ic = b:CreateTexture(nil, "ARTWORK")
	b.Ic:SetAllPoints(b)
	b.Ic:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	b.Fondo = tex(b, "OVERLAY")
	b.Fondo:SetSize(26, 14)
	b.Fondo:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 6, -6)
	W().Color(b.Fondo, "bg", 0.95)
	b.Rango = texto(b, "small", "text")
	b.Rango:SetDrawLayer("OVERLAY", 7)
	b.Rango:SetPoint("CENTER", b.Fondo, "CENTER", 0, 0)
	b:SetScript("OnEnter", function(self)
		local d = self.psDatos
		if not (d and GameTooltip) then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local ok = d.hechizo and pcall(GameTooltip.SetSpellByID, GameTooltip, d.hechizo)
		if not ok then GameTooltip:SetText(d.nombre or "", 1, 1, 1) end
		local r, g, bb = tipColor("textDim")
		local rt, gt, bt = tipColor("text")
		GameTooltip:AddLine(" ")
		if d.comparar then
			GameTooltip:AddLine(format("Tienes %d · esta build pide %d.", d.tengo or 0, d.quiero or 0), rt, gt, bt, true)
		end
		local C = Cl()
		local porque = C and C.PorQue(d.clase, d.b, d.nodo, function(x) return CV.NombreTalento(d.clase, x) end) or {}
		for k, l in ipairs(porque) do
			if k == 2 then GameTooltip:AddLine("Por qué esta build lo toma:", rt, gt, bt, true) end
			GameTooltip:AddLine(l, r, g, bb, true)
		end
		if d.pide and d.pide > 0 then GameTooltip:AddLine(format("Se abre con %d puntos en este árbol.", d.pide), r, g, bb, true) end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
	panel.nodos[i] = b
	return b
end

local function flecha(panel, i)
	local t = panel.flechas[i]
	if t then return t end
	t = { h = tex(panel, "BORDER"), v = tex(panel, "BORDER") }
	panel.flechas[i] = t
	return t
end

-- vista = { clase, b, n (puntos al nivel), comparar, mios, final }
local function arboles(V, vista)
	local C = Cl()
	local Ar = C.Arbol(vista.clase)
	local o = pieza(V, "talArboles", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.P = { crearArbolPanel(f), crearArbolPanel(f), crearArbolPanel(f) }
		return f
	end)
	local hueco = 10
	local ancho = floor((V.ancho - hueco * 2) / 3)
	local filas = 1
	for _, n in pairs(Ar.nodos) do if n[3] > filas then filas = n[3] end end
	local celda = min(54, floor((ancho - 16) / 4))
	local icono = max(26, celda - 18)
	local alto = 28 + 12 + filas * celda
	local rangos = vista.comparar and vista.mios or C.RangosHasta(vista.b, vista.n)
	local porArbol = C.PorArbol(vista.clase, rangos)
	local hasta = C.RangosHasta(vista.b, vista.n)
	for s = 1, 3 do
		local P = o.P[s]
		P:ClearAllPoints()
		P:SetPoint("TOPLEFT", o, "TOPLEFT", (s - 1) * (ancho + hueco), 0)
		P:SetSize(ancho, alto)
		P.Nombre:SetText(C.NombreSpecES(Ar.specs[s] or ""))
		P.Puntos:SetText(tostring(porArbol[s] or 0))
		W().Color(P.Puntos, (porArbol[s] or 0) > 0 and "text" or "textMuted")
		local ox = floor((ancho - 4 * celda) / 2) + floor((celda - icono) / 2)
		local pos, k = {}, 0
		for nodo, n in pairs(Ar.nodos) do
			if n[2] == s then
				k = k + 1
				local x, y = ox + (n[4] - 1) * celda, -(28 + 12 + (n[3] - 1) * celda)
				pos[nodo] = { x, y }
				local bt = nodoBoton(P, k)
				bt:ClearAllPoints()
				bt:SetPoint("TOPLEFT", P, "TOPLEFT", x, y)
				bt:SetSize(icono, icono)
				local hechizo = hechizoDe(vista.clase, nodo, n)
				bt.Ic:SetTexture(iconoHechizo(hechizo))
				local nombre = nombreHechizo(hechizo) or n[7]
				local d = { hechizo = hechizo, nombre = nombre, pide = Ar.pide[nodo], comparar = vista.comparar }
				local quiero = vista.final[nodo] or 0
				local estado, insignia
				if vista.comparar then
					estado, insignia = C.Estado(vista.final, vista.mios, nodo)
					d.tengo, d.quiero = vista.mios[nodo] or 0, quiero
				else
					local r = hasta[nodo] or 0
					estado = r > 0 and "tomado" or (quiero > 0 and "despues" or nil)
					insignia = r > 0 and (r .. "/" .. n[5]) or nil
				end
				local vivo = estado == "tomado" or estado == "bien" or estado == "sobra"
				bt.Ic:SetDesaturated(not vivo)
				bt.Ic:SetAlpha(vivo and 1 or (estado and 0.6 or 0.28))
				local borde = ({ tomado = "accent", bien = "success", sobra = "danger", falta = "warning", despues = "textMuted" })[estado]
				bt.Borde:SetShown(borde ~= nil)
				if borde then W().Color(bt.Borde, borde, estado == "despues" and 0.5 or 1) end
				bt.Fondo:SetShown(insignia ~= nil)
				bt.Rango:SetShown(insignia ~= nil)
				bt.Rango:SetText(insignia or "")
				if insignia then
					W().Color(bt.Rango, ({ bien = "success", sobra = "danger", falta = "warning" })[estado] or "text")
					bt.Fondo:SetWidth(max(18, (bt.Rango:GetStringWidth() or 12) + 6))
				end
				d.clase, d.b, d.nodo = vista.clase, vista.b, nodo
				bt.psDatos = d
				bt.psNodo = nodo
				bt.psEstado = estado
				bt:Show()
			end
		end
		for i = k + 1, #P.nodos do P.nodos[i]:Hide() end
		-- flechas: en línea recta (misma columna o misma fila) o en L (primero de lado, después hacia abajo)
		local f = 0
		for _, e in ipairs(Ar.flechas or {}) do
			local a, z = pos[e[1]], pos[e[2]]
			if a and z then
				f = f + 1
				local fl = flecha(P, f)
				local activa = vista.comparar and ((vista.mios[e[2]] or 0) > 0) or (not vista.comparar and (hasta[e[2]] or 0) > 0)
				local enBuild = (vista.final[e[2]] or 0) > 0
				local col, al = activa and "accent" or "textMuted", activa and 0.9 or (enBuild and 0.55 or 0.3)
				local mitad = floor(icono / 2)
				fl.h:ClearAllPoints(); fl.v:ClearAllPoints()
				if a[1] == z[1] then
					fl.h:Hide()
					fl.v:SetPoint("TOPLEFT", P, "TOPLEFT", a[1] + mitad - 1, a[2] - icono - 2)
					fl.v:SetSize(3, max(2, (a[2] - z[2]) - icono - 4))
					fl.v:Show()
				elseif a[2] == z[2] then
					fl.v:Hide()
					local x1 = min(a[1], z[1]) + icono + 2
					fl.h:SetPoint("TOPLEFT", P, "TOPLEFT", x1, a[2] - mitad + 1)
					fl.h:SetSize(max(2, math.abs(z[1] - a[1]) - icono - 4), 3)
					fl.h:Show()
				else
					local x1 = (z[1] > a[1]) and (a[1] + icono + 2) or (z[1] + mitad - 1)
					fl.h:SetPoint("TOPLEFT", P, "TOPLEFT", x1, a[2] - mitad + 1)
					fl.h:SetSize(max(2, math.abs(z[1] - a[1]) - mitad - 1), 3)
					fl.v:SetPoint("TOPLEFT", P, "TOPLEFT", z[1] + mitad - 1, a[2] - mitad + 1)
					fl.v:SetSize(3, max(2, (a[2] - z[2]) - mitad - 2))
					fl.h:Show(); fl.v:Show()
				end
				W().Color(fl.h, col, al); W().Color(fl.v, col, al)
			end
		end
		for i = f + 1, #P.flechas do P.flechas[i].h:Hide(); P.flechas[i].v:Hide() end
	end
	V:_colocar(o, alto)
	o.psVista = vista
end

---------------------------------------------------------------- la sección de talentos (Clase › Talentos y el riel)
local MOTIVOS = {
	sinclase = "tu clase no está en los datos",
	sinapi = "el juego no dio acceso a tus talentos",
	sinconfig = "el juego todavía no cargó tus talentos: abre la ventana de talentos una vez y vuelve",
	sinnodos = "el juego no reconoció tus talentos",
}

local function fuenteCorta(b)
	local f = b.fuente or {}
	local C = Cl()
	local nombre = C.FuenteCorta(b) or "?"
	local autor = f.autor and f.autor ~= "" and f.autor ~= nombre and f.autor or nil
	local fecha = f.fecha and f.fecha:match("(%d%d%d%d%-%d%d%-%d%d)")
	if fecha then
		local y, m, d = fecha:match("(%d+)%-(%d+)%-(%d+)")
		fecha = d .. "-" .. m .. "-" .. y
	end
	local det = {}
	if autor then det[#det + 1] = autor end
	if fecha then det[#det + 1] = fecha end
	return "Fuente: " .. nombre .. (#det > 0 and (" (" .. table.concat(det, ", ") .. ")") or "") .. " · árbol de ForeverDB.net"
end

function CV.Talentos(est, V)
	local C = Cl()
	if not C then V:Vacio("Falta el módulo de clase", "Activa «Asistente_Clase» en la lista de accesorios.") return end
	if not C.Arbol then V:Vacio("Faltan los datos del árbol", "Vuelve a instalar Mamba.") return end
	-- otra clase: «si me hago un paladín, ¿tendré guía?»
	local items = {}
	for _, c in ipairs(C.CLASES) do items[#items + 1] = { key = c, label = C.CLASE_ES[c] } end
	local clase = claseVista(est)
	est.claseMostrada = clase
	V:Segmentos(items, clase, function(k) est.clase = k; est.build = nil; est.nivel = nil; est.comparar = nil end)
	local b = buildElegida(est, clase)
	if not b then V:Vacio("Sin builds", "Todavía no hay builds para esta clase.") return end
	local mia = clase == miClase()
	est.nivel = est.nivel or (mia and max(10, min(60, miNivel())) or 60)
	local n = C.PuntosHasta(b, est.nivel)
	local final = C.Final(b)
	V:Titulo(C.NombreBuild(clase, b), "Al 60: " .. C.RepartoEnPalabras(clase, final))
	if b.nota and b.nota ~= "" then V:Nota(b.nota) end
	-- los botones de V ya redibujan al soltar el clic; la regla redibuja sola (abajo, en su OnClick)
	local function fijar(nv) est.nivel = max(10, min(60, nv)); est.comparar = nil end
	-- comparar: primero se leen tus talentos (si el juego no los da, se dice por qué y se vuelve a la build)
	local mios, motivo
	if est.comparar then
		local ok, r, m = pcall(C.LeerTalentos, clase)
		if ok and r then mios = r else motivo = ok and m or "sinapi" end
		if not mios then est.comparar = nil end
	end
	if not est.comparar then regla(V, est, b, n, fijar) end
	-- lo que hay al nivel elegido, y los botones (arriba del árbol, para que siempre se vean)
	local lectura
	if est.comparar then
		lectura = nil
	elseif n == 0 then
		lectura = "Antes del nivel 10 no hay puntos de talento."
	else
		lectura = format("Al nivel %d: %s  ·  punto %d de %d", est.nivel, CV.NombreTalento(clase, b.picks[n]), n, #b.picks)
	end
	local botones = {}
	if not est.comparar then
		botones[#botones + 1] = { "- 1 nivel", function() fijar(est.nivel - 1) end, apagado = est.nivel <= 10 }
		botones[#botones + 1] = { "+ 1 nivel", function() fijar(est.nivel + 1) end, apagado = est.nivel >= 60 }
	end
	botones[#botones + 1] = { est.comparar and "Dejar de comparar" or "Comparar con mis talentos",
		function() est.comparar = not est.comparar end, apagado = not mia }
	V:Botones(botones, lectura)
	if not mia then V:Nota("Para comparar, entra con un personaje de esta clase.") end
	if motivo then V:Nota("No pude leer tus talentos: " .. (MOTIVOS[motivo] or tostring(motivo)) .. ".", "warning") end
	arboles(V, { clase = clase, b = b, n = n, comparar = est.comparar, mios = mios or {}, final = final })
	if est.comparar and mios then
		V:Nota("Verde: lo tienes como pide la build.   Rojo (+): puntos que la build no usa.   Amarillo (-): te falta.", "textDim")
		local cmp = C.Comparar(clase, b, mios)
		local ok, doble = pcall(C.TieneDoble)
		local consejo = C.Consejo(miNivel(), cmp, ok and doble or nil)
		V:Nota(consejo.texto, "text")
		V:Nota("Cambiar talentos lo haces tú en la ventana de talentos del juego: Mamba no toca nada.")
	end
	V:Nota(fuenteCorta(b))
end

---------------------------------------------------------------- profesiones: una tarjeta por objetivo
-- Ícono de cada profesión: el de su hechizo (aprendiz), que trae el cliente; si no, el del archivo.
local PROF_HECHIZO = { ["Alquimia"] = 2259, ["Herrería"] = 2018, ["Encantamiento"] = 7411, ["Ingeniería"] = 4036,
	["Herboristería"] = 2366, ["Peletería"] = 2108, ["Minería"] = 2575, ["Desuello"] = 8613, ["Sastrería"] = 3908,
	["Cocina"] = 2550, ["Primeros auxilios"] = 3273, ["Pesca"] = 7620 }
local PROF_ARCHIVO = { ["Alquimia"] = "Trade_Alchemy", ["Herrería"] = "Trade_BlackSmithing", ["Encantamiento"] = "Trade_Engraving",
	["Ingeniería"] = "Trade_Engineering", ["Herboristería"] = "Trade_Herbalism", ["Peletería"] = "Trade_LeatherWorking",
	["Minería"] = "Trade_Mining", ["Desuello"] = "INV_Misc_Pelt_Wolf_01", ["Sastrería"] = "Trade_Tailoring" }
-- La raza: el ícono de su habilidad racial (Cultivo del tauren, Especialización en Ingeniería del gnomo…).
local RAZA_HECHIZO = { Tauren = { 20552, 20549 }, Gnome = { 20593, 20589 }, Dwarf = { 20594, 20596 }, Human = { 20599, 20600 },
	NightElf = { 20580, 20582 }, Orc = { 20572, 20573 }, Troll = { 26297, 20554 }, Scourge = { 7744, 20577 }, Undead = { 7744 } }
local RAZA_ES = { Tauren = "Tauren", Gnome = "Gnomo", Dwarf = "Enano", Human = "Humano", NightElf = "Elfo de la noche", Orc = "Orco",
	Troll = "Trol", Scourge = "No-muerto", Undead = "No-muerto" }

function CV.IconoProfesion(p)
	local id = PROF_HECHIZO[p]
	local t
	if id then pcall(function() t = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)) or (GetSpellTexture and GetSpellTexture(id)) end) end
	return t or (PROF_ARCHIVO[p] and ("Interface\\Icons\\" .. PROF_ARCHIVO[p])) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function iconoRaza(raza)
	for _, id in ipairs(RAZA_HECHIZO[raza] or {}) do
		local t
		pcall(function() t = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)) or (GetSpellTexture and GetSpellTexture(id)) end)
		if t then return t end
	end
end

local USOS = { { "subir", "Para subir de nivel" }, { "mazmorra", "Mazmorras al 60" }, { "jcj", "JcJ al 60" }, { "oro", "Para ganar oro" } }
CV.USOS_PROF = USOS

local function plan() local p = _G.MambaPlan; return type(p) == "table" and p or nil end

-- Lo que cuestan los instructores de las dos profesiones hasta 300 (los rangos de Mi plan). nil: sin dato.
local function costoPar(par)
	local P = plan()
	if not (P and P.CostoProfesion and P.Estado) then return nil end
	local ok, total = pcall(function()
		local e = P.Estado()
		local t = 0
		for _, p in ipairs(par) do
			local c = P.CostoProfesion(e, p)
			if not c then return nil end
			t = t + (c.rangosOro or 0)
		end
		return t
	end)
	return ok and total or nil
end

local function elegida()
	local P = plan()
	local ok, pj = pcall(function() return P and P.PJ and P.PJ() end)
	return ok and pj and pj.respuestas and pj.respuestas.profesiones or nil
end

function CV.Elegir(clave)
	local P = plan()
	if not (P and P.PJ) then return false end
	local ok = pcall(function()
		local pj = P.PJ()
		pj.respuestas = pj.respuestas or {}
		pj.respuestas.profesiones = clave
		if P.Cambio then P.Cambio() end
	end)
	if ok and P.AbrirPlan then pcall(P.AbrirPlan, "profesiones") end
	return ok
end

local function metaPrincipal()
	local P = plan()
	local ok, pj = pcall(function() return P and P.PJ and P.PJ() end)
	local r = ok and pj and pj.respuestas
	local estilo = r and r.estilo or "jce"
	return (P and P.USO_DE_ESTILO and P.USO_DE_ESTILO[estilo]) or "mazmorra"
end

local function tarjeta(V, d)
	local o = pieza(V, "profTarjeta", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.Fondo = W().Fill(f, "panelAlt")
		f.Barra = tex(f, "ARTWORK")
		f.Barra:SetWidth(3)
		f.Barra:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
		f.Barra:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		f.I1 = f:CreateTexture(nil, "ARTWORK"); f.I1:SetSize(36, 36); f.I1:SetPoint("LEFT", f, "LEFT", 14, 0)
		f.I2 = f:CreateTexture(nil, "ARTWORK"); f.I2:SetSize(36, 36); f.I2:SetPoint("LEFT", f.I1, "RIGHT", 6, 0)
		f.Uso = texto(f, "small", "textMuted")
		f.Uso:SetPoint("TOPLEFT", f, "TOPLEFT", 112, -10)
		f.Par = texto(f, "title", "text")
		f.Par:SetPoint("TOPLEFT", f.Uso, "BOTTOMLEFT", 0, -3)
		f.Por = texto(f, "small", "textDim")
		f.Por:SetWordWrap(true)
		f.Por:SetJustifyH("LEFT")
		f.Por:SetPoint("TOPLEFT", f.Par, "BOTTOMLEFT", 0, -3)
		f.Costo = texto(f, "small", "textMuted")
		f.Costo:SetJustifyH("RIGHT")
		f.Costo:SetWordWrap(true)
		f.Costo:SetWidth(150)
		f.Boton = W().Button(f, "Elegir", nil, { height = 28 })
		f.Boton:SetPoint("RIGHT", f, "RIGHT", -14, 0)
		f.Boton.psFixedWidth = 96
		f.Boton:SetWidth(96)
		f.BotonPri = W().Button(f, "Elegir", nil, { height = 28, primary = true })
		f.BotonPri:SetPoint("RIGHT", f, "RIGHT", -14, 0)
		f.BotonPri.psFixedWidth = 96
		f.BotonPri:SetWidth(96)
		f.Costo:SetPoint("RIGHT", f, "RIGHT", -124, 0)
		f.I1:SetTexCoord(0.07, 0.93, 0.07, 0.93); f.I2:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		return f
	end)
	o.I1:SetTexture(CV.IconoProfesion(d.par[1]))
	o.I2:SetTexture(CV.IconoProfesion(d.par[2] or d.par[1]))
	o.I2:SetShown(d.par[2] ~= nil)
	o.Uso:SetText(d.uso:upper() .. (d.meta and "  ·  TU META" or ""))
	o.Par:SetText(table.concat(d.par, " + "))
	o.Por:SetWidth(max(120, V.ancho - 112 - 260))
	o.Por:SetText(d.porque or "")
	o.Costo:SetText(d.costo or "")
	o.Barra:SetShown(d.meta or false)
	if d.meta then W().Color(o.Barra, "accent") end
	local bt = d.meta and o.BotonPri or o.Boton
	o.Boton:SetShown(not d.meta); o.BotonPri:SetShown(d.meta or false)
	W().SetButtonText(bt, d.yaElegida and "Elegida" or "Elegir")
	bt:SetScript("OnClick", function() if d.elegir then pcall(d.elegir) end; Hub.Redibujar() end)
	if d.elegir then bt:Enable() else bt:Disable() end
	V:_colocar(o, max(70, 10 + 14 + 3 + 20 + 3 + (o.Por:GetStringHeight() or 14) + 12))
	V:Espacio(8)
end

local function filaRaza(V, raza, bono)
	local o = pieza(V, "profRaza", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.I = f:CreateTexture(nil, "ARTWORK"); f.I:SetSize(26, 26); f.I:SetPoint("LEFT", f, "LEFT", 0, 0)
		f.I:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		f.T = texto(f, "body", "text")
		f.T:SetPoint("LEFT", f.I, "RIGHT", 10, 0)
		f.T:SetJustifyH("LEFT")
		return f
	end)
	local ic = iconoRaza(raza)
	o.I:SetShown(ic ~= nil)
	if ic then o.I:SetTexture(ic) end
	o.T:ClearAllPoints()
	o.T:SetPoint("LEFT", o, "LEFT", ic and 36 or 0, 0)
	o.T:SetWidth(V.ancho - 40)
	o.T:SetText((RAZA_ES[raza] or raza) .. "  ·  " .. (bono or ""))
	V:_colocar(o, 34)
	V:Espacio(6)
end

function CV.Profesiones(est, V)
	local m, C = M(), Cl()
	if not (m and C and C.Profesiones) then V:Vacio("Falta el módulo de clase", "Activa «Asistente_Clase» en la lista de accesorios.") return end
	local clase = miClase()
	local spec
	pcall(function()
		local rangos = C.LeerTalentos(clase)
		spec = rangos and C.SpecPrincipal(clase, rangos)
	end)
	local _, raza = UnitRace("player")
	local r = raza and C.BonoRaza(raza)
	if raza then filaRaza(V, raza, r and r.bono or "sin bono de profesión") end
	local meta, ya = metaPrincipal(), elegida()
	local fuentes, vistas = {}, {}
	local FP = CV.FuentesProf and CV.FuentesProf() or {}
	local alguna = false
	for _, u in ipairs(USOS) do
		local par, porque, ids = C.Profesiones(clase, u[1], spec)
		if par then
			alguna = true
			local clave = table.concat(par, " + ")
			local costo = costoPar(par)
			for _, id in ipairs(ids or {}) do
				local f = FP[id]
				if f and not vistas[id] then
					vistas[id] = true
					local fecha = f[3]:match("(%d%d%d%d%-%d%d%-%d%d)")
					if fecha then local y, mm, d = fecha:match("(%d+)%-(%d+)%-(%d+)"); fecha = d .. "-" .. mm .. "-" .. y end
					local nombre = f[1]:gsub("%s*%(.*%)", ""):gsub(",.*$", "")
					fuentes[#fuentes + 1] = nombre .. (fecha and (" (" .. fecha .. ")") or "")
				end
			end
			tarjeta(V, { par = par, uso = u[2], porque = porque, meta = u[1] == meta,
				costo = costo and ("Instructores hasta 300:\n" .. A.Monedas(costo)) or "Costo: sin dato",
				yaElegida = ya == clave, elegir = plan() and function() CV.Elegir(clave) end or nil })
		end
	end
	if not alguna then V:Vacio("Sin consejos", "Todavía no hay consejos de profesiones para tu clase.") return end
	V:Nota("Según " .. table.concat(fuentes, ", ") .. ". Sin verificar en Forever: parte de esto viene del juego clásico.")
end

-- Las fuentes de profesiones (Datos_Profesiones.lua: ns.FUENTES_PROF), expuestas por el módulo.
function CV.FuentesProf()
	local m = M()
	return m and m.FuentesProf and m.FuentesProf() or {}
end

---------------------------------------------------------------- la entrada «Talentos» del riel (reemplaza la de Polestar)
Hub.Seccion({
	clave = "MambaTalentos", nombre = "Talentos", icono = "icon-learn", orden = 40, addon = "Asistente_Clase",
	titulo = function(est)
		local C = Cl()
		local clase = est.claseMostrada or miClase()
		local nombre = C and C.CLASE_ES and C.CLASE_ES[clase] or (UnitClass and UnitClass("player")) or ""
		return "Talentos", tostring(nombre) .. " · el árbol de cada build, punto por punto"
	end,
	nav = function(est) return CV.Nav(est) end,
	onNav = function(est, key) CV.OnNav(est, key) end,
	dibujar = function(est, V) CV.Talentos(est, V) end,
})
Hub.Grupo({ clave = "Talents", nombre = "Talentos", icono = "icon-learn", orden = 40, partes = { "MambaTalentos" } })
