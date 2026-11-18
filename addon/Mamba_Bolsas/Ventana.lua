-- Mamba_Bolsas: la ventana de las bolsas y la del banco (la misma pieza, dos veces).
-- Dirección de arte (revisada con la skill direccion-de-arte, 18-11): linaje "bandeja de piezas" de un catálogo
-- industrial dentro de la apariencia de Polestar. Gesto propio: el PIE es a la vez la barra de bolsas y la regla
-- de capacidad: cada bolsa es una celda con su ícono, "libres/total" y una regla fina que se llena con lo usado;
-- clic = ver solo esa bolsa, pasar el ratón = se encienden sus casillas en la rejilla. Un solo acento (el de la
-- apariencia) para lo elegido, lo nuevo y la bolsa resaltada; la calidad usa los colores del juego.
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

local HUECO = 3      -- entre casillas
local PIE = 46       -- alto del pie (barra de bolsas + regla)
local BARRA = 28     -- alto de la fila del buscador
local CHIPS = 22     -- alto de la fila de filtros
local CELDA = 70     -- ancho de cada bolsa en el pie
local MIN_ANCHO = 470

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
	vender = { "Interface\\Buttons\\UI-GroupLoot-Coin-Up", true },
	subastar = { "Interface\\Buttons\\UI-GroupLoot-Coin-Up", false },
	guardar = { "Interface\\PetBattles\\PetBattle-LockIcon", false },
}

local function pintar(b, d, f)
	local o = adornar(b)
	local tam = f.tam
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
		elseif d and d.id then color(t, "divider", 0.6); t:Show()
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
	local mejora = M.Op("mejora") and d and d.id and M.EsMejora(d)
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
	m:SetID(bolsa)
	m.GetBagID = function(self) return self:GetID() end
	m:SetAllPoints(f.rejilla)
	m.botones = {}
	f.marcos[bolsa] = m
	return m
end

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
		end)
	end
	if b.IconBorder then b.IconBorder:SetAlpha(0) end
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
	b.hasItem = d.id and true or nil
	b.readable = nil
	if SetItemButtonTexture then pcall(SetItemButtonTexture, b, d.icono or VACIA) end
	if SetItemButtonCount then pcall(SetItemButtonCount, b, d.n or 0) end
	if SetItemButtonDesaturated then pcall(SetItemButtonDesaturated, b, d.bloqueado and true or false) end
	local icon = b.icon or b.Icon
	if icon and icon.SetAlpha then icon:SetAlpha(d.id and 1 or 0.35) end
	if b.Cooldown and CooldownFrame_Set and C_Container and C_Container.GetContainerItemCooldown then
		local ok, s, dur, en = pcall(C_Container.GetContainerItemCooldown, d.bolsa, d.casilla)
		if ok then pcall(CooldownFrame_Set, b.Cooldown, s, dur, en) end
	end
	if b.IconBorder then b.IconBorder:SetAlpha(0) end
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

