-- Mamba_Comodidades: raros y tesoros (fila K70 de MAMBA_ACEPTACION.md; reemplaza a RareScanner, K93).
-- Polestar ya detecta los raros (vignetas, placas, objetivo y ratón), avisa con una tarjeta con botón
-- "Apuntar" y los pone en el mapa (Polestar/Rares). Mamba le suma lo que faltaba, leyendo sus datos (el
-- Codex) sin tocar su código:
--   1) la MINIATURA: la cara 3D del raro al lado de la tarjeta de aviso;
--   2) la RUTA: el orden más corto para pasar por los raros de la zona, con su largo y su tiempo (R0);
--   3) el MACRO "MambaRaros": /targetexact con los raros de la zona actual, el más cercano primero (como el
--      RS_MACRO de RareScanner). Se arma solo al cambiar de zona, fuera de combate.
-- Código escrito de cero: RareScanner es "All Rights Reserved" (su .toc, leído el 18-11-2026).
-- Licencia: GPL-3.0-only.
local _, M = ...
local R = {}
M.Raros = R

local floor, max, sqrt, format = math.floor, math.max, math.sqrt, string.format

R.MACRO = "MambaRaros"
R.ICONO = 134400          -- signo de pregunta: el macro toma el icono del juego
R.LIMITE = 255            -- largo máximo de un macro
R.LLEGAR = 40             -- a esta distancia (m) la ruta pasa al siguiente raro
R.A_PIE, R.MONTADO = 7, 11.2 -- m/s: correr y montura de 60 %

local function PS() local p = _G.Polestar; return type(p) == "table" and p or nil end
local function Rares() local p = PS(); return p and p.Rares end

function R.Opciones()
	local d = M.DB()
	d.raros = d.raros or {}
	local o = d.raros
	if o.miniatura == nil then o.miniatura = true end
	if o.macro == nil then o.macro = true end
	if o.tesoros == nil then o.tesoros = false end
	if o.grises == nil then o.grises = false end
	return o
end

---------------------------------------------------------------- puro: distancias, ruta y macro
local function plano(a, b)
	if not (a and b) or a.map ~= b.map then return nil end
	local dx, dy = (a.x - b.x) * 10, (a.y - b.y) * 10 -- sin Polestar: ~1000 m por mapa (solo pruebas)
	return sqrt(dx * dx + dy * dy)
end

-- Metros entre dos puntos { map, x, y, f }: los de Polestar (coordenadas del mundo), si no, una
-- aproximación sobre el mapa.
function R.Metros(a, b)
	local Ra = Rares()
	if Ra and Ra.Yards then
		local ok, d = pcall(Ra.Yards, a, b)
		if ok and d then return d end
	end
	return plano(a, b)
end

local function largo(desde, orden)
	local total, prev = 0, desde
	for _, p in ipairs(orden) do
		if prev then total = total + (R.Metros(prev, p.spawn) or 0) end
		prev = p.spawn
	end
	return total
end
R.Largo = largo

