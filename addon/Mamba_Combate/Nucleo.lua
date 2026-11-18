-- Mamba_Combate: núcleo. Ajustes, fallas al diagnóstico, eventos que quizá este cliente no tenga, y lectura
-- segura de los "valores secretos" de Forever (se muestran pero no se pueden comparar: aquí se devuelven nil).
-- Licencia: GPL-3.0-only.
local _, M = ...
_G.MambaCombate = M

M.DEFECTO = {
	modo = "auto", rol = "auto", sugerencia = true, resaltar = true, avisos = true, sonido = true,
	disparo = true, amenaza = true, placas = true, lanzamiento = true, numerosCD = true, medidor = true,
	avisoMana = 25, avisoAmenaza = 90, sonidoTodos = false, avisoAmenazaSi = true, avisoManaSi = true,
}

function M.DB()
	MambaCombateDB = MambaCombateDB or {}
	local d = MambaCombateDB
	for k, v in pairs(M.DEFECTO) do if d[k] == nil then d[k] = v end end
	d.diag = d.diag or {}
	return d
end

function M.Falla(donde, err)
	local d = M.DB().diag
	d.fallas = d.fallas or {}
	if #d.fallas < 30 then d.fallas[#d.fallas + 1] = (date and date("%d-%m %H:%M") or "") .. " " .. donde .. ": " .. tostring(err) end
	if geterrorhandler then geterrorhandler()(err) end
end
function M.Proteger(donde, fn, ...)
	local ok, a, b, c = pcall(fn, ...)
	if not ok then M.Falla(donde, a); return nil end
	return a, b, c
end
function M.Escuchar(f, ev, unidad)
	local ok
	if unidad and f.RegisterUnitEvent then ok = pcall(f.RegisterUnitEvent, f, ev, unidad)
	else ok = pcall(f.RegisterEvent, f, ev) end
	if not ok then
		local d = M.DB().diag
		d.eventosNo = d.eventosNo or {}
		d.eventosNo[ev] = true
	end
	return ok
end

function M.Secreto(v) return issecretvalue ~= nil and issecretvalue(v) end
-- Número que se puede usar en cuentas, o nil si el juego lo esconde.
function M.Num(v)
	if v == nil or M.Secreto(v) or type(v) ~= "number" then return nil end
	return v
end
function M.Pct(a, b)
	a, b = M.Num(a), M.Num(b)
	if not (a and b) or b <= 0 then return nil end
	return a / b * 100
end

function M.Clase() return UnitClass and select(2, UnitClass("player")) or "WARRIOR" end
function M.EnCombate() return InCombatLockdown and InCombatLockdown() or (UnitAffectingCombat and UnitAffectingCombat("player")) end

function M.NombreHechizo(id)
	return (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)) or ("hechizo " .. tostring(id))
end
function M.Icono(id)
	local i = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
	return i or 134400
end
-- "{8921}" -> nombre en el idioma del juego
function M.Texto(t)
	return ((t or ""):gsub("{(%d+)}", function(id) return M.NombreHechizo(tonumber(id)) end))
end

function M.Conoce(id)
	if IsPlayerSpell and IsPlayerSpell(id) then return true end
	if IsSpellKnown and IsSpellKnown(id) then return true end
	local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
	return n ~= nil and GetSpellInfo ~= nil and GetSpellInfo(n) ~= nil
end

-- Botones de "Cómo jugar" y "Dos formas de jugar" (K61): el libro de hechizos y el instructor (Servicios de Mamba).
function M.AbrirLibro()
	if M.EnCombate() then return end
	if ToggleSpellBook then pcall(ToggleSpellBook, BOOKTYPE_SPELL or "spell") end
end
function M.BuscarInstructor()
	local api = _G.MambaAPI
	if api and api.Abrir then pcall(api.Abrir, "MambaServicios") end
end

local oyentes = {}
function M.AlCambiar(fn) oyentes[#oyentes + 1] = fn end
function M.Cambio() for _, fn in ipairs(oyentes) do pcall(fn) end end

-- Un marco movible propio (K55), con la ventana de Mamba si está.
function M.Movible(f, nombre)
	local api = _G.MambaAPI
	if api and api.Movible then pcall(api.Movible, f, nombre) else
		f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", function(s) if not M.EnCombate() then s:StartMoving() end end)
		f:SetScript("OnDragStop", f.StopMovingOrSizing)
	end
	return f
end

-- Barra simple (estado + texto) para disparo, lanzamiento y amenaza.
function M.Barra(padre, ancho, alto, nombre)
	local b = CreateFrame("StatusBar", nombre, padre or UIParent)
	b:SetSize(ancho, alto)
	b:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	b:SetMinMaxValues(0, 1)
	b.fondo = b:CreateTexture(nil, "BACKGROUND")
	b.fondo:SetAllPoints(b)
	b.fondo:SetColorTexture(0.05, 0.05, 0.06, 0.8)
	b.texto = M.Piezas.Texto(b, "small", "text")
	b.texto:SetPoint("CENTER", b, "CENTER", 0, 0)
	return b
end
