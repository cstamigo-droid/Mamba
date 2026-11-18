-- Asistente_Clase: lógica pura (sin llamadas al juego, se prueba con lupa).
--   C.Builds(clase, rol)              -> builds de la clase para ese rol (o todas)
--   C.Reparto(clase, rangos)          -> "19/0/8" en el orden de los árboles del juego
--   C.Comparar(clase, build, rangos)  -> qué coincide, qué falta, qué sobra y el próximo punto
--   C.Consejo(nivel, cmp, doble)      -> qué hacer: seguir, esperar al 40, doble especialización o reiniciar
--   C.Roles(clase)                    -> roles que puede cumplir y cómo cambiar de uno a otro
-- rangos = { [nodo del árbol] = rango }. El nodo es el mismo en todos los idiomas del juego.
-- Nada de esto cambia talentos: solo aconseja. Cambiar talentos lo hace el jugador.
-- Licencia: GPL-3.0-only. Autor: Cristian Amigo.
local _, ns = ...
local C = ns.Clase or {}
ns.Clase = C

C.PRIMER_NIVEL = 10      -- el primer punto llega al nivel 10 (DRUIDA.md)
C.NIVEL_DOBLE = 40       -- doble especialización desde el 40 (Blizzard, 15-10-2026)
C.PUNTOS_60 = 51

C.ROLES = { sanar = "sanar", danio = "daño", tanque = "tanque", jcj = "JcJ (PvP)" }
C.USOS = { subir = "para subir de nivel", mazmorra = "mazmorras al 60", jcj = "JcJ al 60", banda = "bandas al 60" }

local function datos(clase) return ns.BUILDS and ns.BUILDS[clase] end

