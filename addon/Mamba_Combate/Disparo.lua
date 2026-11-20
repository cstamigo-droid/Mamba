-- Mamba_Combate: temporizador del Disparo automático y del golpe (K64) y barra de lanzamiento con la latencia y el
-- enfriamiento global (K73), más los números de enfriamiento en los botones (K73, idea de OmniCC: el juego ya los
-- dibuja con su opción "countdownForCooldowns"; LibActionButton de Mamba_Barras la respeta).
-- Disparo: PLAYER_SWING (duración y tipo) y PLAYER_SWING_RANGE_UPDATE (a distancia o no), los eventos de Forever
-- que usa Quartz Forever. El último medio segundo antes del disparo automático hay que estar QUIETO: la barra se
-- pone roja ahí; el resto del tiempo te puedes mover sin cortar el disparo. Código propio (Quartz es GPL v2).
-- Licencia: GPL-3.0-only.
local _, M = ...
local D = {}
M.Disparo = D
D.QUIETO = 0.5 -- segundos finales del disparo automático en los que moverse lo corta

local barras = {}
local function ahora() return GetTime and GetTime() or 0 end

local function nombreTipo(tipo)
	local E = Enum and Enum.PlayerSwingType
	if E then
		if tipo == E.Ranged then return "distancia" elseif tipo == E.OffHand then return "izquierda" end
	end
	return "derecha"
end

local ancla
-- El ancla del disparo y el golpe se ve solo mientras hay una barra (escondida no se come los clics).
function D.CrearAncla()
	if ancla then return end
	ancla = CreateFrame("Frame", "MambaDisparo", UIParent)
	ancla:SetSize(200, 14)
	ancla:SetPoint("CENTER", UIParent, "CENTER", 0, -230)
	ancla:Hide()
	M.Movible(ancla, "MambaDisparo", "Disparo automático y golpe")
end
local function barra(tipo)
	local k = nombreTipo(tipo)
	if barras[k] then return barras[k] end
	if not ancla then D.CrearAncla() end
	local b = M.Barra(ancla, 200, 12)
	local n = 0
	for _ in pairs(barras) do n = n + 1 end
	b:SetPoint("TOP", ancla, "TOP", 0, -n * 14)
	b.tipo = k
	b:Hide()
	barras[k] = b
	return b
end

-- Lo que la barra dice en el momento t: fracción, color y texto (separado para probarlo).
function D.Estado(b, t)
	if not (b and b.inicio and b.dur and b.dur > 0) then return nil end
	local pasado = t - b.inicio
	if pasado >= b.dur then return nil end
	local resta = b.dur - pasado
	local quieto = b.tipo == "distancia" and resta <= D.QUIETO
	local col = quieto and { 0.9, 0.2, 0.2 } or (b.tipo == "distancia" and { 0.3, 0.8, 0.3 } or { 0.8, 0.7, 0.3 })
	if b.fuera then col = { 0.4, 0.4, 0.4 } end
	local txt = b.tipo == "distancia" and (quieto and "QUIETO" or "muévete") or ""
	if b.fuera then txt = "fuera de alcance" end
	return pasado / b.dur, col, txt .. ("  %.1f"):format(resta)
end

function D.Empezar(tipo, dur)
	if M.Secreto(tipo) or not M.DB().disparo then return end
	local d = M.Num(dur)
	local b = barra(tipo)
	if not d or d <= 0 then b:Hide(); return end
	b.inicio, b.dur = ahora(), d
	b:Show()
	ancla:Show()
end

function D.Alcance(tipo, dentro, revisa)
	if M.Secreto(tipo) then return end
	local b = barra(tipo)
	if M.Secreto(dentro) then return end
	b.fuera = revisa and not dentro
end

function D.Tick()
	local t = ahora()
	local alguna = false
	for _, b in pairs(barras) do
		if b:IsShown() then
			local fr, col, txt = D.Estado(b, t)
			if not fr then b:Hide() else
				alguna = true
				b:SetValue(fr)
				b:SetStatusBarColor(col[1], col[2], col[3])
				b.texto:SetText(txt)
			end
		end
	end
	if ancla and not alguna and not ancla.mostrada and ancla:IsShown() then ancla:Hide() end
	D.TickLanzamiento(t)
end

---------------------------------------------------------------- lanzamiento propio y enfriamiento global
local lanz, gcd
function D.Latencia()
	if not GetNetStats then return 0 end
	local _, _, casa, mundo = GetNetStats()
	return ((M.Num(mundo) or M.Num(casa) or 0) / 1000)
end

local function crearLanz()
	lanz = M.Barra(UIParent, 220, 16, "MambaLanzamiento")
	lanz:SetPoint("CENTER", UIParent, "CENTER", 0, -260)
	M.Movible(lanz, "MambaLanzamiento", "Barra de lanzamiento")
	lanz.lat = lanz:CreateTexture(nil, "OVERLAY")
	lanz.lat:SetColorTexture(0.9, 0.2, 0.2, 0.5)
	lanz.lat:SetPoint("TOPRIGHT", lanz, "TOPRIGHT")
	lanz.lat:SetPoint("BOTTOMRIGHT", lanz, "BOTTOMRIGHT")
	lanz:Hide()
	gcd = M.Barra(lanz, 220, 3)
	gcd:SetPoint("TOP", lanz, "BOTTOM", 0, -1)
	gcd:SetStatusBarColor(1, 0.82, 0.2)
	gcd:Hide()
