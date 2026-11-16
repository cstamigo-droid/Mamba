-- Tasador: ¿esta pieza es mejor que la que llevas puesta? (lógica pura, sin llamadas al juego)
-- Licencia: GPL-3.0.
-- Los pesos de estadísticas de DRUIDA vienen de Polestar (Polestar/Gear/SpecData.lua, GPL-3.0,
-- https://github.com/fitzforge/polestar), que los armó con sus pesos de subida de nivel y con
-- simulaciones de wowsims (MIT, https://github.com/wowsims). Copiados el 16-11-2026: los NÚMEROS sin cambios;
-- solo se tradujeron los nombres (balance->equilibrio, restoration->sanacion) y se unieron dos bandas feral idénticas.
local _, T = ...
T = T or Tasador or {}
Tasador = T

T.PESOS = {
	DRUID = {
		equilibrio = {
			{ hasta = 39, w = { armor = 0.005, heal = 0.1, health = 0.05, int = 1, mana = 0.06, mp5 = 2, sp = 0.9, spArcane = 0.7, spNature = 0.9, spellCrit = 6, spellHit = 8, spi = 0.5, sta = 0.5 } },
			{ hasta = 49, w = { armor = 0.003, heal = 0.05, health = 0.025, int = 0.577, mana = 0.03, mp5 = 1, sp = 0.9, spArcane = 0.652, spNature = 0.599, spellCrit = 5.637, spellHit = 7.708, spi = 0.25, sta = 0.25 } },
			{ hasta = 59, w = { armor = 0.003, heal = 0.05, health = 0.025, int = 0.572, mana = 0.03, mp5 = 1, sp = 0.9, spArcane = 0.629, spNature = 0.621, spellCrit = 6.375, spellHit = 9.288, spi = 0.25, sta = 0.25 } },
			{ hasta = 60, w = { armor = 0.001, heal = 0.025, health = 0.013, int = 0.358, mana = 0.015, mp5 = 0.5, sp = 0.9, spArcane = 0.593, spNature = 0.482, spellCrit = 6.563, spellHit = 9.931, spi = 0.125, sta = 0.125 } },
		},
		feral = {
			{ hasta = 24, w = { agi = 1, ap = 0.5, armor = 0.04, crit = 9, defense = 0.4, dodge = 6, health = 0.07, hit = 9, hp5 = 0.5, int = 0.2, spi = 0.15, sta = 0.65, str = 1 } },
			{ hasta = 49, w = { agi = 1, ap = 0.498, armor = 0.02, crit = 6.527, defense = 0.2, dodge = 3, health = 0.035, hit = 6.532, hp5 = 0.25, int = 0.266, mana = 0.01, mp5 = 0.114, spi = 0.095, sta = 0.325, str = 1.045 } },
			{ hasta = 59, w = { agi = 1, ap = 0.463, armor = 0.02, crit = 8.047, defense = 0.2, dodge = 3, health = 0.035, hit = 9.704, hp5 = 0.25, int = 0.243, mana = 0.009, mp5 = 0.098, spi = 0.092, sta = 0.325, str = 1.006 } },
			{ hasta = 60, w = { agi = 1, ap = 0.434, armor = 0.01, crit = 11.102, defense = 0.1, dodge = 1.5, health = 0.018, hit = 10.457, hp5 = 0.125, int = 0.238, mana = 0.009, mp5 = 0.244, spi = 0.155, sta = 0.163, str = 0.991 } },
		},
		sanacion = {
			{ hasta = 60, w = { armor = 0.005, heal = 0.7, health = 0.05, int = 1, mana = 0.06, mp5 = 2.2, sp = 0.1, spellCrit = 4, spi = 0.65, sta = 0.45 } },
		},
	},
}

-- Nombres del juego (C_Item.GetItemStats) -> nombres cortos de los pesos. Mapeo de hechos, igual al de Polestar.
T.STAT = {
	ITEM_MOD_STRENGTH_SHORT = "str", ITEM_MOD_AGILITY_SHORT = "agi", ITEM_MOD_STAMINA_SHORT = "sta",
	ITEM_MOD_INTELLECT_SHORT = "int", ITEM_MOD_SPIRIT_SHORT = "spi", RESISTANCE0_NAME = "armor",
	ITEM_MOD_HEALTH_SHORT = "health", ITEM_MOD_MANA_SHORT = "mana",
	ITEM_MOD_ATTACK_POWER_SHORT = "ap",
	ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "sp", ITEM_MOD_SPELL_POWER_SHORT = "sp",
	ITEM_MOD_SPELL_HEALING_DONE_SHORT = "heal",
	ITEM_MOD_MANA_REGENERATION_SHORT = "mp5", ITEM_MOD_POWER_REGEN0_SHORT = "mp5",
	ITEM_MOD_HEALTH_REGEN_SHORT = "hp5", ITEM_MOD_HEALTH_REGENERATION_SHORT = "hp5",
	ITEM_MOD_CRIT_RATING_SHORT = "crit", ITEM_MOD_CRIT_MELEE_RATING_SHORT = "crit",
	ITEM_MOD_HIT_RATING_SHORT = "hit", ITEM_MOD_HIT_MELEE_RATING_SHORT = "hit",
	ITEM_MOD_CRIT_SPELL_RATING_SHORT = "spellCrit", ITEM_MOD_HIT_SPELL_RATING_SHORT = "spellHit",
	ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "defense", ITEM_MOD_DODGE_RATING_SHORT = "dodge",
	ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "dps",
}

T.ROL_NOMBRE = { equilibrio = "Equilibrio", feral = "Feral", sanacion = "Restauración" }

-- Ranuras de equipo. Ojo: anillos y abalorios tienen dos ranuras.
T.RANURAS = {
	INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 },
	INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
	INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
	INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
	INVTYPE_WEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 }, INVTYPE_2HWEAPON = { 16 },
	INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_SHIELD = { 17 },
	INVTYPE_RELIC = { 18 }, INVTYPE_RANGED = { 18 },
}

