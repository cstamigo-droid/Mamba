-- Mamba_Combate: medidor de combate de verdad (K65, K80) con el medidor del juego (C_DamageMeter, el que usa
-- Details Forever): daño, curación, daño recibido, daño evitable, interrupciones, disipaciones, absorciones y
-- muertes, del combate actual o del total; desglose por hechizo y "¿qué me mató?" (C_DeathRecap).
-- En combate Forever esconde los números (valores secretos): la ventana se pone al día al terminar la pelea y
-- dentro de la pelea muestra lo que el juego deja ver. Código propio (Details es de otro autor).
-- Licencia: GPL-3.0-only.
local _, M = ...
local Med = {}
M.Medidor = Med

local function DM() return C_DamageMeter end
local function enum(nombre, k) return Enum and Enum[nombre] and Enum[nombre][k] end

Med.TIPOS = {
	{ "DamageDone", "Daño" }, { "HealingDone", "Curación" }, { "DamageTaken", "Daño recibido" },
	{ "AvoidableDamageTaken", "Daño evitable" }, { "Interrupts", "Interrupciones" }, { "Dispels", "Disipaciones" },
	{ "Absorbs", "Absorciones" }, { "Deaths", "Muertes" },
}
Med.SESIONES = { { "Current", "Esta pelea" }, { "Overall", "Total" } }

function Med.Disponible()
	local d = DM()
	return d ~= nil and d.GetCombatSessionFromType ~= nil and Enum ~= nil and Enum.DamageMeterType ~= nil
end

-- { total, dur, filas = { { nombre, total, porSeg, clase, yo, guid, muerte } } } o nil y el motivo.
function Med.Sesion(sesion, tipo)
	if not Med.Disponible() then return nil, "Este cliente no trae el medidor del juego." end
	local st, mt = enum("DamageMeterSessionType", sesion), enum("DamageMeterType", tipo)
	if st == nil or mt == nil then return nil, "Tipo no disponible." end
	local ok, s = pcall(DM().GetCombatSessionFromType, st, mt)
	if not ok or not s then return nil, "Sin datos todavía: pelea un poco." end
	local out = { filas = {}, total = M.Num(s.totalAmount), dur = M.Num(s.durationSeconds) }
	local secreto = false
	for _, x in ipairs(s.combatSources or {}) do
		local total, nombre = M.Num(x.totalAmount), x.name
		if total == nil or M.Secreto(nombre) then secreto = true else
			out.filas[#out.filas + 1] = { nombre = nombre, total = total, porSeg = M.Num(x.amountPerSecond), clase = (not M.Secreto(x.classFilename)) and x.classFilename or nil,
				yo = (not M.Secreto(x.isLocalPlayer)) and x.isLocalPlayer or false, guid = (not M.Secreto(x.sourceGUID)) and x.sourceGUID or nil,
				muerte = M.Num(x.deathRecapID) }
		end
	end
	table.sort(out.filas, function(a, b) return a.total > b.total end)
	out.secreto = secreto
	if secreto and #out.filas == 0 then return nil, "En combate el juego esconde los números: se ven al terminar la pelea." end
	return out
end

-- Desglose por hechizo de un jugador (por defecto, tú).
function Med.Hechizos(sesion, tipo, guid)
	if not Med.Disponible() or not DM().GetCombatSessionSourceFromType then return nil end
	local st, mt = enum("DamageMeterSessionType", sesion), enum("DamageMeterType", tipo)
	if not guid then
		local s = Med.Sesion(sesion, tipo)
		for _, f in ipairs(s and s.filas or {}) do if f.yo then guid = f.guid end end
	end
	if not guid then return nil end
	-- firma NO VERIFICADA: se prueba sin y con el 4.º argumento
	local ok, sp = pcall(DM().GetCombatSessionSourceFromType, st, mt, guid)
	if not (ok and sp) then ok, sp = pcall(DM().GetCombatSessionSourceFromType, st, mt, guid, true) end
	if not ok or not sp then M.DB().diag.hechizosNo = true; return nil end
	local out, total = {}, M.Num(sp.totalAmount)
	for _, x in ipairs(sp.combatSpells or {}) do
		local id, amt = M.Num(x.spellID), M.Num(x.totalAmount)
		if id and amt then
			out[#out + 1] = { id = id, nombre = M.NombreHechizo(id), total = amt, porSeg = M.Num(x.amountPerSecond),
				pct = total and total > 0 and amt / total * 100 or nil }
		end
	end
	table.sort(out, function(a, b) return a.total > b.total end)
	return out, total
end

-- "¿Qué me mató?": el último golpe del registro de muerte del juego.
function Med.QueMeMato()
	local R = C_DeathRecap
	local s = Med.Sesion("Overall", "Deaths")
	local id
	for _, f in ipairs(s and s.filas or {}) do if f.yo and f.muerte and f.muerte > 0 then id = f.muerte end end
	if not (R and id and R.GetRecapEvents) then return nil end
	if R.HasRecapEvents and not R.HasRecapEvents(id) then return nil end
	local ok, ev = pcall(R.GetRecapEvents, id)
	if not (ok and type(ev) == "table" and ev[1]) then return nil end
	local e = ev[1]
	local quien = (not M.Secreto(e.sourceName)) and e.sourceName or "algo"
	local que = (not M.Secreto(e.spellName)) and e.spellName or (M.Num(e.spellId) and M.NombreHechizo(e.spellId)) or "un golpe"
	local cuanto = M.Num(e.amount)
	return ("%s te mató con %s%s"):format(quien, que, cuanto and (" (" .. cuanto .. ")") or "")
