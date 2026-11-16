-- Asistente: estilo visual común. Usa las plantillas y letras del propio juego (como Polestar),
-- para que todas las ventanas de todos los módulos se vean iguales y "del juego".
-- Licencia: GPL-3.0-only.
local A = _G.Asistente

-- Colores con significado fijo en todos los módulos (ARQUITECTURA §4).
A.COLOR = {
	titulo = "ffd100",     -- dorado del juego
	bueno = "40ff40",      -- recomendado
	dudoso = "ffff00",     -- dato sin verificar
	gris = "9d9d9d",       -- sin datos
	blanco = "ffffff",
}

function A.Color(nombre, texto)
	return "|cff" .. (A.COLOR[nombre] or "ffffff") .. tostring(texto) .. "|r"
end

-- Marca de confianza de cada dato (ALCANCE §2).
A.CONFIANZA = {
	fdb = "dato de forever-db",
	titulo = "por el título del PNJ, sin verificar",
	medido = "medido por ti",
}

-- ¿Juega con la interfaz de mando? (como Polestar, Core/Init.lua: la API manda; el CVar solo si no hay API)
function A.InterfazMando()
	local E = Enum and Enum.InputDeviceInterfaceType
	if not (E and E.Gamepad) then return false end
	local S = C_InputInterfaceStyle
	if S and S.GetCurrentStyle then return S.GetCurrentStyle() == E.Gamepad end
	local get = (C_CVar and C_CVar.GetCVar) or GetCVar
	return get and tonumber(get("InputDeviceInterfaceStyle")) == E.Gamepad or false
end

-- Marco hijo de un marco del juego: se crea SIN padre y después se cuelga. La interfaz de mando
-- intercepta CreateFrame con padre en el mapa y deja el mapa "contaminado" (taint), lo que bloquea
-- acciones. SetParent no se intercepta. (Mismo arreglo que Polestar: ns.CreateFrameUnder.)
function A.CrearMarcoBajo(tipo, nombre, padre, plantilla)
	local f = CreateFrame(tipo, nombre, nil, plantilla)
	if padre then f:SetParent(padre) end
	return f
end

-- Ventana estándar: borde, fondo y cruz del juego. Se puede mover y se acuerda de su lugar.
function A.CrearVentana(nombre, titulo, ancho, alto)
	local f = A.CrearMarcoBajo("Frame", nombre, UIParent, "BasicFrameTemplateWithInset")
	f:SetSize(ancho, alto)
	f:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
	f:SetFrameStrata("MEDIUM")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	-- la plantilla ya trae su título (TitleText): se usa ese, no uno encima
	f.titulo = f.TitleText or f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if not f.TitleText then f.titulo:SetPoint("TOP", f, "TOP", 0, -5) end
	f.titulo:SetText(titulo or "")
	-- se cierra con Escape; con interfaz de mando no (sus menús leen esa lista: Polestar, Core/Init.lua)
	if UISpecialFrames and not A.InterfazMando() then table.insert(UISpecialFrames, nombre) end
	f:Hide()
	return f
end
