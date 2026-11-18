-- Asistente: comandos del núcleo.
--   /asis              ayuda y módulos
--   /asis creditos     de dónde viene cada dato y cada pedazo de código
--   /servicios [texto] buscador de servicios de la ciudad (carga el módulo si hace falta)
-- Nota: "/asistente" lo usa hoy Asistente_Datos; pasa al núcleo cuando ese módulo se una al grupo
-- (ARQUITECTURA §9, paso 3).
-- Licencia: GPL-3.0-only.
local A = _G.Asistente

local MODULOS = {
	{ "Asistente_Servicios", "servicios", "buscador de servicios con flecha (/servicios)" },
	{ "Asistente_Datos", nil, "qué juntar en cada zona y plan de bolsas (/asistente)" },
	{ "Tasador", nil, "qué hacer con cada objeto (/tasador)" },
	{ "Medidor", nil, "experiencia, oro y profesión por hora (/medidor)" },
}

local function cargado(addon)
	return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(addon) and true or false
end

function A.Ayuda()
	A.Decir("versión " .. A.version .. ". Módulos:")
	for _, m in ipairs(MODULOS) do
		local estado = cargado(m[1]) and A.ColorOscuro("bueno", "cargado") or A.ColorOscuro("gris", "se carga cuando haga falta")
		A.Decir("  " .. m[1] .. ": " .. m[3] .. " · " .. estado)
	end
	A.Decir("/asis creditos: de dónde viene cada dato.")
end

function A.Creditos()
	A.Decir("Datos de PNJ y buzones: forever-db de Polestar (GPL-3.0). Sus fuentes: EG Link / Efficient Games (CC BY 4.0), CMaNGOS classic-db (GPL-3.0), VMaNGOS y Factoruide (GPL-2.0 o posterior), ForeverTDB (GPL-2.0), QuestieDB, pfQuest (MIT, Shagu) y las tablas del cliente.")
	A.Decir("Rutas a pie: Polestar Nav (GPL-3.0 o posterior), nacido de Shortest Path Forever de Cillian Berragan. Se usa si Polestar está instalado.")
	A.Decir("Nombres y títulos del juego: de Blizzard Entertainment. Este addon no está hecho ni respaldado por Blizzard.")
	A.Decir("Licencia de este addon: GPL-3.0. Gratis, sin publicidad.")
end

local function abrirServicios(texto)
	A.Cargar("Asistente_Servicios", function()
		local S = A.modulos.servicios
		if S and S.Comando then S.Comando(texto or "") end
	end)
end
A.AbrirServicios = abrirServicios

SLASH_ASISNUCLEO1 = "/asis"
SlashCmdList.ASISNUCLEO = function(arg)
	arg = (arg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if arg == "creditos" or arg == "créditos" then
		A.Creditos()
	elseif arg:find("^servicios") then
		abrirServicios(arg:gsub("^servicios%s*", ""))
	else
		A.Ayuda()
	end
end

SLASH_ASISSERVICIOS1 = "/servicios"
SLASH_ASISSERVICIOS2 = "/serv"
SlashCmdList.ASISSERVICIOS = function(arg)
	abrirServicios(arg)
end

-- /equipo, /clase y /mamba (18-11): abren la ventana de Mamba en su pestaña (Ventana.lua). Lo que se
-- escribe después del comando elige la sección: "/equipo mazmorras", "/clase builds"...
SLASH_ASISEQUIPO1 = "/equipo"
SlashCmdList.ASISEQUIPO = function(arg)
	A.AbrirVentana("equipo", arg)
end

SLASH_ASISCLASE1 = "/clase"
SlashCmdList.ASISCLASE = function(arg)
	A.AbrirVentana("clase", arg)
end

SLASH_ASISMAMBA1 = "/mamba"
SlashCmdList.ASISMAMBA = function(arg)
	arg = (arg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if arg == "boton" or arg == "botón" then
		A.AlternarBotonMinimapa()
	else
		A.AbrirVentana(arg ~= "" and arg or nil)
	end
end

-- Ajustes de los módulos en la ventana de ajustes de Polestar (Ajustes › Mamba), registrados aquí porque
-- Asistente se carga siempre: los módulos se cargan cuando hacen falta (Servicios, al entrar a una ciudad)
-- y su página tiene que estar desde el principio (ESTETICA_MAMBA.md, E5).
A.Defaults("servicios", { abrirAlEntrar = true })
A.Opciones("Servicios", "Buscador de servicios de la ciudad", {
	{ kind = "toggle", label = "Abrir la lista al entrar a una ciudad",
		help = "Al entrar a Orgrimmar, Cima del Trueno o Entrañas se abre esta lista. Lo mismo que /servicios auto si|no.",
		get = function() return A.Ajuste("servicios", "abrirAlEntrar") and true or false end,
		set = function(valor) A.FijarAjuste("servicios", "abrirAlEntrar", valor and true or false) end },
})
