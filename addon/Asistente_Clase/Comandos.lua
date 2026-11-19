-- Asistente_Clase: el asesor según tu clase. Solo da consejos en el chat; nunca cambia talentos,
-- equipo ni barras (eso lo hace el jugador).
--   /clase                 resumen: roles, profesiones y builds de tu clase
--   /clase prof [árbol]    profesiones para subir, mazmorras, JcJ y oro (con fuentes). Sin árbol,
--                          usa el árbol donde tienes más puntos
--   /clase builds [rol]    builds de tu clase (rol: sanar, danio, tanque, jcj, subir)
--   /clase build <clave>   orden nivel por nivel de una build
--   /clase revisar <clave> compara tus talentos con esa build y dice qué cambiar
--   /clase rol <rol>       qué hacer para cambiar a ese rol
-- Licencia: GPL-3.0-only.
local _, ns = ...
local A = _G.Asistente
local C = ns.Clase
local M = {}

-- C.salida: la ventana de Mamba la pone mientras arma la sección «Clase» (las líneas van a la ventana, no al chat).
local function decir(t)
	if C.salida then C.salida(t) return end
	if A and A.Decir then A.Decir(t) elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(t) end
end
C.decir = decir

local CREDITO = "Data from ForeverDB.net (https://foreverdb.net)."
local MOTIVOS = {
	sinclase = "tu clase no está en los datos del addon",
	sinapi = "el juego no dio acceso a los talentos",
	sinconfig = "el juego todavía no tiene tus talentos cargados; abre la ventana de talentos y prueba otra vez",
	sinnodos = "el juego no reconoció ningún talento: puede que el árbol haya cambiado y el addon necesite datos nuevos",
}