---------------------------------------------------------------- el pie: barra de bolsas + regla de capacidad
local function celda(f, i)
	f.celdas = f.celdas or {}
	local c = f.celdas[i]
	if c then return c end
	c = CreateFrame("Button", nil, f.pie)
	c:SetSize(CELDA - 6, PIE - 8)
	c.icono = c:CreateTexture(nil, "ARTWORK")
	c.icono:SetSize(22, 22)
	c.icono:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -2)
	c.texto = P.Texto(c, "number", "text")
	c.texto:SetPoint("LEFT", c.icono, "RIGHT", 6, 0)
	c.regla = tex(c, "BORDER")
	c.regla:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 4)
	c.regla:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, 4)
	c.regla:SetHeight(3)
	color(c.regla, "divider", 0.5)
	c.lleno = tex(c, "ARTWORK")
	c.lleno:SetPoint("BOTTOMLEFT", c.regla, "BOTTOMLEFT", 0, 0)
	c.lleno:SetHeight(3)
	c.elegida = tex(c, "BACKGROUND")
	c.elegida:SetAllPoints(c)
	color(c.elegida, "accent", 0.14)
	c.elegida:Hide()
	c:RegisterForDrag("LeftButton")
	c:SetScript("OnEnter", function(self)
		f.resalte = self.bolsa
		M.DibujarCasillas(f)
		local lineas = { self.libres .. " libres de " .. self.total, "Clic: ver solo esta bolsa · otra vez: todas" }
		if self.inv and M.EsVivo(f) then lineas[#lineas + 1] = "Arrastra una bolsa aquí para ponértela" end
		local A = _G.Asistente
		if A and A.CuadroAyuda then A.CuadroAyuda(self, self.nombre or "Bolsa", lineas) end
	end)
	c:SetScript("OnLeave", function()
		f.resalte = nil
		M.DibujarCasillas(f)
		if GameTooltip then GameTooltip:Hide() end
	end)
	c:SetScript("OnClick", function(self)
		if CursorHasItem and CursorHasItem() and self.inv and PutItemInBag and not InCombatLockdown() then
			pcall(PutItemInBag, self.inv)
			return
		end
		f.sola = (f.sola ~= self.bolsa) and self.bolsa or nil
		M.Dibujar(f)
	end)
	c:SetScript("OnReceiveDrag", function(self)
		if self.inv and PutItemInBag and not InCombatLockdown() then pcall(PutItemInBag, self.inv) end
	end)
	c:SetScript("OnDragStart", function(self)
		if self.inv and self.bolsa ~= 0 and PickupBagFromSlot and M.EsVivo(f) and not InCombatLockdown() then pcall(PickupBagFromSlot, self.inv) end
	end)
	f.celdas[i] = c
	return c
end

local function dibujarPie(f, bolsas)
	local vivo = M.EsVivo(f)
	local p = M.DB().personajes[f.dueno]
	local libresT, totalT = 0, 0
	local ancho = (f.anchoRejilla or 400)
	local porFila = math.max(1, math.floor((ancho - 200) / CELDA))
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
		local w = CELDA - 6
		c.lleno:SetWidth(math.max(1, w * usado))
		color(c.lleno, libres == 0 and "warning" or (f.sola == b and "accent" or "textMuted"), 0.9)
		c.elegida:SetShown(f.sola == b)
		c:ClearAllPoints()
		local fila, col = math.floor((i - 1) / porFila), (i - 1) % porFila
		c:SetPoint("TOPLEFT", f.pie, "TOPLEFT", col * CELDA, -fila * (PIE - 6))
		c:Show()
		libresT, totalT = libresT + libres, totalT + total
	end
	for i = #bolsas + 1, #(f.celdas or {}) do f.celdas[i]:Hide() end
	f.totalTexto:SetText(libresT .. " libres de " .. totalT)
	color(f.totalTexto, libresT <= 2 and "warning" or "text")
	local oro = (vivo or f.tipo ~= "banco") and p and p.oro
	f.oroTexto:SetText(oro and (GetCoinTextureString and GetCoinTextureString(oro) or M.Dinero(oro)) or "")
	local filas = math.ceil(#bolsas / porFila)
	return math.max(PIE, filas * (PIE - 6) + 6)
end

---------------------------------------------------------------- la rejilla
-- Solo vuelve a pintar las casillas (resalte, filtro, búsqueda): sin mover nada.
function M.DibujarCasillas(f)
	if not (f and f.lista) then return end
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
	M.RefrescarSugerencias()
	local vivo = M.EsVivo(f)
	local bolsas = bolsasDe(f)
	f.tam = M.Op("tamano")
	local cols = (f.tipo == "banco") and M.Op("columnasBanco") or M.Op("columnas")
	if vivo then f.pendiente = asegurarVivos(f, bolsas) end
	-- esconder lo de antes
	for _, m in pairs(f.marcos or {}) do for _, b in ipairs(m.botones) do b:Hide() end end
	for _, b in ipairs(f.guardados or {}) do b:Hide() end
	f.guardados = f.guardados or {}
	local lista = casillas(f, bolsas)
	f.lista, f.mostrados = lista, {}
	local x, y, col = 0, 0, 0
	local paso = f.tam + HUECO
	local maxCol, nGuardado = 0, 0
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
			b:SetSize(f.tam, f.tam)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", f.rejilla, "TOPLEFT", col * paso, -y)
			b:Show()
			if b.vivo then actualizarVivo(b, d, f) else actualizarGuardado(b, d, f) end
			f.mostrados[i] = b
		end
		col = col + 1
		if col > maxCol then maxCol = col end
	end
	local filas = #lista > 0 and (y + paso) or 0
	local anchoRejilla = math.max(cols, 1) * paso - HUECO
	f.anchoRejilla = anchoRejilla
	local ancho = math.max(MIN_ANCHO, anchoRejilla + 2 * f.margen)
	local altoPie = dibujarPie(f, bolsas)
	f.vacio:SetShown(#lista == 0)
	if #lista == 0 then
		f.vacio:SetText(vivo and "No hay bolsas." or (f.tipo == "banco" and "Todavía no viste este banco: habla con un banquero una vez." or "Sin datos de este personaje."))
	end
	local altoRejilla = math.max(filas, #lista == 0 and 60 or 0)
	f.rejilla:SetSize(anchoRejilla, math.max(1, altoRejilla))
	f:SetSize(ancho, f.cuerpo + 8 + BARRA + 6 + CHIPS + 10 + altoRejilla + 12 + altoPie + 10)
	f:SetScale(M.Op("escala") or 1)
	f:SetAlpha(math.max(0.3, M.Op("fondo") or 1))
	M.Titulo(f)
	M.PintarChips(f)
	if f.botonVista then f.botonVista.psActive = f.sola ~= nil end
end

function M.Titulo(f)
	local quien = M.NombreDe(f.dueno)
	local yo = f.dueno == M.Clave()
	local t = (f.tipo == "banco" and "Banco" or "Bolsas") .. (yo and "" or (" de " .. quien))
	if not M.EsVivo(f) then
		local p = M.DB().personajes[f.dueno]
		local fecha = p and (f.tipo == "banco" and p.fechaBanco or p.fecha)
		t = t .. (fecha and ("  ·  visto el " .. fecha) or "")
	end
	if f.titulo then f.titulo:SetText(t) end
end

---------------------------------------------------------------- filtros
function M.PintarChips(f)
	for _, c in ipairs(f.chips or {}) do
		local activo = (f.filtro or "todo") == c.clave
		color(c.texto, activo and "accent" or "textMuted")
		c.linea:SetShown(activo)
	end
end

local function chips(f)
	f.chips = {}
	local x = 0
	for _, fl in ipairs(M.FILTROS) do
		local c = CreateFrame("Button", nil, f)
		c.clave = fl[1]
		c.texto = P.Texto(c, "label", "textMuted")
		c.texto:SetPoint("LEFT", c, "LEFT", 0, 0)
		c.texto:SetText(fl[2])
		local w = (c.texto.GetStringWidth and c.texto:GetStringWidth() or 50)
		if not w or w < 10 then w = 50 end
		c:SetSize(w + 2, CHIPS)
		c.linea = tex(c, "ARTWORK")
		c.linea:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 0, 1)
		c.linea:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", 0, 1)
		c.linea:SetHeight(2)
		color(c.linea, "accent")
		c:SetPoint("TOPLEFT", f, "TOPLEFT", f.margen + x, -(f.cuerpo + 8 + BARRA + 6))
		c:SetScript("OnClick", function(self)
			f.filtro = (f.filtro == self.clave) and "todo" or self.clave
			M.PintarChips(f)
			M.DibujarCasillas(f)
		end)
		x = x + w + 18
		f.chips[#f.chips + 1] = c
	end
end

---------------------------------------------------------------- otros personajes
local function menuPersonajes(f, ancla)
	local _, _, W = PS()
	local items = {}
	for _, k in ipairs(M.Personajes()) do
		local p = M.DB().personajes[k]
		local yo = k == M.Clave()
		items[#items + 1] = { text = M.NombreDe(k) .. (yo and "  (tú)" or "") .. ((p and p.oro and not yo) and ("  ·  " .. M.Dinero(p.oro)) or ""),
			checked = f.dueno == k, onClick = function() f.dueno = k; f.sola = nil; M.Dibujar(f) end }
	end
	if W and W.ShowMenu then pcall(W.ShowMenu, ancla, items, { minWidth = 220 })
	else
		-- sin Polestar: pasa al siguiente personaje
		local lista = M.Personajes()
		local i = 1
		for j, k in ipairs(lista) do if k == f.dueno then i = j end end
		f.dueno = lista[i % #lista + 1]
		M.Dibujar(f)
	end
end

---------------------------------------------------------------- armar una ventana
M.ventanas = {}

function M.CrearVentanaBolsas(tipo)
	local nombre = tipo == "banco" and "MambaBolsasBanco" or "MambaBolsasVentana"
	local f = P.Ventana(nombre, tipo == "banco" and "Banco" or "Bolsas", MIN_ANCHO, 420)
	f.tipo, f.dueno, f.filtro, f.texto = tipo, M.Clave(), "todo", ""
	f.margen = f.margen or 16
	f.cuerpo = f.cuerpo or 26
	f:SetFrameStrata("HIGH")
	if tipo == "banco" then
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -120)
	else
		f:ClearAllPoints()
		f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -60, 120)
	end
	-- fila del buscador y los botones
	local y = -(f.cuerpo + 8)
	local der = {}
	local function agregar(icono, ayuda, fn)
		local b = iconoBoton(f, icono, ayuda, fn)
		der[#der + 1] = b
		return b
	end
	f.botonOpciones = agregar("gear", "Opciones de las bolsas", function()
		local I = _G.MambaInterfaz
		if I and I.Abrir then I.Abrir("bolsas", "opciones") end
	end)
	f.botonOtro = agregar(tipo == "banco" and "layers" or "house", tipo == "banco" and "Ver mis bolsas" or "Ver mi banco (aunque no estés en él)", function()
		if tipo == "banco" then M.AbrirInventario(true) else M.AbrirBanco(f.dueno) end
	end)
	f.botonPersonajes = agregar("menu", "Ver las bolsas de otro personaje", function(self) menuPersonajes(f, self) end)
	f.botonVista = agregar("compact", "Todas juntas / una por una (clic en una bolsa del pie)", function()
		if f.sola then f.sola = nil else
			local b = bolsasDe(f)
			f.sola = b[1]
		end
		M.Dibujar(f)
	end)
	f.botonOrdenar = agregar("reload", "Ordenar y apilar", function()
		if not M.EsVivo(f) then return end
		local ok, msg = M.Ordenar(f.tipo == "banco")
		if msg then f.aviso:SetText(msg) else f.aviso:SetText("") end
	end)
	local xDer = -f.margen
	for _, b in ipairs(der) do
		b:SetPoint("TOPRIGHT", f, "TOPRIGHT", xDer, y)
		xDer = xDer - 28
	end
	local A = _G.Asistente
	local buscar = function(t) f.texto = t or ""; M.DibujarCasillas(f) end
	if A and A.Buscador then f.buscador = A.Buscador(f, "Buscar en " .. (tipo == "banco" and "el banco" or "las bolsas"), buscar)
	else
		f.buscador = CreateFrame("EditBox", nil, f)
		f.buscador:SetAutoFocus(false)
		f.buscador:SetScript("OnTextChanged", function(self) buscar(self:GetText()) end)
	end
	f.buscador:SetPoint("TOPLEFT", f, "TOPLEFT", f.margen, y)
	f.buscador:SetPoint("RIGHT", der[#der], "LEFT", -10, 0)
	f.buscador:SetHeight(BARRA - 4)
	chips(f)
	f.aviso = P.Texto(f, "note", "warning")
	f.aviso:SetPoint("TOPRIGHT", f, "TOPRIGHT", -f.margen, -(f.cuerpo + 8 + BARRA + 9))
	-- la rejilla
	f.rejilla = CreateFrame("Frame", nil, f)
	f.rejilla:SetPoint("TOPLEFT", f, "TOPLEFT", f.margen, -(f.cuerpo + 8 + BARRA + 6 + CHIPS + 10))
	f.rejilla:SetSize(1, 1)
	f.vacio = P.Texto(f.rejilla, "note", "textMuted")
	f.vacio:SetPoint("TOPLEFT", f.rejilla, "TOPLEFT", 0, -8)
	-- el pie
	f.linea = P.Linea(f, false)
	f.linea:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", f.margen, PIE + 14)
	f.linea:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -f.margen, PIE + 14)
	f.pie = CreateFrame("Frame", nil, f)
	f.pie:SetPoint("TOPLEFT", f.rejilla, "BOTTOMLEFT", 0, -14)
	f.pie:SetPoint("RIGHT", f, "RIGHT", -f.margen, 0)
	f.pie:SetHeight(PIE)
	f.totalTexto = P.Texto(f, "number", "text")
	f.totalTexto:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -f.margen, 30)
	f.oroTexto = P.Texto(f, "number", "textDim")
	f.oroTexto:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -f.margen, 12)
	-- se mueve (K55): Piezas.Ventana ya la suma a MambaAPI.Movible; aquí el candado propio de la ventana
	if f.cabeza and f.cabeza.EnableMouse then f.cabeza:EnableMouse(not M.Op("fija")) end
	f:HookScript("OnShow", function(self) M.Dibujar(self) end)
	f:HookScript("OnHide", function(self)
		self.sola, self.resalte = nil, nil
		if self.tipo == "banco" and M.bancoAbierto then
			local B = C_Bank
			if B and B.CloseBankFrame then pcall(B.CloseBankFrame) elseif CloseBankFrame then pcall(CloseBankFrame) end
		end
		if self.tipo == "inventario" and C_NewItems and C_NewItems.ClearAll and M.Op("nuevo") == false then pcall(C_NewItems.ClearAll) end
	end)
	-- cambios del juego
	local pendiente = false
	local function programar(soloCasillas)
		if pendiente then return end
		pendiente = true
		local function correr()
			pendiente = false
			if not f:IsShown() then return end
			if soloCasillas then M.DibujarCasillas(f) else M.Dibujar(f) end
		end
		if C_Timer and C_Timer.After then C_Timer.After(0.05, correr) else correr() end
	end
	table.insert(M.alCambiar, function(motivo)
		if not f:IsShown() then return end
		if motivo == "casillas" or motivo == "datos" then
			if M.EsVivo(f) or motivo == "datos" then programar(true) end
		elseif motivo == "fuera-de-combate" then
			if f.pendiente then programar(false) end
		elseif motivo == "banco-abierto" or motivo == "banco-cerrado" then
			if f.tipo == "banco" then programar(false) end
		elseif motivo == "oro" then
			if f.oroTexto then programar(false) end
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
