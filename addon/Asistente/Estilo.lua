-- Asistente: estilo visual común de los módulos de Mamba.
-- REGLA DE ESTÉTICA (WOW_FOREVER/ESTETICA_MAMBA.md): cada ventana y cada texto de un módulo nuestro se
-- dibuja con las piezas de Polestar (Theme y Widgets), así toma la apariencia que el jugador eligió en
-- Polestar (las 9 apariencias, el esquema de color, la letra y su tamaño) y cambia junto con ella. Si
-- Polestar no está cargado (pruebas sueltas, o un jugador que lo apagó) se usan las plantillas del juego.
-- Las funciones internas de Polestar que se usan aquí las vigila tools/asistente/generador/polestar_al_dia.py.
-- Licencia: GPL-3.0-only.
local A = _G.Asistente

-- Polestar y sus piezas de dibujo, o nada si no están (o son de una versión sin estas funciones).
function A.Polestar()
	local P = _G.Polestar
	local T, W = P and P.Theme, P and P.Widgets
	if T and W and T.Skin and T.Band and T.BandCoords and T.Hex and T.OnChanged and W.Text and W.IconButton
		and W.SearchBox and W.Hover and W.Tooltip and P.DragWindow and P.CloseOnEscape then
		return P, T, W
	end
end

-- Colores con significado fijo en todos los módulos (ARQUITECTURA §4). Sin Polestar, estos; con Polestar,
-- el color de la apariencia elegida (TOKEN), para que el dorado sea el acento de su apariencia.
A.COLOR = {
	titulo = "ffd100",     -- dorado del juego
	bueno = "40ff40",      -- recomendado
	dudoso = "ffff00",     -- dato sin verificar
	gris = "9d9d9d",       -- sin datos
	blanco = "ffffff",
}
local TOKEN = { titulo = "accent", bueno = "success", dudoso = "warning", gris = "textMuted", blanco = "text" }

-- Dónde va el texto decide el color (docs/DESIGN.md de Polestar, "Theme.TipColor"):
--   A.Color(nombre, texto)        en una ventana de Mamba: el color de la apariencia sobre su fondo;
--   A.ColorOscuro(nombre, texto)  en el cuadro de ayuda o en el chat, que tienen SIEMPRE fondo oscuro:
--                                 Polestar aclara el color hasta que se lea (una apariencia clara como
--                                 Vellum tiene tinta casi negra, que ahí no se vería).
local function hexDe(r, g, b)
	local f = function(x) return math.floor((x or 1) * 255 + 0.5) end
	return string.format("ff%02x%02x%02x", f(r), f(g), f(b))
end
function A.Color(nombre, texto, fondo)
	local _, T = A.Polestar()
	local tok = TOKEN[nombre]
	if T and tok then
		local ok, hex
		if fondo == "oscuro" and T.TipColor then
			local r, g, b
			ok, r, g, b = pcall(T.TipColor, tok)
			hex = ok and r and hexDe(r, g, b)
		else
			ok, hex = pcall(T.Hex, tok)
		end
		if ok and hex then return "|c" .. hex .. tostring(texto) .. "|r" end
	end
	return "|cff" .. (A.COLOR[nombre] or "ffffff") .. tostring(texto) .. "|r"
end
function A.ColorOscuro(nombre, texto) return A.Color(nombre, texto, "oscuro") end

-- fn() cada vez que Polestar repinta (cambio de apariencia, esquema, acento, brillo o letra). Un texto con
-- A.Color lleva el color DENTRO del texto: el módulo lo vuelve a escribir aquí para que cambie al instante.
function A.AlCambiarApariencia(fn)
	local _, T = A.Polestar()
	if T then T.OnChanged(fn) end
end

