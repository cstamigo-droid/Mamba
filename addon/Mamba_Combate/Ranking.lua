-- Mamba_Combate: ranking del grupo (K106, K65), como Details: una barra por jugador del grupo con daño,
-- curación o daño recibido, de esta pelea, del total o de una pelea anterior; clic en una barra = de qué
-- hechizos salió lo de ESE jugador. Todo sale del medidor del juego (C_DamageMeter); Forever no da el
-- registro de combate.
-- Valores secretos: en combate el juego esconde nombres y cifras. Aquí NUNCA se comparan ni se suman: se
-- pasan tal cual a la barra (SetMinMaxValues/SetValue) y al texto (format, AbbreviateNumbers), como hace
-- Details Forever (classes/class_damage.lua, UpdateBarApocalypseWow). Así el ranking queda en el orden que
-- da el juego. Se refresca por eventos del medidor, con un freno de medio segundo; nada corre por cuadro.
-- Código propio (Details es de otro autor). Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas
local Rk = {}
M.Ranking = Rk

-- ancho para 3 botones de Polestar (mínimo 90 c/u, «Daño recibido» más) con el margen de 24 de su ventana
local FILAS, ALTO_FILA, ANCHO = 10, 18, 380
local FRENO = 0.5

Rk.TIPOS = { { "DamageDone", "Daño" }, { "HealingDone", "Curación" }, { "DamageTaken", "Daño recibido" } }
Rk.SEGMENTOS = { { "Current", "Esta pelea" }, { "Overall", "Total" }, { "Anterior", "Anteriores" } }
-- guid y nombre son los del jugador elegido (pueden ser secretos: solo se pasan de vuelta al juego).
Rk.estado = { tipo = "DamageDone", seg = "Current", indice = nil, guid = nil, nombre = nil }

local function DM() return C_DamageMeter end
local function enum(nombre, k) return Enum and Enum[nombre] and Enum[nombre][k] end
local function S(v) return M.Secreto(v) end

