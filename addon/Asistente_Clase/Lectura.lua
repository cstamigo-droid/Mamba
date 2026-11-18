-- Asistente_Clase: lee del juego la clase, el nivel y los talentos puestos. Solo LEE: nunca cambia nada.
-- Forever guarda los talentos en un árbol C_Traits por clase. Se lee igual que Polestar
-- (Polestar Talents/Talents.lua, T.Read, y Gear/Gear.lua, Client.TreeColumns; GPL-3.0-only):
-- configuración activa -> información de cada nodo -> rango activo.
-- Aquí se pregunta solo por los nodos que conocemos (ns.BUILDS[clase].talentos), así no hace
-- falta el número del árbol.
-- Licencia: GPL-3.0-only.
local _, ns = ...
local C = ns.Clase

local function llamar(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, a, b = pcall(fn, ...)
	if ok then return a, b end
end

function C.MiClase()
	local _, token = UnitClass("player")
	return token
end

function C.MiNivel()
	return UnitLevel("player") or 1
end

-- -> rangos { [nodo] = rango } | nil, motivo
-- activo = lo aprendido; los puntos que el jugador marcó pero no aplicó no cuentan.
function C.LeerTalentos(clase)
	clase = clase or C.MiClase()
	local d = ns.BUILDS and ns.BUILDS[clase]
	if not d then return nil, "sinclase" end
	local CT, T = C_ClassTalents, C_Traits
	if not (CT and T) then return nil, "sinapi" end
	local config = llamar(CT.GetActiveConfigID)
	if type(config) ~= "number" then return nil, "sinconfig" end
	local rangos, leidos = {}, 0
	for nodo in pairs(d.talentos) do
		local info = llamar(T.GetNodeInfo, config, nodo)
		if type(info) == "table" and info.ID and info.ID ~= 0 then
			leidos = leidos + 1
			local r = info.activeRank or info.currentRank or 0
			if r > 0 then rangos[nodo] = r end
		end
	end
	if leidos == 0 then return nil, "sinnodos" end
	return rangos
end

-- Nombre del talento en el idioma del juego (si el juego lo da) o el inglés de los datos.
function C.NombreTalento(clase, nodo)
	local d = ns.BUILDS and ns.BUILDS[clase]
	local t = d and d.talentos[nodo]
	local T = C_Traits
	local config = C_ClassTalents and llamar(C_ClassTalents.GetActiveConfigID)
	if T and config then
		local info = llamar(T.GetNodeInfo, config, nodo)
		local entrada = type(info) == "table" and ((info.activeEntry and info.activeEntry.entryID) or (info.entryIDs and info.entryIDs[1]))
		local e = entrada and llamar(T.GetEntryInfo, config, entrada)
		local def = type(e) == "table" and e.definitionID and llamar(T.GetDefinitionInfo, e.definitionID)
		if type(def) == "table" then
			if def.overrideName and def.overrideName ~= "" then return def.overrideName end
			local nombre = def.spellID and ((C_Spell and llamar(C_Spell.GetSpellName, def.spellID)) or (GetSpellInfo and llamar(GetSpellInfo, def.spellID)))
			if nombre then return nombre end
		end
	end
	return t and t.nombre or ("nodo " .. tostring(nodo))
end

-- ¿Está abierta la doble especialización? true / false / nil (no se pudo saber).
-- NO VERIFICADO qué función usa Forever: se prueban las de las versiones del juego que la tienen.
function C.TieneDoble()
	if C.MiNivel() < C.NIVEL_DOBLE then return false end
	local n = llamar(GetNumTalentGroups) or llamar(GetNumSpecGroups)
	if type(n) == "number" then return n >= 2 end
	return nil
end
