-- Mamba_Panel/Panel.lua: las líneas de Mamba DENTRO del panel de la guía de Polestar (K56), en su flujo y con sus
-- piezas: van después de «De camino» y antes de «A continuación», con el mismo divisor, el mismo rótulo chico y
-- filas como las de «De camino» (ícono de verbo + texto). Sin marco encima: Polestar las apila como una parte
-- más ("mamba") por el parche P9 (UI/GuideFrameLayout.lua llama a Polestar.UI.MambaLineas).
-- Cada fila: el qué; debajo, atenuado, la puntuación (K62) y el cómo (K61); a la derecha, su botón: «Llévame»
-- (la flecha), «Guía» (pestaña nueva, K57) o «Ver». Clic derecho: Llévame, Abrir guía en otra pestaña, Hecho,
-- No me interesa. El rótulo abre y cierra la lista; su clic derecho filtra «solo lo que puedo hacer solo».
-- Dirección de arte (skill direccion-de-arte, 18-11): la ventana es de Polestar y manda su estética; el único
-- gesto propio es una marca vertical de 2 px en el verde oliva de «Mamba» (el del encabezado, K63) junto al rótulo.
-- El acento del tema va solo en el botón de cada fila.
-- Licencia: GPL-3.0-only.
local _, N = ...
local floor, max, min = math.floor, math.max, math.min

local OLIVA = { 0.55, 0.62, 0.42 } -- el de f.MambaMarca (Theme/Widgets.lua)
local VISIBLES = 4 -- filas a la vista; el resto, en Mi plan
local BOTON_W = 58

local function PS() local p = _G.Polestar; return type(p) == "table" and p or nil end
local function W() local p = PS(); return p and p.Widgets end
local function Theme() local p = PS(); return p and p.Theme end

local cont, cab, filas = nil, nil, {}
N.lineas = {}

---------------------------------------------------------------- acciones de una línea
local function verAlgo(l)
	local M, API = _G.MambaPlan, _G.MambaAPI
	if l.ver == "macro" and M and M.CrearMacro then return pcall(M.CrearMacro, l.macro) end
	if (l.ver == "dinero" or l.ver == "farmeo") and M and M.AbrirPlan then return pcall(M.AbrirPlan, l.ver) end
	if (l.ver == "subasta" or l.ver == "vender") and API and API.Abrir then return pcall(API.Abrir, "MambaSubasta") end
	if M and M.AbrirPlan then return pcall(M.AbrirPlan, "ahora") end
end

-- El botón de la fila: lo que más acerca a cumplirla (K61).
function N.Accion(l)
	if l.tramo then return nil end -- un tramo del viaje en curso: se lee, no se hace
	if l.accion then return l.accion[1], l.accion[2] end -- un aviso con su propio botón (K103: «Publicar»)
	if l.llevar then return "Llévame", function() pcall(l.llevar) end end
	if l.lugar or (l.destino and N.PuedeLlevar()) then return "Llévame", function() N.Llevame(l) end end
	if l.guia then return "Guía", function() N.AbrirGuiaDe(l) end end
	if l.ver == "macro" then return "Crear", function() verAlgo(l) end end
	return "Ver", function() verAlgo(l) end
end

