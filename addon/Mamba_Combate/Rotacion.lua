-- Mamba_Combate: sugerencia de rotación con un motor propio (C2b; C_AssistedCombat no está en Forever: el
-- diagnóstico del 18-11 dio IsAvailable() = false) y los modos de pelea (M1).
--   - Lee la prioridad de "Cómo jugar" (C1b) del modo actual (solo, varios, mazmorra, jcj, jefe; emergencia
--     encima si tu vida baja) y marca el primer paso que se puede hacer AHORA: hechizo aprendido, usable, sin
--     enfriamiento y con sus condiciones cumplidas. Lo que Forever esconde (vida del objetivo, auras ajenas en
--     instancias) queda "?" y no se adivina.
--   - Solo MUESTRA: un recuadro con el próximo hechizo y su tecla, y un borde en el botón de tus barras.
--     Mamba no decide ni lanza nada (lo prohíbe Blizzard: C2⛔).
--   - Modos de pelea (M1): el modo y el rol cambian solos con el contexto (grupo, instancia, campo de batalla,
--     forma del druida, doble especialización) o con un botón; cada rol muestra u oculta los marcos de curación
--     y la amenaza.
-- Licencia: GPL-3.0-only.
local _, M = ...
local R = {}
M.Rotacion = R

R.MODOS = { { "solo", "Solo" }, { "varios", "Varios" }, { "mazmorra", "Mazmorra" }, { "jcj", "Contra jugadores" }, { "jefe", "Jefe largo" } }
local NOMBRE_MODO = {}
for _, m in ipairs(R.MODOS) do NOMBRE_MODO[m[1]] = m[2] end
NOMBRE_MODO.emergencia = "Emergencia"
R.NOMBRE_MODO = NOMBRE_MODO

local OSO, GATO, OSO_TEMIBLE = 5487, 768, 9634

---------------------------------------------------------------- lectura del juego
local function aura(unidad, id, filtro)
	local nombre = M.NombreHechizo(id)
	local A = C_UnitAuras
	if A and A.GetAuraDataBySpellName then
		local ok, a = pcall(A.GetAuraDataBySpellName, unidad, nombre, filtro)
		if not ok then return nil end
		if M.Secreto(a) then return nil end
		return a ~= nil
	end
	if A and A.GetAuraDataByIndex then
		for i = 1, 40 do
			local ok, a = pcall(A.GetAuraDataByIndex, unidad, i, filtro)
			if not ok then return nil end
			if not a then return false end
			if M.Secreto(a.name) or M.Secreto(a.spellId) then return nil end
			if a.name == nombre or a.spellId == id then return true end
		end
		return false
	end
end

local function poder(tipo) return M.Num(UnitPower and UnitPower("player", tipo)) end

function R.Enemigos()
	local N = C_NamePlate
	if not (N and N.GetNamePlates) then return nil end
	local n = 0
	for _, p in ipairs(N.GetNamePlates() or {}) do
		local u = p.namePlateUnitToken or (p.UnitFrame and p.UnitFrame.unit)
		if u and UnitCanAttack and UnitCanAttack("player", u) and UnitAffectingCombat and UnitAffectingCombat(u) then n = n + 1 end
	end
	return n
end

