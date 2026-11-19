-- Mamba_Plan: el estado del personaje (R6 de la hoja de ruta). Lo leen todos: nivel, clase, raza, bando, oro,
-- experiencia, profesiones con su habilidad, bolsas (casillas y ranuras vacías), puntos de talento por árbol y
-- hechizos que conoce. Solo lee: no cambia nada. Licencia: GPL-3.0-only.
local _, M = ...

local function seguro(fn, ...)
	if not fn then return end
	local r = { pcall(fn, ...) }
	if r[1] then return select(2, unpack(r)) end
end

local function profesiones()
	local out = {}
	if not (GetProfessions and GetProfessionInfo) then return out end
	local lista = { seguro(GetProfessions) }
	for i = 1, 6 do
		local idx = lista[i]
		if idx then
			local nombre, _, rango, maximo, _, _, linea = seguro(GetProfessionInfo, idx)
			if nombre then out[#out + 1] = { nombre = nombre, rango = rango or 0, max = maximo or 0, linea = linea, ranura = i } end
		end
	end
	return out
end

local function bolsas()
	local C = C_Container
	local b = { total = 0, libres = 0, ranuras = {}, vacias = 0 }
	if not (C and C.GetContainerNumSlots) then return b end
	for bolsa = 0, 4 do
		local n = seguro(C.GetContainerNumSlots, bolsa) or 0
		local libres = seguro(C.GetContainerNumFreeSlots, bolsa) or 0
		local id
		if bolsa > 0 then
			local inv = C.ContainerIDToInventoryID and seguro(C.ContainerIDToInventoryID, bolsa)
			id = inv and seguro(GetInventoryItemID, "player", inv)
			if not id then b.vacias = b.vacias + 1 end
		end
		b.ranuras[bolsa] = { casillas = n, libres = libres, item = id }
		b.total, b.libres = b.total + n, b.libres + libres
	end
	return b
end

local function talentos()
	local out = {}
	if not GetNumTalentTabs then return out end
	for t = 1, (seguro(GetNumTalentTabs) or 0) do
		local a, b, c, d, e = seguro(GetTalentTabInfo, t)
		-- según el cliente, los puntos vienen en el 3.º o el 5.º valor: el que sea número
		local puntos = (type(e) == "number" and e) or (type(c) == "number" and c) or 0
		out[t] = { nombre = (type(b) == "string" and b) or (type(a) == "string" and a) or "", puntos = puntos }
	end
	return out
end

function M.Conoce(hechizo)
	if IsPlayerSpell then
		local ok, r = pcall(IsPlayerSpell, hechizo)
		if ok and r then return true end
	end
	if IsSpellKnown then
		local ok, r = pcall(IsSpellKnown, hechizo)
		if ok and r then return true end
	end
	return false
end

function M.NombreHechizo(id)
	if C_Spell and C_Spell.GetSpellName then
		local ok, n = pcall(C_Spell.GetSpellName, id)
		if ok and n then return n end
	end
	if GetSpellInfo then
		local ok, n = pcall(GetSpellInfo, id)
		if ok and n then return n end
	end
end

function M.Estado()
	local e = {}
	e.nombre = UnitName("player")
	-- nivel, oro y exp pueden venir secretos en Forever (K110): `secreto or 0` da error; se leen como "no sé"
	local function legible(v) if issecretvalue and issecretvalue(v) then return nil end return v end
	e.nivel = legible(UnitLevel("player")) or 1
	e.claseNombre, e.clase = UnitClass("player")
	e.razaNombre, e.raza = UnitRace("player")
	e.bando = UnitFactionGroup and UnitFactionGroup("player") or "Horde"
	e.oro = legible(GetMoney and GetMoney()) or 0
	e.xp, e.xpMax = legible(UnitXP and UnitXP("player")) or 0, legible(UnitXPMax and UnitXPMax("player")) or 1
	e.profesiones = profesiones()
	e.bolsas = bolsas()
	e.talentos = talentos()
	e.equitacion = M.Conoce(33388) or M.Conoce(33391)
	return e
end

function M.Profesion(e, nombre)
	for _, p in ipairs(e.profesiones) do if p.nombre == nombre then return p end end
end
