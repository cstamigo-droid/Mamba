-- Asistente/Hub.lua: las secciones de Mamba DENTRO del hub de Polestar (su riel izquierdo), con su estética.
-- Cada módulo se suma con A.Hub.Seccion(spec); el hub pone el riel, el buscador, el título y las pestañas, y
-- aquí se dibuja el cuerpo con piezas de Polestar (W.Text, W.Button, W.Scroll...). Nada sale por el chat.
--
--   A.Hub.Seccion({
--     clave, nombre, icono, orden,       -- icono: nombre de Polestar Media/UI o ruta de textura
--     addon = "Asistente_Equipo",       -- opcional: se carga al abrir la sección
--     pestanas = { {key,label} } | fn(est),
--     titulo = fn(est) -> titulo, subtitulo,
--     nav = fn(est) -> items, activo,    -- la barra lateral: FILTRA (ranura, tipo...), no repite las pestañas
--     onNav = fn(est, key),              -- opcional (por defecto: est.filtro = key)
--     buscar = "texto de ayuda" | nil,   -- con buscar, el buscador del hub filtra (est.busqueda)
--     dibujar = fn(est, V),              -- escribe el cuerpo con el constructor V (ver abajo)
--   })
--   A.Hub.Abrir(clave) · A.Hub.Redibujar() · A.Hub.Disponible()
--
-- Constructor V (todo se apila de arriba abajo; las filas miden 44 px):
--   V:Panel{ titulo, texto, boton = {texto, fn}, boton2 = {texto, fn} }   (el boton es el único dorado)
--   V:Segmentos(items, activo, fn, nota)   V:Columnas{ {titulo, ancho}, ... }   V:Fila{...}
--   V:Titulo(t, derecha)   V:Nota(t)   V:Vacio(titulo, texto, boton)   V:Botones{ {texto, fn, apagado}, ... }
--   V:Interruptor(texto, valor, fn)   V:Espacio(h)
--   Fila: { icono = itemID | textura, item = itemID | link, celdas = { {a, b}, ... }, ir = fn, irTexto,
--           clic = fn, derecho = fn(self), tip = fn(self), marca = "dungeon" | nil }
-- Licencia: GPL-3.0-only.
local A = _G.Asistente
local Hub = { secciones = {}, estado = {} }
A.Hub = Hub

local FILA_H, PAD = 44, 22
local max, min, floor, format = math.max, math.min, math.floor, string.format

local function PS() local p = _G.Polestar; return type(p) == "table" and p or nil end
local function W() local p = PS(); return p and p.Widgets end
local function Theme() local p = PS(); return p and p.Theme end
local function Picker() local p = PS(); return p and p.UI and p.UI.Picker end

function Hub.Disponible()
	local p = PS()
	return p and p.UI and p.UI.RegisterSection and p.Widgets and p.Widgets.Scroll and true or false
end

local function cargado(addon)
	if not addon then return true end
	local C = C_AddOns
	return C and C.IsAddOnLoaded and C.IsAddOnLoaded(addon) and true or false
end

function Hub.Est(clave)
	Hub.estado[clave] = Hub.estado[clave] or {}
	return Hub.estado[clave]
end

-- Vuelve a dibujar el hub si está a la vista (un dato que llegó después, un clic).
function Hub.Redibujar()
	local P = Picker()
	local win = _G.PolestarPicker
	if P and P.Render and win and win:IsShown() then pcall(P.Render) end
end

