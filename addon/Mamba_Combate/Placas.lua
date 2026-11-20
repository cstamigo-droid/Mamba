-- Mamba_Combate: placas de nombre propias y compactas (K67, K90; idea de Platynator y Plater, código propio).
-- Cristian, 18-11: las de Blizzard son grandes. Sobre la placa de cada ENEMIGO (las amigas quedan como el juego)
-- se dibuja una barra fina y se esconde el dibujo de Blizzard (solo su aspecto: el clic para elegir objetivo
-- sigue siendo el del juego). Lleva:
--   - la vida (el juego puede pasarla como valor secreto: va tal cual a la barra, sin cuentas);
--   - el nombre, y el nivel si el juego lo deja leer;
--   - ÉLITE o RARO;
--   - el color de la amenaza contigo (para el tanque, al revés: rojo si lo pierdes);
--   - el marcador de banda (calavera, cruz…);
--   - la barra de lanzamiento con «INTERRUMPIBLE» (si el juego lo esconde, no se marca);
--   - los enfriamientos importantes que el enemigo ya usó (Gladius.lua), si es un jugador.
-- Tamaño configurable (ancho y alto) en Combate › Avisos y barras. Apagarlas devuelve las de Blizzard.
-- Nada se hace por el jugador. Licencia: GPL-3.0-only.
local _, M = ...
local Pl = {}
M.Placas = Pl

local placas = {}       -- placa del juego -> la nuestra
local ocultas = {}      -- UnitFrame de Blizzard que escondemos -> true
local COLOR_AMENAZA = { [1] = { 1, 0.85, 0.3 }, [2] = { 1, 0.55, 0.1 }, [3] = { 0.95, 0.15, 0.15 } }
local ICONOS_BANDA = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"

local function db() return M.DB() end
local function leer(v) if v == nil or M.Secreto(v) then return nil end return v end
-- Tal cual (secreto incluido) o el valor por defecto si no hay: nunca se prueba un secreto con «or» ni «if».
local function tal(v, defecto) if M.Secreto(v) then return v end if v == nil then return defecto end return v end
Pl.Tal = tal

function Pl.Medidas()
	local d = db()
	local an = M.Num(d.placaAncho) or 100
	local al = M.Num(d.placaAlto) or 8
	return math.max(50, math.min(200, an)), math.max(3, math.min(20, al))
end

-- ¿Es un enemigo (lo que dibuja Mamba)? Lo amigo queda con la placa del juego.
function Pl.EsEnemigo(u)
	if not (UnitCanAttack) then return false end
	local ok, si = pcall(UnitCanAttack, "player", u)
	return ok and leer(si) == true
end

-- Esconde el dibujo de Blizzard (solo el aspecto). Si Blizzard le vuelve a subir el alfa, se baja de nuevo.
local function esconderBlizzard(placa)
	local uf = placa and placa.UnitFrame
	if not uf or not uf.SetAlpha then return end
	ocultas[uf] = true
	uf:SetAlpha(0)
	if not uf.mambaGancho and hooksecurefunc then
		uf.mambaGancho = true
		pcall(hooksecurefunc, uf, "SetAlpha", function(s, a)
			if ocultas[s] and a ~= 0 and not s.mambaPoniendo then s.mambaPoniendo = true; s:SetAlpha(0); s.mambaPoniendo = nil end
		end)
	end
end
local function mostrarBlizzard(placa)
	local uf = placa and placa.UnitFrame
	if not uf or not ocultas[uf] then return end
	ocultas[uf] = nil
	uf.mambaPoniendo = true
	uf:SetAlpha(1)
	uf.mambaPoniendo = nil
end
Pl.MostrarBlizzard = mostrarBlizzard

