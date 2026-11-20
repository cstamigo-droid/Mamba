-- Mamba_Combate: su parte en Interfaz (menú de Polestar): Cómo jugar (C1b), Modo de pelea (M1, C2b),
-- Medidor (K65) y Avisos y barras (M2, K64, K66, K67, K73). Sin comandos. Licencia: GPL-3.0-only.
local _, M = ...
local P = M.Piezas
local R = M.Rotacion
local sub = "jugar"
local paneles, listas = {}, {}
local verSpec, verCaso = nil, nil

local CASOS = { { "solo", "Subir solo" }, { "varios", "Contra varios" }, { "mazmorra", "Mazmorra" }, { "jcj", "Contra jugadores" },
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
		linea2 = "Fuentes: " .. ((d.fuentes and d.fuentes[1] and d.fuentes[1][1]) or "—") .. (d.fuentes and #d.fuentes > 1 and (" y " .. (#d.fuentes - 1) .. " más") or "") .. ".",
		alFiltro = function(k)
			local a, b = k:match("^(%a):(.+)$")
			if a == "s" then verSpec = b elseif a == "c" then verCaso = b end
			M.RefrescarPanel()
		end }
	local out = {}
	local c = casos[caso]
	-- C1b, a la vista: la prioridad en una tira de íconos con su tecla (lo que sabes; «·» si no está en tus barras)
	local tira = {}
	for _, p in ipairs(c and c.pasos or {}) do
		if M.Conoce(p.h) then tira[#tira + 1] = ("|T%s:24:24:0:0|t %s"):format(tostring(M.Icono(p.h)), R.Tecla(p.h) or "·") end
	end
	if #tira > 0 then out[#out + 1] = { tipo = "En orden", titulo = table.concat(tira, "   ›   "),
		detalle = "Haz el primero que puedas; si no se puede, el siguiente. En combate, Mamba marca en tus barras el que toca." } end
	for i, p in ipairs(c and c.pasos or {}) do
		local sabe = M.Conoce(p.h)
		local tecla = sabe and R.Tecla(p.h)
		local acc
		if sabe and not tecla then acc = { { "Abrir libro de hechizos", M.AbrirLibro } }
		elseif not sabe then acc = { { "Buscar instructor", M.BuscarInstructor } } end
		out[#out + 1] = { tipo = tostring(i) .. "." .. (sabe and "" or "\naún no"), titulo = icono(p.h) .. M.Texto(p.cuando),
			detalle = sabe and (tecla and ("Tecla: " .. tecla) or "No está en tus barras: arrástralo desde el libro de hechizos a una barra.")
				or (M.NombreHechizo(p.h) .. ": todavía no lo tienes. Se aprende con tu instructor de clase al nivel que pide, o con talentos."),
			acciones = acc }
	end
	if c and c.nota and c.nota ~= "" then out[#out + 1] = { tipo = "Ojo", titulo = M.Texto(c.nota) } end
	if M.Clase() == "DRUID" then
		out[#out + 1] = { tipo = "Formas", titulo = "Cuándo cambiar de forma" }
		for _, x in ipairs({ { 5487, "Varios enemigos o te pegan mucho: {5487}." }, { 768, "Uno solo, para matar rápido: {768}." },
			{ 8936, "Para curar o lanzar desde lejos: sal de forma ({8936}, {2912})." },
			{ 783, "Te enraízan o te frenan: cambia de forma ({783}): se quitan." } }) do
			if M.Conoce(x[1]) then
				local tecla = R.Tecla(x[1])
				out[#out + 1] = { tipo = "", titulo = icono(x[1]) .. M.Texto(x[2]), detalle = tecla and ("Tecla: " .. tecla) or nil }
			end
		end
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
	if not s then
		cab.linea2 = motivo
		return { { tipo = "Grupo", titulo = "Ranking del grupo", acciones = { { "Abrir el ranking", function() if M.Ranking then M.Ranking.Abrir() end end } } } }, cab
	end
	local out = { { tipo = "Grupo", titulo = "Ranking del grupo", detalle = "Una barra por jugador: daño, curación o daño recibido, de esta pelea, del total o de una anterior. Clic en una barra: sus hechizos.",
		acciones = { { "Abrir el ranking", function() if M.Ranking then M.Ranking.Abrir() end end } } } }
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
	local y = titulo(p, "Modo de pelea", "El modo cambia solo: en grupo o mazmorra, Mazmorra; contra un jugador o en campo de batalla, Contra jugadores; con 3 o más enemigos, Varios. También se cambia con un clic en el rótulo de arriba del recuadro de la sugerencia.")
	local modos = { { value = "auto", text = "Automático" } }
	for _, m in ipairs(R.MODOS) do modos[#modos + 1] = { value = m[1], text = m[2] } end
	local specs = { { value = "auto", text = "Automática (tus talentos y tu forma)" } }
	for _, s in ipairs((R.Datos() or { specs = {} }).specs) do specs[#specs + 1] = { value = s.clave, text = s.nombre } end
	local function I(et, ay, k) return P.Interruptor(p, et, ay, function() return d[k] end, function(v) d[k] = v; M.Cambio() end) end
	colocar(p, {
		P.Desplegable(p, "Modo", nil, modos, function() return d.modo end, function(v) d.modo = v; M.Cambio() end),
		P.Desplegable(p, "Rol", "Daño: matar. Tanque: recibir los golpes y cuidar al grupo. Sanar: curar. Sanar muestra los marcos de curación; tanque y daño, la amenaza. Druida: cambia solo con la forma.",
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
		I("Avisos en pantalla", "Te controlaron (y qué usar para salir, si tu clase tiene algo), un enemigo usó un control, maná bajo, amenaza alta.", "avisos"),
		I("Sonido cuando te controlan", nil, "sonido"),
		I("Sonido en todos los avisos", nil, "sonidoTodos"),
		I("Aviso de amenaza alta", nil, "avisoAmenazaSi"),
		I("Aviso de maná bajo", nil, "avisoManaSi"),
		I("Temporizador del disparo y del golpe", "Cazador: la barra se pone roja el último medio segundo; ahí no te muevas.", "disparo"),
		I("Barra de lanzamiento", "Con tu retraso de conexión en rojo al final y la espera entre hechizos debajo.", "lanzamiento"),
		I("Números de enfriamiento en los botones", "La opción del juego; la respetan las barras de Mamba.", "numerosCD"),
		I("Amenaza del grupo", "Solo en grupo.", "amenaza"),
		I("Placas de nombre compactas de Mamba", (M.Placas and M.Placas.OtroAddon() and ("Ahora no se usan: ya tienes " .. M.Placas.OtroAddon() .. ". ") or "") .. "En los enemigos: una barra fina con la vida, el nombre, ÉLITE o RARO, el color de la amenaza, el marcador y los lanzamientos INTERRUMPIBLES. Apagadas vuelven las del juego.", "placas"),
		P.Deslizador(p, "Ancho de las placas", nil, 50, 200, 10, "%d", function() return d.placaAncho end, function(v) d.placaAncho = v; M.Cambio() end),
		P.Deslizador(p, "Alto de las placas", nil, 3, 20, 1, "%d", function() return d.placaAlto end, function(v) d.placaAlto = v; M.Cambio() end),
		I("Indicador de agro al acercarte", "Fuera de combate: una barrita bajo el personaje que pasa de verde a rojo cuando te acercas a un bicho hostil que ataca solo, con una marca hacia su lado de la pantalla, para pasar sin atraerlo. El radio es aproximado (Classic: unas 20 yardas a tu nivel, una más o menos por nivel de diferencia).", "agro"),
		I("Ver la barrita de agro siempre", "Apagado: solo aparece cuando hay peligro.", "agroSiempre"),
		I("Marcar en su placa al bicho que estás por atraer", "Borde naranja si puede estar dentro de su radio; rojo si ya estás dentro.", "agroPlacas"),
		I("Ficha del enemigo (contra jugadores)", "Al elegir de objetivo a un jugador enemigo: su clase, sus controles y defensas (apagados con los segundos que le faltan si ya los usó) y lo tuyo para responder, con su tecla.", "ficha"),
		I("Aviso cuando un enemigo usa una defensa", "«X usó Escudo divino». Los controles («X usó Aturdir») van con los avisos en pantalla.", "avisoDefensas"),
		P.Desplegable(p, "Barra de marcadores", "Calavera, cruz, luna… Clic: marca a tu objetivo.", { { value = "siempre", text = "Siempre" }, { value = "grupo", text = "Solo en grupo" }, { value = "nunca", text = "Nunca" } },
			function() return d.marcadores end, function(v) d.marcadores = v; M.Cambio() end),
		I("Medidor de combate en pantalla", "Clic: cambia qué mide. Clic derecho: esta pelea o el total.", "medidor"),
		I("Abrir sola la ventana grande de enemigos cerca", "Apagado: basta la barrita «Cerca: N»; la ventana grande se abre con un clic en la barrita o con el botón de abajo.", "cercanosSola"),
		P.Desplegable(p, "Barra «Cerca: N»", "Chica y fija, como la de Spy: crece con cada jugador enemigo cerca. Clic en ella: la ventana completa.",
			{ { value = "siempre", text = "Siempre a la vista" }, { value = "conEnemigos", text = "Solo cuando hay enemigos" }, { value = "nunca", text = "Nunca" } },
			function() return d.cercaBarra end, function(v) d.cercaBarra = v; M.Cambio() end),
		P.Interruptor(p, "Placas de nombre de enemigos (detectan antes)", "La tecla V del juego. Con ellas apagadas, Mamba solo ve a los enemigos que señalas con el ratón o eliges de objetivo. No se cambia en combate.",
			function() return M.BarraCerca and M.BarraCerca.PlacasEnemigas() end, function(v) if M.BarraCerca then M.BarraCerca.EncenderPlacas(v) end end),
		P.Boton(p, "Ver enemigos cerca y muertes", function() if M.Cercanos then M.Cercanos.Abrir() end end),
		P.Deslizador(p, "Transparencia de medidor, amenaza, barra «Cerca», ranking y marcadores", "100 % = sin transparencia. El tamaño se cambia con la rueda del ratón en «Mover elementos».", 30, 100, 5, "%d %%",
			function() return d.alfaMarcos end, function(v) d.alfaMarcos = v; M.AplicarTransparencia() end),
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
				{ key = "medidor", label = "Medidor", icon = "icon-level" }, { key = "builds", label = "Dos formas de jugar", icon = "record" },
				{ key = "avisos", label = "Avisos y barras", icon = "compact" } }
		end,
		activo = function() return sub end,
		elegir = function(k) if k == "jugar" or k == "modo" or k == "medidor" or k == "avisos" or k == "builds" then sub = k end end,
		dibujar = dibujar, refrescar = function() M.Proteger("panel", M.RefrescarPanel) end,
	})
end)
