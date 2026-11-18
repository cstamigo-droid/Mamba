-- Simulación del cliente de Forever para probar Mamba_Barras fuera del juego (Lua 5.1, lupa).
-- No simula LibActionButton: la reemplaza por una falsa que anota lo que se le pide (la real funciona en
-- Forever: es la que usa Bartender4 4.19.0, instalada y en uso por Cristian el 18-11).
-- Reglas del cliente que SÍ se simulan, porque ya rompieron algo en el juego:
--  * registrar un evento que Forever no conoce da error (18-11, Tasador);
--  * en combate, tocar un marco protegido da error ("ADDON_ACTION_BLOCKED").
EVENTOS_DESCONOCIDOS = { AUCTION_ITEM_LIST_UPDATE = true, TRADE_SKILL_UPDATE = true, PET_BAR_UPDATE_USABLE = true }
COMBATE = false
BLOQUEOS = {}
handlers = {}
frames = {}
BINDINGS = {}       -- comando -> { teclas }
OVERRIDES = {}      -- tecla -> "nombreBoton"
GUARDADO = 0
ACCIONES = {}       -- casilla -> true
CLASE = "DRUID"
FORMAS = { { 132276, false, true, 5487 }, { 132115, true, true, 768 } }

local function protegido(f, que)
	if COMBATE and f.protegido then
		table.insert(BLOQUEOS, (f.nombre or "?") .. ":" .. que)
		error("ADDON_ACTION_BLOCKED " .. que)
	end
end

local Marco = {}
Marco.__index = Marco
function Marco:RegisterEvent(e)
	if EVENTOS_DESCONOCIDOS[e] then error('Frame:RegisterEvent(): Attempt to register unknown event "' .. e .. '"') end
	self.ev[e] = true
end
function Marco:UnregisterEvent(e) self.ev[e] = nil end
function Marco:UnregisterAllEvents() self.ev = {} end
function Marco:SetScript(k, fn) self.scripts[k] = fn; if k == "OnEvent" then table.insert(handlers, self) end end
function Marco:GetScript(k) return self.scripts[k] end
function Marco:HookScript(k, fn) self.scripts[k] = fn end
function Marco:Show() protegido(self, "Show"); self.visible = true end
function Marco:Hide() protegido(self, "Hide"); self.visible = false end
function Marco:IsShown() return self.visible end
function Marco:IsVisible() return self.visible end
function Marco:SetShown(v) if v then self:Show() else self:Hide() end end
function Marco:SetParent(p) protegido(self, "SetParent"); self.padre = p end
function Marco:GetParent() return self.padre end
function Marco:SetPoint(...) protegido(self, "SetPoint"); self.punto = { ... } end
function Marco:ClearAllPoints() protegido(self, "ClearAllPoints"); self.punto = nil end
function Marco:SetAllPoints(o) self.todo = o end
function Marco:SetSize(w, h) protegido(self, "SetSize"); self.w, self.h = w, h end
function Marco:SetWidth(w) self.w = w end
function Marco:SetHeight(h) self.h = h end
function Marco:GetWidth() return self.w or 45 end
function Marco:GetHeight() return self.h or 45 end
function Marco:SetScale(s) protegido(self, "SetScale"); self.escala = s end
function Marco:GetScale() return self.escala or 1 end
function Marco:SetAlpha(a) self.alfa = a end
function Marco:GetAlpha() return self.alfa or 1 end
function Marco:SetAttribute(k, v) protegido(self, "SetAttribute"); self.attr[k] = v end
function Marco:GetAttribute(k) return self.attr[k] end
function Marco:GetName() return self.nombre end
function Marco:GetLeft() return 100 end
function Marco:GetBottom() return 50 end
function Marco:IsMouseOver() return false end
function Marco:SetChecked(v) self.marcado = v end
function Marco:GetChecked() return self.marcado end
function Marco:RegisterForClicks() end
function Marco:RegisterForDrag() end
function Marco:EnableMouse() end
function Marco:EnableKeyboard(v) self.teclado = v end
function Marco:EnableMouseWheel() end
function Marco:SetMovable() end
function Marco:SetClampedToScreen() end
function Marco:SetFrameStrata(e) self.estrato = e end
function Marco:SetFrameLevel() end
function Marco:GetFrameLevel() return 1 end
function Marco:SetToplevel() end
function Marco:StartMoving() end
function Marco:StopMovingOrSizing() end
function Marco:SetScrollChild(c) self.hijo = c end
function Marco:SetVerticalScroll() end
function Marco:GetVerticalScroll() return 0 end
function Marco:SetHighlightTexture() end
function Marco:SetText(t) self.texto = t end
function Marco:GetText() return self.texto end
function Marco:SetAutoFocus() end
function Marco:ClearFocus() end
function Marco:GetFontString() return nil end
function Marco:SetMinMaxValues() end
function Marco:SetValueStep() end
function Marco:SetObeyStepOnDrag() end
function Marco:SetValue(v) self.valor = v end
local function textura()
	local t = setmetatable({}, { __index = function() return function() end end })
	return t
