-- Mamba_Barras: datos y cálculos puros (sin marcos). Se prueban fuera del juego (tools/asistente/pruebas/
-- test_barras.py). Licencia: GPL-3.0-only.
local _, M = ...
_G.MambaBarras = M

-- Las barras. inicio = la primera casilla de acción (1-180) de la barra; comando = la acción de teclado del
-- juego que ya usa esas casillas: si Cristian tenía teclas puestas en las barras del juego, siguen andando.
-- bt = número de la barra en Bartender4 (sus casillas son (bt-1)*12+1), para copiar su lugar y sus teclas.
M.BARRAS = {
	{ id = 1, nombre = "Barra principal", inicio = 1, comando = "ACTIONBUTTON", bt = 1, pagina = true },
	{ id = 2, nombre = "Barra 2", inicio = 13, bt = 2 },
	{ id = 3, nombre = "Lateral 1", inicio = 25, comando = "MULTIACTIONBAR3BUTTON", bt = 3 },
	{ id = 4, nombre = "Lateral 2", inicio = 37, comando = "MULTIACTIONBAR4BUTTON", bt = 4 },
	{ id = 5, nombre = "Barra 5", inicio = 49, comando = "MULTIACTIONBAR2BUTTON", bt = 5 },
	{ id = 6, nombre = "Barra 6", inicio = 61, comando = "MULTIACTIONBAR1BUTTON", bt = 6 },
	{ id = 7, nombre = "Barra 7", inicio = 145, comando = "MULTIACTIONBAR5BUTTON", bt = 13 },
	{ id = 8, nombre = "Barra 8", inicio = 157, comando = "MULTIACTIONBAR6BUTTON", bt = 14 },
	{ id = 9, nombre = "Barra 9", inicio = 169, comando = "MULTIACTIONBAR7BUTTON", bt = 15 },
}
-- Barras propias que no son de 12 casillas de acción.
M.ESPECIALES = {
	{ id = "formas", nombre = "Formas", comando = "SHAPESHIFTBUTTON", max = 10 },
	{ id = "mascota", nombre = "Mascota", comando = "BONUSACTIONBUTTON", max = 10 },
}

function M.Def(id)
	for _, d in ipairs(M.BARRAS) do if d.id == id then return d end end
	for _, d in ipairs(M.ESPECIALES) do if d.id == id then return d end end
end

-- Lugar por defecto (sin Bartender): parecido a las barras del juego. x, y en unidades de la pantalla
-- (UIParent), desde el punto indicado.
local LUGAR = {
	[1] = { "BOTTOM", 0, 40 }, [6] = { "BOTTOM", 0, 92 }, [5] = { "BOTTOM", 0, 144 },
	[3] = { "RIGHT", -8, 0 }, [4] = { "RIGHT", -58, 0 }, [2] = { "BOTTOM", 0, 196 },
	[7] = { "CENTER", 0, -120 }, [8] = { "CENTER", 0, -170 }, [9] = { "CENTER", 0, -220 },
	formas = { "BOTTOM", -200, 196 }, mascota = { "BOTTOM", 200, 196 },
}

function M.ConfigPorDefecto(id)
	local l = LUGAR[id] or { "CENTER", 0, 0 }
	local vertical = (id == 3 or id == 4)
	return {
		mostrar = (type(id) == "string") or id == 1 or id == 3 or id == 4 or id == 5 or id == 6,
		botones = (type(id) == "string") and 10 or 12,
		filas = vertical and 12 or 1,
		escala = 0.8,
		separacion = 2,
		alfa = 1,
		ver = "siempre",          -- "siempre" | "combate" | "raton"
		punto = l[1], x = l[2], y = l[3],
	}
end

---------------------------------------------------------------- formas y actitudes
-- Por clase: qué condición del juego dice que estás en esa forma y a qué página de 12 casillas pasa la
-- barra principal (la misma numeración que usa el juego: felina 7, sigilo 8, oso 9, lechúcico 10).
-- pagina 0 = "no cambia". La forma más específica va primero (sigilo antes que felina).
M.FORMAS = {
	DRUID = {
		{ clave = "sigilo", nombre = "Felina en sigilo", cond = "[bonusbar:1,stealth]", pagina = 8 },
		{ clave = "felina", nombre = "Forma felina", cond = "[bonusbar:1]", pagina = 7 },
		{ clave = "oso", nombre = "Forma de oso", cond = "[bonusbar:3]", pagina = 9 },
		{ clave = "lechucico", nombre = "Forma de lechúcico", cond = "[bonusbar:4]", pagina = 10 },
	},
	WARRIOR = {
		{ clave = "batalla", nombre = "Actitud de batalla", cond = "[bonusbar:1]", pagina = 7 },
		{ clave = "defensiva", nombre = "Actitud defensiva", cond = "[bonusbar:2]", pagina = 8 },
		{ clave = "rabiosa", nombre = "Actitud rabiosa", cond = "[bonusbar:3]", pagina = 9 },
	},
	ROGUE = {
		{ clave = "sigilo", nombre = "En sigilo", cond = "[bonusbar:1]", pagina = 7 },
	},
	PRIEST = {
		{ clave = "sombras", nombre = "Forma de las Sombras", cond = "[bonusbar:1]", pagina = 0 },
	},
}

