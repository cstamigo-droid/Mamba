-- Mamba_Bolsas: la ventana de las bolsas y la del banco (la misma pieza, dos veces).
-- Dirección de arte (skill direccion-de-arte; K104, 18-11: "más en el estilo de Bagnon"): la ESTRUCTURA y la
-- DENSIDAD de Bagnon con las piezas de Polestar, sin su arte. Arriba el retrato redondo que sobresale de la esquina
-- (clic = otro personaje), "Inventario de Hope" y los botones; el buscador a todo lo ancho; la fila de bolsas, que
-- también es la regla de capacidad (ícono, libres/total y una regla fina que se llena; clic = ver solo esa bolsa,
-- pasar el ratón = se encienden sus casillas); la rejilla apretada (2 px); abajo las casillas libres y el oro. Los
-- filtros son pestañas de ícono pegadas al borde izquierdo, por fuera. Un solo acento (el de la apariencia) para lo
-- elegido, lo nuevo y la bolsa resaltada; la calidad usa los colores del juego.
--   * Casillas en vivo: botones ContainerFrameItemButtonTemplate del juego (usar, arrastrar, dividir, Mayús+clic,
--     vender y depositar funcionan como en la bolsa del juego), hijos de un marco por bolsa con SetID(bolsa).
--     Se crean FUERA de combate; si una bolsa crece en combate, sus casillas aparecen al salir.
--   * Casillas guardadas (otro personaje, o el banco lejos del banquero): botones propios, solo para mirar.
--   * Encima de cada casilla: borde por calidad, marca de basura / vender / subastar / guardar, flecha y brillo de
--     mejora (Polestar), signo de misión y el brillo de lo nuevo.
-- El menú del objeto (Alt + clic derecho) es el de la ventana de Mamba (SecSubasta.lua lo abre sobre cualquier
-- bolsa leyendo el cuadro del objeto): aquí NO se agrega otro. Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas

-- Medidas (K104: la estructura y la densidad de Bagnon, con las piezas de Polestar)
local HUECO = 2         -- entre casillas
local CABEZA = 34       -- alto de la cabecera (retrato, título, botones)
local BUSCADOR = 22     -- alto del buscador
local FILA_BOLSAS = 28  -- alto de una fila de la barra de bolsas
local CELDA = 64        -- ancho de cada bolsa en la barra
local PIE = 24          -- alto del pie (libres y oro)
local PESTANA = 30      -- pestañas de filtro en el borde izquierdo
local RETRATO = 48      -- el retrato redondo que sobresale de la esquina
local MARGEN = 10
local PRIMERA_PESTANA = 48 -- bajo el retrato
local MIN_ANCHO = 340

local function PS()
	local p = _G.Polestar
	local T, W = p and p.Theme, p and p.Widgets
	if T and W and W.Text and W.IconButton and T.Color then return p, T, W end
end

local function color(tex, token, a)
	local _, T, W = PS()
	if W and W.Color then W.Color(tex, token, a); return end
	local c = ({ accent = { 1, 0.82, 0 }, success = { 0.25, 1, 0.25 }, warning = { 1, 0.6, 0.2 }, textMuted = { 0.6, 0.6, 0.6 },
		text = { 1, 1, 1 }, divider = { 1, 1, 1 } })[token] or { 1, 1, 1 }
	if tex.SetVertexColor then tex:SetVertexColor(c[1], c[2], c[3], a or 1) end
	if tex.SetTextColor then tex:SetTextColor(c[1], c[2], c[3], a or 1) end
end

local BLANCO = "Interface\\Buttons\\WHITE8X8"
local function tex(padre, capa, sub)
	local t = padre:CreateTexture(nil, capa or "ARTWORK", nil, sub)
	t:SetTexture(BLANCO)
	return t
end

local function media(nombre)
	local _, T = PS()
	if T and T.Media then
		local ok, m = pcall(T.Media, T.Icon and T.Icon(nombre) or nombre)
		if ok and m then return m end
	end
end

local function iconoBoton(padre, icono, ayuda, alClic)
	local _, _, W = PS()
	if W then return W.IconButton(padre, icono, 24, ayuda, alClic, 14) end
	local b = CreateFrame("Button", nil, padre, "UIPanelButtonTemplate")
	b:SetSize(24, 24)
	b:SetText(ayuda and ayuda:sub(1, 1) or "?")
	b:SetScript("OnClick", alClic)
	return b
end

local function calidadRGB(q)
	if not q or q < 0 then return nil end
	if C_Item and C_Item.GetItemQualityColor then
		local ok, r, g, b = pcall(C_Item.GetItemQualityColor, q)
		if ok and r then return r, g, b end
	end
	local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	if c then return c.r, c.g, c.b end
end

---------------------------------------------------------------- encima de cada casilla
local function adornar(b)
	if b.mamba then return b.mamba end
	local o = {}
	o.borde = {}
	for i, punto in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true },
		{ "TOPLEFT", "BOTTOMLEFT", false }, { "TOPRIGHT", "BOTTOMRIGHT", false } }) do
		local t = tex(b, "OVERLAY", 2)
		t:SetPoint(punto[1], b, punto[1], 0, 0)
		t:SetPoint(punto[2], b, punto[2], 0, 0)
		if punto[3] then t:SetHeight(1) else t:SetWidth(1) end
		t:Hide()
		o.borde[i] = t
	end
	o.resalte = tex(b, "OVERLAY", 1)
	o.resalte:SetAllPoints(b)
	color(o.resalte, "accent", 0.28)
	o.resalte:Hide()
	o.nuevo = b:CreateTexture(nil, "OVERLAY", nil, 3)
	o.nuevo:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	o.nuevo:SetBlendMode("ADD")
	o.nuevo:SetPoint("CENTER", b, "CENTER", 0, 0)
	color(o.nuevo, "accent", 0.9)
	o.nuevo:Hide()
	o.mejoraBrillo = b:CreateTexture(nil, "OVERLAY", nil, 2)
	o.mejoraBrillo:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
	o.mejoraBrillo:SetBlendMode("ADD")
	o.mejoraBrillo:SetPoint("CENTER", b, "CENTER", 0, 0)
	color(o.mejoraBrillo, "success", 0.7)
	o.mejoraBrillo:Hide()
	o.mejora = b:CreateTexture(nil, "OVERLAY", nil, 4)
	o.mejora:SetTexture(media("qol-upgrade") or "Interface\\Buttons\\UI-MicroStream-Green")
	o.mejora:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
	color(o.mejora, "success")
	o.mejora:Hide()
	o.mision = b:CreateTexture(nil, "OVERLAY", nil, 4)
	o.mision:SetTexture("Interface\\GossipFrame\\ActiveQuestIcon")
	o.mision:SetPoint("TOPRIGHT", b, "TOPRIGHT", -1, -1)
	o.mision:Hide()
	o.marca = b:CreateTexture(nil, "OVERLAY", nil, 4)
	o.marca:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 2, 2)
	o.marca:Hide()
	b.mamba = o
	return o
