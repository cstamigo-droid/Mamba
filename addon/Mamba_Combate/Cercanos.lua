-- Mamba_Combate: enemigos cercanos (K105, K96), como Spy: una ventana con los jugadores de la otra facción
-- que se vieron hace poco (nombre en el color de su clase, nivel, clase y gremio si el juego lo da), la
-- alerta que se silencia con un botón, y la lista de a quién mataste y quién te mató.
-- NO detecta nada por su cuenta: la detección es la alerta del Tasador (Tasador/Alerta.lua), que avisa con
-- MambaAPI.AlVerEnemigo. Sin el Tasador encendido la ventana lo dice.
-- Muertes, sin registro de combate (Forever no lo da):
--   * mataste / tu grupo mató: el evento PARTY_KILL (quién mató, a quién), el mismo que usa Spy en Forever;
--     el golpe tuyo o de tu mascota es «mataste», el de alguien de tu grupo es «tu grupo». De respaldo, el
--     mensaje de honor del juego (COMBATLOG_HONORGAIN y _NO_RANK), que no dice quién mató: cuenta como «tu grupo».
--   * te mató: al morir, el último registro de muerte del juego (C_DeathRecap). Se descarta si es el mismo
--     que ya se leyó, si su golpe es de hace más de un minuto o si esconde al atacante; y solo cuenta si quien
--     dio el golpe es un enemigo de la lista (una caída o un bicho no entran).
-- Las víctimas y asesinos se reconocen por nombre en la lista de vistos: los que nunca se vieron no entran.
-- Nada corre por cuadro: eventos, y un reloj de 5 s solo mientras la ventana está abierta.
-- Código propio (Spy es de otro autor). Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas
local Cz = {}
M.Cercanos = Cz

local RECIENTE = 120      -- «cerca ahora»: vistos en los últimos 2 minutos
local TOPE_VISTOS = 200
local TOPE_MUERTES = 50
-- ancho: «Cerca ahora» y «Muertes» a la izquierda y «Activar alerta» a la derecha sin pisarse con Polestar
local FILAS, ALTO_FILA, ANCHO = 12, 30, 440

Cz.vistos = {}            -- nombre -> { nombre, nivel, clase, claseToken, gremio, visto }

local function ahora() return (GetTime and M.Num(GetTime())) or 0 end
local function reloj() return (time and M.Num(time())) or 0 end
local function texto(x) return (type(x) == "string" and not M.Secreto(x) and x ~= "") and x or nil end

local function db()
	local d = M.DB()
	d.muertesJcJ = d.muertesJcJ or {}
	return d
end

local function api() return _G.MambaAPI end
function Cz.HayDeteccion()
	if Cz.Enganchar then Cz.Enganchar() end
	local a = api()
	return a ~= nil and a.AlVerEnemigo ~= nil
end

---------------------------------------------------------------- lista de vistos
function Cz.Visto(info)
	if type(info) ~= "table" then return end
	local nombre = texto(info.nombre)
	if not nombre then return end -- nombre secreto (instancias): no se puede guardar
	local x = Cz.vistos[nombre]
	local nuevo = not x or (ahora() - x.visto > RECIENTE) -- recién llegado (o volvió tras irse)
	if not x then
		local n = 0
		for _ in pairs(Cz.vistos) do n = n + 1 end
		if n >= TOPE_VISTOS then
			-- se olvida al más viejo
			local viejo, cuando
			for k, y in pairs(Cz.vistos) do if not cuando or y.visto < cuando then viejo, cuando = k, y.visto end end
			if viejo then Cz.vistos[viejo] = nil end
		end
		x = { nombre = nombre }
		Cz.vistos[nombre] = x
	end
	local nivel = M.Num(info.nivel)
	if nivel and nivel > 0 then x.nivel = nivel end
	x.clase = texto(info.clase) or x.clase
	x.claseToken = texto(info.claseToken) or x.claseToken
	x.gremio = texto(info.gremio) or x.gremio
	x.visto = ahora()
	Cz.Pedir(nuevo)
end

