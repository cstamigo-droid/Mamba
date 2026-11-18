-- Asistente: LA ventana de Mamba. Una sola ventana, movible, con una pestaña por módulo (Equipo, Clase,
-- Subasta) y, dentro de cada una, sus secciones. Todo se navega con clic: nada sale por el chat.
--   A.AbrirVentana(pestana, seccion)   abre (o trae al frente) la ventana; pestana: "equipo" | "clase" |
--                                      "tasador" | nil (la última que viste); seccion: la del comando
--                                      ("/equipo mazmorras" -> "mazmorras") o nil (la primera)
--   A.AlternarBotonMinimapa()          muestra u oculta el botón de Mamba del minimapa (/mamba boton)
--
-- Cómo se suma una pestaña (contrato con los módulos):
--   M.Secciones = { { clave = "revisar", nombre = "Mi equipo" }, ... }
--   M.Seccion(seccion, L)  escribe las filas con L:Fila(texto, opciones). opciones:
--       item    = id o enlace de objeto   (cuadro del objeto al pasar el ratón; mayús+clic lo enlaza)
--       ir      = "seccion" o "seccion:detalle"   (clic: navega ahí; el botón «Volver» regresa)
--       clic    = function()              (clic: hace algo, por ejemplo poner la flecha)
--       ayuda   = { titulo, { lineas } }  (cuadro de ayuda al pasar el ratón)
--       sangria = 1, 2...                 tipo = "titulo" | "nota"
--   Un módulo que todavía escribe en el chat (Clase, Tasador) se muestra con un adaptador: la ventana
--   corre su comando y pone en la pestaña, como filas, lo que iba a decir en el chat.
--
-- Solo marcos normales (Frame, Button, ScrollFrame): nada protegido, así que se puede abrir y usar en
-- combate. Lo que no se puede en combate (cargar un módulo, cargar la base de objetos) lo dice la pestaña.
-- Licencia: GPL-3.0-only.
local A = _G.Asistente

local ANCHO, ALTO = 580, 500
local FILA_MIN = 18

local v                 -- la ventana
local actual = { pestana = nil, seccion = nil }
local historial = {}    -- { {pestana, seccion}, ... } para «Volver»
local filasUsadas = 0

---------------------------------------------------------------- las pestañas
-- modulo: la tabla que el módulo registra con A.Registrar (A.modulos[modulo]); adaptador: para los
-- módulos que escriben en el chat.
A.PESTANAS = {
	{ clave = "equipo", nombre = "Equipo", addon = "Asistente_Equipo", modulo = "equipo" },
	{ clave = "clase", nombre = "Clase", addon = "Asistente_Clase", adaptador = "clase" },
	{ clave = "tasador", nombre = "Subasta", addon = "Tasador", adaptador = "tasador" },
}
local ADAPTADOR = {}

local function pestanaDe(clave)
	for _, p in ipairs(A.PESTANAS) do
		if p.clave == clave then return p end
	end
end

local function cargado(addon)
	local C = C_AddOns
	return C and C.IsAddOnLoaded and C.IsAddOnLoaded(addon) and true or false
end

local function moduloDe(p)
	if p.adaptador then return ADAPTADOR[p.adaptador] end
	return A.modulos[p.modulo]
end

---------------------------------------------------------------- la lista de filas
local Lista = {}
Lista.__index = Lista