---------------------------------------------------------------- dinero con íconos
function A.Monedas(c)
	c = floor(tonumber(c) or 0)
	if GetCoinTextureString then
		local ok, t = pcall(GetCoinTextureString, c)
		if ok and t then return t end
	end
	local o, p, b = floor(c / 10000), floor(c / 100) % 100, c % 100
	local out = {}
	if o > 0 then out[#out + 1] = o .. "o" end
	if p > 0 then out[#out + 1] = p .. "p" end
	if b > 0 or #out == 0 then out[#out + 1] = b .. "c" end
	return table.concat(out, " ")
end

-- 32,5 % con coma, como en el resto de Mamba
function A.Pct(x, dec)
	if not x then return "sin datos aún" end
	if x > 999 then return "más de 999 %" end
	local t = dec == 0 and tostring(floor(x + 0.5)) or format("%.1f", x):gsub("%.0$", "")
	return (t:gsub("%.", ",")) .. " %"
end

---------------------------------------------------------------- el constructor de cuerpos
local V = {}
V.__index = V

local function color(fs, nombre)
	local w = W()
	if w and w.Color then w.Color(fs, nombre) end
end

local function pool(self, tipo, crear)
	local p = self.pools[tipo]
	if not p then p = { n = 0 }; self.pools[tipo] = p end
	p.n = p.n + 1
	local o = p[p.n]
	if not o then o = crear(self.child); p[p.n] = o end
	o:ClearAllPoints()
	o:Show()
	return o
end

function V:_colocar(o, h, x)
	o:SetPoint("TOPLEFT", self.child, "TOPLEFT", x or 0, -self.y)
	o:SetWidth(self.ancho - (x or 0))
	if h then o:SetHeight(h) end
	self.y = self.y + (h or o:GetHeight())
end

function V:Espacio(h) self.y = self.y + (h or 8) end

local function texto(parent, rol, col, wrap)
	local fs = W().Text(parent, rol, col)
	if wrap then fs:SetWordWrap(true); fs:SetJustifyV("TOP") end
	return fs
end

function V:Titulo(t, derecha)
	local o = pool(self, "titulo", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.T = texto(f, "label", "text")
		f.T:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 8)
		f.D = texto(f, "small", "textMuted")
		f.D:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 8)
		f.L = W().Divider(f)
		f.L:ClearAllPoints()
		f.L:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		f.L:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
		return f
	end)
	o.T:SetText(t or "")
	o.D:SetText(derecha or "")
	self:_colocar(o, 34)
end

function V:Nota(t, col)
	local o = pool(self, "nota", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.T = texto(f, "small", "textMuted", true)
		f.T:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4)
		return f
	end)
	o.T:SetWidth(self.ancho)
	color(o.T, col or "textMuted")
	o.T:SetText(t or "")
	self:_colocar(o, (o.T:GetStringHeight() or 12) + 10)
end

-- Un cuadro con un título, un texto y hasta dos botones. El primero es el dorado de la pantalla.
function V:Panel(s)
	local o = pool(self, "panel", function(p)
		local f = CreateFrame("Frame", nil, p)
		W().Fill(f, "panelAlt")
		f.T = texto(f, "title", "text")
		f.T:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -12)
		f.X = texto(f, "body", "textDim", true)
		f.X:SetPoint("TOPLEFT", f.T, "BOTTOMLEFT", 0, -6)
		f.B1 = W().Button(f, "", nil, { primary = true, height = 30, icon = "icon-goto" })
		f.B2 = W().Button(f, "", nil, { height = 28 })
		return f
	end)
	local ancho = self.ancho
	o.T:SetText(s.titulo or "")
	local derecha = (s.boton or s.boton2) and 220 or 0
	o.X:SetWidth(ancho - 32 - derecha)
	o.X:SetText(s.texto or "")
	for i, b in ipairs({ o.B1, o.B2 }) do
		local d = i == 1 and s.boton or s.boton2
		if d then
			W().SetButtonText(b, d[1])
			b:SetWidth(200)
			b:SetScript("OnClick", function() pcall(d[2]); Hub.Redibujar() end)
			b:ClearAllPoints()
			b:SetPoint("TOPRIGHT", o, "TOPRIGHT", -16, i == 1 and -14 or -50)
			b:Show()
		else
			b:Hide()
		end
	end
	local h = max(s.boton2 and 92 or 60, 12 + (o.T:GetStringHeight() or 16) + 6 + (o.X:GetStringHeight() or 14) + 14)
	self:_colocar(o, h)
	self:Espacio(10)
