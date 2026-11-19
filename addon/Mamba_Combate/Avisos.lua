-- Mamba_Combate: avisos de combate (M2). Solo MUESTRAN (y suenan si quieres); no hacen nada por ti.
--   - Te controlaron (aturdido, miedo, raíces…): qué tiene tu clase para salir (K40), del juego (C_LossOfControl).
--   - "X usó Aturdir" (C4b): un enemigo terminó de lanzar un control conocido (solo el ya terminado; sin registro
--     de combate, que Forever no da: se lee del objetivo, el foco y las placas).
--   - Maná bajo (K19: Inervar, Evocación, beber) y amenaza alta si no eres el tanque.
--   - Antes de pelear (K17, lo propio): te falta tu bufo de clase.
-- Licencia: GPL-3.0-only.
local _, M = ...
local Av = {}
M.Avisos = Av

-- Controles enemigos conocidos (id de rango 1 → qué es). Ids del libro de hechizos del cliente.
Av.CONTROLES = {
	[408] = "aturdir", [1833] = "aturdir", [853] = "aturdir", [5211] = "aturdir", [20549] = "aturdir", [12809] = "aturdir",
	[1776] = "incapacitar", [6770] = "incapacitar", [2094] = "cegar", [118] = "polimorfia", [19503] = "desorientar",
	[5782] = "miedo", [8122] = "miedo", [5246] = "miedo", [5484] = "miedo", [6789] = "miedo", [6358] = "seducir",
	[122] = "raíces", [339] = "raíces", [1499] = "congelar", [2637] = "dormir", [9005] = "aturdir", [19386] = "dormir",
}
-- Qué usar para salir, por clase (K40). Ids de rango 1; solo se nombra lo que sabes.
Av.SALIDAS = {
	DRUID = { raices = { 768, 5487, 783 }, lentitud = { 768, 5487, 783 } },
	HUNTER = { raices = {}, lentitud = {}, miedo = {} },
	ROGUE = {},
	MAGE = { raices = { 1953 }, aturdir = { 1953 } },
	WARRIOR = { raices = {} }, -- Ira rabiosa se pone ANTES: no saca del miedo
	PRIEST = {}, -- Resguardo contra el miedo se pone ANTES: no saca del miedo
	SHAMAN = {}, -- el tótem de tremor también va antes
	PALADIN = { raices = { 1044 }, lentitud = { 1044 } }, -- Escudo divino no quita aturdir ni miedo
	WARLOCK = {},
}
Av.RAZA = { Scourge = { miedo = 7744, dormir = 7744, seducir = 7744 }, -- Voluntad de los Renegados
	Gnome = { raices = 20589, lentitud = 20589 } } -- Artista del escape
Av.BUFO = { DRUID = { 1126 }, PRIEST = { 1243 }, MAGE = { 1459 }, WARRIOR = { 6673 }, HUNTER = { 13165 }, PALADIN = { 19740 }, WARLOCK = { 706, 687 }, SHAMAN = { 324 } }
Av.MANA = { DRUID = 29166, MAGE = 12051, WARLOCK = 1454, SHAMAN = 16190 }

local function clave(tipo)
	if not tipo or M.Secreto(tipo) then return nil end
	tipo = tostring(tipo):upper()
	if tipo:find("ROOT") then return "raices" end
	if tipo:find("FEAR") or tipo:find("CHARM") or tipo:find("CONFUSE") then return "miedo" end
	if tipo:find("STUN") then return "aturdir" end
	if tipo:find("SNARE") or tipo:find("SLOW") then return "lentitud" end
	if tipo:find("SLEEP") then return "dormir" end
	return nil
end

