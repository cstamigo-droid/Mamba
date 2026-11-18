-- El hub de Polestar simulado para probar las secciones de Mamba (Asistente/Hub.lua) fuera del juego.
-- Se carga después de mock_wow.lua y mock_ventana.lua. Si las piezas REALES de Polestar (Theme/Widgets.lua)
-- cargaron, la prueba las usa (USAR_W_REAL); si no, usa estas, con las mismas firmas.
local PS = Polestar
PS.UI = PS.UI or {}
REGISTRADAS = {}
SHOWPICKER = 0
SECCION = nil
local win = CreateFrame("Frame", "PolestarPicker")
win:Hide()
win.TabRow = CreateFrame("Frame"); win.TabRow.padre = win
PESTANAS_VISTAS, TITULO_VISTO = {}, {}

function PS.UI.RegisterSection(spec)
	REGISTRADAS[spec.key] = spec
	return true
end
local P = {}
PS.UI.Picker = P
function P.Section() return SECCION end
function P.ShowSection(k) SECCION = k; P.Render() end
function P.Render()
	local s = SECCION and REGISTRADAS[SECCION]
	if not (s and win:IsShown()) then return end
	if not s.psFrame then
		s.psFrame = CreateFrame("Frame", nil, win)
		s.psFrame.w, s.psFrame.h = 900, 560
		s.build(s.psFrame, win)
	end
	for _, o in pairs(REGISTRADAS) do if o.psFrame then o.psFrame:SetShown(o == s) end end
	PESTANAS_VISTAS = {}
	s.render()
	if s.nav then NAV_ITEMS, NAV_ACTIVO = s.nav() end
end
function PS.UI.ShowPicker() SHOWPICKER = SHOWPICKER + 1; win:Show(); P.Render() end

AJUSTES = { ["qol.sellJunk"] = true, ["qol.autoRepair"] = false }
function PS.Get(k) return AJUSTES[k] end
function PS.Set(k, v) AJUSTES[k] = v end
FIRED = {}
function PS.Fire(msg, ...) table.insert(FIRED, { msg, ... }) end

if not USAR_W_REAL then
	local W = {}
	PS.Widgets = W
	PS.Theme = PS.Theme or {}
	function PS.Theme.Media(n) return "Interface\\AddOns\\Polestar\\Media\\UI\\" .. tostring(n) end
	local function txt(p) local f = p:CreateFontString(); f.esTexto = true; return f end
	function W.Text(p) return txt(p) end
	function W.Color(r, c) r.color = c end
	function W.Fill(p) return p:CreateTexture() end
	function W.Divider(p) return p:CreateTexture() end
	function W.Hover(p) return p:CreateTexture() end
	function W.Button(p, t, fn, o)
		local b = CreateFrame("Button", nil, p)
		b.Label = txt(b); b.Label:SetText(t)
		b.primario = o and o.primary
		b.activo = true
		function b:Enable() self.activo = true end
		function b:Disable() self.activo = false end
		function b:IsEnabled() return self.activo end
		if fn then b:SetScript("OnClick", fn) end
		return b
	end
	function W.SetButtonText(b, t) b.Label:SetText(t) end
	function W.Checkbox(p, fn)
		local c = CreateFrame("CheckButton", nil, p)
		function c:SetChecked(v) self.marcado = v end
		function c:GetChecked() return self.marcado end
		if fn then c:SetScript("OnClick", fn) end
		return c
	end
	function W.Scroll(p)
		local sf = CreateFrame("ScrollFrame", nil, p)
		sf.w, sf.h = 870, 540
		sf.Child = CreateFrame("Frame", nil, sf)
		return sf
	end
	function W.SetScrollContent(sf, h) sf.contenido = h end
	function W.ScrollTo(sf, y) sf.scroll = y end
	function W.ItemTip(o, id, extra) GameTooltip:SetOwner(o); GameTooltip.itemID = id; GameTooltip.extra = extra end
	function W.HideTooltip() end
	function W.Tooltip(o, a, t, l) GameTooltip:SetOwner(o); GameTooltip.titulo = t end
	MENU = nil
	function W.ShowMenu(anchor, items) MENU = items end
end
-- las pestañas y el título los pone el hub (W.ShellTabs/ShellTitle): se anotan
PS.Widgets.ShellTabs = function(f, tabs, activo, fn)
	PESTANAS_VISTAS = tabs or {}
	PESTANA_ACTIVA, ON_TAB = activo, fn
end
PS.Widgets.ShellTitle = function(f, t, s) TITULO_VISTO = { t, s } end
