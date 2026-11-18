-- Mamba_Mapa: lo que se dibuja (X7b, R2/K84, O8/K94).
--   - Coordenadas bajo el minimapa y en el mapa del mundo (tuyas y las del cursor).
--   - Tamaño del mapa del mundo (solo fuera de combate).
--   - Botones de accesorios del minimapa: se ven solo al pasar el ratón (si se pide) y zoom con la rueda.
--   - Capa de nodos de hierbas y vetas en el mapa y en el minimapa (datos propios de ForeverTDB, sin GatherMate).
--   - La ruta por los nodos dibujada en el mapa, con su largo y sus minutos, y "Seguir la ruta" con la flecha.
-- Nada de esto toca marcos protegidos; lo que cambia el mapa del juego espera a salir de combate.
-- Licencia: GPL-3.0-only.
local _, M = ...

local function db() return M.DB() end
local function enCombate() return InCombatLockdown and InCombatLockdown() end

---------------------------------------------------------------- qué nodos mostrar
local function habilidades()
	local h, v
	if GetProfessions and GetProfessionInfo then
		local t = { GetProfessions() }
		for i = 1, 6 do
			if t[i] then
				local nombre, _, rango = GetProfessionInfo(t[i])
				if nombre == "Herboristería" or nombre == "Herbalism" then h = rango end
				if nombre == "Minería" or nombre == "Mining" then v = rango end
			end
		end
	end
	return h, v
end

function M.Filtro()
	local d = db()
	local h, v = habilidades()
	if not h and UnitRace and select(2, UnitRace("player")) == "Tauren" then h = (UnitLevel("player") or 1) * 5 end
	local f = { hierbas = d.verHierbas, vetas = d.verVetas }
	if d.soloMios then
		f.hierbas = f.hierbas and h ~= nil
		f.vetas = f.vetas and v ~= nil
		f.habH, f.habV = h, v
	end
	return f
end

---------------------------------------------------------------- mapa del mundo
local capa, pinesM, lineas = nil, {}, {}
M.rutaActiva = nil -- { mapa, orden, largo, minutos, i }

local function hijoMapa()
	local W = WorldMapFrame
	return W and W.ScrollContainer and W.ScrollContainer.Child
end

local function pin(i, padre, pool, tam)
	local t = pool[i]
	if not t then
		t = padre:CreateTexture(nil, "OVERLAY")
		t:SetSize(tam, tam)
		pool[i] = t
	end
	return t
end

local COLOR = { h = { 0.45, 0.85, 0.35 }, v = { 0.85, 0.7, 0.4 } }

function M.DibujarMapa()
	local hijo = hijoMapa()
	if not hijo then return end
	if not capa then
		capa = CreateFrame("Frame", nil, hijo)
		capa:SetAllPoints(hijo)
		capa:SetFrameLevel((hijo.GetFrameLevel and hijo:GetFrameLevel() or 1) + 20)
	end
	local mapa = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
	local w, h = hijo:GetWidth(), hijo:GetHeight()
	local n = 0
	if db().nodos and mapa then
		for _, p in ipairs(M.NodosDe(mapa, M.Filtro())) do
			n = n + 1
			local t = pin(n, capa, pinesM, 7)
			t:SetColorTexture(unpack(COLOR[p.tipo]))
			t:ClearAllPoints()
			t:SetPoint("CENTER", capa, "TOPLEFT", p.x / 100 * w, -p.y / 100 * h)
			t:Show()
		end
	end
	for i = n + 1, #pinesM do pinesM[i]:Hide() end
	-- la ruta
	local r = M.rutaActiva
	local k = 0
	if r and r.mapa == mapa and capa.CreateLine then
		for i = 1, #r.orden do
			local a, b = r.orden[i], r.orden[i % #r.orden + 1]
			k = k + 1
			local l = lineas[k]
			if not l then
				l = capa:CreateLine(nil, "OVERLAY")
				l:SetThickness(2)
				lineas[k] = l
			end
			l:SetColorTexture(1, 0.82, 0.2, 0.85)
			l:SetStartPoint("TOPLEFT", capa, a.x / 100 * w, -a.y / 100 * h)
			l:SetEndPoint("TOPLEFT", capa, b.x / 100 * w, -b.y / 100 * h)
			l:Show()
		end
	end
	for i = k + 1, #lineas do lineas[i]:Hide() end
end

---------------------------------------------------------------- minimapa
local puntosMini = {}
local mundoZona -- { mapa, puntos = { { wx, wy, tipo } } }
-- diámetro del minimapa en yardas por nivel de zoom (afuera / adentro), valores del cliente clásico
local DIAM_AFUERA = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 }
local DIAM_ADENTRO = { [0] = 300, 240, 180, 120, 80, 50 }