end

local MARCA = {
	basura = { "Interface\\Buttons\\UI-GroupLoot-Coin-Up", true },
	vender = { "Interface\\Icons\\INV_Misc_Coin_02", false },
	subastar = { "Interface\\Buttons\\UI-GroupLoot-Coin-Up", false },
	guardar = { "Interface\\PetBattles\\PetBattle-LockIcon", false },
}

local BASE = 37 -- tamaño de la plantilla del juego: las casillas en vivo se escalan, no se estiran
local function pintar(b, d, f)
	local o = adornar(b)
	local tam = b.vivo and BASE or f.tam
	o.nuevo:SetSize(tam * 1.75, tam * 1.75)
	o.mejoraBrillo:SetSize(tam * 1.75, tam * 1.75)
	o.mejora:SetSize(math.max(12, tam * 0.45), math.max(12, tam * 0.45))
	o.mision:SetSize(math.max(11, tam * 0.36), math.max(11, tam * 0.36))
	o.marca:SetSize(math.max(11, tam * 0.36), math.max(11, tam * 0.36))
	local r, g, bl = calidadRGB(d and d.id and d.calidad)
	local _, _, W = PS()
	for _, t in ipairs(o.borde) do
		if r and d.calidad >= 2 then
			if W and W.Uncolor then W.Uncolor(t) end -- el color de la calidad no sigue a la apariencia
			t:SetVertexColor(r, g, bl, 0.95); t:Show()
		else t:Hide() end
	end
	local marcas = M.Op("marcas") and d and d.id
	local m = marcas and M.Marca(d) or nil
	if m and MARCA[m] then
		o.marca:SetTexture(MARCA[m][1])
		o.marca:SetDesaturated(MARCA[m][2])
		o.marca:SetAlpha(m == "basura" and 0.9 or 1)
		o.marca:Show()
	else o.marca:Hide() end
	o.mision:SetShown(marcas and M.EsDeMision(d) or false)
	local mejora = M.Op("mejora") and f.dueno == M.Clave() and d and d.id and M.EsMejora(d)
	o.mejora:SetShown(mejora or false)
	o.mejoraBrillo:SetShown(mejora or false)
	o.nuevo:SetShown(M.Op("nuevo") and d and d.nuevo or false)
	o.resalte:SetShown(f.resalte ~= nil and d and d.bolsa == f.resalte or false)
	local pasa = M.Pasa(f.filtro, d) and M.Coincide(f.texto, d)
	b:SetAlpha(pasa and 1 or 0.18)
end

---------------------------------------------------------------- casillas en vivo
local num = 0
local function marcoBolsa(f, bolsa)
	f.marcos = f.marcos or {}
	local m = f.marcos[bolsa]
	if m then return m end
	m = CreateFrame("Frame", nil, f.rejilla)
	m:SetID(bolsa) -- la plantilla lee la bolsa con GetParent():GetID()
	m:SetAllPoints(f.rejilla)
	m.botones = {}
	f.marcos[bolsa] = m
	return m
end

-- Partes de la plantilla del juego que su propio código prende y apaga; sin sus scripts quedan prendidas (el brillo
-- azul de tienda en todas las casillas, el "?" de misión, el oscurecido): Mamba dibuja las suyas y estas van ocultas.
local PARTES_DEL_JUEGO = { "BattlepayItemTexture", "NewItemTexture", "IconQuestTexture", "JunkIcon", "UpgradeIcon",
	"IconOverlay", "IconOverlay2", "ItemContextOverlay", "searchOverlay", "ExtendedSlot", "ExtendedOverlay", "ExtendedOverlay2" }
local function apagarPartes(b)
	for _, k in ipairs(PARTES_DEL_JUEGO) do
		local r = b[k]
		if type(r) == "table" and r.Hide then r:Hide() end
	end
	if b.IconBorder then b.IconBorder:SetAlpha(0) end
end
M.ApagarPartes = apagarPartes

local function crearVivo(m, casilla)
	num = num + 1
	local nombre = "MambaBolsasCasilla" .. num
	local ok, b = pcall(CreateFrame, "ItemButton", nombre, m, "ContainerFrameItemButtonTemplate")
	if not ok or not b then b = CreateFrame("Button", nombre, m, "ContainerFrameItemButtonTemplate") end
	b:SetID(casilla)
	-- el botón del juego se actualiza solo con sus eventos: aquí lo hace la ventana
	b:SetScript("OnEvent", nil)
	b:SetScript("OnShow", nil)
	if b.HookScript then
		b:HookScript("OnEnter", function(self)
			local bolsa = self:GetParent():GetID()
			if C_NewItems and C_NewItems.IsNewItem and C_NewItems.IsNewItem(bolsa, self:GetID()) then
				pcall(C_NewItems.RemoveNewItem, bolsa, self:GetID())
				if self.mamba then self.mamba.nuevo:Hide() end
			end
			apagarPartes(self) -- el código del juego al pasar el ratón puede volver a prenderlas
		end)
	end
	apagarPartes(b)
	b.vivo = true
	return b
