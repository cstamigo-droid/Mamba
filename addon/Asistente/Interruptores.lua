-- K124 (regla de Cristian, 19-11): «todas las ventanas, marcos, avisos y automatismos de Mamba tienen que poder
-- encenderse y apagarse desde Opciones, sin comandos». Aquí está el registro único y la sección que los junta:
-- Ajustes › Mamba › «Qué se muestra», la primera pestaña, con un interruptor por cosa, agrupados.
--
-- Cada módulo publica el suyo, sin que este archivo toque su código:
--   MambaAPI.Interruptor({
--     id     = "combate.dano",            -- único, "modulo.cosa"
--     nombre = "Medidor de daño",         -- lo que lee el jugador
--     grupo  = "Combate",                 -- el título del bloque donde va (ver GRUPOS)
--     addon  = "Mamba_Combate",           -- la carpeta del addon que lo publica (la prueba K124 lo exige)
--     ayuda  = "Qué hace, en una línea.", -- opcional
--     get    = function() return true end,      -- ¿está encendido? -> boolean
--     set    = function(encendido) ... end,     -- lo enciende o lo apaga Y lo aplica en el momento
--   })  -> true | false, motivo
-- Si el módulo se carga antes que Asistente, deja el spec en _G.MambaInterruptoresPendientes (una lista) y
-- Asistente lo registra al cargarse.
-- MambaAPI.Interruptores() -> copia de la lista { id, nombre, grupo, addon, ayuda } en orden.
local A = _G.Asistente
local API = _G.MambaAPI

local PAGINA, PESTANA = "Mamba", "Qué se muestra"
-- Orden de los bloques; un grupo que no está aquí va al final, en el orden en que llegó.
local GRUPOS = { "Ventanas y botones", "Combate", "Avisos", "Mapa", "Misiones", "Objetos y subasta", "Bolsas y venta",
	"Barras", "Oro", "Ciudad", "Errores" }
local ordenGrupo = {}
for i, g in ipairs(GRUPOS) do ordenGrupo[g] = i end

local lista, porId = {}, {}

-- Los interruptores que ya están dibujados en Ajustes se repintan (revisor t9: el mismo ajuste también se cambia
-- desde la ventana de Mamba, y el dibujado quedaba viejo). Solo los de estado (sin clave de Polestar).
function A.RefrescarAjustes()
	local P = _G.Polestar
	local O = P and P.UI and P.UI.Options
	local v = O and O.view
	for _, w in pairs(v and v.cache or {}) do
		if w.psControl and not w.psControl.key and w.Refresh then pcall(w.Refresh, w) end
	end
end

-- Los bloques en el orden de GRUPOS (revisor t9): Polestar ordena las secciones por la primera vez que llegan,
-- así que se declaran todas aquí, vacías (Polestar no dibuja una sección sin controles).
do
	local P = _G.Polestar
	if P and P.RegisterOptions then
		for _, g in ipairs(GRUPOS) do
			pcall(P.RegisterOptions, { page = PAGINA, tab = PESTANA, lead = true, section = g, controls = {} })
		end
	end
end

local function aPolestar(x)
	local P = _G.Polestar
	if not (P and P.RegisterOptions) then return false end
	local ok, err = P.RegisterOptions({ page = PAGINA, tab = PESTANA, lead = true, section = x.grupo, controls = {
		{ kind = "toggle", label = x.nombre, help = x.ayuda,
			get = function()
				local ok2, v = pcall(x.get)
				return ok2 and v and true or false
			end,
			set = function(v)
				local ok2, e = pcall(x.set, v and true or false)
				if not ok2 and geterrorhandler then geterrorhandler()(e) end
				-- la ventana de Mamba muestra algunos de los mismos interruptores (Capa, Servicios)
				if A.Hub and A.Hub.Redibujar then A.Hub.Redibujar() end
			end },
	} })
	if not ok and geterrorhandler then geterrorhandler()(err) end
	return ok
end