end

-- Botones de filtro en fila ("Ya", "Más adelante", "Todo"); el elegido, con fondo; nota a la derecha.
function V:Segmentos(items, activo, fn, nota)
	local o = pool(self, "segm", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.B = {}
		f.N = texto(f, "small", "textMuted")
		return f
	end)
	local x = 0
	for i, it in ipairs(items) do
		local b = o.B[i]
		if not b then b = W().Button(o, "", nil, { height = 26 }); o.B[i] = b end
		W().SetButtonText(b, it.label)
		b:SetWidth((b.Label:GetStringWidth() or 40) + 26)
		b:ClearAllPoints()
		b:SetPoint("LEFT", o, "LEFT", x, 0)
		if b.Label then color(b.Label, it.key == activo and "text" or "textMuted") end
		b:SetAlpha(it.key == activo and 1 or 0.8)
		b:SetScript("OnClick", function() fn(it.key); Hub.Redibujar() end)
		b:Show()
		x = x + b:GetWidth() + 2
	end
	for i = #items + 1, #o.B do o.B[i]:Hide() end
	o.N:ClearAllPoints()
	o.N:SetPoint("LEFT", o, "LEFT", x + 12, 0)
	o.N:SetWidth(max(50, self.ancho - x - 12))
	o.N:SetText(nota or "")
	self:_colocar(o, 30)
	self:Espacio(6)
end

-- Las columnas de las filas que siguen: { {titulo, ancho}, ... } (la última toma lo que sobra).
function V:Columnas(cols, sinCabecera)
	self.cols = cols
	if sinCabecera then return end
	local o = pool(self, "cabecera", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.T = {}
		return f
	end)
	local x = 0
	for i, c in ipairs(cols) do
		local fs = o.T[i]
		if not fs then fs = texto(o, "small", "textMuted"); o.T[i] = fs end
		fs:ClearAllPoints()
		fs:SetPoint("LEFT", o, "LEFT", x, 0)
		fs:SetWidth(max(10, (c[2] or 100) - 8))
		fs:SetText(c[1] and c[1]:upper() or "")
		fs:Show()
		x = x + (c[2] or 0)
	end
	for i = #cols + 1, #o.T do o.T[i]:Hide() end
	self:_colocar(o, 24)
end

local function filaEnter(self)
	local d = self.psDatos
	if not d then return end
	if d.item then
		local id = type(d.item) == "number" and d.item or tonumber(tostring(d.item):match("item:(%d+)"))
		if type(d.item) == "string" and GameTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			pcall(GameTooltip.SetHyperlink, GameTooltip, d.item)
			if d.tipExtra then for _, l in ipairs(d.tipExtra) do GameTooltip:AddLine(l, 0.76, 0.79, 0.87, true) end end
			GameTooltip:Show()
		elseif id then
			W().ItemTip(self, id, d.tipExtra)
		end
	elseif d.tip then
		pcall(d.tip, self)
	end
end

local function filaLeave(self)
	if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	local w = W()
	if w and w.HideTooltip then w.HideTooltip(self) end
end

local function iconoDe(x)
	if type(x) == "number" then
		local f = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
		return f and f(x) or "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	return x
end