-- Cuadro de ayuda al pasar el ratón: el de Polestar (W.Tooltip: colores de la apariencia) o el del juego.
-- lineas: textos; se pueden colorear con A.Color.
function A.CuadroAyuda(dueno, titulo, lineas)
	local _, _, W = A.Polestar()
	if W then return W.Tooltip(dueno, "ANCHOR_RIGHT", titulo, lineas) end
	if not (GameTooltip and GameTooltip.SetOwner) then return end
	GameTooltip:SetOwner(dueno, "ANCHOR_RIGHT")
	GameTooltip:AddLine(titulo or "")
	for _, l in ipairs(lineas or {}) do GameTooltip:AddLine(l) end
	GameTooltip:Show()
end

function A.OcultarAyuda()
	if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
end

-- Lugar guardado de cada ventana (AsistenteDB.ventanas[nombre] = { izquierda, arriba }).
local function lugar(nombre)
	local db = _G.AsistenteDB
	return db and db.ventanas and db.ventanas[nombre]
end
local function guardarLugar(nombre, f)
	local db = _G.AsistenteDB
	if not (db and f.GetLeft and f:GetLeft() and f:GetTop()) then return end
	db.ventanas = db.ventanas or {}
	db.ventanas[nombre] = { f:GetLeft(), f:GetTop() }
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

-- Medidas de la ventana de Polestar (UI/Copy.lua): cabecera con la banda de estrellas, márgenes.
local CABEZA, MARGEN = 56, 24

-- Ventana de un módulo como las de Polestar: fondo y borde de la apariencia elegida, banda de estrellas
-- con el título, cruz para cerrar, se arrastra por la cabecera, se cierra con Escape y se acuerda de su
-- lugar. f.cuerpo = cuánto baja la cabecera (el contenido empieza ahí); f.margen = margen lateral.
-- f.abiertaSola = true cuando se abrió sin que el jugador la pidiera (con mando no le quita el foco).
function A.CrearVentana(nombre, titulo, ancho, alto)
	local P, T, W = A.Polestar()
	local f
	if P then
		-- Bajo UIParent, no bajo la capa de Polestar: una ventana que el jugador pidió se ve aunque haya
		-- escondido Polestar.
		f = CreateFrame("Frame", nombre, UIParent)
		f:SetSize(ancho, alto)
		local l = lugar(nombre)
		if l then f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l[1], l[2]) else f:SetPoint("CENTER", UIParent, "CENTER", 300, 0) end
		f:SetFrameStrata("MEDIUM")
		f:SetToplevel(true)
		f:SetClampedToScreen(true)
		f:SetMovable(true)
		f:EnableMouse(true)
		T.Skin(f, "window")
		local cab = CreateFrame("Frame", nil, f)
		cab:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
		cab:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
		cab:SetHeight(CABEZA)
		P.DragWindow(cab, f, { onStop = function(v) guardarLugar(nombre, v) end })
		f.cabeza = cab
		f.banda = T.Band(cab, "BACKGROUND", -5)
		f.banda:SetAllPoints(cab)
		f.banda:SetTexCoord(T.BandCoords(ancho - 2, CABEZA))
		if W.Haze then W.Haze(cab, { width = ancho * 0.9, height = CABEZA }) end
		if W.Rim then W.Rim(f, { width = ancho * 0.7 }) end
		f.cerrar = W.IconButton(cab, "close", 28, CLOSE or "Cerrar", function() f:Hide() end, 14)
		f.cerrar:SetPoint("TOPRIGHT", cab, "TOPRIGHT", -12, -14)
		if W.FrameClose then W.FrameClose(f, f.cerrar) end
		f.titulo = W.Text(cab, "title", "text")
		f.titulo:SetPoint("LEFT", cab, "LEFT", MARGEN, 0)
		f.titulo:SetPoint("RIGHT", f.cerrar, "LEFT", -8, 0)
		f.cuerpo, f.margen, f.polestar = CABEZA, MARGEN, true
		P.CloseOnEscape(nombre)
		if P.Gamepad and P.Gamepad.Register then P.Gamepad.Register(f, { unasked = function() return f.abiertaSola end }) end
	else
		f = A.CrearMarcoBajo("Frame", nombre, UIParent, "BasicFrameTemplateWithInset")
		f:SetSize(ancho, alto)
		local l = lugar(nombre)
		if l then f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l[1], l[2]) else f:SetPoint("CENTER", UIParent, "CENTER", 300, 0) end
		f:SetFrameStrata("MEDIUM")
		f:SetClampedToScreen(true)
		f:SetMovable(true)
		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); guardarLugar(nombre, self) end)
		-- la plantilla ya trae su título (TitleText): se usa ese, no uno encima
		local tt = type(f.TitleText) == "table" and f.TitleText or nil
		f.titulo = tt or f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		if not tt then f.titulo:SetPoint("TOP", f, "TOP", 0, -5) end
		f.cuerpo, f.margen = 26, 16
		-- se cierra con Escape; con interfaz de mando no (sus menús leen esa lista: Polestar, Core/Init.lua)
		if UISpecialFrames and not A.InterfazMando() then table.insert(UISpecialFrames, nombre) end
	end
	f.titulo:SetText(titulo or "")
	f:Hide()
	return f
