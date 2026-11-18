-- Mamba: la sección "Interfaz" del menú de Polestar (su riel izquierdo), compartida por los módulos de
-- interfaz de Mamba: Barras, Bolsas, Curación, Combate y Mapa. Una sola entrada en el riel (revisión de
-- maquetas del 18-11, hallazgo 5: con una sección por módulo el riel no cabe). Su índice muestra un título
-- por módulo y debajo sus elementos; el panel de la derecha es el del módulo elegido.
-- Cada módulo trae una copia de este archivo; la versión más nueva gana (como LibStub).
--   MambaInterfaz.Agregar({ clave, titulo, orden, items = fn() -> { {key, label, count} }, activo = fn() -> key,
--     elegir = fn(key), dibujar = fn(parent, ancho, alto), refrescar = fn() })
--   MambaInterfaz.Abrir(clave, key)   abre el menú de Polestar en ese módulo (y ese elemento)
-- Licencia: GPL-3.0-only.
local VERSION = 1
local I = _G.MambaInterfaz
if I and (I.version or 0) >= VERSION then return end
local viejo = I
I = { version = VERSION, modulos = viejo and viejo.modulos or {} }
_G.MambaInterfaz = I

local KEY = "MambaInterfaz"
local actual -- clave del módulo elegido
local raiz, paneles = nil, {}

local function ordenados()
	local t = {}
	for _, m in pairs(I.modulos) do t[#t + 1] = m end
	table.sort(t, function(a, b) return (a.orden or 100) < (b.orden or 100) end)
	return t
end

local function UI()
	local P = _G.Polestar
	return P and P.UI
end

local function render()
	local ui = UI()
	if ui and ui.Picker and ui.Picker.Render then ui.Picker.Render() end
end

local function mostrar()
	if not raiz then return end
	local lista = ordenados()
	if not actual and lista[1] then actual = lista[1].clave end
	for clave, p in pairs(paneles) do if clave ~= actual then p:Hide() end end
	local m = I.modulos[actual]
	if not m then return end
	local p = paneles[actual]
	if not p then
		p = CreateFrame("Frame", nil, raiz)
		p:SetAllPoints(raiz)
		paneles[actual] = p
		local w, h = raiz:GetWidth(), raiz:GetHeight()
		if not w or w < 200 then w = 620 end
		if not h or h < 200 then h = 480 end
		local ok, err = pcall(m.dibujar, p, w, h)
		if not ok and geterrorhandler then geterrorhandler()(err) end
	end
	p:Show()
	if m.refrescar then pcall(m.refrescar) end
end

local registrada = false
local function registrar()
	if registrada then return true end
	local ui = UI()
	if not (ui and ui.RegisterSection) then return false end
	registrada = ui.RegisterSection({
		key = KEY, label = "Interfaz", icon = "layers", order = 210,
		build = function(parent) raiz = parent end,
		render = mostrar,
		nav = function()
			local items, activa = {}, nil
			local lista = ordenados()
			if not actual and lista[1] then actual = lista[1].clave end
			for _, m in ipairs(lista) do
				items[#items + 1] = { key = "", heading = true, label = m.titulo }
				local ok, sub = pcall(m.items)
				for _, it in ipairs(ok and sub or {}) do
					local k = m.clave .. ":" .. tostring(it.key)
					items[#items + 1] = { key = k, label = it.label, count = it.count, icon = it.icon }
				end
				if m.clave == actual and m.activo then
					local okA, a = pcall(m.activo)
					if okA and a ~= nil then activa = m.clave .. ":" .. tostring(a) end
				end
			end
			return items, activa
		end,
		onNav = function(k)
			local clave, sub = tostring(k):match("^([^:]+):(.*)$")
			if not clave or not I.modulos[clave] then return end
			actual = clave
			local m = I.modulos[clave]
			if m.elegir then pcall(m.elegir, sub) end
			render()
		end,
	}) and true or false
	return registrada
end

function I.Agregar(m)
	I.modulos[m.clave] = m
	registrar()
	if raiz and raiz:IsShown() then render() end
end

function I.Abrir(clave, sub)
	local ui = UI()
	if not (registrar() and ui.ShowPicker and ui.Picker and ui.Picker.ShowSection) then return false end
	actual = clave or actual
	local m = I.modulos[actual]
	if m and sub ~= nil and m.elegir then pcall(m.elegir, tostring(sub)) end
	ui.ShowPicker()
	ui.Picker.ShowSection(KEY)
	render()
	return true
end

function I.Registrada() return registrada end
