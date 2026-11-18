-- Mamba_Curacion: los marcos de grupo y banda con clic para curar (C7, K11-K13, K16, K86, K97).
-- Plantillas seguras del juego: SecureGroupHeaderTemplate arma un botón por miembro y cada botón es un
-- SecureUnitButtonTemplate con los atributos del perfil (el clic del jugador lanza el hechizo sobre ese miembro,
-- sin cambiar el objetivo). La rueda se ata solo mientras el ratón está encima (fragmento seguro _onenter).
-- Forever esconde algunos números (vida exacta, auras de otros en instancias): se pasan tal cual a las barras
-- sin hacer cuentas con ellos, y lo que no se puede leer no se muestra. Licencia: GPL-3.0-only.
local _, M = ...

local cabecera, ancla
local botones = {}
local pendiente = false
local function enCombate() return InCombatLockdown and InCombatLockdown() end
local function secreto(v) return issecretvalue and issecretvalue(v) end

-- Fragmento seguro: al entrar el ratón ata la rueda a este botón; al salir la suelta.
local ENTRAR = [[ self:SetBindingClick(true, "MOUSEWHEELUP", self, "Button4"); self:SetBindingClick(true, "MOUSEWHEELDOWN", self, "Button5") ]]
local SALIR = [[ self:ClearBindings() ]]