---------------------------------------------------------------- datos
-- Peleas anteriores que el juego guarda, de la más nueva a la más vieja. Cada una: { id, nombre }.
-- La ÚLTIMA de la lista del juego es la pelea actual (así la trata Details, boot.lua GetSegmentIdFromCurrent):
-- ya sale en «Esta pelea» y aquí se salta. NO VERIFICADO en Forever: los campos de cada pelea (Details solo
-- usa sessionID).
function Rk.Anteriores()
	local d = DM()
	if not (d and d.GetAvailableCombatSessions and d.GetCombatSessionFromID) then return {} end
	local ok, lista = pcall(d.GetAvailableCombatSessions)
	if not ok or type(lista) ~= "table" then M.Contar(ok and "sesionesNoTabla" or "sesionesError"); return {} end
	-- diag: cuántas peleas da el juego y qué campos trae cada una (Details solo usa sessionID: NO VERIFICADO)
	local campos
	if type(lista[1]) == "table" and not M.Secreto(lista[1]) then
		campos = {}
		for k in pairs(lista[1]) do if type(k) == "string" then campos[#campos + 1] = k end end
		table.sort(campos)
		campos = table.concat(campos, ",")
	end
	M.Contar("sesiones", campos)
	M.DB().diag.k105.sesionesUltima = #lista
	local out = {}
	for i = #lista - 1, 1, -1 do
		local x = lista[i]
		local id = type(x) == "table" and M.Num(x.sessionID) or nil
		if id then
			local nombre = type(x) == "table" and x.name
			out[#out + 1] = { id = id, nombre = (type(nombre) == "string" and not S(nombre) and nombre ~= "") and nombre or nil }
		end
	end
	return out
end

-- La pelea elegida tal como la da el juego (puede traer secretos), o nil y el motivo.
function Rk.Sesion(seg, tipo, indice)
	if not (M.Medidor and M.Medidor.Disponible()) then return nil, "Este cliente no trae el medidor del juego." end
	local mt = enum("DamageMeterType", tipo)
	if mt == nil then return nil, "Este tipo no está en el medidor del juego." end
	local ok, s
	if seg == "Anterior" then
		local ant = Rk.Anteriores()
		local x = ant[indice or 1]
		if not x then return nil, "Todavía no hay peleas anteriores guardadas." end
		ok, s = pcall(DM().GetCombatSessionFromID, x.id, mt)
	else
		local st = enum("DamageMeterSessionType", seg)
		if st == nil then return nil, "Este tipo no está en el medidor del juego." end
		ok, s = pcall(DM().GetCombatSessionFromType, st, mt)
	end
	if not ok or type(s) ~= "table" then return nil, "Sin datos todavía: pelea un poco." end
	return s
end

-- Filas por jugador. Si NINGUNA cifra es secreta se ordenan de mayor a menor; si hay secretos, el orden es
-- el del juego (no se puede comparar). Cada fila: { nombre, total, porSeg, clase, guid, yo } con los
-- valores tal cual (secretos incluidos), salvo clase y yo, que solo se usan si se pueden leer.
function Rk.Filas(s)
	local filas, secreto = {}, false
	for _, x in ipairs(type(s) == "table" and s.combatSources or {}) do
		if type(x) == "table" then
			local clase = x.classFilename
			if S(clase) or type(clase) ~= "string" then clase = nil end
			local yo = x.isLocalPlayer
			if S(yo) then yo = false end
			if S(x.totalAmount) or S(x.name) then secreto = true end
			filas[#filas + 1] = { nombre = x.name, total = x.totalAmount, porSeg = x.amountPerSecond, clase = clase,
				guid = x.sourceGUID, yo = yo == true }
		end
	end
	if not secreto then
		for _, f in ipairs(filas) do if type(f.total) ~= "number" then f.total = 0 end end
		table.sort(filas, function(a, b) return a.total > b.total end)
	end
	return filas, secreto
end

-- Desglose por hechizo de un jugador (guid tal cual, aunque sea secreto), con 3 argumentos. Details pasa un
-- 4.º (el número de criatura, solo para criaturas); para jugadores, NO VERIFICADO que haga falta.
function Rk.Hechizos(seg, tipo, indice, guid)
	local d = DM()
	if not (d and guid ~= nil) then return nil end
	local mt = enum("DamageMeterType", tipo)
	local fn, primero
	if seg == "Anterior" then
		local x = Rk.Anteriores()[indice or 1]
		fn, primero = d.GetCombatSessionSourceFromID, x and x.id
	else
		fn, primero = d.GetCombatSessionSourceFromType, enum("DamageMeterSessionType", seg)
	end
	if not (fn and primero ~= nil and mt ~= nil) then return nil end
	local ok, sp = pcall(fn, primero, mt, guid)
	if not (ok and type(sp) == "table") then M.DB().diag.rankingHechizosNo = true; return nil end
	local out, secreto = {}, false
	for _, x in ipairs(sp.combatSpells or {}) do
		if type(x) == "table" then
			if S(x.totalAmount) or S(x.spellID) then secreto = true end
			out[#out + 1] = { id = x.spellID, total = x.totalAmount, porSeg = x.amountPerSecond, criatura = x.creatureName }
		end
	end
	if not secreto then
		for _, h in ipairs(out) do if type(h.total) ~= "number" then h.total = 0 end end
		table.sort(out, function(a, b) return a.total > b.total end)
	end
	return out, sp.totalAmount, sp.maxAmount, secreto
end

---------------------------------------------------------------- textos (aceptan secretos)
-- Cifra corta: si se puede leer, la de Mamba ("12,3 mil"); si es secreta, la abrevia el juego.
function Rk.Cifra(v)
	local n = M.Num(v)
	if n then return M.Medidor.Corto(n) end
	if v ~= nil and S(v) and AbbreviateNumbers then
		local ok, t = pcall(AbbreviateNumbers, v)
		if ok and t ~= nil then return t end
	end
	return "…"
end

function Rk.NombreHechizo(id, criatura)
	local nombre
	if M.Num(id) then nombre = M.NombreHechizo(id)
	elseif id ~= nil and C_Spell and C_Spell.GetSpellName then
		local ok, n = pcall(C_Spell.GetSpellName, id)
		nombre = ok and n or nil
	end
	nombre = nombre or "Un hechizo"
	-- golpes de la mascota o de un guardián: el juego los separa con el nombre de la criatura
	if criatura ~= nil and (S(criatura) or (type(criatura) == "string" and criatura ~= "")) then
		local ok, t = pcall(string.format, "%s (%s)", nombre, criatura)
		if ok then return t end
	end
	return nombre
end

local function colorClase(clase)
	local c = clase and RAID_CLASS_COLORS and RAID_CLASS_COLORS[clase]
	if c then return c.r, c.g, c.b end
	-- sin clase (mascota, criatura): el gris de la apariencia, leído del color que da Estilo.lua
	local r, g, b = tostring(P.Color("gris", "")):match("|c%x%x(%x%x)(%x%x)(%x%x)")
	if r then return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255 end
	return RAID_CLASS_COLORS and RAID_CLASS_COLORS.PRIEST and RAID_CLASS_COLORS.PRIEST.r or 1, 1, 1
end

---------------------------------------------------------------- ventana
local v

local function nombreDe(lista, clave)
	for _, x in ipairs(lista) do if x[1] == clave then return x[2] end end
	return clave
end

local function crearFila(i)
	local f = P.Fila(v.lista, ANCHO - 2 * v.margen, ALTO_FILA)
	f:SetPoint("TOPLEFT", v.lista, "TOPLEFT", 0, -(i - 1) * (ALTO_FILA + 2))
	f:RegisterForClicks("LeftButtonUp")
	f.barra = CreateFrame("StatusBar", nil, f)
	f.barra:SetAllPoints(f)
	f.barra:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	f.barra:SetMinMaxValues(0, 1)
	-- los textos van sobre la barra (si fueran de la fila, la barra hija los taparía)
	f.izq = P.Texto(f.barra, "small", "text")
	f.izq:SetPoint("LEFT", f.barra, "LEFT", 4, 0)
	f.izq:SetPoint("RIGHT", f.barra, "RIGHT", -110, 0)
	f.der = P.Texto(f.barra, "number", "text")
	f.der:SetPoint("RIGHT", f.barra, "RIGHT", -4, 0)
	if f.der.SetJustifyH then f.der:SetJustifyH("RIGHT") end
	f:SetScript("OnClick", function(self)
		if not self.dato then return end
		local e = Rk.estado
		if e.guid == nil then
			e.guid, e.nombre = self.dato.guid, self.dato.nombre
			M.Proteger("ranking", Rk.Dibujar)
		end
	end)
	return f
end

local function crear()
	v = P.Ventana("MambaRanking", "Ranking del grupo", ANCHO, 400)
	v.margen = v.margen or 16
	local arriba = -(v.cuerpo or 26) - 4
	-- el alto sale de la cabecera real (56 con Polestar, 26 sin): 4 filas de controles + la lista + margen
	v:SetHeight((v.cuerpo or 26) + 4 + 112 + FILAS * (ALTO_FILA + 2) + 12)
	-- qué se mide: a la izquierda; de qué pelea: a la derecha (dos grupos, no una fila pareja)
	v.tipos, v.segs = {}, {}
	local x = v.margen
	for i, t in ipairs(Rk.TIPOS) do
		local b = P.Boton(v, t[2], function() Rk.estado.tipo = t[1]; Rk.estado.guid = nil; M.Proteger("ranking", Rk.Dibujar) end)
		b:SetPoint("TOPLEFT", v, "TOPLEFT", x, arriba)
		x = x + (b:GetWidth() or 90) + 4
		v.tipos[i] = b
	end
	local y2 = arriba - 30
	for i, s in ipairs(Rk.SEGMENTOS) do
		local b = P.Boton(v, s[2], function()
			local e = Rk.estado
			e.seg, e.guid = s[1], nil
			if s[1] == "Anterior" then e.indice = e.indice or 1 end
			M.Proteger("ranking", Rk.Dibujar)
		end)
		if i == 1 then b:SetPoint("TOPLEFT", v, "TOPLEFT", v.margen, y2)
		else b:SetPoint("LEFT", v.segs[i - 1], "RIGHT", 4, 0) end
		v.segs[i] = b
	end
	-- línea de estado: qué se ve y, en las anteriores, cuál
	v.estado = P.Texto(v, "note", "textDim")
	v.estado:SetPoint("TOPLEFT", v, "TOPLEFT", v.margen, y2 - 32)
	v.estado:SetPoint("RIGHT", v, "RIGHT", -v.margen, 0)
	-- fila propia para Volver / Más nueva / Más vieja (no pisa la línea de estado)
	local y3 = y2 - 52
	v.atras = P.Boton(v, "Volver", function() Rk.estado.guid = nil; M.Proteger("ranking", Rk.Dibujar) end)
	v.atras:SetPoint("TOPLEFT", v, "TOPLEFT", v.margen, y3)
	v.mas = P.Boton(v, "Más vieja", function()
		local e = Rk.estado
		e.indice = math.min((e.indice or 1) + 1, math.max(#Rk.Anteriores(), 1)); e.guid = nil; M.Proteger("ranking", Rk.Dibujar)
	end)
	v.mas:SetPoint("TOPRIGHT", v, "TOPRIGHT", -v.margen, y3)
	v.menos = P.Boton(v, "Más nueva", function()
		local e = Rk.estado
		e.indice = math.max((e.indice or 1) - 1, 1); e.guid = nil; M.Proteger("ranking", Rk.Dibujar)
	end)
	v.menos:SetPoint("RIGHT", v.mas, "LEFT", -4, 0)
	v.lista = CreateFrame("Frame", nil, v)
	v.lista:SetPoint("TOPLEFT", v, "TOPLEFT", v.margen, y3 - 30)
	v.lista:SetSize(ANCHO - 2 * v.margen, FILAS * (ALTO_FILA + 2))
	v.filas = {}
	for i = 1, FILAS do v.filas[i] = crearFila(i) end
	v.vacio = P.Texto(v.lista, "body", "textMuted")
	v.vacio:SetPoint("TOPLEFT", v.lista, "TOPLEFT", 4, -6)
	v.vacio:SetPoint("RIGHT", v.lista, "RIGHT", -4, 0)
	v:HookScript("OnShow", function() M.DB().rankingAbierto = true; Rk.Reloj(M.EnCombate()); M.Proteger("ranking", Rk.Dibujar) end)
	v:HookScript("OnHide", function() M.DB().rankingAbierto = false; Rk.Reloj(false) end)
	if _G.Asistente and _G.Asistente.AlCambiarApariencia then
		_G.Asistente.AlCambiarApariencia(function() if v:IsShown() then M.Proteger("ranking", Rk.Dibujar) end end)
	end
end

local function pintarFila(f, i, dato, top, izq, der, clase)
	f.dato = dato
	f.barra:SetMinMaxValues(0, top)
	f.barra:SetValue(dato.total)
	local r, g, b = colorClase(clase)
	f.barra:SetStatusBarColor(r, g, b, 0.55)
	f.izq:SetText(izq)
	f.der:SetText(der)
	f:Show()
end

local function texto(fmt, ...)
	local ok, t = pcall(string.format, fmt, ...)
	return ok and t or "…"
end

function Rk.Dibujar()
	if not v or not v:IsShown() then return end
	local e = Rk.estado
	local nT, nS = nombreDe(Rk.TIPOS, e.tipo), nombreDe(Rk.SEGMENTOS, e.seg)
	local s, motivo = Rk.Sesion(e.seg, e.tipo, e.indice)
	local donde = nS
	if e.seg == "Anterior" then
		local ant = Rk.Anteriores()
		local x = ant[e.indice or 1]
		donde = x and (("Pelea anterior %d de %d"):format(e.indice or 1, #ant) .. (x.nombre and (" · " .. x.nombre) or "")) or nS
	end
	v.mas:SetShown(e.seg == "Anterior" and e.guid == nil)
	v.menos:SetShown(e.seg == "Anterior" and e.guid == nil)
	v.atras:SetShown(e.guid ~= nil)
	local lista, top, secreto = {}, 1, false
	if s and e.guid == nil then
		lista, secreto = Rk.Filas(s)
		top = s.maxAmount
		if top == nil then top = lista[1] and lista[1].total or 1 end
		if not S(top) and (type(top) ~= "number" or top <= 0) then top = 1 end
		v.estado:SetText(nT .. " · " .. donde .. (secreto and " · en combate el juego esconde las cifras" or ""))
		for i = 1, FILAS do
			local x, f = lista[i], v.filas[i]
			if x then
				local izq = texto("%d. %s%s", i, x.nombre, x.yo and " (tú)" or "")
				local der = Rk.Cifra(x.total)
				if x.porSeg ~= nil then der = texto("%s  %s/s", der, Rk.Cifra(x.porSeg)) end
				pintarFila(f, i, x, top, izq, der, x.clase)
			else f.dato = nil; f:Hide() end
		end
		v.vacio:SetText(#lista == 0 and "Nadie de tu grupo hizo esto en esta pelea." or "")
	elseif s then
		-- desglose del jugador elegido
		local hs, total, maxH, secretoH = Rk.Hechizos(e.seg, e.tipo, e.indice, e.guid)
		v.estado:SetText(texto("%s de %s · %s", nT, e.nombre, donde))
		hs = hs or {}
		top = maxH
		if top == nil then top = hs[1] and hs[1].total or 1 end
		if not S(top) and (type(top) ~= "number" or top <= 0) then top = 1 end
		for i = 1, FILAS do
			local h, f = hs[i], v.filas[i]
			if h then
				local der = Rk.Cifra(h.total)
				local n, t = M.Num(h.total), M.Num(total)
				if n and t and t > 0 then der = texto("%s  %d %%", der, math.floor(n / t * 100 + 0.5)) end
				pintarFila(f, i, { total = h.total }, top, ("|T%s:14:14:0:0|t %s"):format(tostring(M.Num(h.id) and M.Icono(h.id) or 134400), Rk.NombreHechizo(h.id, h.criatura)), der, nil)
				f.dato = nil -- en el desglose una fila no se aprieta
			else f.dato = nil; f:Hide() end
		end
		v.vacio:SetText(#hs == 0 and "El juego no dio el desglose de este jugador." or "")
	else
		v.estado:SetText(nT .. " · " .. donde)
		for i = 1, FILAS do v.filas[i].dato = nil; v.filas[i]:Hide() end
		v.vacio:SetText(motivo or "")
	end
end

-- Freno: los eventos del medidor llegan muchas veces por segundo en combate; se dibuja como mucho uno cada
-- medio segundo (sin C_Timer, en el acto). Nada corre por cuadro.
local pendiente = false
function Rk.Pedir()
	if not v or not v:IsShown() then return end
	if not (C_Timer and C_Timer.After) then M.Proteger("ranking", Rk.Dibujar); return end
	if pendiente then return end
	pendiente = true
	C_Timer.After(FRENO, function() pendiente = false; M.Proteger("ranking", Rk.Dibujar) end)
end

-- Reloj de 1 s SOLO en combate y con la ventana abierta: por si el juego no manda DAMAGE_METER_* durante la
-- pelea (Details Forever también refresca con un reloj). Fuera de combate no corre.
function Rk.Reloj(prender)
	if not v then return end
	if prender and not v.tic and C_Timer and C_Timer.NewTicker then
		v.tic = C_Timer.NewTicker(1, function() M.Proteger("ranking", Rk.Dibujar) end)
	elseif not prender and v.tic then
		v.tic:Cancel(); v.tic = nil
	end
end

function Rk.Abrir()
	if not v then crear() end
	v.ejemplo = nil
	v:Show()
	M.DB().rankingAbierto = true
	Rk.Reloj(M.EnCombate())
	M.Proteger("ranking", Rk.Dibujar)
end
function Rk.Cerrar() if v then v:Hide(); M.DB().rankingAbierto = false; Rk.Reloj(false) end end
function Rk.Alternar() if v and v:IsShown() then Rk.Cerrar() else Rk.Abrir() end end
function Rk.Ventana() return v end
M.Precrear(function() if not v then crear() end end)
M.AlModoMover(function(activo)
	if not v then crear() end
	if activo then
		if not v:IsShown() then v.ejemplo = true; v:Show(); M.DB().rankingAbierto = false end
	elseif v.ejemplo then
		v.ejemplo = nil
		v:Hide()
		M.DB().rankingAbierto = false
	end
end)

local f = CreateFrame("Frame")
for _, ev in ipairs({ "DAMAGE_METER_COMBAT_SESSION_UPDATED", "DAMAGE_METER_CURRENT_SESSION_UPDATED", "DAMAGE_METER_RESET",
	"PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_LOGIN" }) do M.Escuchar(f, ev) end
f:SetScript("OnEvent", function(_, ev)
	if ev:find("^DAMAGE_METER") then M.Proteger("diag", M.Contar, ev .. (M.EnCombate() and ":combate" or "")) end
	if ev == "PLAYER_LOGIN" then
		if M.DB().rankingAbierto then M.Proteger("ranking", Rk.Abrir) end
		return
	end
	if ev == "PLAYER_REGEN_DISABLED" then
		if v and v:IsShown() then Rk.Reloj(true) end
		return
	end
	if ev == "PLAYER_REGEN_ENABLED" then Rk.Reloj(false) end
	if ev == "DAMAGE_METER_RESET" then Rk.estado.guid = nil end
	Rk.Pedir()
end)