end

M.Precrear(function() D.CrearAncla(); if not lanz then crearLanz() end end)
M.AlModoMover(function(activo)
	D.CrearAncla()
	if not lanz then crearLanz() end
	if not ancla.ejemplo then
		ancla.ejemplo = M.Piezas.Texto(ancla, "small", "text")
		ancla.ejemplo:SetAllPoints(ancla)
	end
	if activo then
		if not ancla:IsShown() then ancla.mostrada = true; ancla.ejemplo:SetText("Disparo automático y golpe (ejemplo)"); ancla:Show() end
		if not lanz:IsShown() then lanz.mostrada = true; lanz.fin = nil; lanz:SetValue(0.6); lanz.texto:SetText("Barra de lanzamiento (ejemplo)"); lanz:Show() end
	else
		ancla.ejemplo:SetText("")
		if ancla.mostrada then ancla.mostrada = nil; ancla:Hide() end
		if lanz.mostrada then lanz.mostrada = nil; lanz.texto:SetText(""); lanz:Hide() end
	end
end)

function D.Lanzando()
	if not M.DB().lanzamiento then return end
	if not lanz then crearLanz() end
	local nombre, ini, fin, _
	if UnitCastingInfo then nombre, _, _, ini, fin = UnitCastingInfo("player") end
	local canal = false
	if not nombre and UnitChannelInfo then nombre, _, _, ini, fin = UnitChannelInfo("player"); canal = nombre ~= nil end
	ini, fin = M.Num(ini), M.Num(fin)
	if not (nombre and ini and fin and fin > ini) then lanz:Hide(); return end
	lanz.ini, lanz.fin, lanz.canal = ini / 1000, fin / 1000, canal
	lanz.texto:SetText(M.Secreto(nombre) and "" or nombre)
	local dur = lanz.fin - lanz.ini
	lanz.lat:SetWidth(math.max(1, math.min(1, D.Latencia() / dur) * 220))
	lanz:SetStatusBarColor(0.35, 0.6, 0.95)
	lanz:Show()
end

function D.TickLanzamiento(t)
	if lanz and lanz.mostrada then return end -- ejemplo del modo «Mover elementos»
	if lanz and lanz:IsShown() and lanz.fin then
		local fr = (t - lanz.ini) / (lanz.fin - lanz.ini)
		if fr >= 1 then lanz:Hide() else lanz:SetValue(lanz.canal and (1 - fr) or fr) end
	end
	D.proxGCD = D.proxGCD or 0
	if gcd and M.DB().lanzamiento and C_Spell and C_Spell.GetSpellCooldown and t >= D.proxGCD then
		D.proxGCD = t + 0.05 -- 20 veces por segundo basta
		local ok, cd = pcall(C_Spell.GetSpellCooldown, 61304)
		local ini, dur = ok and cd and M.Num(cd.startTime), ok and cd and M.Num(cd.duration)
		if ini and dur and ini > 0 and dur > 0 and t < ini + dur then
			gcd:SetValue((t - ini) / dur)
			gcd:Show()
			if not lanz:IsShown() then lanz:Show(); lanz:SetValue(0); lanz.texto:SetText(""); lanz.fin = nil end
		else
			gcd:Hide()
			if lanz:IsShown() and not lanz.fin then lanz:Hide() end
		end
	end
end

---------------------------------------------------------------- números de enfriamiento (opción del juego)
function D.NumerosCD()
	if not SetCVar or M.EnCombate() then return end
	local quiero = M.DB().numerosCD and "1" or "0"
	if GetCVar and GetCVar("countdownForCooldowns") == quiero then return end
	pcall(SetCVar, "countdownForCooldowns", quiero)
end

local f = CreateFrame("Frame")
M.Escuchar(f, "PLAYER_SWING")
M.Escuchar(f, "PLAYER_SWING_RANGE_UPDATE")
M.Escuchar(f, "PLAYER_LOGIN")
for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
	"UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP" }) do
	M.Escuchar(f, e, "player")
end
f:SetScript("OnEvent", function(_, e, a, b, c)
	if e == "PLAYER_SWING" then M.Proteger("disparo", D.Empezar, b, a)
	elseif e == "PLAYER_SWING_RANGE_UPDATE" then M.Proteger("alcance", D.Alcance, a, b, c)
	elseif e == "PLAYER_LOGIN" then M.Proteger("cd", D.NumerosCD)
	else M.Proteger("lanzamiento", D.Lanzando) end
end)
f:SetScript("OnUpdate", function() M.Proteger("disparoTick", D.Tick) end)
M.AlCambiar(function() M.Proteger("cd", D.NumerosCD) end)

-- K124: al apagarlos desde Opciones se esconden en el momento (no al terminar el golpe o el lanzamiento).
function D.Refrescar()
	local d = M.DB()
	if not d.disparo then
		for _, b in pairs(barras) do b:Hide() end
		if ancla and not ancla.ejemplo then ancla:Hide() end
	end
	if not d.lanzamiento then
		if lanz and not lanz.ejemplo then lanz:Hide() end
		if gcd then gcd:Hide() end
	end
end
