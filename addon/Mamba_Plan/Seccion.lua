-- Mamba_Plan: la sección "Mi plan" del menú de Polestar (riel izquierdo, justo bajo Guías). Su índice:
-- Ahora, Metas, Talentos, Equipo, Profesiones, Farmeo, Bolsas, Dinero, Macros y Builds conocidas. Arriba, quién
-- eres y tus números (nivel, oro, bolsas, profesiones); a la derecha, la lista de la parte elegida, con un
-- botón por fila para hacerlo (flecha, crear macro, ver en Equipo...) y "Hecho" / "No me interesa".
-- Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas

local KEY = "MambaPlan"
local vista = "ahora"
local raiz, cab, lista, hijo, pool = nil, nil, nil, nil, {}

M.VISTAS = {
	{ key = "ahora", label = "Ahora", icon = "icon-goto" },
	{ key = "metas", label = "Metas", icon = "icon-level" },
	{ key = "talentos", label = "Talentos", icon = "icon-level" },
	{ key = "equipo", label = "Equipo a buscar", icon = "icon-dungeon" },
	{ key = "profesiones", label = "Profesiones", icon = "icon-craft" },
	{ key = "farmeo", label = "Farmeo", icon = "icon-collect" },
	{ key = "bolsas", label = "Bolsas", icon = "icon-buy" },
	{ key = "dinero", label = "Dinero", icon = "icon-buy" },
	{ key = "macros", label = "Macros", icon = "compact" },
	{ key = "builds", label = "Builds conocidas", icon = "record" },
}

---------------------------------------------------------------- acciones
local function textoBoton(b, t)
	local _, _, W = P.Polestar()
	if W and W.SetButtonText and b.Label then W.SetButtonText(b, t)
	elseif b.Label then b.Label:SetText(t)
	elseif b.SetText then b:SetText(t) end
	b:SetWidth(math.max(80, ((b.Label and b.Label:GetStringWidth()) or 60) + 26))
end

function M.Flecha(lugar, etiqueta)
	if not lugar then return false end
	local PS = _G.Polestar
	local N = PS and PS.Nav and PS.Nav.API
	if N and N.version == 1 and N.Navigate then
		local ok, hecho = pcall(N.Navigate, "MambaPlan", lugar.mapa, lugar.x / 100, lugar.y / 100, etiqueta or "Mamba")
		return ok and hecho
	end
	return false
end

-- «Llévame» (K58/K61/K119): la ruta más rápida de Ir a… (MambaAPI.Llevame: tramos y flecha); sin ella, la flecha sola.
function M.Llevame(lugar, etiqueta)
	if not lugar then return false end
	local api = _G.MambaAPI
	if api and api.Llevame then
		local ok, hecho = pcall(api.Llevame, { map = lugar.mapa, x = lugar.x, y = lugar.y, nombre = etiqueta or lugar.npc })
		if ok and hecho then return true end
	end
	return M.Flecha(lugar, etiqueta)
end

local ACCION = {
	guia = { "Ir a la guía", function() M.Fuentes.AbrirSeccion("Guides") end },
	equipo = { "Ver en Equipo", function() M.Fuentes.AbrirSeccion("Equipo") end },
	dinero = { "Ver Dinero", function() vista = "dinero"; M.Refrescar() end },
	subasta = { "Ver en Subasta", function() M.Fuentes.AbrirSeccion("Subasta") end },
	medidor = { "Ver el Medidor", function() M.Fuentes.AbrirSeccion("Medidor") end },
	farmeo = { "Ver Farmeo", function() vista = "farmeo"; M.Refrescar() end },
}

---------------------------------------------------------------- filas
local function fila(i, ancho)
	local f = pool[i]
	if not f then
		f = P.Fila(hijo, ancho, 54)
		f.tipo = P.Texto(f, "small", "textMuted")
		f.tipo:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
		f.tipo:SetWidth(86)
		f.titulo = P.Texto(f, "body", "text")
		f.titulo:SetPoint("TOPLEFT", f, "TOPLEFT", 104, -6)
		f.detalle = P.Texto(f, "note", "textDim")
		f.detalle:SetPoint("TOPLEFT", f.titulo, "BOTTOMLEFT", 0, -3)
		f.conf = P.Texto(f, "small", "textMuted")
		f.conf:SetPoint("TOPLEFT", f.detalle, "BOTTOMLEFT", 0, -2)
		f.botones = {}
		for k = 1, 3 do
			local b = P.Boton(f, "·", function() if f.acciones and f.acciones[k] then f.acciones[k]() end end, k == 1)
			b:SetHeight(22)
			f.botones[k] = b
		end
		pool[i] = f
	end
	f:SetWidth(ancho)
	f:ClearAllPoints()
	return f