function V:Fila(d)
	local o = pool(self, "fila", function(p)
		local f = CreateFrame("Button", nil, p)
		f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		W().Hover(f)
		f.Ic = f:CreateTexture(nil, "ARTWORK")
		f.Ic:SetSize(30, 30)
		f.Marca = f:CreateTexture(nil, "ARTWORK")
		f.Marca:SetTexture(Theme().Media("white"))
		f.Marca:SetSize(6, 6)
		f.L = W().Divider(f)
		f.L:ClearAllPoints()
		f.L:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		f.L:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
		f.A, f.B = {}, {}
		f.Ir = W().Button(f, "Ir", nil, { height = 24, icon = "icon-goto" })
		f.Ir:SetWidth(54)
		f:SetScript("OnEnter", filaEnter)
		f:SetScript("OnLeave", filaLeave)
		f:SetScript("OnClick", function(self, boton)
			local x = self.psDatos
			if not x then return end
			if boton == "RightButton" then
				if x.derecho then pcall(x.derecho, self) end
				return
			end
			if x.item and IsModifiedClick and IsModifiedClick("CHATLINK") then
				local w = W()
				if type(x.item) == "number" and w.ItemClick then w.ItemClick(x.item)
				elseif HandleModifiedItemClick then HandleModifiedItemClick(x.item) end
				return
			end
			if x.clic then pcall(x.clic, self); Hub.Redibujar() end
		end)
		return f
	end)
	o.psDatos = d
	local cols = self.cols or { { nil, self.ancho } }
	local x = 0
	local conIcono = d.icono ~= nil
	o.Ic:SetShown(conIcono)
	if conIcono then
		o.Ic:SetTexture(iconoDe(d.icono))
		o.Ic:ClearAllPoints()
		o.Ic:SetPoint("LEFT", o, "LEFT", (cols[1] and d.iconoEnCol2 and cols[1][2] or 0), 0)
	end
	o.Marca:SetShown(d.marca ~= nil)
	if d.marca then
		W().Color(o.Marca, d.marca)
		o.Marca:ClearAllPoints()
		o.Marca:SetPoint("RIGHT", o, "LEFT", -6, 0)
	end
	local derecha = d.ir and 64 or 0
	for i, c in ipairs(cols) do
		local ancho = c[2] or 100
		if i == #cols then ancho = max(40, self.ancho - x - derecha) end
		local cel = d.celdas and d.celdas[i] or {}
		local fa, fb = o.A[i], o.B[i]
		if not fa then
			fa = texto(o, "body", "text"); fb = texto(o, "small", "textMuted")
			o.A[i], o.B[i] = fa, fb
		end
		local dx = (conIcono and ((d.iconoEnCol2 and i == 2) or (not d.iconoEnCol2 and i == 1))) and 40 or 0
		fa:ClearAllPoints(); fb:ClearAllPoints()
		local dos = cel[2] and cel[2] ~= ""
		fa:SetPoint(dos and "BOTTOMLEFT" or "LEFT", o, dos and "LEFT" or "LEFT", x + dx, dos and 1 or 0)
		fb:SetPoint("TOPLEFT", o, "LEFT", x + dx, -2)
		fa:SetWidth(ancho - dx - 8); fb:SetWidth(ancho - dx - 8)
		color(fa, cel.col or "text")
		fa:SetText(cel[1] or ""); fb:SetText(cel[2] or "")
		fa:Show(); fb:SetShown(dos)
		x = x + ancho
	end
	for i = #cols + 1, #o.A do o.A[i]:Hide(); o.B[i]:Hide() end
	if d.ir then
		W().SetButtonText(o.Ir, d.irTexto or "Ir")
		o.Ir:SetWidth(d.irTexto and ((o.Ir.Label:GetStringWidth() or 30) + 36) or 54)
		o.Ir:ClearAllPoints()
		o.Ir:SetPoint("RIGHT", o, "RIGHT", -4, 0)
		o.Ir:SetScript("OnClick", function() pcall(d.ir); Hub.Redibujar() end)
		o.Ir:Show()
	else
		o.Ir:Hide()
	end
	o:EnableMouse(true)
	self:_colocar(o, FILA_H)
end

