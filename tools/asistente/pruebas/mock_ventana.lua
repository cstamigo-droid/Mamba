-- Marcos del juego simulados para probar la ventana de Mamba (Asistente/Ventana.lua) fuera del juego.
-- Se carga DESPUÉS de mock_wow.lua: reemplaza CreateFrame por marcos que guardan texto, puntos, tamaño,
-- scripts y visibilidad, y aceptan (sin hacer nada) cualquier otro método del juego.
local Marco = {}
Marco.__index = function(_, k)
	local v = rawget(Marco, k)
	if v ~= nil then return v end
	if type(k) == "string" and k:match("^%u") then return function() end end
	return nil
end
function Marco:RegisterEvent(e) self.ev[e] = true end
function Marco:UnregisterEvent(e) self.ev[e] = nil end
function Marco:SetScript(nombre, fn)
	self.scripts[nombre] = fn
	if nombre == "OnEvent" then table.insert(handlers, { f = self, fn = fn }) end
end
function Marco:GetScript(n) return self.scripts[n] end
function Marco:HookScript(n, fn)
	local antes = self.scripts[n]
	self.scripts[n] = function(...) if antes then antes(...) end fn(...) end
end
function Marco:Show() self.visible = true end
function Marco:Hide()
	local estaba = self.visible
	self.visible = false
	if estaba and self.scripts.OnHide then self.scripts.OnHide(self) end
end
function Marco:IsShown() return self.visible end
function Marco:IsVisible()
	local f = self
	while f do
		if not f.visible then return false end
		f = f.padre
	end
	return true
end
function Marco:SetShown(v) if v then self:Show() else self:Hide() end end
function Marco:SetText(t) self.text = t end
function Marco:GetText() return self.text or "" end
function Marco:GetStringHeight() return 14 end
function Marco:GetStringWidth() return #(self.text or "") * 6 end
function Marco:SetPoint(...) self.point = { ... } end
function Marco:SetSize(w, h) self.w, self.h = w, h end
function Marco:SetWidth(w) self.w = w end
function Marco:SetHeight(h) self.h = h end
function Marco:GetWidth() return self.w or 100 end
function Marco:GetHeight() return self.h or 300 end
function Marco:SetParent(p) self.padre = p end
function Marco:GetParent() return self.padre end
function Marco:EnableMouse(v) self.raton = v end
function Marco:SetVerticalScroll(y) self.scroll = y end
function Marco:GetVerticalScroll() return self.scroll or 0 end
function Marco:SetScrollChild(c) self.hijo = c; c.padre = self end
function Marco:CreateFontString() local f = NuevoMarco(); f.padre = self; return f end
function Marco:CreateTexture() local f = NuevoMarco(); f.padre = self; return f end
function Marco:SetTexture(t) self.texture = t end
function Marco:Click() if self.scripts.OnClick then self.scripts.OnClick(self, "LeftButton") end end
function NuevoMarco(nombre)
	local f = setmetatable({ ev = {}, scripts = {}, visible = true }, Marco)
	if nombre then _G[nombre] = f end
	TODOS[#TODOS + 1] = f
	return f
end
TODOS = {}
function CreateFrame(tipo, nombre, padre, plantilla)
	local f = NuevoMarco(nombre)
	f.tipo, f.padre, f.plantilla = tipo, padre, plantilla
	if plantilla == "BasicFrameTemplateWithInset" then f.TitleText = NuevoMarco(); f.TitleText.padre = f end
	return f
end
UIParent = NuevoMarco()
Minimap = NuevoMarco(); Minimap.w = 140
function Minimap:GetCenter() return 100, 100 end
UISpecialFrames = {}
function GetCursorPosition() return 0, 0 end
GameTooltip = NuevoMarco()
function GameTooltip:SetOwner(o) self.dueno = o; self.lineas = {}; self.enlace = nil end
function GameTooltip:SetHyperlink(l) self.enlace = l end
function GameTooltip:AddLine(t) table.insert(self.lineas, t) end
ERRORES = {}
function geterrorhandler() return function(e) table.insert(ERRORES, tostring(e)) end end
function Slash(cmd, arg)
	for k, fn in pairs(SlashCmdList) do
		for i = 1, 3 do if _G["SLASH_" .. k .. i] == cmd then return fn(arg or "") end end
	end
	error("no existe " .. cmd)
end