local function prepararZona(mapa)
	mundoZona = { mapa = mapa, puntos = {} }
	if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return end
	for _, p in ipairs(M.NodosDe(mapa, M.Filtro())) do
		local ok, _, v = pcall(C_Map.GetWorldPosFromMapPos, mapa, CreateVector2D(p.x / 100, p.y / 100))
		if ok and v then
			local wx, wy = v:GetXY()
			mundoZona.puntos[#mundoZona.puntos + 1] = { wx, wy, p.tipo }
		end
	end
end

-- Posición en el minimapa (en píxeles desde el centro) de un punto del mundo; nil si queda afuera.
function M.EnMinimapa(px, py, wx, wy, diam, radioPx, angulo)
	local dx, dy = -(wy - py), (wx - px) -- este, norte (en yardas)
	if angulo and angulo ~= 0 then
		local c, s = math.cos(angulo), math.sin(angulo)
		dx, dy = dx * c - dy * s, dx * s + dy * c
	end
	local esc = radioPx / (diam / 2)
	local x, y = dx * esc, dy * esc
	if x * x + y * y > radioPx * radioPx then return nil end
	return x, y
end

function M.DibujarMinimapa()
	local mini = Minimap
	if not mini then return end
	local n = 0
	if db().nodos and db().nodosMinimapa and UnitPosition then
		local mapa = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
		if mapa and (not mundoZona or mundoZona.mapa ~= mapa) then prepararZona(mapa) end
		local py, px = UnitPosition("player") -- y = norte, x = oeste en UnitPosition: (posY, posX)
		if mundoZona and px and py then
			local zoom = mini.GetZoom and mini:GetZoom() or 0
			local adentro = GetCVar and GetCVar("minimapInsideZoom") ~= nil and IsIndoors and IsIndoors()
			local diam = (adentro and DIAM_ADENTRO or DIAM_AFUERA)[zoom] or 466
			local radio = (mini:GetWidth() or 140) / 2
			local ang = (GetCVar and GetCVar("rotateMinimap") == "1" and GetPlayerFacing) and -(GetPlayerFacing() or 0) or 0
			for _, p in ipairs(mundoZona.puntos) do
				local x, y = M.EnMinimapa(py, px, p[1], p[2], diam, radio, ang)
				if x then
					n = n + 1
					local t = pin(n, mini, puntosMini, 6)
					t:SetColorTexture(unpack(COLOR[p[3]]))
					t:ClearAllPoints()
					t:SetPoint("CENTER", mini, "CENTER", x, y)
					t:Show()
				end
			end
		end
	end
	for i = n + 1, #puntosMini do puntosMini[i]:Hide() end
end

---------------------------------------------------------------- coordenadas
local textoMini, textoMapa
local function coords(mapa, unidad)
	if not (C_Map and C_Map.GetPlayerMapPosition and mapa) then return nil end
	local ok, v = pcall(C_Map.GetPlayerMapPosition, mapa, unidad or "player")
	if ok and v and v.GetXY then
		local x, y = v:GetXY()
		if x and y and (x > 0 or y > 0) then return x * 100, y * 100 end
	end
end

function M.ActualizarCoords()
	local d = db()
	if Minimap and d.coords then
		if not textoMini then
			textoMini = Minimap:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			textoMini:SetPoint("TOP", Minimap, "BOTTOM", 0, -4)
		end
		local x, y = coords(C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
		textoMini:SetText(x and string.format("%.1f, %.1f", x, y) or "")
		textoMini:Show()
	elseif textoMini then textoMini:Hide() end
	local W = WorldMapFrame
	if W and W.IsShown and W:IsShown() and d.coordsMapa then
		if not textoMapa then
			textoMapa = (W.BorderFrame or W):CreateFontString(nil, "OVERLAY", "GameFontNormal")
			textoMapa:SetPoint("BOTTOM", W.ScrollContainer or W, "BOTTOM", 0, 6)
		end
		local mapa = W.GetMapID and W:GetMapID()
		local tx, ty = coords(mapa)
		local cx, cy
		local sc = W.ScrollContainer
		if sc and sc.GetNormalizedCursorPosition then
			local ok, a, b = pcall(sc.GetNormalizedCursorPosition, sc)
			if ok and a and a >= 0 and a <= 1 and b >= 0 and b <= 1 then cx, cy = a * 100, b * 100 end
		end
		textoMapa:SetText(("Tú: %s    Cursor: %s"):format(tx and ("%.1f, %.1f"):format(tx, ty) or "—", cx and ("%.1f, %.1f"):format(cx, cy) or "—"))
		textoMapa:Show()
	elseif textoMapa then textoMapa:Hide() end
end

---------------------------------------------------------------- tamaño del mapa y minimapa
function M.AplicarEscala()
	local W = WorldMapFrame
	if not (W and W.SetScale) then return end
	if enCombate() then M.pendiente = true; return end
	W:SetScale(db().escalaMapa or 1)
end

local function botonesMinimapa()
	local out = {}
	if not Minimap or not Minimap.GetChildren then return out end
	for _, h in ipairs({ Minimap:GetChildren() }) do
		local n = h.GetName and h:GetName()
		if n and (n:find("^LibDBIcon10_") or n:find("MinimapButton")) then out[#out + 1] = h end
	end
	return out
end

function M.AplicarMinimapa()
	if not Minimap then return end
	local d = db()
	local function alfa(a) for _, b in ipairs(botonesMinimapa()) do b:SetAlpha(a) end end
	if d.ocultarBotones then
		alfa(0)
		if not M.ganchoMini and Minimap.HookScript then
			M.ganchoMini = true
			Minimap:HookScript("OnEnter", function() if db().ocultarBotones then alfa(1) end end)
			Minimap:HookScript("OnLeave", function() if db().ocultarBotones then alfa(0) end end)
		end
	else
		alfa(1)
	end
	if d.ruedaZoom and not M.ganchoRueda and Minimap.EnableMouseWheel then
		M.ganchoRueda = true
		Minimap:EnableMouseWheel(true)
		Minimap:HookScript("OnMouseWheel", function(self, delta)
			if not db().ruedaZoom then return end
			local z = (self:GetZoom() or 0) + (delta > 0 and 1 or -1)
			z = math.max(0, math.min((self.GetZoomLevels and self:GetZoomLevels() or 6) - 1, z))
			self:SetZoom(z)
		end)
	end
end

---------------------------------------------------------------- ruta
-- Arma y muestra una ruta en un mapa: por el nodo de un objeto (itemID, con los datos de Mamba_Profesiones),
-- por objetivo ("hierbas" | "minerales") o por lo que muestra la capa.
function M.ArmarRuta(mapa, itemID, objetivo)
	local filtro = M.Filtro()
	if objetivo then filtro = { hierbas = objetivo == "hierbas", vetas = objetivo == "minerales", habH = filtro.habH, habV = filtro.habV } end
	if itemID then
		local P = _G.MambaProfesiones
		local nombres = {}
		for _, f in ipairs((P and P.FUENTES and P.FUENTES[itemID]) or {}) do
			if (f[1] == "hierba" or f[1] == "veta") then nombres[f[5]] = true end
		end
		local pts = {}
		for nombre in pairs(nombres) do
			for _, p in ipairs(M.NodosDe(mapa, { nombre = nombre })) do pts[#pts + 1] = p end
		end
		return M.RutaDe(mapa, pts)
	end
	return M.RutaDe(mapa, M.NodosDe(mapa, filtro))
end

function M.RutaDe(mapa, pts)
	local w, h = M.Yardas(mapa)
	local yo
	local mp = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if mp == mapa and C_Map.GetPlayerMapPosition then
		local ok, v = pcall(C_Map.GetPlayerMapPosition, mapa, "player")
		if ok and v then local x, y = v:GetXY(); yo = { x = x * 100, y = y * 100 } end
	end
	local orden, largo = M.Ruta(pts, w, h, yo)
	return { mapa = mapa, orden = orden, largo = largo, yardas = w ~= nil, minutos = w and M.MinutosVuelta(largo, #orden) or nil, i = 1 }
end

function M.MostrarRuta(mapa, itemID, objetivo)
	local r = M.ArmarRuta(mapa, itemID, objetivo)
	M.rutaActiva = r
	db().ultimaRuta = { mapa = mapa, item = itemID, objetivo = objetivo }
	if WorldMapFrame and not enCombate() then
		if ShowUIPanel and not WorldMapFrame:IsShown() then pcall(ShowUIPanel, WorldMapFrame) end
		if WorldMapFrame.SetMapID then pcall(WorldMapFrame.SetMapID, WorldMapFrame, mapa) end
	end
	M.DibujarMapa()
	M.Cambio()
	return r
end

-- Seguir la ruta: la flecha de Polestar al nodo siguiente; al llegar (15 yd) pasa al otro.
function M.SeguirRuta()
	local r = M.rutaActiva
	if not (r and r.orden[r.i]) then return false end
	local p = r.orden[r.i]
	local N = _G.Polestar and _G.Polestar.Nav and _G.Polestar.Nav.API
	if N and N.Navigate then
		M.siguiendo = true
		return N.Navigate("MambaMapa", r.mapa, p.x / 100, p.y / 100, ("%s (%d de %d)"):format(p.nombre or "Nodo", r.i, #r.orden))
	end
	return false
end

function M.TickRuta()
	local r = M.rutaActiva
	if not (M.siguiendo and r) then return end
	local p = r.orden[r.i]
	local mapa = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
	if not p or mapa ~= r.mapa then return end
	local ok, v = pcall(C_Map.GetPlayerMapPosition, mapa, "player")
	if not (ok and v) then return end
	local x, y = v:GetXY()
	local w, h = M.Yardas(mapa)
	w, h = w or 1000, h or 1000
	local d = math.sqrt(((x * 100 - p.x) * w / 100) ^ 2 + ((y * 100 - p.y) * h / 100) ^ 2)
	if d < 15 then
		r.i = r.i % #r.orden + 1
		M.SeguirRuta()
	end
end

---------------------------------------------------------------- eventos y reloj
local reloj = 0
local f = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA", "SKILL_LINES_CHANGED" }) do M.Escuchar(f, e) end
f:SetScript("OnEvent", function(_, e)
	if e == "PLAYER_LOGIN" then
		M.Proteger("escala", M.AplicarEscala)
		M.Proteger("minimapa", M.AplicarMinimapa)
		if WorldMapFrame and WorldMapFrame.HookScript then
			WorldMapFrame:HookScript("OnShow", function() M.Proteger("mapa", M.DibujarMapa) end)
		end
		if hooksecurefunc and WorldMapFrame and WorldMapFrame.OnMapChanged then
			hooksecurefunc(WorldMapFrame, "OnMapChanged", function() M.Proteger("mapa", M.DibujarMapa) end)
		end
	elseif e == "PLAYER_REGEN_ENABLED" then
		if M.pendiente then M.pendiente = nil; M.Proteger("escala", M.AplicarEscala) end
	else
		mundoZona = nil
	end
end)
f:SetScript("OnUpdate", function(_, dt)
	reloj = reloj + (dt or 0)
	if reloj < 0.2 then return end
	reloj = 0
	M.Proteger("coords", M.ActualizarCoords)
	M.Proteger("minimapa", M.DibujarMinimapa)
	M.Proteger("ruta", M.TickRuta)
end)
M.AlCambiar(function() mundoZona = nil; M.Proteger("mapa", M.DibujarMapa); M.Proteger("minimapa", M.AplicarMinimapa) end)
