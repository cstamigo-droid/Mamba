'use strict';
// Mamba: REGLA DE ESTÉTICA (WOW_FOREVER/ESTETICA_MAMBA.md). Las ventanas y textos de los módulos de Mamba
// se dibujan con las piezas de Polestar y siguen la apariencia que eligió el jugador, igual que una
// ventana del propio Polestar (la de copiar, UI/Copy.lua, sirve de vara).
// Corre con Lua 5.1; sin lua5.1 instalado en Windows:
//   LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-estetica.test.js

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { runAddon } = require('./helpers/lua');

const POLESTAR = { name: 'Polestar', files: ['Core/Core.xml', 'Theme/Theme.xml', 'UI/UI.xml'] };

function run(script, conPolestar = true) {
	return runAddon({
		stubs: ['stub_ui.lua'],
		addons: conPolestar ? [POLESTAR, 'Asistente'] : ['Asistente'],
		script: `${conPolestar ? 'uistub.install()\n' : ''}stub.login()\nlocal A = Asistente\n${script}`,
	}).emitted;
}

// Letra y color de un texto, para comparar dos textos.
const LETRA = `
local function letra(fs)
	local cara, tam = fs:GetFont()
	local r, g, b = fs:GetTextColor()
	return { cara = cara, tam = tam and math.floor(tam + 0.5), color = string.format("%.2f,%.2f,%.2f", r or -1, g or -1, b or -1) }
end
`;

test('con Polestar: la ventana de un módulo es una ventana de Polestar (banda, cruz, título con su letra)', () => {
	const [out] = run(`${LETRA}
		Polestar.UI.ShowCopy("vara", "x")
		local vara = PolestarCopy
		local f = A.CrearVentana("MambaPruebaVentana", "Servicios", 320, 200)
		f:Show()
		emit({ polestar = f.polestar == true, banda = f.banda ~= nil, cerrar = f.cerrar ~= nil,
			cuerpo = f.cuerpo, titulo = f.titulo:GetText(), plantilla = type(f.TitleText) == "table",
			igual = letra(f.titulo).cara == letra(vara.Title).cara and letra(f.titulo).tam == letra(vara.Title).tam })
	`);
	assert.equal(out.polestar, true);
	assert.equal(out.banda, true, 'lleva la banda de estrellas');
	assert.equal(out.cerrar, true, 'lleva la cruz de Polestar');
	assert.equal(out.plantilla, false, 'no usa la plantilla gris del juego');
	assert.equal(out.cuerpo, 56);
	assert.equal(out.titulo, 'Servicios');
	assert.equal(out.igual, true, 'el título usa la misma letra que el de una ventana de Polestar');
});

test('con Polestar: al cambiar de apariencia, el texto del módulo cambia igual que el de Polestar', () => {
	const out = run(`${LETRA}
		local T = Polestar.Theme
		Polestar.UI.ShowCopy("vara", "x")
		local f = A.CrearVentana("MambaPruebaVentana2", "Servicios", 320, 200)
		local texto = A.Texto(f, "title", "text")
		texto:SetText("hola")
		f:Show() -- Polestar repinta lo que está a la vista (lo oculto, al mostrarse)
		local vistas = {}
		for _, c in ipairs(T.SkinChoices()) do
			Polestar.Set("ui.skin", c.value)
			T.Refresh()
			local a, b = letra(texto), letra(PolestarCopy.Title)
			vistas[#vistas + 1] = { skin = c.value, igual = a.cara == b.cara and a.tam == b.tam and a.color == b.color, cara = a.cara, color = a.color, cara2 = b.cara, color2 = b.color, tam = a.tam, tam2 = b.tam }
		end
		emit(vistas)
	`);
	const vistas = out[0];
	assert.ok(vistas.length >= 6, `hay apariencias para probar (${vistas.length})`);
	for (const v of vistas) assert.equal(v.igual, true, `apariencia ${v.skin}: el texto de Mamba no sigue a Polestar: ${JSON.stringify(v)}`);
	const distintas = new Set(vistas.map((v) => `${v.cara}|${v.color}`));
	assert.ok(distintas.size >= 2, 'las apariencias cambian de verdad la letra o el color (si no, la prueba no mide nada)');
});

test('con Polestar: los colores con significado son los de la apariencia (el dorado es su acento)', () => {
	const [out] = run(`
		local T = Polestar.Theme
		emit({ titulo = A.Color("titulo", "x"), acento = "|c" .. T.Hex("accent") .. "x|r",
			gris = A.Color("gris", "x"), apagado = "|c" .. T.Hex("textMuted") .. "x|r" })
	`);
	assert.equal(out.titulo, out.acento);
	assert.equal(out.gris, out.apagado);
});

test('con Polestar: los ajustes de un módulo van a la ventana de ajustes de Polestar, página Mamba', () => {
	const [out] = run(`
		local valor = false
		local ok = A.Opciones("Servicios", "Prueba", { { kind = "toggle", label = "Abrir sola",
			get = function() return valor end, set = function(v) valor = v end } })
		local pagina
		Polestar.Widgets.OnOptionsRegistered(function(spec) if spec.page == "Mamba" then pagina = spec end end)
		pagina.controls[1].set(true)
		emit({ ok = ok, tab = pagina.tab, get = pagina.controls[1].get() })
	`);
	assert.deepEqual(out, { ok: true, tab: 'Servicios', get: true });
});