function Lista:Fila(texto, o)
	o = o or {}
	o.texto = texto and tostring(texto) or ""
	self.filas[#self.filas + 1] = o
	return o
end

function Lista:Blanco()
	return self:Fila("", { blanco = true })
end

local function NuevaLista()
	return setmetatable({ filas = {} }, Lista)
end
A.NuevaLista = NuevaLista

---------------------------------------------------------------- dibujar
local function textoDeFila(o)
	if o.tipo == "titulo" then return A.Color("titulo", o.texto) end
	if o.tipo == "nota" then return A.Color("gris", o.texto) end
	return o.texto
end

local function alPasar(self)
	local o = self.o
	if not o then return end
	if o.item and GameTooltip and GameTooltip.SetOwner then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local link = type(o.item) == "number" and ("item:" .. o.item) or o.item
		if GameTooltip.SetHyperlink then pcall(GameTooltip.SetHyperlink, GameTooltip, link) end
		GameTooltip:Show()
	elseif o.ayuda then
		A.CuadroAyuda(self, o.ayuda[1], o.ayuda[2])
	end
end

local function alSalir()
	if A.OcultarAyuda then A.OcultarAyuda() elseif GameTooltip and GameTooltip.Hide then GameTooltip:Hide() end
end

local function alClic(self)
	local o = self.o
	if not o then return end
	if o.item and IsModifiedClick and IsModifiedClick("CHATLINK") and HandleModifiedItemClick then
		local link = type(o.item) == "string" and o.item or select(2, (C_Item and C_Item.GetItemInfo or GetItemInfo)(o.item))
		if link then HandleModifiedItemClick(link) end
		return
	end
	if o.clic then
		local ok, err = pcall(o.clic)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	end
	if o.ir then
		local pestana, seccion = actual.pestana, o.ir
		if o.ir:find("^%a+/") then pestana, seccion = o.ir:match("^(%a+)/(.*)$") end
		A.AbrirVentana(pestana, seccion, true)
	end
end

local function filaVisual(i)
	local b = v.filas[i]
	if b then return b end
	b = A.Fila(v.contenido, 10, FILA_MIN)
	b.texto = A.Texto(b, "body", "text")
	b.texto:SetJustifyH("LEFT")
	if b.texto.SetJustifyV then b.texto:SetJustifyV("TOP") end
	if b.texto.SetWordWrap then b.texto:SetWordWrap(true) end
	b:SetScript("OnEnter", alPasar)
	b:SetScript("OnLeave", alSalir)
	b:SetScript("OnClick", alClic)
	v.filas[i] = b
	return b
end

local function dibujarFilas(lista)
	local ancho = v.anchoContenido
	local y = 0
	for i, o in ipairs(lista.filas) do
		local b = filaVisual(i)
		b.o = o
		local sangria = (o.sangria or 0) * 16
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", v.contenido, "TOPLEFT", sangria, -y)
		b:SetWidth(ancho - sangria)
		b.texto:ClearAllPoints()
		b.texto:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -2)
		b.texto:SetWidth(ancho - sangria - 8)
		local t = textoDeFila(o)
		if (o.ir or o.clic) and not o.tipo then t = t .. A.Color("gris", "  ›") end
		b.texto:SetText(t)
		local alto = o.blanco and 8 or math.max(FILA_MIN, math.ceil((b.texto:GetStringHeight() or 12) + 4))
		b:SetHeight(alto)
		b:EnableMouse((o.item or o.ir or o.clic or o.ayuda) and true or false)
		b:Show()
		y = y + alto
	end
	for i = #lista.filas + 1, filasUsadas do
		if v.filas[i] then v.filas[i].o = nil; v.filas[i]:Hide() end
	end
	filasUsadas = #lista.filas
	v.contenido:SetHeight(math.max(1, y))
	v.altoTotal = y
end

local function desplazar(delta)
	local maximo = math.max(0, (v.altoTotal or 0) - v.desliza:GetHeight())
	local nuevo = math.max(0, math.min(maximo, (v.desliza:GetVerticalScroll() or 0) - delta * 40))
	v.desliza:SetVerticalScroll(nuevo)
end

---------------------------------------------------------------- botones de pestaña
local function botonPestana(padre, texto, alClicar)
	local b = A.Fila(padre, 10, 22)
	b.texto = A.Texto(b, "label", "text")
	b.texto:SetPoint("CENTER", b, "CENTER", 0, 0)
	b.texto:SetText(texto)
	b:SetWidth(math.max(60, (b.texto:GetStringWidth() or 40) + 20))
	b:SetScript("OnClick", alClicar)
	b.nombre = texto
	return b
end

local function marcar(b, elegido)
	b.texto:SetText(elegido and A.Color("titulo", "[ " .. b.nombre .. " ]") or A.Color("gris", b.nombre))
end

