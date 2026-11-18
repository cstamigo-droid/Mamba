'use strict';
// Mamba_Panel (K56/K57, MAMBA_ACEPTACION.md): las líneas de Mi plan DENTRO del panel de la guía de Polestar,
// en su flujo (parche P9), y las pestañas: otra guía se abre en una pestaña nueva (P11) y la de leveo queda
// fija, sin × (P10). Contra el Core, Theme, UI y Nav reales de Polestar y los falsos de tests/lua/stub_ui.lua.
// Corre con Lua 5.1; sin lua5.1 en Windows:
//   LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-panel.test.js

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { runAddon } = require('./helpers/lua');

const POLESTAR = { name: 'Polestar', files: ['Core/Core.xml', 'Nav/Nav.xml', 'Theme/Theme.xml', 'Lookup/Lookup.xml', 'UI/UI.xml', 'Maps/Maps.xml'] };

// Mi plan, falso: los pasos con la forma de Mamba_Plan/Plan.lua (M.Pasos).
const PLAN = `
local pj = { respuestas = {}, hechos = {}, descartados = {} }
MambaPlan = {
	PJ = function() return pj end,
	Estado = function() return { nivel = 40, oro = 900000, profesiones = {}, bolsas = { total = 64, libres = 1, ranuras = {}, vacias = 0 } } end,
	Pasos = function() return {
		{ clave = "guia", tipo = "Ahora", titulo = "Entrega 2 misiones", fijo = true, accion = "guia" },
		{ clave = "macro:forma", tipo = "Macro", titulo = "Macro de forma de oso", detalle = "Un clic.", accion = "macro", macro = "forma" },
		{ clave = "mazmorra:zf", tipo = "Mazmorra", titulo = "Zul'Farrak: vale la pena repetirla", detalle = "Collar (mejora 32 %) · 6 % por pasada · unas 4 pasadas", item = 9641 },
		{ clave = "montura40", tipo = "Montura", titulo = "Montura al 40: ya te alcanza", detalle = "Equitación 20 o + Kodo", lugar = { npc = 3690, mapa = 1412, x = 47.5, y = 58.2, zona = "Mulgore" } },
		{ clave = "rango:Cocina150", tipo = "Profesión", titulo = "Cocina 74/75: aprende Oficial", detalle = "Cuesta 5 p.", nivel = 10, lugar = { mapa = 1456, x = 51, y = 52, zona = "Cima del Trueno" } },
		{ clave = "bolsa:4499", tipo = "Bolsas", titulo = "Cambia tu bolsa de 6 por Bolsa de Huargo (12 casillas)", detalle = "subasta 2 o", item = 4499 },
	} end,
	ComoJuntar = function() return {} end,
	AlCambiar = function() end,
	Cambio = function() end,
}
`;


function run(script, opts = {}) {
	return runAddon({
		stubs: ['stub_nav.lua', 'stub_ui.lua'],
		addons: opts.sinPanel ? [POLESTAR] : [POLESTAR, 'Mamba_Panel'],
		script: `uistub.install()\n${PLAN}\nstub.login()\nlocal LEV = "forever/horde/orc-troll/01-durotar"\nlocal E, GF, N = Polestar.Engine, Polestar.UI.GuideFrame, MambaPanel\n${script}`,
	}).emitted;
}

