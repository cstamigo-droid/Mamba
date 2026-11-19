-- Asistente_Clase/Arbol.lua: la lógica del planificador visual de talentos (K109), sin dibujar nada.
--   C.NombreBuild(clase, b)            -> "Restauración · mazmorras al 60" (+ " (Leprestore)" si hay dos iguales)
--   C.NombreCortoBuild(clase, b)       -> "Restauración · mazmorras", diferencia ("Leprestore" | "tanque" | nil)
--   C.NombreSpecES(nombre)             -> "Restauración"  (el árbol en español)
--   C.PuntosHasta(b, nivel)            -> cuántos puntos de la build hay al nivel dado (el primero al 10)
--   C.RangosHasta(b, n)                -> { [nodo] = rango } con los n primeros puntos
--   C.PorArbol(clase, rangos)          -> { puntos del árbol 1, 2, 3 }
--   C.RepartoEnPalabras(clase, rangos) -> "11 en Equilibrio y 40 en Restauración"
--   C.Estado(final, mios, nodo)        -> "bien" | "sobra" | "falta" | nil, y el texto de la insignia
--   C.PorQue(clase, b, nodo, nombreDe) -> { lineas } : por qué esta build toma ese talento (sale de los datos:
--                                         nivel, flechas, fila más honda), o que no lo toma
--   C.Arbol(clase)                     -> ns.ARBOL[clase] (Datos_Arbol.lua)
-- Solo aconseja: no cambia talentos. Licencia: GPL-3.0-only.
local _, ns = ...
local C = ns.Clase
local format = string.format

C.SPEC_ES = {
	["Balance"] = "Equilibrio", ["Feral Combat"] = "Combate feral", ["Restoration"] = "Restauración",
	["Beast Mastery"] = "Dominio de bestias", ["Marksmanship"] = "Puntería", ["Survival"] = "Supervivencia",
	["Arcane"] = "Arcano", ["Fire"] = "Fuego", ["Frost"] = "Escarcha",
	["Holy"] = "Sagrado", ["Protection"] = "Protección", ["Retribution"] = "Reprensión",
	["Discipline"] = "Disciplina", ["Shadow"] = "Sombra",
	["Assassination"] = "Asesinato", ["Combat"] = "Combate", ["Subtlety"] = "Sutileza",
	["Elemental"] = "Elemental", ["Enhancement"] = "Mejora",
	["Affliction"] = "Aflicción", ["Demonology"] = "Demonología", ["Destruction"] = "Destrucción",
	["Arms"] = "Armas", ["Fury"] = "Furia",
}
C.CLASE_ES = { DRUID = "Druida", HUNTER = "Cazador", MAGE = "Mago", PALADIN = "Paladín", PRIEST = "Sacerdote",
	ROGUE = "Pícaro", SHAMAN = "Chamán", WARLOCK = "Brujo", WARRIOR = "Guerrero" }