-- Lo que un druida puede usar en Vanilla (subclases de Enum.ItemArmorSubclass / ItemWeaponSubclass).
T.DRUIDA_ARMADURA = { [0] = true, [1] = true, [2] = true, [8] = true } -- varios, tela, cuero, ídolo
T.DRUIDA_ARMA = { [4] = true, [5] = true, [10] = true, [13] = true, [15] = true } -- maza, maza 2M, bastón, puño, daga

-- DPS del arma: en Forever las formas de gato y oso pegan con el DPS del arma equipada
-- (Polestar, Gear.lua, citando a Blizzard). Feral: 14 x el peso del poder de ataque;
-- los demás roles: 0,01 (solo desempata). Mismo criterio que Polestar.
local conDps = setmetatable({}, { __mode = "k" })
local function ConDps(w, rol)
	if not w or w.dps then return w end
	local c = conDps[w]
	if not c then
		c = {}
		for k, v in pairs(w) do c[k] = v end
		c.dps = (rol == "feral" and w.ap) and 14 * w.ap or 0.01
		conDps[w] = c
	end
	return c
end

-- Pesos sin lo que solo desempata (armadura y DPS del arma): sirven para saber si una pieza
-- aporta algo de verdad a tu rol (una capa de Fuerza con armadura no es "mejora" para Equilibrio).
local sinDesempate = setmetatable({}, { __mode = "k" })
function T.SinDesempate(w)
	if not w then return nil end
	local c = sinDesempate[w]
	if not c then
		c = {}
		for k, v in pairs(w) do
			if k ~= "armor" and k ~= "dps" then c[k] = v end
		end
		sinDesempate[w] = c
	end
	return c
end