function API.Interruptor(spec)
	if type(spec) ~= "table" then return false, "Interruptor: spec debe ser una tabla" end
	local id = spec.id
	if type(id) ~= "string" or id == "" then return false, "Interruptor: falta id" end
	if porId[id] then return false, "Interruptor: id repetido " .. id end
	if type(spec.nombre) ~= "string" or spec.nombre == "" then return false, "Interruptor(" .. id .. "): falta nombre" end
	if type(spec.addon) ~= "string" or spec.addon == "" then return false, "Interruptor(" .. id .. "): falta addon" end
	if type(spec.get) ~= "function" or type(spec.set) ~= "function" then
		return false, "Interruptor(" .. id .. "): get y set deben ser funciones"
	end
	local x = { id = id, nombre = spec.nombre, grupo = type(spec.grupo) == "string" and spec.grupo ~= "" and spec.grupo or "Otros",
		addon = spec.addon, ayuda = type(spec.ayuda) == "string" and spec.ayuda or nil, get = spec.get, set = spec.set, seq = #lista + 1 }
	lista[#lista + 1] = x
	porId[id] = x
	aPolestar(x)
	return true
end

function API.Interruptores()
	local out = {}
	for _, x in ipairs(lista) do
		out[#out + 1] = { id = x.id, nombre = x.nombre, grupo = x.grupo, addon = x.addon, ayuda = x.ayuda }
	end
	table.sort(out, function(a, b)
		local ga, gb = ordenGrupo[a.grupo] or 99, ordenGrupo[b.grupo] or 99
		if ga ~= gb then return ga < gb end
		return porId[a.id].seq < porId[b.id].seq
	end)
	return out
end

-- Para la prueba de carga completa (K124: el contrato de cada get/set). No es para los módulos.
function API._InterruptoresCrudos() return lista end

-- ¿encendido? (para la ventana de Mamba y las pruebas) -> boolean | nil si no existe
function API.InterruptorEncendido(id)
	local x = porId[id]
	if not x then return nil end
	local ok, v = pcall(x.get)
	return ok and v and true or false
end

-- Los que llegaron antes que Asistente.
local pend = _G.MambaInterruptoresPendientes
if type(pend) == "table" then
	for _, spec in ipairs(pend) do
		local ok, err = API.Interruptor(spec)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	end
end
_G.MambaInterruptoresPendientes = nil

---------------------------------------------------------------- los de Asistente
local function propio(spec)
	spec.addon = "Asistente"
	local ok, err = API.Interruptor(spec)
	if not ok and geterrorhandler then geterrorhandler()(err) end
end

propio({ id = "ventana.boton", nombre = "Botón de Mamba en el minimapa", grupo = "Ventanas y botones",
	ayuda = "El botón redondo del borde del minimapa que abre la ventana de Mamba.",
	get = function() return A.BotonMinimapaVisible() end, set = function(v) A.FijarBotonMinimapa(v) end })

propio({ id = "ventana.serpiente", nombre = "Serpiente animada en el encabezado", grupo = "Ventanas y botones",
	ayuda = "La mamba negra que rodea el título de la ventana. Solo se mueve con la ventana abierta.",
	get = function() return A.Serpiente.Encendida() and true or false end, set = function(v) A.Serpiente.Fijar(v) end })

propio({ id = "capa.cuadro", nombre = "Cuadro de la capa en pantalla", grupo = "Ciudad",
	ayuda = "El cuadrito que dice en qué capa del mundo estás.",
	get = function() return A.Ajuste("capa", "mostrar") and true or false end,
	set = function(v) A.FijarAjuste("capa", "mostrar", v); if A.Capa and A.Capa.Pintar then A.Capa.Pintar() end end })

propio({ id = "capa.aviso", nombre = "Aviso al cambiar de capa", grupo = "Avisos",
	ayuda = "Un mensaje cuando el juego te pasa a otra capa del mundo.",
	get = function() return A.Ajuste("capa", "avisar") and true or false end,
	set = function(v) A.FijarAjuste("capa", "avisar", v) end })

propio({ id = "servicios.auto", nombre = "Abrir Servicios al entrar a una ciudad", grupo = "Ciudad",
	ayuda = "Al entrar a Orgrimmar, Cima del Trueno o Entrañas se abre sola la lista de servicios.",
	get = function() return A.Ajuste("servicios", "abrirAlEntrar") and true or false end,
	set = function(v) A.FijarAjuste("servicios", "abrirAlEntrar", v) end })