C.CLASES = { "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }
local USO_LARGO = { subir = "para subir de nivel", mazmorra = "mazmorras al 60", jcj = "JcJ al 60", banda = "bandas al 60" }
local USO_CORTO = { subir = "subir de nivel", mazmorra = "mazmorras", jcj = "JcJ", banda = "bandas" }
local ROL_ES = { sanar = "sanar", danio = "daño", tanque = "tanque", jcj = "JcJ" }

function C.Arbol(clase) return ns.ARBOL and ns.ARBOL[clase] end

function C.NombreSpecES(nombre) return C.SPEC_ES[nombre] or nombre end

-- El nombre del autor o sitio, corto: "ForeverDB 'Restoration: ...' (propósito: healing)" -> "ForeverDB"
function C.FuenteCorta(b)
	local n = b.fuente and b.fuente.nombre or ""
	n = n:gsub("%s*%(.*$", ""):gsub("%s+'.*$", ""):gsub(",.*$", ""):gsub("%s+y%s+.*$", "")
	if n:find("^Polestar") then return "Polestar" end
	return n ~= "" and n or nil
end

-- Lo que diferencia a una build de otra con el mismo árbol y el mismo uso: el rol si cambia, si no la fuente.
local function diferencia(clase, b)
	local d = ns.BUILDS[clase]
	local mismos = {}
	for _, x in ipairs(d and d.builds or {}) do
		if x.spec == b.spec and x.uso == b.uso then mismos[#mismos + 1] = x end
	end
	if #mismos < 2 then return nil end
	local roles = {}
	for _, x in ipairs(mismos) do roles[x.rol] = (roles[x.rol] or 0) + 1 end
	if roles[b.rol] == 1 then return ROL_ES[b.rol] or b.rol end
	return C.FuenteCorta(b)
end

function C.NombreBuild(clase, b)
	local d = ns.BUILDS[clase]
	local spec = C.NombreSpecES(d and d.specs[b.spec] or "?")
	local t = spec .. " · " .. (USO_LARGO[b.uso] or b.uso or "")
	local dif = diferencia(clase, b)
	return dif and (t .. " (" .. dif .. ")") or t
end

function C.NombreCortoBuild(clase, b)
	local d = ns.BUILDS[clase]
	local spec = C.NombreSpecES(d and d.specs[b.spec] or "?")
	return spec .. " · " .. (USO_CORTO[b.uso] or b.uso or ""), diferencia(clase, b)
end

function C.PuntosHasta(b, nivel)
	local n = (nivel or 60) - C.PRIMER_NIVEL + 1
	if n < 0 then n = 0 end
	if n > #b.picks then n = #b.picks end
	return n
end

function C.RangosHasta(b, n)
	local r = {}
	for i = 1, math.min(n or #b.picks, #b.picks) do
		local nodo = b.picks[i]
		r[nodo] = (r[nodo] or 0) + 1
	end
	return r
end

function C.PorArbol(clase, rangos)
	local A, t = C.Arbol(clase), { 0, 0, 0 }
	if not A then return t end
	for nodo, r in pairs(rangos or {}) do
		local n = A.nodos[nodo]
		if n then t[n[2]] = (t[n[2]] or 0) + r end
	end
	return t
end

function C.RepartoEnPalabras(clase, rangos)
	local A = C.Arbol(clase)
	local t, out = C.PorArbol(clase, rangos), {}
	for i, p in ipairs(t) do
		if p > 0 then out[#out + 1] = p .. " en " .. C.NombreSpecES(A and A.specs[i] or "?") end
	end
	if #out == 0 then return "sin puntos" end
	if #out == 1 then return out[1] end
	return table.concat(out, ", ", 1, #out - 1) .. " y " .. out[#out]
end

-- Comparar un talento: quiero = lo que pide la build; tengo = lo que tiene el jugador.
-- -> "bien" (tienes lo que pide, o parte), "sobra" (puntos que la build no pide), "falta" (la build lo pide y no
--    tienes ninguno) o nil (nadie lo usa); y la insignia: "3/5", "+2", "-3".
function C.Estado(final, mios, nodo)
	local quiero, tengo = final[nodo] or 0, mios[nodo] or 0
	if tengo > quiero then return "sobra", "+" .. (tengo - quiero) end
	if tengo > 0 then return "bien", tengo .. "/" .. quiero end
	if quiero > 0 then return "falta", "-" .. quiero end
	return nil, nil
end

-- Por qué la build toma este talento. Todo sale de los datos (cuándo, qué abre, qué tan hondo): no se inventa
-- una opinión. nombreDe(nodo) -> el nombre del talento en el idioma del juego.
function C.PorQue(clase, b, nodo, nombreDe)
	local A = C.Arbol(clase)
	local n = A and A.nodos[nodo]
	if not n then return {} end
	nombreDe = nombreDe or function(x) local m = A.nodos[x]; return m and m[7] or tostring(x) end
	local primero, ultimo, puestos = nil, nil, 0
	for i, x in ipairs(b.picks) do
		if x == nodo then
			primero = primero or i
			ultimo = i
			puestos = puestos + 1
		end
	end
	local out = {}
	if not primero then
		out[1] = "Esta build no lo toma."
		return out
	end
	local nv1, nv2 = C.PRIMER_NIVEL + primero - 1, C.PRIMER_NIVEL + ultimo - 1
	out[#out + 1] = (puestos == 1 and format("Esta build le pone 1 punto, al nivel %d.", nv1))
		or format("Esta build le pone %d de %d puntos, del nivel %d al %d.", puestos, n[5], nv1, nv2)
	local final = C.Final(b)
	local razones = {}
	for _, f in ipairs(A.flechas or {}) do
		if f[1] == nodo and final[f[2]] then
			razones[#razones + 1] = format("Abre %s, que esta build también toma (la flecha).", nombreDe(f[2]))
		end
	end
	local hondo = 0
	for x in pairs(final) do
		local m = A.nodos[x]
		if m and m[2] == n[2] and m[3] > hondo then hondo = m[3] end
	end
	if n[3] == hondo and hondo >= 5 then
		razones[#razones + 1] = format("Es lo más hondo que toma en %s: para llegar aquí pide %d puntos en ese árbol.",
			C.NombreSpecES(A.specs[n[2]]), A.pide[nodo] or 0)
	end
	if primero <= 5 then
		razones[#razones + 1] = "Es de lo primero que toma: ayuda desde el nivel 10."
	end
	if #razones == 0 then
		razones[1] = format("Suma puntos en %s: cada 5 puntos se abre la fila siguiente del árbol.", C.NombreSpecES(A.specs[n[2]]))
	end
	for _, r in ipairs(razones) do out[#out + 1] = r end
	return out
end