function T.PesosPara(clase, rol, nivel)
	local bandas = T.PESOS[clase] and T.PESOS[clase][rol]
	if not bandas then return nil end
	for _, b in ipairs(bandas) do
		if (nivel or 1) <= b.hasta then return ConDps(b.w, rol) end
	end
	return ConDps(bandas[#bandas].w, rol)
end

-- stats = tabla del juego { ITEM_MOD_INTELLECT_SHORT = 5, ... }
function T.Puntaje(stats, pesos)
	if not stats or not pesos then return 0 end
	local total = 0
	for clave, valor in pairs(stats) do
		local corto = T.STAT[clave]
		if corto and pesos[corto] and type(valor) == "number" then
			total = total + valor * pesos[corto]
		end
	end
	return total
end

-- nuevo = puntaje de la pieza; puestos = lista de puntajes de lo que llevas en esa(s) ranura(s)
-- (false = ranura vacía). Compara con la PEOR de las ranuras (anillos, abalorios).
-- Devuelve diferencia en % (positivo = mejor), "vacia", o "sinbase" cuando lo que llevas
-- no suma nada para tu rol (un porcentaje sobre cero no tiene sentido).
function T.Comparar(nuevo, puestos)
	local peor = nil
	for _, p in ipairs(puestos) do
		if p == false then return "vacia" end
		if peor == nil or p < peor then peor = p end
	end
	if peor == nil then return "vacia" end
	if peor <= 0 then return "sinbase" end
	return (nuevo - peor) / peor * 100
end

---------------------------------------------------------------------------
-- Bonificaciones "Equipar:" (C_Item.GetItemStats NO las trae en Forever:
-- sanación, daño de hechizos, maná cada 5 s, crítico, golpe...). Se leen del
-- texto del cuadro del objeto. Reglas propias por palabras clave (español y
-- inglés). Una línea "Equipar:" que no se entiende se cuenta como DESCONOCIDA:
-- con alguna desconocida, el Tasador no afirma que la pieza sea mejora.
---------------------------------------------------------------------------

local function Numeros(texto)
	local n = {}
	for x in texto:gmatch("%d+%.?%d*") do n[#n + 1] = tonumber(x) end
	return n
end

local function Tiene(texto, ...)
	for i = 1, select("#", ...) do
		if texto:find((select(i, ...)), 1, true) then return true end
	end
	return false
end

-- Se busca en minúsculas (la línea se pasa a minúsculas solo para esto: las raíces no llevan tilde).
local ESCUELA = {
	{ "naturaleza", "spNature" }, { "nature", "spNature" },
	{ "arcan", "spArcane" }, { "fuego", "spFire" }, { "fire", "spFire" },
	{ "escarcha", "spFrost" }, { "frost", "spFrost" }, { "sombra", "spShadow" }, { "shadow", "spShadow" },
	{ "sagrad", "spHoly" }, { "holy", "spHoly" },
}

-- Solo se aceptan bonificaciones FIJAS, que empiezan con "Aumenta / Mejora / Restaura / +N"
-- (o "Increases / Improves / Restores"). Un efecto por probabilidad ("Tus golpes críticos tienen
-- un 10% de probabilidad de aturdir", "Al golpear...") NO es una estadística: queda como desconocido.
local INICIOS = { "Aumenta", "Mejora", "Restaura", "Increases", "Improves", "Restores" }
local function EsFijo(texto)
	local t = texto:gsub("^%s+", "")
	if t:find("^%+%d") then return true end
	for _, p in ipairs(INICIOS) do
		if t:sub(1, #p) == p then return true end
	end
	return false
end

-- Una línea SIN el prefijo "Equipar:". Devuelve { clave = valor } o nil si no se entiende.
function T.ClasificarEquipar(texto)
	if type(texto) ~= "string" or not EsFijo(texto) then return nil end
	-- "un 10% de probabilidad de ..." / "chance to ... when" = efecto que salta, no estadística fija.
	if Tiene(texto, "de probabilidad", "chance on", "chance when", " when ", " cuando ", " al ") then return nil end
	-- Bonificación temporal ("... durante 10 s", "for 10 sec"): tampoco es fija.
	if Tiene(texto, "durante", " for ", " sec") then return nil end
	local n = Numeros(texto)
	local a, b = n[1], n[2]
	if not a then return nil end
	if Tiene(texto, "maná cada 5", "mana cada 5", "mana per 5", "mana every 5") then return { mp5 = a } end
	if Tiene(texto, "salud cada 5", "health per 5", "health every 5") then return { hp5 = a } end
	local sanacion = Tiene(texto, "sanación", "sanacion", "healing")
	local dano = Tiene(texto, "daño", "dano", "damage")
	local hechizo = Tiene(texto, "hechizo", "spell", "magic")
	if sanacion and dano and b and Tiene(texto, "sanación realizada", "healing done") then
		return { heal = a, sp = b } -- "hasta A de sanación y hasta B de daño"
	end
	if sanacion and dano then return { sp = a, heal = a } end -- "daño y sanación": como Polestar (sp y heal)
	if sanacion then return { heal = a } end
	if dano and hechizo then
		local bajo = texto:lower()
		for _, e in ipairs(ESCUELA) do
			if bajo:find(e[1], 1, true) then return { [e[2]] = a } end
		end
		return { sp = a }
	end
	local critico = Tiene(texto, "crítico", "critico", "critical", "crit")
	local golpe = Tiene(texto, "golpear", "acertar", "to hit", "hit with")
	local todos = Tiene(texto, "hechizos y ataques", "spells and attacks")
	if critico and todos then return { crit = a, spellCrit = a } end
	if golpe and todos then return { hit = a, spellHit = a } end
	if critico then return hechizo and { spellCrit = a } or { crit = a } end
	if golpe then return hechizo and { spellHit = a } or { hit = a } end
	if Tiene(texto, "a distancia", "ranged") then return {} end -- poder de ataque a distancia: no sirve al druida
	if Tiene(texto, "poder de ataque", "attack power") then return { ap = a } end
	if Tiene(texto, "esquivar", "dodge") then return { dodge = a } end
	if Tiene(texto, "defensa", "defense") then return { defense = a } end
	return nil
end

-- lineas = lista de textos del cuadro del objeto. prefijo = "Equipar:" del cliente.
-- Devuelve extra (tabla de claves cortas), desconocidas (número).
function T.LeerEquipar(lineas, prefijo)
	local extra, desconocidas = {}, 0
	local prefijos = { prefijo or "Equipar:", "Equipar:", "Equip:" }
	for _, linea in ipairs(lineas or {}) do
		if type(linea) == "string" then
			for _, p in ipairs(prefijos) do
				if linea:sub(1, #p) == p then
					local c = T.ClasificarEquipar(linea:sub(#p + 1))
					if c then
						for k, v in pairs(c) do extra[k] = (extra[k] or 0) + v end
					else
						desconocidas = desconocidas + 1
					end
					break
				end
			end
		end
	end
	return extra, desconocidas
end

-- Puntaje con las estadísticas del juego más las "Equipar:" leídas del cuadro.
-- Si una clave ya viene en las del juego, no se suma dos veces.
function T.PuntajeTotal(stats, extra, pesos)
	local total = T.Puntaje(stats, pesos)
	if not pesos or not extra then return total end
	local yaViene = {}
	for clave in pairs(stats or {}) do
		local corto = T.STAT[clave]
		if corto then yaViene[corto] = true end
	end
	for corto, valor in pairs(extra) do
		if not yaViene[corto] and pesos[corto] then total = total + valor * pesos[corto] end
	end
	return total
end

---------------------------------------------------------------------------
-- Herramientas de profesión: nunca venderlas ni botarlas.
-- IDs de Vanilla (hechos del juego): pico de minero, cuchillo de desollar,
-- martillo de herrero, llave de ingeniero, cañas de pescar y varas rúnicas.
---------------------------------------------------------------------------
T.HERRAMIENTAS = {
	[2901] = true, [7005] = true, [12709] = true, [5956] = true, [6219] = true, [10498] = true,
	[6256] = true, [6365] = true, [6366] = true, [6367] = true, [12225] = true, [19022] = true, [19970] = true,
	[6218] = true, [6339] = true, [11130] = true, [11145] = true, [16207] = true,
}
T.SUB_CANA = 20 -- subclase de arma "caña de pescar"

function T.EsHerramienta(id, clase, subclase)
	if id and T.HERRAMIENTAS[id] then return true end
	return clase == 2 and subclase == T.SUB_CANA
end

---------------------------------------------------------------------------
-- Rol del druida a partir del nombre de la rama de talentos (cualquier idioma
-- que use estas raíces) o de su posición (1 Equilibrio, 2 Feral, 3 Restauración).
---------------------------------------------------------------------------
local ORDEN_ROL = { "equilibrio", "feral", "sanacion" }

function T.RolDeNombre(nombre, posicion)
	if type(nombre) == "string" then
		if nombre:find("[Ff]eral") then return "feral" end
		if nombre:find("[Ee]quilibr") or nombre:find("[Bb]alance") then return "equilibrio" end
		if nombre:find("[Rr]estaur") or nombre:find("[Rr]estoration") then return "sanacion" end
	end
	return posicion and ORDEN_ROL[posicion] or nil
end

-- columnas = { { name = ..., points = ... }, ... }. Devuelve el rol con más puntos o nil.
function T.RolDeColumnas(columnas)
	if type(columnas) ~= "table" then return nil end
	local mejor, max = nil, 0
	for i, c in ipairs(columnas) do
		local p = type(c) == "table" and c.points
		if type(p) == "number" and p > max then
			local rol = T.RolDeNombre(c.name, i)
			if rol then mejor, max = rol, p end
		end
	end
	return mejor
end