test('sin Polestar: la ventana cae a la plantilla del juego y nada se rompe', () => {
	const [out] = run(`
		local f = A.CrearVentana("MambaPruebaSola", "Servicios", 320, 200)
		emit({ polestar = f.polestar == true, plantilla = type(f.TitleText) == "table", color = A.Color("titulo", "x"),
			opciones = A.Opciones("Servicios", "Prueba", {}) })
	`, false);
	assert.equal(out.polestar, false);
	assert.equal(out.color, '|cffffd100x|r');
	assert.equal(out.opciones, false);
});

test('módulo de prueba: la ventana de Servicios (/servicios) se dibuja con Polestar y su ajuste está en la página Mamba', () => {
	const [out] = runAddon({
		stubs: ['stub_ui.lua'],
		addons: [POLESTAR, 'Asistente', 'Asistente_Servicios'],
		script: `uistub.install()\nstub.login()
			local A = Asistente
			local S = A.modulos.servicios
			local id = next(S.datos.ciudades)
			S.Abrir(id)
			local v = AsistenteServiciosVentana
			local pagina
			Polestar.Widgets.OnOptionsRegistered(function(spec) if spec.page == "Mamba" and spec.tab == "Servicios" then pagina = spec end end)
			emit({ abierta = v:IsShown(), polestar = v.polestar == true, banda = v.banda ~= nil,
				buscador = v.buscar.Placeholder ~= nil, filas = #v.filas, titulo = v.titulo:GetText(),
				ajuste = pagina and pagina.controls[1].label or false })
		`,
	}).emitted;
	assert.equal(out.abierta, true);
	assert.equal(out.polestar, true, 'ventana de Polestar, no la plantilla gris');
	assert.equal(out.banda, true);
	assert.equal(out.buscador, true, 'el buscador es el de Polestar (con texto de ayuda)');
	assert.equal(out.filas, 14);
	assert.match(out.titulo, /^Servicios de /);
	assert.equal(out.ajuste, 'Abrir la lista al entrar a una ciudad');
});

test('módulo de prueba: al cambiar de apariencia, las filas de Servicios se reescriben con los colores nuevos (no quedan pegados)', () => {
	const [out] = runAddon({
		stubs: ['stub_ui.lua'],
		addons: [POLESTAR, 'Asistente', 'Asistente_Servicios'],
		script: `uistub.install()
stub.login()
			local A, T = Asistente, Polestar.Theme
			local S = A.modulos.servicios
			S.Abrir(next(S.datos.ciudades))
			local v = AsistenteServiciosVentana
			local vistas = {}
			for _, c in ipairs(T.SkinChoices()) do
				Polestar.Set("ui.skin", c.value)
				T.Refresh()
				local fila = v.filas[1]:IsShown() and v.filas[1].texto:GetText() or ""
				local pie = v.pie:GetText() or ""
				vistas[#vistas + 1] = { skin = c.value, fila = fila:find(T.Hex("text"), 1, true) ~= nil or fila:find(T.Hex("textMuted"), 1, true) ~= nil,
					pie = pie:find(T.Hex("textMuted"), 1, true) ~= nil, hex = T.Hex("textMuted") }
			end
			emit(vistas)
		`,
	}).emitted;
	assert.ok(out.length >= 6);
	for (const x of out) {
		assert.equal(x.fila, true, `apariencia ${x.skin}: la fila no tiene el color de la apariencia`);
		assert.equal(x.pie, true, `apariencia ${x.skin}: el pie no tiene el color de la apariencia`);
	}
	assert.ok(new Set(out.map((x) => x.hex)).size >= 2, 'las apariencias cambian el color de verdad (si no, la prueba no mide nada)');
});

test('la ventana vuelve al lugar guardado (AsistenteDB.ventanas, lo guarda el onStop del arrastre de Polestar)', () => {
	const [out] = run(`
		AsistenteDB = AsistenteDB or { ajustes = {} }
		AsistenteDB.ventanas = { MambaPruebaLugar = { 111, 555 } }
		local f = A.CrearVentana("MambaPruebaLugar", "x", 200, 100)
		local p, rel, relp, x, y = f:GetPoint(1)
		emit({ p = p, relp = relp, x = x, y = y })
	`);
	assert.deepEqual(out, { p: 'TOPLEFT', relp: 'BOTTOMLEFT', x: 111, y: 555 });
});

test('la página Mamba › Servicios existe desde el inicio, antes de que Servicios se cargue (E5)', () => {
	const [out] = run(`
		local pagina
		Polestar.Widgets.OnOptionsRegistered(function(spec) if spec.page == "Mamba" and spec.tab == "Servicios" then pagina = spec end end)
		emit({ hay = pagina ~= nil, cargado = A.modulos.servicios ~= nil, valor = pagina and pagina.controls[1].get() })
	`);
	assert.deepEqual(out, { hay: true, cargado: false, valor: true });
});
