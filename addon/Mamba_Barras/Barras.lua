-- Mamba_Barras: el motor. Barras de acción seguras (LibActionButton-1.0, BSD) que se mueven, se escalan,
-- cambian solas con la forma o la actitud, y esconden las barras del juego. Todo lo que toca un marco
-- protegido se hace FUERA de combate: si llega en combate, queda en espera y se aplica al salir.
-- Mamba no decide ni lanza nada por el jugador: los botones son los del juego, el jugador los aprieta.
-- Licencia: GPL-3.0-only.
local _, M = ...
local LAB = LibStub("LibActionButton-1.0")

M.marcos = {}      -- [id] = cabecera segura de la barra
M.botones = {}     -- [casilla] = botón (para las teclas)
M.listo = false

local oculto = CreateFrame("Frame")
oculto:Hide()
M.oculto = oculto

---------------------------------------------------------------- base de datos y diagnóstico
local function db()
	MambaBarrasDB = MambaBarrasDB or {}
	MambaBarrasDB.diag = MambaBarrasDB.diag or {}
	return MambaBarrasDB
end
local function pj()
	MambaBarrasPJ = MambaBarrasPJ or {}
	return MambaBarrasPJ
end
M.DB, M.PJ = db, pj

-- Lo que pasó en el juego, para leerlo desde el computador (WTF/.../SavedVariables/Mamba_Barras.lua):
-- así se arregla sin pedirle comandos a nadie.
function M.Anotar(clave, valor)
	db().diag[clave] = valor
end
function M.Contar(clave)
	local d = db().diag
	d.cuenta = d.cuenta or {}
	d.cuenta[clave] = (d.cuenta[clave] or 0) + 1
end
function M.Falla(donde, err)
	local d = db().diag
	d.fallas = d.fallas or {}
	if #d.fallas < 30 then d.fallas[#d.fallas + 1] = date("%d-%m %H:%M") .. " " .. donde .. ": " .. tostring(err) end
	if geterrorhandler then geterrorhandler()(err) end
