-- Mamba_Curacion: los marcos de grupo y banda con clic para curar (C7, K11-K13, K16, K86, K97).
-- Plantillas seguras del juego: SecureGroupHeaderTemplate arma un botón por miembro y cada botón es un
-- SecureUnitButtonTemplate con los atributos del perfil (el clic del jugador lanza el hechizo sobre ese miembro,
-- sin cambiar el objetivo). La rueda se ata solo mientras el ratón está encima (fragmento seguro _onenter).
-- Forever esconde algunos números (vida exacta, auras de otros en instancias): se pasan tal cual a las barras
-- sin hacer cuentas con ellos, y lo que no se puede leer no se muestra. Licencia: GPL-3.0-only.
local _, M = ...

local cabecera, ancla, asa
local porUnidad = {} -- "party1" -> botón
function M.Unidad(b, u)
	for k, x in pairs(porUnidad) do if x == b then porUnidad[k] = nil end end
	if type(u) == "string" then porUnidad[u] = b end
end
function M.BotonDe(u) return porUnidad[u] end
local botones = {}
local pendiente = false
local function enCombate() return InCombatLockdown and InCombatLockdown() end
local function secreto(v) return issecretvalue and issecretvalue(v) end

-- Fragmento seguro: al entrar el ratón ata la rueda a este botón; al salir la suelta.
local ENTRAR = [[
	for _, m in ipairs(newtable("", "SHIFT-", "CTRL-", "ALT-")) do
		self:SetBindingClick(true, m .. "MOUSEWHEELUP", self, "Button4")
		self:SetBindingClick(true, m .. "MOUSEWHEELDOWN", self, "Button5")
	end ]]
local SALIR = [[ self:ClearBindings() ]]
local function usaRueda(attrs)
	for k in pairs(attrs) do if k:match("type[45]$") then return true end end
	return false
end

