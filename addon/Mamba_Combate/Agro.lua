-- Mamba_Combate: indicador de agro al acercarse (K123). Cristian, 19-11: "un indicador que diga cuando estás
-- atrayendo un enemigo… discreto… una barra que se comience a poner de verde a rojo cuando esté muy cerca… tiene
-- que poder orientar por dónde pasar sin atraer enemigos".
-- Cómo funciona (solo FUERA de combate y solo con bichos hostiles que atacan solos, no los neutrales amarillos):
--   1) Radio de agro de cada bicho, aproximación de Classic: unas 20 yardas si tiene tu nivel, más o menos 1 yarda
--      por nivel de diferencia, entre 5 y 45 (calavera: 45). NO VERIFICADO que Forever use la misma regla: es lo
--      que describen las guías de Classic; lo exacto lo decide el servidor.
--   2) Distancia: el juego no da coordenadas de enemigos. Se ACOTA con lo que sí deja medir: las distancias de
--      interacción (CheckInteractDistance: duelo ≈10 yd, seguir ≈28 yd; NO VERIFICADO en Forever) y el alcance
--      REAL de tus hechizos de ataque (C_Spell.IsSpellInRange con el alcance que da el juego). Queda un intervalo
--      «entre X e Y yardas». Qué sondas responden en Forever queda contado en diag.agro.
--   3) Dirección: dónde está la placa de nombre en la pantalla (izquierda, delante, derecha).
-- Se ve: una barrita fina bajo el personaje, verde → amarillo → rojo según el bicho más peligroso, con una marca
-- por cada bicho en su lado de la pantalla (por dónde está el peligro). Opcional: borde naranja en su placa.
-- Solo muestra. Licencia: GPL-3.0-only.
local _, M = ...
local Ag = {}
M.Agro = Ag

local ANCHO, ALTO, MARCAS = 220, 6, 8
local function leer(v) if v == nil or M.Secreto(v) then return nil end return v end

-- Radio de agro aproximado (yardas) según la diferencia de nivel.
function Ag.Radio(nivelBicho, nivelYo)
	nivelBicho, nivelYo = M.Num(nivelBicho), M.Num(nivelYo)
	if not (nivelBicho and nivelYo) then return nil end
	if nivelBicho == -1 then return 45 end
	return math.max(5, math.min(45, 20 + (nivelBicho - nivelYo)))
end

-- ¿Ataca solo? Hostil (reacción 1-3), se puede atacar, no es un jugador, vivo y fuera de combate.
function Ag.EsAgresivo(u)
	local r = UnitReaction and M.Num(UnitReaction(u, "player"))
	if not r or r > 3 then return false end
	if not (UnitCanAttack and M.Si(UnitCanAttack("player", u))) then return false end
	if UnitIsPlayer and M.Si(UnitIsPlayer(u)) then return false end
	if UnitIsDeadOrGhost and M.Si(UnitIsDeadOrGhost(u)) then return false end
	if UnitAffectingCombat and M.Si(UnitAffectingCombat(u)) then return false end -- ya pelea: no es «atraerlo»
	return true
end