local function crear(placa)
	local an, al = Pl.Medidas()
	local c = CreateFrame("Frame", nil, placa)
	c:SetSize(an, al)
	c:SetPoint("CENTER", placa, "CENTER", 0, 0)
	c.vida = M.Barra(c, an, al)
	c.vida:SetAllPoints(c)
	c.vida.texto:SetText("")
	c.borde = {}
	for i, l in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, 1, true }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, -1, true },
		{ "TOPLEFT", "BOTTOMLEFT", -1, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 1, 0 } }) do
		local t = c:CreateTexture(nil, "OVERLAY")
		t:SetPoint(l[1], c, l[1], l[3], l[4])
		t:SetPoint(l[2], c, l[2], l[3], l[4])
		if l[5] then t:SetHeight(1) else t:SetWidth(1) end
		t:SetColorTexture(0, 0, 0, 1)
		c.borde[i] = t
	end
	c.nombre = M.Piezas.Texto(c, "small", "text")
	c.nombre:SetPoint("BOTTOM", c, "TOP", 0, 2)
	c.marca = M.Piezas.Texto(c, "small", "text")
	c.marca:SetPoint("RIGHT", c.nombre, "LEFT", -3, 0)
	c.banda = c:CreateTexture(nil, "OVERLAY")
	c.banda:SetSize(14, 14)
	c.banda:SetPoint("LEFT", c, "RIGHT", 3, 0)
	c.banda:SetTexture(ICONOS_BANDA)
	c.banda:Hide()
	c.lanz = M.Barra(c, an, math.max(6, al - 1))
	c.lanz:SetPoint("TOP", c, "BOTTOM", 0, -2)
	c.lanz:Hide()
	c.cds = {}
	for i = 1, 3 do
		local f = CreateFrame("Frame", nil, c)
		f:SetSize(16, 16)
		if i == 1 then f:SetPoint("BOTTOMRIGHT", c, "TOPRIGHT", 0, 14) else f:SetPoint("RIGHT", c.cds[i - 1], "LEFT", -2, 0) end
		f.icono = f:CreateTexture(nil, "ARTWORK")
		f.icono:SetAllPoints(f)
		f.t = M.Piezas.Texto(f, "small", "text")
		f.t:SetPoint("CENTER", f, "CENTER", 0, 0)
		f:Hide()
		c.cds[i] = f
	end
	placas[placa] = c
	return c
end

local function capa(unidad)
	local N = C_NamePlate
	local placa = N and N.GetNamePlateForUnit and N.GetNamePlateForUnit(unidad)
	if not placa then return nil end
	local c = placas[placa] or crear(placa)
	c.unidad, c.placa = unidad, placa
	return c
end
Pl.Capa = capa

-- Ícono del marcador de banda (1 estrella … 8 calavera) en la textura del juego.
function Pl.CoordsBanda(i)
	i = (i or 1) - 1
	local x, y = i % 4, math.floor(i / 4)
	return x * 0.25, (x + 1) * 0.25, y * 0.25, (y + 1) * 0.25
end

function Pl.Color(unidad)
	-- amenaza contigo primero (en combate)
	local st = UnitThreatSituation and M.Num(UnitThreatSituation("player", unidad))
	local tanque = M.Rotacion and M.Rotacion.Rol and M.Rotacion.Rol() == "tanque"
	if st and UnitAffectingCombat and leer(UnitAffectingCombat(unidad)) then
		if tanque then
			if st == 3 then return 0.25, 0.75, 0.3, "amenaza" end
			return 0.95, 0.15, 0.15, "amenaza"
		end
		local c = COLOR_AMENAZA[st]
		if c then return c[1], c[2], c[3], "amenaza" end
	end
	if UnitIsPlayer and leer(UnitIsPlayer(unidad)) then
		local _, token = UnitClass(unidad)
		token = leer(token)
		local c = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
		if c then return c.r, c.g, c.b, "clase" end
	end
	local r = UnitReaction and leer(UnitReaction(unidad, "player"))
	if r == 4 then return 0.9, 0.8, 0.2, "neutral" end
	return 0.75, 0.18, 0.15, "hostil"
end

-- Otro addon de placas (Plater, Platynator, Kui, ThreatPlates…) ya dibuja las suyas: Mamba no dibuja encima ni
-- toca el alfa de la placa del juego (revisión wow-addon-lua, 19-11).
Pl.OTROS = { "Plater", "Platynator", "Kui_Nameplates", "TidyPlates_ThreatPlates", "NeatPlates" }
local otroVisto, otroCual
function Pl.OtroAddon()
	if otroVisto then return otroCual end
	otroVisto = true
	otroCual = Pl.BuscarOtro()
	return otroCual