-- Página elegida para cada forma: la guardada o la por defecto. 'tieneAccion(casilla)' (opcional) decide
-- las por defecto: una página vacía no se usa (si nunca pusiste nada en la página de sigilo, el sigilo
-- sigue en la de felina). Así Mamba hace lo mismo que tenías, sin preguntarte.
function M.PaginasFormas(clase, guardadas, tieneAccion)
	local out = {}
	for _, f in ipairs(M.FORMAS[clase] or {}) do
		local p = guardadas and guardadas[f.clave]
		if p == nil then
			p = f.pagina
			if p > 0 and tieneAccion then
				local alguna = false
				for i = 1, 12 do if tieneAccion((p - 1) * 12 + i) then alguna = true; break end end
				if not alguna then
					p = (f.clave == "sigilo" and clase == "DRUID") and -1 or 0 -- -1: como la felina
				end
			end
		end
		out[f.clave] = p
	end
	if out.sigilo == -1 then out.sigilo = out.felina or 0 end
	return out
end

-- La cadena de condiciones de la barra principal. idx = { anular, vehiculo } (números del juego: se leen
-- en vivo con GetOverrideBarIndex/GetVehicleBarIndex; nil si este cliente no los tiene).
function M.Conductor(clase, paginas, idx)
	local partes = {}
	idx = idx or {}
	if idx.anular then partes[#partes + 1] = "[overridebar]" .. idx.anular end
	if idx.vehiculo then partes[#partes + 1] = "[vehicleui][possessbar]" .. idx.vehiculo end
	partes[#partes + 1] = "[bonusbar:5]11"
	for p = 2, 6 do partes[#partes + 1] = "[bar:" .. p .. "]" .. p end
	for _, f in ipairs(M.FORMAS[clase] or {}) do
		local p = paginas and paginas[f.clave]
		if p and p > 0 then partes[#partes + 1] = f.cond .. p end
	end
	partes[#partes + 1] = "1"
	return table.concat(partes, ";")
end

-- Disposición en rejilla: columnas y filas para n botones en 'filas' filas.
function M.Rejilla(n, filas)
	n = math.max(1, math.floor(n or 12))
	filas = math.max(1, math.min(n, math.floor(filas or 1)))
	local cols = math.ceil(n / filas)
	filas = math.ceil(n / cols)
	return cols, filas
end

---------------------------------------------------------------- copiar de Bartender4
-- perfil = Bartender4DB.namespaces.<Modulo>.profiles[<perfil>] de cada módulo, en una tabla
-- { ActionBars = ..., StanceBar = ..., PetBar = ... }. Devuelve { [id] = config } con lo que Bartender
-- tenía: si se veía, filas, botones, tamaño, separación, transparencia y lugar.
local BT_DEF = { enabled = true, rows = 1, buttons = 12, padding = 2, alpha = 1, scale = 1 }

local function copiarLugar(c, pos)
	if type(pos) ~= "table" or not pos.point then return end
	c.punto, c.x, c.y = pos.point, pos.x or 0, pos.y or 0
	if pos.scale then c.escala = pos.scale end
end

local function desdeBT(id, b, porDefectoVisible)
	local c = M.ConfigPorDefecto(id)
	b = b or {}
	local en = b.enabled
	if en == nil then en = porDefectoVisible end
	c.mostrar = en and true or false
	c.filas = b.rows or BT_DEF.rows
	c.botones = b.buttons or ((type(id) == "string") and 10 or BT_DEF.buttons)
	c.separacion = b.padding or BT_DEF.padding
	c.alfa = b.alpha or BT_DEF.alpha
	c.escala = b.scale or BT_DEF.scale
	copiarLugar(c, b.position)
	if b.visibility and b.visibility.nocombat then c.ver = "combate" end
	if b.fadeout then c.ver = "raton" end
	return c
end

function M.DeBartender(perfil)
	if type(perfil) ~= "table" then return nil end
	local out = {}
	local ab = perfil.ActionBars and perfil.ActionBars.actionbars
	if type(ab) == "table" then
		for _, d in ipairs(M.BARRAS) do
			-- Bartender trae las barras 1 a 6 encendidas y las demás apagadas, salvo que digas otra cosa.
			out[d.id] = desdeBT(d.id, ab[d.bt], d.bt <= 6)
		end
	end
	if perfil.StanceBar then out.formas = desdeBT("formas", perfil.StanceBar, true) end
	if perfil.PetBar then out.mascota = desdeBT("mascota", perfil.PetBar, true) end
	return out
end

-- Teclas de Bartender: "CLICK BT4Button<N>:..." -> el botón de Mamba de esa casilla (o nil si Mamba no
-- tiene esa barra).
function M.BotonDeBT(comando)
	local n = type(comando) == "string" and tonumber(comando:match("^CLICK BT4Button(%d+):"))
	if not n then return nil end
	local bt = math.floor((n - 1) / 12) + 1
	for _, d in ipairs(M.BARRAS) do
		if d.bt == bt then return d.inicio + (n - 1) % 12 end
	end
end