local function fuentes(ids)
	local out = {}
	for _, id in ipairs(ids or {}) do
		local f = ns.FUENTES_PROF[id]
		if f then out[#out + 1] = f[1] .. " (" .. f[3] .. ") " .. f[2] end
	end
	return table.concat(out, " · ")
end

local function specDe(clase, build)
	local d = ns.BUILDS[clase]
	return d and d.specs[build.spec]
end

local function lineaBuild(clase, b)
	return string.format("%s · %s · %s · %s%s", b.clave, specDe(clase, b) or "?", C.USOS[b.uso] or b.uso, b.reparto,
		b.ordenDeLaGuia and "" or " (orden armado por el addon)")
end

local function fuenteBuild(b)
	local f = b.fuente
	return string.format("Fuente: %s, %s, %s. %s", f.nombre, f.autor or "sin autor", f.fecha, f.url)
end

function M.Profesiones(clase, spec)
	local P = ns.PROFESIONES
	if spec then decir("Consejo para tu árbol: " .. spec .. " (cámbialo con /clase prof <árbol>).") end
	decir("Profesiones (12): " .. table.concat(P.primarias, ", ") .. " · secundarias: " .. table.concat(P.secundarias, ", ") .. ". " .. P.notaLista)
	for _, uso in ipairs({ "subir", "mazmorra", "jcj", "oro" }) do
		local par, por, f = C.Profesiones(clase, uso, spec)
		if par then
			decir(string.format("%s: %s + %s. %s Según: %s", uso == "oro" and "para ganar oro" or C.USOS[uso], par[1], par[2], por, fuentes(f)))
		end
	end
	local c = P.clases[clase]
	if c and c.desacuerdo then decir("No coinciden: " .. c.desacuerdo) end
	decir(P.notaOro)
	local _, raza = UnitRace("player")
	local r = raza and C.BonoRaza(raza)
	if r then decir("Tu raza: " .. r.bono .. (r.verificado and "" or " (NO VERIFICADO)")) end
	decir(P.notaGeneral)
end

-- "/clase prof feral" -> "Feral Combat" (el nombre del árbol en inglés, o su comienzo)
function M.SpecPedida(clase, texto)
	texto = (texto or ""):lower()
	if texto == "" then return nil end
	for _, s in ipairs(ns.BUILDS[clase] and ns.BUILDS[clase].specs or {}) do
		if s:lower():sub(1, #texto) == texto then return s end
	end
end

function M.Builds(clase, rol)
	local lista = C.Builds(clase, rol)
	if #lista == 0 then decir("No hay builds para ese rol en tu clase.") return end
	for _, b in ipairs(lista) do decir(lineaBuild(clase, b)) end
	decir(CREDITO)
	decir("Escribe /clase build <clave> para el orden, o /clase revisar <clave> para compararla con tus talentos.")
end

function M.Build(clase, clave)
	local b = C.BuildPorClave(clase, clave)
	if not b then decir("No conozco esa build. Mira /clase builds.") return end
	decir(lineaBuild(clase, b) .. ". " .. (b.nota or ""))
	decir(fuenteBuild(b))
	-- el orden en tramos: "10-14 Talento x5"
	local i, n = 1, #b.picks
	while i <= n do
		local nodo, j = b.picks[i], i
		while j < n and b.picks[j + 1] == nodo do j = j + 1 end
		local nivel = C.PRIMER_NIVEL + i - 1
		local tramo = (j > i) and (nivel .. "-" .. (C.PRIMER_NIVEL + j - 1)) or tostring(nivel)
		decir(string.format("  %s: %s +%d", tramo, C.NombreTalento(clase, nodo), j - i + 1))
		i = j + 1
	end
	for _, o in ipairs(b.otras or {}) do
		decir(string.format("Otra guía: %s dice %s (%s) %s", o.nombre, o.reparto, o.fecha, o.url))
	end
	decir(CREDITO)
end

function M.Revisar(clase, clave)
	local b = C.BuildPorClave(clase, clave)
	if not b then decir("No conozco esa build. Mira /clase builds.") return end
	local rangos, motivo = C.LeerTalentos(clase)
	if not rangos then decir("No pude leer tus talentos: " .. (MOTIVOS[motivo] or tostring(motivo)) .. ".") return end
	local nivel = C.MiNivel()
	local cmp = C.Comparar(clase, b, rangos)
	decir(string.format("Tus talentos: %s · build %s: %s.", C.Reparto(clase, rangos), b.clave, b.reparto))
	for _, s in ipairs(cmp.sobran) do
		decir(string.format("  Sobra: %s %d de %d (la build pide %d)", C.NombreTalento(clase, s[1]), s[2], ns.BUILDS[clase].talentos[s[1]].max, s[3]))
	end
	local c = C.Consejo(nivel, cmp, C.TieneDoble())
	decir(c.texto)
	if cmp.siguiente then
		local prox = {}
		for k = cmp.siguiente, math.min(#b.picks, cmp.siguiente + 4) do prox[#prox + 1] = C.NombreTalento(clase, b.picks[k]) end
		decir("Próximos puntos de la build (desde el nivel " .. cmp.nivelSiguiente .. "): " .. table.concat(prox, ", "))
	end
	decir("Cambiar talentos lo haces tú en la ventana de talentos; el addon no toca nada.")
	decir(CREDITO)
end

function M.Rol(clase, rol)
	for _, paso in ipairs(C.PasosCambio(clase, rol, C.MiNivel())) do decir(paso) end
end

function M.Resumen(clase)
	local d = ns.BUILDS[clase]
	if not d then decir("Tu clase no está en los datos.") return end
	local r = d.roles
	local function l(t) return #t > 0 and table.concat(t, ", ") or "no" end
	decir(string.format("Tu clase puede: sanar (%s) · daño (%s) · tanque (%s). %s", l(r.sanar), l(r.danio), l(r.tanque), r.nota or ""))
	decir(string.format("%d builds. Comandos: /clase prof · /clase builds [sanar|danio|tanque|jcj|subir] · /clase rol <rol> · /clase revisar <clave>", #d.builds))
end

-- El comando /clase lo define el núcleo (Asistente/Comandos.lua): carga este módulo y llama aquí.
function M.Comando(arg)
	local clase = C.MiClase()
	arg = (arg or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local cmd, resto = arg:match("^(%S*)%s*(.-)$")
	cmd = (cmd or ""):lower()
	if cmd == "prof" or cmd == "profesiones" then
		local spec = M.SpecPedida(clase, resto)
		if not spec then
			local rangos = C.LeerTalentos(clase)
			spec = rangos and C.SpecPrincipal(clase, rangos)
		end
		M.Profesiones(clase, spec)
	elseif cmd == "builds" then
		M.Builds(clase, resto ~= "" and resto:lower() or nil)
	elseif cmd == "build" then
		M.Build(clase, resto)
	elseif cmd == "revisar" then
		M.Revisar(clase, resto)
	elseif cmd == "rol" then
		M.Rol(clase, resto:lower())
	else
		M.Resumen(clase)
	end
end

-- La ventana de Mamba: M.Salida(fn) manda las líneas a fn (nil: al chat otra vez). M.Datos: las tablas.
function M.Salida(fn) C.salida = fn end
-- Las fuentes de los consejos de profesiones (Datos_Profesiones.lua), para las tarjetas de la ventana.
function M.FuentesProf() return ns.FUENTES_PROF end
M.C = C
-- El nombre de la especialización de una build (b.spec es una clave de ns.BUILDS[clase].specs).
function C.NombreSpec(clase, spec)
	local d = ns.BUILDS[clase]
	return d and d.specs and d.specs[spec] or nil
end
ns.ComandosClase = M
if A and A.Registrar then A.Registrar("clase", M) end