-- Un estado sin contenido (combate, sin datos, sin resultados...): ícono, título, texto, botón.
function V:Vacio(titulo, txt, boton)
	local o = pool(self, "vacio", function(p)
		local f = CreateFrame("Frame", nil, p)
		W().Fill(f, "panel")
		f.T = texto(f, "title", "text")
		f.T:SetJustifyH("CENTER")
		f.T:SetPoint("TOP", f, "TOP", 0, -26)
		f.X = texto(f, "body", "textDim", true)
		f.X:SetJustifyH("CENTER")
		f.X:SetPoint("TOP", f.T, "BOTTOM", 0, -8)
		f.B = W().Button(f, "", nil, { height = 28 })
		return f
	end)
	o.T:SetText(titulo or "")
	o.X:SetWidth(min(520, self.ancho - 60))
	o.X:SetText(txt or "")
	local h = 26 + (o.T:GetStringHeight() or 16) + 8 + (o.X:GetStringHeight() or 14) + 26
	if boton then
		W().SetButtonText(o.B, boton[1])
		o.B:SetWidth((o.B.Label:GetStringWidth() or 60) + 32)
		o.B:ClearAllPoints()
		o.B:SetPoint("TOP", o.X, "BOTTOM", 0, -12)
		o.B:SetScript("OnClick", function() pcall(boton[2]); Hub.Redibujar() end)
		o.B:Show()
		h = h + 40
	else
		o.B:Hide()
	end
	self:_colocar(o, h)
	self:Espacio(10)
end

function V:Botones(lista, nota)
	local o = pool(self, "botones", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.B = {}
		f.N = texto(f, "small", "textMuted", true)
		return f
	end)
	local x = 0
	for i, d in ipairs(lista) do
		local b = o.B[i]
		if not b then b = W().Button(o, "", nil, { height = 28 }); o.B[i] = b end
		W().SetButtonText(b, d[1])
		b:SetWidth((b.Label:GetStringWidth() or 60) + 30)
		b:ClearAllPoints()
		b:SetPoint("LEFT", o, "LEFT", x, 0)
		if d.apagado then b:Disable() else b:Enable() end
		b:SetScript("OnClick", function() pcall(d[2]); Hub.Redibujar() end)
		b:Show()
		x = x + b:GetWidth() + 8
	end
	for i = #lista + 1, #o.B do o.B[i]:Hide() end
	o.N:ClearAllPoints()
	o.N:SetPoint("LEFT", o, "LEFT", x + 6, 0)
	o.N:SetWidth(max(60, self.ancho - x - 6))
	o.N:SetText(nota or "")
	self:_colocar(o, max(34, (o.N:GetStringHeight() or 12) + 8))
end

function V:Interruptor(txt, valor, fn)
	local o = pool(self, "sw", function(p)
		local f = CreateFrame("Frame", nil, p)
		f.C = W().Checkbox(f)
		f.C:SetPoint("LEFT", f, "LEFT", 0, 0)
		f.T = texto(f, "body", "text")
		f.T:SetPoint("LEFT", f.C, "RIGHT", 8, 0)
		return f
	end)
	o.C:SetChecked(valor and true or false)
	o.C:SetScript("OnClick", function(c) pcall(fn, c:GetChecked() and true or false); Hub.Redibujar() end)
	o.T:SetText(txt)
	self:_colocar(o, 28)
end

---------------------------------------------------------------- registrar en el hub de Polestar
local function construir(spec)
	return function(parent)
		local raiz = CreateFrame("Frame", nil, parent)
		raiz:SetAllPoints(parent)
		local sc = W().Scroll(raiz)
		sc:SetPoint("TOPLEFT", raiz, "TOPLEFT", PAD, -12)
		sc:SetPoint("BOTTOMRIGHT", raiz, "BOTTOMRIGHT", -PAD + 8, 12)
		spec.psRaiz, spec.psScroll = raiz, sc
	end
end