end

local function llenar(f, d, ancho)
	f.tipo:SetText(d.tipo or "")
	f.titulo:SetText(d.titulo or "")
	f.detalle:SetText(d.detalle or "")
	f.conf:SetText(d.confianza or "")
	local acc = d.acciones or {}
	f.acciones = {}
	local x = -8
	for k = 3, 1, -1 do f.botones[k]:Hide() end
	for k = #acc, 1, -1 do
		local b = f.botones[k]
		if b then
			textoBoton(b, acc[k][1])
			f.acciones[k] = acc[k][2]
			b:ClearAllPoints()
			b:SetPoint("TOPRIGHT", f, "TOPRIGHT", x, -8)
			b:Show()
			x = x - b:GetWidth() - 6
		end
	end
	local libre = ancho - 104 + x - 10
	f.titulo:SetWidth(math.max(120, libre))
	f.detalle:SetWidth(math.max(120, libre))
	local h = 14 + (f.titulo:GetStringHeight() or 14) + (f.detalle:GetText() ~= "" and (f.detalle:GetStringHeight() or 12) + 3 or 0)
		+ (f.conf:GetText() ~= "" and 14 or 0)
	f:SetHeight(math.max(40, h))
	f:Show()
	return f:GetHeight()
end

local function accionesDePaso(p)
	local a = {}
	if p.accion and ACCION[p.accion] then a[#a + 1] = ACCION[p.accion] end
	if p.lugar then a[#a + 1] = { "Llévame", function() M.Llevame(p.lugar, p.titulo) end } end
	if p.accion == "macro" then a[#a + 1] = { "Crear macro", function() M.CrearMacro(p.macro) end } end
	if not p.fijo then
		a[#a + 1] = { "Hecho", function() M.PJ().hechos[p.clave] = true; M.Refrescar() end }
		if #a < 3 then a[#a + 1] = { "No me interesa", function() M.PJ().descartados[p.clave] = true; M.Refrescar() end } end
	end
	while #a > 3 do table.remove(a, 2) end
	return a
end

---------------------------------------------------------------- qué se ve en cada parte
local function datos(e, r)
	local out = {}
	local function add(d) out[#out + 1] = d end
	if vista == "ahora" then
		for _, p in ipairs(M.Pasos(e, r)) do
			p.acciones = accionesDePaso(p)
			add(p)
		end
	elseif vista == "metas" or vista == "dinero" then
		for _, m in ipairs(M.Metas(e)) do
			add({ tipo = "Nivel " .. m.nivel, titulo = m.titulo .. ": " .. M.Dinero(m.costo),
				detalle = m.detalle .. (m.falta > 0 and (" · te faltan " .. M.Dinero(m.falta) .. " si pagas en orden") or " · te alcanza"),
				confianza = m.confianza, acciones = m.lugar and { { "Llévame", function() M.Llevame(m.lugar, m.titulo) end } } or nil })
		end
		if vista == "dinero" then
			for _, i in ipairs(M.ComoJuntar(e)) do
				add({ tipo = "Juntar", titulo = i.titulo, detalle = i.detalle, acciones = ACCION[i.accion] and { ACCION[i.accion] } or nil })
			end
		end
	elseif vista == "talentos" then
		local b = r.build
		local nombre = b
		if b and b:find("^conocida:") then
			local x = M.CONOCIDAS[tonumber(b:match("%d+"))]
			nombre = x and (x.uso .. " · " .. x.autor .. " (" .. x.reparto .. ")")
		end
		add({ tipo = "Tu build", titulo = nombre or "Sin elegir", detalle = "El próximo punto y la revisión de tus talentos están en la sección Clase.",
			acciones = { { "Ver en Clase", function() M.Fuentes.AbrirSeccion("Clase") end }, { "Cambiar", function() M.AbrirInicio() end } } })
		local C = M.Fuentes.Clase()
		if not C then add({ tipo = "", titulo = "La sección Clase todavía no está instalada.", detalle = "Cuando esté, aquí sale el próximo talento." }) end
	elseif vista == "equipo" then
		local mz = M.Fuentes.Mazmorras(e.nivel)
		if not mz then add({ titulo = "La sección Equipo no está cargada.", detalle = "Sin ella no hay datos de botín." }) end
		for i, x in ipairs(mz or {}) do
			if i > 6 then break end
			local pz = x.pieza
			add({ tipo = ("%d-%d"):format(x.min or 0, x.max or 0), titulo = x.nombre,
				detalle = pz and ((pz.nombre or "") .. " · " .. tostring(pz.pct or "?") .. " % por pasada") or "",
				confianza = "dato de forever-db", acciones = { ACCION.equipo } })
		end
	elseif vista == "profesiones" then
		for _, p in ipairs(e.profesiones) do
			local c = M.CostoProfesion(e, p.nombre)
			add({ tipo = "Tienes", titulo = ("%s %d / %d"):format(p.nombre, p.rango, p.max),
				detalle = c and c.rangosOro > 0 and ("Rangos que faltan: " .. M.Dinero(c.rangosOro) .. " en instructores") or "Rango máximo",
				confianza = "del juego" })
		end
		if r.profesiones then add({ tipo = "Elegiste", titulo = r.profesiones, acciones = { { "Cambiar", function() M.AbrirInicio() end } } }) end
		for _, rec in ipairs(M.ProfesionesRecomendadas(e, r)) do
			if rec.uso ~= "ya" then
				add({ tipo = rec.uso == "subir" and "Para subir" or (rec.uso == "oro" and "Para oro" or (rec.uso == "jcj" and "Para JcJ" or "Al 60")),
					titulo = table.concat(rec.par, " + "), detalle = rec.porque .. (rec.raza and ("  Tu raza: " .. rec.raza) or ""),
					confianza = #rec.fuentes > 0 and ("según " .. #rec.fuentes .. " fuente(s): pasa el ratón en el asistente") or nil })
			end
		end
	elseif vista == "farmeo" then
		local hay = 0
		for _, i in ipairs(M.ComoJuntar(e)) do
			if i.accion == "farmeo" then
				hay = hay + 1
				add({ tipo = "Farmear", titulo = i.titulo, detalle = i.detalle, acciones = { ACCION.subasta } })
			end
		end
		if hay == 0 then
			add({ tipo = "Farmear", titulo = "No tienes profesiones de recolección",
				detalle = "Herboristería, Minería o Desuello dan oro sin gastar materiales. Mira cuál te conviene.",
				acciones = { { "Ver profesiones", function() vista = "profesiones"; M.Refrescar() end } } })
		end
		-- lo que se junta matando (tela, cuero, carne) vale igual: se vende en la subasta
		add({ tipo = "Vender", titulo = "Lo que juntas matando también es oro", detalle = "Tela, cuero y carne: el Tasador te dice cuál conviene subastar.",
			acciones = { ACCION.subasta } })
	elseif vista == "bolsas" then
		local b = M.Bolsas(e)
		add({ tipo = "Tienes", titulo = ("%d casillas · %d libres · la más chica: %d%s"):format(e.bolsas.total, e.bolsas.libres, b.menor,
			b.vacias > 0 and (" · " .. b.vacias .. " ranura(s) sin bolsa") or "") })
		for i, o in ipairs(b.opciones) do
			if i > 10 then break end
			add({ tipo = (o == b.recomendada) and "Recomendada" or (o.familia ~= "bolsa" and o.familia or ""),
				titulo = ("%s (%d casillas)"):format(o.nombre, o.casillas), detalle = table.concat(o.formas, " · "),
				confianza = o.precioDias and ("precio de la subasta, hace " .. o.precioDias .. " día(s)") or "dato del juego",
				acciones = o.lugar and { { "Llévame", function() M.Llevame(o.lugar, o.nombre) end } } or nil })
		end
	elseif vista == "macros" then
		local todas = M.TodasLasMacros(e)
		local faltan = 0
		for _, x in ipairs(todas) do if x.sabe and not x.mal and not x.creada then faltan = faltan + 1 end end
		add({ tipo = "", titulo = faltan > 0 and ("Crear las %d que te sirven, de una vez"):format(faltan) or "Ya tienes todas las que te sirven",
			detalle = "Mamba las prueba con el juego al crearlas y saca las que no funcionan en Forever. Quedan en tus macros (Esc › Macros) para arrastrarlas a una barra.",
			acciones = faltan > 0 and { { "Crear todas", function()
				local c, s2, motivo = M.CrearTodasLasMacros(e)
				M.ultimoMacros = motivo or (("Creadas: %d · sacadas porque el juego no las entiende: %d"):format(c, s2))
				M.Cambio()
			end } } or nil })
		if M.ultimoMacros then add({ tipo = "Resultado", titulo = M.ultimoMacros }) end
		local rechazadas = 0
		for _, x in ipairs(todas) do if x.mal then rechazadas = rechazadas + 1 end end
		if rechazadas > 0 then add({ tipo = "", titulo = ("%d que el juego no entendió"):format(rechazadas),
			detalle = "Si crees que fue un error, pruébalas otra vez.", acciones = { { "Probar de nuevo", function() M.ReintentarMacros() end } } }) end
		for _, x in ipairs(todas) do
			local m = x.m
			local tipo
			if x.mal then tipo = "No funciona"
			elseif x.creada then tipo = x.bien and "Creada · funciona" or "Creada"
			elseif not x.sabe then tipo = "Te falta un hechizo" else tipo = "" end
			add({ tipo = tipo, titulo = m.titulo,
				detalle = x.mal and "El juego no reconoce su hechizo en Forever: Mamba la sacó y no la vuelve a ofrecer." or (m.detalle or ""),
				confianza = x.bien and "el juego la entiende (probada al crearla)" or nil,
				acciones = (x.sabe and not x.mal) and { { x.creada and "Ponerla en el cursor" or "Crear macro", function() M.CrearMacro(m.clave) end } } or nil })
		end
	elseif vista == "builds" then
		for _, b in ipairs(M.CONOCIDAS or {}) do
			if b.clase == e.clase then
				add({ tipo = b.reparto, titulo = b.uso .. " · " .. b.autor, detalle = b.destaca .. " · Talentos clave: " .. b.clave,
					confianza = "verificada el 18-11 en su fuente (" .. b.fecha .. ")" })
			end
		end
		add({ tipo = "", titulo = "Todavía no hay rankings de daño en Forever.", detalle = "Las bandas abren el 9-12-2026; después se suman los mejores de cada clase." })
	end
	return out
end

---------------------------------------------------------------- dibujar
local function cabecera(e, r)
	local roles = { sanar = "Sanar", tanque = "Tanque", danio = "Daño" }
	local estilos = { jce = "Mazmorras", jcj = "JcJ", oro = "Oro" }
	cab.quien:SetText(("%s  ·  %s %s, nivel %d"):format(e.nombre or "", e.claseNombre or "", (e.razaNombre or ""):lower(), e.nivel))
	local profs = {}
	for _, p in ipairs(e.profesiones) do profs[#profs + 1] = p.nombre .. " " .. p.rango .. "/" .. p.max end
	cab.numeros:SetText(("Oro %s   ·   Bolsas: %d libres de %d   ·   %s"):format(M.Dinero(e.oro), e.bolsas.libres, e.bolsas.total,
		#profs > 0 and table.concat(profs, " · ") or "sin profesiones"))
	local es = {}
	for _, k in ipairs({ "jce", "jcj", "oro" }) do
		local prio = r.estilos and r.estilos[k]
		if prio then es[#es + 1] = estilos[k] .. (prio == 2 and " (de segundo)" or "") end
	end
	if #es == 0 and r.estilo then es[1] = estilos[r.estilo] end
	cab.respuestas:SetText(r.rol and (("Elegiste: %s%s%s · %s"):format(roles[r.rol] or r.rol, r.rol2 and (" + " .. (roles[r.rol2] or r.rol2)) or "",
		r.spec and (" (" .. r.spec .. ")") or "", table.concat(es, ", "))) or "Todavía no respondiste las preguntas de inicio.")
end

function M.Refrescar()
	-- Sin exigir IsShown: Polestar llama a render antes de mostrar la sección, y con esa condición la lista se
	-- quedaba con lo de la vista anterior ("Ahora" mostraba "Equipo a buscar": visto en el juego el 18-11).
	if not (raiz and lista) then return end
	M.ultimaVista = vista
	local e, r = M.Estado(), M.PJ().respuestas or {}
	cabecera(e, r)
	local ancho = math.max(300, (lista:GetWidth() or 600) - 14)
	local y = 0
	local filasD = datos(e, r)
	for i, d in ipairs(filasD) do
		local f = fila(i, ancho)
		f:SetPoint("TOPLEFT", hijo, "TOPLEFT", 0, -y)
		y = y + llenar(f, d, ancho) + 2
	end
	for i = #filasD + 1, #pool do pool[i]:Hide() end
	hijo:SetHeight(math.max(1, y))
	local _, _, W = P.Polestar()
	if W and W.SetScrollContent then W.SetScrollContent(lista, y + 8, lista:GetHeight()) end
end
M.AlCambiar(function() M.Refrescar() end)

local function construir(parent)
	raiz = parent
	cab = CreateFrame("Frame", nil, parent)
	cab:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -10)
	cab:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, -10)
	cab:SetHeight(70)
	cab.quien = P.Texto(cab, "title", "text")
	cab.quien:SetPoint("TOPLEFT", cab, "TOPLEFT", 0, 0)
	cab.cambiar = P.Boton(cab, "Cambiar mis respuestas", function() M.AbrirInicio() end)
	cab.cambiar:SetPoint("TOPRIGHT", cab, "TOPRIGHT", 0, 2)
	cab.numeros = P.Texto(cab, "body", "textDim")
	cab.numeros:SetPoint("TOPLEFT", cab.quien, "BOTTOMLEFT", 0, -8)
	cab.numeros:SetPoint("RIGHT", cab, "RIGHT", 0, 0)
	cab.respuestas = P.Texto(cab, "note", "textMuted")
	cab.respuestas:SetPoint("TOPLEFT", cab.numeros, "BOTTOMLEFT", 0, -6)
	local raya = P.Linea(parent, false)
	raya:SetPoint("TOPLEFT", cab, "BOTTOMLEFT", 0, -4)
	raya:SetPoint("TOPRIGHT", cab, "BOTTOMRIGHT", 0, -4)
	local _, _, W = P.Polestar()
	if W and W.Scroll then
		lista = W.Scroll(parent)
		hijo = lista.Child
	else
		lista = CreateFrame("ScrollFrame", nil, parent)
		hijo = CreateFrame("Frame", nil, lista)
		lista:SetScrollChild(hijo)
		lista:EnableMouseWheel(true)
		lista:SetScript("OnMouseWheel", function(self, d) self:SetVerticalScroll(math.max(0, self:GetVerticalScroll() - d * 40)) end)
	end
	lista:SetPoint("TOPLEFT", cab, "BOTTOMLEFT", 0, -10)
	lista:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
	hijo:SetWidth(math.max(300, (parent:GetWidth() or 640) - 40))
end

local registrada = false
local function registrar()
	local PS = _G.Polestar
	local UI = PS and PS.UI
	if registrada or not (UI and UI.RegisterSection) then return registrada end
	registrada = UI.RegisterSection({
		key = KEY, label = "Mi plan", icon = "pin", order = 21, -- 20 es Buscar (Lookup) de Polestar: empatar deja el orden al azar
		build = construir,
		render = function()
			M.Proteger("refrescar", M.Refrescar)
			-- otra vez en el cuadro siguiente, ya con la sección a la vista y su ancho final
			if C_Timer then C_Timer.After(0, function() M.Proteger("refrescar", M.Refrescar) end) end
		end,
		nav = function()
			local items = {}
			for _, x in ipairs(M.VISTAS) do items[#items + 1] = { key = x.key, label = x.label, icon = x.icon } end
			return items, vista
		end,
		onNav = function(k)
			vista = k
			if UI.Picker and UI.Picker.Render then UI.Picker.Render() end
		end,
	}) and true or false
	return registrada
end

function M.AbrirPlan(v)
	if v then vista = v end
	local PS = _G.Polestar
	local UI = PS and PS.UI
	if registrar() and UI.ShowPicker and UI.Picker and UI.Picker.ShowSection then
		UI.ShowPicker()
		UI.Picker.ShowSection(KEY)
		return true
	end
	return false
end

local ev = CreateFrame("Frame")
M.Escuchar(ev, "PLAYER_LOGIN")
for _, e in ipairs({ "PLAYER_MONEY", "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "SKILL_LINES_CHANGED", "LEARNED_SPELL_IN_TAB" }) do
	M.Escuchar(ev, e)
end
ev:SetScript("OnEvent", function(_, e)
	if e == "PLAYER_LOGIN" then
		M.Proteger("registrar", registrar)
		local A = _G.Asistente
		if A and A.Opciones then
			pcall(A.Opciones, "Mi plan", "Mi plan", {
				{ kind = "button", label = "Abrir Mi plan", onClick = function() M.AbrirPlan() end },
				{ kind = "button", label = "Volver a responder las preguntas de inicio", onClick = function() M.AbrirInicio() end },
			})
		end
	else
		M.Refrescar()
	end
end)
