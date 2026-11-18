-- Mamba_Combate: su parte en Interfaz (menú de Polestar): Cómo jugar (C1b), Modo de pelea (M1, C2b),
-- Medidor (K65) y Avisos y barras (M2, K64, K66, K67, K73). Sin comandos. Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas
local R = M.Rotacion
local sub = "jugar"
local paneles, listas = {}, {}
local verSpec, verCaso = nil, nil

local CASOS = { { "solo", "Subir solo" }, { "varios", "Contra varios" }, { "mazmorra", "Mazmorra" }, { "jcj", "JcJ" },
	{ "jefe", "Jefe largo" }, { "emergencia", "Emergencia" } }
local function db() return M.DB() end
local function icono(id) return ("|T%s:18:18:0:0|t "):format(tostring(M.Icono(id))) end

---------------------------------------------------------------- Cómo jugar
function M.FilasJugar()
	local d = R.Datos()
	if not d then return {}, { titulo = "Cómo jugar", linea1 = "Todavía no hay datos de tu clase." } end
	local actual = R.Spec()
	local s = verSpec and (function() for _, x in ipairs(d.specs) do if x.clave == verSpec then return x end end end)() or actual
	local casos = R.Casos(s)
	local caso = verCaso or R.Modo()
	if not casos[caso] then caso = casos.solo and "solo" or "mazmorra" end
	local filtros = {}
	for _, x in ipairs(d.specs) do filtros[#filtros + 1] = { "s:" .. x.clave, x.nombre, x == s } end
	for _, c in ipairs(CASOS) do if casos[c[1]] then filtros[#filtros + 1] = { "c:" .. c[1], c[2], c[1] == caso } end end
	local cab = { titulo = "Cómo jugar: " .. (s.nombre or ""), filtros = filtros,
		linea1 = "Prioridad de arriba hacia abajo: haz el primero que puedas. Solo salen los hechizos que ya tienes.",
		linea2 = "Fuentes: " .. ((d.fuentes and d.fuentes[1] and d.fuentes[1][1]) or "—") .. (d.fuentes and #d.fuentes > 1 and (" y " .. (#d.fuentes - 1) .. " más") or "") .. ". Forever cambió algunos hechizos: si algo no cuadra, dilo.",
		alFiltro = function(k)
			local a, b = k:match("^(%a):(.+)$")
			if a == "s" then verSpec = b elseif a == "c" then verCaso = b end
			M.RefrescarPanel()
		end }
	local out = {}
	local c = casos[caso]
	for i, p in ipairs(c and c.pasos or {}) do
		local sabe = M.Conoce(p.h)
		local tecla = sabe and R.Tecla(p.h)
		out[#out + 1] = { tipo = tostring(i) .. "." .. (sabe and "" or "\naún no"), titulo = icono(p.h) .. M.Texto(p.cuando),
			detalle = sabe and (tecla and ("Tecla: " .. tecla) or "No está en tus barras: arrástralo desde el libro de hechizos.")
				or (M.NombreHechizo(p.h) .. ": todavía no lo tienes (lo aprendes con tu instructor o con talentos)."),
		}
	end
	if c and c.nota and c.nota ~= "" then out[#out + 1] = { tipo = "Ojo", titulo = M.Texto(c.nota) } end
	if M.Clase() == "DRUID" then
		out[#out + 1] = { tipo = "Formas", titulo = "Cuándo cambiar de forma",
			detalle = M.Texto("Varios enemigos o te pegan mucho: {5487}. Uno solo, para matar rápido: {768}. Para curar o lanzar desde lejos: sal de forma. Cambiar de forma quita las raíces y la lentitud.") }
	end
	return out, cab
end

---------------------------------------------------------------- Medidor
function M.FilasMedidor()
	local Med = M.Medidor
	local e = Med.estado
	local filtros = {}
	for _, t in ipairs(Med.TIPOS) do filtros[#filtros + 1] = { "t:" .. t[1], t[2], t[1] == e.tipo } end
	for _, s in ipairs(Med.SESIONES) do filtros[#filtros + 1] = { "s:" .. s[1], s[2], s[1] == e.sesion } end
	local cab = { titulo = "Medidor de combate", filtros = filtros,
		linea1 = "Del medidor del juego. En combate el juego esconde los números: se ven al terminar la pelea.",
		alFiltro = function(k)
			local a, b = k:match("^(%a):(.+)$")
			if a == "t" then e.tipo = b elseif a == "s" then e.sesion = b end
			Med.Dibujar(); M.RefrescarPanel()
		end }
	local s, motivo = Med.Sesion(e.sesion, e.tipo)
	if not s then cab.linea2 = motivo; return {}, cab end
	local out = {}
	for i, x in ipairs(s.filas) do
		if i > 10 then break end
		out[#out + 1] = { tipo = "#" .. i, titulo = x.nombre .. (x.yo and " (tú)" or ""),
			detalle = Med.Corto(x.total) .. (x.porSeg and ("  ·  " .. Med.Corto(x.porSeg) .. " por segundo") or "") }
	end
	local hs = Med.Hechizos(e.sesion, e.tipo)
	if hs then
		for i, h in ipairs(hs) do
			if i > 8 then break end
			out[#out + 1] = { tipo = i == 1 and "Tus hechizos" or "", titulo = icono(h.id) .. h.nombre,
				detalle = Med.Corto(h.total) .. (h.pct and ("  ·  " .. math.floor(h.pct + 0.5) .. " %") or "") }
		end
	end
	local mato = Med.QueMeMato()
	if mato then out[#out + 1] = { tipo = "Muerte", titulo = mato } end
	out[#out + 1] = { tipo = "", titulo = "Empezar de cero", acciones = { { "Reiniciar", function() Med.Reiniciar(); M.RefrescarPanel() end } } }
	return out, cab
end

---------------------------------------------------------------- opciones
local function colocar(p, filas, ancho, y)
	for _, f in ipairs(filas) do
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", p, "TOPLEFT", 16, y)
		y = y - P.Acomodar(f, ancho - 40) - 4
	end
	return y
end
local function titulo(p, t, s2)
	local a = P.Texto(p, "title", "text")
	a:SetPoint("TOPLEFT", p, "TOPLEFT", 16, -12)
	a:SetText(t)
	local b = P.Texto(p, "note", "textDim")
	b:SetPoint("TOPLEFT", a, "BOTTOMLEFT", 0, -6)
	b:SetWidth(560)
	b:SetText(s2 or "")
	return -60
end

local function dibujarModo(p, ancho)
	local d = db()
	local y = titulo(p, "Modo de pelea", "El modo cambia solo: en grupo o mazmorra, Mazmorra; contra un jugador o en campo de batalla, JcJ; con 3 o más enemigos, Varios. También se cambia con un clic sobre el recuadro de la sugerencia.")
	local modos = { { value = "auto", text = "Automático" } }
	for _, m in ipairs(R.MODOS) do modos[#modos + 1] = { value = m[1], text = m[2] } end
	local specs = { { value = "auto", text = "Automática (tus talentos y tu forma)" } }
	for _, s in ipairs((R.Datos() or { specs = {} }).specs) do specs[#specs + 1] = { value = s.clave, text = s.nombre } end
	local function I(et, ay, k) return P.Interruptor(p, et, ay, function() return d[k] end, function(v) d[k] = v; M.Cambio() end) end
	colocar(p, {
		P.Desplegable(p, "Modo", nil, modos, function() return d.modo end, function(v) d.modo = v; M.Cambio() end),
		P.Desplegable(p, "Rol", "Sanar muestra los marcos de curación; tanque y daño, la amenaza. Druida: cambia solo con la forma.",
			{ { value = "auto", text = "Automático" }, { value = "daño", text = "Daño" }, { value = "tanque", text = "Tanque" }, { value = "sanar", text = "Sanar" } },
			function() return d.rol end, function(v) d.rol = v; M.Cambio() end),
		P.Desplegable(p, "Especialización", nil, specs, function() return d.spec or "auto" end, function(v) d.spec = (v ~= "auto") and v or nil; M.Cambio() end),
		I("Sugerir el próximo hechizo", "Un recuadro con el próximo hechizo y su tecla. Solo muestra: tú decides y lanzas.", "sugerencia"),
		I("Marcar ese hechizo en mis barras", "Un borde dorado en el botón.", "resaltar"),
	}, ancho, y)
end

local function dibujarAvisos(p, ancho)
	local d = db()
	local y = titulo(p, "Avisos y barras de combate", "Todo se mueve arrastrándolo y vuelve a su lugar con «Restablecer posiciones» en Ajustes › Mamba › Ventanas.")
	local function I(et, ay, k) return P.Interruptor(p, et, ay, function() return d[k] end, function(v) d[k] = v; M.Cambio() end) end
	colocar(p, {
		I("Avisos en pantalla", "Te controlaron (y qué usar para salir), un enemigo usó un control, maná bajo, amenaza alta.", "avisos"),
		I("Con sonido", nil, "sonido"),
		I("Temporizador del disparo y del golpe", "Cazador: la barra se pone roja el último medio segundo; ahí no te muevas.", "disparo"),
		I("Barra de lanzamiento con latencia y enfriamiento global", nil, "lanzamiento"),
		I("Números de enfriamiento en los botones", "La opción del juego; la respetan las barras de Mamba.", "numerosCD"),
		I("Amenaza del grupo", "Solo en grupo.", "amenaza"),
		I("Placas de nombre de Mamba", "Color por amenaza, élite o raro, y lanzamientos interrumpibles.", "placas"),
		I("Medidor de combate en pantalla", "Clic: cambia qué mide. Clic derecho: esta pelea o el total.", "medidor"),
		P.Deslizador(p, "Avisar con el maná bajo el", nil, 5, 60, 5, "%d %%", function() return d.avisoMana end, function(v) d.avisoMana = v end),
		P.Deslizador(p, "Avisar con la amenaza sobre el", nil, 60, 110, 5, "%d %%", function() return d.avisoAmenaza end, function(v) d.avisoAmenaza = v end),
	}, ancho, y)
end

---------------------------------------------------------------- armado
local LISTAS = { jugar = M.FilasJugar, medidor = M.FilasMedidor, builds = function() return M.FilasDosBuilds() end }
function M.RefrescarPanel()
	for k, p in pairs(paneles) do if k == sub then p:Show() else p:Hide() end end
	local fn, L = LISTAS[sub], listas[sub]
	if fn and L then
		local filas, cab = M.Proteger("panel:" .. sub, fn)
		L:Dibujar(cab or {}, filas or {})
	end
end

local function dibujar(parent, ancho)
	for k in pairs(LISTAS) do
		paneles[k] = CreateFrame("Frame", nil, parent)
		paneles[k]:SetAllPoints(parent)
		listas[k] = M.Lista.Nueva(paneles[k])
	end
	paneles.modo = CreateFrame("Frame", nil, parent); paneles.modo:SetAllPoints(parent); dibujarModo(paneles.modo, ancho)
	paneles.avisos = CreateFrame("Frame", nil, parent); paneles.avisos:SetAllPoints(parent); dibujarAvisos(paneles.avisos, ancho)
end

local reg = CreateFrame("Frame")
M.Escuchar(reg, "PLAYER_LOGIN")
reg:SetScript("OnEvent", function()
	local I = _G.MambaInterfaz
	if not (I and I.Agregar) then return end
	M.Proteger("interfaz", I.Agregar, {
		clave = "combate", titulo = "Combate", orden = 4,
		items = function()
			return { { key = "jugar", label = "Cómo jugar", icon = "record" }, { key = "modo", label = "Modo de pelea", icon = "icon-level" },
				{ key = "medidor", label = "Medidor", icon = "icon-level" }, { key = "builds", label = "Dos builds", icon = "record" },
				{ key = "avisos", label = "Avisos y barras", icon = "compact" } }
		end,
		activo = function() return sub end,
		elegir = function(k) if k == "jugar" or k == "modo" or k == "medidor" or k == "avisos" or k == "builds" then sub = k end end,
		dibujar = dibujar, refrescar = function() M.Proteger("panel", M.RefrescarPanel) end,
	})
end)