---------------------------------------------------------------- sondas de distancia
local sondasHechizo -- { { nombre, alcance } } de tus hechizos de ataque, del más corto al más largo
function Ag.SondasHechizo()
	if sondasHechizo then return sondasHechizo end
	sondasHechizo = {}
	local vistos = {}
	local R = M.Rotacion
	local datos = R and R.Datos and R.Datos()
	for _, s in ipairs(datos and datos.specs or {}) do
		for _, caso in pairs(s.casos or {}) do
			for _, p in ipairs(caso.pasos or {}) do
				local id = p.h
				if id and not vistos[id] and M.Conoce(id) and C_Spell and C_Spell.GetSpellInfo then
					vistos[id] = true
					local ok, info = pcall(C_Spell.GetSpellInfo, id)
					local alc = ok and type(info) == "table" and M.Num(info.maxRange)
					local minimo = ok and type(info) == "table" and M.Num(info.minRange) or 0
					if minimo > 0 then alc = nil end -- con alcance mínimo, «fuera» puede ser «demasiado cerca»
					local dano = true
					if C_Spell.IsSpellHarmful then local okH, h = pcall(C_Spell.IsSpellHarmful, id); dano = not okH or M.Si(h) end
					-- uno por alcance (con varios plates y 4 veces por segundo, cada sonda cuenta)
					if dano and alc and alc > 0 and not vistos["r" .. alc] then
						vistos["r" .. alc] = true
						sondasHechizo[#sondasHechizo + 1] = { nombre = info.name, alcance = alc, id = id }
					end
				end
			end
		end
	end
	table.sort(sondasHechizo, function(a, b) return a.alcance < b.alcance end)
	return sondasHechizo
end
function Ag.Olvidar() sondasHechizo = nil end

local function diag()
	local d = M.DB().diag
	d.agro = d.agro or { interaccion = 0, interaccionNil = 0, hechizo = 0, hechizoNil = 0 }
	return d.agro
end

-- Intervalo de distancia { lo, hi } en yardas (hi = nil: más lejos que todo lo medible).
Ag.INTERACCION = { { 3, 9.9 }, { 2, 11.11 }, { 4, 28 } } -- índice de CheckInteractDistance → yardas (Classic)
function Ag.Distancia(u)
	local lo, hi = 0, nil
	local dg = diag()
	local function dato(cerca, yd)
		if cerca == true then if not hi or yd < hi then hi = yd end
		elseif cerca == false then if yd > lo then lo = yd end end
	end
	if CheckInteractDistance then
		for _, x in ipairs(Ag.INTERACCION) do
			local ok, v = pcall(CheckInteractDistance, u, x[1])
			if ok then v = leer(v) else v = nil end
			if v == nil then dg.interaccionNil = dg.interaccionNil + 1 else dg.interaccion = dg.interaccion + 1 end
			if v ~= nil then dato(v and true or false, x[2]) end
		end
	end
	if C_Spell and C_Spell.IsSpellInRange then
		for _, s in ipairs(Ag.SondasHechizo()) do
			local ok, v = pcall(C_Spell.IsSpellInRange, s.nombre, u)
			if ok then v = leer(v) else v = nil end
			if v == nil then dg.hechizoNil = dg.hechizoNil + 1 else dg.hechizo = dg.hechizo + 1 end
			if v ~= nil then dato((v == true or v == 1), s.alcance) end
		end
	end
	return lo, hi
end

-- Peligro de un bicho: "rojo" (seguro dentro de su radio), "amarillo" (puede estar dentro o a menos de 8 yd del
-- borde), "verde" (fuera) o nil (no se sabe). Devuelve también el radio y la distancia acotada.
function Ag.Peligro(u)
	local R = Ag.Radio(UnitLevel and UnitLevel(u), UnitLevel and UnitLevel("player"))
	if not R then return nil end
	local lo, hi = Ag.Distancia(u)
	if hi and hi <= R then return "rojo", R, lo, hi end
	if lo >= R then return "verde", R, lo, hi end      -- seguro fuera de su radio
	if hi == nil then return nil, R, lo, hi end         -- más lejos que todo lo medible, pero el radio es mayor: no se sabe
	return "amarillo", R, lo, hi                         -- puede estar dentro (entre lo y hi está el borde)
end

-- Lado de la pantalla de su placa: -1 (izquierda) … 0 (delante) … 1 (derecha), o nil.
function Ag.Lado(placa)
	if not (placa and placa.GetCenter and UIParent and UIParent.GetWidth) then return nil end
	local x = placa:GetCenter()
	x = M.Num(x)
	local w = M.Num(UIParent:GetWidth())
	if not (x and w and w > 0) then return nil end
	local s = (placa.GetEffectiveScale and M.Num(placa:GetEffectiveScale())) or 1
	local su = (UIParent.GetEffectiveScale and M.Num(UIParent:GetEffectiveScale())) or 1
	x = x * s / su
	return math.max(-1, math.min(1, (x - w / 2) / (w / 2)))
end

---------------------------------------------------------------- la barrita
local barra
local COLOR = { verde = { 0.25, 0.75, 0.3 }, amarillo = { 0.95, 0.8, 0.2 }, rojo = { 0.95, 0.2, 0.15 } }
function Ag.Crear()
	if barra then return barra end
	barra = CreateFrame("Frame", "MambaAgro", UIParent)
	barra:SetSize(ANCHO, ALTO + 10)
	barra:SetPoint("CENTER", UIParent, "CENTER", 0, -90)
	barra:Hide()
	barra.fondo = barra:CreateTexture(nil, "BACKGROUND")
	barra.fondo:SetPoint("LEFT", barra, "LEFT", 0, 0)
	barra.fondo:SetPoint("RIGHT", barra, "RIGHT", 0, 0)
	barra.fondo:SetHeight(ALTO)
	barra.fondo:SetColorTexture(0.05, 0.05, 0.06, 0.6)
	barra.color = barra:CreateTexture(nil, "ARTWORK")
	barra.color:SetAllPoints(barra.fondo)
	barra.marcas = {}
	for i = 1, MARCAS do
		local t = barra:CreateTexture(nil, "OVERLAY")
		t:SetSize(3, ALTO + 10)
		t:Hide()
		barra.marcas[i] = t
	end
	M.Movible(barra, "MambaAgro", "Indicador de agro")
	return barra
end
M.Precrear(function() Ag.Crear() end)
M.AlModoMover(function(activo)
	Ag.Crear()
	if activo then
		if not barra:IsShown() then barra.ejemplo = true; local c = COLOR.amarillo; barra.color:SetColorTexture(c[1], c[2], c[3], 0.6); barra:Show() end
	elseif barra.ejemplo then
		barra.ejemplo = nil
		barra:Hide()
	end
end)

local ORDEN = { verde = 1, amarillo = 2, rojo = 3 }
-- -> lista { { unidad, nivel, lado, radio, lo, hi } } de los que están amarillo o rojo, y el peor nivel
function Ag.Revisar()
	local lista, peor = {}, nil
	local N = C_NamePlate
	if not (N and N.GetNamePlates) then return lista, nil end
	for _, p in ipairs(N.GetNamePlates() or {}) do
		local u = p.namePlateUnitToken or (p.UnitFrame and p.UnitFrame.unit)
		local agresivo = u and Ag.EsAgresivo(u)
		if u and not agresivo and M.Placas and M.Placas.MarcarAgro then M.Placas.MarcarAgro(u, nil) end
		if agresivo then
			local nivel, R, lo, hi = Ag.Peligro(u)
			if nivel == "rojo" or nivel == "amarillo" then
				lista[#lista + 1] = { unidad = u, nivel = nivel, lado = Ag.Lado(p), radio = R, lo = lo, hi = hi }
				if not peor or ORDEN[nivel] > ORDEN[peor] then peor = nivel end
			end
			if M.Placas and M.Placas.MarcarAgro then M.Placas.MarcarAgro(u, M.DB().agroPlacas and nivel or nil) end
		end
	end
	table.sort(lista, function(a, b) return ORDEN[a.nivel] > ORDEN[b.nivel] end)
	return lista, peor
end

function Ag.LimpiarPlacas()
	local N = C_NamePlate
	if not (N and N.GetNamePlates and M.Placas and M.Placas.MarcarAgro) then return end
	for _, p in ipairs(N.GetNamePlates() or {}) do
		local u = p.namePlateUnitToken or (p.UnitFrame and p.UnitFrame.unit)
		if u then M.Placas.MarcarAgro(u, nil) end
	end
end

function Ag.Dibujar()
	Ag.Crear()
	if barra.ejemplo then return end
	local d = M.DB()
	if not d.agro or M.Si(M.EnCombate()) then barra:Hide(); Ag.ultimo = nil; Ag.LimpiarPlacas(); return end
	local lista, peor = Ag.Revisar()
	Ag.ultimo = { lista = lista, peor = peor }
	if not peor and not d.agroSiempre then barra:Hide(); return end
	local c = COLOR[peor or "verde"]
	barra.color:SetColorTexture(c[1], c[2], c[3], 0.75)
	for i, t in ipairs(barra.marcas) do
		local x = lista[i]
		if x and x.lado then
			local cm = COLOR[x.nivel]
			t:SetColorTexture(cm[1], cm[2], cm[3], 1)
			t:ClearAllPoints()
			t:SetPoint("CENTER", barra, "CENTER", x.lado * (ANCHO / 2 - 2), 0)
			t:Show()
		else t:Hide() end
	end
	barra:Show()
end
function Ag.Barra() return barra end

local f = CreateFrame("Frame")
M.Escuchar(f, "PLAYER_REGEN_DISABLED")
M.Escuchar(f, "PLAYER_LEVEL_UP")
M.Escuchar(f, "SPELLS_CHANGED")
f:SetScript("OnEvent", function(_, ev)
	if ev == "PLAYER_REGEN_DISABLED" then if barra then barra:Hide() end return end
	Ag.Olvidar() -- hechizos nuevos: otras sondas
end)
local acum = 0
f:SetScript("OnUpdate", function(_, dt)
	acum = acum + (dt or 0)
	if acum < 0.25 then return end -- cuatro veces por segundo basta para caminar
	acum = 0
	if not M.DB().agro then if barra and barra:IsShown() and not barra.ejemplo then barra:Hide() end return end
	M.Proteger("agro", Ag.Dibujar)
end)
