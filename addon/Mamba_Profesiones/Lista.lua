-- Mamba: la lista de recomendaciones con la estética de Polestar (misma fila que "Mi plan"): arriba un título,
-- dos líneas de números y los filtros (K62: "Solo", "Con grupo", "Tengo 15 min"); debajo filas con tipo,
-- título, detalle, una línea de confianza y hasta 3 botones ("Llévame", "Abrir guía"...). Cada módulo de
-- Mamba que la usa trae su copia (misma versión, mismo contrato). Licencia: GPL-3.0-only.
--   local L = M.Lista.Nueva(padre)
--   L:Dibujar({ titulo, linea1, linea2, filtros = { { clave, texto, activo } }, alFiltro = fn(clave) }, filas)
--   fila = { tipo, titulo, detalle, conf, acciones = { { "Llévame", fn }, ... } }
local _, M = ...
local P = M.Piezas
local Lista = {}
M.Lista = Lista

local function textoBoton(b, t)
	local _, _, W = P.Polestar()
	if W and W.SetButtonText and b.Label then W.SetButtonText(b, t)
	elseif b.Label then b.Label:SetText(t)
	elseif b.SetText then b:SetText(t) end
	b:SetWidth(math.max(70, ((b.Label and b.Label:GetStringWidth()) or (b.GetFontString and b:GetFontString() and b:GetFontString():GetStringWidth()) or 60) + 24))
end

local metodos = {}

function metodos:Fila(i, ancho)
	local f = self.pool[i]
	if not f then
		f = P.Fila(self.hijo, ancho, 54)
		f.tipo = P.Texto(f, "small", "textMuted")
		f.tipo:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
		f.tipo:SetWidth(92)
		f.titulo = P.Texto(f, "body", "text")
		f.titulo:SetPoint("TOPLEFT", f, "TOPLEFT", 108, -6)
		f.detalle = P.Texto(f, "note", "textDim")
		f.detalle:SetPoint("TOPLEFT", f.titulo, "BOTTOMLEFT", 0, -3)
		f.conf = P.Texto(f, "small", "textMuted")
		f.conf:SetPoint("TOPLEFT", f.detalle, "BOTTOMLEFT", 0, -2)
		f.botones = {}
		for k = 1, 3 do
			local b = P.Boton(f, "·", function() if f.acciones and f.acciones[k] then M.Proteger("boton", f.acciones[k]) end end, k == 1)
			b:SetHeight(22)
			f.botones[k] = b
		end
		self.pool[i] = f
	end
	f:SetWidth(ancho)
	f:ClearAllPoints()
	return f
end

