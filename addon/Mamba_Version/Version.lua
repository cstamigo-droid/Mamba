-- Mamba_Version: "Hay una versión nueva de Mamba" (19-11-2026).
-- Cristian: "tenemos que lograr que el cambio que le hagamos se haga en los demás usuarios que lo ocupan".
-- Cada jugador con Mamba manda su sello (MambaSello.build, de Sello.lua) a su grupo o banda con el prefijo
-- propio "MAMBAver"; quien recibe un sello más nuevo que el suyo ve UNA vez por sesión el aviso de cerrar el
-- juego y actualizar. Los que usan el Polestar oficial no registran este prefijo: no reciben nada.
-- Fuera de lo que permite el juego no se insiste: en mazmorra o banda el chat de addons puede estar
-- bloqueado (InChatMessagingLockdown); ahí no se manda y se reintenta al cambiar de grupo o de zona.
local PREFIJO = "MAMBAver"
local ESPERA_ENVIO = 30      -- segundos mínimos entre dos envíos al grupo
local ESPERA_RESPUESTA = 60  -- a un mismo jugador se le responde como mucho una vez por minuto

local M = {}
MambaVersion = M
local sello = MambaSello or { build = 0, texto = "sin sellar" }
local ultimoEnvio, respondido, avisado = -1e9, {}, false

local function ahora() return GetTime and GetTime() or 0 end

local function canal()
	if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
	if IsInRaid and IsInRaid() then return "RAID" end
	if IsInGroup and IsInGroup() then return "PARTY" end
	return nil
end

local function bloqueado()
	return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() and true or false
end

-- Mensaje: "V1|<build>|<texto>". El texto es solo para mostrar.
-- %.0f y no %d: el build (AAAAMMDDHHMM) no cabe en 32 bits, y en Windows %d de Lua 5.1 lo corta.
function M.Codificar(build, texto) return ("V1|%.0f|%s"):format(build or 0, (texto or ""):sub(1, 60)) end
function M.Decodificar(msg)
	local v, b, t = tostring(msg or ""):match("^(V1)|(%d+)|(.*)$")
	if not v then return nil end
	return tonumber(b), t
end

function M.Enviar(destino)
	if (sello.build or 0) <= 0 then return false end -- copia de desarrollo: escucha, no anuncia
	local c = destino and "WHISPER" or canal()
	if not c or bloqueado() then return false end
	local ok = pcall(C_ChatInfo.SendAddonMessage, PREFIJO, M.Codificar(sello.build, sello.texto), c, destino)
	return ok
end

local function anunciar(forzar)
	if not forzar and ahora() - ultimoEnvio < ESPERA_ENVIO then return end
	if M.Enviar() then ultimoEnvio = ahora() end
end

function M.Avisar(build, texto, quien)
	if avisado then return end
	avisado = true
	local linea = ("|cff8c9e6bMamba:|r hay una versión nueva (%s%s). Cierra el juego y haz doble clic en «Actualizar Mamba» en tu escritorio.")
		:format(texto ~= "" and texto or tostring(build), quien and (", la tiene " .. quien) or "")
	if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(linea) end
	if UIErrorsFrame then UIErrorsFrame:AddMessage("Hay una versión nueva de Mamba: cierra el juego y actualiza", 0.55, 0.62, 0.42) end
end

function M.Recibir(msg, quien)
	local build, texto = M.Decodificar(msg)
	if not build then return end
	local mio = sello.build or 0
	MambaVersionDB = MambaVersionDB or {}
	if build > mio then
		if build > (MambaVersionDB.masNueva or 0) then
			MambaVersionDB.masNueva, MambaVersionDB.texto, MambaVersionDB.quien = build, texto, quien
		end
		M.Avisar(build, texto, quien)
	elseif build < mio and quien and mio > 0 then
		-- El otro está atrasado: se le responde (por susurro de addon) para que vea el aviso.
		if ahora() - (respondido[quien] or -1e9) >= ESPERA_RESPUESTA then
			respondido[quien] = ahora()
			M.Enviar(quien)
		end
	end
end

function M.Sello() return sello end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, ev, a1, a2, a3, a4)
	if ev == "PLAYER_LOGIN" then
		if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(PREFIJO) end
		MambaVersionDB = MambaVersionDB or {}
		-- Recordatorio entre sesiones: si la última vez se vio una versión más nueva y sigues con la vieja.
		if (MambaVersionDB.masNueva or 0) > (sello.build or 0) and (sello.build or 0) > 0 then
			M.Avisar(MambaVersionDB.masNueva, MambaVersionDB.texto or "", MambaVersionDB.quien)
		end
	elseif ev == "CHAT_MSG_ADDON" then
		if a1 == PREFIJO then
			local quien = a4
			if quien and Ambiguate then quien = Ambiguate(quien, "none") end
			if UnitName and quien == UnitName("player") then return end
			M.Recibir(a2, quien)
		end
	else
		anunciar(false)
	end
end)
