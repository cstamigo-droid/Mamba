-- Asistente: capa del servidor ("layer"). Reemplaza a MyLayerTracker con una implementación
-- propia del mismo método: leer el formato público del GUID de un PNJ. MyLayerTracker no declara
-- licencia y no se copió su archivo, pero se escribió conociéndolo (revisor externo, 16-11):
-- comparte lo funcional (qué campo del GUID, Creature/Vehicle, la clave servidor:instancia:zona).
-- /layer choca con MyLayerTracker si los dos están activos: es su reemplazo, se apaga el otro.
-- Licencia: GPL-3.0-only. Autor: Cristian Amigo.
--
-- Cómo se sabe la capa: el GUID de un PNJ es
--   "Creature-0-<servidor>-<instancia>-<zona>-<idPNJ>-<aparición>"
-- y el 5.º campo (zona) cambia con la capa. No es el número oficial de la capa
-- (el juego no lo da), es un identificador: sirve para saber si CAMBIASTE de capa.
-- Se mira el objetivo y el PNJ bajo el ratón (MyLayerTracker solo el objetivo).
-- Nunca juega por ti: solo lee y muestra.
local A = _G.Asistente
local Capa = {}
A.Capa = Capa

A.Defaults("capa", { mostrar = true, avisar = true, bloqueado = false, punto = nil })

-- GUID -> zona (texto), clave "servidor:instancia:zona" | nil, motivo
function Capa.Leer(guid)
	if guid == nil then return nil, nil, "sin_pnj" end
	if issecretvalue and issecretvalue(guid) then return nil, nil, "restringido" end
	if type(guid) ~= "string" then return nil, nil, "sin_pnj" end
	local tipo, _, servidor, instancia, zona = strsplit("-", guid)
	if tipo ~= "Creature" and tipo ~= "Vehicle" then return nil, nil, "sin_pnj" end
	if not (servidor and instancia and zona) or zona == "" then return nil, nil, "sin_pnj" end
	return zona, servidor .. ":" .. instancia .. ":" .. zona
end

Capa.actual = nil -- { zona, clave, cuando, mapa }

local function ahora() return GetTime and GetTime() or 0 end

-- Mira una unidad. -> true si la capa cambió respecto de la anterior conocida
function Capa.Observar(unidad)
	if not UnitGUID then return false end
	local ok, guid = pcall(UnitGUID, unidad)
	if not ok then return false end
	local zona, clave = Capa.Leer(guid)
	if not zona then return false end
	local antes = Capa.actual
	local mapa = A.MapaActual and A.MapaActual() or nil
	Capa.actual = { zona = zona, clave = clave, cuando = ahora(), mapa = mapa }
	local cambio = antes ~= nil and antes.clave ~= clave and antes.mapa == mapa
	if cambio and A.Ajuste("capa", "avisar") then
		A.Decir(("cambiaste de capa: %s › %s"):format(antes.zona, zona))
		if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage("Capa " .. zona, 1, 0.82, 0) end
	end
	Capa.Pintar()
	return cambio
end

function Capa.Olvidar()
	Capa.actual = nil
	Capa.Pintar()
end

function Capa.Texto()
	local c = Capa.actual
	if not c then return "Capa: ? (apunta a un PNJ)" end
	local seg = math.floor(ahora() - (c.cuando or 0))
	local hace = seg < 60 and (seg .. " s") or (math.floor(seg / 60) .. " min")
	return ("Capa: %s  (hace %s)"):format(c.zona, hace)
end

---------------------------------------------------------------- cuadro en pantalla
local marco
function Capa.Pintar()
	if not marco then return end
	if A.Ajuste("capa", "mostrar") then
		marco.texto:SetText(Capa.Texto())
		marco:Show()
	else
		marco:Hide()
	end
end

local function crearMarco()
	if marco or not CreateFrame then return end
	marco = CreateFrame("Frame", "AsistenteCapa", UIParent)
	marco:SetSize(160, 18)
	local p = A.Ajuste("capa", "punto")
	if type(p) == "table" and p[1] then
		marco:SetPoint(p[1], UIParent, p[2] or p[1], p[3] or 0, p[4] or 0)
	elseif Minimap then
		marco:SetPoint("BOTTOM", Minimap, "TOP", 0, 6)
	else
		marco:SetPoint("TOP", UIParent, "TOP", 0, -10)
	end
	marco.texto = marco:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	marco.texto:SetAllPoints()
	marco:EnableMouse(true)
	marco:SetMovable(true)
	marco:RegisterForDrag("LeftButton")
	marco:SetScript("OnDragStart", function(f) if not A.Ajuste("capa", "bloqueado") then f:StartMoving() end end)
	marco:SetScript("OnDragStop", function(f)
		f:StopMovingOrSizing()
		local a, _, b, x, y = f:GetPoint(1)
		A.FijarAjuste("capa", "punto", { a, b, x, y })
	end)
	local acum = 0
	marco:SetScript("OnUpdate", function(_, dt)
		acum = acum + dt
		if acum >= 1 then acum = 0; marco.texto:SetText(Capa.Texto()) end
	end)
	Capa.Pintar()
end

---------------------------------------------------------------- eventos
if CreateFrame then
	local ev = CreateFrame("Frame")
	ev:RegisterEvent("PLAYER_LOGIN")
	ev:RegisterEvent("PLAYER_TARGET_CHANGED")
	ev:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	ev:RegisterEvent("PLAYER_ENTERING_WORLD")
	ev:SetScript("OnEvent", function(_, evento)
		if evento == "PLAYER_LOGIN" then
			crearMarco()
		elseif evento == "PLAYER_ENTERING_WORLD" then
			Capa.Olvidar() -- pantalla de carga: puede ser otra capa
		elseif evento == "PLAYER_TARGET_CHANGED" then
			Capa.Observar("target")
		else
			Capa.Observar("mouseover")
		end
	end)
end

-- /capa · /capa mostrar · /capa ocultar · /capa avisos · /capa bloquear · /capa olvidar
function Capa.Comando(arg)
	arg = (arg or ""):lower():match("^%s*(%S*)")
	if arg == "mostrar" or arg == "ocultar" then
		A.FijarAjuste("capa", "mostrar", arg == "mostrar")
		Capa.Pintar()
	elseif arg == "avisos" then
		local v = not A.Ajuste("capa", "avisar")
		A.FijarAjuste("capa", "avisar", v)
		A.Decir("avisos de cambio de capa: " .. (v and "sí" or "no"))
	elseif arg == "bloquear" then
		local v = not A.Ajuste("capa", "bloqueado")
		A.FijarAjuste("capa", "bloqueado", v)
		A.Decir("cuadro de capa " .. (v and "bloqueado" or "movible"))
	elseif arg == "olvidar" then
		Capa.Olvidar()
	else
		A.Decir(Capa.Texto() .. ". Opciones: /capa mostrar | ocultar | avisos | bloquear | olvidar")
	end
end

SLASH_ASISTENTECAPA1 = "/capa"
SLASH_ASISTENTECAPA2 = "/layer"
-- (no reasignar SlashCmdList: reescribir esa global la contamina y el /run del juego quedaba bloqueado,
-- "Asistente intentó SetAllowDangerousScripts()", 18-11)
SlashCmdList.ASISTENTECAPA = Capa.Comando
