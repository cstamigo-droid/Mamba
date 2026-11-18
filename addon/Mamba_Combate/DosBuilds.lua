-- Mamba_Combate: plan de dos builds (K59) por la doble especialización desde el 40 (Blizzard, 15-10-2026).
--   1) Build principal y secundaria (de tus respuestas de Mi plan, o la secundaria natural de tu clase), cada una
--      con su build recomendada y su fuente (Asistente_Clase, por MambaAPI.Clase).
--   2) Mamba DECIDE con números entre: (a) subir con la de daño y activar la doble al 40, juntando de paso el equipo
--      de la otra; (b) llevar las dos ya, reiniciando talentos cada vez que cambias; (c) terminar una al 60 y
--      después la otra. Las horas hasta el 60 son las mismas en las tres (subes con la misma build; se muestran con
--      la XP/h MEDIDA o "sin datos aún"): deciden el oro y desde qué nivel puedes cumplir el segundo rol.
--   3) Tu equipo por ranura: sirve para las dos, solo para una o para ninguna, y qué cambiar primero.
-- Lo no verificado (costo de la doble: 50 o según Wowhead; reinicios 1/5/10 o según jugadores) va marcado.
-- Licencia: GPL-3.0-only.
local _, M = ...
local B = {}
M.DosBuilds = B

-- XP para pasar de nivel en Classic 1.12 (Forever: NO VERIFICADO; el nivel actual se lee del juego).
B.XP = { 400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600, 8800, 10100, 11400, 12900, 14400, 16000, 17700,
	19400, 21300, 23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400, 50800, 54500, 58600,
	62800, 67100, 71600, 76100, 80800, 85700, 90700, 95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100,
	141200, 147500, 153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800 }
B.COSTO_DOBLE = 500000           -- 50 o, NO VERIFICADO (Wowhead; Blizzard no lo confirmó: DRUIDA.md §1)
B.COSTO_REINICIOS = { 10000, 50000, 100000 } -- 1, 5 y 10 o: cifras de jugadores, NO VERIFICADO
B.NIVEL_DOBLE = 40

local ROL_TXT = { danio = "daño", ["daño"] = "daño", sanar = "curar", tanque = "tanque", jcj = "JcJ" }
-- Segundo rol natural de cada clase (si no lo elegiste en Mi plan)
B.SEGUNDO = { DRUID = "sanar", PRIEST = "danio", SHAMAN = "sanar", PALADIN = "sanar", WARRIOR = "tanque",
	HUNTER = "jcj", MAGE = "jcj", ROGUE = "jcj", WARLOCK = "jcj" } -- sin segundo rol de curar: daño en JcJ

function B.XPHasta60(nivel, xpAhora, xpMax)
	if nivel >= 60 then return 0 end
	local falta = math.max(0, (xpMax or B.XP[nivel] or 0) - (xpAhora or 0))
	for n = nivel + 1, 59 do falta = falta + (B.XP[n] or 0) end
	return falta
end

-- XP por hora MEDIDA por el Medidor, separada en solo (misiones) y mazmorras. nil si no hay 15 min medidos.
function B.XPHora()
	local Md = _G.Medidor
	local cubos = Md and Md.pj and Md.pj.cubos
	if type(cubos) ~= "table" then return nil end
	local s = { misiones = { 0, 0 }, mazmorra = { 0, 0 } }
	for _, c in pairs(cubos) do
		local k = (c.act == "mazmorra") and "mazmorra" or "misiones"
		s[k][1], s[k][2] = s[k][1] + (c.xp or 0), s[k][2] + (c.seg or 0)
	end
	local function h(x) return x[2] >= 900 and x[1] / (x[2] / 3600) or nil end
	return { solo = h(s.misiones), mazmorra = h(s.mazmorra) }
end

