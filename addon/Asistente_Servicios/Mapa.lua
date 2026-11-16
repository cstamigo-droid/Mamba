-- Asistente_Servicios: la marca del servicio elegido en el mapa del mundo y en el minimapa.
-- Marcas propias (sin librerías cerradas): un icono del juego encima del mapa de la ciudad,
-- y otro en el minimapa, que se pega al borde si el lugar queda fuera de vista.
-- Licencia: GPL-3.0-only.
local _, ns = ...
local S = ns.S
local A = _G.Asistente
local bajo = A.CrearMarcoBajo -- crear sin padre y colgar después (taint del mapa con mando)

local marcado      -- lugar marcado (nil: ninguno)
local marcadoMapa  -- uiMap de la ciudad del lugar
local pinMundo, pinMini, vigia

local function icono(lugar)
	local c = lugar and S.CAT[lugar.cat]
	return c and c.icono or "Interface\\Minimap\\Tracking\\None"
end

---------------------------------------------------------------- mapa del mundo
local function lienzo()
	if not WorldMapFrame then return nil end
	if WorldMapFrame.GetCanvas then return WorldMapFrame:GetCanvas() end
	return WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
end

local function mapaAbierto()
	if not (WorldMapFrame and WorldMapFrame.GetMapID) then return nil end
	return WorldMapFrame:GetMapID()
end

local function actualizarMundo()
	if not pinMundo then return end
	local c = lienzo()
	if not (marcado and c and mapaAbierto() == marcadoMapa) then
		pinMundo:Hide()
		return
	end
	pinMundo:SetParent(c)
	pinMundo:SetFrameLevel((c.GetFrameLevel and c:GetFrameLevel() or 1) + 50)
	-- mismo tamaño en pantalla con cualquier zoom del mapa
	local escala = WorldMapFrame.GetCanvasScale and WorldMapFrame:GetCanvasScale() or 1
	if type(escala) ~= "number" or escala <= 0 then escala = 1 end
	pinMundo:SetSize(28 / escala, 28 / escala)
	pinMundo:ClearAllPoints()
	pinMundo:SetPoint("CENTER", c, "TOPLEFT", c:GetWidth() * marcado.px / 100, -c:GetHeight() * marcado.py / 100)
	pinMundo:Show()
end

local function crearMundo()
	if pinMundo or not WorldMapFrame then return end
	pinMundo = bajo("Frame", nil, WorldMapFrame)
	pinMundo:SetSize(28, 28)
	pinMundo.tex = pinMundo:CreateTexture(nil, "OVERLAY")
	pinMundo.tex:SetAllPoints()
	pinMundo:Hide()
	-- Revisa el mapa abierto solo mientras el mapa del mundo está a la vista (OnUpdate de un hijo).
	vigia = bajo("Frame", nil, WorldMapFrame)
	local t = 0
	vigia:SetScript("OnUpdate", function(_, dt)
		t = t + (dt or 0)
		if t < 0.2 then return end
		t = 0
		actualizarMundo()
	end)
end

---------------------------------------------------------------- minimapa
local function crearMini()
	if pinMini or not Minimap then return end
	pinMini = bajo("Frame", nil, Minimap)
	pinMini:SetSize(16, 16)
	pinMini:SetFrameLevel((Minimap.GetFrameLevel and Minimap:GetFrameLevel() or 1) + 5)
	pinMini.tex = pinMini:CreateTexture(nil, "OVERLAY")
	pinMini.tex:SetAllPoints()
	pinMini:Hide()
end

function S.ActualizarMinimapa()
	if not pinMini then return end
	if not marcado then pinMini:Hide(); return end
	local x, y = S.PosicionJugador()
	if not x then pinMini:Hide(); return end
	local zoom = Minimap.GetZoom and Minimap:GetZoom() or 0
	local adentro = IsIndoors and IsIndoors() or false
	local delJuego = C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius() or nil
	local radio = S.RadioMinimapa(zoom, adentro, delJuego)
	local gira = GetCVar and GetCVar("rotateMinimap") == "1"
	local dx, dy, borde = S.PuntoMinimapa(x, y, marcado.x, marcado.y, radio, Minimap:GetWidth(), gira, S.Rumbo())
	pinMini:ClearAllPoints()
	pinMini:SetPoint("CENTER", Minimap, "CENTER", dx, dy)
	pinMini:SetAlpha(borde and 0.6 or 1)
	pinMini:Show()
end

---------------------------------------------------------------- marcar / desmarcar
function S.MarcarMapas(lugar)
	crearMundo()
	crearMini()
	marcado = lugar
	marcadoMapa = lugar and S.flecha.destino and S.flecha.destino.uiMap or nil
	if pinMundo then pinMundo.tex:SetTexture(icono(lugar)) end
	if pinMini then pinMini.tex:SetTexture(icono(lugar)) end
	actualizarMundo()
	S.ActualizarMinimapa()
end

function S.Marcado() return marcado, marcadoMapa end
function S._Pines() return pinMundo, pinMini, vigia end -- para las pruebas