end

-- Texto con la letra y el color de la apariencia. rol: el de Polestar (title, heading, body, label, note,
-- small, number); color: un color de la apariencia (text, textDim, textMuted, accent, success, warning).
local PLANTILLA = { title = "GameFontNormal", heading = "GameFontNormal", body = "GameFontHighlight",
	label = "GameFontHighlightSmall", note = "GameFontDisableSmall", small = "GameFontHighlightSmall",
	number = "GameFontHighlightSmall" }
function A.Texto(padre, rol, color)
	local _, _, W = A.Polestar()
	if W then return W.Text(padre, rol or "body", color or "text") end
	local fs = padre:CreateFontString(nil, "OVERLAY", PLANTILLA[rol or "body"] or "GameFontHighlight")
	fs:SetJustifyH("LEFT")
	return fs
end

-- Caja de búsqueda: la de Polestar (lupa, texto de ayuda, cruz para borrar, borde del acento al escribir)
-- o la del juego. alCambiar(texto) con cada letra; alEnter(caja) al apretar Enter.
function A.Buscador(padre, ayuda, alCambiar, alEnter)
	local _, _, W = A.Polestar()
	local e
	if W then
		e = W.SearchBox(padre, ayuda, function(t) if alCambiar then alCambiar(t or "") end end)
	else
		e = A.CrearMarcoBajo("EditBox", nil, padre, "InputBoxTemplate")
		e:SetHeight(20)
		e:SetAutoFocus(false)
		e:SetScript("OnTextChanged", function(self) if alCambiar then alCambiar(self:GetText() or "") end end)
		e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	end
	e:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		if alEnter then alEnter(self) end
	end)
	return e
end

-- Fila que se puede apretar, con el resaltado al pasar el ratón de la apariencia.
function A.Fila(padre, ancho, alto)
	local _, _, W = A.Polestar()
	local b = A.CrearMarcoBajo("Button", nil, padre)
	b:SetSize(ancho, alto)
	if W then W.Hover(b) else b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD") end
	return b
end

-- Ajustes de un módulo en la ventana de ajustes de Polestar (página "Mamba", una pestaña por módulo), no
-- en una ventana aparte. controles: los de Polestar (toggle, slider, dropdown, button), con get/set.
-- Sin Polestar no hay ventana: el ajuste sigue por su comando de chat.
function A.Opciones(pestana, seccion, controles)
	local P = _G.Polestar
	if not (P and P.RegisterOptions) then return false end
	local ok, err = P.RegisterOptions({ page = "Mamba", tab = pestana, section = seccion, controls = controles })
	if not ok and geterrorhandler then geterrorhandler()(err) end
	return ok
end