function B.Roles()
	local r = (MambaPlanPJ and MambaPlanPJ.respuestas) or {}
	local clase = M.Clase()
	local rol1 = r.rol
	if not rol1 then
		local s = M.Rotacion and M.Rotacion.Spec()
		rol1 = s and (s.rol == "daño" and "danio" or (s.rol == "sanar" and "sanar" or s.rol)) or "danio"
	end
	local rol2 = r.rol2
	if not rol2 or rol2 == rol1 then rol2 = B.SEGUNDO[clase] end
	if not rol2 or rol2 == rol1 then rol2 = (rol1 == "danio") and "jcj" or "danio" end
	return rol1, rol2
end

local function build(rol, uso)
	local api = _G.MambaAPI
	if not (api and api.Clase) then return nil end
	local ok, C = pcall(api.Clase)
	if not (ok and C and C.Builds) then return nil end
	local ok2, l = pcall(C.Builds, M.Clase(), rol, uso)
	if ok2 and l and l[1] then return l[1] end
	local ok3, l2 = pcall(C.Builds, M.Clase(), rol)
	return ok3 and l2 and l2[1] or nil
end

-- Las tres estrategias con sus números y la elegida (R0: horas, oro y desde qué nivel tienes el 2.º rol).
function B.Estrategias(nivel, xpH, valorHora)
	local falta = B.XPHasta60(nivel, UnitXP and UnitXP("player"), UnitXPMax and UnitXPMax("player"))
	local horas = (xpH and xpH > 0) and falta / xpH or nil
	local antes40 = nivel < B.NIVEL_DOBLE
	local reinicios = 0
	if antes40 then for _, c in ipairs(B.COSTO_REINICIOS) do reinicios = reinicios + c end end
	local e = {
		{ clave = "a", titulo = "Subir con la de daño y activar la doble especialización al 40",
			horas = horas, oro = B.COSTO_DOBLE, segundoDesde = math.max(nivel, B.NIVEL_DOBLE),
			como = "Subes al ritmo de daño; desde el 40 curas mazmorras con la segunda y juntas su equipo de paso." },
		{ clave = "b", titulo = "Llevar las dos ya",
			horas = horas, oro = B.COSTO_DOBLE + reinicios, segundoDesde = nivel,
			como = antes40 and "Antes del 40 cada cambio es reiniciar talentos (cuesta más cada vez)." or "Desde el 40 es lo mismo que la primera: las dos ya están." },
		{ clave = "c", titulo = "Terminar una al 60 y después la otra",
			horas = horas, oro = B.COSTO_DOBLE, segundoDesde = 60,
			como = "El segundo rol empieza al 60 y con su equipo desde cero." },
	}
	-- la cuenta: horas iguales en las tres (subes con la misma build); decide el oro (en horas de tu tiempo) y
	-- después cuánto antes tienes el segundo rol
	for _, x in ipairs(e) do
		x.costo = (x.horas or 0) + x.oro / math.max(1, valorHora or 1)
	end
	table.sort(e, function(a, b)
		if math.abs(a.costo - b.costo) > 0.01 then return a.costo < b.costo end
		return a.segundoDesde < b.segundoDesde
	end)
	e.falta = falta
	return e
end

---------------------------------------------------------------- equipo por ranura
B.RANURAS = { { 1, "Cabeza" }, { 2, "Cuello" }, { 3, "Hombros" }, { 15, "Espalda" }, { 5, "Pecho" }, { 9, "Muñecas" },
	{ 10, "Manos" }, { 6, "Cintura" }, { 7, "Piernas" }, { 8, "Pies" }, { 11, "Anillo" }, { 12, "Anillo" },
	{ 13, "Abalorio" }, { 14, "Abalorio" }, { 16, "Arma" }, { 17, "Mano izquierda" }, { 18, "Distancia o reliquia" } }