end
-- se mira una vez por sesión (los addons no se cargan a mitad de juego)
function Pl.BuscarOtro()
	local cargado = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
	if not cargado then return nil end
	for _, n in ipairs(Pl.OTROS) do
		local ok, si = pcall(cargado, n)
		if ok and si then return n end
	end
end

-- K123: borde naranja o rojo en la placa del bicho que estás por atraer (nivel = "rojo" | "amarillo" | nil).
-- El objetivo conserva su borde blanco.
function Pl.MarcarAgro(unidad, nivel)
	local N = C_NamePlate
	local placa = N and N.GetNamePlateForUnit and N.GetNamePlateForUnit(unidad)
	local c = placa and placas[placa]
	if not c or not c:IsShown() or c.objetivo then return end
	c.agro = nivel
	for _, t in ipairs(c.borde) do
		if nivel == "rojo" then t:SetColorTexture(1, 0.2, 0.1, 1)
		elseif nivel == "amarillo" then t:SetColorTexture(1, 0.65, 0.1, 1)
		else t:SetColorTexture(0, 0, 0, 1) end
	end
end

function Pl.Pintar(unidad)
	if Pl.OtroAddon() then return end
	local N = C_NamePlate
	local placa = N and N.GetNamePlateForUnit and N.GetNamePlateForUnit(unidad)
	if not placa then return end
	if not db().placas or not Pl.EsEnemigo(unidad) then
		mostrarBlizzard(placa)
		if placas[placa] then placas[placa]:Hide() end
		return
	end
	local c = capa(unidad)
	esconderBlizzard(placa)
	local an, al = Pl.Medidas()
	c:SetSize(an, al)
	c.vida:SetSize(an, al)
	c.lanz:SetSize(an, math.max(6, al - 1))
	-- vida: secreta o no, va tal cual a la barra
	c.vida:SetMinMaxValues(0, tal(UnitHealthMax(unidad), 1))
	c.vida:SetValue(tal(UnitHealth(unidad), 0))
	local r, g, b, porque = Pl.Color(unidad)
	c.vida:SetStatusBarColor(r, g, b)
	c.porque = porque
	-- objetivo: borde claro
	local obj = UnitIsUnit and leer(UnitIsUnit(unidad, "target"))
	for _, t in ipairs(c.borde) do
		if obj then t:SetColorTexture(1, 1, 1, 0.95) else t:SetColorTexture(0, 0, 0, 1) end
	end
	c.objetivo = obj and true or false
	-- nombre (secreto o no, va tal cual) y nivel solo si se puede leer
	c.nombre:SetText(tal(UnitName(unidad), ""))
	local nivel = UnitLevel and M.Num(UnitLevel(unidad))
	local cl = UnitClassification and leer(UnitClassification(unidad))
	local marca = ""
	if cl == "elite" or cl == "worldboss" then marca = M.Piezas.Color("titulo", "ÉLITE")
	elseif cl == "rare" or cl == "rareelite" then marca = M.Piezas.Color("bueno", "RARO") end
	if nivel then marca = (nivel == -1 and "??" or tostring(nivel)) .. (marca ~= "" and (" " .. marca) or "") end
	c.marca:SetText(marca)
	c.clasif = cl
	-- marcador de banda
	local i = GetRaidTargetIndex and M.Num(GetRaidTargetIndex(unidad))
	if i and i >= 1 and i <= 8 then
		c.banda:SetTexCoord(Pl.CoordsBanda(i)); c.banda:Show(); c.marcador = i
	else c.banda:Hide(); c.marcador = nil end
	Pl.PintarCDs(c)
	c:Show()
end

-- Enfriamientos usados por ese jugador (los lleva Gladius.lua).
function Pl.PintarCDs(c)
	local G = M.Gladius
	local lista = (G and G.ActivosDe and G.ActivosDe(c.unidad)) or {}
	for i, f in ipairs(c.cds) do
		local x = lista[i]
		if x then f.icono:SetTexture(x.icono); f.t:SetText(x.resta and tostring(math.ceil(x.resta)) or ""); f:Show() else f:Hide() end
	end
end