local function dibujarPestanas()
	for _, b in ipairs(v.botonesPestana) do marcar(b, b.clave == actual.pestana) end
	for _, b in ipairs(v.botonesSeccion) do b:Hide() end
	local p = pestanaDe(actual.pestana)
	local M = p and cargado(p.addon) and moduloDe(p)
	local x = 0
	local base = (actual.seccion or ""):match("^([^:]*)")
	if M and M.Secciones then
		for i, s in ipairs(M.Secciones) do
			local b = v.botonesSeccion[i]
			if not b then
				b = botonPestana(v.barraSecciones, s.nombre)
				v.botonesSeccion[i] = b
			end
			b.nombre, b.clave = s.nombre, s.clave
			b.texto:SetText(s.nombre)
			b:SetWidth(math.max(50, (b.texto:GetStringWidth() or 40) + 16))
			b:SetScript("OnClick", function() A.AbrirVentana(actual.pestana, s.clave) end)
			b:ClearAllPoints()
			b:SetPoint("LEFT", v.barraSecciones, "LEFT", x, 0)
			x = x + b:GetWidth() + 2
			marcar(b, s.clave == base)
			b:Show()
		end
	end
	if #historial > 0 then v.volver:Show() else v.volver:Hide() end
end

---------------------------------------------------------------- crear la ventana
local function crear()
	if v then return v end
	v = A.CrearVentana("MambaVentana", "Mamba", ANCHO, ALTO)
	local m, arriba = v.margen or 16, v.cuerpo or 26
	v.filas, v.botonesPestana, v.botonesSeccion = {}, {}, {}
	-- fila 1: los módulos
	local x = m
	for _, p in ipairs(A.PESTANAS) do
		local b = botonPestana(v, p.nombre, function() historial = {}; A.AbrirVentana(p.clave) end)
		b.clave = p.clave
		b:SetPoint("TOPLEFT", v, "TOPLEFT", x, -(arriba + 4))
		x = x + b:GetWidth() + 4
		v.botonesPestana[#v.botonesPestana + 1] = b
	end
	-- fila 2: las secciones del módulo elegido
	v.barraSecciones = CreateFrame("Frame", nil, v)
	v.barraSecciones:SetPoint("TOPLEFT", v, "TOPLEFT", m, -(arriba + 30))
	v.barraSecciones:SetPoint("TOPRIGHT", v, "TOPRIGHT", -m - 70, -(arriba + 30))
	v.barraSecciones:SetHeight(22)
	v.volver = botonPestana(v, "« Volver", function()
		local h = table.remove(historial)
		if h then A.AbrirVentana(h[1], h[2], false, true) end
	end)
	v.volver:SetPoint("TOPRIGHT", v, "TOPRIGHT", -m, -(arriba + 30))
	v.volver.texto:SetText(A.Color("titulo", "« Volver"))
	v.volver:Hide()
	-- el contenido, con rueda del ratón
	v.desliza = CreateFrame("ScrollFrame", nil, v)
	v.desliza:SetPoint("TOPLEFT", v, "TOPLEFT", m, -(arriba + 58))
	v.desliza:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -m, 30)
	v.anchoContenido = ANCHO - 2 * m
	v.contenido = CreateFrame("Frame", nil, v.desliza)
	v.contenido:SetSize(v.anchoContenido, 1)
	v.desliza:SetScrollChild(v.contenido)
	v.desliza:EnableMouseWheel(true)
	v.desliza:SetScript("OnMouseWheel", function(_, delta) desplazar(delta) end)
	v.pie = A.Texto(v, "note", "textMuted")
	v.pie:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", m, 10)
	v.pie:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -m, 10)
	v.pie:SetText(A.Color("gris", "Rueda del ratón: subir y bajar · Pasa el ratón por un objeto para verlo · Esc cierra"))
	v:HookScript("OnHide", function()
		for _, a in pairs(ADAPTADOR) do if a.AlCerrar then a.AlCerrar() end end
	end)
	if A.AlCambiarApariencia then A.AlCambiarApariencia(function() if v:IsShown() then A.Redibujar() end end) end
	return v
end