-- Vistos en los últimos 2 minutos, el más reciente primero.
function Cz.Recientes()
	local t, out = ahora(), {}
	for _, x in pairs(Cz.vistos) do if t - x.visto <= RECIENTE then out[#out + 1] = x end end
	table.sort(out, function(a, b) return a.visto > b.visto end)
	return out
end

---------------------------------------------------------------- muertes
-- tipo: "mataste" (tu golpe o el de tu mascota) | "grupo" (alguien de tu grupo) | "temato".
-- Una misma muerte llega por dos señales (PARTY_KILL y el mensaje de honor): dentro de 10 s cuenta una vez,
-- y si llega «mataste» después de «grupo», la anotación sube a «mataste».
local ultima = {}
function Cz.Muerte(tipo, nombre)
	nombre = texto(nombre)
	if not nombre or (tipo ~= "mataste" and tipo ~= "grupo" and tipo ~= "temato") then return false end
	local clave, t = (tipo == "temato" and "temato:" or "kill:") .. nombre, ahora()
	local lista = db().muertesJcJ
	if ultima[clave] and t - ultima[clave] < 10 then
		local m = ultima[clave .. "#"]
		if tipo == "mataste" and m and m.tipo == "grupo" then m.tipo = "mataste"; Cz.Pedir(false); return true end
		return false
	end
	local x = Cz.vistos[nombre] or {}
	local m = { tipo = tipo, nombre = nombre, claseToken = x.claseToken, clase = x.clase, nivel = x.nivel, cuando = reloj() }
	ultima.n = (ultima.n or 0) + 1
	if ultima.n > 200 then ultima = { n = 1 } end -- solo hacen falta las de los últimos 10 s
	ultima[clave], ultima[clave .. "#"] = t, m
	table.insert(lista, 1, m)
	while #lista > TOPE_MUERTES do table.remove(lista) end
	Cz.Pedir(false)
	return true
end

function Cz.Cuenta()
	local mataste, grupo, temato = 0, 0, 0
	for _, m in ipairs(db().muertesJcJ) do
		if m.tipo == "mataste" then mataste = mataste + 1 elseif m.tipo == "grupo" then grupo = grupo + 1 else temato = temato + 1 end
	end
	return mataste, grupo, temato
end

local function leer(v) if v == nil or M.Secreto(v) then return nil end return v end

-- ¿Este GUID es tuyo (o de tu mascota)? ¿De alguien de tu grupo (o su mascota)?
local function guidDe(u) local ok, g = pcall(UnitGUID, u); return ok and leer(g) or nil end
function Cz.DeQuien(guid)
	if type(guid) ~= "string" or not UnitGUID then return nil end
	if guid == guidDe("player") or guid == guidDe("pet") then return "mataste" end
	local n = (GetNumGroupMembers and M.Num(GetNumGroupMembers())) or 0
	local raid = IsInRaid and IsInRaid()
	for i = 1, math.min(n, 40) do
		local u = raid and ("raid" .. i) or ("party" .. i)
		if guid == guidDe(u) or guid == guidDe(u .. "pet" ) or (raid and guid == guidDe("raidpet" .. i)) then return "grupo" end
	end
	return nil
end

-- PARTY_KILL(quién mató, a quién): solo cuenta si la víctima es un enemigo de la lista.
function Cz.PartyKill(atacante, victima)
	local quien = Cz.DeQuien(leer(atacante))
	victima = leer(victima)
	if not (quien and type(victima) == "string" and GetPlayerInfoByGUID) then return false end
	local ok, _, _, _, _, _, nombre = pcall(GetPlayerInfoByGUID, victima)
	nombre = ok and texto(nombre)
	if nombre and Cz.vistos[nombre] then return Cz.Muerte(quien, nombre) end
	return false
end

-- «X muere, muerte con honor…»: el patrón sale del texto del juego en su idioma; acepta %s, %d y los de
-- posición (%1$s). El nombre es el primer %s (o el %1$s).
local function escapar(s) return (s:gsub("([%%%(%)%.%[%]%*%+%-%?%^%$])", "%%%1")) end
function Cz.Patron(fmt)
	if type(fmt) ~= "string" then return nil end
	local out, i, capturado = { "^" }, 1, false
	while true do
		local a, b, pos, tipo = fmt:find("%%(%d*%$?)([sd])", i)
		if not a then break end
		out[#out + 1] = escapar(fmt:sub(i, a - 1))
		if tipo == "d" then out[#out + 1] = "%d+"
		elseif not capturado and (pos == "" or pos == "1$") then out[#out + 1] = "(.-)"; capturado = true
		else out[#out + 1] = ".-" end
		i = b + 1
	end
	if not capturado then return nil end
	out[#out + 1] = escapar(fmt:sub(i)) .. "$"
	return table.concat(out)
end
function Cz.MensajeHonor(msg)
	if type(msg) ~= "string" or M.Secreto(msg) then return end
	for _, k in ipairs({ "COMBATLOG_HONORGAIN", "COMBATLOG_HONORGAIN_NO_RANK" }) do
		local p = Cz.Patron(_G[k])
		local nombre = p and msg:match(p)
		if nombre and Cz.vistos[nombre] then return Cz.Muerte("grupo", nombre) end
	end
end

-- Al morir: quién dio el último golpe, del registro de muerte MÁS NUEVO del juego (sin repetir uno viejo).
local ultimoRecap
local function idRecap()
	local R = C_DeathRecap
	if not (R and R.GetRecapLink) then return nil end
	local ok, link = pcall(R.GetRecapLink)
	link = ok and leer(link)
	return type(link) == "string" and tonumber(link:match("death:(%d+)")) or nil
end
function Cz.QuienMeMato()
	local R = C_DeathRecap
	if not (R and R.GetRecapEvents) then return nil, "sin registro" end
	local id = idRecap()
	if id and id == ultimoRecap then return nil, "viejo" end
	if id then ultimoRecap = id end
	local ok, ev
	if id then ok, ev = pcall(R.GetRecapEvents, id) else ok, ev = pcall(R.GetRecapEvents) end
	if not (ok and type(ev) == "table" and not M.Secreto(ev) and not (issecrettable and issecrettable(ev)) and type(ev[1]) == "table"
		and not (issecrettable and issecrettable(ev[1]))) then return nil, "ilegible" end
	local e = ev[1]
	local cuando = M.Num(e.timestamp)
	if cuando and cuando > 1000000000 and math.abs(reloj() - cuando) > 60 then return nil, "viejo" end
	if not id then
		-- sin número de registro: el mismo golpe que la vez anterior es un registro viejo
		local marca = tostring(cuando) .. ":" .. tostring(texto(e.sourceName))
		if marca == ultimoRecap then return nil, "viejo" end
		ultimoRecap = marca
	end
	if leer(e.hideCaster) then return nil, "escondido" end
	return texto(e.sourceName)
end
function Cz.AlMorir()
	local quien, porque = Cz.QuienMeMato()
	M.Contar(quien and "recapLeido" or ("recap:" .. tostring(porque)))
	if quien and Cz.vistos[quien] then return Cz.Muerte("temato", quien) end
end

---------------------------------------------------------------- alerta (silenciar)
function Cz.Silenciada()
	local a = api()
	if a and a.CercanosSilenciados then
		local ok, s = pcall(a.CercanosSilenciados)
		return ok and s == true
	end
	return false
end
function Cz.Silenciar(si)
	local a = api()
	if a and a.SilenciarCercanos then pcall(a.SilenciarCercanos, si and true or false) end
	M.Proteger("cercanos", Cz.Dibujar)
end

---------------------------------------------------------------- ventana
local v

local function hace(seg)
	seg = math.max(0, math.floor(seg + 0.5))
	if seg < 60 then return ("hace %d s"):format(seg) end
	return ("hace %d min"):format(math.floor(seg / 60))
end
local function cuandoFue(t)
	local d = reloj() - (t or 0)
	if d < 3600 then return hace(d) end
	if d < 86400 then return ("hace %d h"):format(math.floor(d / 3600)) end
	return ("hace %d días"):format(math.floor(d / 86400))
end

-- Nombre en el color de su clase (dato del juego, igual en todas las apariencias).
local function nombreColor(nombre, token)
	local c = token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
	local hex = c and c.colorStr
	if type(hex) == "string" and #hex == 8 then return "|c" .. hex .. nombre .. "|r" end
	return nombre
end
Cz.NombreColor = nombreColor

local function crearFila(i)
	local f = P.Fila(v.lista, ANCHO - 2 * v.margen, ALTO_FILA)
	f:SetPoint("TOPLEFT", v.lista, "TOPLEFT", 0, -(i - 1) * ALTO_FILA)
	f.arriba = P.Texto(f, "body", "text")
	f.arriba:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -2)
	f.arriba:SetPoint("RIGHT", f, "RIGHT", -70, 0)
	f.abajo = P.Texto(f, "small", "textDim")
	f.abajo:SetPoint("TOPLEFT", f.arriba, "BOTTOMLEFT", 0, -1)
	f.abajo:SetPoint("RIGHT", f, "RIGHT", -4, 0)
	-- en «Historial»: clic = lista «Matar», clic derecho = nota (Historial.lua)
	f:EnableMouse(true)
	f:SetScript("OnMouseUp", function(s, boton)
		local H = M.Historial
		if Cz.vista ~= "historial" or not s.nombre or not H then return end
		if boton == "RightButton" then H.Nota(s.nombre) else H.Matar(s.nombre) end
		M.Proteger("cercanos", Cz.Dibujar)
	end)
	f.cuando = P.Texto(f, "small", "textMuted")
	f.cuando:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -3)
	if f.cuando.SetJustifyH then f.cuando:SetJustifyH("RIGHT") end
	return f
end

Cz.vista = "cerca" -- "cerca" | "muertes" | "historial"

local function crear()
	v = P.Ventana("MambaCercanos", "Enemigos cerca", ANCHO, 400)
	v.margen = v.margen or 16
	local arriba = -(v.cuerpo or 26) - 4
	-- alto según la cabecera real (56 con Polestar, 26 sin): botones + estado + lista + margen
	v:SetHeight((v.cuerpo or 26) + 4 + 52 + FILAS * ALTO_FILA + 12)
	v.bCerca = P.Boton(v, "Cerca ahora", function() Cz.vista = "cerca"; M.Proteger("cercanos", Cz.Dibujar) end)
	v.bCerca:SetPoint("TOPLEFT", v, "TOPLEFT", v.margen, arriba)
	v.bMuertes = P.Boton(v, "Muertes", function() Cz.vista = "muertes"; M.Proteger("cercanos", Cz.Dibujar) end)
	v.bMuertes:SetPoint("LEFT", v.bCerca, "RIGHT", 4, 0)
	v.bHistorial = P.Boton(v, "Historial", function() Cz.vista = "historial"; M.Proteger("cercanos", Cz.Dibujar) end)
	v.bHistorial:SetPoint("LEFT", v.bMuertes, "RIGHT", 4, 0)
	v.bSilencio = P.Boton(v, "Silenciar", function() Cz.Silenciar(not Cz.Silenciada()) end)
	v.bSilencio:SetPoint("TOPRIGHT", v, "TOPRIGHT", -v.margen, arriba)
	v.estado = P.Texto(v, "note", "textDim")
	v.estado:SetPoint("TOPLEFT", v, "TOPLEFT", v.margen, arriba - 32)
	v.estado:SetPoint("RIGHT", v, "RIGHT", -v.margen, 0)
	v.lista = CreateFrame("Frame", nil, v)
	v.lista:SetPoint("TOPLEFT", v, "TOPLEFT", v.margen, arriba - 52)
	v.lista:SetSize(ANCHO - 2 * v.margen, FILAS * ALTO_FILA)
	v.filas = {}
	for i = 1, FILAS do v.filas[i] = crearFila(i) end
	-- la rueda recorre la lista (el historial guarda hasta 300; revisión wow-addon-lua, 19-11)
	if v.lista.EnableMouseWheel then v.lista:EnableMouseWheel(true) end
	v.lista:SetScript("OnMouseWheel", function(_, delta)
		Cz.desde = math.max(0, math.min((Cz.total or 0) - FILAS, (Cz.desde or 0) - delta * 3))
		M.Proteger("cercanos", Cz.Dibujar)
	end)
	v.vacio = P.Texto(v.lista, "body", "textMuted")
	v.vacio:SetPoint("TOPLEFT", v.lista, "TOPLEFT", 4, -6)
	v.vacio:SetPoint("RIGHT", v.lista, "RIGHT", -4, 0)
	-- reloj de 5 s solo con la ventana abierta («hace 12 s» y quién deja de estar cerca)
	v:HookScript("OnShow", function() Cz.Reloj(true); M.Proteger("cercanos", Cz.Dibujar) end)
	-- la cerró el jugador (cruz, Escape o el botón): no se vuelve a abrir sola por un minuto
	v:HookScript("OnHide", function() Cz.Reloj(false); Cz.cerradaEn = ahora() end)
	if _G.Asistente and _G.Asistente.AlCambiarApariencia then
		_G.Asistente.AlCambiarApariencia(function() if v:IsShown() then M.Proteger("cercanos", Cz.Dibujar) end end)
	end
end

function Cz.Reloj(prender)
	if prender and not v.tic and C_Timer and C_Timer.NewTicker then
		v.tic = C_Timer.NewTicker(5, function() M.Proteger("cercanos", Cz.Dibujar) end)
	elseif not prender and v.tic then
		v.tic:Cancel(); v.tic = nil
	end
end

local function color(nombre, t) return P.Color(nombre, t) end

function Cz.Dibujar()
	if not v or not v:IsShown() then return end
	v.bSilencio:SetText(Cz.Silenciada() and "Activar alerta" or "Silenciar")
	local filas = {}
	if not Cz.HayDeteccion() then
		v.estado:SetText("")
		v.vacio:SetText("Para ver enemigos cerca hacen falta Mamba (Asistente) y el Tasador encendidos: el Tasador los detecta. Actívalos en la lista de addons.")
	elseif Cz.vista == "cerca" then
		local lista = Cz.Recientes()
		v.estado:SetText(Cz.Silenciada() and color("dudoso", "Alerta silenciada: la lista se sigue llenando.")
			or "Jugadores de la otra facción vistos en los últimos 2 minutos.")
		local t = ahora()
		for _, x in ipairs(lista) do
			local partes = { x.nivel and ("nivel " .. x.nivel) or "nivel ??", x.clase or "clase desconocida" }
			if x.gremio then partes[#partes + 1] = "<" .. x.gremio .. ">" end
			filas[#filas + 1] = { arriba = nombreColor(x.nombre, x.claseToken), abajo = table.concat(partes, " · "), cuando = hace(t - x.visto) }
		end
		v.vacio:SetText(#lista == 0 and "Nadie a la vista. Con las placas de nombre de enemigos encendidas (tecla V) se detectan antes." or "")
	elseif Cz.vista == "historial" and M.Historial then
		local H = M.Historial
		filas = H.Filas(nombreColor, cuandoFue)
		v.estado:SetText(("%d enemigos anotados. Clic: lista «Matar» (aviso fuerte al verlo). Clic derecho: nota."):format(#filas))
		v.vacio:SetText(#filas == 0 and "Todavía no viste a nadie de la otra facción." or "")
	else
		local lista = db().muertesJcJ
		local a, g, b = Cz.Cuenta()
		v.estado:SetText(("Mataste: %d   ·   Tu grupo: %d   ·   Te mataron: %d"):format(a, g, b))
		for _, m in ipairs(lista) do
			local quien = nombreColor(m.nombre, m.claseToken)
			local arriba
			if m.tipo == "mataste" then arriba = color("bueno", "Mataste a ") .. quien
			elseif m.tipo == "grupo" then arriba = color("bueno", "Tu grupo mató a ") .. quien
			else arriba = quien .. color("dudoso", " te mató") end
			filas[#filas + 1] = {
				arriba = arriba,
				abajo = (m.nivel and ("nivel " .. m.nivel) or "nivel ??") .. " · " .. (m.clase or "clase desconocida"),
				cuando = cuandoFue(m.cuando) }
		end
		v.vacio:SetText(#lista == 0 and "Todavía no hay muertes contra jugadores anotadas." or "")
	end
	if Cz.vistaAntes ~= Cz.vista then Cz.desde, Cz.vistaAntes = 0, Cz.vista end
	Cz.total = #filas
	Cz.desde = math.max(0, math.min(Cz.desde or 0, #filas - FILAS))
	for i = 1, FILAS do
		local x, f = filas[i + Cz.desde], v.filas[i]
		if x then
			f.arriba:SetText(x.arriba); f.abajo:SetText(x.abajo); f.cuando:SetText(x.cuando); f.nombre = x.nombre; f:Show()
		else f.nombre = nil; f:Hide() end
	end
end

-- Freno: una ola de enemigos (un grupo grande) dibuja una sola vez por medio segundo.
-- sola = llegó un enemigo NUEVO: abre la ventana si está permitido, no silenciada y no la cerró el jugador
-- hace menos de un minuto.
local pendiente = false
function Cz.Pedir(sola)
	local d = M.DB()
	local reciencerrada = Cz.cerradaEn and ahora() - Cz.cerradaEn < 60
	-- en plena pelea no se abre sola: taparía la vista (revisión wow-addon-lua, tanda 4)
	if sola and d.cercanosSola and not M.EnCombate() and not Cz.Silenciada() and not reciencerrada and (not v or not v:IsShown()) and Cz.vista == "cerca" then
		Cz.Abrir(true)
		return
	end
	if not v or not v:IsShown() then return end
	if not (C_Timer and C_Timer.After) then M.Proteger("cercanos", Cz.Dibujar); return end
	if pendiente then return end
	pendiente = true
	C_Timer.After(0.5, function() pendiente = false; M.Proteger("cercanos", Cz.Dibujar) end)
end

function Cz.Abrir(sola)
	if not v then crear() end
	v.ejemplo = nil
	v.abiertaSola = sola and true or nil
	v:Show()
	Cz.Reloj(true)
	M.Proteger("cercanos", Cz.Dibujar)
end
function Cz.Cerrar() if v then v:Hide(); Cz.Reloj(false); Cz.cerradaEn = ahora() end end
function Cz.Ventana() return v end
M.Precrear(function() if not v then crear() end end)
M.AlModoMover(function(activo)
	if not v then crear() end
	if activo then
		if not v:IsShown() then v.ejemplo = true; v.cerradaAntes = Cz.cerradaEn; v:Show() end
	elseif v.ejemplo then
		v.ejemplo = nil
		v:Hide()
		Cz.cerradaEn = v.cerradaAntes -- salir del modo no cuenta como cerrarla el jugador
	end
end)

---------------------------------------------------------------- eventos
local enganchado = false
local function enganchar()
	if enganchado then return end
	local a = api()
	if a and a.AlVerEnemigo then
		enganchado = true
		pcall(a.AlVerEnemigo, function(info) M.Proteger("cercanos:visto", Cz.Visto, info) end)
	end
end

local f = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_DEAD", "CHAT_MSG_COMBAT_HONOR_GAIN", "PARTY_KILL" }) do M.Escuchar(f, ev) end
f:SetScript("OnEvent", function(_, ev, a1, a2)
	if ev == "PLAYER_LOGIN" or ev == "PLAYER_ENTERING_WORLD" then
		enganchar()
	elseif ev == "PLAYER_DEAD" then
		M.Contar("muerteJugador")
		-- el registro de muerte tarda un poco en llenarse: se mira a los 0,5 s y a los 2 s (el mismo registro
		-- no se anota dos veces: QuienMeMato recuerda el último leído)
		if C_Timer and C_Timer.After then
			C_Timer.After(0.5, function() M.Proteger("cercanos:muerte", Cz.AlMorir) end)
			C_Timer.After(2, function() M.Proteger("cercanos:muerte", Cz.AlMorir) end)
		else M.Proteger("cercanos:muerte", Cz.AlMorir) end
	elseif ev == "CHAT_MSG_COMBAT_HONOR_GAIN" then
		-- diag: ¿llega?, ¿secreto?, y el formato del juego en su idioma (para el patrón, NO VERIFICADO en esMX)
		if M.Secreto(a1) then M.Contar("honorSecreto") else
			M.Contar("honor", type(a1) == "string" and a1:sub(1, 120) or nil)
			M.Contar("honorFormato", type(_G.COMBATLOG_HONORGAIN) == "string" and _G.COMBATLOG_HONORGAIN or "sin COMBATLOG_HONORGAIN")
		end
		local r = M.Proteger("cercanos:honor", Cz.MensajeHonor, a1)
		if r then M.Contar("honorAnotado") end
	elseif ev == "PARTY_KILL" then
		M.Contar((M.Secreto(a1) or M.Secreto(a2)) and "partyKillSecreto" or "partyKill")
		local r = M.Proteger("cercanos:muerte", Cz.PartyKill, a1, a2)
		if r then M.Contar("partyKillAnotado") end
	end
end)
-- por si el Tasador cargó después de PLAYER_LOGIN de este addon
Cz.Enganchar = enganchar
