-- Juego falso para probar el Medidor fuera de WoW. Solo imita las funciones que el Medidor usa.
frames = {}
chat = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, m) table.insert(chat, m) end }
function CreateFrame()
	local f = { ev = {}, scripts = {} }
	function f:RegisterEvent(e) self.ev[e] = true end
	function f:SetScript(n, fn) self.scripts[n] = fn end
	table.insert(frames, f)
	return f
end
function Fire(e, ...)
	for _, f in ipairs(frames) do
		if f.ev[e] and f.scripts.OnEvent then f.scripts.OnEvent(f, e, ...) end
	end
end
function Tick(seg)
	for _, f in ipairs(frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f, seg) end end
end
SlashCmdList = {}

-- Estado del personaje que cada prueba cambia
P = { xp = 1000, max = 5000, nivel = 37, dinero = 10000, zona = "Mil Agujas", inst = false, tipo = "none", afk = false }
function UnitName() return "Hope" end
function GetRealmName() return "Reino" end
function UnitXP() if P.secreto then return SECRETO end return P.xp end
function UnitXPMax() return P.max end
function UnitLevel() return P.nivel end
function GetMoney() return P.dinero end
function GetRealZoneText() return P.zona end
function IsInInstance() return P.inst, P.tipo end
-- Dentro de una instancia el juego da su nombre; P.instNombre permite simular la zona atrasada
function GetInstanceInfo() if P.inst then return P.instNombre or P.zona, P.tipo end return P.zona, "none" end
INSTANCE_RESET_SUCCESS = "%s has been reset."

function UnitIsAFK() return P.afk end
RELOJ = 1000000
function time() return RELOJ end
-- Valores secretos de Forever: SECRETO es un objeto que da error si se compara o se suma
SECRETO = setmetatable({}, { __lt = function() error("secreto comparado") end, __le = function() error("secreto comparado") end,
	__sub = function() error("secreto restado") end, __add = function() error("secreto sumado") end })
function issecretvalue(v) return v == SECRETO end

-- Bolsas: BOLSA[i] = {itemID=, stackCount=}; una sola bolsa de 16 huecos
NUM_BAG_SLOTS = 4
NUM_TOTAL_EQUIPPED_BAG_SLOTS = 5   -- la bolsa 5 (componentes) también se lee
COMPONENTES = {}
BOLSA = {}
C_Container = {
	GetContainerNumSlots = function(b) return (b == 0 and 16) or (b == 5 and 4) or 0 end,
	GetContainerItemInfo = function(b, s) if b == 5 then return COMPONENTES[s] end return BOLSA[s] end,
}
PUESTO = {}
function GetInventoryItemID(_, s) return PUESTO[s] end

-- Objetos: ITEMS[id] = {vendedor, liga}; si no está, el juego "no lo tiene cargado"
ITEMS = {}
PEDIDOS = {}
C_Item = {
	GetItemInfo = function(id)
		local i = ITEMS[id]
		if not i then return nil end
		return "obj" .. id, "", 1, 1, 1, "", "", 20, "", 0, i[1], 7, 0, i[2] or 0
	end,
	RequestLoadItemDataByID = function(id) PEDIDOS[id] = true end,
}
PRECIOS = {}
Auctionator = { API = { v1 = { GetAuctionPriceByItemID = function(_, id) return PRECIOS[id] end } } }

-- Profesiones: PROF = { {nombre, rango, id}, ... } en el orden que las devuelve GetProfessions
PROF = {}
function GetProfessions()
	-- como el juego: huecos vacíos son nil (primaria 2 vacía, por ejemplo)
	return PROF[1] and 1 or nil, PROF[2] and 2 or nil, nil, PROF[4] and 4 or nil, PROF[5] and 5 or nil
end
function GetProfessionInfo(i)
	local p = PROF[i]
	return p[1], "icono", p[2], 300, 0, 0, p[3]
end
