-- Mamba_Combate: núcleo. Ajustes, fallas al diagnóstico, eventos que quizá este cliente no tenga, y lectura
-- segura de los "valores secretos" de Forever (se muestran pero no se pueden comparar: aquí se devuelven nil).
-- Licencia: GPL-3.0-only.
local _, M = ...
_G.MambaCombate = M

M.DEFECTO = {
	modo = "auto", rol = "auto", sugerencia = true, resaltar = true, avisos = true, sonido = true,
	disparo = true, amenaza = true, placas = true, lanzamiento = true, numerosCD = true, medidor = true,
	avisoMana = 25, avisoAmenaza = 90, sonidoTodos = false, avisoAmenazaSi = true, avisoManaSi = true,
	cercanosSola = false, ficha = true, avisoDefensas = true, placaAncho = 100, placaAlto = 8, marcadores = "siempre", cercaBarra = "siempre", alfaMarcos = 100, agro = true, agroSiempre = false, agroPlacas = true,
}

function M.DB()
	MambaCombateDB = MambaCombateDB or {}
	local d = MambaCombateDB
	for k, v in pairs(M.DEFECTO) do if d[k] == nil then d[k] = v end end
	-- versión 2 de los ajustes (Cristian, 19-11: la ventana grande "no la necesito… que se pueda abrir pero no se
	-- abra sola"): la barrita «Cerca: N» es la vista principal; a quien la tenía encendida se le apaga una vez
	if (d.versionAjustes or 1) < 2 then
		d.cercanosSola = false
		d.versionAjustes = 2
	end
	d.diag = d.diag or {}
	return d
end

function M.Falla(donde, err)
	local d = M.DB().diag
	d.fallas = d.fallas or {}
	if #d.fallas < 30 then d.fallas[#d.fallas + 1] = (date and date("%d-%m %H:%M") or "") .. " " .. donde .. ": " .. tostring(err) end
	if geterrorhandler then geterrorhandler()(err) end
end
-- K105/K106 (opción b): contadores en MambaCombateDB.diag.k105 para saber, al cerrar el juego, qué señales da
-- Forever de verdad (PARTY_KILL, honor, DAMAGE_METER_*, peleas anteriores). Solo cuentan; no cambian nada.
function M.Contar(clave, dato)
	local d = M.DB().diag
	local k = d.k105 or { cuenta = {}, ultimo = {}, dato = {} }
	d.k105 = k
	k.cuenta[clave] = (k.cuenta[clave] or 0) + 1
	-- la hora de la última vez se escribe como mucho una vez por segundo por clave (DAMAGE_METER llega seguido)
	local t = (GetTime and M.Num(GetTime())) or 0
	M.contarHora = M.contarHora or {}
	if not M.contarHora[clave] or t - M.contarHora[clave] >= 1 then
		M.contarHora[clave] = t
		k.ultimo[clave] = date and date("%d-%m %H:%M:%S") or true
	end
	if dato ~= nil and k.dato[clave] == nil then k.dato[clave] = dato end -- el primer ejemplo, una vez
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
-- Sí/no del juego que puede venir SECRETO (en mazmorras y en combate, como en Midnight): probarlo con if/and/or
-- da «attempt to perform boolean test on a secret boolean value» (K110). Secreto = no se sabe = false.
function M.Si(v)
	if v == nil or M.Secreto(v) then return false end
	return v and true or false
end
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

-- K120: transparencia de los marcos de combate que quedan siempre a la vista (el tamaño se cambia con la rueda en
-- «Mover elementos»). 30-100 %.
M.TRANSPARENTES = { "MambaAgro", "MambaMedidorCombate", "MambaAmenaza", "MambaCercaBarra", "MambaRanking", "MambaDisparo", "MambaMarcadores" }
function M.AplicarTransparencia()
	local a = (M.Num(M.DB().alfaMarcos) or 100) / 100
	a = math.max(0.3, math.min(1, a))
	for _, n in ipairs(M.TRANSPARENTES) do
		local f = _G[n]
		if f and f.SetAlpha then f:SetAlpha(a) end
	end
	return a
end

local oyentes = {}
function M.AlCambiar(fn) oyentes[#oyentes + 1] = fn end
function M.Cambio()
	for _, fn in ipairs(oyentes) do pcall(fn) end
	M.Proteger("transparencia", M.AplicarTransparencia)
end

-- Un marco movible propio (K55): se registra en el modo «Mover elementos» de la ventana de Mamba
-- (MambaAPI.Movible, K55 ampliado) con su nombre en español (etiqueta). Estos marcos no tienen barra de título:
-- van con sinAsa = true, así solo se mueven en ese modo y no se arrastran por accidente al jugar; la posición y
-- el tamaño quedan por personaje. Sin la ventana de Mamba, se arrastran enteros fuera de combate.
function M.Movible(f, nombre, etiqueta)
	local api = _G.MambaAPI
	if api and api.Movible then
		-- si falla, que se vea en Errores (antes el pcall se lo tragaba)
		local ok, err = pcall(api.Movible, f, nombre, nil, { etiqueta = etiqueta, sinAsa = true })
		if not ok then M.Falla("movible:" .. tostring(nombre), err) end
	else
		-- sin la ventana de Mamba: se arrastra fuera de combate, pero el ratón solo se activa en marcos que ya
		-- lo usan (un cartel en el centro no se come los clics al mundo; revisión wow-addon-lua, 19-11)
		-- Si el marco tiene una franja de título con ratón (medidor, barra Cerca), se arrastra desde ella.
		f:SetMovable(true)
		local asa = (f.titulo and f.titulo.RegisterForDrag) and f.titulo or f
		asa:RegisterForDrag("LeftButton")
		asa:SetScript("OnDragStart", function() if not M.EnCombate() then f:StartMoving() end end)
		asa:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
	end
	M.movibles[nombre] = etiqueta or nombre
	return f
end
M.movibles = {} -- nombre del marco -> su nombre en español (lo que se puede mover)

-- Mientras el modo «Mover elementos» está abierto, cada módulo muestra con datos de ejemplo sus marcos que
-- están escondidos (para que el recuadro tenga a qué pegarse), y al cerrarlo los deja como estaban.
-- El modo se cierra solo al entrar en combate (Ventanas.lua). fn(activo)
local alMover = {}
function M.AlModoMover(fn) alMover[#alMover + 1] = fn end
function M.ModoMover(activo)
	M.moviendo = activo and true or false
	for _, fn in ipairs(alMover) do M.Proteger("mover", fn, M.moviendo) end
end
function M.ConectarMover()
	local api = _G.MambaAPI
	if M.moverConectado or not (api and api.AlModoMover) then return end
	M.moverConectado = true
	pcall(api.AlModoMover, M.ModoMover)
end

-- Los marcos que se arman recién cuando hacen falta se crean al entrar, ESCONDIDOS, para que «Mover elementos»
-- los encuentre aunque todavía no hayan salido en pantalla.
local precrear = {}
function M.Precrear(fn) precrear[#precrear + 1] = fn end
local fp = CreateFrame("Frame")
M.Escuchar(fp, "PLAYER_LOGIN")
fp:SetScript("OnEvent", function()
	for _, fn in ipairs(precrear) do M.Proteger("precrear", fn) end
	M.Proteger("transparencia", M.AplicarTransparencia)
	M.ConectarMover()
end)

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
