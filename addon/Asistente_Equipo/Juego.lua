-- Asistente_Equipo: puente con el juego. SOLO LEE (lo puesto, nivel, facción). No equipa ni automatiza nada.
-- Rol, pesos y estadísticas los da Polestar.Gear (ver Logica.lua). Aquí solo se juntan los enlaces de lo
-- puesto y se avisa de las piezas con un "Equipar:" que ni Polestar ni el Tasador saben medir.
-- Licencia: GPL-3.0-only.
local _, E = ...

local function Leer(v)
	if v ~= nil and issecretvalue ~= nil and issecretvalue(v) == true then return nil end
	return v
end

-- -> clase ("DRUID"), nivel, lado ("H" | "A" | nil). Lo lee Polestar.Gear.
function E.Jugador(G)
	local p = G.GetPlayer()
	local faccion = p.faction
	if faccion == nil and UnitFactionGroup then faccion = Leer((UnitFactionGroup("player"))) end
	local lado = (faccion == "Horde" and "H") or (faccion == "Alliance" and "A") or nil
	return p.class, p.level or 1, lado
end

function E.EquipoPuesto()
	local puestos = {}
	for _, r in ipairs(E.RANURAS) do
		local link = GetInventoryItemLink and Leer(GetInventoryItemLink("player", r))
		if link then puestos[r] = link end
	end
	return puestos
end

-- Líneas "Equipar:" del cuadro del objeto (C_TooltipInfo). nil si el cuadro aún no está.
local function LineasEquipar(link)
	local get = C_TooltipInfo and C_TooltipInfo.GetHyperlink
	if not get then return nil end
	local ok, datos = pcall(get, link)
	if not (ok and type(datos) == "table" and type(datos.lines) == "table") then return nil end
	local pref = ITEM_SPELL_TRIGGER_ONEQUIP or "Equipar:"
	local out, todas = {}, 0
	for _, l in ipairs(datos.lines) do
		local t = type(l) == "table" and Leer(l.leftText)
		if type(t) == "string" then
			todas = todas + 1
			if t:sub(1, #pref) == pref or t:sub(1, 6) == "Equip:" then out[#out + 1] = t end
		end
	end
	if todas == 0 then return nil end
	return out
end

-- ¿Se puede medir bien esta pieza? false = tiene un "Equipar:" que nadie sabe medir:
--   * si NO está en la base de Polestar (ItemDB), Polestar solo ve lo que da GetItemStats, que no trae los
--     "Equipar:": cualquier "Equipar:" la deja dudosa (y también si no se puede leer el cuadro);
--   * si SÍ está, la base trae sus bonificaciones fijas, pero no los efectos por probabilidad: con el Tasador
--     cargado se revisa que no haya un "Equipar:" que no entienda.
function E.SabeEquipar(link, id)
	local P = _G.Polestar
	local DB = P and P.ItemDB
	local enBase = DB and DB.Get and id and DB.Get(id) and true or false
	local lineas = LineasEquipar(link)
	if not lineas then return enBase end
	if #lineas == 0 then return true end
	if not enBase then return false end
	local T = _G.Tasador
	if T and T.LeerEquipar then
		local _, desconocidas = T.LeerEquipar(lineas, ITEM_SPELL_TRIGGER_ONEQUIP)
		return desconocidas == 0
	end
	return false -- sin el Tasador no se puede saber si alguno es un efecto por probabilidad
end

-- ¿Ya completaste esta misión? (la da el juego; sin la función, nil)
function E.MisionHecha(q)
	local Q = C_QuestLog
	if Q and Q.IsQuestFlaggedCompleted then
		local ok, r = pcall(Q.IsQuestFlaggedCompleted, q)
		return ok and Leer(r) == true
	end
	return nil
end

-- Nombre en tu idioma: el del juego (enlace) si ya lo tiene; si aún no lo cargó, el esMX de los datos
-- (A.NOMBRES_OBJ, del generador: caché del cliente y sus tablas) y se le pide al juego que lo cargue para la
-- próxima vez. El nombre inglés de la base de Polestar solo queda como último recurso.
function E.NombreObjeto(id, respaldo)
	local f = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
	if f then
		local ok, nombre, link = pcall(f, id)
		if ok and Leer(link) then return Leer(link) end
		if ok and Leer(nombre) then return Leer(nombre) end
	end
	local pedir = C_Item and C_Item.RequestLoadItemDataByID
	if pedir and type(id) == "number" then pcall(pedir, id) end
	local es = E.NOMBRES_OBJ and E.NOMBRES_OBJ[id]
	if es then return es end
	if respaldo then return respaldo end
	local P = _G.Polestar
	local n = P and P.ItemDB and P.ItemDB.ItemName and P.ItemDB.ItemName(id)
	return n and (n .. "*") or ("objeto " .. tostring(id))
end

-- La flecha a la entrada de la mazmorra: el viaje lo hace Mamba (Polestar.Dungeons.GuideTo: rutas a pie,
-- vuelos y su flecha). -> true | false, motivo ("combate", "sin_entrada", "sin_base").
function E.GuiarEntrada(m)
	local P = _G.Polestar
	local D = P and P.Dungeons
	local clave = m and E.CLAVE_POLESTAR and E.CLAVE_POLESTAR[m.clave]
	if not (D and D.Load and D.GuideTo) then return false, "sin_base" end
	if not clave then return false, "sin_entrada" end
	if InCombatLockdown and InCombatLockdown() then return false, "combate" end
	local ok, cargada = pcall(D.Load)
	if not (ok and cargada) then return false, "sin_base" end
	local ok2, hecho = pcall(D.GuideTo, clave)
	if ok2 and hecho then return true end
	return false, "sin_entrada"
end