-- Una condición: true, false o nil (el juego no deja saberlo).
function R.Condicion(c)
	local k, v = c[1], c[2]
	if k == "sinDebuff" then local a = UnitExists("target") and aura("target", v, "HARMFUL|PLAYER"); if a == nil then return nil end; return not a
	elseif k == "sinBuff" then local a = aura("player", v, "HELPFUL"); if a == nil then return nil end; return not a
	elseif k == "buff" or k == "forma" then return aura("player", v, "HELPFUL")
	elseif k == "vidaObj<" then local p = M.Pct(UnitHealth("target"), UnitHealthMax("target")); return p and p < v
	elseif k == "vida<" then local p = M.Pct(UnitHealth("player"), UnitHealthMax("player")); return p and p < v
	elseif k == "vida>=" then local p = M.Pct(UnitHealth("player"), UnitHealthMax("player")); return p and p >= v
	elseif k == "mana<" then local p = M.Pct(UnitPower("player", 0), UnitPowerMax("player", 0)); return p and p < v
	elseif k == "energia>=" then local p = poder(3); return p and p >= v
	elseif k == "ira>=" then local p = poder(1); return p and p >= v
	elseif k == "combo>=" then
		local p = GetComboPoints and M.Num(GetComboPoints("player", "target")) or poder(14)
		return p and p >= v
	elseif k == "enemigos>=" then local n = R.Enemigos(); return n and n >= v
	elseif k == "sinForma" then return (GetShapeshiftForm and GetShapeshiftForm() or 0) == 0
	elseif k == "mascota" then return UnitExists("pet") and true or false
	elseif k == "amenaza>=" then
		if not UnitDetailedThreatSituation then return nil end
		local _, _, pct = UnitDetailedThreatSituation("player", "target")
		pct = M.Num(pct)
		return pct and pct >= v
	elseif k == "fueraDeCombate" then return not (UnitAffectingCombat and UnitAffectingCombat("player"))
	end
	return nil
end

-- ¿Se puede lanzar ya? (aprendido, usable y sin enfriamiento; lo secreto cuenta como sí)
function R.Listo(id)
	if not M.Conoce(id) then return false, "noSabe" end
	local nombre = M.NombreHechizo(id)
	if C_Spell and C_Spell.IsSpellUsable then
		local ok, usable, sinMana = pcall(C_Spell.IsSpellUsable, nombre)
		if ok and not M.Secreto(usable) and not usable then return false, sinMana and "mana" or "noUsable" end
	end
	if C_Spell and C_Spell.GetSpellCooldown then
		local ok, cd = pcall(C_Spell.GetSpellCooldown, nombre)
		if ok and cd then
			local ini, dur = M.Num(cd.startTime), M.Num(cd.duration)
			if ini and dur and ini > 0 and dur > 1.6 then
				local resta = ini + dur - (GetTime and GetTime() or 0)
				if resta > 0.3 then return false, "enfriamiento", resta end
			end
		end
	end
	return true
end

---------------------------------------------------------------- especialización, rol y modo
function R.Datos() return (M.JUGAR or {})[M.Clase()] end

local function puntos(i)
	if not GetTalentTabInfo then return 0 end
	local t = { GetTalentTabInfo(i) }
	return tonumber(t[5]) or tonumber(t[3]) or 0
end

function R.ArbolMayor()
	local mejor, max = 1, -1
	for i = 1, (GetNumTalentTabs and GetNumTalentTabs() or 3) do
		local p = puntos(i)
		if p > max then mejor, max = i, p end
	end
	return mejor
end

function R.Spec()
	local d = R.Datos()
	if not d then return nil end
	local elegida = M.DB().spec
	if elegida then for _, s in ipairs(d.specs) do if s.clave == elegida then return s end end end
	-- druida: la forma manda
	if M.Clase() == "DRUID" then
		local clave
		if aura("player", OSO, "HELPFUL") or aura("player", OSO_TEMIBLE, "HELPFUL") then clave = "oso"
		elseif aura("player", GATO, "HELPFUL") then clave = "gato" end
		if clave then for _, s in ipairs(d.specs) do if s.clave == clave then return s end end end
	end
	local arbol = R.ArbolMayor()
	for _, s in ipairs(d.specs) do if s.arbol == arbol then return s end end
	return d.specs[1]
end

-- Los casos de una especialización (o los de la que "usa")
function R.Casos(s)
	if not s then return {} end
	if s.usa then
		for _, x in ipairs(R.Datos().specs) do if x.clave == s.usa then return x.casos or {} end end
	end
	return s.casos or {}