---------------------------------------------------------------- abrir y navegar
-- Vuelve a escribir la sección actual (por ejemplo cuando llega un dato que estaba cargando).
function A.Redibujar(mantenerPosicion)
	if not (v and v:IsShown()) then return end
	local p = pestanaDe(actual.pestana)
	local L = NuevaLista()
	if not p then
		L:Fila("Elige una pestaña de arriba.", { tipo = "nota" })
	elseif not cargado(p.addon) then
		if A.EnCombate() then
			L:Fila("Estás en combate: esta pestaña se abre sola al salir del combate.", { tipo = "nota" })
		else
			L:Fila("El addon " .. p.addon .. " no está instalado o está desactivado en la lista de accesorios.", { tipo = "nota" })
		end
	else
		local M = moduloDe(p)
		if not (M and M.Seccion) then
			L:Fila("Esta pestaña todavía no tiene ventana.", { tipo = "nota" })
		else
			local ok, err = pcall(M.Seccion, actual.seccion, L)
			if not ok then
				L:Blanco()
				L:Fila("Algo falló al armar esta sección. Abre «Errores» y mándale el texto a Cristian.", { tipo = "nota" })
				if geterrorhandler then geterrorhandler()(err) end
			end
		end
	end
	dibujarPestanas()
	dibujarFilas(L)
	if not mantenerPosicion then v.desliza:SetVerticalScroll(0) end
end

local function primeraSeccion(p)
	local M = moduloDe(p)
	return M and M.Secciones and M.Secciones[1] and M.Secciones[1].clave or nil
end

-- seccion: la clave de una sección, lo escrito después del comando (el módulo la traduce con
-- M.Alias), o nil (la primera). navegar: guardar la vista actual para «Volver». atras: viene de «Volver».
-- Con Polestar, la ventana de Mamba son sus secciones en el hub de Polestar (Hub.lua).
local HUB_PESTANA = { equipo = "MambaEquipo", clase = "MambaClase", tasador = "MambaSubasta", servicios = "MambaServicios" }
local HUB_SECCION = { revisar = "llevas", mazmorras = "mazmorras", ["60"] = "60", jcj = "jcj", rol = "rol", fuentes = "fuentes",
	prof = "prof", builds = "talentos", reventa = "reventa", pnj = "pnj", vender = "vender", fabricar = "fabricar" }

