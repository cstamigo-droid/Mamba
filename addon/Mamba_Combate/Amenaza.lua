-- Mamba_Combate: amenaza del grupo (K66) y placas de nombre propias (K67).
--   Amenaza: UnitDetailedThreatSituation (Forever sí la deja leer: ALCANCE.md, comprobado en EllesmereUI). Una
--   ventanita con tu % y el de tu grupo sobre tu objetivo, y aviso "vas a quitarle el objetivo al tanque".
--   Placas: sobre la placa de cada enemigo, un borde del color de su amenaza contigo, una marca de élite o raro y su
--   barra de lanzamiento con "INTERRUMPIBLE" (si el juego lo esconde, no se marca). Solo se cambia el aspecto, que
--   Blizzard permite; nada se hace por el jugador. Licencia: GPL-3.0-only.
local _, M = ...
local A = {}
M.Amenaza = A

---------------------------------------------------------------- amenaza del grupo
function A.Unidades()
	local out = { "player" }
	if IsInRaid and IsInRaid() then
		for i = 1, (GetNumGroupMembers and GetNumGroupMembers() or 0) do out[#out + 1] = "raid" .. i end
	elseif IsInGroup and IsInGroup() then
		for i = 1, 4 do out[#out + 1] = "party" .. i end
	end
	if UnitExists and UnitExists("pet") then out[#out + 1] = "pet" end
	return out
end

-- Lista ordenada { { nombre, pct, tanque, yo } } sobre el objetivo (lo secreto queda fuera).
function A.Lista()
	local out = {}
	if not (UnitExists("target") and UnitDetailedThreatSituation) then return out end
	for _, u in ipairs(A.Unidades()) do
		if UnitExists(u) and not (UnitIsUnit and u ~= "player" and UnitIsUnit(u, "player")) then
			local ok, tanque, _, pct = pcall(UnitDetailedThreatSituation, u, "target")
			pct = ok and M.Num(pct)
			if pct then
				out[#out + 1] = { nombre = UnitName(u) or u, pct = pct, tanque = (not M.Secreto(tanque)) and tanque or false, yo = u == "player" }
			end
		end
	end
	table.sort(out, function(a, b) return a.pct > b.pct end)
	return out
end

local ventana, filas = nil, {}
local mostrarRol = true
function A.MostrarPorRol(v) mostrarRol = v and true or false; A.Dibujar() end

function A.Dibujar()
	local d = M.DB()
	local lista = A.Lista()
	local ver = d.amenaza and mostrarRol and #lista > 0 and (IsInGroup and IsInGroup() or false)
	if not ventana then
		if not ver then return end
		ventana = CreateFrame("Frame", "MambaAmenaza", UIParent)
		ventana:SetSize(160, 14)
		ventana:SetPoint("RIGHT", UIParent, "RIGHT", -260, 0)
		M.Movible(ventana, "MambaAmenaza")
		ventana.titulo = M.Piezas.Texto(ventana, "small", "text")
		ventana.titulo:SetPoint("BOTTOMLEFT", ventana, "TOPLEFT", 0, 1)
		ventana.titulo:SetText("Amenaza")
	end
	if not ver then ventana:Hide(); return end
	for i = 1, math.max(#lista, #filas) do
		local x = lista[i]
		local b = filas[i]
		if x and i <= 6 then
			if not b then
				b = M.Barra(ventana, 160, 12)
				b:SetPoint("TOP", ventana, "TOP", 0, -(i - 1) * 13)
				b:SetMinMaxValues(0, 100)
				filas[i] = b
			end
			b:SetValue(math.min(100, x.pct))
			if x.tanque then b:SetStatusBarColor(0.8, 0.2, 0.2)
			elseif x.yo then b:SetStatusBarColor(0.9, 0.75, 0.2)
			else b:SetStatusBarColor(0.4, 0.55, 0.85) end
			b.texto:SetText(("%s  %d %%"):format(x.nombre, math.floor(x.pct + 0.5)))
			b:Show()
		elseif b then b:Hide() end
	end
	ventana:Show()
end

-- Aviso: tu amenaza pasa el límite y no eres el tanque.
function A.Peligro()
	if not (UnitExists("target") and UnitDetailedThreatSituation) then return nil end
	local ok, tanque, _, pct = pcall(UnitDetailedThreatSituation, "player", "target")
	pct = ok and M.Num(pct)
	if not pct or M.Secreto(tanque) or tanque then return nil end
	local rol = M.Rotacion and M.Rotacion.Rol and M.Rotacion.Rol()
	if rol == "tanque" then return nil end
	return pct >= (M.DB().avisoAmenaza or 90), pct
end

---------------------------------------------------------------- placas propias
local placas = {}
local COLOR_AMENAZA = { [0] = { 0.3, 0.3, 0.3, 0 }, [1] = { 1, 1, 0.3, 0.9 }, [2] = { 1, 0.55, 0.1, 0.9 }, [3] = { 1, 0.1, 0.1, 0.9 } }

local function capa(unidad)
	local N = C_NamePlate
	local placa = N and N.GetNamePlateForUnit and N.GetNamePlateForUnit(unidad)
	if not placa then return nil end
	local c = placas[placa]
	if not c then
		c = CreateFrame("Frame", nil, placa)
		c:SetAllPoints(placa)
		c.borde = {}
		for i, l in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true } }) do
			local t = c:CreateTexture(nil, "OVERLAY")
			t:SetPoint(l[1], c, l[1], 0, i == 1 and -8 or 8)
			t:SetPoint(l[2], c, l[2], 0, i == 1 and -8 or 8)
			t:SetHeight(2)
			c.borde[i] = t
		end
		c.clase = M.Piezas.Texto(c, "small", "text")
		c.clase:SetPoint("RIGHT", c, "LEFT", 4, 0)
		c.lanz = M.Barra(c, 110, 8)
		c.lanz:SetPoint("TOP", c, "BOTTOM", 0, 4)
		c.lanz:Hide()
		placas[placa] = c
	end
	c.unidad = unidad
	return c
end

function A.PintarPlaca(unidad)
	if not M.DB().placas then return end
	local c = capa(unidad)
	if not c then return end
	-- amenaza contigo
	local st = UnitThreatSituation and UnitThreatSituation("player", unidad)
	st = M.Num(st)
	local col = COLOR_AMENAZA[st or 0] or COLOR_AMENAZA[0]
	-- para el tanque, perder el enemigo es lo peligroso: se invierte
	if M.Rotacion and M.Rotacion.Rol and M.Rotacion.Rol() == "tanque" and st and UnitAffectingCombat and UnitAffectingCombat(unidad) then
		col = (st == 3) and { 0.2, 0.8, 0.2, 0.9 } or { 1, 0.1, 0.1, 0.9 }
	end
	for _, t in ipairs(c.borde) do t:SetColorTexture(col[1], col[2], col[3], col[4]) end
	-- élite o raro
	local cl = UnitClassification and UnitClassification(unidad)
	if M.Secreto(cl) then cl = nil end
	c.clase:SetText((cl == "elite" or cl == "worldboss") and M.Piezas.Color("titulo", "ÉLITE") or ((cl == "rare" or cl == "rareelite") and M.Piezas.Color("bueno", "RARO") or ""))
	c:Show()
end

function A.LanzaPlaca(unidad)
	if not M.DB().placas then return end
	local c = capa(unidad)
	if not c then return end
	local nombre, ini, fin, noInt, _
	if UnitCastingInfo then nombre, _, _, ini, fin, _, _, noInt = UnitCastingInfo(unidad) end
	if not nombre and UnitChannelInfo then nombre, _, _, ini, fin, _, noInt = UnitChannelInfo(unidad) end
	ini, fin = M.Num(ini), M.Num(fin)
	if not (nombre and ini and fin) then c.lanz:Hide(); return end
	c.lanz.ini, c.lanz.fin = ini / 1000, fin / 1000
	local se = (not M.Secreto(noInt)) and (noInt == false or noInt == nil)
	c.lanz:SetStatusBarColor(se and 0.95 or 0.5, se and 0.75 or 0.5, se and 0.2 or 0.5)
	c.lanz.texto:SetText(se and "INTERRUMPIBLE" or "")
	c.lanz:Show()
end

function A.TickPlacas(t)
	for _, c in pairs(placas) do
		local b = c.lanz
		if b:IsShown() and b.fin then
			local fr = (t - b.ini) / (b.fin - b.ini)
			if fr >= 1 then b:Hide() else b:SetValue(fr) end
		end
	end
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE",
	"PLAYER_TARGET_CHANGED", "GROUP_ROSTER_UPDATE", "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_CHANNEL_START",
	"UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_INTERRUPTED" }) do M.Escuchar(f, e) end
f:SetScript("OnEvent", function(_, e, u)
	if e == "NAME_PLATE_UNIT_REMOVED" then
		local N = C_NamePlate
		local p = N and N.GetNamePlateForUnit and N.GetNamePlateForUnit(u)
		if p and placas[p] then placas[p].lanz:Hide() end
		return
	end
	if type(u) == "string" and u:find("^nameplate") then
		if e:find("SPELLCAST") then M.Proteger("lanzaPlaca", A.LanzaPlaca, u) else M.Proteger("placa", A.PintarPlaca, u) end
	end
	if e:find("THREAT") or e == "PLAYER_TARGET_CHANGED" or e == "GROUP_ROSTER_UPDATE" then
		M.Proteger("amenaza", A.Dibujar)
		local N = C_NamePlate
		if N and N.GetNamePlates then
			for _, p in ipairs(N.GetNamePlates() or {}) do
				local uu = p.namePlateUnitToken or (p.UnitFrame and p.UnitFrame.unit)
				if uu then M.Proteger("placa", A.PintarPlaca, uu) end
			end
		end
	end
end)
f:SetScript("OnUpdate", function() M.Proteger("placasTick", A.TickPlacas, GetTime and GetTime() or 0) end)