end

function R.ModoAuto()
	local _, tipo
	if IsInInstance then _, tipo = IsInInstance() end
	if tipo == "pvp" or tipo == "arena" then return "jcj" end
	if UnitExists("target") and UnitIsPlayer and UnitIsPlayer("target") and UnitCanAttack and UnitCanAttack("player", "target") then return "jcj" end
	if tipo == "party" or tipo == "raid" then
		local nivel = UnitLevel and M.Num(UnitLevel("target"))
		local clas = UnitClassification and UnitClassification("target")
		if M.Secreto(clas) then clas = nil end
		if nivel == -1 or clas == "worldboss" then return "jefe" end
		return "mazmorra"
	end
	local n = R.Enemigos()
	if n and n >= 3 then return "varios" end
	return "solo"
end

function R.Modo()
	local m = M.DB().modo
	if m == "auto" or not NOMBRE_MODO[m] then return R.ModoAuto(), true end
	return m, false
end

-- Rol para los modos de pelea (M1): el de la especialización elegida o detectada.
function R.Rol()
	local r = M.DB().rol
	if r ~= "auto" then return r end
	local s = R.Spec()
	return s and s.rol or "daño"
end

---------------------------------------------------------------- el motor
-- -> { modo, spec, pasos = { { paso, estado = "si"|"quizas"|"no", porque, tecla } }, ahora = índice }
function R.Evaluar()
	local s = R.Spec()
	if not s then return nil end
	local casos = R.Casos(s)
	local modo = R.Modo()
	local caso = casos[modo] or casos.solo or casos.mazmorra
	local vida = M.Pct(UnitHealth("player"), UnitHealthMax("player"))
	if vida and vida < 35 and casos.emergencia then caso, modo = casos.emergencia, "emergencia" end
	if not caso then return { modo = modo, spec = s, pasos = {} } end
	local out = { modo = modo, spec = s, pasos = {}, nota = caso.nota }
	for _, p in ipairs(caso.pasos or {}) do
		local listo, porque = R.Listo(p.h)
		local estado = "no"
		if listo then
			estado = "si"
			for _, c in ipairs(p.c or {}) do
				local v = R.Condicion(c)
				if v == false then estado = "no"; porque = c[1]; break end
				if v == nil then estado = "quizas" end
			end
		end
		if porque ~= "noSabe" then
			out.pasos[#out.pasos + 1] = { paso = p, estado = estado, porque = porque }
		end
	end
	-- el primero en orden que no está descartado: si es "?" se muestra con "?" (no se salta lo dudoso)
	for i, x in ipairs(out.pasos) do if x.estado ~= "no" then out.ahora = i; break end end
	return out
end

---------------------------------------------------------------- dónde está ese hechizo en tus barras
local function botonesCon(id)
	local slots = {}
	if C_ActionBar and C_ActionBar.FindSpellActionButtons then
		local ok, l = pcall(C_ActionBar.FindSpellActionButtons, id)
		if ok and type(l) == "table" then for _, s in ipairs(l) do slots[s] = true end end
	end
	local out = {}
	R.nombres = R.nombres or {}
	for i = 1, 120 do
		local nb = R.nombres[i]
		if not nb then nb = "MambaBoton" .. i; R.nombres[i] = nb end
		local b = _G[nb]
		if b and b.IsVisible and b:IsVisible() then
			local a = b._state_action or b.action
			if a and slots[a] then out[#out + 1] = b end
		end
	end
	for i = 1, 12 do
		local b = _G["ActionButton" .. i]
		if b and b.IsVisible and b:IsVisible() and b.action and slots[b.action] then out[#out + 1] = b end
	end
	return out
end
R.BotonesCon = botonesCon

function R.Tecla(id, lista)
	for _, b in ipairs(lista or botonesCon(id)) do
		local hk = b.HotKey and b.HotKey.GetText and b.HotKey:GetText()
		if hk and hk ~= "" and hk ~= "●" then return hk end
	end
end

local brillos = {}
local function brillo(b)
	local g = brillos[b]
	if not g then
		g = CreateFrame("Frame", nil, b)
		g:SetAllPoints(b)
		g:SetFrameLevel((b.GetFrameLevel and b:GetFrameLevel() or 1) + 5)
		for _, lado in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
			local t = g:CreateTexture(nil, "OVERLAY")
			t:SetColorTexture(1, 0.82, 0.2, 0.95)
			t:SetPoint(lado[1], g, lado[1])
			t:SetPoint(lado[2], g, lado[2])
			if lado[3] then t:SetHeight(2) else t:SetWidth(2) end
		end
		brillos[b] = g
	end
	return g
end

---------------------------------------------------------------- el recuadro "Siguiente"
local caja
local function crearCaja()
	caja = CreateFrame("Frame", "MambaSiguiente", UIParent)
	caja:SetSize(150, 66)
	caja:SetPoint("CENTER", UIParent, "CENTER", 0, -160)
	M.Movible(caja, "MambaSiguiente", "Sugerencia de hechizo")
	caja.modo = CreateFrame("Button", nil, caja)
	caja.modo:SetSize(150, 14)
	caja.modo:SetPoint("BOTTOM", caja, "TOP", 0, 2)
	caja.modo.texto = M.Piezas.Texto(caja.modo, "small", "text")
	caja.modo.texto:SetAllPoints(caja.modo)
	caja.modo:SetScript("OnClick", function() R.SiguienteModo() end)
	caja.iconos = {}
	for i = 1, 3 do
		local f = CreateFrame("Frame", nil, caja)
		local t = i == 1 and 46 or 30
		f:SetSize(t, t)
		if i == 1 then f:SetPoint("LEFT", caja, "LEFT", 0, 0) else f:SetPoint("LEFT", caja.iconos[i - 1], "RIGHT", 6, 0) end
		f.icono = f:CreateTexture(nil, "ARTWORK")
		f.icono:SetAllPoints(f)
		f.tecla = M.Piezas.Texto(f, "small", "text")
		f.tecla:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
		f.duda = M.Piezas.Texto(f, "body", "text")
		f.duda:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 1)
		caja.iconos[i] = f
	end
end

M.Precrear(function() if not caja then crearCaja(); caja:Hide() end end)
M.AlModoMover(function(activo)
	if not caja then crearCaja(); caja:Hide() end
	if activo then
		if not caja:IsShown() then
			caja.ejemplo = true
			caja.modo.texto:SetText("Sugerencia de hechizo (ejemplo)")
			for _, f in ipairs(caja.iconos) do f.icono:SetTexture(134400); f.tecla:SetText(""); f.duda:SetText(""); f:Show() end
			caja:Show()
		end
	elseif caja.ejemplo then
		caja.ejemplo = nil
		caja:Hide()
		R.Dibujar()
	end
end)

-- Línea de arriba de la caja: modo · especialización, y «(auto)» o «(fijo)». Corta, y el botón se ensancha
-- a lo que mida el texto (en el juego salía «Solo · Equilibrio · automát…», 18-11).
function R.TextoModo(modo, spec, auto)
	return (NOMBRE_MODO[modo] or modo) .. " · " .. (spec or "") .. (auto and " (auto)" or " (fijo)")
end

-- Pasa al modo siguiente con el botón (auto → solo → varios → … → auto)
function R.SiguienteModo()
	local d = M.DB()
	local orden = { "auto", "solo", "varios", "mazmorra", "jcj", "jefe" }
	local i = 1
	for k, v in ipairs(orden) do if v == d.modo then i = k end end
	d.modo = orden[i % #orden + 1]
	M.Cambio()
end

local ultimo = {}
function R.Dibujar()
	if caja and caja.ejemplo then return end -- modo «Mover elementos»
	local d = M.DB()
	for b, g in pairs(brillos) do g:Hide() end
	if not d.sugerencia then if caja then caja:Hide() end return end
	local e = R.Evaluar()
	if not caja then crearCaja() end
	if not e or (#e.pasos == 0) or not (UnitExists("target") or M.EnCombate()) then caja:Hide(); return end
	if e.spec.rol == "sanar" and (e.modo == "mazmorra" or e.modo == "jefe") then caja:Hide(); return end
	local modo, auto = R.Modo()
	caja.modo.texto:SetText(R.TextoModo(e.modo, e.spec.nombre, auto))
	local fs = caja.modo.texto
	local medir = fs.GetUnboundedStringWidth or fs.GetStringWidth
	local ancho = medir and M.Num(medir(fs))
	caja.modo:SetWidth(math.max(150, (ancho or 0) + 12))
	local lista = {}
	if e.ahora then
		for i = e.ahora, #e.pasos do
			if e.pasos[i].estado ~= "no" then lista[#lista + 1] = e.pasos[i] end
			if #lista == 3 then break end
		end
	end
	for i, f in ipairs(caja.iconos) do
		local x = lista[i]
		if x then
			x.botones = botonesCon(x.paso.h)
			f.icono:SetTexture(M.Icono(x.paso.h))
			f.tecla:SetText(R.Tecla(x.paso.h, x.botones) or "")
			f.duda:SetText(x.estado == "quizas" and "?" or "")
			f:Show()
		else
			f:Hide()
		end
	end
	caja:Show()
	ultimo = lista
	if d.resaltar and lista[1] then
		for _, b in ipairs(lista[1].botones or botonesCon(lista[1].paso.h)) do brillo(b):Show() end
	end
end
function R.Ultimo() return ultimo end

---------------------------------------------------------------- modos de pelea (M1)
-- Qué muestra cada rol: curación (marcos de grupo), amenaza y disparo.
R.PERFIL_ROL = {
	sanar = { curacion = true, amenaza = false },
	tanque = { curacion = false, amenaza = true },
	["daño"] = { curacion = false, amenaza = true },
}
local rolAplicado
function R.AplicarRol()
	local rol = R.Rol()
	if rol == rolAplicado then return end
	if M.EnCombate() then return end -- se aplica al salir de combate
	rolAplicado = rol
	local p = R.PERFIL_ROL[rol] or R.PERFIL_ROL["daño"]
	local Cu = _G.MambaCuracion
	if Cu and Cu.Mostrar then
		-- sanar: a la vista aun sin grupo; los otros roles dejan lo que el jugador eligió en Curación
		pcall(Cu.Mostrar, p.curacion and true or nil)
	end
	if M.Amenaza and M.Amenaza.MostrarPorRol then M.Amenaza.MostrarPorRol(p.amenaza) end
end
function R.RolAplicado() return rolAplicado end

---------------------------------------------------------------- eventos
local f = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UPDATE_SHAPESHIFT_FORM",
	"ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_ENTERING_WORLD", "SPELL_UPDATE_COOLDOWN" }) do M.Escuchar(f, e) end
local sucio, t = true, 0
f:SetScript("OnEvent", function(_, e)
	sucio = true
	if e ~= "SPELL_UPDATE_COOLDOWN" and e ~= "PLAYER_TARGET_CHANGED" then
		M.Proteger("rol", R.AplicarRol)
	end
end)
f:SetScript("OnUpdate", function(_, dt)
	t = t + (dt or 0)
	local paso = M.EnCombate() and 0.1 or 0.5
	if t < paso and not sucio then return end
	t, sucio = 0, false
	M.Proteger("rotacion", R.Dibujar)
end)
M.AlCambiar(function() rolAplicado = nil; M.Proteger("rol", R.AplicarRol); M.Proteger("rotacion", R.Dibujar) end)