local MAGIA = { ITEM_MOD_INTELLECT_SHORT = true, ITEM_MOD_SPIRIT_SHORT = true, ITEM_MOD_SPELL_POWER_SHORT = true,
	ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = true, ITEM_MOD_MANA_REGENERATION_SHORT = true, ITEM_MOD_SPELL_HEALING_DONE_SHORT = true }
local CURA = { ITEM_MOD_INTELLECT_SHORT = true, ITEM_MOD_SPIRIT_SHORT = true, ITEM_MOD_SPELL_POWER_SHORT = true,
	ITEM_MOD_MANA_REGENERATION_SHORT = true, ITEM_MOD_SPELL_HEALING_DONE_SHORT = true }
local LANZA = { ITEM_MOD_INTELLECT_SHORT = true, ITEM_MOD_SPELL_POWER_SHORT = true, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = true }
local FISICO = { ITEM_MOD_AGILITY_SHORT = true, ITEM_MOD_STRENGTH_SHORT = true, ITEM_MOD_ATTACK_POWER_SHORT = true }
local TANQUE = { ITEM_MOD_STAMINA_SHORT = true, ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = true, RESISTANCE0_NAME = true,
	ITEM_MOD_AGILITY_SHORT = true, ITEM_MOD_STRENGTH_SHORT = true }
-- Clases que hacen daño con hechizos (el resto, físico); el druida depende de su especialización.
local LANZADORA = { MAGE = true, WARLOCK = true, PRIEST = true }

-- ¿Qué atributos quiere un rol? (tabla de claves)
function B.Quiere(rol)
	if rol == "sanar" then return CURA end
	if rol == "tanque" then return TANQUE end
	local clase = M.Clase()
	local s = M.Rotacion and M.Rotacion.Spec()
	if LANZADORA[clase] or (s and (s.clave == "equilibrio" or s.clave == "elemental")) then return LANZA end
	return FISICO
end

-- Para qué rol sirve una pieza: "dos" | "rol1" | "rol2" | "nada"
function B.SirvePara(stats, rol1, rol2)
	local q1, q2 = B.Quiere(rol1), B.Quiere(rol2)
	local s1, s2, algo = false, false, false
	for k in pairs(stats or {}) do
		local kk = tostring(k)
		if not kk:find("_SHORT$") and kk:find("^ITEM_MOD") then kk = kk .. "_SHORT" end
		algo = true
		if q1[kk] then s1 = true end
		if q2[kk] then s2 = true end
	end
	if not algo then return "nada" end
	if s1 and s2 then return "dos" elseif s1 then return "rol1" elseif s2 then return "rol2" end
	return "nada"
end

