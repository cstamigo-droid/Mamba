-- Tasador: alerta de enemigos cerca (jugadores de la facción contraria).
-- Detecta por placas de nombre (activa las de enemigos con la tecla V), ratón encima y objetivo.
-- Solo AVISA: no apunta ni ataca por ti. Se apaga dentro de mazmorras, bandas y campos de batalla.
-- Licencia: GPL-3.0.
local _, T = ...

local vistos = {}          -- nombre -> momento del último aviso
local ESPERA = 60          -- no repetir el aviso del mismo jugador antes de 60 s
local ESPERA_SONIDO = 10   -- límite GLOBAL: como mucho un sonido cada 10 s (un grupo grande no hace ruido sin parar)
local ultimoSonido = nil
local ESPERA_PANTALLA = 3  -- límite GLOBAL de avisos grandes en pantalla: uno cada 3 s (el resto va al chat)
local ultimoAviso = nil
local cuentaVistos, TOPE_VISTOS = 0, 500

-- API para la ventana «Enemigos cerca» de Mamba_Combate (K105): ella NO detecta, escucha a esta alerta.
--   MambaAPI.AlVerEnemigo(fn)       fn({ nombre, nivel, clase, claseToken, gremio, momento }) con CADA vista
--                                   (antes del freno de 60 s, para saber la última vez que se vio a cada uno)
--   MambaAPI.SilenciarCercanos(si)  sin cartel en pantalla, sin sonido y sin chat; la lista se sigue llenando
--   MambaAPI.CercanosSilenciados()  -> true | false
local oyentes = {}
local API = {}
function API.AlVerEnemigo(fn) if type(fn) == "function" then oyentes[#oyentes + 1] = fn end end
function API.SilenciarCercanos(si)
	if not T.db then return end
	T.db.ajustes = T.db.ajustes or {}
	T.db.ajustes.alertaSilencio = si and true or nil
end
function API.CercanosSilenciados() return T.db and T.db.ajustes and T.db.ajustes.alertaSilencio == true or false end
-- MambaAPI la crea Asistente/Grupos.lua (OptionalDeps: carga antes): aquí solo se le cuelgan las funciones,
-- ahora y otra vez al entrar al juego. Sin Asistente no hay API (la alerta sigue igual).
local function colgarAPI()
	local api = _G.MambaAPI
	if type(api) ~= "table" then return end
	for k, fn in pairs(API) do api[k] = fn end
end
colgarAPI()

local function Activa()
	if T.db and T.db.ajustes and T.db.ajustes.alerta == false then return false end
	local dentro = IsInInstance and T.Leer(IsInInstance())
	return not dentro
end

local function Numero(x)
	x = T.Leer(x)
	return type(x) == "number" and x or nil
end

-- Llama a una función del juego protegida y sin valores secretos.
local function Limpiar(ok, ...)
	if not ok then return nil end
	local n = select("#", ...)
	local r = { ... }
	for i = 1, n do r[i] = T.Leer(r[i]) end
	return unpack(r, 1, n)
end

local function Pedir(fn, ...)
	if not fn then return nil end
	return Limpiar(pcall(fn, ...))
end

local function Revisar(unidad)
	if not unidad or not Activa() then return end
	if not Pedir(UnitIsPlayer, unidad) then return end
	-- Enemigo = jugador de la otra facción AL QUE PUEDES ATACAR (si no, no es peligro para ti).
	if UnitCanAttack and not Pedir(UnitCanAttack, "player", unidad) then return end
	local suya = Pedir(UnitFactionGroup, unidad)
	local mia = Pedir(UnitFactionGroup, "player")
	if type(suya) ~= "string" or type(mia) ~= "string" then return end
	if suya == mia or (suya ~= "Alliance" and suya ~= "Horde") then return end
	local nombre = Pedir(UnitName, unidad)
	if type(nombre) ~= "string" or nombre == "" then return end
	local ahora = Numero(GetTime and GetTime()) or 0
	if #oyentes > 0 then
		local claseL, claseT = Pedir(UnitClass, unidad)
		local gremio = GetGuildInfo and Pedir(GetGuildInfo, unidad)
		local info = { nombre = nombre, nivel = Numero(Pedir(UnitLevel, unidad)), clase = type(claseL) == "string" and claseL or nil,
			claseToken = type(claseT) == "string" and claseT or nil, gremio = type(gremio) == "string" and gremio or nil, momento = ahora }
		for _, fn in ipairs(oyentes) do pcall(fn, info) end
	end
	if API.CercanosSilenciados() then return end
	if vistos[nombre] and ahora - vistos[nombre] < ESPERA then return end
	if not vistos[nombre] then
		cuentaVistos = cuentaVistos + 1
		if cuentaVistos > TOPE_VISTOS then vistos, cuentaVistos = {}, 1 end
	end
	vistos[nombre] = ahora

	local nivel = Numero(Pedir(UnitLevel, unidad))
	local claseLocal, claseToken = Pedir(UnitClass, unidad)
	local color = "ffffff"
	if RAID_CLASS_COLORS and type(claseToken) == "string" and RAID_CLASS_COLORS[claseToken] then
		color = RAID_CLASS_COLORS[claseToken].colorStr and RAID_CLASS_COLORS[claseToken].colorStr:sub(3) or color
	end
	local miNivel = Numero(UnitLevel("player")) or 0
	local nivelTxt = (nivel and nivel > 0) and tostring(nivel) or "??"
	local peligro = ""
	if not nivel or nivel <= 0 or nivel >= miNivel + 3 then peligro = "  |cffff3333¡PELIGRO: más fuerte que tú!|r" end
	local texto = string.format("|cffff4040¡ENEMIGO CERCA!|r %s · nivel %s · |cff%s%s|r%s",
		nombre, nivelTxt, color, type(claseLocal) == "string" and claseLocal or "?", peligro)

	if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and (not ultimoAviso or ahora - ultimoAviso >= ESPERA_PANTALLA) then
		ultimoAviso = ahora
		pcall(RaidNotice_AddMessage, RaidWarningFrame, texto, ChatTypeInfo["RAID_WARNING"])
	end
	if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING and (not ultimoSonido or ahora - ultimoSonido >= ESPERA_SONIDO) then
		ultimoSonido = ahora
		pcall(PlaySound, SOUNDKIT.RAID_WARNING, "Master")
	end
	T.Decir(texto)
end

local f = CreateFrame("Frame")
f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
f:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, evento, unidad)
	if evento == "PLAYER_LOGIN" then colgarAPI(); return end
	if evento == "UPDATE_MOUSEOVER_UNIT" then unidad = "mouseover"
	elseif evento == "PLAYER_TARGET_CHANGED" then unidad = "target" end
	local ok, err = pcall(Revisar, unidad)
	if not ok and T.db and T.db.depurar then T.Decir("error en la alerta: " .. tostring(err)) end
end)