end

function Med.Corto(n)
	if not n then return "—" end
	if n >= 1e6 then return ("%.1f M"):format(n / 1e6) elseif n >= 1e4 then return ("%.1f mil"):format(n / 1e3) end
	return tostring(math.floor(n + 0.5))
end

---------------------------------------------------------------- ventana flotante
local v, filas
Med.estado = { sesion = "Current", tipo = "DamageDone" }

-- El marco se arma una vez (al entrar, escondido, para «Mover elementos»; o al dibujarlo).
function Med.Crear()
	if v then return v end
	v = CreateFrame("Frame", "MambaMedidorCombate", UIParent)
	v:SetSize(190, 16)
	v:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -320, 220)
	v:Hide()
	v.titulo = CreateFrame("Button", nil, v)
	-- el título es solo la franja de arriba; las barras van DENTRO del marco y el marco crece con ellas, así el
	-- recuadro de «Mover elementos» cubre todo lo que se ve (Cristian, 19-11: "no se mueve": arrastraba las barras)
	v.titulo:SetPoint("TOPLEFT", v, "TOPLEFT", 0, 0)
	v.titulo:SetPoint("TOPRIGHT", v, "TOPRIGHT", 0, 0)
	v.titulo:SetHeight(16)
	v.titulo.t = M.Piezas.Texto(v.titulo, "small", "text")
	v.titulo.t:SetAllPoints(v.titulo)
	v.titulo:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	v.titulo:SetScript("OnClick", function(_, boton)
		local e = Med.estado
		if boton == "RightButton" then
			e.sesion = e.sesion == "Current" and "Overall" or "Current"
		else
			local i = 1
			for k, t in ipairs(Med.TIPOS) do if t[1] == e.tipo then i = k end end
			e.tipo = Med.TIPOS[i % #Med.TIPOS + 1][1]
		end
		Med.Dibujar()
	end)
	filas = {}
	M.Movible(v, "MambaMedidorCombate", "Medidor de combate")
	return v
end
M.Precrear(Med.Crear)
M.AlModoMover(function(activo)
	if not v then Med.Crear() end
	if activo then
		if not v:IsShown() then
			v.ejemplo = true
			v.titulo.t:SetText("Medidor de combate (ejemplo)")
			v:SetHeight(16 + 4 * 14) -- el alto de unas barras, para que el recuadro se vea del tamaño real
			v:Show()
		end
	elseif v.ejemplo then
		v.ejemplo = nil
		v:Hide()
		Med.Dibujar()
	end
end)

function Med.Dibujar()
	if v and v.ejemplo then return end -- modo «Mover elementos»
	local d = M.DB()
	if not d.medidor then if v then v:Hide() end return end
	if not v then Med.Crear() end
	local e = Med.estado
	local nombreT, nombreS = e.tipo, e.sesion
	for _, t in ipairs(Med.TIPOS) do if t[1] == e.tipo then nombreT = t[2] end end
	for _, s in ipairs(Med.SESIONES) do if s[1] == e.sesion then nombreS = s[2] end end
	v.titulo.t:SetText(nombreT .. " · " .. nombreS)
	local s, motivo = Med.Sesion(e.sesion, e.tipo)
	local lista = s and s.filas or {}
	local max = lista[1] and lista[1].total or 1
	for i = 1, 8 do
		local x, b = lista[i], filas[i]
		if not b then
			b = M.Barra(v, 190, 13)
			b:SetPoint("TOP", v, "TOP", 0, -16 - (i - 1) * 14)
			b:SetMinMaxValues(0, 1)
			filas[i] = b
		end
		if x then
			b:SetValue(max > 0 and x.total / max or 0)
			local c = x.clase and RAID_CLASS_COLORS and RAID_CLASS_COLORS[x.clase]
			b:SetStatusBarColor(c and c.r or 0.5, c and c.g or 0.5, c and c.b or 0.5)
			b.texto:SetText(("%s  %s%s"):format(x.nombre, Med.Corto(x.total), x.porSeg and (" (" .. Med.Corto(x.porSeg) .. "/s)") or ""))
			b:Show()
		elseif i == 1 and not s then
			b:SetValue(0); b.texto:SetText(motivo or ""); b:Show()
		else b:Hide() end
	end
	local vistas = 0
	for i = 1, 8 do if filas[i] and filas[i]:IsShown() then vistas = i end end
	v:SetHeight(16 + vistas * 14)
	v:Show()
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "DAMAGE_METER_COMBAT_SESSION_UPDATED", "DAMAGE_METER_RESET", "PLAYER_REGEN_ENABLED", "PLAYER_LOGIN" }) do M.Escuchar(f, e) end
f:SetScript("OnEvent", function() M.Proteger("medidor", Med.Dibujar) end)
M.AlCambiar(function() M.Proteger("medidor", Med.Dibujar) end)

function Med.Reiniciar()
	if Med.Disponible() and DM().ResetAllCombatSessions then pcall(DM().ResetAllCombatSessions) end
	Med.Dibujar()
end