function B.Equipo(rol1, rol2)
	local out = {}
	for _, r in ipairs(B.RANURAS) do
		local link = GetInventoryItemLink and GetInventoryItemLink("player", r[1])
		if link then
			local stats = (C_Item and C_Item.GetItemStats and C_Item.GetItemStats(link)) or (GetItemStats and GetItemStats(link)) or {}
			out[#out + 1] = { ranura = r[2], link = link, sirve = B.SirvePara(stats, rol1, rol2) }
		else
			out[#out + 1] = { ranura = r[2], sirve = "vacia" }
		end
	end
	return out
end

-- Por qué gana la primera contra la segunda (con el número que decide).
function B.Porque(x, y)
	if x.costo < y.costo - 0.01 then return " · Gana: cuesta " .. M.Dinero(y.oro - x.oro) .. " menos." end
	if y.segundoDesde > x.segundoDesde then return " · Gana: tienes el segundo rol " .. (y.segundoDesde - x.segundoDesde) .. " niveles antes, al mismo costo." end
	return " · Empata con la siguiente: elige la que prefieras."
end

---------------------------------------------------------------- filas para el panel
function M.FilasDosBuilds()
	local nivel = UnitLevel and UnitLevel("player") or 1
	local rol1, rol2 = B.Roles()
	local cab = { titulo = ("Dos formas de jugar: %s y %s"):format(ROL_TXT[rol1] or tostring(rol1), ROL_TXT[rol2] or tostring(rol2)),
		linea1 = "Desde el nivel 40 tu instructor de clase te deja tener dos juegos de talentos y cambiar entre ellos (costo aproximado 50 o: confírmalo con él).",
		linea2 = "Tus roles salen de Mi plan (puedes cambiarlos en «Cambiar mis respuestas»)." }
	local out = {}
	for i, rol in ipairs({ rol1, rol2 }) do
		local b = build(rol, i == 1 and "subir" or "mazmorra")
		out[#out + 1] = { tipo = i == 1 and "Principal" or "Secundaria", titulo = "Para " .. (ROL_TXT[rol] or rol) .. ": " .. ((b and (b.nombre or b.clave)) or "sin plan de talentos cargado aún"),
			detalle = b and b.fuente and ("Fuente: " .. tostring(type(b.fuente) == "table" and (b.fuente[1] or "") or b.fuente)) or nil,
			acciones = { { "Ver talentos", function() local api = _G.MambaAPI; if api and api.Abrir then pcall(api.Abrir, "MambaClase", "talentos") end end }, { "Buscar instructor", M.BuscarInstructor } } }
	end
	local xph = B.XPHora()
	local api = _G.MambaAPI
	local valor
	if api and api.OroPorHora then local ok, r = pcall(api.OroPorHora); valor = ok and r and r.actual end
	local medidoValor = valor ~= nil
	valor = valor or nivel * 2500
	local est = B.Estrategias(nivel, xph and xph.solo, valor)
	for i, x in ipairs(est) do
		out[#out + 1] = { tipo = i == 1 and "MEJOR" or ("#" .. i), titulo = x.titulo,
			detalle = ("%s · oro: %s · segundo rol desde el nivel %d"):format(
				x.horas and (("%.0f h hasta el 60 (con tu experiencia por hora medida)"):format(x.horas)) or "horas hasta el 60: sin datos aún (se mide solo mientras juegas)",
				M.Dinero and M.Dinero(x.oro) or (math.floor(x.oro / 10000) .. " o"), x.segundoDesde),
			conf = x.como .. ((i == 1 and est[2]) and B.Porque(x, est[2]) or "") }
	end
	local eq = B.Equipo(rol1, rol2)
	local nada = {}
	local TXT = { dos = "sirve para las dos", rol1 = "solo para " .. (ROL_TXT[rol1] or rol1), rol2 = "solo para " .. (ROL_TXT[rol2] or rol2), nada = "no sirve para ninguna", vacia = "vacía" }
	local cuenta = {}
	for _, x in ipairs(eq) do
		cuenta[x.sirve] = (cuenta[x.sirve] or 0) + 1
		if x.sirve ~= "dos" and x.sirve ~= "vacia" then nada[#nada + 1] = x.ranura .. " (" .. TXT[x.sirve] .. ")" end
	end
	out[#out + 1] = { tipo = "Equipo", titulo = ("%d piezas sirven para las dos formas de jugar"):format(cuenta.dos or 0),
		detalle = #nada > 0 and ("Para cambiar de rol con lo mínimo, busca primero: " .. table.concat(nada, ", ")) or "Todo lo que llevas sirve para las dos.",
		conf = "Cuenta los atributos que pide cada forma de jugar (por ejemplo, intelecto sirve a Equilibrio y a Restauración; aguante y armadura, al oso).",
		acciones = { { "Ver en Equipo", function() if api and api.Abrir then pcall(api.Abrir, "MambaEquipo", "mejorar") end end } } }
	return out, cab
end

function M.Dinero(c)
	c = math.floor((c or 0) + 0.5)
	local o, p = math.floor(c / 10000), math.floor(c / 100) % 100
	if o > 0 then return o .. " o" .. (p > 0 and (" " .. p .. " p") or "") end
	return p .. " p"
end
