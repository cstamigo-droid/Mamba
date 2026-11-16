-- Simulación mínima del cliente de WoW: Forever para probar Asistente + Asistente_Servicios fuera del juego.
chat = {}
handlers = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) table.insert(chat, m) end }

-- Marco genérico: guarda lo que importa (texto, puntos, visible, rotación) y acepta todo lo demás.
local Marco = {}
Marco.__index = function(t, k)
	local v = rawget(Marco, k)
	if v ~= nil then return v end
	if type(k) == "string" and k:match("^%u") then return function() end end -- métodos del juego (Mayúscula)
	return nil
end
function Marco:RegisterEvent(e) self.ev[e] = true end
function Marco:UnregisterEvent(e) self.ev[e] = nil end
function Marco:SetScript(nombre, fn)
	self.scripts[nombre] = fn
	if nombre == "OnEvent" then table.insert(handlers, self) end
end
function Marco:GetScript(n) return self.scripts[n] end
function Marco:Show() self.visible = true end
function Marco:Hide() self.visible = false end
function Marco:IsShown() return self.visible end
function Marco:SetText(t) self.text = t end
function Marco:GetText() return self.text or "" end
function Marco:SetTexture(t) self.texture = t end
function Marco:SetRotation(r) self.rotation = r end
function Marco:SetPoint(...) self.point = { ... } end
function Marco:GetWidth() return self.w or 100 end
function Marco:GetHeight() return self.h or 100 end
function Marco:SetSize(w, h) self.w, self.h = w, h end
function Marco:SetAlpha(a) self.alpha = a end
function Marco:GetFrameLevel() return 1 end
function Marco:CreateFontString() return NuevoMarco() end
function Marco:CreateTexture() return NuevoMarco() end
function NuevoMarco(nombre)
	local f = setmetatable({ ev = {}, scripts = {}, visible = true }, Marco)
	if nombre then _G[nombre] = f end
	return f
end
CREADOS = {} -- { padre = ..., plantilla = ... } de cada CreateFrame (para revisar el arreglo del taint)
function CreateFrame(_, nombre, padre, plantilla)
	local f = NuevoMarco(nombre)
	table.insert(CREADOS, { padre = padre, plantilla = plantilla })
	if plantilla == "BasicFrameTemplateWithInset" then f.TitleText = NuevoMarco() end -- como la plantilla real
	return f
end
Marco.SetParent = function(self, p) self.parent = p end
UIParent = NuevoMarco()
UISpecialFrames = {}
GameTooltip = NuevoMarco()

function Fire(e, ...)
	for _, f in ipairs(handlers) do if f.ev[e] then f.scripts.OnEvent(f, e, ...) end end
end
SlashCmdList = {}
function Slash(cmd, arg)
	for k, fn in pairs(SlashCmdList) do
		for i = 1, 3 do if _G["SLASH_" .. k .. i] == cmd then return fn(arg or "") end end
	end
	error("no existe " .. cmd)
end

-- Jugador
POS = { x = 0, y = 0, z = 10, mapa = 1 }
FACING = 0
COMBATE = false
MAPA = nil
function UnitPosition() if POS_SECRETA then return SECRET, SECRET, 0, 1 end return POS.x, POS.y, POS.z, POS.mapa end
SECRET = setmetatable({}, { __tostring = function() return "SECRETO" end })
function issecretvalue(v) return v == SECRET end
function GetPlayerFacing() return FACING end
function UnitClass() return "Druida", "DRUID" end
function UnitFactionGroup() return "Horde" end
function InCombatLockdown() return COMBATE end
function GetTime() return NOW or 0 end
function IsIndoors() return false end
function GetCVar(k) return CVARS and CVARS[k] end
C_Map = {
	GetBestMapForUnit = function() return MAPA end,
	GetMapInfo = function(m) return ({ [1454] = { name = "Orgrimmar" }, [1456] = { name = "Cima del Trueno" } })[m] end,
}
C_Minimap = nil
Minimap = NuevoMarco(); Minimap.w = 140
Minimap.GetZoom = function() return 0 end
WorldMapFrame = NuevoMarco()
WorldMapFrame.GetMapID = function() return WORLDMAP_ID end
CANVAS = NuevoMarco(); CANVAS.w, CANVAS.h = 1000, 667
WorldMapFrame.GetCanvas = function() return CANVAS end

-- Addons: qué hay cargado y qué se puede cargar
CARGADOS = { Asistente = true }
CARGABLES = { Asistente_Servicios = true }
CARGAS = {}
C_AddOns = {
	IsAddOnLoaded = function(n) return CARGADOS[n] or false end,
	LoadAddOn = function(n)
		table.insert(CARGAS, n)
		if CARGABLES[n] then
			CARGADOS[n] = true
			if CARGAR_MODULO and n == "Asistente_Servicios" then CARGAR_MODULO() end
			if n == "Polestar_Nav" and MOTOR_AL_CARGAR then Polestar_NavEngine = MOTOR_AL_CARGAR end
			return true
		end
		return false, "MISSING"
	end,
}

-- Motor de rutas de Polestar simulado: guarda el pedido; la prueba decide cuándo responde.
function NuevoMotor()
	local M = { pedidos = {} }
	function M.Available(map) return map == 1 end
	function M.Find(map, from, to, cb, opts)
		table.insert(M.pedidos, { map = map, from = from, to = to, cb = cb, opts = opts })
		return {}
	end
	function M.Cancel() end
	return M
end