function Pl.Lanza(unidad)
	if not db().placas or not Pl.EsEnemigo(unidad) then return end
	local c = capa(unidad)
	if not c then return end
	local nombre, ini, fin, noInt, _
	if UnitCastingInfo then nombre, _, _, ini, fin, _, _, noInt = UnitCastingInfo(unidad) end
	if not (M.Secreto(nombre) or nombre ~= nil) and UnitChannelInfo then nombre, _, _, ini, fin, _, noInt = UnitChannelInfo(unidad) end
	ini, fin = M.Num(ini), M.Num(fin)
	if not (M.Secreto(nombre) or nombre ~= nil) or not (ini and fin) then c.lanz:Hide(); return end
	c.lanz.ini, c.lanz.fin = ini / 1000, fin / 1000
	local se = (not M.Secreto(noInt)) and (noInt == false or noInt == nil)
	c.lanz:SetStatusBarColor(se and 0.95 or 0.5, se and 0.75 or 0.5, se and 0.2 or 0.5)
	c.lanz.texto:SetText(se and "INTERRUMPIBLE" or "")
	c.lanz:Show()
end

function Pl.Quitar(unidad)
	local N = C_NamePlate
	local p = N and N.GetNamePlateForUnit and N.GetNamePlateForUnit(unidad)
	local c = p and placas[p]
	if c then c.lanz:Hide(); c:Hide() end
	if p then mostrarBlizzard(p) end
end

function Pl.Tick(t)
	for _, c in pairs(placas) do
		local b = c.lanz
		if b:IsShown() and b.fin then
			local fr = (t - b.ini) / (b.fin - b.ini)
			if fr >= 1 then b:Hide() else b:SetValue(fr) end
		end
	end
end

-- Todas de nuevo (al cambiar el tamaño, encender o apagar, o el objetivo).
function Pl.Todas()
	local N = C_NamePlate
	if not (N and N.GetNamePlates) then return end
	for _, p in ipairs(N.GetNamePlates() or {}) do
		local u = p.namePlateUnitToken or (p.UnitFrame and p.UnitFrame.unit)
		if u then M.Proteger("placa", Pl.Pintar, u) end
	end
end
function Pl.Lista() return placas end

-- compatibilidad con el nombre de antes (Amenaza.lua)
if M.Amenaza then M.Amenaza.PintarPlaca, M.Amenaza.LanzaPlaca = Pl.Pintar, Pl.Lanza end

local f = CreateFrame("Frame")
for _, e in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE",
	"PLAYER_TARGET_CHANGED", "RAID_TARGET_UPDATE", "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP",
	"UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_FACTION" }) do M.Escuchar(f, e) end
local proxTodas = 0
f:SetScript("OnEvent", function(_, e, u)
	if e == "NAME_PLATE_UNIT_REMOVED" then M.Proteger("placaQuitar", Pl.Quitar, u); return end
	if e == "PLAYER_TARGET_CHANGED" or e == "RAID_TARGET_UPDATE" then M.Proteger("placas", Pl.Todas); return end
	if type(u) ~= "string" or not u:find("^nameplate") then
		if e:find("THREAT") then
			local t = GetTime and GetTime() or 0
			if t >= proxTodas then proxTodas = t + 0.2; M.Proteger("placas", Pl.Todas) end
		end
		return
	end
	if e:find("SPELLCAST") then M.Proteger("lanzaPlaca", Pl.Lanza, u)
	elseif e == "UNIT_HEALTH" or e == "UNIT_MAXHEALTH" then
		local N = C_NamePlate
		local p = N and N.GetNamePlateForUnit and N.GetNamePlateForUnit(u)
		local c = p and placas[p]
		if c and c:IsShown() then c.vida:SetMinMaxValues(0, tal(UnitHealthMax(u), 1)); c.vida:SetValue(tal(UnitHealth(u), 0)) end
	else M.Proteger("placa", Pl.Pintar, u) end
end)
local acum = 0
f:SetScript("OnUpdate", function(_, dt)
	local t = GetTime and GetTime() or 0
	M.Proteger("placasTick", Pl.Tick, t)
	acum = acum + (dt or 0)
	if acum >= 1 then -- los números de los enfriamientos del enemigo, una vez por segundo
		acum = 0
		for _, c in pairs(placas) do if c:IsShown() then M.Proteger("placasCD", Pl.PintarCDs, c) end end
	end
end)
M.AlCambiar(function() M.Proteger("placas", Pl.Todas) end)
