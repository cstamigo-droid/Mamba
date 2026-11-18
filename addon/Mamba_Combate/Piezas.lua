-- Mamba (copia de Mamba_Plan/Piezas.lua): piezas de ajuste dibujadas con Polestar (las filas de su ventana de ajustes: interruptor,
-- deslizador, desplegable y botón), así se ven igual que Ajustes de Polestar y cambian con la apariencia.
-- TODO(estética E4): estas piezas van en addon/Asistente/Estilo.lua (dueña: la sesión de la ventana de
-- Mamba); mientras tanto viven aquí, con el mismo contrato, para pasarlas tal cual.
-- Sin Polestar (solo pruebas) se usan las plantillas del juego. Licencia: GPL-3.0-only.
local _, M = ...
local P = {}
M.Piezas = P

local function polestar()
	local Ps = _G.Polestar
	local T, W = Ps and Ps.Theme, Ps and Ps.Widgets
	if T and W and W.Toggle and W.Slider and W.Dropdown and W.Button and W.LayoutRow then return Ps, T, W end
end
P.Polestar = polestar

local function A() return _G.Asistente end

function P.Texto(padre, rol, color)
	local a = A()
	if a and a.Texto then return a.Texto(padre, rol, color) end
	local fs = padre:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	fs:SetJustifyH("LEFT")
	return fs
end

-- Toda ventana de Mamba se mueve y se acuerda de su lugar por personaje (fila K55): MambaAPI.Movible de la
-- ventana de Mamba, que respeta el candado de Ajustes › Mamba › Ventanas. La ventana ya se arrastra sola.
local function movible(f, nombre)
	local api = _G.MambaAPI
	if f and api and api.Movible then pcall(api.Movible, f, nombre, nil, { yaArrastra = true }) end
	return f
end

function P.Ventana(nombre, titulo, ancho, alto)
	local a = A()
	if a and a.CrearVentana then return movible(a.CrearVentana(nombre, titulo, ancho, alto), nombre) end
	local f = CreateFrame("Frame", nombre, UIParent, "BasicFrameTemplateWithInset")
	f:SetSize(ancho, alto)
	f:SetPoint("CENTER")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f.titulo = f.TitleText or f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.titulo:SetText(titulo)
	f.cuerpo, f.margen = 26, 16
	f:Hide()
	return movible(f, nombre)
end

-- Fila con interruptor. get() -> bool; set(bool)
function P.Interruptor(padre, etiqueta, ayuda, get, set)
	local _, _, W = polestar()
	if W then return W.Toggle(padre, etiqueta, nil, ayuda, nil, { get = get, set = set }) end
	local c = CreateFrame("CheckButton", nil, padre, "UICheckButtonTemplate")
	c.text = c.Text or c.text
	if c.text then c.text:SetText(etiqueta) end
	c.Refresh = function(self) self:SetChecked(get() and true or false) end
	c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
	c:Refresh()
	return c
end

-- Fila con deslizador. formato: "%d" o "%d %%"
function P.Deslizador(padre, etiqueta, ayuda, min, max, paso, formato, get, set)
	local _, _, W = polestar()
	if W then return W.Slider(padre, etiqueta, nil, min, max, paso, formato, ayuda, nil, { get = get, set = set }) end
	local s = CreateFrame("Slider", nil, padre, "OptionsSliderTemplate")
	s:SetMinMaxValues(min, max)
	s:SetValueStep(paso)
	s:SetObeyStepOnDrag(true)
	s.Refresh = function(self) self:SetValue(get()) end
	s:SetScript("OnValueChanged", function(_, v, usuario) if usuario then set(v) end end)
	s:Refresh()
	return s
end

-- Fila con desplegable. opciones = { { value = ..., text = "..." }, ... }
function P.Desplegable(padre, etiqueta, ayuda, opciones, get, set)
	local _, _, W = polestar()
	if W then return W.Dropdown(padre, etiqueta, nil, opciones, ayuda, nil, { get = get, set = set }) end
	-- sin Polestar: un botón que va pasando por las opciones
	local b = CreateFrame("Button", nil, padre, "UIPanelButtonTemplate")
	b:SetSize(200, 22)
	b.Refresh = function(self)
		local v = get()
		for _, o in ipairs(opciones) do if o.value == v then self:SetText(etiqueta .. ": " .. o.text) end end
	end
	b:SetScript("OnClick", function(self)
		local v, i = get(), 1
		for j, o in ipairs(opciones) do if o.value == v then i = j end end
		set(opciones[i % #opciones + 1].value)
		self:Refresh()
	end)
	b:Refresh()
	return b
end

function P.Boton(padre, texto, alClic, principal)
	local _, _, W = polestar()
	if W then
		local b = W.Button(padre, texto, alClic, { primary = principal })
		b:SetWidth(math.max(90, (b.Label and b.Label:GetStringWidth() or 60) + 28))
		return b
	end
	local b = CreateFrame("Button", nil, padre, "UIPanelButtonTemplate")
	b:SetText(texto)
	b:SetSize(math.max(90, (b:GetFontString() and b:GetFontString():GetStringWidth() or 60) + 24), 24)
	b:SetScript("OnClick", alClic)
	return b
end

-- Ancho de una fila de ajuste (las de Polestar se acomodan a él); devuelve el alto.
function P.Acomodar(fila, ancho)
	local _, _, W = polestar()
	if W and (fila.psRow or fila.psSpan) then return W.LayoutRow(fila, ancho) end
	fila:SetWidth(ancho)
	return math.max(fila:GetHeight(), 26)
end

-- Una fila de la lista de la izquierda (con el resaltado de la apariencia).
function P.Fila(padre, ancho, alto)
	local a = A()
	if a and a.Fila then return a.Fila(padre, ancho, alto) end
	local b = CreateFrame("Button", nil, padre)
	b:SetSize(ancho, alto)
	b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
	return b
end

-- Relleno de color de la apariencia (marca de la barra elegida, rejilla del modo mover).
function P.Relleno(padre, token, capa)
	local _, _, W = polestar()
	if W and W.Fill then return W.Fill(padre, token, capa or "BACKGROUND") end
	local t = padre:CreateTexture(nil, capa or "BACKGROUND")
	t:SetAllPoints(padre)
	t:SetColorTexture(1, 0.82, 0, 0.15)
	return t
end

function P.Linea(padre, vertical)
	local _, _, W = polestar()
	if W and W.Divider then return W.Divider(padre, vertical, 0.5) end
	local t = padre:CreateTexture(nil, "BACKGROUND")
	t:SetColorTexture(1, 1, 1, 0.12)
	if vertical then t:SetWidth(1) else t:SetHeight(1) end
	return t
end

function P.Color(nombre, texto)
	local a = A()
	if a and a.Color then return a.Color(nombre, texto) end
	return texto
end