end

-- ¿Faltan casillas por crear? Se crean aquí (fuera de combate). Devuelve true si quedó alguna pendiente.
local function asegurarVivos(f, bolsas)
	local falta = false
	for _, bolsa in ipairs(bolsas) do
		local m = marcoBolsa(f, bolsa)
		for s = #m.botones + 1, M.Casillas(bolsa) do
			if InCombatLockdown and InCombatLockdown() then falta = true; break end
			m.botones[s] = crearVivo(m, s)
		end
	end
	return falta
end

local function datosVivo(bolsa, casilla)
	local info = M.Info(bolsa, casilla)
	local d = { bolsa = bolsa, casilla = casilla }
	if info then
		d.id, d.link, d.n, d.calidad, d.icono = info.itemID, info.hyperlink, info.stackCount or 1, info.quality, info.iconFileID
		d.bloqueado, d.mision = info.isLocked, nil
		if C_Container and C_Container.GetContainerItemQuestInfo then
			local ok, q = pcall(C_Container.GetContainerItemQuestInfo, bolsa, casilla)
			if ok and type(q) == "table" and (q.isQuestItem or q.questID) then d.mision = true end
		end
		if C_NewItems and C_NewItems.IsNewItem then
			local ok, n = pcall(C_NewItems.IsNewItem, bolsa, casilla)
			d.nuevo = ok and n or false
		end
	end
	return d
end

local VACIA = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
local function actualizarVivo(b, d, f)
	-- sin escribir campos propios en el botón del juego (hasItem, readable…): lo que el clic lee queda del juego
	if SetItemButtonTexture then pcall(SetItemButtonTexture, b, d.icono or VACIA) end
	if SetItemButtonCount then pcall(SetItemButtonCount, b, d.n or 0) end
	if SetItemButtonDesaturated then pcall(SetItemButtonDesaturated, b, d.bloqueado and true or false) end
	local icon = b.icon or b.Icon
	if icon and icon.SetAlpha then icon:SetAlpha(d.id and 1 or 0.35) end
	if b.Cooldown and CooldownFrame_Set and C_Container and C_Container.GetContainerItemCooldown then
		local ok, s, dur, en = pcall(C_Container.GetContainerItemCooldown, d.bolsa, d.casilla)
		if ok then pcall(CooldownFrame_Set, b.Cooldown, s, dur, en) end
	end
	apagarPartes(b)
	pintar(b, d, f)
end