-- Qué hechizos tuyos sirven contra ese control (solo los que sabes y están listos).
function Av.Salidas(tipo)
	if M.Secreto(tipo) then return {} end
	local k = clave(tipo) or tipo
	local out = {}
	for _, id in ipairs((Av.SALIDAS[M.Clase()] or {})[k] or {}) do
		if M.Conoce(id) then out[#out + 1] = id end
	end
	local raza = UnitRace and select(2, UnitRace("player"))
	local r = Av.RAZA[raza or ""]
	if r and r[k] and M.Conoce(r[k]) then out[#out + 1] = r[k] end
	return out
end

---------------------------------------------------------------- el cartel
local cartel
function Av.CrearCartel()
	if cartel then return end
	cartel = CreateFrame("Frame", "MambaAviso", UIParent)
	cartel:SetSize(420, 30)
	cartel:SetPoint("TOP", UIParent, "TOP", 0, -180)
	cartel:Hide()
	M.Movible(cartel, "MambaAviso", "Avisos en pantalla")
	cartel.texto = M.Piezas.Texto(cartel, "heading", "text")
	cartel.texto:SetAllPoints(cartel)
end
M.Precrear(function() Av.CrearCartel() end)
M.AlModoMover(function(activo)
	Av.CrearCartel()
	if activo then
		if not cartel:IsShown() then
			cartel.ejemplo = true
			cartel.hasta = nil -- no se apaga solo mientras se mueve
			cartel.texto:SetText(M.Piezas.Color("titulo", "Avisos en pantalla (ejemplo)"))
			cartel:Show()
		end
	elseif cartel.ejemplo then
		cartel.ejemplo = nil
		cartel:Hide()
	end
end)
local function mostrar(texto, rojo, control)
	if not M.DB().avisos then return end
	if not cartel then Av.CrearCartel() end
	cartel.texto:SetText(M.Piezas.Color(rojo and "dudoso" or "titulo", texto))
	cartel.hasta = (GetTime and GetTime() or 0) + 3
	cartel:Show()
	local d = M.DB()
	if PlaySound and ((control and d.sonido) or d.sonidoTodos) then pcall(PlaySound, 8959) end
	Av.ultimo = texto
end
Av.Mostrar = mostrar

function Av.Control()
	local L = C_LossOfControl
	if not (L and L.GetActiveLossOfControlData) then return end
	local ok, d = pcall(L.GetActiveLossOfControlData, 1)
	if not (ok and d) then return end
	local tipo = d.locType
	local txt = (not M.Secreto(d.displayText) and d.displayText) or "Te controlaron"
	local s = Av.Salidas(tipo)
	local nombres = {}
	for _, id in ipairs(s) do nombres[#nombres + 1] = M.NombreHechizo(id) end
	mostrar(txt .. (#nombres > 0 and (": usa " .. table.concat(nombres, " o ")) or ""), true, true)
end

local ultimoLanzado, porNombre = {}, nil
-- Un control por su NOMBRE (cada rango tiene otro id: Polimorfia 118, 12824…)
function Av.TipoControl(id)
	if M.Secreto(id) or not id then return nil end
	if Av.CONTROLES[id] then return Av.CONTROLES[id] end
	if not porNombre then
		porNombre = {}
		for i, tipo in pairs(Av.CONTROLES) do
			local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(i)
			if n then porNombre[n] = tipo end
		end
	end
	local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
	return n and porNombre[n]
end
function Av.Lanzado(unidad, id)
	if not Av.TipoControl(id) then return end
	local t = GetTime and GetTime() or 0
	local tipo = Av.TipoControl(id)
	if t - (ultimoLanzado[tipo] or -99) < 3 then return end -- uno cada 3 s por tipo de control
	ultimoLanzado[tipo] = t
	if not (UnitCanAttack and M.Si(UnitCanAttack("player", unidad))) then return end
	local quien = UnitName(unidad)
	if M.Secreto(quien) then quien = "Un enemigo" end
	mostrar(("%s usó %s"):format(quien or "Un enemigo", M.NombreHechizo(id)), true)
end

local avisoManaHecho, manaMuyBajo, amenazaArmada, ultimoAmenaza = false, false, true, -99
function Av.Revisar()
	local d = M.DB()
	local t = GetTime and GetTime() or 0
	if cartel and cartel.hasta and t > cartel.hasta then cartel:Hide() end
	if not M.EnCombate() then avisoManaHecho, manaMuyBajo = false, false; return end
	local pct = M.Pct(UnitPower("player", 0), UnitPowerMax("player", 0))
	-- maná: una vez por pelea, y otra solo si baja del 10 %
	local toca = pct and d.avisoManaSi and ((not avisoManaHecho and pct < (d.avisoMana or 25)) or (not manaMuyBajo and pct < 10))
	if toca then
		avisoManaHecho = true
		if pct < 10 then manaMuyBajo = true end
		local id = Av.MANA[M.Clase()]
		mostrar(("Maná bajo (%d %%)"):format(pct) .. ((id and M.Conoce(id)) and (": usa " .. M.NombreHechizo(id)) or ": bebe al terminar"))
	end
	local peligro, ap
	if M.Amenaza then peligro, ap = M.Amenaza.Peligro() end
	-- amenaza: al cruzar el límite; se vuelve a armar al bajar del 80 % o a los 30 s
	if ap and (ap < 80 or t - ultimoAmenaza > 30) then amenazaArmada = true end
	if peligro and d.avisoAmenazaSi and amenazaArmada then
		amenazaArmada = false
		ultimoAmenaza = t
		mostrar(("Amenaza %d %%: vas a quitarle el objetivo al tanque"):format(ap), true)
	end
end

-- Antes de pelear: ¿te falta tu bufo de clase? (devuelve el id o nil)
function Av.BufoQueFalta()
	local R = M.Rotacion
	local falta
	for _, id in ipairs(Av.BUFO[M.Clase()] or {}) do
		if M.Conoce(id) then
			local a = R and R.Condicion({ "sinBuff", id })
			if a == false then return nil end -- tiene uno de los de su clase
			if a == true and not falta then falta = id end
		end
	end
	return falta
end

local f = CreateFrame("Frame")
M.Escuchar(f, "LOSS_OF_CONTROL_ADDED")
M.Escuchar(f, "UNIT_SPELLCAST_SUCCEEDED")
M.Escuchar(f, "PLAYER_REGEN_DISABLED")
M.Escuchar(f, "ZONE_CHANGED_NEW_AREA")
f:SetScript("OnEvent", function(_, e, u, _, id)
	if e == "LOSS_OF_CONTROL_ADDED" then M.Proteger("control", Av.Control)
	elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
		if type(u) == "string" and (u == "target" or u == "focus" or u:find("^nameplate")) then M.Proteger("lanzado", Av.Lanzado, u, id) end
	elseif e == "ZONE_CHANGED_NEW_AREA" then
		local _, tipo
	if IsInInstance then _, tipo = IsInInstance() end
		local falta = (tipo == "party" or tipo == "raid") and Av.BufoQueFalta()
		if falta then mostrar("Antes de pelear: te falta " .. M.NombreHechizo(falta)) end
	end
end)
local t = 0
f:SetScript("OnUpdate", function(_, dt)
	t = t + (dt or 0)
	if t < 0.5 then return end
	t = 0
	M.Proteger("avisos", Av.Revisar)
end)
