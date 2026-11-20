-- Mamba_Curacion: núcleo. Ajustes, perfiles de clic por clase y especialización (K18) y las curas que se
-- pueden poner en cada clic. Cada clic lo hace el jugador (permitido): Mamba solo pone el hechizo en el botón.
-- Licencia: GPL-3.0-only.
local _, M = ...
_G.MambaCuracion = M

-- Hechizos que tiene sentido poner en un clic, por clase (id de rango 1; el juego lanza el rango más alto que
-- sabes al usar el nombre). Sacados del libro de hechizos del cliente (wago esMX), no de una guía.
M.CURAS = {
	DRUID = { 774, 8936, 5185, 18562, 2782, 8946, 2893, 20484, 29166, 1126 },
	PRIEST = { 2050, 2054, 2061, 139, 17, 527, 528, 552, 596, 2006, 1243 },
	SHAMAN = { 331, 8004, 1064, 526, 2870, 2008 },
	PALADIN = { 635, 19750, 4987, 1152, 633, 1022, 7328, 19740 },
	MAGE = { 475, 1459 },
	HUNTER = { 136 },
	WARLOCK = {}, ROGUE = {}, WARRIOR = {},
}
-- Primer perfil sugerido (el jugador lo cambia): clave del clic -> id o "target" / "menu".
M.SUGERIDO = {
	-- pedido de Cristian (19-11): izquierdo Rejuvenecimiento, derecho Recrecimiento, lateral de atrás Toque de sanación
	DRUID = { ["1"] = 774, ["2"] = 8936, ["4"] = 5185, ["shift-1"] = 5185, ["ctrl-1"] = 2782, ["ctrl-2"] = 8946, ["3"] = 18562,
		["ra"] = 774, ["rb"] = 8936, ["alt-1"] = "target", ["alt-2"] = "menu" },
	PRIEST = { ["1"] = 2061, ["2"] = 139, ["shift-1"] = 2054, ["shift-2"] = 17, ["ctrl-1"] = 527, ["ctrl-2"] = 528,
		["ra"] = 139, ["rb"] = 17, ["alt-1"] = "target", ["alt-2"] = "menu" },
	SHAMAN = { ["1"] = 8004, ["2"] = 1064, ["shift-1"] = 331, ["ctrl-1"] = 526, ["ctrl-2"] = 2870, ["alt-1"] = "target", ["alt-2"] = "menu" },
	PALADIN = { ["1"] = 19750, ["2"] = 635, ["ctrl-1"] = 4987, ["ctrl-2"] = 1152, ["shift-2"] = 633, ["alt-1"] = "target", ["alt-2"] = "menu" },
}
M.CLICS = { -- clave, texto
	{ "1", "Clic izquierdo" }, { "2", "Clic derecho" }, { "3", "Clic de la rueda" },
	{ "4", "Botón lateral de atrás (el de abajo)" }, { "5", "Botón lateral de adelante (el de arriba)" },
	{ "ra", "Rueda arriba" }, { "rb", "Rueda abajo" },
	{ "shift-1", "Mayús + clic izquierdo" }, { "shift-2", "Mayús + clic derecho" },
	{ "ctrl-1", "Ctrl + clic izquierdo" }, { "ctrl-2", "Ctrl + clic derecho" },
	{ "alt-1", "Alt + clic izquierdo" }, { "alt-2", "Alt + clic derecho" },
	{ "shift-4", "Mayús + lateral de atrás" }, { "shift-5", "Mayús + lateral de adelante" },
	{ "ctrl-4", "Ctrl + lateral de atrás" }, { "ctrl-5", "Ctrl + lateral de adelante" },
	{ "shift-ra", "Mayús + rueda arriba" }, { "shift-rb", "Mayús + rueda abajo" },
}
-- Lo que tu clase puede limpiar (para marcar en el marco solo eso, K16).
M.LIMPIA = {
	DRUID = { Curse = true, Poison = true }, PRIEST = { Magic = true, Disease = true }, SHAMAN = { Poison = true, Disease = true },
	PALADIN = { Magic = true, Poison = true, Disease = true }, MAGE = { Curse = true },
}

M.DEFECTO = { mover = false, mostrar = "grupo", ancho = 90, alto = 38, columnas = 5, escala = 1, solo = true, hots = true, limpiar = true, rango = true }

function M.DB()
	MambaCuraDB = MambaCuraDB or {}
	local d = MambaCuraDB
	for k, v in pairs(M.DEFECTO) do if d[k] == nil then d[k] = v end end
	d.perfiles = d.perfiles or {}
	d.diag = d.diag or {}
	return d
end

-- Cada lugar avisa UNA vez por sesión (las de OnUpdate se repetirían 4 veces por segundo); el resto solo se cuenta.
local yaAviso = {}
function M.Falla(donde, err)
	local d = M.DB().diag
	d.fallas = d.fallas or {}
	d.repetidas = d.repetidas or {}
	if yaAviso[donde] then d.repetidas[donde] = (d.repetidas[donde] or 0) + 1; return end
	yaAviso[donde] = true
	if #d.fallas < 30 then d.fallas[#d.fallas + 1] = (date and date("%d-%m %H:%M") or "") .. " " .. donde .. ": " .. tostring(err) end
	if geterrorhandler then geterrorhandler()(err) end