-- El fragmento que la cabecera corre en cada botón nuevo (también en combate): copia los atributos del perfil.
function M.FragmentoInicial(attrs)
	local t = { [[ self:SetWidth(self:GetParent():GetAttribute("anchoBoton")); self:SetHeight(self:GetParent():GetAttribute("altoBoton")); self:RegisterForClicks("AnyUp") ]] }
	local claves = {}
	for k in pairs(attrs) do claves[#claves + 1] = k end
	table.sort(claves)
	for _, k in ipairs(claves) do
		t[#t + 1] = ("self:SetAttribute(%q, %q)"):format(k, attrs[k])
	end
	t[#t + 1] = ("self:SetAttribute(%q, %q)"):format("_onenter", ENTRAR)
	t[#t + 1] = ("self:SetAttribute(%q, %q)"):format("_onleave", SALIR)
	return table.concat(t, "\n")
end

---------------------------------------------------------------- cómo se ve cada botón
local function crearCuerpo(b)
	if b.mamba then return end
	b.mamba = true
	b.fondo = b:CreateTexture(nil, "BACKGROUND")
	b.fondo:SetAllPoints(b)
	b.fondo:SetColorTexture(0.06, 0.06, 0.07, 0.85)
	b.vida = CreateFrame("StatusBar", nil, b)
	b.vida:SetPoint("TOPLEFT", b, "TOPLEFT", 1, -1)
	b.vida:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
	b.vida:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	b.nombre = b.vida:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	b.nombre:SetPoint("CENTER", b.vida, "CENTER", 0, 4)
	b.estado = b.vida:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	b.estado:SetPoint("TOP", b.nombre, "BOTTOM", 0, -1)
	b.borde = b:CreateTexture(nil, "OVERLAY")
	b.borde:SetAllPoints(b)
	b.borde:SetColorTexture(0, 0, 0, 0)
	b.hots = {}
	for i = 1, 3 do
		local h = CreateFrame("Frame", nil, b.vida)
		h:SetSize(11, 11)
		h:SetPoint("BOTTOMRIGHT", b.vida, "BOTTOMRIGHT", -2 - (i - 1) * 12, 2)
		h.icono = h:CreateTexture(nil, "ARTWORK")
		h.icono:SetAllPoints(h)
		h.cd = CreateFrame("Cooldown", nil, h, "CooldownFrameTemplate")
		h.cd:SetAllPoints(h)
		if h.cd.SetHideCountdownNumbers then h.cd:SetHideCountdownNumbers(false) end
		h:Hide()
		b.hots[i] = h
	end
end

local COLOR_LIMPIAR = { Magic = { 0.2, 0.6, 1 }, Curse = { 0.6, 0, 1 }, Poison = { 0, 0.6, 0 }, Disease = { 0.6, 0.4, 0 } }

-- Actualiza un botón con lo que el juego deja leer (todo protegido: nada de cuentas con valores secretos).
function M.Pintar(b)
	local u = b.GetAttribute and b:GetAttribute("unit")
	if not (u and UnitExists and UnitExists(u)) then return end
	crearCuerpo(b)
	local d = M.DB()
	local _, clase = UnitClass(u)
	local c = clase and RAID_CLASS_COLORS and RAID_CLASS_COLORS[clase]
	b.vida:SetStatusBarColor(c and c.r or 0.3, c and c.g or 0.8, c and c.b or 0.3)
	pcall(b.vida.SetMinMaxValues, b.vida, 0, UnitHealthMax(u))
	pcall(b.vida.SetValue, b.vida, UnitHealth(u))
	b.nombre:SetText(UnitName(u) or "")
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost(u) then b.estado:SetText("Muerto")
	elseif UnitIsConnected and not UnitIsConnected(u) then b.estado:SetText("Desconectado")
	else b.estado:SetText("") end
	-- alcance (K12): del hechizo del clic izquierdo si se puede, si no el de grupo
	if d.rango then
		local inR
		local sp = b:GetAttribute("spell1")
		if sp and C_Spell and C_Spell.IsSpellInRange then inR = C_Spell.IsSpellInRange(sp, u) end
		if inR == nil and UnitInRange then inR = UnitInRange(u) end
		if secreto(inR) and b.SetAlphaFromBoolean then pcall(b.SetAlphaFromBoolean, b, inR, 1, 0.45)
		elseif not secreto(inR) then b:SetAlpha((inR == false or inR == 0) and 0.45 or 1) end
	end
	-- mis HoT con su cuenta regresiva (K13)
	local A = C_UnitAuras
	local n = 0
	if d.hots and A and A.GetAuraDataByIndex then
		for i = 1, 20 do
			local ok, a = pcall(A.GetAuraDataByIndex, u, i, "HELPFUL|PLAYER")
			if not ok or not a then break end
			if n < 3 then
				n = n + 1
				local h = b.hots[n]
				pcall(h.icono.SetTexture, h.icono, a.icon)
				if not secreto(a.duration) and not secreto(a.expirationTime) and (a.duration or 0) > 0 then
					h.cd:SetCooldown(a.expirationTime - a.duration, a.duration)
				end
				h:Show()
			end
		end
	end
	for i = n + 1, 3 do b.hots[i]:Hide() end
	-- lo que puedo limpiar (K16): el filtro RAID del juego trae solo lo que tu clase limpia
	b.borde:SetColorTexture(0, 0, 0, 0)
	if d.limpiar and A and A.GetAuraDataByIndex then
		local ok, a = pcall(A.GetAuraDataByIndex, u, 1, "HARMFUL|RAID")
		if ok and a then
			local tipo = a.dispelName
			local col = (not secreto(tipo)) and COLOR_LIMPIAR[tipo] or { 1, 0.2, 0.2 }
			b.borde:SetColorTexture(col[1], col[2], col[3], 0.35)
		end
	end
end

function M.PintarTodo()
	for _, b in ipairs(botones) do if b:IsVisible() then M.Proteger("pintar", M.Pintar, b) end end
	M.ActualizarPresteza()
end

---------------------------------------------------------------- "Presteza lista" (K13)
local aviso
function M.PrestezaLista()
	if not (M.Clase() == "DRUID" and M.Conoce(18562)) then return nil end
	local cd = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(18562)
	if not cd or secreto(cd.startTime) then return nil end
	return (cd.startTime or 0) == 0 or (cd.duration or 0) <= 1.5
end
function M.ActualizarPresteza()
	if not ancla then return end
	if not aviso then
		aviso = ancla:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		aviso:SetPoint("BOTTOMLEFT", ancla, "TOPLEFT", 0, 2)
	end
	local lista = M.PrestezaLista()
	aviso:SetText(lista and "Presteza lista" or "")
end

---------------------------------------------------------------- la cabecera
function M.Aplicar()
	if enCombate() then pendiente = true; return false end
	pendiente = false
	local d = M.DB()
	local attrs = M.Atributos(M.Perfil())
	if not ancla then
		ancla = CreateFrame("Frame", "MambaCuraAncla", UIParent)
		ancla:SetSize(d.ancho * d.columnas, 20)
		ancla:SetPoint("LEFT", UIParent, "LEFT", 260, -120)
		local api = _G.MambaAPI
		if api and api.Movible then pcall(api.Movible, ancla, "MambaCuraAncla") end
	end
	if not cabecera then
		cabecera = CreateFrame("Frame", "MambaCuraCabecera", ancla, "SecureGroupHeaderTemplate")
		cabecera:SetPoint("TOPLEFT", ancla, "TOPLEFT", 0, 0)
		cabecera:SetAttribute("template", "SecureUnitButtonTemplate,SecureHandlerEnterLeaveTemplate")
		cabecera:SetAttribute("showPlayer", true)
		cabecera:SetAttribute("showParty", true)
		cabecera:SetAttribute("showRaid", true)
		cabecera:SetAttribute("groupBy", "GROUP")
		cabecera:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		cabecera:SetAttribute("point", "TOP")
		cabecera:SetAttribute("columnAnchorPoint", "LEFT")
		cabecera:SetAttribute("unitsPerColumn", 5)
		cabecera:SetAttribute("maxColumns", 8)
		if cabecera.HookScript then
			cabecera:HookScript("OnAttributeChanged", function(_, nombre, valor)
				if type(nombre) == "string" and nombre:match("^child%d+$") and type(valor) == "table" then
					M.NuevoBoton(valor)
				end
			end)
		end
	end
	cabecera:SetAttribute("anchoBoton", d.ancho)
	cabecera:SetAttribute("altoBoton", d.alto)
	cabecera:SetAttribute("showSolo", d.solo)
	cabecera:SetAttribute("initialConfigFunction", M.FragmentoInicial(attrs))
	ancla:SetScale(d.escala or 1)
	-- los botones que ya existen reciben el perfil nuevo
	for _, b in ipairs(botones) do
		for _, c in ipairs(M.CLICS) do
			local pre, boton = c[1]:match("^(.-)(%d)$")
			b:SetAttribute(pre .. "type" .. boton, nil)
			b:SetAttribute(pre .. "spell" .. boton, nil)
		end
		for k, v in pairs(attrs) do b:SetAttribute(k, v) end
	end
	M.MostrarSegun()
	return true
end

function M.NuevoBoton(b)
	for _, x in ipairs(botones) do if x == b then return end end
	botones[#botones + 1] = b
	-- la rueda: el fragmento de entrar/salir va en el botón (SecureHandlerEnterLeaveTemplate)
	if not enCombate() and b.SetAttribute then
		b:SetAttribute("_onenter", ENTRAR)
		b:SetAttribute("_onleave", SALIR)
		for k, v in pairs(M.Atributos(M.Perfil())) do b:SetAttribute(k, v) end
	end
	if b.HookScript then b:HookScript("OnAttributeChanged", function(s, n) if n == "unit" then M.Proteger("pintar", M.Pintar, s) end end) end
	M.Proteger("pintar", M.Pintar, b)
end

-- ¿Se muestran? "siempre" | "grupo" | "nunca". Los modos de pelea (Mamba_Combate) lo cambian con M.Mostrar.
function M.MostrarSegun()
	if not cabecera then return end
	if enCombate() then pendiente = true; return end
	local m, d = M.forzado, M.DB()
	local ver
	if m ~= nil then ver = m
	elseif d.mostrar == "nunca" then ver = false
	elseif d.mostrar == "siempre" then ver = true
	else ver = (IsInGroup and IsInGroup()) or false end
	if ver then cabecera:Show() else cabecera:Hide() end
end
function M.Mostrar(v) M.forzado = v; M.MostrarSegun() end
function M.Pendiente() return pendiente end

---------------------------------------------------------------- eventos
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "GROUP_ROSTER_UPDATE", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_AURA",
	"UNIT_CONNECTION", "ACTIVE_TALENT_GROUP_CHANGED", "SPELL_UPDATE_COOLDOWN", "LEARNED_SPELL_IN_TAB" }) do M.Escuchar(ev, e) end
ev:SetScript("OnEvent", function(_, e, unidad)
	if e == "PLAYER_LOGIN" or e == "ACTIVE_TALENT_GROUP_CHANGED" or e == "LEARNED_SPELL_IN_TAB" then
		M.Proteger("aplicar", M.Aplicar)
	elseif e == "PLAYER_REGEN_ENABLED" then
		if pendiente then M.Proteger("aplicar", M.Aplicar) end
	elseif e == "GROUP_ROSTER_UPDATE" then
		M.Proteger("mostrar", M.MostrarSegun)
		M.PintarTodo()
	elseif e == "SPELL_UPDATE_COOLDOWN" then
		M.Proteger("presteza", M.ActualizarPresteza)
	else
		for _, b in ipairs(botones) do
			if not unidad or (b.GetAttribute and b:GetAttribute("unit") and UnitIsUnit and UnitIsUnit(b:GetAttribute("unit"), unidad)) then
				M.Proteger("pintar", M.Pintar, b)
			end
		end
	end
end)
-- el alcance cambia sin evento: se revisa 4 veces por segundo
local t = 0
ev:SetScript("OnUpdate", function(_, dt)
	t = t + (dt or 0)
	if t < 0.25 then return end
	t = 0
	M.PintarTodo()
end)
M.AlCambiar(function() M.Proteger("aplicar", M.Aplicar) end)