function A.AbrirVentana(pestana, seccion, navegar, atras)
	if A.Hub and A.Hub.Disponible() then
		local clave = pestana and HUB_PESTANA[pestana] or nil
		local base = type(seccion) == "string" and seccion:lower():match("^%s*([^%s:]*)") or nil
		if A.Hub.Abrir(clave, base and HUB_SECCION[base] or nil) then return end
	end
	crear()
	pestana = pestana or actual.pestana or "equipo"
	local p = pestanaDe(pestana)
	if not p then
		A.Decir("no conozco la pestaña \"" .. tostring(pestana) .. "\". Prueba /mamba, /equipo o /clase.")
		return
	end
	if navegar and actual.pestana then historial[#historial + 1] = { actual.pestana, actual.seccion } end
	if not navegar and not atras and pestana ~= actual.pestana then historial = {} end
	if seccion and type(seccion) == "string" then
		seccion = seccion:gsub("^%s+", ""):gsub("%s+$", "")
		if seccion == "" then seccion = nil end
	end
	local function mostrar()
		local M = moduloDe(p)
		if seccion and M and M.Alias then seccion = M.Alias(seccion) or seccion end
		actual.pestana, actual.seccion = pestana, seccion or primeraSeccion(p)
		for _, a in pairs(ADAPTADOR) do if a ~= M and a.AlCerrar then a.AlCerrar() end end
		v:Show()
		if v.Raise then v:Raise() end
		A.Redibujar()
	end
	if cargado(p.addon) then
		mostrar()
	else
		actual.pestana, actual.seccion = pestana, nil
		v:Show()
		A.Redibujar() -- dice "en combate" o "no instalado" mientras tanto
		A.Cargar(p.addon, mostrar)
	end
end

function A.VentanaAbierta()
	return v and v:IsShown() and actual.pestana or nil
end

---------------------------------------------------------------- adaptadores: lo que iba al chat, a la pestaña
-- Corre fn() y pone en L, como filas, todo lo que el módulo iba a escribir en el chat con tabla[campo].
local function capturar(tabla, campo, L, fn)
	local original = tabla[campo]
	tabla[campo] = function(t) L:Fila(t) end
	local ok, err = pcall(fn)
	tabla[campo] = original
	if not ok then
		L:Fila("Algo falló: " .. tostring(err):sub(1, 160), { tipo = "nota" })
	end
end

-- Clase: sus comandos escriben con A.Decir.
ADAPTADOR.clase = {
	Secciones = {
		{ clave = "resumen", nombre = "Resumen" },
		{ clave = "prof", nombre = "Profesiones" },
		{ clave = "builds", nombre = "Builds" },
	},
	Alias = function(s)
		s = s:lower()
		if s:find("^prof") then return "prof" end
		if s:find("^builds") then return "builds" end
		if s:find("^build ") or s:find("^revisar ") then return (s:gsub("%s+", ":", 1)) end
		return s
	end,
}
function ADAPTADOR.clase.Seccion(seccion, L)
	local M = A.modulos.clase
	if not (M and M.Comando) then
		L:Fila("El módulo de clase no respondió.", { tipo = "nota" })
		return
	end
	local base, detalle = (seccion or "resumen"):match("^([^:]*):?(.*)$")
	local comando = (base == "resumen" and "") or (detalle ~= "" and (base .. " " .. detalle)) or base
	local captura = NuevaLista()
	capturar(A, "Decir", captura, function() M.Comando(comando) end)
	-- En la lista de builds, cada línea empieza con su clave: clic = ver esa build.
	for _, o in ipairs(captura.filas) do
		local clave = base == "builds" and o.texto:match("^(%S+) · ")
		if clave then
			o.ir = "build:" .. clave
			o.ayuda = { "Build " .. clave, { "Clic: ver el orden nivel por nivel." } }
		end
		L.filas[#L.filas + 1] = o
	end
	if base == "build" and detalle ~= "" then
		L:Blanco()
		L:Fila("Comparar mis talentos con esta build", { ir = "revisar:" .. detalle })
	end
end

-- Tasador: escribe con Tasador.Decir. La reventa espera la lista de la subasta (llega después): mientras
-- esta sección esté a la vista, lo que diga el Tasador sigue llegando a la pestaña.
local tas = { lineas = nil, activo = false }
ADAPTADOR.tasador = {
	Secciones = {
		{ clave = "reventa", nombre = "Revender" },
		{ clave = "pnj", nombre = "Vender al PNJ" },
		{ clave = "vender", nombre = "Qué vender" },
		{ clave = "fabricar", nombre = "Fabricar" },
	},
	Alias = function(s)
		s = s:lower()
		if s == "op" or s:find("^oportunidad") then return "reventa" end
		if s == "vendedor" then return "pnj" end
		return s
	end,
}
local COMANDO_TAS = { reventa = "MostrarReventa", pnj = "MostrarReventa", vender = "MostrarVender", fabricar = "MostrarFabricar" }

function ADAPTADOR.tasador.AlCerrar()
	local T = _G.Tasador
	if tas.activo and T and tas.original then T.Decir = tas.original end
	tas.activo, tas.seccion = false, nil
end

function ADAPTADOR.tasador.Seccion(seccion, L)
	local T = _G.Tasador
	local fn = T and T[COMANDO_TAS[seccion or ""] or ""]
	if not fn then
		L:Fila("Esta parte del Tasador no está en tu versión.", { tipo = "nota" })
		return
	end
	if tas.seccion ~= seccion then
		-- sección nueva: se pide otra vez y lo que diga el Tasador viene aquí
		ADAPTADOR.tasador.AlCerrar()
		tas.lineas, tas.seccion, tas.activo, tas.original = NuevaLista(), seccion, true, T.Decir
		T.Decir = function(t)
			tas.lineas:Fila(t)
			if A.VentanaAbierta() == "tasador" then A.Redibujar(true) end
		end
		local ok, err = pcall(fn, seccion == "pnj" and "vendedor" or (seccion == "reventa" and "reventa" or nil))
		if not ok then tas.lineas:Fila("Algo falló: " .. tostring(err):sub(1, 160), { tipo = "nota" }) end
	end
	for _, o in ipairs(tas.lineas.filas) do L.filas[#L.filas + 1] = o end
	if #tas.lineas.filas == 0 then L:Fila("Cargando la lista de la subasta…", { tipo = "nota" }) end
	L:Blanco()
	L:Fila("Abrir la ventana de oportunidades del Tasador", { clic = function() if T.AbrirOportunidades then T.AbrirOportunidades() end end })
	L:Fila("Volver a calcular", { clic = function() tas.seccion = nil; A.Redibujar() end })
end

---------------------------------------------------------------- botón del minimapa
-- Un botón propio en el borde del minimapa (el de Polestar sigue igual): clic abre la ventana, arrastrar lo
-- mueve. Dónde va: AsistenteDB.minimapa.angulo (grados, 0 = este). /mamba boton lo oculta o lo muestra.
local boton
local function dbMinimapa()
	A.PrepararDB()
	AsistenteDB.minimapa = AsistenteDB.minimapa or { angulo = 160, oculto = false } -- 225 es el de Polestar
	return AsistenteDB.minimapa
end

local function ubicarBoton()
	local a = math.rad(dbMinimapa().angulo or 160)
	local r = ((Minimap.GetWidth and Minimap:GetWidth() or 140) / 2) + 5
	boton:ClearAllPoints()
	boton:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function crearBoton()
	if boton or not Minimap then return end
	boton = A.CrearMarcoBajo("Button", "MambaBotonMinimapa", Minimap)
	boton:SetSize(31, 31)
	boton:SetFrameStrata("MEDIUM")
	boton:SetFrameLevel(8)
	boton:RegisterForClicks("LeftButtonUp")
	boton:RegisterForDrag("LeftButton")
	local icono = boton:CreateTexture(nil, "BACKGROUND")
	icono:SetTexture("Interface\\Icons\\Ability_Hunter_Pet_WindSerpent")
	icono:SetSize(20, 20)
	icono:SetPoint("CENTER", boton, "CENTER", 0, 1)
	boton.icono = icono
	local borde = boton:CreateTexture(nil, "OVERLAY")
	borde:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	borde:SetSize(53, 53)
	borde:SetPoint("TOPLEFT", boton, "TOPLEFT", 0, 0)
	boton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	boton:SetScript("OnClick", function()
		if A.Hub and A.Hub.Disponible() then A.Hub.Alternar() return end
		if v and v:IsShown() then v:Hide() else A.AbrirVentana() end
	end)
	boton:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local cx, cy = Minimap:GetCenter()
			local x, y = GetCursorPosition()
			local s = Minimap:GetEffectiveScale()
			dbMinimapa().angulo = math.deg(math.atan2(y / s - cy, x / s - cx))
			ubicarBoton()
		end)
	end)
	boton:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	boton:SetScript("OnEnter", function(self)
		A.CuadroAyuda(self, "Mamba", { "Clic: abrir o cerrar la ventana de Mamba", "Arrastrar: mover este botón" })
	end)
	boton:SetScript("OnLeave", alSalir)
	ubicarBoton()
end

function A.MostrarBotonMinimapa()
	if dbMinimapa().oculto then
		if boton then boton:Hide() end
		return
	end
	crearBoton()
	if boton then boton:Show() end
end

function A.AlternarBotonMinimapa()
	local db = dbMinimapa()
	db.oculto = not db.oculto
	A.MostrarBotonMinimapa()
	A.Decir(db.oculto and "botón del minimapa oculto. /mamba boton lo vuelve a mostrar." or "botón del minimapa visible.")
end

local alEntrar = CreateFrame("Frame")
alEntrar:RegisterEvent("PLAYER_LOGIN")
alEntrar:SetScript("OnEvent", function() A.MostrarBotonMinimapa() end)