-- El fragmento que la cabecera corre en cada botón nuevo (también en combate): copia los atributos del perfil.
function M.FragmentoInicial(attrs)
	local t = { [[ self:SetWidth(self:GetParent():GetAttribute("anchoBoton")); self:SetHeight(self:GetParent():GetAttribute("altoBoton")); self:SetAttribute("useOnKeyDown", false) ]] }
	local claves = {}
	for k in pairs(attrs) do claves[#claves + 1] = k end
	table.sort(claves)
	for _, k in ipairs(claves) do
		t[#t + 1] = ("self:SetAttribute(%q, %q)"):format(k, attrs[k])
	end
	-- OJO: el código restringido NO puede poner atributos que empiezan con "_" (RestrictedFrames: "Invalid attribute
	-- name", 275 veces en el juego el 19-11). Los fragmentos de la rueda van con "_initialAttribute-" en la cabecera.
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
	b.nombre = M.Piezas.Texto(b.vida, "small", "text")
	b.nombre:SetPoint("CENTER", b.vida, "CENTER", 0, 4)
	b.estado = M.Piezas.Texto(b.vida, "small", "textMuted")
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
-- Alcance (K12): del hechizo del clic izquierdo si se puede, si no el de grupo
function M.Alcance(b)
	local u = b.GetAttribute and b:GetAttribute("unit")
	if not (u and M.DB().rango) then return end
		local inR
		local sp = b:GetAttribute("spell1")
		if sp and C_Spell and C_Spell.IsSpellInRange then inR = C_Spell.IsSpellInRange(sp, u) end
		if not secreto(inR) and inR == nil and UnitInRange then inR = UnitInRange(u) end
		if secreto(inR) and b.SetAlphaFromBoolean then pcall(b.SetAlphaFromBoolean, b, inR, 1, 0.45)
		elseif not secreto(inR) then b:SetAlpha((inR == false or inR == 0) and 0.45 or 1) end
end

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
	M.Alcance(b)
	-- mis HoT con su cuenta regresiva (K13)
	local A = C_UnitAuras
	local n = 0
	if d.hots and A and A.GetAuraDataByIndex then
		for i = 1, 20 do
			local ok, a = pcall(A.GetAuraDataByIndex, u, i, "HELPFUL|PLAYER")
			if not ok or not a then break end
			local dur = a.duration
			local corto = (not secreto(dur)) and (dur or 0) > 0 and dur <= 60
			if n < 3 and (corto or secreto(dur)) then
				n = n + 1
				local h = b.hots[n]
				pcall(h.icono.SetTexture, h.icono, a.icon)
				if not secreto(a.duration) and not secreto(a.expirationTime) and (a.duration or 0) > 0 then
					h.cd:SetCooldown(a.expirationTime - a.duration, a.duration)
				elseif h.cd.Clear then
					h.cd:Clear()
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
		aviso = M.Piezas.Texto(ancla, "small", "text")
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
		-- el asa: un marco aparte (no protegido) que solo se ve con "Mover marcos" y fuera de combate
		asa = CreateFrame("Frame", "MambaCuraAsa", UIParent)
		asa:SetSize(160, 18)
		asa:SetPoint("BOTTOMLEFT", ancla, "TOPLEFT", 0, 16)
		asa.fondo = asa:CreateTexture(nil, "BACKGROUND")
		asa.fondo:SetAllPoints(asa)
		asa.fondo:SetColorTexture(0.1, 0.1, 0.12, 0.9)
		asa.texto = M.Piezas.Texto(asa, "small", "text")
		asa.texto:SetPoint("CENTER", asa, "CENTER", 0, 0)
		asa.texto:SetText("Arrastra para mover")
		asa:Hide()
		local api = _G.MambaAPI
		if api and api.Movible then pcall(api.Movible, ancla, "MambaCuraAncla", asa) end
		ancla:EnableMouse(false)
	end
	if not cabecera then
		cabecera = CreateFrame("Frame", "MambaCuraCabecera", ancla, "SecureGroupHeaderTemplate")
		cabecera:SetPoint("TOPLEFT", ancla, "TOPLEFT", 0, 0)
		-- SecureActionButtonTemplate (como HealBot): SecureUnitButtonTemplate consulta antes los atajos de clic de Blizzard
		cabecera:SetAttribute("template", "SecureActionButtonTemplate,SecureHandlerEnterLeaveTemplate,SecureHandlerShowHideTemplate")
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
	-- la rueda: el código seguro de la cabecera copia estos atributos a cada botón nuevo (también en combate)
	local r = usaRueda(attrs)
	cabecera:SetAttribute("_initialAttribute-_onenter", r and ENTRAR or nil)
	cabecera:SetAttribute("_initialAttribute-_onleave", r and SALIR or nil)
	cabecera:SetAttribute("_initialAttribute-_onhide", r and SALIR or nil)
	ancla:SetScale(d.escala or 1)
	for i = 1, 40 do
		local h = cabecera.GetAttribute and cabecera:GetAttribute("child" .. i)
		if type(h) == "table" then M.NuevoBoton(h) end
	end
	-- los botones que ya existen reciben el perfil nuevo y el tamaño (y los clics de todos los botones del ratón:
	-- un botón creado en plena pelea solo tiene el izquierdo hasta acá)
	local rueda = usaRueda(attrs)
	for _, b in ipairs(botones) do
		if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
		b:SetSize(d.ancho, d.alto)
		b:SetAttribute("_onenter", rueda and ENTRAR or nil)
		b:SetAttribute("_onleave", rueda and SALIR or nil)
		b:SetAttribute("_onhide", rueda and SALIR or nil)
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
		local attrs = M.Atributos(M.Perfil())
		if b.RegisterForClicks then b:RegisterForClicks("AnyUp") end
		b:SetAttribute("useOnKeyDown", false)
		if usaRueda(attrs) then
			b:SetAttribute("_onenter", ENTRAR)
			b:SetAttribute("_onleave", SALIR)
			b:SetAttribute("_onhide", SALIR)
		end
		for k, v in pairs(attrs) do b:SetAttribute(k, v) end
	elseif enCombate() then
		pendiente = true -- RegisterForClicks y el perfil, al salir de combate
	end
	if b.HookScript then b:HookScript("OnAttributeChanged", function(s, n, v)
		if n == "unit" then M.Unidad(s, v); M.Proteger("pintar", M.Pintar, s) end
	end) end
	M.Unidad(b, b.GetAttribute and b:GetAttribute("unit"))
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
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "GROUP_ROSTER_UPDATE", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_AURA",
	"UNIT_CONNECTION", "ACTIVE_TALENT_GROUP_CHANGED", "SPELL_UPDATE_COOLDOWN", "LEARNED_SPELL_IN_TAB", "SPELLS_CHANGED" }) do M.Escuchar(ev, e) end
ev:SetScript("OnEvent", function(_, e, unidad)
	if e == "SPELLS_CHANGED" then
		-- LEARNED_SPELL_IN_TAB no existe en Forever (diag 19-11): se usa SPELLS_CHANGED, solo si cambió el perfil
		local k, at = {}, M.Atributos(M.Perfil())
		for x, v in pairs(at) do k[#k + 1] = x .. "=" .. tostring(v) end
		table.sort(k)
		local firma = table.concat(k, ";")
		if firma == M.firma then return end
		M.firma = firma
		M.Proteger("aplicar", M.Aplicar)
	elseif e == "PLAYER_LOGIN" or e == "ACTIVE_TALENT_GROUP_CHANGED" or e == "LEARNED_SPELL_IN_TAB" then
		M.Proteger("aplicar", M.Aplicar)
	elseif e == "PLAYER_REGEN_ENABLED" or e == "PLAYER_REGEN_DISABLED" then
		-- al entrar en combate InCombatLockdown() todavía da false: el asa se esconde SIEMPRE (y se corta el arrastre)
		if e == "PLAYER_REGEN_DISABLED" then
			if asa then if asa.StopMovingOrSizing and ancla then ancla:StopMovingOrSizing() end; asa:Hide() end
		else
			M.Proteger("asa", M.MostrarAsa)
		end
		if e == "PLAYER_REGEN_ENABLED" and pendiente then M.Proteger("aplicar", M.Aplicar) end
	elseif e == "GROUP_ROSTER_UPDATE" then
		M.Proteger("mostrar", M.MostrarSegun)
		M.PintarTodo()
	elseif e == "SPELL_UPDATE_COOLDOWN" then
		M.Proteger("presteza", M.ActualizarPresteza)
	else
		if type(unidad) == "string" and not (unidad == "player" or unidad:find("^party") or unidad:find("^raid")) then return end
		-- tabla unidad -> botón: sin recorrer todos los botones en cada evento
		local b = unidad and porUnidad[unidad]
		if b then
			M.Proteger("pintar", M.Pintar, b)
		elseif not unidad or unidad == "player" then
			for _, x in ipairs(botones) do
				local u = x.GetAttribute and x:GetAttribute("unit")
				if not unidad or (u and UnitIsUnit and UnitIsUnit(u, unidad)) then M.Proteger("pintar", M.Pintar, x) end
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
	for _, b in ipairs(botones) do if b:IsVisible() then M.Proteger("alcance", M.Alcance, b) end end
	M.ActualizarPresteza()
end)

-- "Mover marcos": el asa solo se ve fuera de combate y con la opción encendida
function M.MostrarAsa()
	if not asa then return end
	if (M.DB().mover or M.modoMover) and not enCombate() then asa:Show() else asa:Hide() end
end
function M.Asa() return asa end
M.AlCambiar(function() M.Proteger("aplicar", M.Aplicar); M.Proteger("asa", M.MostrarAsa) end)

-- K55 ampliado (18-11): el modo «Mover elementos» de Mamba muestra también el asa de estos marcos.
local enlace = CreateFrame("Frame")
enlace:RegisterEvent("PLAYER_LOGIN")
enlace:SetScript("OnEvent", function()
	local api = _G.MambaAPI
	if not (api and api.AlModoMover) then return end
	pcall(api.AlModoMover, function(activo)
		M.modoMover = activo and true or false
		M.Proteger("asa", M.MostrarAsa)
	end)
end)