end
function M.Proteger(donde, fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then M.Falla(donde, err) end
	return ok
end

-- Registrar un evento que este cliente quizá no tenga (en Forever, registrar uno desconocido da error y
-- corta el archivo: medido el 18-11 con el Tasador).
function M.Escuchar(f, ev)
	local ok = pcall(f.RegisterEvent, f, ev)
	if not ok then
		local d = db().diag
		d.eventosNo = d.eventosNo or {}
		d.eventosNo[ev] = true
	end
	return ok
end

---------------------------------------------------------------- lo que espera a salir de combate
local espera = {}
function M.FueraDeCombate(clave, fn)
	if not InCombatLockdown() then return M.Proteger(clave, fn) end
	espera[clave] = fn
end
local salida = CreateFrame("Frame")
M.Escuchar(salida, "PLAYER_REGEN_ENABLED")
salida:SetScript("OnEvent", function()
	local lista = espera
	espera = {}
	for clave, fn in pairs(lista) do M.Proteger(clave, fn) end
end)

---------------------------------------------------------------- configuración
-- ¿Hay otro addon de barras encendido? Entonces Mamba no pone las suyas (dos juegos de barras se pisan).
M.OTROS = { "Bartender4", "Dominos", "ElvUI", "EllesmereUIActionBars", "NeuronActionBars" }
function M.OtroAddonDeBarras()
	local C = C_AddOns
	if not (C and C.IsAddOnLoaded) then return nil end
	for _, n in ipairs(M.OTROS) do
		if C.IsAddOnLoaded(n) then return n end
	end
end

local function claveBT()
	local nombre = UnitName("player") or "?"
	local reino = GetRealmName and GetRealmName() or ""
	return { nombre .. " - " .. reino, nombre .. " " .. reino, nombre }
end

-- La copia de Bartender de este personaje: la que dejó la instalación o, si Bartender4 está cargado, la
-- suya en vivo.
function M.CopiaBartender()
	for _, k in ipairs(claveBT()) do
		if M.COPIA_BT and M.COPIA_BT[k] then return M.COPIA_BT[k], "instalación" end
	end
	local B = _G.Bartender4DB
	if type(B) == "table" and B.profileKeys and B.namespaces then
		for _, k in ipairs(claveBT()) do
			local perfil = B.profileKeys[k]
			if perfil then
				local p = {}
				for mod, ns in pairs(B.namespaces) do
					if type(ns) == "table" and ns.profiles and ns.profiles[perfil] then p[mod] = ns.profiles[perfil] end
				end
				return p, "Bartender4"
			end
		end
	end
end

function M.Config(id)
	local p = pj()
	p.barras = p.barras or {}
	if not p.barras[id] then p.barras[id] = M.ConfigPorDefecto(id) end
	local c = p.barras[id]
	-- campos que falten (una versión vieja del archivo guardado)
	for k, v in pairs(M.ConfigPorDefecto(id)) do if c[k] == nil then c[k] = v end end
	return c
end

-- Primera vez de este personaje: si hay copia de Bartender, se usa; si no, el lugar por defecto.
-- K99 (18-11): si al entrar no había copia (la instalación todavía no la traía), se vuelve a mirar en cada
-- entrada hasta que aparezca, y se copia UNA sola vez; lo de antes queda para «Deshacer» y se avisa.
local function primeraVez()
	local p = pj()
	if p.copiadoDe then return end
	local perfil, origen = M.CopiaBartender()
	local conv = perfil and M.DeBartender(perfil)
	local yaEntro = p.version ~= nil
	p.version = 2
	if not conv then return end -- sin copia todavía: se vuelve a intentar la próxima vez
	if yaEntro and p.barras then p.anterior = p.barras end
	p.barras = conv
	p.copiadoDe = origen
	M.Anotar("copiaBartender", origen)
	if yaEntro then
		M.avisoCopia = true
		local chat = _G.DEFAULT_CHAT_FRAME
		if chat and chat.AddMessage then
			chat:AddMessage("Mamba: copié tus barras de Bartender. Si preferías como estaban, en Mamba › Interfaz › Barras aprieta «Deshacer».")
		end
	end
end

function M.CopiarBartender()
	local perfil, origen = M.CopiaBartender()
	local conv = perfil and M.DeBartender(perfil)
	if not conv then return false end
	local p = pj()
	p.anterior = p.barras
	p.barras = conv
	p.copiadoDe = origen
	M.FueraDeCombate("disponer", M.DisponerTodo)
	return true
end
-- "Restablecer posiciones" de Ajustes › Mamba › Ventanas (MambaAPI.AlRestablecer): cada barra vuelve al
-- lugar copiado de Bartender, o al de siempre si no hay copia. Solo el lugar: tamaño, botones y filas quedan.
function M.RestablecerLugares()
	local perfil = M.CopiaBartender()
	local conv = perfil and M.DeBartender(perfil) or {}
	for id in pairs(M.marcos) do
		local c = M.Config(id)
		local base = conv[id] or M.ConfigPorDefecto(id)
		c.punto, c.x, c.y = base.punto, base.x, base.y
	end
	M.FueraDeCombate("disponer", M.DisponerTodo)
end

function M.Deshacer()
	local p = pj()
	if not p.anterior then return false end
	p.barras, p.anterior = p.anterior, nil
	M.FueraDeCombate("disponer", M.DisponerTodo)
	return true
end

---------------------------------------------------------------- crear las barras
local function idxJuego()
	local i = {}
	if GetOverrideBarIndex then i.anular = GetOverrideBarIndex() end
	if GetVehicleBarIndex then i.vehiculo = GetVehicleBarIndex() end
	return i
end

local function tieneAccion(casilla)
	local f = (C_ActionBar and C_ActionBar.HasAction) or HasAction
	local ok, r = pcall(f, casilla)
	return ok and r and true or false
end

function M.ConductorActual()
	local _, clase = UnitClass("player")
	local p = pj()
	p.formas = p.formas or {}
	local paginas = M.PaginasFormas(clase, p.formasElegidas, tieneAccion)
	p.formas = paginas
	return M.Conductor(clase, paginas, idxJuego()), clase, paginas
end

local MAXPAG = 18

local function configLAB(def, i, vertical)
	return {
		showGrid = M.moviendo and true or false,
		tooltip = "enabled",
		actionButtonUI = true,        -- así el resaltado de rotación de Blizzard se ve en estos botones
		assistedHighlight = true,
		keyBoundTarget = def.comando and (def.comando .. i) or false,
		flyoutDirection = vertical and "LEFT" or "UP",
	}
end
M.ConfigLAB = configLAB

local function crearBarra(def)
	local h = CreateFrame("Frame", "MambaBarra" .. def.id, UIParent, "SecureHandlerStateTemplate")
	h.def = def
	-- MEDIUM, como Bartender4: en LOW cualquier marco del juego en MEDIUM (la barra principal mal escondida
	-- de la 1.ª tanda) quedaba encima y se comía los clics y el arrastre (K99).
	h:SetFrameStrata("MEDIUM")
	h:SetMovable(true)
	h:SetClampedToScreen(true)
	h.botones = {}
	h:SetAttribute("_onstate-page", [[
		self:SetAttribute("state", newstate)
		control:ChildUpdate("state", newstate)
	]])
	local c = M.Config(def.id)
	for i = 1, 12 do
		local casilla = def.inicio + i - 1
		local b = LAB:CreateButton(i, "MambaBoton" .. casilla, h, configLAB(def, i, c.filas > 1))
		if def.pagina then
			for p = 1, MAXPAG do b:SetState(p, "action", (p - 1) * 12 + i) end
		else
			b:SetState(0, "action", casilla)
		end
		h.botones[i] = b
		M.botones[casilla] = b
		-- K99: cuántos clics y cuántos hechizos soltados llegan de verdad a los botones (se lee en el diag)
		b:HookScript("PostClick", function() M.Contar("clics") end)
		b:HookScript("OnReceiveDrag", function() M.Contar("soltados") end)
	end
	if def.pagina then
		local cond = M.ConductorActual()
		M.Anotar("conductor", cond)
		RegisterStateDriver(h, "page", cond)
	end
	M.marcos[def.id] = h
	return h
end

-- Vuelve a armar las condiciones de la barra principal (cambiaste la página de una forma).
function M.ActualizarConductor()
	M.FueraDeCombate("conductor", function()
		local h = M.marcos[1]
		if not h then return end
		local cond = M.ConductorActual()
		M.Anotar("conductor", cond)
		UnregisterStateDriver(h, "page")
		RegisterStateDriver(h, "page", cond)
	end)
end

---------------------------------------------------------------- poner cada barra en su lugar
function M.Colocar(h, c)
	local esc = (c.escala and c.escala > 0) and c.escala or 1
	h:SetScale(esc)
	h:ClearAllPoints()
	h:SetPoint(c.punto or "CENTER", UIParent, c.punto or "CENTER", (c.x or 0) / esc, (c.y or 0) / esc)
end

local function verBarra(h, c)
	UnregisterStateDriver(h, "visibility")
	-- apagadas en Opciones (K124): nada vuelve a mostrarlas (revisor tanda 10: Formas, Mover, Opciones y
	-- Restablecer pasaban por aquí y las volvían a poner a la vista)
	if pj().apagado then h:Hide() return end
	if not c.mostrar then
		h:Hide()
	elseif c.ver == "combate" then
		RegisterStateDriver(h, "visibility", "[combat]show;hide")
	elseif h.condicionVer then
		RegisterStateDriver(h, "visibility", h.condicionVer)
	else
		RegisterStateDriver(h, "visibility", "[petbattle]hide;show")
	end
	h:SetAlpha(c.ver == "raton" and 0 or (c.alfa or 1))
end
M.VerBarra = verBarra

-- Botones en rejilla. lista = los botones de la barra; tam = el lado de un botón.
function M.Rejillar(h, lista, c)
	local n = math.min(c.botones or #lista, #lista)
	local cols, filas = M.Rejilla(n, c.filas)
	local tam = lista[1] and lista[1]:GetWidth() or 45
	if not tam or tam < 10 then tam = 45 end
	local sep = c.separacion or 2
	for i, b in ipairs(lista) do
		b:ClearAllPoints()
		if i <= n then
			local col, fila = (i - 1) % cols, math.floor((i - 1) / cols)
			b:SetPoint("TOPLEFT", h, "TOPLEFT", col * (tam + sep), -fila * (tam + sep))
			b:Show()
		else
			b:Hide()
		end
	end
	h:SetSize(math.max(1, cols * (tam + sep) - sep), math.max(1, filas * (tam + sep) - sep))
end

function M.Disponer(id)
	local h = M.marcos[id]
	if not h then return end
	local c = M.Config(id)
	if h.def and h.def.inicio then
		for i, b in ipairs(h.botones) do
			b:SetAttribute("flyoutDirection", (c.filas or 1) > 1 and "LEFT" or "UP")
		end
	end
	M.Rejillar(h, h.botones, c)
	M.Colocar(h, c)
	verBarra(h, c)
	-- para revisar desde el computador dónde quedó cada barra (sin pedir capturas)
	local d = db().diag
	d.lugares = d.lugares or {}
	d.lugares[tostring(id)] = { punto = c.punto, x = c.x, y = c.y, escala = c.escala, mostrar = c.mostrar,
		izq = h.GetLeft and h:GetLeft(), abajo = h.GetBottom and h:GetBottom(), ancho = h.GetWidth and h:GetWidth() }
	if M.AlDisponer then M.AlDisponer(id) end
end

function M.DisponerTodo()
	for id in pairs(M.marcos) do M.Disponer(id) end
end

-- K99: un tamaño (escala) y una separación para todas las barras de una vez, fuera de combate.
local function todasLasBarras(campo, v)
	for _, d in ipairs(M.BARRAS) do M.Config(d.id)[campo] = v end
	for _, d in ipairs(M.ESPECIALES or {}) do M.Config(d.id)[campo] = v end
	M.FueraDeCombate("disponer", M.DisponerTodo)
end
function M.TamanoTodas(esc)
	esc = math.max(0.3, math.min(1.5, tonumber(esc) or 1))
	pj().escalaTodas = esc
	todasLasBarras("escala", esc)
end
function M.SeparacionTodas(sep)
	sep = math.max(0, math.min(20, math.floor(tonumber(sep) or 2)))
	pj().separacionTodas = sep
	todasLasBarras("separacion", sep)
end

-- Grilla a la vista (modo mover) o solo los botones con algo.
function M.MostrarVacios(si)
	M.moviendo = si
	for casilla, b in pairs(M.botones) do
		if b.config then
			local h = b.header
			local def = h and h.def
			local i = b.id
			if def and def.inicio then
				local c = configLAB(def, i, (M.Config(def.id).filas or 1) > 1)
				c.showGrid = si and true or false
				b:UpdateConfig(c)
			end
		end
	end
end

---------------------------------------------------------------- esconder las barras del juego
-- Medido en el juego el 18-11: con solo SetParent la barra principal del juego seguía a la vista. El Modo de
-- edición del cliente nuevo reemplaza Hide() en sus barras: hay que esconderla con su Hide original (HideBase),
-- y quitarle los eventos que la vuelven a mostrar al entrar y salir de combate o al arrastrar un hechizo.
M.padres = M.padres or {}      -- marco del juego -> su padre original (para devolverlo al apagar, K124)
M.escondidos = M.escondidos or {}
local function esconderMarco(f, eventos)
	if not f then return end
	if M.padres[f] == nil and f.GetParent then
		M.padres[f] = f:GetParent() or false
		-- ¿se veía antes de esconderla? (las que el jugador tenía apagadas no se devuelven a la vista)
		M.visibles = M.visibles or {}
		M.visibles[f] = (f.IsShown and f:IsShown()) and true or false
	end
	if eventos and f.UnregisterAllEvents then f:UnregisterAllEvents() end
	if f.HideBase then pcall(f.HideBase, f) elseif f.Hide then pcall(f.Hide, f) end
	f:SetParent(oculto)
end
local function esconderBoton(b)
	if not b then return end
	b:UnregisterAllEvents()
	b:SetAttribute("statehidden", true)
	b:Hide()
	M.escondidos[b] = true
end

-- K124 (apagar desde Opciones): devolver las barras del juego. Los botones del juego perdieron sus eventos
-- propios al esconderlos: se ven y funcionan, y con la próxima recarga quedan exactamente como el juego las deja.
function M.MostrarJuego()
	for f, padre in pairs(M.padres) do
		if padre then pcall(f.SetParent, f, padre) end
		-- solo las que estaban a la vista (revisor tanda 10: aparecían StanceBar, PetActionBar y barras apagadas)
		if M.visibles and M.visibles[f] then
			if f.ShowBase then pcall(f.ShowBase, f) elseif f.Show then pcall(f.Show, f) end
		end
	end
	for b in pairs(M.escondidos) do
		pcall(b.SetAttribute, b, "statehidden", nil)
		pcall(b.Show, b)
	end
end

M.MARCOS_JUEGO = { "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight",
	"MultiBar5", "MultiBar6", "MultiBar7", "StanceBar", "PetActionBar", "PossessActionBar" }
M.BOTONES_JUEGO = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
	"MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button" }

function M.EsconderJuego()
	local vistos = {}
	esconderMarco(_G.MainActionBar, false)   -- cliente nuevo
	esconderMarco(_G.MainMenuBar, false)     -- cliente viejo
	vistos.MainActionBar = _G.MainActionBar ~= nil
	vistos.MainMenuBar = _G.MainMenuBar ~= nil
	for _, barra in ipairs({ _G.MainMenuBar, _G.MainActionBar }) do
		if barra and barra.UnregisterEvent then
			for _, e in ipairs({ "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "ACTIONBAR_SHOWGRID", "ACTIONBAR_HIDEGRID" }) do
				pcall(barra.UnregisterEvent, barra, e)
			end
		end
	end
	for _, n in ipairs(M.MARCOS_JUEGO) do
		vistos[n] = _G[n] ~= nil
		esconderMarco(_G[n], true)
	end
	for _, pre in ipairs(M.BOTONES_JUEGO) do
		for i = 1, 12 do esconderBoton(_G[pre .. i]) end
	end
	M.Anotar("marcosDelJuego", vistos)
end

---------------------------------------------------------------- aparecer al pasar el ratón
local fundido = CreateFrame("Frame")
local cuenta = 0
fundido:SetScript("OnUpdate", function(_, dt)
	cuenta = cuenta + dt
	if cuenta < 0.1 then return end
	cuenta = 0
	for id, h in pairs(M.marcos) do
		local c = M.Config(id)
		if c.mostrar and c.ver == "raton" and h:IsShown() then
			local encima = M.moviendo or h:IsMouseOver()
			if not encima and SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:IsMouseOver() then encima = true end
			h:SetAlpha(encima and (c.alfa or 1) or 0)
		end
	end
end)

---------------------------------------------------------------- diagnóstico de la rotación de Blizzard
-- ¿Este cliente trae el "resaltado asistido" de Blizzard (la sugerencia oficial del próximo hechizo)?
-- Se anota para el módulo de combate; no cambia nada.
function M.DiagnosticoRotacion()
	local d = {}
	local AC = _G.C_AssistedCombat
	d.C_AssistedCombat = AC ~= nil
	if AC then
		local fns = {}
		for k, v in pairs(AC) do if type(v) == "function" then fns[#fns + 1] = k end end
		table.sort(fns)
		d.funciones = table.concat(fns, ",")
		if AC.IsAvailable then
			local ok, a, motivo = pcall(AC.IsAvailable)
			d.disponible = ok and tostring(a) or ("error " .. tostring(a))
			d.motivo = ok and motivo and tostring(motivo) or nil
		end
		if AC.GetRotationSpells then
			local ok, t = pcall(AC.GetRotationSpells)
			d.hechizos = ok and type(t) == "table" and #t or nil
		end
	end
	d.AssistedCombatManager = _G.AssistedCombatManager ~= nil
	local get = (C_CVar and C_CVar.GetCVar) or GetCVar
	if get then
		local ok, v = pcall(get, "assistedCombatHighlight")
		d.cvarResaltado = ok and v or nil
	end
	M.Anotar("rotacion", d)
end

---------------------------------------------------------------- arranque
function M.Construir()
	if M.listo then return end
	if pj().apagado then M.Anotar("apagado", true) return end -- K124: el jugador las apagó en Opciones
	local otro = M.OtroAddonDeBarras()
	M.Anotar("otroAddon", otro or false)
	if otro then
		M.bloqueadoPor = otro
		return
	end
	primeraVez()
	for _, def in ipairs(M.BARRAS) do
		M.Proteger("barra " .. def.id, crearBarra, def)
	end
	if M.CrearFormas then M.Proteger("formas", M.CrearFormas) end
	if M.CrearMascota then M.Proteger("mascota", M.CrearMascota) end
	M.Proteger("disponer", M.DisponerTodo)
	-- Recién con las barras de Mamba en pantalla se esconden las del juego: si algo falló arriba, el
	-- jugador no se queda sin barras.
	local n = 0
	for _ in pairs(M.marcos) do n = n + 1 end
	M.Anotar("barrasCreadas", n)
	if n > 0 then M.Proteger("esconder", M.EsconderJuego) end
	if M.AplicarTeclas then M.Proteger("teclas", M.AplicarTeclas) end
	local api = _G.MambaAPI
	if api and api.AlRestablecer then pcall(api.AlRestablecer, M.RestablecerLugares) end
	M.listo = true
end

local arranque = CreateFrame("Frame")
M.Escuchar(arranque, "PLAYER_LOGIN")
M.Escuchar(arranque, "PLAYER_ENTERING_WORLD")
arranque:SetScript("OnEvent", function(self, ev)
	if ev == "PLAYER_LOGIN" then
		local d = db().diag
		d.version = "0.1.0"
		d.cliente = select(4, GetBuildInfo())
		d.entrada = date("%d-%m-%Y %H:%M")
		local _, clase = UnitClass("player")
		d.clase = clase
		M.FueraDeCombate("construir", M.Construir)
	else
		M.Proteger("diagRotacion", M.DiagnosticoRotacion)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end)

-- Aprendiste algo nuevo o cambió la doble especialización: la página por defecto de una forma puede
-- dejar de estar vacía.
local cambios = CreateFrame("Frame")
M.Escuchar(cambios, "UPDATE_SHAPESHIFT_FORMS")
M.Escuchar(cambios, "ACTIVE_TALENT_GROUP_CHANGED")
cambios:SetScript("OnEvent", function()
	if M.listo and M.marcos[1] then M.ActualizarConductor() end
end)