---------------------------------------------------------------- casillas guardadas (solo mirar)
local function crearGuardado(f)
	local b = CreateFrame("Button", nil, f.rejilla)
	b.icono = b:CreateTexture(nil, "ARTWORK")
	b.icono:SetAllPoints(b)
	b.cuenta = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	b.cuenta:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
	b:SetScript("OnEnter", function(self)
		if not (self.link and GameTooltip) then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if GameTooltip.SetHyperlink then pcall(GameTooltip.SetHyperlink, GameTooltip, self.link) end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
	b:SetScript("OnClick", function(self)
		if self.link and IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then ChatEdit_InsertLink(self.link) end
	end)
	return b
end

local function actualizarGuardado(b, d, f)
	b.link = d.link
	local icono = d.id and ((C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(d.id)) or (GetItemIcon and GetItemIcon(d.id)))
	b.icono:SetTexture(icono or VACIA)
	b.icono:SetAlpha(d.id and 1 or 0.35)
	b.cuenta:SetText((d.n and d.n > 1) and d.n or "")
	pintar(b, d, f)
end

local function calidadDe(link, id)
	local q = link and C_Item and C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(link)
	if not q and id and GetItemInfo then q = select(3, GetItemInfo(id)) end
	if not q and link then
		local hex = link:match("|c(%x%x%x%x%x%x%x%x)")
		local tabla = { ff9d9d9d = 0, ffffffff = 1, ff1eff00 = 2, ff0070dd = 3, ffa335ee = 4, ffff8000 = 5 }
		q = hex and tabla[hex:lower()]
	end
	return q
end

---------------------------------------------------------------- qué se muestra
-- ¿En vivo o guardado? En vivo: tus bolsas siempre; el banco solo con el banquero abierto.
function M.EsVivo(f)
	if f.dueno ~= M.Clave() then return false end
	if f.tipo == "banco" then return M.bancoAbierto end
	return true
end

local function bolsasDe(f)
	if M.EsVivo(f) then
		local t = f.tipo == "banco" and M.BolsasBanco() or M.BolsasInventario()
		local out = {}
		for _, b in ipairs(t) do if M.Casillas(b) > 0 then out[#out + 1] = b end end
		return out
	end
	local p = M.DB().personajes[f.dueno]
	local out = {}
	for b in pairs(p and p.slots or {}) do
		if M.EsBanco(b) == (f.tipo == "banco") then out[#out + 1] = b end
	end
	table.sort(out)
	return out
end
M.BolsasDeVentana = bolsasDe

-- La lista de casillas a dibujar: { d, ... } con d.bolsa y d.casilla, y d.nueva fila si "separar".
local function casillas(f, bolsas)
	local out = {}
	local vivo = M.EsVivo(f)
	local p = not vivo and M.DB().personajes[f.dueno]
	local orden = {}
	for _, b in ipairs(bolsas) do orden[#orden + 1] = b end
	if M.Op("reves") then
		local inv = {}
		for i = #orden, 1, -1 do inv[#inv + 1] = orden[i] end
		orden = inv
	end
	for _, b in ipairs(orden) do
		if not f.sola or f.sola == b then
			local n = vivo and M.Casillas(b) or (p and p.slots[b] and p.slots[b].n or 0)
			for s = 1, n do
				local d
				if vivo then d = datosVivo(b, s)
				else
					d = { bolsa = b, casilla = s }
					local x = p.slots[b].items and p.slots[b].items[s]
					if x then
						d.id, d.n, d.link = M.Partir(x)
						d.calidad = calidadDe(d.link, d.id)
					end
				end
				if s == 1 and M.Op("separar") and #out > 0 then d.filaNueva = true end
				out[#out + 1] = d
			end
		end
	end
	return out
end
M.CasillasDeVentana = casillas

---------------------------------------------------------------- la fila de bolsas (arriba, como Bagnon) + regla de capacidad
local function celda(f, i)
	f.celdas = f.celdas or {}
	local c = f.celdas[i]
	if c then return c end
	c = CreateFrame("Button", nil, f.filaBolsas)
	c:SetSize(CELDA - 4, FILA_BOLSAS - 2)
	c.icono = c:CreateTexture(nil, "ARTWORK")
	c.icono:SetSize(22, 22)
	c.icono:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
	c.texto = P.Texto(c, "number", "text")
	c.texto:SetPoint("LEFT", c.icono, "RIGHT", 4, 0)
	c.regla = tex(c, "BORDER")
	c.regla:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 1)
	c.regla:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, 1)
	c.regla:SetHeight(2)
	color(c.regla, "divider", 0.5)
	c.lleno = tex(c, "ARTWORK")
	c.lleno:SetPoint("BOTTOMLEFT", c.regla, "BOTTOMLEFT", 0, 0)
	c.lleno:SetHeight(2)
	c.elegida = tex(c, "BACKGROUND")
	c.elegida:SetAllPoints(c)
	color(c.elegida, "accent", 0.14)
	c.elegida:Hide()
	c:RegisterForDrag("LeftButton")
	c:SetScript("OnEnter", function(self)
		f.resalte = self.bolsa
		M.PintarResalte(f)
		local lineas = { self.libres .. " libres de " .. self.total, "Clic: ver solo esta bolsa · otra vez: todas" }
		if self.inv and M.EsVivo(f) then lineas[#lineas + 1] = "Arrastra una bolsa aquí para ponértela" end
		local A = _G.Asistente
		if A and A.CuadroAyuda then A.CuadroAyuda(self, self.nombre or "Bolsa", lineas) end
	end)
	c:SetScript("OnLeave", function()
		f.resalte = nil
		M.PintarResalte(f)
		if GameTooltip then GameTooltip:Hide() end
	end)
	c:SetScript("OnClick", function(self)
		if CursorHasItem and CursorHasItem() and M.EsVivo(f) and not InCombatLockdown() then
			if self.bolsa == 0 and PutItemInBackpack then pcall(PutItemInBackpack); return end
			if self.inv and PutItemInBag then pcall(PutItemInBag, self.inv); return end
		end
		f.sola = (f.sola ~= self.bolsa) and self.bolsa or nil
		M.Dibujar(f)
	end)
	c:SetScript("OnReceiveDrag", function(self)
		if not M.EsVivo(f) or InCombatLockdown() then return end
		if self.bolsa == 0 and PutItemInBackpack then pcall(PutItemInBackpack)
		elseif self.inv and PutItemInBag then pcall(PutItemInBag, self.inv) end
	end)
	c:SetScript("OnDragStart", function(self)
		if self.inv and self.bolsa ~= 0 and PickupBagFromSlot and M.EsVivo(f) and not InCombatLockdown() then pcall(PickupBagFromSlot, self.inv) end
	end)
	f.celdas[i] = c
	return c
end

-- Dibuja la fila de bolsas (si está a la vista) y los totales del pie. Devuelve el alto de la fila (0 si oculta).
local function dibujarBolsas(f, bolsas, anchoUtil)
	local vivo = M.EsVivo(f)
	local p = M.DB().personajes[f.dueno]
	local libresT, totalT = 0, 0
	local verFila = M.Op("verBolsas")
	local porFila = math.max(1, math.floor((anchoUtil + 4) / CELDA))
	for i, b in ipairs(bolsas) do
		local c = celda(f, i)
		local libres, total, nombre, icono, inv
		if vivo then
			libres, total = M.Espacio(b)
			nombre, icono, inv = M.DatosBolsa(b)
		else
			local s = p and p.slots[b] or {}
			total = s.n or 0
			local usadas = 0
			for _ in pairs(s.items or {}) do usadas = usadas + 1 end
			libres, nombre, icono = total - usadas, s.nombre, s.icono
		end
		c.bolsa, c.libres, c.total, c.nombre, c.inv = b, libres, total, nombre, inv
		c.icono:SetTexture(icono or VACIA)
		c.texto:SetText(libres .. "/" .. total)
		color(c.texto, libres == 0 and "warning" or "text")
		local usado = total > 0 and (total - libres) / total or 0
		c.lleno:SetWidth(math.max(1, (CELDA - 4) * usado))
		color(c.lleno, libres == 0 and "warning" or (f.sola == b and "accent" or "textMuted"), 0.9)
		c.elegida:SetShown(f.sola == b)
		c:ClearAllPoints()
		local fila, col = math.floor((i - 1) / porFila), (i - 1) % porFila
		c:SetPoint("TOPLEFT", f.filaBolsas, "TOPLEFT", col * CELDA, -fila * FILA_BOLSAS)
		c:SetShown(verFila)
		libresT, totalT = libresT + libres, totalT + total
	end
	for i = #bolsas + 1, #(f.celdas or {}) do f.celdas[i]:Hide() end
	f.libresTexto:SetText(libresT .. "/" .. totalT)
	color(f.libresTexto, libresT <= 2 and "warning" or "text")
	f.libresT = libresT
	local oro = (f.tipo ~= "banco") and p and p.oro
	f.oroTexto:SetText(oro and (GetCoinTextureString and GetCoinTextureString(oro) or M.Dinero(oro)) or "")
	if not verFila or #bolsas == 0 then f.filaBolsas:SetHeight(1); return 0 end
	local alto = math.ceil(#bolsas / porFila) * FILA_BOLSAS
	f.filaBolsas:SetHeight(alto)
	return alto
end

---------------------------------------------------------------- la rejilla
-- Pasar el ratón por una bolsa: solo cambia el resalte, sin volver a leer las casillas.
function M.PintarResalte(f)
	for i, d in ipairs(f.lista or {}) do
		local b = f.mostrados and f.mostrados[i]
		if b and b.mamba then b.mamba.resalte:SetShown(f.resalte ~= nil and d.bolsa == f.resalte) end
	end
end

-- Solo vuelve a pintar las casillas (resalte, filtro, búsqueda): sin mover nada.
function M.DibujarCasillas(f)
	if not (f and f.lista) then return end
	M.RefrescarSugerencias() -- lo que marcaste con Alt + clic derecho se ve al momento
	for i, d in ipairs(f.lista) do
		local b = f.mostrados and f.mostrados[i]
		if b then
			if b.vivo then
				local nd = datosVivo(d.bolsa, d.casilla)
				f.lista[i] = nd
				actualizarVivo(b, nd, f)
			else pintar(b, d, f) end
		end
	end
end

function M.Dibujar(f)
	if not (f and f:IsShown()) then return end
	if InCombatLockdown and InCombatLockdown() and M.EsVivo(f) and f.lista then
		f.pendiente = true -- al salir de combate se rehace entero (fuera-de-combate)
		M.DibujarCasillas(f)
		return
	end
	M.RefrescarSugerencias()
	local vivo = M.EsVivo(f)
	local bolsas = bolsasDe(f)
	f.tam = M.Op("tamano")
	local cols = (f.tipo == "banco") and M.Op("columnasBanco") or M.Op("columnas")
	if vivo then f.pendiente = asegurarVivos(f, bolsas) end
	for _, m in pairs(f.marcos or {}) do for _, b in ipairs(m.botones) do b:Hide() end end
	for _, b in ipairs(f.guardados or {}) do b:Hide() end
	f.guardados = f.guardados or {}
	local lista = casillas(f, bolsas)
	f.lista, f.mostrados = lista, {}
	local y, col = 0, 0
	local paso = f.tam + HUECO
	-- un banco grande no sale de la pantalla: más columnas si no cabe
	local altoPantalla = (UIParent and UIParent:GetHeight() or 1080) / (M.Op("escala") or 1)
	local filasMax = math.max(4, math.floor((altoPantalla * 0.9 - f.cuerpo - 160) / paso))
	if math.ceil(#lista / cols) > filasMax then cols = math.ceil(#lista / filasMax) end
	local nGuardado = 0
	for i, d in ipairs(lista) do
		if d.filaNueva and col > 0 then col = 0; y = y + paso + 4 end
		if col >= cols then col = 0; y = y + paso end
		local b
		if vivo then
			local m = f.marcos[d.bolsa]
			b = m and m.botones[d.casilla]
		else
			nGuardado = nGuardado + 1
			b = f.guardados[nGuardado]
			if not b then b = crearGuardado(f); f.guardados[nGuardado] = b end
		end
		if b then
			b:ClearAllPoints()
			if b.vivo then
				local e = f.tam / BASE
				b:SetScale(e)
				b:SetPoint("TOPLEFT", f.rejilla, "TOPLEFT", col * paso / e, -y / e)
			else
				b:SetSize(f.tam, f.tam)
				b:SetPoint("TOPLEFT", f.rejilla, "TOPLEFT", col * paso, -y)
			end
			b:Show()
			if b.vivo then actualizarVivo(b, d, f) else actualizarGuardado(b, d, f) end
			f.mostrados[i] = b
		end
		col = col + 1
	end
	local altoRejilla = #lista > 0 and (y + paso - HUECO) or 40
	local anchoRejilla = math.max(cols, 1) * paso - HUECO
	f.anchoRejilla = anchoRejilla
	local ancho = math.max(MIN_ANCHO, anchoRejilla + 2 * f.margen)
	f.anchoVentana = ancho
	local altoFila = dibujarBolsas(f, bolsas, ancho - 2 * f.margen)
	f.vacio:SetShown(#lista == 0)
	if #lista == 0 then
		f.vacio:SetText(vivo and "No hay bolsas." or (f.tipo == "banco" and "Todavía no viste este banco: habla con un banquero una vez." or "Todavía no hay casillas guardadas de este personaje: entra una vez con él."))
	end
	-- de arriba abajo: cabecera, buscador, fila de bolsas, rejilla, pie (y en el banco, la compra de pestaña)
	local yFila = f.cuerpo + BUSCADOR + 6
	f.filaBolsas:ClearAllPoints()
	f.filaBolsas:SetPoint("TOPLEFT", f, "TOPLEFT", f.margen, -yFila)
	f.filaBolsas:SetWidth(ancho - 2 * f.margen)
	local yRejilla = yFila + (altoFila > 0 and (altoFila + 6) or 0)
	f.rejilla:ClearAllPoints()
	f.rejilla:SetPoint("TOPLEFT", f, "TOPLEFT", f.margen, -yRejilla)
	f.rejilla:SetSize(anchoRejilla, math.max(1, altoRejilla))
	local altoCompra = M.DibujarCompra and M.DibujarCompra(f) or 0
	local altoMin = PRIMERA_PESTANA + #M.FILTROS * (PESTANA + 2) + 6
	f:SetSize(ancho, math.max(altoMin, yRejilla + altoRejilla + 8 + PIE + altoCompra + 6))
	f:SetScale(M.Op("escala") or 1)
	f:SetAlpha(math.max(0.3, M.Op("fondo") or 1))
	M.Titulo(f)
	M.PintarPestanas(f)
	M.PintarFiltroPuesto(f)
	if f.botonFila then
		local _, _, W = PS()
		if W and W.SetIconState then W.SetIconState(f.botonFila, M.Op("verBolsas")) else f.botonFila.psActive = M.Op("verBolsas") end
	end
end

-- "Inventario de Hope" / "Banco de Hope" (como "Hope Fé's Inventory" de Bagnon), y el retrato.
function M.Titulo(f)
	local quien = M.NombreDe(f.dueno)
	local t = (f.tipo == "banco" and "Banco de " or "Inventario de ") .. quien
	if not M.EsVivo(f) then
		local p = M.DB().personajes[f.dueno]
		local fecha = p and (f.tipo == "banco" and p.fechaBanco or p.fecha)
		if f.libresTexto and fecha then f.libresTexto:SetText((f.libresTexto:GetText() or "") .. "  ·  visto el " .. fecha) end
	end
	if f.titulo then
		if f.titulo.SetWordWrap then f.titulo:SetWordWrap(false) end
		f.titulo:SetText(t)
	end
	if f.retrato then
		local p = M.DB().personajes[f.dueno]
		if f.dueno == M.Clave() and SetPortraitTexture then
			f.retrato:SetTexCoord(0, 1, 0, 1)
			pcall(SetPortraitTexture, f.retrato, "player")
		else
			local cc = p and p.clase and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[p.clase]
			if cc then
				f.retrato:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
				f.retrato:SetTexCoord(cc[1], cc[2], cc[3], cc[4])
			else
				f.retrato:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				f.retrato:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			end
		end
	end
end

---------------------------------------------------------------- filtros: pestañas de ícono en el borde izquierdo
local ICONOS_FILTRO = {
	todo = { "Interface\\Buttons\\Button-Backpack-Up" },
	basura = { nil, "bags-icon-junk", "Interface\\Icons\\INV_Misc_Coin_02" },
	equipo = { nil, "bags-icon-equipment", "Interface\\Icons\\INV_Chest_Chain" },
	consumibles = { nil, "bags-icon-consumables", "Interface\\Icons\\INV_Potion_51" },
	materiales = { nil, "bags-icon-tradegoods", "Interface\\Icons\\INV_Fabric_Linen_01" },
	mision = { nil, "bags-icon-questitem", "Interface\\GossipFrame\\ActiveQuestIcon" },
	nuevo = { "Interface\\Icons\\INV_Misc_Gift_01" },
}

-- Con un filtro puesto, el pie lo dice (si no, las casillas apagadas parecen una falla)
function M.PintarFiltroPuesto(f)
	if not f.filtroTexto then return end
	local nombre
	for _, fl in ipairs(M.FILTROS) do if fl[1] == f.filtro and fl[1] ~= "todo" then nombre = fl[2] end end
	f.filtroTexto:SetText(nombre and ("Filtro: " .. nombre .. " · clic en su pestaña para quitarlo") or "")
end

function M.PintarPestanas(f)
	for _, c in ipairs(f.pestanas or {}) do
		local activo = (f.filtro or "todo") == c.clave
		c.fondoActivo:SetShown(activo)
		c.icono:SetDesaturated(not activo)
		c.icono:SetAlpha(activo and 1 or 0.75)
	end
end

local function pestanas(f)
	f.pestanas = {}
	local y = 0
	for _, fl in ipairs(M.FILTROS) do
		local c = CreateFrame("Button", nil, f)
		c.clave, c.etiqueta = fl[1], fl[2]
		c:SetSize(PESTANA, PESTANA)
		c.fondo = tex(c, "BACKGROUND")
		c.fondo:SetAllPoints(c)
		color(c.fondo, "panel", 0.97)
		c.fondoActivo = tex(c, "BORDER")
		c.fondoActivo:SetPoint("TOPLEFT", c, "TOPLEFT", 0, 0)
		c.fondoActivo:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 0)
		c.fondoActivo:SetWidth(3)
		color(c.fondoActivo, "accent")
		c.icono = c:CreateTexture(nil, "ARTWORK")
		c.icono:SetPoint("CENTER", c, "CENTER", 1, 0)
		c.icono:SetSize(PESTANA - 10, PESTANA - 10)
		local ic = ICONOS_FILTRO[fl[1]] or {}
		local puesto = false
		if ic[2] and c.icono.SetAtlas then puesto = pcall(c.icono.SetAtlas, c.icono, ic[2]) end
		if not puesto then c.icono:SetTexture(ic[1] or ic[3]) end
		c:SetPoint("TOPRIGHT", f, "TOPLEFT", 1, -(PRIMERA_PESTANA + y))
		if c.RegisterForClicks then c:RegisterForClicks("LeftButtonUp") end
		c:SetScript("OnClick", function(self, boton)
			if boton and boton ~= "LeftButton" then return end
			f.filtro = (f.filtro == self.clave) and "todo" or self.clave
			M.Anotar("filtro", self.clave)
			M.PintarPestanas(f)
			M.PintarFiltroPuesto(f)
			M.DibujarCasillas(f)
		end)
		c:SetScript("OnEnter", function(self)
			local A = _G.Asistente
			if A and A.CuadroAyuda then A.CuadroAyuda(self, self.etiqueta, { self.clave == "todo" and "Todo lo que llevas" or ("Solo " .. self.etiqueta:lower() .. "; otro clic: todo") }) end
		end)
		c:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
		y = y + PESTANA + 2
		f.pestanas[#f.pestanas + 1] = c
	end
	-- que las pestañas no queden fuera de la pantalla
	if f.SetClampRectInsets then f:SetClampRectInsets(-PESTANA, 0, 0, 0) end
end

---------------------------------------------------------------- otros personajes (clic en el retrato, como Bagnon)
local function menuPersonajes(f, ancla)
	local _, _, W = PS()
	local items = {}
	for _, k in ipairs(M.Personajes()) do
		local p = M.DB().personajes[k]
		local yo = k == M.Clave()
		items[#items + 1] = { text = M.NombreDe(k) .. (yo and "  (tú)" or "") .. ((p and p.oro and not yo) and ("  ·  " .. M.Dinero(p.oro)) or ""),
			checked = f.dueno == k, onClick = function() f.dueno = k; f.sola = nil; M.Dibujar(f) end }
	end
	if W and W.ShowMenu then pcall(W.ShowMenu, ancla, items, { minWidth = 220, point = "TOPLEFT", relPoint = "BOTTOMLEFT" })
	else
		local lista = M.Personajes()
		local i = 1
		for j, k in ipairs(lista) do if k == f.dueno then i = j end end
		f.dueno = lista[i % #lista + 1]
		M.Dibujar(f)
	end
end

---------------------------------------------------------------- el marco: compacto, con retrato (sin la cabecera alta de Polestar)
local function marco(nombre, titulo)
	local Ps, T, W = PS()
	local f
	if Ps and T.Skin and Ps.DragWindow and W.IconButton then
		f = CreateFrame("Frame", nombre, UIParent)
		f:SetSize(MIN_ANCHO, 300)
		f:SetPoint("CENTER")
		f:SetFrameStrata("HIGH")
		f:SetToplevel(true)
		f:SetClampedToScreen(true)
		f:SetMovable(true)
		f:EnableMouse(true)
		T.Skin(f, "window")
		local cab = CreateFrame("Frame", nil, f)
		cab:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
		cab:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
		cab:SetHeight(CABEZA)
		Ps.DragWindow(cab, f, {})
		f.cabeza = cab
		f.cerrar = W.IconButton(cab, "close", 22, CLOSE or "Cerrar", function() f:Hide() end, 12)
		f.cerrar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
		f.titulo = W.Text(cab, "heading", "text")
		if Ps.CloseOnEscape then Ps.CloseOnEscape(nombre) end
	else
		f = CreateFrame("Frame", nombre, UIParent, "BasicFrameTemplateWithInset")
		f:SetSize(MIN_ANCHO, 300)
		f:SetPoint("CENTER")
		f:SetFrameStrata("HIGH")
		f:SetClampedToScreen(true)
		f:SetMovable(true)
		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", function(self) if not M.Op("fija") then self:StartMoving() end end)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)
		f.titulo = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		if UISpecialFrames then table.insert(UISpecialFrames, nombre) end
	end
	-- el retrato, redondo, sobresale de la esquina (como el de Bagnon); clic = otro personaje
	f.botonRetrato = CreateFrame("Button", nil, f)
	f.botonRetrato:SetSize(RETRATO, RETRATO)
	f.botonRetrato:SetPoint("TOPLEFT", f, "TOPLEFT", -8, 8)
	f.botonRetrato:SetFrameLevel((f:GetFrameLevel() or 1) + 5)
	f.anillo = f.botonRetrato:CreateTexture(nil, "BACKGROUND")
	f.anillo:SetPoint("CENTER", f.botonRetrato, "CENTER", 0, 0)
	f.anillo:SetSize(RETRATO + 4, RETRATO + 4)
	f.anillo:SetTexture(media("disc-64") or "Interface\\CharacterFrame\\TempPortraitAlphaMask")
	color(f.anillo, "accent", 0.9)
	f.retrato = f.botonRetrato:CreateTexture(nil, "ARTWORK")
	f.retrato:SetPoint("CENTER", f.botonRetrato, "CENTER", 0, 0)
	f.retrato:SetSize(RETRATO - 2, RETRATO - 2)
	if f.botonRetrato.CreateMaskTexture then
		local mascara = f.botonRetrato:CreateMaskTexture()
		mascara:SetAllPoints(f.retrato)
		mascara:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		f.retrato:AddMaskTexture(mascara)
	end
	f.botonRetrato:SetScript("OnClick", function(self) menuPersonajes(f, self) end)
	f.botonRetrato:SetScript("OnEnter", function(self)
		local A = _G.Asistente
		if A and A.CuadroAyuda then A.CuadroAyuda(self, "Personajes", { "Clic: ver las bolsas y el banco de otro de tus personajes" }) end
	end)
	f.botonRetrato:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
	f.titulo:ClearAllPoints()
	f.titulo:SetPoint("TOPLEFT", f, "TOPLEFT", RETRATO, -11)
	f.titulo:SetText(titulo or "")
	f.cuerpo, f.margen = CABEZA, MARGEN
	f:Hide()
	return f
end

---------------------------------------------------------------- armar una ventana
M.ventanas = {}

function M.CrearVentanaBolsas(tipo)
	local nombre = tipo == "banco" and "MambaBolsasBanco" or "MambaBolsasVentana"
	local f = marco(nombre, tipo == "banco" and "Banco" or "Inventario")
	f.tipo, f.dueno, f.filtro, f.texto = tipo, M.Clave(), "todo", ""
	f:ClearAllPoints()
	if tipo == "banco" then f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 60, -120)
	else f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -60, 120) end
	-- K55: lugar por personaje, candado y "Restablecer posiciones", con ESTE lugar como el de siempre
	local api = _G.MambaAPI
	if api and api.Movible then pcall(api.Movible, f, nombre, nil, { yaArrastra = true }) end
	-- botones de la cabecera (a la izquierda de la cruz)
	local der = {}
	local function agregar(icono, ayuda, fn)
		local b = iconoBoton(f.cabeza or f, icono, ayuda, fn)
		der[#der + 1] = b
		return b
	end
	f.botonOpciones = agregar("gear", "Opciones de las bolsas", function()
		local I = _G.MambaInterfaz
		if I and I.Abrir then I.Abrir("bolsas", "opciones") end
	end)
	f.botonOrdenar = agregar("reload", "Ordenar y apilar", function()
		if not M.EsVivo(f) then return end
		local _, msg = M.Ordenar(f.tipo == "banco")
		f.aviso:SetText(msg or "")
		if msg and C_Timer and C_Timer.After then C_Timer.After(4, function() f.aviso:SetText("") end) end
	end)
	f.botonOtro = agregar(tipo == "banco" and "layers" or "house", tipo == "banco" and "Ver mis bolsas" or "Ver mi banco (aunque no estés en él)", function()
		if tipo == "banco" then M.AbrirInventario(true) else M.AbrirBanco(f.dueno) end
	end)
	f.botonFila = agregar("compact", "Mostrar u ocultar la fila de bolsas (clic en una bolsa: verla sola)", function()
		M.DB().opciones.verBolsas = not M.Op("verBolsas")
		M.Redibujar()
	end)
	local xDer = -34
	for _, b in ipairs(der) do
		b:SetPoint("TOPRIGHT", f, "TOPRIGHT", xDer, -6)
		xDer = xDer - 26
	end
	f.titulo:SetPoint("RIGHT", der[#der], "LEFT", -6, 0)
	-- buscador (bajo el título, a todo lo ancho)
	local A = _G.Asistente
	local buscar = function(t) f.texto = t or ""; M.DibujarCasillas(f) end
	if A and A.Buscador then f.buscador = A.Buscador(f, "Buscar en " .. (tipo == "banco" and "el banco" or "las bolsas"), buscar)
	else
		f.buscador = CreateFrame("EditBox", nil, f)
		f.buscador:SetAutoFocus(false)
		f.buscador:SetScript("OnTextChanged", function(self) buscar(self:GetText()) end)
	end
	f.buscador:SetPoint("TOPLEFT", f, "TOPLEFT", RETRATO - 4, -(f.cuerpo - 2))
	f.buscador:SetPoint("TOPRIGHT", f, "TOPRIGHT", -f.margen, -(f.cuerpo - 2))
	f.buscador:SetHeight(BUSCADOR)
	f.filtroTexto = P.Texto(f, "note", "accent")
	f.filtroTexto:SetPoint("BOTTOM", f, "BOTTOM", 0, 9)
	f.aviso = P.Texto(f, "note", "warning")
	f.aviso:SetPoint("BOTTOM", f.filtroTexto, "TOP", 0, 2)
	pestanas(f)
	f.filaBolsas = CreateFrame("Frame", nil, f)
	f.filaBolsas:SetSize(1, FILA_BOLSAS)
	f.rejilla = CreateFrame("Frame", nil, f)
	f.rejilla:SetSize(1, 1)
	f.vacio = P.Texto(f.rejilla, "note", "textMuted")
	f.vacio:SetPoint("TOPLEFT", f.rejilla, "TOPLEFT", 0, -8)
	-- el pie: casillas libres a la izquierda, oro a la derecha (como Bagnon)
	f.libresTexto = P.Texto(f, "number", "text")
	f.libresTexto:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", f.margen, 9)
	f.oroTexto = P.Texto(f, "number", "text")
	f.oroTexto:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -f.margen, 9)
	if f.cabeza and f.cabeza.EnableMouse then f.cabeza:EnableMouse(not M.Op("fija")) end
	f:HookScript("OnShow", function(self) M.Dibujar(self) end)
	f:HookScript("OnHide", function(self)
		if self.tipo == "inventario" then M.Anotar("ventana", "cerrada") end
		self.sola, self.resalte = nil, nil
		if self.tipo == "banco" and M.bancoAbierto then
			local B = C_Bank
			if B and B.CloseBankFrame then pcall(B.CloseBankFrame) elseif CloseBankFrame then pcall(CloseBankFrame) end
		end
	end)
	-- cambios del juego: un solo pedido en espera; si alguno pidió el redibujo completo, se hace el completo
	local pendiente, completo = false, false
	local function programar(soloCasillas, espera)
		if not soloCasillas then completo = true end
		if pendiente then return end
		pendiente = true
		local function correr()
			local todo = completo
			pendiente, completo = false, false
			if not f:IsShown() then return end
			if todo then M.Dibujar(f) else M.DibujarCasillas(f) end
		end
		if C_Timer and C_Timer.After then C_Timer.After(espera or 0.05, correr) else correr() end
	end
	table.insert(M.alCambiar, function(motivo)
		if not f:IsShown() then return end
		if motivo == "casillas" then
			if M.EsVivo(f) then programar(true) end
		elseif motivo == "datos" then
			programar(true, 0.4) -- nombres y misiones que llegan de a poco: se juntan
		elseif motivo == "fuera-de-combate" then
			if f.pendiente then programar(false) end
		elseif motivo == "banco-abierto" or motivo == "banco-cerrado" then
			if f.tipo == "banco" then programar(false) end
		elseif motivo == "oro" then
			local p = M.DB().personajes[f.dueno]
			if f.tipo ~= "banco" and p and p.oro and f.oroTexto then f.oroTexto:SetText(GetCoinTextureString and GetCoinTextureString(p.oro) or M.Dinero(p.oro)) end
			if f.tipo == "banco" and M.DibujarCompra then
				local antes = f.compra and f.compra:IsShown()
				M.DibujarCompra(f)
				if (f.compra and f.compra:IsShown()) ~= antes then programar(false) end
			end
		else
			if M.EsVivo(f) then programar(false) end
		end
	end)
	if A and A.AlCambiarApariencia then A.AlCambiarApariencia(function() if f:IsShown() then M.Dibujar(f) end end) end
	M.ventanas[tipo] = f
	return f
end

function M.Ventana(tipo)
	return M.ventanas[tipo] or M.CrearVentanaBolsas(tipo)
end

function M.AplicarFija()
	for _, f in pairs(M.ventanas) do
		if f.cabeza and f.cabeza.EnableMouse then f.cabeza:EnableMouse(not M.Op("fija")) end
	end
end

function M.Redibujar()
	for _, f in pairs(M.ventanas) do if f:IsShown() then M.Dibujar(f) end end
end
