-- Asistente_Servicios: la flecha que te lleva caminando al servicio elegido.
-- Con Polestar (la base), el viaje lo hace SU flecha, por su API pública Polestar.Nav.API (versión 1).
-- Sin Polestar, o si cambió su API, nuestra flecha apunta en línea recta y lo dice. En combate solo se muestra: no se piden rutas.
-- Licencia: GPL-3.0-only.
local _, ns = ...
local S = ns.S
local A = _G.Asistente

local LLEGADA = 5        -- yardas: "Llegaste"
local DESVIO = 80        -- yardas lejos del próximo punto: se pide la ruta otra vez
local REINTENTO = 5      -- segundos entre pedidos de ruta
local REFRESCO = 0.05    -- segundos entre dibujos de la flecha

local F = { destino = nil, puntos = nil, idx = 1, modo = nil, ultimoPedido = -100, token = 0 }
S.flecha = F

---------------------------------------------------------------- posición del jugador
function S.PosicionJugador()
	if not UnitPosition then return nil end
	local ok, x, y, z, mapa = pcall(UnitPosition, "player")
	if not ok or type(x) ~= "number" or type(y) ~= "number" then return nil end -- secreto u oculto
	if issecretvalue and (issecretvalue(x) or issecretvalue(y)) then return nil end
	return x, y, (type(z) == "number" and z ~= 0) and z or nil, mapa
end

function S.Rumbo()
	if not GetPlayerFacing then return nil end
	local ok, f = pcall(GetPlayerFacing)
	if not ok or type(f) ~= "number" then return nil end
	if issecretvalue and issecretvalue(f) then return nil end
	return f
end

---------------------------------------------------------------- motor de rutas de Polestar
-- Respaldo SIN partes internas de Polestar (ARQUITECTURA §4, regla 2): Polestar_NavEngine es el traspaso
-- interno entre Polestar y su Polestar_Nav, no una API pública. El respaldo es solo la línea recta.
function S.Motor()
	return nil
end

-- Sin motor de rutas propio (ARQUITECTURA §7): el respaldo es la línea recta.
local function pedirRuta()
	if F.destino then F.modo = "recta" end
end
S.PedirRuta = pedirRuta

---------------------------------------------------------------- estado
-- lugar: fila de Ciudades.lua · uiMap: la ciudad · etiqueta: "Banco", "Instructor de druida"...
function S.IrA(lugar, uiMap, etiqueta)
	etiqueta = tostring(etiqueta or "")
	-- nunca dos flechas: si el destino anterior lo llevaba Polestar, se le quita primero
	if F.modo == "polestar" then
		local N0 = S.PolestarNav()
		if N0 and N0.Cancel then pcall(N0.Cancel, S.DUENO) end
	end
	local c = S.datos and S.datos.ciudades and S.datos.ciudades[uiMap]
	F.destino = { x = lugar.x, y = lugar.y, z = lugar.z, mapa = c and c.mapa, uiMap = uiMap,
		nombre = lugar.nombre, etiqueta = etiqueta, lugar = lugar }
	F.puntos, F.idx, F.modo, F.motivo = nil, 1, "recta", nil
	F.ultimoPedido = -100
	-- Polestar es la base (ARQUITECTURA §1): su flecha, su ruta a pie y su marca en el mapa hacen el viaje.
	-- La flecha propia queda solo de respaldo, si Polestar falta o cambió su API.
	local NAPI = S.PolestarNav()
	if NAPI and lugar.px and lugar.py then
		local ok, hecho = pcall(NAPI.Navigate, S.DUENO, uiMap, lugar.px / 100, lugar.py / 100, etiqueta .. ": " .. tostring(lugar.nombre))
		if ok and hecho then
			F.modo = "polestar"
			if S.MostrarFlecha then S.MostrarFlecha(false) end -- nunca dos flechas
			if S.MarcarMapas then S.MarcarMapas(nil) end
			return
		end
	end
	pedirRuta()
	if S.MostrarFlecha then S.MostrarFlecha(true) end
	if S.MarcarMapas then S.MarcarMapas(lugar) end
end

-- Polestar.Nav.API versión 1 (docs/ARCHITECTURE.md de Polestar, "Nav API"), o nil.
S.DUENO = "Asistente"
function S.PolestarNav()
	local P = _G.Polestar
	local N = type(P) == "table" and type(P.Nav) == "table" and P.Nav.API or nil
	if type(N) == "table" and N.version == 1 and type(N.Navigate) == "function" then return N end
	-- Polestar está pero su API cambió: avisar una vez (no en silencio) y seguir con la flecha propia
	if type(P) == "table" and not S.avisoApi and A then
		S.avisoApi = true
		A.Decir("Polestar cambió su API de viajes (versión " .. tostring(N and N.version) .. "): uso mi flecha en línea recta. Hay que actualizar el Asistente.")
	end
	return nil
