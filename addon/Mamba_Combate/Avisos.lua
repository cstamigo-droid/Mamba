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
	[122] = "raíces", [339] = "raíces", [1499] = "congelar", [2637] = "dormir",
}
-- Qué usar para salir, por clase (K40). Ids de rango 1; solo se nombra lo que sabes.
Av.SALIDAS = {
	DRUID = { raices = { 768, 5487, 783 }, lentitud = { 768, 5487, 783 } },
	HUNTER = { raices = {}, lentitud = {}, miedo = {} },
	ROGUE = {},
	MAGE = { raices = { 1953 }, aturdir = { 1953 } },
	WARRIOR = { miedo = { 18499 }, raices = {} },
	PRIEST = { miedo = { 6346 } },
	SHAMAN = { miedo = { 8143 } },
	PALADIN = { aturdir = { 642 }, miedo = { 642 }, raices = { 1044 }, lentitud = { 1044 } },
	WARLOCK = {},
}
Av.RAZA = { Scourge = { miedo = 7744, dormir = 7744, seducir = 7744 } } -- Voluntad de los Renegados
Av.BUFO = { DRUID = 1126, PRIEST = 1243, MAGE = 1459, WARRIOR = 6673, HUNTER = 13165, PALADIN = 19740, WARLOCK = 687, SHAMAN = 324 }
Av.MANA = { DRUID = 29166, MAGE = 12051 }

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
local function mostrar(texto, rojo)
	if not M.DB().avisos then return end
	if not cartel then
		cartel = CreateFrame("Frame", "MambaAviso", UIParent)
		cartel:SetSize(420, 30)
		cartel:SetPoint("TOP", UIParent, "TOP", 0, -180)
		M.Movible(cartel, "MambaAviso")
		cartel.texto = M.Piezas.Texto(cartel, "heading", "text")
		cartel.texto:SetAllPoints(cartel)
	end
	cartel.texto:SetText(M.Piezas.Color(rojo and "dudoso" or "titulo", texto))
	cartel.hasta = (GetTime and GetTime() or 0) + 3
	cartel:Show()
	if M.DB().sonido and PlaySound then pcall(PlaySound, 8959) end
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
	mostrar(txt .. (#nombres > 0 and (": usa " .. table.concat(nombres, " o ")) or ""), true)
end

function Av.Lanzado(unidad, id)
	if M.Secreto(id) or not Av.CONTROLES[id] then return end
	if not (UnitCanAttack and UnitCanAttack("player", unidad)) then return end
	local quien = UnitName(unidad)
	if M.Secreto(quien) then quien = "Un enemigo" end
	mostrar(("%s usó %s"):format(quien or "Un enemigo", M.NombreHechizo(id)), true)
end

local ultimoMana, ultimoAmenaza = 0, 0
function Av.Revisar()
	local d = M.DB()
	local t = GetTime and GetTime() or 0
	if cartel and cartel.hasta and t > cartel.hasta then cartel:Hide() end
	if not M.EnCombate() then return end
	local pct = M.Pct(UnitPower("player", 0), UnitPowerMax("player", 0))
	if pct and pct < (d.avisoMana or 25) and t - ultimoMana > 20 and (UnitPowerMax("player", 0) or 0) > 0 then
		ultimoMana = t
		local id = Av.MANA[M.Clase()]
		mostrar(("Maná bajo (%d %%)"):format(pct) .. ((id and M.Conoce(id)) and (": usa " .. M.NombreHechizo(id)) or ": bebe al terminar"))
	end
	local peligro, ap
	if M.Amenaza then peligro, ap = M.Amenaza.Peligro() end
	if peligro and t - ultimoAmenaza > 6 then
		ultimoAmenaza = t
		mostrar(("Amenaza %d %%: vas a quitarle el objetivo al tanque"):format(ap), true)
	end
end

-- Antes de pelear: ¿te falta tu bufo de clase? (devuelve el id o nil)
function Av.BufoQueFalta()
	local id = Av.BUFO[M.Clase()]
	if not (id and M.Conoce(id)) then return nil end
	local R = M.Rotacion
	local a = R and R.Condicion({ "sinBuff", id })
	if a == true then return id end
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
