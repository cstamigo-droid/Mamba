-- Simulación mínima del cliente de WoW: Forever para probar el Tasador fuera del juego.
handlers = {}
chat = {}
warnings = {}
sounds = 0
DEFAULT_CHAT_FRAME = { AddMessage = function(self, m) table.insert(chat, m) end }
function CreateFrame()
	local f = { ev = {} }
	function f:RegisterEvent(e) self.ev[e] = true end
	function f:UnregisterEvent(e) end
	function f:SetScript(_, fn) table.insert(handlers, { f = self, fn = fn }) end
	return f
end
function Fire(e, ...) for _, h in ipairs(handlers) do if h.f.ev[e] then h.fn(h.f, e, ...) end end end
SlashCmdList = {}
ITEMS = {}

-- Valores secretos: SECRET es un valor que el addon no debe usar.
SECRET = setmetatable({}, { __tostring = function() return "SECRETO" end })
function issecretvalue(v) return v == SECRET end

local function idDe(x)
	return type(x) == "number" and x or tonumber(tostring(x):match("item:(%d+)"))
end
C_Item = {
	GetItemInfo = function(x)
		local id = idDe(x)
		local i = ITEMS[id]
		INFO_CALLS = (INFO_CALLS or 0) + 1
		if not i then return nil end
		return i.name, "|Hitem:" .. id .. "|h[" .. i.name .. "]|h", i.q, i.ilvl or 30, i.req or 30, "", "", i.stack or 1, i.loc or "", 0,
			i.sell, i.cls, i.sub or 0, i.bind or 0, 0, nil, i.reag or false
	end,
	GetItemInfoInstant = function(x)
		local id = idDe(x)
		local i = ITEMS[id]
		if not i then return nil end
		INSTANT_CALLS = (INSTANT_CALLS or 0) + 1
		return id, "", "", i.loc or "", 0, i.cls, i.sub or 0
	end,
	GetItemStats = function(link) local id = idDe(link); return ITEMS[id] and ITEMS[id].stats end,
	RequestLoadItemDataByID = function() end,
}
-- El cuadro del objeto: líneas de texto (para las bonificaciones "Equipar:").
ITEM_SPELL_TRIGGER_ONEQUIP = "Equipar:"
ITEM_SOULBOUND = "Ligado"
RETRIEVING_ITEM_INFO = "Recuperando información del objeto"
C_TooltipInfo = {
	GetHyperlink = function(link)
		local i = ITEMS[idDe(link)]
		if not i then return nil end
		local lines = { { leftText = i.name } }
		for _, t in ipairs(i.tip or {}) do lines[#lines + 1] = { leftText = t } end
		return { lines = lines }
	end,
}
EQUIP = {}
EQUIP_LINK = {}
function GetInventoryItemLink(_, slot)
	if EQUIP_LINK[slot] then return EQUIP_LINK[slot] end
	local id = EQUIP[slot]; return id and ("|Hitem:" .. id .. "|h[x]|h") or nil
end
UNITS = {}
function UnitClass(u)
	if u == "player" then return "Druida", "DRUID" end
	return UNITS[u] and UNITS[u].cl or "Guerrero", UNITS[u] and UNITS[u].tok or "WARRIOR"
end
function UnitLevel(u) if u == "player" then return 37 end return UNITS[u] and UNITS[u].lvl or 1 end
function UnitIsPlayer(u) return UNITS[u] ~= nil end
function UnitCanAttack(_, u) return UNITS[u] ~= nil and UNITS[u].atk ~= false end
function UnitFactionGroup(u) if u == "player" then return "Horde" end return UNITS[u] and UNITS[u].fac end
function UnitName(u) return UNITS[u] and UNITS[u].name end
function IsInInstance() return INST or false end
function GetTime() return NOW or 0 end
RaidWarningFrame = {}
ChatTypeInfo = { RAID_WARNING = {} }
function RaidNotice_AddMessage(_, t) table.insert(warnings, t) end
SOUNDKIT = { RAID_WARNING = 8959 }
function PlaySound() sounds = sounds + 1 end
RAID_CLASS_COLORS = { PALADIN = { colorStr = "fff58cba" } }

-- Talentos de Forever: un árbol C_Traits con una columna por rama.
TALENT_COLS = nil -- { {name=..., points=...}, ... }
C_ClassTalents = { GetActiveConfigID = function() return TALENT_COLS and 1 or nil end }
C_Traits = {
	GetConfigInfo = function() return { treeIDs = { 10 } } end,
	GetGroupDisplayInfoByTreeID = function()
		local out = {}
		for i, c in ipairs(TALENT_COLS or {}) do out[i] = { groupID = 100 + i, displayName = c.name } end
		return out
	end,
	GetGroupCurrencyInfo = function()
		local out = {}
		for i, c in ipairs(TALENT_COLS or {}) do out[i] = { traitNodeGroupID = 100 + i, currencyInfos = { { spent = c.points } } } end
		return out
	end,
}

-- Subasta (Auctionator).
PRICES = {}
PRICES_LINK = {}
DAY0 = 1577836800
TODAY = 1000
function time(t) if t then return DAY0 end return DAY0 + TODAY * 86400 + 3600 end
Auctionator = { API = { v1 = {
	GetAuctionPriceByItemLink = function(_, link) return PRICES_LINK[link] or PRICES[tonumber(link:match("item:(%d+)"))] end,
	GetAuctionPriceByItemID = function(_, id) return PRICES[id] end,
	GetAuctionAgeByItemID = function(_, id) return AGES and AGES[id] end,
	GetAuctionAgeByItemLink = function(_, link) return AGES and AGES[tonumber(link:match("item:(%d+)"))] end,
} }, Database = { db = {} }, Constants = { SCAN_DAY_0 = DAY0 } }
-- Temporizador con cola: cada tanda corre aparte (como en el juego, en cuadros distintos).
TIMERS = {}
C_Timer = { After = function(_, fn) TIMER_CALLS = (TIMER_CALLS or 0) + 1; table.insert(TIMERS, fn) end }
function RunTimers()
	MAX_BATCH = 0
	while #TIMERS > 0 do
		local fn = table.remove(TIMERS, 1)
		local antes = INSTANT_CALLS or 0
		fn()
		local hecho = (INSTANT_CALLS or 0) - antes
		if hecho > MAX_BATCH then MAX_BATCH = hecho end
	end
end

BAG, STACK, BOUND = {}, {}, {}
C_Container = {
	GetContainerNumSlots = function(b) return b == 0 and #BAG or 0 end,
	GetContainerItemLink = function(b, s) local id = BAG[s]; return id and ("|Hitem:" .. id .. "|h[x]|h") end,
	GetContainerItemInfo = function(b, s) return { stackCount = STACK[s] or 1, isBound = BOUND[s] or false } end,
}
GameTooltip = {
	lines = {},
	AddLine = function(self, t) table.insert(self.lines, t) end,
	AddDoubleLine = function(self, a, b) table.insert(self.lines, a .. " | " .. b) end,
	Show = function() end,
	GetItem = function(self) return "x", self.link end,
}
ItemRefTooltip = {}
Enum = { TooltipDataType = { Item = 0 } }
TooltipDataProcessor = { AddTooltipPostCall = function(_, fn) TIP_HOOK = fn end }
-- Muestra el cuadro de un objeto como lo haría el cliente.
function ShowTip(link, extraLines)
	GameTooltip.lines = {}
	GameTooltip.link = link
	local lines = {}
	for _, t in ipairs(extraLines or {}) do lines[#lines + 1] = { leftText = t } end
	TIP_HOOK(GameTooltip, { id = tonumber(link:match("item:(%d+)")), lines = lines })
	return GameTooltip.lines
end
