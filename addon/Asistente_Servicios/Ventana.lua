-- Asistente_Servicios: la ventana "¿Qué hay en esta ciudad?" y los comandos.
--   /servicios               abre la lista de la ciudad donde estás
--   /servicios <texto>       busca: "banco", "alquimia", "instructor de druida", "reparar"...
--                            si hay un solo resultado, la flecha te lleva directo
--   /servicios parar         quita la flecha y las marcas
--   /servicios auto si|no    abrir (o no) la lista al entrar a una ciudad
-- Licencia: GPL-3.0-only.
local _, ns = ...
local S = ns.S
local A = _G.Asistente

if A then A.Defaults("servicios", { abrirAlEntrar = true }) end

local FILAS = 14
local ALTO_FILA = 22
local v              -- la ventana
local grupos, vistos = {}, {}
local desplaza = 0
S.ciudadActual = nil

local function claseJugador()
	if not UnitClass then return nil end
	local _, token = UnitClass("player")
	return token
end

local function texto()
	return v and v.buscar and v.buscar:GetText() or ""
end

---------------------------------------------------------------- elegir un grupo
-- Elige el más cercano del grupo y arranca la flecha.
function S.Elegir(g)
	if not (g and g.mejor and S.ciudadActual) then return end
	S.IrA(g.mejor, S.ciudadActual, g.etiqueta)
	local donde = g.mejor.titulo and (g.mejor.nombre .. " <" .. g.mejor.titulo .. ">") or g.mejor.nombre
	local aviso = g.conf == "titulo" and (" " .. A.Color("dudoso", "(" .. A.CONFIANZA.titulo .. ")")) or ""
	A.Decir(g.etiqueta .. ": " .. donde .. ", " .. S.TextoDistancia(g.mejor.dist) .. ". Sigue la flecha." .. aviso)
end