-- Los raros (y tesoros, si se piden) con un lugar de aparición en el mapa `zona`. Por cada uno, el lugar
-- más cercano a `desde`. Fuera: los de mazmorra y, salvo grises = true, los que ya no dan experiencia.
--   lista = { Rares.Info, ... }; o = { nivel, gris (nivel gris máximo), grises }
function R.DeLaZona(lista, zona, desde, o)
	o = o or {}
	local out = {}
	for _, rec in ipairs(lista or {}) do
		local nivel = rec.levelMax or rec.level
		local gris = not o.grises and o.gris and nivel and nivel <= o.gris
		if not rec.instance and not gris then
			local mejor, mejorD
			for _, s in ipairs(rec.spawns or {}) do
				if s.map == zona then
					local d = desde and R.Metros(desde, s) or 0
					if not mejor or (d and d < mejorD) then mejor, mejorD = s, d or 0 end
				end
			end
			if mejor then out[#out + 1] = { rec = rec, spawn = mejor, metros = mejorD } end
		end
	end
	table.sort(out, function(a, b) return a.metros < b.metros end)
	return out
end

-- El orden más corto que encuentra para pasar por todos los puntos saliendo de `desde` (no vuelve):
-- el vecino más cercano y después 2-opt hasta que no mejora. Devuelve orden, metros totales.
function R.Ruta(puntos, desde)
	local quedan, orden, actual = {}, {}, desde
	for i, p in ipairs(puntos) do quedan[i] = p end
	while #quedan > 0 do
		local mejorI, mejorD = 1, nil
		for i, p in ipairs(quedan) do
			local d = actual and R.Metros(actual, p.spawn) or 0
			if d and (not mejorD or d < mejorD) then mejorI, mejorD = i, d end
		end
		local p = table.remove(quedan, mejorI)
		orden[#orden + 1] = p
		actual = p.spawn
	end
	local n = #orden
	local mejoro, vueltas = true, 0
	while mejoro and vueltas < 50 do
		mejoro, vueltas = false, vueltas + 1
		for i = 1, n - 1 do
			for k = i + 1, n do
				local a = (i == 1) and desde or orden[i - 1].spawn
				local b, c = orden[i].spawn, orden[k].spawn
				local d = orden[k + 1] and orden[k + 1].spawn
				if a then
					local antes = (R.Metros(a, b) or 0) + (d and (R.Metros(c, d) or 0) or 0)
					local despues = (R.Metros(a, c) or 0) + (d and (R.Metros(b, d) or 0) or 0)
					if despues + 0.5 < antes then
						local x, y = i, k
						while x < y do orden[x], orden[y] = orden[y], orden[x]; x, y = x + 1, y - 1 end
						mejoro = true
					end
				end
			end
		end
	end
	return orden, largo(desde, orden)
end

local function nombreSeguro(n)
	return type(n) == "string" and n ~= "" and not n:find("%c") and #n < 60
end

-- El texto del macro: un /targetexact por nombre, el primero de la lista es el que gana (va al final,
-- porque el último que encuentra queda apuntado). Caben los que entran en 255 caracteres; el resto se
-- deja. `cola`: una línea más al final si cabe (la marca de Polestar). Devuelve texto, cuántos entraron.
function R.Macro(nombres, cola)
	local elegidos, vistos, largoT = {}, {}, 0
	for _, n in ipairs(nombres or {}) do
		if nombreSeguro(n) and not vistos[n] then
			local linea = "/targetexact " .. n
			if largoT + #linea + 1 > R.LIMITE then break end
			vistos[n] = true
			elegidos[#elegidos + 1] = linea
			largoT = largoT + #linea + 1
		end
	end
	if #elegidos == 0 then return nil, 0 end
	local lineas = {}
	for i = #elegidos, 1, -1 do lineas[#lineas + 1] = elegidos[i] end
	local texto = table.concat(lineas, "\n")
	if cola and #texto + 1 + #cola <= R.LIMITE then texto = texto .. "\n" .. cola end
	return texto, #elegidos
end

-- El signo de "aproximado": ≈ si la letra de la apariencia lo tiene, si no "~" (Polestar, Theme.Approx).
function R.Aprox()
	local p = PS()
	local T = p and p.Theme
	if T and T.Approx then
		local ok, a = pcall(T.Approx)
		if ok and type(a) == "string" then return a end
	end
	return "~"
end

-- "≈4 min" (R0: lo estimado lleva ≈).
function R.Minutos(metros, velocidad)
	local s = (metros or 0) / velocidad
	if s < 60 then return R.Aprox() .. "1 min" end
	return R.Aprox() .. floor(s / 60 + 0.5) .. " min"
end

function R.MetrosTexto(m)
	m = floor((m or 0) + 0.5)
	if m >= 1000 then return format("%d %03d m", floor(m / 1000), m % 1000) end
	return m .. " m"
end

---------------------------------------------------------------- en el juego: la zona y sus raros
-- El mapa de la zona del jugador (sube desde una cueva o un barrio hasta el mapa de la zona).
function R.Zona()
	if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
	local id = C_Map.GetBestMapForUnit("player")
	local zonaTipo = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
	local vueltas = 0
	while id and C_Map.GetMapInfo and vueltas < 6 do
		local info = C_Map.GetMapInfo(id)
		if not info or info.mapType == zonaTipo or (info.mapType or 9) < zonaTipo then break end
		id, vueltas = info.parentMapID, vueltas + 1
	end
	return id
end

function R.NombreZona(id)
	local info = id and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
	return info and info.name or "esta zona"
end

local function aqui()
	local p = PS()
	if p and p.PlayerPoint then
		local ok, pt = pcall(p.PlayerPoint)
		if ok and pt then return pt end
	end
end
R.Aqui = aqui

local function enCombate() return InCombatLockdown and InCombatLockdown() end

-- Los registros de un tipo con algún lugar en el mapa `zona`, guardados por zona: recorrer toda la base
-- de raros se hace una vez por zona y no en cada aviso.
local porZona = {}
function R.DeEsteMapa(tipo, zona)
	local k = tipo .. ":" .. tostring(zona)
	if porZona[k] then return porZona[k] end
	local Ra = Rares()
	local out = {}
	for _, rec in ipairs((Ra and Ra.ListOf and Ra.ListOf(tipo)) or {}) do
		for _, s in ipairs(rec.spawns or {}) do
			if s.map == zona then out[#out + 1] = rec; break end
		end
	end
	porZona[k] = out
	return out
end

-- Los raros de la zona actual, el más cercano primero; nil, motivo cuando no hay datos.
function R.Lista()
	local Ra = Rares()
	if not (Ra and Ra.Codex and Ra.ListOf) then return nil, "Falta Polestar." end
	if not Ra.Codex(not enCombate()) then
		return nil, enCombate() and "Sin datos aún: sal de combate y vuelve a abrir." or "Sin datos aún: falta la base de raros de Polestar."
	end
	local zona = R.Zona()
	if not zona then return nil, "Sin datos aún: no se sabe en qué zona estás." end
	local o = R.Opciones()
	local nivel = UnitLevel and UnitLevel("player") or 1
	local filtro = { grises = o.grises, gris = Ra.GreyLevel and Ra.GreyLevel(nivel) }
	local desde = aqui()
	local lista = R.DeLaZona(R.DeEsteMapa("rare", zona), zona, desde, filtro)
	if o.tesoros then
		for _, t in ipairs(R.DeLaZona(R.DeEsteMapa("treasure", zona), zona, desde, { grises = true })) do lista[#lista + 1] = t end
		table.sort(lista, function(a, b) return a.metros < b.metros end)
	end
	return lista, nil, zona
end

---------------------------------------------------------------- el macro
local function marca()
	local p = PS()
	local B = p and p.QoL and p.QoL.Buttons
	if B and B.MarkLine then
		local ok, l = pcall(B.MarkLine, "mob")
		if ok and type(l) == "string" then return l end
	end
end

-- Los nombres del macro: primero los que Polestar ve cerca AHORA, después los de la zona por distancia.
function R.NombresMacro(lista)
	local nombres = {}
	local Ra = Rares()
	if Ra and Ra.Nearby then
		local ok, cerca = pcall(Ra.Nearby)
		if ok and type(cerca) == "table" then for _, n in ipairs(cerca) do nombres[#nombres + 1] = n end end
	end
	for _, p in ipairs(lista or {}) do
		if p.rec.kind ~= "treasure" then nombres[#nombres + 1] = p.rec.name end
	end
	return nombres
end

R.ultimo = { texto = nil, cuantos = 0, total = 0, zona = nil }
local pendiente = false

-- Escribe el macro MambaRaros (lo crea la primera vez). Fuera de combate; en combate queda para después.
function R.ActualizarMacro(forzar)
	if not (forzar or R.Opciones().macro) then return false, "apagado" end
	if enCombate() then pendiente = true; return false, "combate" end
	local lista, motivo, zona = R.Lista()
	if not lista then R.ultimo = { cuantos = 0, total = 0, motivo = motivo }; return false, motivo end
	local nombres = R.NombresMacro(lista)
	local texto, cuantos = R.Macro(nombres, marca())
	R.ultimo = { texto = texto, cuantos = cuantos, total = #nombres, zona = zona }
	texto = texto or "/run print(\"Mamba: no hay raros en esta zona.\")"
	if not (GetMacroIndexByName and CreateMacro and EditMacro) then return false, "sin macros" end
	local i = GetMacroIndexByName(R.MACRO)
	local ok
	if i and i > 0 then
		ok = pcall(EditMacro, i, R.MACRO, R.ICONO, texto)
	else
		ok = pcall(CreateMacro, R.MACRO, R.ICONO, texto, nil)
		if not ok or (GetMacroIndexByName(R.MACRO) or 0) == 0 then
			ok = pcall(CreateMacro, R.MACRO, R.ICONO, texto, true) -- los macros de la cuenta están llenos
		end
	end
	if not ok then return false, "No se pudo escribir el macro: la lista de macros está llena." end
	return true
end

-- Pone el macro en el cursor, para soltarlo en una barra (sin abrir la ventana de macros).
function R.AlCursor()
	if enCombate() then return false, "ahora no se puede: sal de combate." end
	local ok, motivo = R.ActualizarMacro(true)
	if PickupMacro and GetMacroIndexByName and (GetMacroIndexByName(R.MACRO) or 0) > 0 then
		PickupMacro(R.MACRO)
		return true
	end
	return false, (not ok and motivo) or "no se pudo crear el macro."
end

---------------------------------------------------------------- la ruta
R.ruta = { activa = false, orden = {}, i = 0, total = 0, ingenuo = 0 }

function R.Calcular()
	local lista, motivo, zona = R.Lista()
	if not lista then R.ruta = { activa = false, orden = {}, i = 0, total = 0, ingenuo = 0, motivo = motivo }; return R.ruta end
	local desde = aqui()
	local orden, total = R.Ruta(lista, desde)
	-- R0: la ruta elegida contra la siguiente alternativa, ir en el orden de la lista (el más cercano
	-- primero, sin mirar adelante).
	R.ruta = { activa = R.ruta.activa and R.ruta.zona == zona, orden = orden, i = 0, total = total,
		ingenuo = largo(desde, lista), zona = zona }
	return R.ruta
end

local function decir(t)
	local A = _G.Asistente
	local nombre = (A and A.ColorOscuro) and A.ColorOscuro("titulo", "Mamba:") or "Mamba:"
	if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(nombre .. " " .. t) end
end
R.Decir = decir

function R.Llevame(p)
	local Ps = PS()
	local N = Ps and Ps.Nav
	if not (p and N and N.SetTarget) then return false end
	local s = p.spawn
	return N.SetTarget(s.map, s.x, s.y, p.rec.name, s.f) and true or false
end

local reloj
local function vigilar()
	if reloj or not (C_Timer and C_Timer.NewTicker) then return end
	reloj = C_Timer.NewTicker(1, function()
		local r = R.ruta
		if not r.activa then reloj:Cancel(); reloj = nil; return end
		local p, yo = r.orden[r.i], aqui()
		local d = p and yo and R.Metros(yo, p.spawn)
		if d and d <= R.LLEGAR then R.Siguiente(true) end
	end)
end

function R.Empezar()
	local r = R.Calcular()
	if #r.orden == 0 then decir(r.motivo or "No hay raros en esta zona."); return false end
	r.activa, r.i = true, 1
	R.Llevame(r.orden[1])
	decir(format("ruta de %d raros, %s (%s). Primero: %s.", #r.orden, R.MetrosTexto(r.total),
		R.Minutos(r.total, R.A_PIE) .. " a pie", r.orden[1].rec.name))
	vigilar()
	if M.RefrescarPanel then pcall(M.RefrescarPanel) end
	return true
end

function R.Siguiente(llego)
	local r = R.ruta
	if not r.activa then return R.Empezar() end
	r.i = r.i + 1
	local p = r.orden[r.i]
	if not p then
		r.activa = false
		decir("ruta terminada.")
	else
		R.Llevame(p)
		local yo = aqui()
		local d = yo and R.Metros(yo, p.spawn)
		decir(format("%s%s (%d de %d%s).", llego and "llegaste. Siguiente: " or "siguiente: ", p.rec.name,
			r.i, #r.orden, d and (", " .. R.MetrosTexto(d)) or ""))
	end
	if M.RefrescarPanel then pcall(M.RefrescarPanel) end
	return true
end

function R.Detener()
	R.ruta.activa = false
	local Ps = PS()
	if Ps and Ps.Nav and Ps.Nav.ClearTarget then pcall(Ps.Nav.ClearTarget) end
	if M.RefrescarPanel then pcall(M.RefrescarPanel) end
end

---------------------------------------------------------------- la miniatura en el aviso de Polestar
-- Cuelga de la tarjeta: hereda su escala, su opacidad y su entrada animada, y se va con ella. Mismo alto
-- que la tarjeta y su mismo marco (psLight: con las apariencias del juego, el marco claro de los avisos).
local mini
local function hacerMini(tarjeta)
	if mini then return mini end
	mini = CreateFrame("Frame", "MambaRaroMiniatura", tarjeta)
	local h = tarjeta.GetHeight and tarjeta:GetHeight()
	if not h or h < 60 then h = 104 end
	mini:SetSize(h, h)
	mini.psLight = true
	local p = PS()
	if p and p.Theme and p.Theme.Skin then pcall(p.Theme.Skin, mini, "window") end
	mini.modelo = CreateFrame("PlayerModel", nil, mini)
	mini.modelo:SetPoint("TOPLEFT", mini, "TOPLEFT", 4, -4)
	mini.modelo:SetPoint("BOTTOMRIGHT", mini, "BOTTOMRIGHT", -4, 4)
	mini:Hide()
	return mini
end
R.HacerMini = hacerMini

-- Dibuja la cara del raro cuando el cliente ya lo conoce (si no, SetCreature no dibuja nada): lo intenta
-- unas veces, medio segundo entre una y otra.
local function pintar(npc, intento)
	if not (mini and mini:IsShown() and mini.npc == npc) then return end
	local p = PS()
	local C = p and p.Compat
	local listo = not (C and C.CreatureCached) or C.CreatureCached(npc) ~= false
	if listo then
		mini.modelo:SetCreature(npc)
		if mini.modelo.SetPortraitZoom then mini.modelo:SetPortraitZoom(1) end
		return
	end
	if intento < 12 and C_Timer and C_Timer.After then
		C_Timer.After(0.5, function() pintar(npc, intento + 1) end)
	else
		mini:Hide()
	end
end

function R.Miniatura(alerta)
	if not R.Opciones().miniatura or type(alerta) ~= "table" then return false end
	if alerta.kind ~= "rare" or type(alerta.id) ~= "number" then if mini then mini:Hide() end; return false end
	local Ra = Rares()
	local tarjeta = Ra and Ra.Toast and Ra.Toast.frame
	if not tarjeta then return false end
	local m = hacerMini(tarjeta)
	m:ClearAllPoints()
	m:SetPoint("TOPRIGHT", tarjeta, "TOPLEFT", -6, 0)
	m.npc = alerta.id
	m:Show()
	pintar(alerta.id, 0)
	return true
end

---------------------------------------------------------------- arranque
function R.Iniciar()
	R.Opciones()
	local p = PS()
	if p and p.On then
		p.On("RARE_SPOTTED", function(a) pcall(R.Miniatura, a) end)
		-- un raro a la vista pasa al frente del macro (como mucho una vez cada 5 segundos)
		local ultima = -10
		p.On("RARE_NEARBY", function()
			local t = GetTime and GetTime() or 0
			if t - ultima < 5 or not R.Opciones().macro or enCombate() then return end
			ultima = t
			pcall(R.ActualizarMacro)
		end)
	end
	local ev = CreateFrame("Frame")
	for _, e in ipairs({ "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }) do pcall(ev.RegisterEvent, ev, e) end
	ev:SetScript("OnEvent", function(_, e)
		if e == "PLAYER_REGEN_ENABLED" then
			if pendiente then pendiente = false; pcall(R.ActualizarMacro) end
			return
		end
		-- al entrar a una zona: el macro y, si hay una ruta en marcha de otra zona, se apaga
		local function luego()
			if R.ruta.activa and R.ruta.zona ~= R.Zona() then R.ruta.activa = false end
			pcall(R.ActualizarMacro)
			if M.RefrescarPanel then pcall(M.RefrescarPanel) end
		end
		if C_Timer and C_Timer.After then C_Timer.After(3, luego) else luego() end
	end)
end