local function dibujarCuerpo(spec, est)
	local sc = spec.psScroll
	if not sc then return end
	local ancho = max(400, (sc:GetWidth() or 0) > 50 and (sc:GetWidth() - 12) or 840)
	sc.Child:SetWidth(ancho)
	local b = spec.psV
	if not b then b = setmetatable({ pools = {}, child = sc.Child }, V); spec.psV = b end
	for _, p in pairs(b.pools) do
		for i = 1, #p do p[i]:Hide() end
		p.n = 0
	end
	b.y, b.ancho, b.cols = 0, ancho, nil
	if A.EnCombate and A.EnCombate() and spec.addon and not cargado(spec.addon) then
		b:Vacio("En combate", "Esta sección se abre sola cuando termine el combate.")
	elseif not cargado(spec.addon) then
		b:Vacio("Cargando…", "Un momento: Mamba está cargando " .. spec.nombre .. ".")
		if A.Cargar then A.Cargar(spec.addon, function() Hub.Redibujar() end) end
	else
		local ok, err = pcall(spec.dibujar, est, b)
		if not ok then
			b:Vacio("Algo falló al armar esta sección", "Abre «Errores» en el riel de la izquierda: ahí está el detalle para mandárselo a Cristian.")
			if geterrorhandler then geterrorhandler()(err) end
		end
	end
	W().SetScrollContent(sc, b.y + 16, sc:GetHeight())
end

function Hub.Seccion(spec)
	Hub.secciones[spec.clave] = spec
	local p = PS()
	if not Hub.Disponible() then return false end
	local UI = p.UI
	local est = Hub.Est(spec.clave)
	local reg = {
		key = spec.clave, label = spec.nombre, icon = spec.icono or "compact", order = spec.orden or 100,
		build = construir(spec),
		render = function()
			local w, win = W(), _G.PolestarPicker
			est.pestana = est.pestana or (type(spec.pestanas) == "table" and spec.pestanas[1] and spec.pestanas[1].key)
			if win then
				local tabs = type(spec.pestanas) == "function" and spec.pestanas(est) or spec.pestanas
				if tabs and #tabs > 0 then
					if est.pestana ~= est.pestanaVista then spec.psScroll = spec.psScroll end
					w.ShellTabs(win, tabs, est.pestana, function(key)
						if est.pestana ~= key then est.filtro = nil end
						est.pestana = key
						Hub.Redibujar()
					end)
				end
				if spec.titulo then
					local ok, t, s = pcall(spec.titulo, est)
					if ok then w.ShellTitle(win, t, s) end
				end
			end
			if est.pestana ~= est.pestanaVista and spec.psScroll and w.ScrollTo then w.ScrollTo(spec.psScroll, 0) end
			est.pestanaVista = est.pestana
			dibujarCuerpo(spec, est)
			Hub.ultima = spec.clave
			if AsistenteDB then AsistenteDB.hubUltima = spec.clave end
		end,
	}
	if spec.nav then
		reg.nav = function()
			local ok, items, activo = pcall(spec.nav, est)
			if ok then return items, activo end
			return {}, nil
		end
		reg.onNav = function(key)
			if spec.onNav then spec.onNav(est, key) else est.filtro = key end
			local P = Picker()
			if P and P.Render then P.Render() end
		end
	end
	if spec.buscar then
		reg.searchPlaceholder = spec.buscar
		reg.search = function(t)
			est.busqueda = t
			Hub.Redibujar()
		end
	end
	return UI.RegisterSection(reg)
end

-- Abre el hub en una sección de Mamba (la última que viste si clave es nil).
function Hub.Abrir(clave, pestana)
	if not Hub.Disponible() then return false end
	clave = clave or Hub.ultima or (AsistenteDB and AsistenteDB.hubUltima) or "MambaEquipo"
	if not Hub.secciones[clave] then clave = "MambaEquipo" end
	if pestana then Hub.Est(clave).pestana = pestana end
	local p = PS()
	if p.UI.ShowPicker then p.UI.ShowPicker() end
	local P = Picker()
	if P and P.ShowSection then P.ShowSection(clave) end
	return true
end

-- El hub está abierto en una sección de Mamba
function Hub.Abierto()
	local win, P = _G.PolestarPicker, Picker()
	if not (win and win:IsShown() and P and P.Section) then return false end
	return Hub.secciones[P.Section()] ~= nil
end

function Hub.Alternar()
	if Hub.Abierto() then _G.PolestarPicker:Hide() return end
	Hub.Abrir()
end