function C.Builds(clase, rol, uso)
	local d, out = datos(clase), {}
	if not d then return out end
	for _, b in ipairs(d.builds) do
		-- "subir" no es un rol sino un uso: /clase builds subir muestra las builds para subir de nivel
		local okRol = not rol or b.rol == rol or (rol == "subir" and b.uso == "subir")
		if okRol and (not uso or b.uso == uso) then out[#out + 1] = b end
	end
	return out
end

function C.BuildPorClave(clase, clave)
	for _, b in ipairs(C.Builds(clase)) do
		if b.clave == clave then return b end
	end
end

function C.Reparto(clase, rangos)
	local d = datos(clase)
	if not d then return nil end
	local tot = {}
	for i = 1, #d.specs do tot[i] = 0 end
	for nodo, r in pairs(rangos) do
		local t = d.talentos[nodo]
		if t and r > 0 then tot[t.col] = tot[t.col] + r end
	end
	return table.concat(tot, "/"), tot
end

-- Especialización principal: el árbol con más puntos. -> nombre del árbol (inglés) | nil si no hay puntos
function C.SpecPrincipal(clase, rangos)
	local d = datos(clase)
	local _, tot = C.Reparto(clase, rangos or {})
	if not (d and tot) then return nil end
	local mejor, idx = 0, nil
	for i, v in ipairs(tot) do if v > mejor then mejor, idx = v, i end end
	return idx and d.specs[idx]
end

-- Rangos finales de una build: { [nodo] = rango }
function C.Final(build)
	local f = {}
	for _, nodo in ipairs(build.picks) do f[nodo] = (f[nodo] or 0) + 1 end
	return f
end

-- Compara lo que el jugador tiene con una build.
-- -> { coinciden, faltan = { {nodo, tengo, quiero} }, sobran = { {nodo, tengo, quiero} },
--      puntosFuera (puntos puestos fuera de la build), gastados, siguiente (índice del próximo
--      punto de la build), nivelSiguiente }
function C.Comparar(clase, build, rangos)
	local final = C.Final(build)
	local cmp = { coinciden = 0, faltan = {}, sobran = {}, puntosFuera = 0, gastados = 0 }
	for nodo, r in pairs(rangos) do
		if r > 0 then
			cmp.gastados = cmp.gastados + r
			local quiero = final[nodo] or 0
			if r > quiero then
				cmp.sobran[#cmp.sobran + 1] = { nodo, r, quiero }
				cmp.puntosFuera = cmp.puntosFuera + (r - quiero)
			end
			cmp.coinciden = cmp.coinciden + math.min(r, quiero)
		end
	end
	for nodo, quiero in pairs(final) do
		local tengo = rangos[nodo] or 0
		if tengo < quiero then cmp.faltan[#cmp.faltan + 1] = { nodo, tengo, quiero } end
	end
	-- el próximo punto: el primero de la build que todavía no se tiene
	local cuenta = {}
	for i, nodo in ipairs(build.picks) do
		cuenta[nodo] = (cuenta[nodo] or 0) + 1
		if (rangos[nodo] or 0) < cuenta[nodo] then
			cmp.siguiente = i
			cmp.nivelSiguiente = C.PRIMER_NIVEL + i - 1
			break
		end
	end
	local orden = function(a, b) return a[1] < b[1] end
	table.sort(cmp.faltan, orden)
	table.sort(cmp.sobran, orden)
	return cmp
end

-- Qué conviene hacer. doble: true = la doble especialización ya está abierta,
-- false = todavía no, nil = el addon no lo pudo leer del juego.
-- -> { accion = "seguir" | "esperar40" | "doble" | "reiniciar" | "nada", texto }
-- El costo de reiniciar está NO VERIFICADO (DRUIDA.md §1): el consejo nunca da una cifra.
function C.Consejo(nivel, cmp, doble)
	local fuera = cmp.puntosFuera or 0
	if fuera == 0 then
		if #cmp.faltan == 0 then return { accion = "nada", texto = "Ya tienes esta build completa." } end
		return { accion = "seguir", texto = "Vas bien: no tienes puntos fuera de esta build. Pon los que te faltan en el orden que te muestro." }
	end
	if nivel >= C.NIVEL_DOBLE then
		if doble == false then
			return { accion = "doble", texto = string.format("Tienes %d puntos fuera de esta build. No reinicies: desbloquea la doble especialización con tu instructor (nivel 40; el precio no está confirmado por Blizzard) y arma esta build en la segunda, que viene vacía.", fuera) }
		end
		return { accion = "doble", texto = string.format("Tienes %d puntos fuera de esta build. Usa tu segunda especialización para esta build en vez de reiniciar la principal. Si ya usas las dos para otra cosa, reinicia solo la que menos uses (costo NO VERIFICADO: míralo en el instructor).", fuera) }
	end
	if nivel >= C.NIVEL_DOBLE - 3 then
		return { accion = "esperar40", texto = string.format("Tienes %d puntos fuera de esta build, pero te faltan %d niveles para la doble especialización. No pagues un reinicio: sigue con lo que tienes y al 40 arma esta build en la segunda especialización.", fuera, C.NIVEL_DOBLE - nivel) }
	end
	if fuera >= 5 then
		return { accion = "reiniciar", texto = string.format("Tienes %d puntos fuera de esta build y faltan %d niveles para la doble especialización. Reiniciar puede valer la pena, pero el costo NO está verificado: pregúntalo al instructor antes. Si no quieres gastar, sigue y al 40 usa la doble especialización.", fuera, C.NIVEL_DOBLE - nivel) }
	end
	return { accion = "seguir", texto = string.format("Solo %d puntos fuera de esta build: no vale la pena reiniciar. Sigue con la build desde aquí.", fuera) }
end

function C.Roles(clase)
	local d = datos(clase)
	return d and d.roles
end

-- Qué equipo pide cada rol. Regla general del juego clásico; en Forever NO VERIFICADO.
-- El detalle (qué pieza, de dónde) es del asesor de equipo, no de este módulo.
local EQUIPO = {
	sanar = "equipo de sanación: intelecto, espíritu y poder de sanación",
	tanque = "equipo de tanque: aguante, armadura y defensa (escudo si tu clase lo usa)",
	danio = "equipo de daño: fuerza o agilidad si pegas cuerpo a cuerpo; intelecto y daño de hechizos si lanzas hechizos",
	jcj = "equipo de JcJ: más aguante que en mazmorras",
}

-- Pasos para pasar a un rol. -> lista de textos (el primero dice si se puede)
function C.PasosCambio(clase, rol, nivel)
	local d = datos(clase)
	if not d then return { "Tu clase no está en los datos." } end
	local r = d.roles
	local specs = (rol == "jcj") and d.specs or r[rol]
	if not specs then return { "Rol desconocido. Usa: sanar, danio, tanque o jcj." } end
	if #specs == 0 then
		return { "Tu clase no puede " .. (C.ROLES[rol] or rol) .. ". " .. (r.nota or "") }
	end
	local pasos = { string.format("Para %s usa: %s.", C.ROLES[rol] or rol, table.concat(specs, " o ")) }
	local b = C.Builds(clase, rol, rol == "jcj" and "jcj" or "mazmorra")[1] or C.Builds(clase, rol)[1]
	if b then
		pasos[#pasos + 1] = string.format("1) Talentos: la build %s (%s). Mírala con /clase build %s.", b.clave, b.reparto, b.clave)
	end
	if nivel >= C.NIVEL_DOBLE then
		pasos[#pasos + 1] = "2) Ponla en tu segunda especialización (doble especialización, desde el 40) para no pagar reinicios; cambias entre las dos cuando quieras."
	else
		pasos[#pasos + 1] = string.format("2) Te faltan %d niveles para la doble especialización (40). Antes de eso, cambiar de rol es reiniciar talentos con el instructor (costo NO VERIFICADO).", C.NIVEL_DOBLE - nivel)
	end
	pasos[#pasos + 1] = "3) Equipo: " .. (EQUIPO[rol] or "") .. " (regla general; NO VERIFICADO en Forever). Guarda un juego por rol en el banco o en las bolsas."
	pasos[#pasos + 1] = "4) Barras: los hechizos cambian entre roles. Blizzard arregló el 13-11 que las barras se borraran al salir con talentos secundarios (news.blizzard.com/en-us/article/24315281). Si se te desordenan, revísalas al cambiar."
	if clase == "DRUID" then
		pasos[#pasos + 1] = "Druida: el rol también cambia con la forma: oso para tanquear, gato para daño, lechúcico para daño a distancia, sin forma para sanar."
	end
	return pasos
end