end

function S.Detener(llegaste)
	local d = F.destino
	if F.modo == "polestar" then
		local N = S.PolestarNav()
		if N and N.Cancel then pcall(N.Cancel, S.DUENO) end
	end
	F.destino, F.puntos, F.modo = nil, nil, nil
	F.token = F.token + 1
	if S.MostrarFlecha then S.MostrarFlecha(false) end
	if S.MarcarMapas then S.MarcarMapas(nil) end
	if llegaste and d and A then A.Decir("Llegaste: " .. (d.etiqueta or "") .. " (" .. (d.nombre or "") .. ").") end
end

-- Un paso: dónde apuntar ahora. Devuelve angulo, distancia_total, modo; o nil si no hay destino o posición.
function S.Paso()
	local d = F.destino
	if not d then return nil end
	local x, y, _, mapa = S.PosicionJugador()
	if not x then return nil end
	if mapa and d.mapa and mapa ~= d.mapa then return nil end
	local total = S.Distancia(x, y, d.x, d.y)
	if total <= LLEGADA then
		S.Detener(true)
		return nil, total, "llegaste"
	end
	local ax, ay = d.x, d.y
	if F.puntos and F.modo == "a_pie" then
		F.idx = S.Avanzar(F.puntos, F.idx, x, y)
		local p = F.puntos[F.idx]
		ax, ay = p.x, p.y
		if S.Distancia(x, y, ax, ay) > DESVIO then pedirRuta() end -- te saliste del camino
	elseif F.modo ~= "a_pie" then
		pedirRuta() -- quizás ya se puede (salió del combate, cargó Polestar)
	end
	local rumbo = S.Rumbo()
	if not rumbo then return nil, total, F.modo end
	return S.AnguloFlecha(x, y, rumbo, ax, ay), total, F.modo
end

---------------------------------------------------------------- la flecha en pantalla
local marco
local function crear()
	if marco then return marco end
	marco = A.CrearMarcoBajo("Frame", "AsistenteServiciosFlecha", UIParent)
	marco:SetSize(64, 80)
	marco:SetPoint("TOP", UIParent, "TOP", 0, -140)
	marco:SetMovable(true)
	marco:EnableMouse(true)
	marco:RegisterForDrag("LeftButton")
	marco:SetScript("OnDragStart", marco.StartMoving)
	marco:SetScript("OnDragStop", marco.StopMovingOrSizing)
	marco.tex = marco:CreateTexture(nil, "ARTWORK")
	marco.tex:SetSize(48, 48)
	marco.tex:SetPoint("TOP")
	marco.tex:SetTexture("Interface\\Minimap\\MinimapArrow")
	marco.texto = marco:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	marco.texto:SetPoint("TOP", marco.tex, "BOTTOM", 0, -2)
	marco.texto:SetWidth(220)
	marco.aviso = marco:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	marco.aviso:SetPoint("TOP", marco.texto, "BOTTOM", 0, -1)
	marco.aviso:SetWidth(220)
	-- clic derecho: dejar de seguir
	marco:SetScript("OnMouseUp", function(_, boton) if boton == "RightButton" then S.Detener(false) end end)
	local acumulado = 0
	marco:SetScript("OnUpdate", function(self, dt)
		acumulado = acumulado + (dt or 0)
		if acumulado < REFRESCO then return end
		acumulado = 0
		S.Dibujar()
	end)
	marco:Hide()
	return marco
end

function S.Dibujar()
	if not marco or not F.destino then return end
	local angulo, total, modo = S.Paso()
	if not F.destino then return end
	if angulo then
		marco.tex:Show()
		marco.tex:SetRotation(angulo)
	else
		marco.tex:Hide()
	end
	marco.texto:SetText((F.destino.etiqueta or "") .. ": " .. S.TextoDistancia(total))
	if modo == "a_pie" then
		marco.aviso:SetText("ruta a pie (Polestar) · clic derecho para quitar")
	else
		marco.aviso:SetText("en línea recta (sin ruta a pie) · clic derecho para quitar")
	end
	if S.ActualizarMinimapa then S.ActualizarMinimapa() end
end

function S.MostrarFlecha(si)
	if si then crear():Show() elseif marco then marco:Hide() end
end