local function menuDe(r)
	local l = r.psLinea
	local w = W()
	if not (l and w and w.ShowMenu) or l.tramo then return end
	local items = {}
	if l.llevar then items[#items + 1] = { text = "Llévame", icon = "icon-goto", onClick = function() pcall(l.llevar) end } end
	if l.abrir then items[#items + 1] = { text = "Ver la lista de compra", icon = "search", onClick = function() pcall(l.abrir) end } end
	if not l.llevar and (l.lugar or (l.destino and N.PuedeLlevar())) then items[#items + 1] = { text = "Llévame", icon = "icon-goto", onClick = function() N.Llevame(l) end } end
	if l.guia then items[#items + 1] = { text = "Abrir la guía en otra pestaña", icon = "plus", onClick = function() N.AbrirGuiaDe(l) end } end
	if l.ver then items[#items + 1] = { text = l.ver == "macro" and "Crear la macro" or "Ver en Mamba", icon = "search", onClick = function() verAlgo(l) end } end
	items[#items + 1] = { separator = true }
	if l.aviso then
		local tipo = l.aviso
		items[#items + 1] = { text = "No avisar más de esto (" .. (N.TIPOS_AVISO[tipo] or tipo) .. ")", icon = "close",
			onClick = function() N.Silenciar(tipo); N.Refrescar(true) end }
	end
	items[#items + 1] = { text = "Hecho", icon = "check", onClick = function() N.Hecho(l); N.Refrescar(true) end }
	items[#items + 1] = { text = "No me interesa", icon = "close", onClick = function() N.Hecho(l, true); N.Refrescar(true) end }
	w.ShowMenu(r, items)
end

---------------------------------------------------------------- piezas
local function construir(GF, body, PAD, UP_TOGGLE)
	local w, th = W(), Theme()
	local T = GF.Text
	cont = CreateFrame("Frame", nil, body)
	cont:Hide()
	cab = CreateFrame("Button", nil, cont)
	cab:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	cab:SetHeight(UP_TOGGLE)
	cab:SetPoint("TOPLEFT", cont, "TOPLEFT", 0, 0)
	cab:SetPoint("TOPRIGHT", cont, "TOPRIGHT", 0, 0)
	w.Hover(cab, 0.7)
	cab.Rule = w.Divider(cab)
	cab.Rule:SetPoint("TOPLEFT", cab, "TOPLEFT", PAD, 0)
	cab.Rule:SetPoint("TOPRIGHT", cab, "TOPRIGHT", -PAD, 0)
	-- el gesto: la marca oliva de Mamba
	cab.Marca = cab:CreateTexture(nil, "ARTWORK")
	cab.Marca:SetTexture(th.Media("white"))
	cab.Marca:SetVertexColor(OLIVA[1], OLIVA[2], OLIVA[3], 1)
	cab.Marca:SetSize(2, 11)
	cab.Marca:SetPoint("LEFT", cab, "LEFT", PAD, 0)
	cab.Label = GF.SizeAs(T(cab, "small", "textMuted"), "up")
	cab.Label:SetPoint("LEFT", cab.Marca, "RIGHT", 6, 0)
	cab.Icon = cab:CreateTexture(nil, "ARTWORK")
	cab.Icon:SetSize(12, 12)
	cab.Icon:SetPoint("RIGHT", cab, "RIGHT", -PAD, 0)
	cab.Icon:SetTexture(th.Media("chevron-down"))
	w.Color(cab.Icon, "textMuted")
	-- K108: «Servicios de la ciudad» cuando el jugador quiera (MambaAPI.AbrirServicios, de la ventana de Mamba)
	cab.Serv = CreateFrame("Button", nil, cab)
	cab.Serv:SetSize(112, 18)
	cab.Serv:SetPoint("RIGHT", cab.Icon, "LEFT", -10, 0)
	cab.Serv.Label = T(cab.Serv, "small", "accent")
	cab.Serv.Label:SetPoint("RIGHT", cab.Serv, "RIGHT", 0, 0)
	cab.Serv.Label:SetText("Servicios de la ciudad")
	cab.Serv:SetScript("OnClick", function() N.AbrirServicios() end)
	cab.Serv:SetScript("OnEnter", function(self) w.Color(self.Label, "text")
		w.Tooltip(self, "ANCHOR_LEFT", "Servicios de la ciudad", { { "Todo lo que hay en la ciudad donde estás (o la más cercana), con su Llévame.", th.Color("textDim") } }) end)
	cab.Serv:SetScript("OnLeave", function(self) w.Color(self.Label, "accent"); w.HideTooltip(self) end)
	cab.Serv:Hide()
	cab:SetScript("OnClick", function(_, boton)
		if boton == "RightButton" then
			local pj = N.PJ()
			local items = {
				{ text = "Solo lo que puedo hacer solo", checked = pj.soloSolo and true or false,
					onClick = function() pj.soloSolo = not pj.soloSolo; N.Refrescar(true) end },
				{ text = "Abrir Mi plan", icon = "search", onClick = function() local M = _G.MambaPlan; if M and M.AbrirPlan then pcall(M.AbrirPlan, "ahora") end end },
				{ separator = true },
			}
			-- K103: cada tipo de aviso se enciende y se apaga aquí (también deshace «No avisar más de esto»)
			for _, tipo in ipairs({ "lugar", "subasta", "espacio", "botin" }) do
				items[#items + 1] = { text = "Avisar: " .. (N.TIPOS_AVISO[tipo] or tipo), checked = not N.Silenciado(tipo),
					onClick = function() N.Silenciar(tipo, N.Silenciado(tipo) == false); N.Refrescar(true) end }
			end
			w.ShowMenu(cab, items)
			return
		end
		N.PJ().abierto = not N.PJ().abierto
		N.Reacomodar()
	end)
	cab:SetScript("OnEnter", function(self)
		w.Color(self.Label, "textDim")
		w.Tooltip(self, "ANCHOR_LEFT", "Mamba: tu plan", {
			{ "Lo que recomienda Mi plan, ordenado por lo que más rinde por minuto.", th.Color("textDim") },
			{ "Clic: mostrar u ocultar · Clic derecho: filtrar", th.Accent() } })
	end)
	cab:SetScript("OnLeave", function(self) w.Color(self.Label, "textMuted"); w.HideTooltip(self) end)
end

local function fila(GF, i)
	local r = filas[i]
	if r then return r end
	local w, th = W(), Theme()
	local T = GF.Text
	r = CreateFrame("Button", nil, cont)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	w.Hover(r)
	r.Icon = r:CreateTexture(nil, "ARTWORK")
	r.Icon:SetSize(13, 13)
	w.Color(r.Icon, "textMuted")
	r.Text = GF.SizeAs(T(r, "label", "textDim"), "up")
	r.Text:SetWordWrap(true)
	r.Text:SetMaxLines(2)
	r.Text:SetJustifyH("LEFT")
	r.Sub = T(r, "small", "textMuted")
	r.Sub:SetWordWrap(true)
	r.Sub:SetMaxLines(2) -- la puntuación y el cómo; completo, en el cuadro
	r.Sub:SetJustifyH("LEFT")
	-- el botón: texto chico en el acento, como el «Click to point the arrow here» de Polestar
	r.Ir = CreateFrame("Button", nil, r)
	r.Ir:SetSize(BOTON_W, 18)
	r.Ir.Label = T(r.Ir, "small", "accent")
	r.Ir.Label:SetPoint("RIGHT", r.Ir, "RIGHT", 0, 0)
	r.Ir:SetScript("OnClick", function(self) if self.psFn then self.psFn() end end)
	r.Ir:SetScript("OnEnter", function(self) self.Label:SetAlpha(1); w.Color(self.Label, "text") end)
	r.Ir:SetScript("OnLeave", function(self) w.Color(self.Label, "accent") end)
	r:SetScript("OnClick", function(self, boton)
		if boton == "RightButton" then return menuDe(self) end
		if self.Ir.psFn then self.Ir.psFn() end
	end)
	r:SetScript("OnEnter", function(self)
		local l = self.psLinea
		if not l then return end
		local lines = {}
		if l.como and l.como ~= "" then lines[#lines + 1] = { l.como, th.Color("textDim") } end
		lines[#lines + 1] = { N.Puntuacion(l) .. (l.porque and (" — " .. l.porque) or ""), th.Color("textDim") }
		if l.viaje then lines[#lines + 1] = { "Viaje ≈" .. l.viaje .. " min (planificador de Polestar)", th.Color("textMuted") } end
		lines[#lines + 1] = { "Clic: " .. (self.Ir.Label:GetText() or "") .. " · Clic derecho: más", th.Accent() }
		w.Tooltip(self, "ANCHOR_LEFT", l.titulo or "", lines)
	end)
	r:SetScript("OnLeave", function(self) w.HideTooltip(self) end)
	filas[i] = r
	return r
end

---------------------------------------------------------------- el gancho de Polestar (parche P9)
-- Polestar lo llama en cada acomodo de la ventana viva. Solo mide y ancla: los textos ya vienen armados.
local function lineas(GF, body, width, shown, PAD, TEXT_X, UP_ROW, UP_TOGGLE)
	if not cont then construir(GF, body, PAD, UP_TOGGLE) end
	local ls = N.lineas
	if not shown or #ls == 0 then
		cont:Hide()
		return cont, 0
	end
	cont:Show()
	local abierto = N.PJ().abierto
	cab.Label:SetText(abierto and "Mamba · tu plan" or ("Mamba · tu plan (" .. #ls .. ")"))
	cab.Serv:SetShown(N.HayServicios())
	local th = Theme()
	cab.Icon:SetTexture(th.Media(abierto and "chevron-up" or "chevron-down"))
	local y = -UP_TOGGLE
	local n = abierto and min(VISIBLES + (N.tramos or 0), #ls) or 0
	for i = 1, n do
		local l, r = ls[i], fila(GF, i)
		r.psLinea = l
		r.Icon:SetTexture(th.VerbIcon(l.verbo))
		local txt, fn = N.Accion(l)
		r.Ir.Label:SetText(txt or "")
		r.Ir.psFn = fn
		r.Ir:SetShown(txt ~= nil)
		r.Text:SetText(l.titulo or "")
		r.Sub:SetText(l.sub or "")
		-- el botón mide lo que mide su texto (nunca "Llévam"); si no deja al menos 120 px para el texto de la
		-- línea, baja a una línea propia debajo del cómo, alineado con el texto
		local bw = 0
		if txt then
			r.Ir.Label:SetWidth(0)
			bw = floor(r.Ir.Label:GetStringWidth() + 0.5) + 2
			r.Ir.Label:SetWidth(bw)
			r.Ir:SetWidth(bw + 4)
		end
		local libre = width - TEXT_X - 14 - PAD
		local abajo = txt ~= nil and (libre - bw - 10) < 120
		local tw = abajo and libre or (libre - (txt and (bw + 10) or 0))
		r.Text:SetWidth(tw)
		r.Sub:SetWidth(tw)
		local inset = max(0, (UP_ROW - r.Text:GetLineHeight()) / 2)
		local h = max(UP_ROW, floor(inset * 2 + r.Text:GetStringHeight() + 2 + r.Sub:GetStringHeight() + 0.5))
		if abajo then h = h + 18 end
		r.Icon:ClearAllPoints()
		r.Icon:SetPoint("LEFT", r, "TOPLEFT", TEXT_X - 2, -UP_ROW / 2)
		r.Text:ClearAllPoints()
		r.Text:SetPoint("TOPLEFT", r, "TOPLEFT", TEXT_X - 2 + 13 + 9, -inset)
		r.Sub:ClearAllPoints()
		r.Sub:SetPoint("TOPLEFT", r.Text, "BOTTOMLEFT", 0, -2)
		r.Ir:ClearAllPoints()
		if abajo then
			r.Ir:SetPoint("TOPLEFT", r.Sub, "BOTTOMLEFT", 0, -2)
			r.Ir.Label:ClearAllPoints()
			r.Ir.Label:SetPoint("LEFT", r.Ir, "LEFT", 0, 0)
		else
			r.Ir:SetPoint("TOPRIGHT", r, "TOPRIGHT", -PAD, -(UP_ROW - 18) / 2)
			r.Ir.Label:ClearAllPoints()
			r.Ir.Label:SetPoint("RIGHT", r.Ir, "RIGHT", 0, 0)
		end
		r.psAbajo = abajo
		r:SetHeight(h)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", cont, "TOPLEFT", 0, y)
		r:SetPoint("TOPRIGHT", cont, "TOPRIGHT", 0, y)
		r:SetAlpha(l.puedeYa and 1 or 0.65)
		r:Show()
		y = y - h
	end
	for i = n + 1, #filas do filas[i]:Hide(); filas[i].psLinea = nil end
	if n > 0 then y = y - 6 end
	cont:SetHeight(-y)
	return cont, -y
end
N.LayoutLineas = lineas

---------------------------------------------------------------- el viaje en curso (K58)
local VERBO_TRAMO = { piedra = "hearth", hogar = "hearth", vuelo = "fly", volar = "fly", zepelin = "fly", barco = "fly", portal = "fly" }

-- "Viaje a X · ≈ 4:18" y una línea por tramo que falta (a lo sumo 3), con su tiempo (R0: ≈ si es estimado).
function N.LineasViaje()
	local API = _G.MambaAPI
	if not (API and API.RutaActual) then return {} end
	local ok, r = pcall(API.RutaActual)
	if not (ok and type(r) == "table" and type(r.tramos) == "table" and #r.tramos > 0) then return {} end
	local function tiempo(seg, est)
		if not seg then return nil end
		if API.TiempoTexto then local okT, t = pcall(API.TiempoTexto, seg, est); if okT and t then return t end end
		return (est and "≈" or "") .. math.floor(seg / 60 + 0.5) .. " min"
	end
	local out = {}
	local total = tiempo(r.total, r.estimado)
	out[1] = { clave = "viaje", tramo = true, verbo = "goto", puedeYa = true,
		titulo = "Viaje a " .. (r.nombre or "tu destino"), sub = total and ("en total " .. total) or "calculando…" }
	for i = 1, math.min(3, #r.tramos) do
		local t = r.tramos[i]
		local tipo = tostring(t.tipo or ""):lower()
		local verbo = "goto"
		for k, v in pairs(VERBO_TRAMO) do if tipo:find(k, 1, true) then verbo = v end end
		out[#out + 1] = { clave = "viaje:" .. i, tramo = true, verbo = verbo, puedeYa = true,
			titulo = t.texto or tipo, sub = tiempo(t.seg, t.estimado) or "" }
	end
	return out
end

---------------------------------------------------------------- K108
function N.HayServicios()
	local A = _G.MambaAPI
	return A and A.AbrirServicios and true or false
end

function N.AbrirServicios()
	local A = _G.MambaAPI
	if A and A.AbrirServicios then return pcall(A.AbrirServicios) end
end

---------------------------------------------------------------- refresco
-- Arma las líneas (con sus textos) y le pide a Polestar que acomode la ventana.
function N.Reacomodar()
	local P = PS()
	local GF = P and P.UI and P.UI.GuideFrame
	if GF and GF.Layout then
		local ok, err = pcall(GF.Layout)
		if not ok then N.Falla("Layout", err) end
	end
end

local pendiente, ultimo = false, 0
local function armar()
	pendiente = false
	ultimo = GetTime and GetTime() or 0
	local ok, ls = pcall(N.Lineas)
	if not ok then N.Falla("Lineas", ls); ls = {} end
	for _, l in ipairs(ls) do
		local como = l.como and l.como ~= "" and (" · " .. l.como) or ""
		l.sub = N.Puntuacion(l) .. como
	end
	-- K58: el viaje en curso de «Llévame», tramo por tramo, arriba de la lista (MambaAPI.RutaActual)
	local tramos = N.LineasViaje()
	for i = #tramos, 1, -1 do table.insert(ls, 1, tramos[i]) end
	N.tramos = #tramos
	N.lineas = ls
	N.PJ().diag.ultimas = #ls
	N.Reacomodar()
end
N.alVolverACalcular = function() N.Refrescar(true) end

-- ya = true: ahora (un clic); si no, a lo sumo una vez por segundo.
function N.Refrescar(ya)
	if ya or not (C_Timer and C_Timer.After) then return armar() end
	if pendiente then return end
	pendiente = true
	local espera = max(0, 1 - ((GetTime and GetTime() or 0) - ultimo))
	C_Timer.After(espera, armar)
end

local enganchado = false
local function enganchar()
	local P = PS()
	if not (P and P.UI) then return false end
	P.UI.MambaLineas = lineas
	if enganchado then return true end
	enganchado = true
	if N.RegistrarPlanificador then N.RegistrarPlanificador() end
	if P.On then
		pcall(P.On, "STEP_CHANGED", function() N.Refrescar() end)
		pcall(P.On, "GUIDE_CHANGED", function() N.Refrescar() end)
	end
	local M = _G.MambaPlan
	if M and M.AlCambiar then M.AlCambiar(function() N.Refrescar() end) end
	local API = _G.MambaAPI
	if API and API.AlCambiarRuta then pcall(API.AlCambiarRuta, function() N.Refrescar(true) end) end
	return true
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_LEVEL_UP", "PLAYER_MONEY", "BAG_UPDATE_DELAYED", "SKILL_LINES_CHANGED", "LEARNED_SPELL_IN_TAB",
	"ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "MERCHANT_SHOW",
	"MERCHANT_CLOSED", "LOOT_READY" }) do
	pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e)
	if e == "PLAYER_LOGIN" then
		enganchar()
		return N.Refrescar(true)
	end
	-- K103: dónde está el jugador y qué saqueó
	if e == "AUCTION_HOUSE_SHOW" then N.estado.subasta = true; return N.Refrescar(true) end
	if e == "AUCTION_HOUSE_CLOSED" then N.estado.subasta = false; return N.Refrescar(true) end
	if e == "MERCHANT_SHOW" then N.estado.vendedor = true elseif e == "MERCHANT_CLOSED" then N.estado.vendedor = false end
	if e == "LOOT_READY" and N.Saqueo then
		local ok, err = pcall(N.Saqueo)
		if not ok then N.Falla("Saqueo", err) end
	end
	N.Refrescar()
end)
-- Polestar ya cargado (OptionalDeps): el gancho queda puesto desde la carga.
enganchar()

-- Para las pruebas (tests/mamba-panel.test.js).
function N._Piezas() return cont, cab, filas end
