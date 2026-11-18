-- Mamba_Bolsas: qué es cada objeto (para los filtros rápidos y las marcas sobre la casilla).
--   M.Clase(id) -> "equipo" | "consumibles" | "materiales" | "mision" | "otros"
--   M.Pasa(filtro, d) -> bool        filtro: "todo" | "basura" | "equipo" | "consumibles" | "materiales" | "mision" | "nuevo"
--   M.Coincide(texto, d) -> bool     buscador: parte del nombre (sin distinguir mayúsculas)
--   M.Marca(d) -> "basura" | "vender" | "subastar" | "guardar" | nil   (lo marcado por el jugador manda sobre lo sugerido)
--   M.EsMejora(d), M.EsDeMision(d)
-- d = { id, link, calidad, bolsa, casilla, nuevo, mision } (una casilla).
-- Reusa a Polestar (marcas basura/guardar, objetos de misión, ¿es mejora?) y a la ventana de Mamba
-- (MambaAPI.Bolsas: lo que sugiere el Tasador). Licencia: GPL-3.0-only.
local _, M = ...

M.FILTROS = {
	{ "todo", "Todo" }, { "basura", "Basura" }, { "equipo", "Equipo" }, { "consumibles", "Consumibles" },
	{ "materiales", "Materiales" }, { "mision", "Misión" }, { "nuevo", "Nuevo" },
}

local function instantaneo(id)
	local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
	if not (f and id) then return nil end
	local ok, _, _, _, equipLoc, _, clase, sub = pcall(f, id)
	if not ok then return nil end
	return clase, sub, equipLoc
end

-- classID del juego: 0 consumible, 2 arma, 3 gema, 4 armadura, 5 componente, 7 objeto comerciable, 12 misión
function M.Clase(id)
	local clase, _, equipLoc = instantaneo(id)
	if clase == 2 or (clase == 4 and equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE") then return "equipo" end
	if clase == 0 then return "consumibles" end
	if clase == 7 or clase == 5 or clase == 3 then return "materiales" end
	if clase == 12 then return "mision" end
	return "otros"
end

local function PS() local p = _G.Polestar; return type(p) == "table" and p or nil end

function M.EsDeMision(d)
	if d.mision then return true end
	if M.Clase(d.id) == "mision" then return true end
	local Q = PS() and PS().QuestDB
	if Q and Q.IsItemNeeded then
		local ok, si = pcall(Q.IsItemNeeded, d.id)
		if ok and si then return true end
	end
	return false
end

-- ¿Mejora para este personaje? El mismo veredicto que la flecha de Polestar en las bolsas del juego
-- (Gear.Bags.IsUpgrade: pesos de su clase y rol, o Forever Leveling BiS si está).
function M.EsMejora(d)
	if not d.link then return false end
	local G = PS() and PS().Gear
	local B = G and G.Bags
	if not (B and B.IsUpgrade) then return false end
	local ok, si = pcall(B.IsUpgrade, d.link)
	return ok and si and true or false
end

-- Lo que sugiere / eligió el jugador en el menú del objeto (MambaAPI.Bolsas), por id. Se arma una vez por
-- dibujo: M.RefrescarSugerencias().
local sugerencias = {}
function M.RefrescarSugerencias()
	sugerencias = {}
	local api = _G.MambaAPI
	if not (api and api.Bolsas) then return end
	local ok, lista = pcall(api.Bolsas)
	if not (ok and type(lista) == "table") then return end
	for _, o in ipairs(lista) do if o.id then sugerencias[o.id] = o end end
end

function M.Marca(d)
	local Ps = PS()
	local Marks = Ps and Ps.QoL and Ps.QoL.Marks
	if Marks and Marks.Get then
		local ok, m = pcall(Marks.Get, d.id)
		if ok and m == "junk" then return "basura" end
		if ok and m == "keep" then return "guardar" end
	end
	local o = sugerencias[d.id]
	local que = o and (o.elegido or o.sug)
	if que == "basura" then return "basura" end
	if que == "guardar" and o.elegido then return "guardar" end
	if que == "vendedor" then return "vender" end
	if que == "subastar" then return "subastar" end
	if d.calidad == 0 then return "basura" end
	return nil
end

function M.Pasa(filtro, d)
	if not filtro or filtro == "todo" then return true end
	if not d or not d.id then return false end
	if filtro == "basura" then
		local m = M.Marca(d)
		return m == "basura" or m == "vender"
	end
	if filtro == "nuevo" then return d.nuevo and true or false end
	if filtro == "mision" then return M.EsDeMision(d) end
	return M.Clase(d.id) == filtro
end

function M.Coincide(texto, d)
	if not texto or texto == "" then return true end
	if not (d and d.id) then return false end
	local nombre = d.link and d.link:match("%[(.-)%]") or M.NombreObjeto(d.id)
	return nombre and nombre:lower():find(texto:lower(), 1, true) and true or false
end