local function llenar(f, d, ancho)
	f.tipo:SetText(d.tipo or "")
	f.titulo:SetText(d.titulo or "")
	f.detalle:SetText(d.detalle or "")
	f.conf:SetText(d.conf or "")
	f.acciones = {}
	for k = 1, 3 do f.botones[k]:Hide() end
	local x = -8
	local acc = d.acciones or {}
	for k = math.min(3, #acc), 1, -1 do
		local b = f.botones[k]
		textoBoton(b, acc[k][1])
		f.acciones[k] = acc[k][2]
		b:ClearAllPoints()
		b:SetPoint("TOPRIGHT", f, "TOPRIGHT", x, -8)
		b:Show()
		x = x - b:GetWidth() - 6
	end
	local libre = math.max(140, ancho - 108 + x - 10)
	f.titulo:SetWidth(libre)
	f.detalle:SetWidth(libre)
	f.conf:SetWidth(libre)
	local h = 14 + (f.titulo:GetStringHeight() or 14)
		+ ((d.detalle or "") ~= "" and (f.detalle:GetStringHeight() or 12) + 3 or 0)
		+ ((d.conf or "") ~= "" and (f.conf:GetStringHeight() or 12) + 2 or 0)
	f:SetHeight(math.max(40, h))
	f:Show()
	return f:GetHeight()
end

function metodos:Dibujar(c, filas)
	c = c or {}
	self.cab.titulo:SetText(c.titulo or "")
	self.cab.l1:SetText(c.linea1 or "")
	self.cab.l2:SetText(c.linea2 or "")
	-- filtros (botones; el activo, principal)
	for _, b in ipairs(self.chips) do b:Hide() end
	local x = 0
	for i, fl in ipairs(c.filtros or {}) do
		local b = self.chips[i]
		if not b or b.activo ~= (fl[3] and true or false) then
			if b then b:Hide() end
			b = P.Boton(self.cab, fl[2], function() if self.alFiltro then self.alFiltro(self.claves[i]) end end, fl[3])
			b:SetHeight(20)
			b.activo = fl[3] and true or false
			self.chips[i] = b
		end
		self.claves[i] = fl[1]
		textoBoton(b, fl[2])
		b:ClearAllPoints()
		b:SetPoint("BOTTOMLEFT", self.cab, "BOTTOMLEFT", x, 0)
		b:Show()
		x = x + b:GetWidth() + 6
	end
	self.alFiltro = c.alFiltro
	local ancho = math.max(300, (self.lista:GetWidth() or 600) - 14)
	local y = 0
	filas = filas or {}
	if #filas == 0 then filas = { { titulo = c.vacio or "Nada por ahora.", detalle = c.vacioDetalle } } end
	for i, d in ipairs(filas) do
		local f = self:Fila(i, ancho)
		f:SetPoint("TOPLEFT", self.hijo, "TOPLEFT", 0, -y)
		y = y + llenar(f, d, ancho) + 2
	end
	for i = #filas + 1, #self.pool do self.pool[i]:Hide() end
	self.hijo:SetHeight(math.max(1, y))
	local _, _, W = P.Polestar()
	if W and W.SetScrollContent then pcall(W.SetScrollContent, self.lista, y + 8, self.lista:GetHeight()) end
end

function Lista.Nueva(parent)
	local L = setmetatable({ pool = {}, chips = {}, claves = {} }, { __index = metodos })
	local cab = CreateFrame("Frame", nil, parent)
	cab:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -10)
	cab:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, -10)
	cab:SetHeight(84)
	cab.titulo = P.Texto(cab, "title", "text")
	cab.titulo:SetPoint("TOPLEFT", cab, "TOPLEFT", 0, 0)
	cab.l1 = P.Texto(cab, "body", "textDim")
	cab.l1:SetPoint("TOPLEFT", cab.titulo, "BOTTOMLEFT", 0, -6)
	cab.l1:SetPoint("RIGHT", cab, "RIGHT", 0, 0)
	cab.l2 = P.Texto(cab, "note", "textMuted")
	cab.l2:SetPoint("TOPLEFT", cab.l1, "BOTTOMLEFT", 0, -4)
	cab.l2:SetPoint("RIGHT", cab, "RIGHT", 0, 0)
	L.cab = cab
	local raya = P.Linea(parent, false)
	raya:SetPoint("TOPLEFT", cab, "BOTTOMLEFT", 0, -6)
	raya:SetPoint("TOPRIGHT", cab, "BOTTOMRIGHT", 0, -6)
	local _, _, W = P.Polestar()
	if W and W.Scroll then
		L.lista = W.Scroll(parent)
		L.hijo = L.lista.Child
	else
		L.lista = CreateFrame("ScrollFrame", nil, parent)
		L.hijo = CreateFrame("Frame", nil, L.lista)
		L.lista:SetScrollChild(L.hijo)
		L.lista:EnableMouseWheel(true)
		L.lista:SetScript("OnMouseWheel", function(s, d) s:SetVerticalScroll(math.max(0, s:GetVerticalScroll() - d * 40)) end)
	end
	L.lista:SetPoint("TOPLEFT", cab, "BOTTOMLEFT", 0, -12)
	L.lista:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
	L.hijo:SetWidth(math.max(300, (parent:GetWidth() or 640) - 40))
	return L
end

-- K62: puntuación simple de impacto ÷ costo, en estrellas.
function Lista.Estrellas(razon)
	if not razon then return "" end
	if razon >= 2 then return "★★★" elseif razon >= 0.7 then return "★★☆" end
	return "★☆☆"
end
