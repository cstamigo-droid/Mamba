-- Mamba_Barras: la pestaña "Barras". A la izquierda, la lista de barras; a la derecha, las opciones de la
-- elegida (mostrar, botones, filas, tamaño, separación, transparencia, cuándo se ve y, en la barra
-- principal, a qué botones pasa con cada forma). Abajo: Mover barras, Asignar teclas, Copiar mis barras
-- de Bartender y Deshacer. Se cuelga de la ventana de Mamba si ésta ofrece A.RegistrarPestana; si no,
-- abre su propia ventana. Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas

local ANCHO, ALTO = 640, 540
local LISTA_W = 170
local elegida = 1
local panel, paginas, lista = nil, {}, {}

local VER = {
	{ value = "siempre", text = "Siempre" },
	{ value = "combate", text = "Solo en combate" },
	{ value = "raton", text = "Al pasar el ratón" },
}

local function todas()
	local t = {}
	for _, d in ipairs(M.BARRAS) do t[#t + 1] = d end
	for _, d in ipairs(M.ESPECIALES) do t[#t + 1] = d end
	return t
end

local function aplicar(id)
	M.FueraDeCombate("disponer" .. tostring(id), function() M.Disponer(id) end)
end

---------------------------------------------------------------- opciones de una barra
local function filas(id, padre, ancho)
	local d = M.Def(id)
	local c = function() return M.Config(id) end
	local max = d.max or 12
	local out = {}
	local function agregar(f) out[#out + 1] = f end
	local function cambia(campo) return function(v) c()[campo] = v; aplicar(id) end end
	local function lee(campo) return function() return c()[campo] end end

	agregar(P.Interruptor(padre, "Mostrar", nil, lee("mostrar"), cambia("mostrar")))
	agregar(P.Deslizador(padre, "Botones", nil, 1, max, 1, "%d", lee("botones"), cambia("botones")))
	agregar(P.Deslizador(padre, "Filas", nil, 1, max, 1, "%d", lee("filas"), cambia("filas")))
	agregar(P.Deslizador(padre, "Tamaño", nil, 50, 150, 5, "%d %%",
		function() return math.floor((c().escala or 1) * 100 + 0.5) end,
		-- el lugar se guarda en unidades de pantalla: la esquina de la barra no se mueve al cambiar el tamaño
		function(v) c().escala = v / 100; aplicar(id) end))
	agregar(P.Deslizador(padre, "Separación", nil, 0, 20, 1, "%d", lee("separacion"), cambia("separacion")))
	agregar(P.Deslizador(padre, "Transparencia", nil, 10, 100, 5, "%d %%",
		function() return math.floor((c().alfa or 1) * 100 + 0.5) end,
		function(v) c().alfa = v / 100; aplicar(id) end))
	agregar(P.Desplegable(padre, "Se ve", nil, VER, lee("ver"), cambia("ver")))

	-- La barra principal cambia sola con la forma o la actitud de tu clase.
	if id == 1 then
		local _, clase = UnitClass("player")
		local formas = M.FORMAS[clase]
		if formas then
			local titulo = P.Texto(padre, "heading", "accent")
			titulo:SetText("Cambia sola con la forma")
			titulo.esTitulo = true
			agregar(titulo)
			local opciones = { { value = 0, text = "No cambia" } }
			for _, f in ipairs(formas) do
				if f.pagina > 0 then
					local ya = false
					for _, o in ipairs(opciones) do if o.value == f.pagina then ya = true end end
					if not ya then opciones[#opciones + 1] = { value = f.pagina, text = "Botones de " .. f.nombre:lower() } end
				end
			end
			for _, f in ipairs(formas) do
				agregar(P.Desplegable(padre, f.nombre, nil, opciones,
					function() return (M.PJ().formas or {})[f.clave] or 0 end,
					function(v)
						local p = M.PJ()
						p.formasElegidas = p.formasElegidas or {}
						p.formasElegidas[f.clave] = v
						M.ActualizarConductor()
					end))
			end
		end
	end
	return out
end

local function pagina(id, padre, ancho)
	if paginas[id] then return paginas[id] end
	local _, _, W = P.Polestar()
	local sf, hijo
	if W and W.Scroll then
		sf = W.Scroll(padre)
		hijo = sf.Child
	else
		sf = CreateFrame("ScrollFrame", nil, padre)
		hijo = CreateFrame("Frame", nil, sf)
		sf:SetScrollChild(hijo)
		sf:EnableMouseWheel(true)
		sf:SetScript("OnMouseWheel", function(self, d) self:SetVerticalScroll(math.max(0, self:GetVerticalScroll() - d * 30)) end)
	end
	sf:SetAllPoints(padre)
	hijo:SetWidth(ancho)
	local nombre = P.Texto(hijo, "heading", "accent")
	nombre:SetPoint("TOPLEFT", hijo, "TOPLEFT", 12, -4)
	nombre:SetText(M.Def(id).nombre)
	local y = 28
	local fs = filas(id, hijo, ancho)
	for _, f in ipairs(fs) do
		f:ClearAllPoints()
		if f.esTitulo then
			y = y + 12
			f:SetPoint("TOPLEFT", hijo, "TOPLEFT", 12, -y)
			y = y + 22
		else
			f:SetPoint("TOPLEFT", hijo, "TOPLEFT", 0, -y)
			y = y + P.Acomodar(f, ancho - 14)
		end
	end
	if W and W.SetScrollContent then W.SetScrollContent(sf, y + 8, padre:GetHeight()) else hijo:SetHeight(y + 8) end
	sf.filas = fs
	paginas[id] = sf
	return sf
end

local function refrescar(sf)
	for _, f in ipairs(sf.filas or {}) do if f.Refresh then f:Refresh() end end
end

---------------------------------------------------------------- dibujar el panel
local function elegir(id)
	elegida = id
	for _, f in ipairs(lista) do
		if f.id == id then f.marca:Show() else f.marca:Hide() end
	end
	for k, sf in pairs(paginas) do if k ~= id then sf:Hide() end end
	if panel and panel.derecha then
		local sf = pagina(id, panel.derecha, panel.derecha:GetWidth())
		refrescar(sf)
		sf:Show()
	end
end

local function dibujarBloqueado(p, ancho)
	local t = P.Texto(p, "body", "text")
	t:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -16)
	t:SetWidth(ancho - 32)
	t:SetText(M.bloqueadoPor .. " está encendido. Las barras de Mamba esperan a que lo apagues, para que no " ..
		"haya dos juegos de barras encima.")
	local b = P.Boton(p, "Apagar " .. M.bloqueadoPor .. " y recargar", function() M.ApagarOtroYRecargar() end, true)
	b:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -16)
end

function M.DibujarPanel(p, ancho, alto)
	panel = p
	if M.bloqueadoPor then return dibujarBloqueado(p, ancho) end
	local pie = 50
	-- izquierda: la lista de barras
	local izq = CreateFrame("Frame", nil, p)
	izq:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
	izq:SetSize(LISTA_W, alto - pie)
	local raya = P.Linea(p, true)
	raya:SetPoint("TOPLEFT", izq, "TOPRIGHT", 0, 0)
	raya:SetPoint("BOTTOMLEFT", izq, "BOTTOMRIGHT", 0, 0)
	local y = 4
	for _, d in ipairs(todas()) do
		local f = P.Fila(izq, LISTA_W, 24)
		f.id = d.id
		f:SetPoint("TOPLEFT", izq, "TOPLEFT", 0, -y)
		f.marca = P.Relleno(f, "padSelect")
		f.marca:Hide()
		local t = P.Texto(f, "body", "textDim")
		t:SetPoint("LEFT", f, "LEFT", 12, 0)
		t:SetText(d.nombre)
		local n = P.Texto(f, "small", "textMuted")
		n:SetPoint("RIGHT", f, "RIGHT", -10, 0)
		f.cuenta = n
		f:SetScript("OnClick", function() elegir(d.id) end)
		lista[#lista + 1] = f
		y = y + 24
	end
	-- derecha: las opciones de la barra elegida
	local der = CreateFrame("Frame", nil, p)
	der:SetPoint("TOPLEFT", izq, "TOPRIGHT", 8, 0)
	der:SetSize(ancho - LISTA_W - 8, alto - pie)
	p.derecha = der
	-- abajo: los botones
	local mover = P.Boton(p, "Mover barras", function() M.EmpezarMover() end, true)
	mover:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 12, 10)
	local teclas = P.Boton(p, "Asignar teclas", function()
		if M.EmpezarTeclas() and M.AbrirAyudaTeclas then M.AbrirAyudaTeclas() end
	end)
	teclas:SetPoint("LEFT", mover, "RIGHT", 8, 0)
	local ultimo = teclas
	if M.CopiaBartender() then
		local copiar = P.Boton(p, "Copiar mis barras de Bartender", function()
			if M.CopiarBartender() then elegir(elegida) end
		end)
		copiar:SetPoint("LEFT", ultimo, "RIGHT", 8, 0)
		ultimo = copiar
	end
	local deshacer = P.Boton(p, "Deshacer", function() if M.Deshacer() then elegir(elegida) end end)
	deshacer:SetPoint("LEFT", ultimo, "RIGHT", 8, 0)
	p:SetScript("OnShow", function() M.RefrescarPanel() end)
	elegir(elegida)
	M.RefrescarPanel()
end

function M.RefrescarPanel()
	for _, f in ipairs(lista) do
		local c = M.Config(f.id)
		f.cuenta:SetText(c.mostrar and tostring(c.botones) or "oculta")
	end
	if paginas[elegida] then refrescar(paginas[elegida]) end
end

---------------------------------------------------------------- dónde se abre
local ventana
local function ventanaPropia()
	if not ventana then
		ventana = P.Ventana("MambaBarrasVentana", "Mamba · Barras", ANCHO, ALTO)
		local m, top = ventana.margen or 16, ventana.cuerpo or 26
		local p = CreateFrame("Frame", nil, ventana)
		p:SetPoint("TOPLEFT", ventana, "TOPLEFT", m - 12, -top)
		p:SetPoint("BOTTOMRIGHT", ventana, "BOTTOMRIGHT", -(m - 12), 4)
		M.DibujarPanel(p, ANCHO - 2 * (m - 12), ALTO - top - 4)
	end
	return ventana
end

function M.AbrirOpciones(id)
	if id then elegida = id end
	local A = _G.Asistente
	if M.enVentanaMamba and A and A.AbrirVentana then
		A.AbrirVentana("barras")
	else
		ventanaPropia():Show()
	end
	if panel and not M.bloqueadoPor then elegir(elegida) end
end

-- Ayuda del modo "Asignar teclas" (una ventana chica arriba, con Listo).
local ayudaTeclas
function M.AbrirAyudaTeclas()
	if not ayudaTeclas then
		ayudaTeclas = P.Ventana("MambaBarrasTeclas", "Asignar teclas", 380, 170)
		ayudaTeclas:ClearAllPoints()
		ayudaTeclas:SetPoint("TOP", UIParent, "TOP", 0, -80)
		local m, top = ayudaTeclas.margen or 16, (ayudaTeclas.cuerpo or 26) + 4
		local t = P.Texto(ayudaTeclas, "body", "textDim")
		t:SetPoint("TOPLEFT", ayudaTeclas, "TOPLEFT", m, -top)
		t:SetPoint("RIGHT", ayudaTeclas, "RIGHT", -m, 0)
		t:SetText("Pasa el ratón por un botón y aprieta la tecla.\nRetroceso borra su tecla. Esc termina.")
		ayudaTeclas.estado = P.Texto(ayudaTeclas, "body", "accent")
		ayudaTeclas.estado:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
		local listo = P.Boton(ayudaTeclas, "Listo", function() M.TerminarTeclas() end, true)
		listo:SetPoint("BOTTOMRIGHT", ayudaTeclas, "BOTTOMRIGHT", -m, 14)
	end
	ayudaTeclas.estado:SetText("")
	ayudaTeclas:Show()
end
function M.AlApuntarTecla(b)
	if ayudaTeclas and ayudaTeclas:IsShown() then
		local k = M.TeclasDe(b)
		ayudaTeclas.estado:SetText(k ~= "" and ("Tecla: " .. k) or "Sin tecla")
	end
end
M.AlCambiarTecla = M.AlApuntarTecla
function M.AlTerminarTeclas() if ayudaTeclas then ayudaTeclas:Hide() end end

---------------------------------------------------------------- otro addon de barras: ofrecer el cambio una vez
local function apagarYRecargar()
	if InCombatLockdown() or not M.bloqueadoPor then return end
	if C_AddOns and C_AddOns.DisableAddOn then C_AddOns.DisableAddOn(M.bloqueadoPor) end
	ReloadUI()
end
M.ApagarOtroYRecargar = apagarYRecargar

local function ofrecerCambio()
	local p = M.PJ()
	if not M.bloqueadoPor or p.ofrecido then return end
	p.ofrecido = true
	local v = P.Ventana("MambaBarrasCambio", "Barras de Mamba", 420, 170)
	local m, top = v.margen or 16, (v.cuerpo or 26) + 4
	local t = P.Texto(v, "body", "text")
	t:SetPoint("TOPLEFT", v, "TOPLEFT", m, -top)
	t:SetPoint("RIGHT", v, "RIGHT", -m, 0)
	t:SetText("Mamba trae sus barras. Tus hechizos, teclas y lugares de " .. M.bloqueadoPor ..
		" pasan tal cual. ¿Usarlas?")
	local si = P.Boton(v, "Usar las barras de Mamba", apagarYRecargar, true)
	si:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", m, 14)
	local no = P.Boton(v, "Ahora no", function() v:Hide() end)
	no:SetPoint("LEFT", si, "RIGHT", 8, 0)
	v:Show()
end

-- Opciones › AddOns del juego: "Mamba: barras", con los mismos dos botones de entrada.
local function categoriaDelJuego()
	if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
	local f = CreateFrame("Frame")
	local t = P.Texto(f, "heading", "accent")
	t:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -16)
	t:SetText("Mamba: barras")
	local a = P.Boton(f, "Abrir las opciones de las barras", function() M.AbrirOpciones() end, true)
	a:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -12)
	local b = P.Boton(f, "Mover barras", function() M.EmpezarMover() end)
	b:SetPoint("LEFT", a, "RIGHT", 8, 0)
	local cat = Settings.RegisterCanvasLayoutCategory(f, "Mamba: barras")
	Settings.RegisterAddOnCategory(cat)
end

---------------------------------------------------------------- engancharse
local ev = CreateFrame("Frame")
M.Escuchar(ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
	M.Proteger("categoria", categoriaDelJuego)
	if M.bloqueadoPor then C_Timer.After(3, function() M.Proteger("ofrecer", ofrecerCambio) end) end
	local A = _G.Asistente
	-- 1) la ventana de Mamba (botón del minimapa), si ofrece pestañas con dibujo propio
	if A and A.RegistrarPestana then
		local ok = pcall(A.RegistrarPestana, { clave = "barras", nombre = "Barras", dibujar = M.DibujarPanel })
		M.enVentanaMamba = ok
	end
	-- 2) Ajustes de Polestar › Mamba › Barras: un botón que la abre
	if A and A.Opciones then
		pcall(A.Opciones, "Barras", "Barras", {
			{ kind = "button", label = "Abrir las opciones de las barras", onClick = function() M.AbrirOpciones() end },
			{ kind = "button", label = "Mover barras", onClick = function() M.EmpezarMover() end },
		})
	end
end)
