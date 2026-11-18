-- Mamba_Mapa: su parte en la sección "Interfaz" del menú de Polestar (MambaInterfaz). Dos elementos:
-- "Mapa y minimapa" (opciones) y "Ruta de recolección" (armar, ver y seguir la ruta por los nodos).
-- Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas
local sub = "opciones"
local paneles = {}

local function db() return M.DB() end
local function cambio() M.Cambio() end

local function zonaNombre(mapa)
	local i = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapa)
	return i and i.name or ("mapa " .. tostring(mapa))
end

local function filasOpciones(p, ancho)
	local d = db()
	local function I(et, ayuda, k, despues)
		return P.Interruptor(p, et, ayuda, function() return d[k] end, function(v) d[k] = v; if despues then despues() end; cambio() end)
	end
	return {
		I("Coordenadas bajo el minimapa", "Tu posición en la zona, en %.", "coords"),
		I("Coordenadas en el mapa del mundo", "La tuya y la del cursor, abajo del mapa.", "coordsMapa"),
		P.Deslizador(p, "Tamaño del mapa del mundo", "Se aplica fuera de combate.", 0.5, 1.5, 0.05, "%.2f",
			function() return d.escalaMapa end, function(v) d.escalaMapa = v; M.AplicarEscala() end),
		I("Botones del minimapa solo al pasar el ratón", "Esconde los botones de los accesorios hasta que pases el ratón por el minimapa.", "ocultarBotones", M.AplicarMinimapa),
		I("Zoom del minimapa con la rueda", "Rueda arriba acerca, abajo aleja.", "ruedaZoom", M.AplicarMinimapa),
		I("Nodos de hierbas y vetas en el mapa", "Puntos verdes (hierbas) y dorados (vetas), de datos propios de Mamba.", "nodos"),
		I("Nodos también en el minimapa", nil, "nodosMinimapa"),
		I("Solo los que puedo recoger", "Según tu Herboristería o Minería y su habilidad.", "soloMios"),
		I("Mostrar hierbas", nil, "verHierbas"),
		I("Mostrar vetas", nil, "verVetas"),
	}
end

local function dibujarOpciones(p, ancho)
	local y = -12
	local t = P.Texto(p, "title", "text")
	t:SetPoint("TOPLEFT", p, "TOPLEFT", 16, y)
	t:SetText("Mapa y minimapa")
	y = y - 30
	for _, f in ipairs(filasOpciones(p, ancho)) do
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", p, "TOPLEFT", 16, y)
		local h = P.Acomodar(f, ancho - 40)
		y = y - h - 4
	end
end

local rutaTexto, rutaDetalle
local function textoRuta()
	local r = M.rutaActiva
	if not rutaTexto then return end
	if not r or #r.orden == 0 then
		rutaTexto:SetText("Sin ruta todavía.")
		rutaDetalle:SetText("Arma una con tus hierbas o vetas de la zona donde estás, o desde Profesiones › Farmeo con \"Ver ruta\".")
		return
	end
	rutaTexto:SetText(("Ruta en %s: %d nodos"):format(zonaNombre(r.mapa), #r.orden))
	rutaDetalle:SetText(r.yardas and ("Una vuelta: %d yardas · ≈ %d min a pie (≈ 4 s por nodo). Al seguirla, la flecha pasa sola al nodo siguiente."):format(
		math.floor(r.largo + 0.5), math.floor(r.minutos + 0.5)) or "El juego no dio el tamaño del mapa: sin minutos.")
end

local function dibujarRuta(p, ancho)
	local t = P.Texto(p, "title", "text")
	t:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -12)
	t:SetText("Ruta de recolección")
	rutaTexto = P.Texto(p, "body", "text")
	rutaTexto:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -10)
	rutaDetalle = P.Texto(p, "note", "textDim")
	rutaDetalle:SetPoint("TOPLEFT", rutaTexto, "BOTTOMLEFT", 0, -4)
	rutaDetalle:SetWidth(ancho - 40)
	local function aqui(obj)
		local mapa = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
		if mapa then M.MostrarRuta(mapa, nil, obj) end
		textoRuta()
	end
	local b1 = P.Boton(p, "Hierbas de esta zona", function() aqui("hierbas") end, true)
	b1:SetPoint("TOPLEFT", rutaDetalle, "BOTTOMLEFT", 0, -14)
	local b2 = P.Boton(p, "Vetas de esta zona", function() aqui("minerales") end)
	b2:SetPoint("LEFT", b1, "RIGHT", 8, 0)
	local b3 = P.Boton(p, "Seguir la ruta", function() M.SeguirRuta() end)
	b3:SetPoint("TOPLEFT", b1, "BOTTOMLEFT", 0, -10)
	local b4 = P.Boton(p, "Quitar la ruta", function() M.rutaActiva = nil; M.siguiendo = nil; M.DibujarMapa(); textoRuta() end)
	b4:SetPoint("LEFT", b3, "RIGHT", 8, 0)
	textoRuta()
end

local function dibujar(parent, ancho, alto)
	paneles.opciones = CreateFrame("Frame", nil, parent)
	paneles.opciones:SetAllPoints(parent)
	dibujarOpciones(paneles.opciones, ancho)
	paneles.ruta = CreateFrame("Frame", nil, parent)
	paneles.ruta:SetAllPoints(parent)
	dibujarRuta(paneles.ruta, ancho)
end

local function refrescar()
	for k, p in pairs(paneles) do if k == sub then p:Show() else p:Hide() end end
	textoRuta()
end
M.AlCambiar(function() pcall(textoRuta) end)

local reg = CreateFrame("Frame")
M.Escuchar(reg, "PLAYER_LOGIN")
reg:SetScript("OnEvent", function()
	local I = _G.MambaInterfaz
	if not (I and I.Agregar) then return end
	M.Proteger("interfaz", I.Agregar, {
		clave = "mapa", titulo = "Mapa", orden = 5,
		items = function()
			return { { key = "opciones", label = "Mapa y minimapa", icon = "icon-goto" },
				{ key = "ruta", label = "Ruta de recolección", icon = "icon-collect", count = M.rutaActiva and #M.rutaActiva.orden or nil } }
		end,
		activo = function() return sub end,
		elegir = function(k) if k == "opciones" or k == "ruta" then sub = k end end,
		dibujar = dibujar, refrescar = refrescar,
	})
end)

-- Abrir la ruta desde otros módulos (Profesiones › Farmeo)
function M.AbrirRuta()
	local I = _G.MambaInterfaz
	sub = "ruta"
	if I and I.Abrir then I.Abrir("mapa", "ruta") end
end