test('K56: las líneas de Mi plan entran al panel de la guía, en su flujo, ordenadas por impacto ÷ costo', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		Polestar.Set("ui.shown", true)
		N.Refrescar(true)
		local cont, cab, filas = N._Piezas()
		local _, rel = cont:GetPoint(1)
		local textos, botones, subs = {}, {}, {}
		for i, r in ipairs(filas) do
			if r:IsShown() then textos[#textos + 1] = r.Text:GetText(); botones[#botones + 1] = r.Ir.Label:GetText(); subs[#subs + 1] = r.Sub:GetText() end
		end
		local claves = {}
		for _, l in ipairs(N.lineas) do claves[#claves + 1] = l.clave end
		emit({ estado = GF.State(), shown = cont:IsShown(), padre = rel == GF.parts.body, enBody = cont:GetParent() == GF.parts.body,
			rotulo = cab.Label:GetText(), textos = textos, botones = botones, subs = subs, claves = claves, n = #N.lineas })`);
	assert.equal(out.estado, 'steps', 'con la guía de leveo en un paso');
	assert.equal(out.shown, true, 'la parte de Mamba se ve');
	assert.equal(out.enBody, true, 'vive dentro del cuerpo del panel de la guía (sin marco encima)');
	assert.equal(out.padre, true, 'Polestar la apila en su flujo (parche P9)');
	assert.equal(out.rotulo, 'Mamba · tu plan');
	assert.ok(!out.claves.includes('guia'), 'el paso de la guía no se repite: la guía ya es el panel');
	assert.equal(out.claves[0], 'montura40', 'la montura (gran mejora, a 2 min + viaje) va primero');
	assert.ok(out.claves.indexOf('mazmorra:zf') > out.claves.indexOf('llenas'), 'la mazmorra (en grupo, ≈100 min) va después de vender');
	assert.ok(out.claves.includes('llenas'), 'bolsas casi llenas: vender o guardar');
	assert.equal(out.textos.length, 4, 'cuatro a la vista; el resto en Mi plan');
	assert.equal(out.botones[0], 'Llévame', 'la línea con lugar trae Llévame');
	assert.match(out.subs[0], /gran mejora · ≈\d+ min · solo · Equitación/, 'la puntuación y el cómo, debajo');
});

test('K61: Llévame pone la flecha de Polestar; la línea de profesión abre su guía', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		N.Refrescar(true)
		-- la flecha de Polestar, falsa (stub_nav no trae Nav.API): se mira qué le pidió Mamba
		local pedido
		Polestar.Nav.API = { Navigate = function(o, m, x, y, t) pedido = { o, m, x, y, t }; return true end }
		local _, _, filas = N._Piezas()
		stub.RunScript(filas[1], "OnClick", "LeftButton")
		local activo, dueno = pedido ~= nil, pedido and pedido[1]
		local mapa, x = pedido and pedido[2], pedido and pedido[3]
		local prof
		for _, l in ipairs(N.lineas) do if l.tipo == "rango" then prof = l end end
		emit({ mapa = mapa, x = x, activo = activo, dueno = dueno, guia = prof and prof.guia and prof.guia.id, accion = prof and (N.Accion(prof)) })`);
	assert.equal(out.activo, true);
	assert.equal(out.dueno, 'Mamba', 'la flecha es de Mamba');
	assert.equal(out.mapa, 1412, 'a Mulgore (el lugar de la montura)');
	assert.equal(out.x, 0.475, 'en fracción, como la toma Nav.API');
	assert.equal(out.guia, 'forever/professions/cooking');
	assert.equal(out.accion, 'Llévame', 'con lugar, el botón lleva; la guía va en el clic derecho');
});

test('K57: otra guía en una pestaña nueva; la de leveo queda fija y las otras se cierran con ×', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		local idx = N.AbrirProfesion("Cocina")
		GF.Render()
		local tabs, activa = E.GetTabs()
		local b1, b2 = GF.tabs[1], GF.tabs[2]
		local fijo1, cierre1, cierre2 = b1.psFijo, b1.Close:IsShown(), b2.Close:IsShown()
		-- el clic del medio no cierra la fija
		stub.RunScript(b1, "OnClick", "MiddleButton")
		local trasMedio = #E.GetTabs()
		-- la × de cocina sí
		stub.RunScript(b2.Close, "OnClick", "LeftButton")
		local trasX = E.GetTabs()
		emit({ idx = idx, n = #tabs, activa = tabs[activa].guideId, primera = tabs[1].guideId, fijo1 = fijo1, cierre1 = cierre1,
			cierre2 = cierre2, trasMedio = trasMedio, trasX = #trasX, queda = trasX[1].guideId })`);
	assert.equal(out.n, 2, 'dos pestañas');
	assert.equal(out.primera, 'forever/horde/orc-troll/01-durotar', 'la de leveo sigue ahí');
	assert.equal(out.activa, 'forever/professions/cooking', 'la nueva queda a la vista');
	assert.equal(out.fijo1, true);
	assert.equal(out.cierre1, false, 'la de leveo no tiene ×');
	assert.equal(out.cierre2, true, 'la de cocina sí');
	assert.equal(out.trasMedio, 2, 'el clic del medio no cierra la de leveo');
	assert.equal(out.trasX, 1, 'la × cierra cocina');
	assert.equal(out.queda, 'forever/horde/orc-troll/01-durotar');
});

test('K57 (P11): elegir cocina en el selector con la guía de leveo abierta la abre en otra pestaña', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		Polestar.UI.Picker.Load("forever/professions/cooking")
		local tabs, activa = E.GetTabs()
		-- otra guía de leveo sí reemplaza (como en Polestar)
		emit({ n = #tabs, a = tabs[1].guideId, b = tabs[2] and tabs[2].guideId, activa = activa })`);
	assert.equal(out.n, 2, 'no reemplaza la de leveo');
	assert.equal(out.a, 'forever/horde/orc-troll/01-durotar');
	assert.equal(out.b, 'forever/professions/cooking');
	assert.equal(out.activa, 2);
});

test('K57: una recomendación con pasos se abre como guía de Mamba en una pestaña', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		N.Refrescar(true)
		local mont
		for _, l in ipairs(N.lineas) do if l.clave == "montura40" then mont = l end end
		-- stub_ui trae su propio registro de guías: lo que se registra, va ahí
		Polestar.RegisterGuide = function(g) uistub.guides[g.id] = g; return true end
		local idx = N.AbrirGuiaDe(mont)
		local tabs, activa = E.GetTabs()
		emit({ idx = idx, n = #tabs, id = tabs[activa].guideId, titulo = tabs[activa].title })`);
	assert.equal(out.n, 2);
	assert.equal(out.id, 'lookup/mamba/montura40');
	assert.match(out.titulo, /^Mamba: Montura al 40/);
});

test('Hecho y No me interesa sacan la línea; el modo compacto la esconde; el rótulo la pliega', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		N.Refrescar(true)
		local antes = #N.lineas
		N.Hecho(N.lineas[1]); N.Refrescar(true)
		local tras = #N.lineas
		local cont, cab = N._Piezas()
		stub.RunScript(cab, "OnClick", "LeftButton")
		local plegado, rotulo = cont:GetHeight(), cab.Label:GetText()
		stub.RunScript(cab, "OnClick", "LeftButton")
		Polestar.Set("ui.compact", true); GF.Layout()
		emit({ antes = antes, tras = tras, plegado = plegado, rotulo = rotulo, compacto = cont:IsShown(), hecho = MambaPlan.PJ().hechos.montura40 })`);
	assert.equal(out.tras, out.antes - 1);
	assert.equal(out.hecho, true, 'queda marcado en Mi plan (el mismo estado)');
	assert.match(out.rotulo, /^Mamba · tu plan \(\d+\)$/, 'plegado dice cuántas hay');
	assert.ok(out.plegado <= 31, 'plegado: solo el rótulo');
	assert.equal(out.compacto, false, 'en el modo compacto no se muestra');
});

test('control negativo: sin Mamba_Panel, Polestar dibuja su panel igual (el parche P9 no rompe nada)', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		GF.Render()
		emit({ ok = true, gancho = Polestar.UI.MambaLineas == nil })`, { sinPanel: true });
	assert.equal(out.ok, true);
	assert.equal(out.gancho, true);
});

test('K58 en el panel: Llévame usa el motor de Ir a… y el viaje en curso se ve tramo por tramo arriba', () => {
	const [out] = run(`
		local pedido
		MambaAPI = MambaAPI or {}
		MambaAPI.Llevame = function(d) pedido = d; return true end
		MambaAPI.TiempoTexto = function(seg, est) return (est and "≈ " or "") .. math.floor(seg / 60) .. ":" .. string.format("%02d", seg % 60) end
		MambaAPI.RutaActual = function() return { nombre = "Mulgore", total = 278, estimado = true, tramos = {
			{ tipo = "piedra", texto = "Piedra de hogar a Cima del Trueno", seg = 10, medido = true, estimado = false },
			{ tipo = "vuelo", texto = "Vuela a Bloodhoof", seg = 200, estimado = true },
			{ tipo = "caminar", texto = "Caminar 382 yd", seg = 68, estimado = true } } } end
		E.SetGuide(LEV)
		N.Refrescar(true)
		local _, _, filas = N._Piezas()
		local t = {}
		for i = 1, 4 do t[i] = { filas[i].Text:GetText(), filas[i].Sub:GetText(), filas[i].Ir:IsShown() } end
		local mont
		for _, l in ipairs(N.lineas) do if l.clave == "montura40" then mont = l end end
		N.Llevame(mont)
		emit({ t = t, map = pedido and pedido.map, x = pedido and pedido.x, nombre = pedido and pedido.nombre, visibles = (function() local n = 0 for _, r in ipairs(filas) do if r:IsShown() then n = n + 1 end end return n end)() })`);
	assert.equal(out.t[0][0], 'Viaje a Mulgore');
	assert.equal(out.t[0][1], 'en total ≈ 4:38');
	assert.equal(out.t[1][0], 'Piedra de hogar a Cima del Trueno');
	assert.equal(out.t[1][1], '0:10', 'medido: sin ≈');
	assert.equal(out.t[2][1], '≈ 3:20', 'estimado: con ≈');
	assert.equal(out.t[1][2], false, 'un tramo no tiene botón');
	assert.equal(out.visibles, 8, 'los 4 del viaje y las 4 del plan');
	assert.equal(out.map, 1412);
	assert.equal(out.x, 47.5);
	assert.match(out.nombre, /^Montura al 40/);
});

test('revisión: la montura sale una vez, "todavía no" antes del nivel, Llévame a la mazmorra por su nombre, sin fallas', () => {
	const [out] = run(`
		local pasos0 = MambaPlan.Pasos
		MambaPlan.Estado = function() return { nivel = 39, oro = 900000, profesiones = {}, bolsas = { total = 64, libres = 10 } } end
		MambaPlan.Pasos = function()
			local t = pasos0()
			table.insert(t, 1, { clave = "meta:montura40", tipo = "Nivel 40", titulo = "Montura al 40: 20 o", detalle = "Te alcanza.", lugar = { mapa = 1412, x = 47.5, y = 58.2 } })
			return t
		end
		local pedido
		MambaAPI = MambaAPI or {}
		MambaAPI.Llevame = function(d) pedido = d; return true end
		E.SetGuide(LEV)
		N.Refrescar(true)
		local monturas, mont, mz = 0
		for _, l in ipairs(N.lineas) do
			if l.tipo == "montura" then monturas = monturas + 1; mont = l end
			if l.tipo == "mazmorra" then mz = l end
		end
		local txt = N.Accion(mz)
		N.Llevame(mz)
		emit({ monturas = monturas, ya = mont.puedeYa, ultima = N.lineas[#N.lineas].tipo, txt = txt, pedido = pedido,
			fallas = MambaPanelPJ.diag.fallas and #MambaPanelPJ.diag.fallas or 0 })`);
	assert.equal(out.monturas, 1, 'una sola línea de montura');
	assert.equal(out.ya, false, 'a nivel 39 la montura del 40 todavía no');
	assert.equal(out.ultima, 'montura', 'lo que todavía no se puede va al final');
	assert.equal(out.txt, 'Llévame', 'la mazmorra trae Llévame (a la entrada)');
	assert.equal(out.pedido, "Zul'Farrak", 'por su nombre, al motor de Ir a…');
	assert.equal(out.fallas, 0);
});

test('profesiones: MambaProfesiones.Recomendaciones entra con su cómo, su Llévame al farmeo y su guía', () => {
	const [out] = run(`
		local llevo
		MambaProfesiones = { Recomendaciones = function() return {
			{ texto = "Sube Cocina de 190 a 225", como = "Cocina 40 Huevo de raptor · Cima del Trueno", impacto = "+35 puntos de Cocina",
			  puntos = 35, minutos = 18.4, oro = 0, solo = true, estrellas = "Conviene mucho", razon = 3.8,
			  llevame = function() llevo = true end, abrir = function() end } } end }
		E.SetGuide(LEV)
		N.Refrescar(true)
		local p
		for _, l in ipairs(N.lineas) do if l.tipo == "profesion" then p = l end end
		local txt, fn = N.Accion(p)
		fn()
		emit({ titulo = p.titulo, como = p.como, min = p.minutos, imp = p.impacto, guia = p.guia and p.guia.id, txt = txt, llevo = llevo })`);
	assert.equal(out.titulo, 'Sube Cocina de 190 a 225');
	assert.match(out.como, /Cima del Trueno/);
	assert.equal(out.min, 18);
	assert.equal(out.imp, 4);
	assert.equal(out.guia, 'forever/professions/cooking');
	assert.equal(out.txt, 'Llévame');
	assert.equal(out.llevo, true, 'Llévame usa el de Profesiones (flecha al farmeo y medición)');
});

// K103: avisos de oportunidad
const AVISOS = `
C_Map = C_Map or {}
C_Map.GetBestMapForUnit = function() return 1412 end
GetRealZoneText = function() return "Mulgore" end
MambaAPI = MambaAPI or {}
local publicado
MambaAPI.PonerEnSubasta = function(id, precio) publicado = { id, precio }; return true end
function PUBLICADO() return publicado end
MambaAPI.Bolsas = function() return {
	{ id = 4306, link = "|cffffffff|Hitem:4306::::::::|h[Paño de seda]|h|r", cantidad = 20, sug = "subastar", precio = 900, motivo = "Hoy se paga bien" },
	{ id = 2589, link = "|cffffffff|Hitem:2589::::::::|h[Paño de lino]|h|r", cantidad = 5, sug = "subastar", precio = 40 },
	{ id = 4865, link = "|cff9d9d9d|Hitem:4865::::::::|h[Garra rota]|h|r", cantidad = 3, sug = "basura", vendedor = 5 },
	{ id = 2770, cantidad = 10, sug = "guardar", vendedor = 1 },
} end
`;

test('K103: avisos de lugar, subasta (con Publicar), espacio y botín; cada tipo se silencia', () => {
	const [out] = run(`${AVISOS}
		E.SetGuide(LEV)
		N.Refrescar(true)
		local mont
		for _, l in ipairs(N.lineas) do if l.clave == "montura40" then mont = l end end
		local lugar = mont.titulo
		-- en la subasta
		stub.fire("AUCTION_HOUSE_SHOW")
		local sub, esp
		for _, l in ipairs(N.lineas) do
			if l.aviso == "subasta" and not sub then sub = l end
			if l.aviso == "espacio" then esp = l end
		end
		local txt, fn = N.Accion(sub)
		fn()
		local nSub = 0
		for _, l in ipairs(N.lineas) do if l.aviso == "subasta" then nSub = nSub + 1 end end
		local hayLlenas = false
		for _, l in ipairs(N.lineas) do if l.clave == "llenas" then hayLlenas = true end end
		-- botín: un material que vale 1 o en la subasta
		MambaAPI.PrecioObjeto = function(id) return 10000, "subasta" end
		GetNumLootItems = function() return 1 end
		GetLootSlotLink = function() return "|cffffffff|Hitem:3667::::::::|h[Carne de kodo]|h|r" end
		UnitExists = function() return true end
		UnitIsDead = function() return true end
		UnitName = function(u) if u == "target" then return "Kodo de las llanuras" end return "Hope" end
		UnitGUID = function(u) if u == "target" then return "Creature-0-1-2-3-4-5" end end
		GetLootSourceInfo = function() return "Creature-0-1-2-3-4-5", 1 end
		stub.fire("LOOT_READY")
		N.Refrescar(true)
		local bot
		for _, l in ipairs(N.lineas) do if l.aviso == "botin" then bot = l end end
		-- silenciar "subasta" y "lugar"
		N.Silenciar("subasta"); N.Silenciar("lugar"); N.Refrescar(true)
		local quedan = 0
		local mont2
		for _, l in ipairs(N.lineas) do if l.aviso == "subasta" then quedan = quedan + 1 end; if l.clave == "montura40" then mont2 = l end end
		-- y se vuelve a encender
		N.Silenciar("subasta", false); N.Refrescar(true)
		local vuelven = 0
		for _, l in ipairs(N.lineas) do if l.aviso == "subasta" then vuelven = vuelven + 1 end end
		-- un botín que no es del objetivo no nombra al bicho
		GetLootSourceInfo = function() return "Creature-otro", 1 end
		N.botin = {}; stub.fire("LOOT_READY"); N.Refrescar(true)
		local otro
		for _, l in ipairs(N.lineas) do if l.aviso == "botin" then otro = l.titulo end end
		emit({ vuelven = vuelven, otro = otro, lugar = lugar, sub = sub.titulo, txt = txt, pub = PUBLICADO(), nSub = nSub, esp = esp and esp.titulo, llenas = hayLlenas,
			bot = bot and bot.titulo, quedan = quedan, mont2 = mont2.titulo, fallas = MambaPanelPJ.diag.fallas and #MambaPanelPJ.diag.fallas or 0 })`);
	assert.match(out.lugar, /^Ya que estás en Mulgore: Montura al 40/, 'la línea con lugar en tu mapa se vuelve aviso');
	assert.equal(out.sub, 'Ya que estás en la subasta: vende Paño de seda a 9 p', 'lo que más deja primero');
	assert.equal(out.txt, 'Publicar');
	assert.deepEqual(out.pub, [4306, 900], 'deja la subasta lista con su precio');
	assert.equal(out.nSub, 2, 'a lo sumo dos avisos de subasta');
	assert.equal(out.esp, 'Vende Garra rota (15 c) para hacer espacio', 'con las bolsas llenas dice QUÉ vender (lo que menos vale)');
	assert.equal(out.llenas, false, 'el aviso de espacio reemplaza la línea genérica');
	assert.equal(out.bot, 'Kodo de las llanuras da Carne de kodo: se vende a 1 o en la subasta');
	assert.equal(out.quedan, 0, 'silenciado por tipo');
	assert.equal(out.vuelven, 2, 'y se vuelve a encender');
	assert.match(out.otro, /^Lo que matas aquí da Carne de kodo/, 'si el botín no es del objetivo, no se nombra al bicho');
	assert.match(out.mont2, /^Montura al 40/, 'sin el aviso de lugar, la línea vuelve a la normal');
	assert.equal(out.fallas, 0);
});

test('K103 control negativo: sin datos del Tasador ni subasta abierta, no hay avisos inventados', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		N.Refrescar(true)
		local n = 0
		for _, l in ipairs(N.lineas) do if l.aviso and l.aviso ~= "lugar" then n = n + 1 end end
		emit({ n = n })`);
	assert.equal(out.n, 0);
});

test('K108: el botón «Servicios de la ciudad» aparece solo si la ventana expone MambaAPI.AbrirServicios', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		N.Refrescar(true)
		local _, cab = N._Piezas()
		local antes = cab.Serv:IsShown()
		local abierto
		MambaAPI = MambaAPI or {}
		MambaAPI.AbrirServicios = function() abierto = true end
		N.Refrescar(true)
		stub.RunScript(cab.Serv, "OnClick", "LeftButton")
		emit({ antes = antes, despues = cab.Serv:IsShown(), abierto = abierto, texto = cab.Serv.Label:GetText() })`);
	assert.equal(out.antes, false);
	assert.equal(out.despues, true);
	assert.equal(out.abierto, true);
	assert.equal(out.texto, 'Servicios de la ciudad');
});

test('botones: miden su texto (nunca "Llévam"); en un panel angosto bajan a su propia línea', () => {
	const [out] = run(`
		E.SetGuide(LEV)
		N.Refrescar(true)
		local function medir(ancho)
			N.LayoutLineas(GF, GF.parts.body, ancho, true, 14, 39, 24, 30)
			local _, _, filas = N._Piezas()
			local r = filas[1]
			local lw, sw = r.Ir.Label:GetWidth(), r.Ir.Label:GetStringWidth()
			local p = { r.Ir:GetPoint(1) }
			return { texto = r.Ir.Label:GetText(), cabe = lw >= sw, abajo = r.psAbajo and true or false, ancla = p[1] }
		end
		emit({ ancho = medir(420), angosto = medir(230) })`);
	assert.equal(out.ancho.texto, 'Llévame');
	assert.equal(out.ancho.cabe, true, 'el texto entra entero');
	assert.equal(out.ancho.abajo, false);
	assert.equal(out.ancho.ancla, 'TOPRIGHT');
	assert.equal(out.angosto.cabe, true);
	assert.equal(out.angosto.abajo, true, 'en un panel angosto el botón baja');
	assert.equal(out.angosto.ancla, 'TOPLEFT');
});