---------------------------------------------------------------- lista
function S.Refrescar()
	local x, y = S.PosicionJugador()
	local todos = S.Grupos(S.ciudadActual, claseJugador(), x, y) or {}
	grupos = todos
	vistos = S.Buscar(todos, texto())
	desplaza = math.max(0, math.min(desplaza, #vistos - FILAS))
	if not v then return vistos end
	for i = 1, FILAS do
		local fila, g = v.filas[i], vistos[i + desplaza]
		if g then
			fila.g = g
			fila.icono:SetTexture(S.CAT[g.cat].icono)
			local n = #g.lugares > 1 and A.Color("gris", " (" .. #g.lugares .. ")") or ""
			local dudoso = g.conf == "titulo" and A.Color("dudoso", " *") or ""
			local color = (g.cat == "clase" and not g.tuya) and "gris" or "blanco"
			fila.texto:SetText(A.Color(color, g.etiqueta) .. n .. dudoso)
			fila.dist:SetText(A.Color("gris", S.TextoDistancia(g.mejor.dist)))
			fila:Show()
		else
			fila.g = nil
			fila:Hide()
		end
	end
	local pie = ""
	if #vistos == 0 then
		pie = "Nada con \"" .. texto() .. "\" aquí."
		local q = S.Normal(texto())
		for token, nombre in pairs(S.CLASES) do
			if q ~= "" and q:find(S.Normal(nombre), 1, true) then
				local en = S.CiudadConClase(token)
				if #en > 0 then pie = "No hay instructor de " .. nombre .. " aquí. Está en: " .. table.concat(en, ", ") .. "." end
			end
		end
	else
		pie = "* = reparar, deducido del título del PNJ (sin verificar)."
	end
	S.ultimoPie = pie
	v.pie:SetText(A.Color("gris", pie))
	return vistos
end

local function crear()
	if v then return v end
	v = A.CrearVentana("AsistenteServiciosVentana", "Servicios", 320, 120 + FILAS * ALTO_FILA)
	v.buscar = A.CrearMarcoBajo("EditBox", nil, v, "InputBoxTemplate")
	v.buscar:SetSize(220, 20)
	v.buscar:SetPoint("TOPLEFT", v, "TOPLEFT", 18, -32)
	v.buscar:SetAutoFocus(false)
	v.buscar:SetScript("OnTextChanged", function() desplaza = 0; S.Refrescar() end)
	v.buscar:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		if #vistos >= 1 then S.Elegir(vistos[1]) end
	end)
	v.buscar:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	local ayuda = v:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	ayuda:SetPoint("LEFT", v.buscar, "RIGHT", 8, 0)
	ayuda:SetText("buscar")
	v.filas = {}
	for i = 1, FILAS do
		local b = A.CrearMarcoBajo("Button", nil, v)
		b:SetSize(288, ALTO_FILA)
		b:SetPoint("TOPLEFT", v, "TOPLEFT", 14, -58 - (i - 1) * ALTO_FILA)
		b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
		b.icono = b:CreateTexture(nil, "ARTWORK")
		b.icono:SetSize(18, 18)
		b.icono:SetPoint("LEFT", 2, 0)
		b.texto = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		b.texto:SetPoint("LEFT", b.icono, "RIGHT", 6, 0)
		b.texto:SetJustifyH("LEFT")
		b.dist = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		b.dist:SetPoint("RIGHT", -4, 0)
		b:SetScript("OnClick", function(self) if self.g then S.Elegir(self.g) end end)
		b:SetScript("OnEnter", function(self)
			if not (self.g and GameTooltip and GameTooltip.SetOwner) then return end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(self.g.etiqueta)
			for k, l in ipairs(self.g.lugares) do
				if k > 6 then break end
				GameTooltip:AddLine(l.nombre .. (l.titulo and (" <" .. l.titulo .. ">") or "") .. "  " .. S.TextoDistancia(l.dist), 1, 1, 1)
			end
			GameTooltip:AddLine(A.CONFIANZA[self.g.conf] or "", 0.6, 0.6, 0.6)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() if GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end end)
		v.filas[i] = b
	end
	v:EnableMouseWheel(true)
	v:SetScript("OnMouseWheel", function(_, delta)
		desplaza = math.max(0, math.min(desplaza - delta * 3, #vistos - FILAS))
		S.Refrescar()
	end)
	v.pie = v:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	v.pie:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", 16, 12)
	v.pie:SetWidth(290)
	v.pie:SetJustifyH("LEFT")
	return v
end

function S.Abrir(uiMap)
	S.ciudadActual = uiMap or S.ciudadActual
	local c = S.datos and S.datos.ciudades and S.datos.ciudades[S.ciudadActual]
	if not c then
		A.Decir("Aquí no hay lista de servicios. Por ahora: Orgrimmar, Cima del Trueno y Entrañas.")
		return false
	end
	crear()
	local nombre = (C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(S.ciudadActual) or {}).name or c.nombre
	v.titulo:SetText("Servicios de " .. nombre)
	v:Show()
	S.Refrescar()
	return true
end

---------------------------------------------------------------- lo que llama el núcleo
function S.AlEntrar(uiMap)
	-- llegó tarde (se entró en combate): solo si sigues en esa ciudad
	if A.MapaActual() ~= uiMap then return end
	S.ciudadActual = uiMap
	if A.EnCombate() or not A.Ajuste("servicios", "abrirAlEntrar") then return end
	S.Abrir(uiMap)
end

function S.Comando(arg)
	arg = S.Normal(arg)
	if arg == "parar" or arg == "quitar" then
		S.Detener(false)
		A.Decir("Flecha y marcas quitadas.")
		return
	end
	local auto = arg:match("^auto%s+(%S+)")
	if auto then
		A.FijarAjuste("servicios", "abrirAlEntrar", auto == "si")
		A.Decir("Abrir la lista al entrar a una ciudad: " .. (auto == "si" and "sí" or "no") .. ".")
		return
	end
	local m = A.MapaActual()
	if m then S.ciudadActual = S.datos.ciudades[m] and m or nil end
	if not S.Abrir(S.ciudadActual) then return end
	if arg ~= "" then
		v.buscar:SetText(arg)
		local r = S.Refrescar()
		if #r == 1 then S.Elegir(r[1]) elseif #r == 0 then A.Decir(S.ultimoPie) end
	end
end

if A then A.Registrar("servicios", S) end