end
function M.Proteger(donde, fn, ...)
	local ok, a, b, c = pcall(fn, ...)
	if not ok then M.Falla(donde, a); return nil end
	return a, b, c
end
function M.Escuchar(f, ev)
	local ok = pcall(f.RegisterEvent, f, ev)
	if not ok then
		local d = M.DB().diag
		d.eventosNo = d.eventosNo or {}
		d.eventosNo[ev] = true
	end
	return ok
end

function M.Clase() return UnitClass and select(2, UnitClass("player")) or "WARRIOR" end
-- Especialización activa (doble especialización desde el 40, K18): 1 o 2.
function M.Spec()
	local f = (C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup) or GetActiveTalentGroup
	local ok, n = pcall(f or function() return 1 end)
	return (ok and n) or 1
end

-- El perfil de clics de esta clase y especialización (se crea con el sugerido la primera vez).
-- Perfiles viejos (hasta el 19-11): "4"/"5" eran la rueda. Si el perfil está igual al sugerido viejo, pasa al nuevo
-- (pedido de Cristian); si el jugador lo cambió, solo se mueve su rueda a "ra"/"rb" y no se pisa nada más.
M.SUGERIDO_VIEJO = {
	DRUID = { ["1"] = 774, ["2"] = 8936, ["shift-1"] = 5185, ["ctrl-1"] = 2782, ["ctrl-2"] = 8946, ["3"] = 18562,
		["4"] = 774, ["5"] = 8936, ["alt-1"] = "target", ["alt-2"] = "menu" },
	PRIEST = { ["1"] = 2061, ["2"] = 139, ["shift-1"] = 2054, ["shift-2"] = 17, ["ctrl-1"] = 527, ["ctrl-2"] = 528,
		["4"] = 139, ["5"] = 17, ["alt-1"] = "target", ["alt-2"] = "menu" },
}
local function iguales(a, b)
	for k, v in pairs(a or {}) do if b[k] ~= v then return false end end
	for k, v in pairs(b or {}) do if a[k] ~= v then return false end end
	return true
end
function M.Migrar(p, clase)
	if p.v2 then return p end
	local viejo = M.SUGERIDO_VIEJO[clase]
	if viejo and iguales(p, viejo) then
		for k in pairs(p) do p[k] = nil end
		for k, v in pairs(M.SUGERIDO[clase] or {}) do p[k] = v end
	else
		for _, pre in ipairs({ "", "shift-", "ctrl-", "alt-" }) do
			if p[pre .. "4"] ~= nil and p[pre .. "ra"] == nil then p[pre .. "ra"], p[pre .. "4"] = p[pre .. "4"], nil end
			if p[pre .. "5"] ~= nil and p[pre .. "rb"] == nil then p[pre .. "rb"], p[pre .. "5"] = p[pre .. "5"], nil end
		end
	end
	p.v2 = true
	return p
end

function M.Perfil()
	local d, clase, spec = M.DB(), M.Clase(), M.Spec()
	d.perfiles[clase] = d.perfiles[clase] or {}
	local p = d.perfiles[clase][spec]
	if p then return M.Migrar(p, clase) end
	if not p then
		p = {}
		for k, v in pairs(M.SUGERIDO[clase] or { ["1"] = "target", ["2"] = "menu" }) do p[k] = v end
		p.v2 = true
		d.perfiles[clase][spec] = p
	end
	return p
end

function M.Conoce(id)
	if type(id) ~= "number" then return true end
	if IsPlayerSpell and IsPlayerSpell(id) then return true end
	if IsSpellKnown and IsSpellKnown(id) then return true end
	local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
	return n ~= nil and GetSpellInfo ~= nil and GetSpellInfo(n) ~= nil
end

function M.NombreAccion(v)
	if v == "target" then return "Elegir de objetivo" elseif v == "menu" then return "Menú del jugador" end
	if type(v) == "number" then return (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(v)) or ("hechizo " .. v) end
	return "Nada"
end

-- Botones de los atributos seguros. 1-5 son los botones FÍSICOS del ratón (4 y 5, los laterales); la rueda va con
-- botones virtuales propios ("RuedaArriba"/"RuedaAbajo"), que el juego nombra "-<nombre>" en los atributos.
M.SUFIJO = { ["1"] = "1", ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5", ra = "-RuedaArriba", rb = "-RuedaAbajo" }
function M.Partes(clave)
	local pre, b = tostring(clave):match("^(.-)([^%-]+)$")
	local suf = b and M.SUFIJO[b]
	if not suf then return nil end
	return pre or "", suf
end

-- Atributos seguros de un clic: prefijo ("shift-") y botón ("1" o "-RuedaArriba") -> { [atributo] = valor }
function M.Atributos(perfil)
	local out = {}
	for clave, v in pairs(perfil) do
		local pre, boton = M.Partes(clave)
		if not pre then v = nil end
		if v == "target" then
			out[pre .. "type" .. boton] = "target"
		elseif v == "menu" then
			out[pre .. "type" .. boton] = "togglemenu"
		elseif type(v) == "number" and M.Conoce(v) then
			out[pre .. "type" .. boton] = "spell"
			out[pre .. "spell" .. boton] = M.NombreAccion(v)
		end
	end
	return out
end

local oyentes = {}
function M.AlCambiar(fn) oyentes[#oyentes + 1] = fn end
function M.Cambio() for _, fn in ipairs(oyentes) do pcall(fn) end end