end
function Marco:CreateTexture() return textura() end
function Marco:CreateFontString()
	local fs = textura()
	fs.SetText = function(s, t) s.texto = t end
	fs.GetStringWidth = function() return 60 end
	return fs
end

function CreateFrame(tipo, nombre, padre, plantilla)
	local f = setmetatable({ ev = {}, scripts = {}, attr = {}, nombre = nombre, padre = padre, tipo = tipo,
		plantilla = plantilla, visible = true }, Marco)
	if plantilla and (plantilla:find("Secure") ) then f.protegido = true end
	if plantilla and plantilla:find("ActionButtonTemplate") then
		f.icon = textura(); f.HotKey = f:CreateFontString(); f.cooldown = textura()
	end
	if nombre then _G[nombre] = f end
	table.insert(frames, f)
	return f
end
UIParent = CreateFrame("Frame", "UIParent")
function UIParent:GetWidth() return 1920 end
function UIParent:GetHeight() return 1080 end

function Fire(e, ...)
	for _, f in ipairs(handlers) do
		if f.ev[e] and f.scripts.OnEvent then f.scripts.OnEvent(f, e, ...) end
	end
end

-- funciones del juego
function InCombatLockdown() return COMBATE end
function UnitClass() return "Druida", CLASE end
function UnitName() return "Hope" end
function GetRealmName() return "Fé" end
function GetBuildInfo() return "1.60.1", "70938", "nov", 16001 end
function date() return "18-11 12:00" end
function geterrorhandler() return function(e) table.insert(ERRORES, tostring(e)) end end
ERRORES = {}
function HasAction(c) return ACCIONES[c] or false end
C_ActionBar = { HasAction = HasAction }
function GetOverrideBarIndex() return 18 end
function GetVehicleBarIndex() return 16 end
DRIVERS = {}
function RegisterStateDriver(f, estado, cond)
	protegido(f, "RegisterStateDriver")
	DRIVERS[(f.nombre or "?") .. ":" .. estado] = cond
end
function UnregisterStateDriver(f, estado)
	protegido(f, "UnregisterStateDriver")
	DRIVERS[(f.nombre or "?") .. ":" .. estado] = nil
end
function GetBindingKey(cmd) return unpack(BINDINGS[cmd] or {}) end
function GetBindingText(k) return k end
function SetBinding(k, cmd)
	for c, ks in pairs(BINDINGS) do
		for i = #ks, 1, -1 do if ks[i] == k then table.remove(ks, i) end end
	end
	if cmd then BINDINGS[cmd] = BINDINGS[cmd] or {}; table.insert(BINDINGS[cmd], k) end
end
function SaveBindings() GUARDADO = GUARDADO + 1 end
function GetCurrentBindingSet() return 2 end
function GetNumBindings()
	local n = 0
	ORDEN = {}
	for c in pairs(BINDINGS) do n = n + 1; ORDEN[n] = c end
	return n
end
function GetBinding(i)
	local c = ORDEN[i]
	local ks = BINDINGS[c] or {}
	return c, "cat", ks[1], ks[2]
end
function ClearOverrideBindings(dueno)
	if COMBATE then table.insert(BLOQUEOS, "ClearOverrideBindings"); error("bloqueado") end
	OVERRIDES = {}
end
function SetOverrideBindingClick(dueno, prio, k, boton)
	if COMBATE then table.insert(BLOQUEOS, "SetOverrideBindingClick"); error("bloqueado") end
	OVERRIDES[k] = boton
end
function GetNumShapeshiftForms() return #FORMAS end
function GetShapeshiftFormInfo(i) local f = FORMAS[i]; if f then return f[1], f[2], f[3], f[4] end end
function GetPetActionInfo(i) return nil end
function IsAltKeyDown() return false end
function IsControlKeyDown() return false end
function IsShiftKeyDown() return false end
C_Timer = { After = function(_, fn) fn() end }
C_AddOns = { IsAddOnLoaded = function(n) return CARGADOS and CARGADOS[n] or false end }
GameTooltip = CreateFrame("Frame", "GameTooltip")
function ReloadUI() end

-- LibStub mínima y una LibActionButton falsa
local libs = {}
LibStub = setmetatable({ NewLibrary = function(_, n) libs[n] = libs[n] or {}; return libs[n] end },
	{ __call = function(_, n) return libs[n] end })
local LAB = LibStub:NewLibrary("LibActionButton-1.0")
function LAB:CreateButton(id, nombre, cabecera, config)
	local b = CreateFrame("CheckButton", nombre, cabecera, "ActionButtonTemplate, SecureActionButtonTemplate")
	b.id, b.header, b.config, b.estados = id, cabecera, config, {}
	function b:SetState(estado, tipo, accion)
		protegido(self, "SetState")
		self.estados[tostring(estado)] = { tipo, accion }
	end
	function b:UpdateConfig(c)
		protegido(self, "UpdateConfig")
		self.config = c
	end
	return b
end
