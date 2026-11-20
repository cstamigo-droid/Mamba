'use strict';
// Mamba K63: la mamba negra del encabezado (addon/Asistente/Serpiente.lua). Da la vuelta a POLESTAR sin pisar
// ningún texto, se acuesta junto a "Mamba", corre solo con la ventana abierta, se queda quieta en combate y
// se apaga con su interruptor. Las texturas son propias (tools/asistente/serpiente_texturas.py).
//   LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-serpiente.test.js

const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { runAddon } = require('./helpers/lua');

const POLESTAR = { name: 'Polestar', files: ['Core/Core.xml', 'Nav/Nav.xml', 'Theme/Theme.xml', 'UI/UI.xml', 'Maps/Maps.xml'] };

function run(script) {
	return runAddon({
		stubs: ['stub_nav.lua', 'stub_ui.lua'],
		addons: [POLESTAR, 'Asistente'],
		script: `uistub.install()\nstub.login()\nlocal A = Asistente\nlocal S = A.Serpiente\n${script}`,
	}).emitted;
}

// La cabeza: su textura y dónde está.
const CABEZA = `
local function cabeza(s)
	local _, _, _, x, y = s.cabeza:GetPoint(1)
	return { x = x, y = -y }
end
`;

test('al abrir la ventana de Mamba la serpiente se arma sobre su barra lateral, con sus texturas propias', () => {
	const [out] = run(`
		Polestar.UI.ShowPicker()
		local s = S.actual
		local archivos = {}
		for _, t in ipairs(s and s.discos or {}) do archivos[t:GetTexture()] = true end
		emit({ armada = s ~= nil, enLaBarra = s and s.host:GetParent() == PolestarPicker.Sidebar, visible = s and s.host:IsVisible(),
			discos = s and #s.discos, esperados = #S.DISCOS, cuerpo = next(archivos), cabeza = s and s.cabeza:GetTexture(),
			lengua = s and s.lengua:GetTexture(), ciclo = S.C.ciclo, puntos = s and s.P and #s.P })
	`);
	assert.equal(out.armada, true);
	assert.equal(out.enLaBarra, true);
	assert.equal(out.visible, true);
	assert.equal(out.discos, out.esperados);
	assert.equal(out.cuerpo, 'Interface\\AddOns\\Asistente\\Media\\serpiente-cuerpo');
	assert.equal(out.cabeza, 'Interface\\AddOns\\Asistente\\Media\\serpiente-cabeza');
	assert.equal(out.lengua, 'Interface\\AddOns\\Asistente\\Media\\serpiente-lengua');
	assert.ok(out.ciclo >= 8 && out.ciclo <= 12, `una vuelta cada 8-12 s (es ${out.ciclo})`);
	assert.ok(out.puntos > 500, 'la huella está muestreada');
});

test('la huella rodea POLESTAR sin pisar el logotipo, "Un proyecto comunitario" ni "Mamba", y termina junto a "Mamba"', () => {
	const [out] = run(`
		Polestar.UI.ShowPicker()
		local s = S.actual
		local g = S.Geometria(PolestarPicker)
		local cajas = {
			{ "logotipo", g.ink.l, g.ink.t, g.ink.r, g.ink.b },
			{ "lema", g.tag.l, g.tag.t + 1, g.tag.r, g.tag.t + 11 },
			{ "Mamba", g.mamba.l, g.mamba.t, g.mamba.r, g.mamba.t + g.mamba.h },
		}
		local choques, minX, maxX, minY, maxY = {}, 1e9, -1e9, 1e9, -1e9
		local media = S.C.grueso / 2 -- medio cuerpo a cada lado de la huella
		for _, p in ipairs(s.P) do
			minX, maxX, minY, maxY = math.min(minX, p[1]), math.max(maxX, p[1]), math.min(minY, p[2]), math.max(maxY, p[2])
			for _, c in ipairs(cajas) do
				if p[1] > c[2] - media and p[1] < c[4] + media and p[2] > c[3] - media and p[2] < c[5] + media then choques[c[1]] = true end
			end
		end
		local fin = s.P[#s.P]
		emit({ choques = choques, minX = minX, maxX = maxX, minY = minY, inkL = g.ink.l, inkR = g.ink.r, inkT = g.ink.t,
			finX = fin[1], finY = fin[2], mambaR = g.mamba.r, mambaMedio = g.mamba.t + g.mamba.h / 2, ancho = PolestarPicker.Sidebar:GetWidth() })
	`);
	assert.deepEqual(out.choques, {}, 'ningún texto queda debajo del cuerpo');
	assert.ok(out.minX < out.inkL && out.maxX > out.inkR && out.minY < out.inkT, 'el contorno rodea el logotipo');
	assert.ok(out.minX > 0 && out.maxX < out.ancho, 'no se sale de la barra lateral');
	assert.ok(Math.abs(out.finX - (out.mambaR + 4)) < 1.5, `la cabeza descansa 4 px después de "Mamba" (${out.finX} vs ${out.mambaR})`);
	assert.ok(Math.abs(out.finY - out.mambaMedio) < 2, 'a media altura de la palabra');
});

test('se mueve con la ventana abierta, se queda quieta en combate y con la ventana cerrada', () => {
	const [out] = run(`${CABEZA}
		Polestar.UI.ShowPicker()
		local s = S.actual
		stub.advance(1.5)
		local a = cabeza(s)
		stub.advance(1)
		local b = cabeza(s)
		stub.inCombat = true
		stub.fire("PLAYER_REGEN_DISABLED")
		stub.advance(2)
		local c = cabeza(s)
		stub.inCombat = false
		stub.fire("PLAYER_REGEN_ENABLED")
		stub.advance(0.5)
		local d = cabeza(s)
		PolestarPicker:Hide()
		local t0 = s.t
		stub.advance(3)
		emit({ mueve = a.x ~= b.x or a.y ~= b.y, quietaEnCombate = b.x == c.x and b.y == c.y, sigue = c.x ~= d.x or c.y ~= d.y,
			cerradaNoCorre = s.t == t0 })
	`);
	assert.equal(out.mueve, true);
	assert.equal(out.quietaEnCombate, true);
	assert.equal(out.sigue, true);
	assert.equal(out.cerradaNoCorre, true);
});

test('el ciclo: entra con fundido, se acuesta junto a "Mamba", saca la lengua y se desvanece', () => {
	const [out] = run(`
		Polestar.UI.ShowPicker()
		local s = S.actual
		local P = s.P
		local C = S.C
		local h0, a0 = S.Pose(P, 0.05)
		local hFin, aFin = S.Pose(P, C.tMover + 0.1)
		local _, _, lengua = S.Pose(P, C.tMover + C.lenguas[1][1] + 0.05)
		local _, aSale = S.Pose(P, C.tMover + C.tReposo + C.tSale + 0.05)
		emit({ a0 = a0, aFin = aFin, aSale = aSale, lengua = lengua, llega = math.abs(hFin - (#P - 1) / 2) < 0.01,
			cuerpoEntero = h0 >= C.largoCabeza + C.largoCuerpo - 0.01 })
	`);
	assert.ok(out.a0 < 0.2, 'entra con fundido');
	assert.equal(out.aFin, 1);
	assert.equal(out.aSale, 0, 'se desvanece');
	assert.equal(out.lengua, true);
	assert.equal(out.llega, true);
	assert.equal(out.cuerpoEntero, true, 'nunca asoma un cuerpo cortado');
});

test('el interruptor de Ajustes › Mamba › Qué se muestra la apaga y la prende', () => {
	const [out] = run(`
		local control
		Polestar.Widgets.OnOptionsRegistered(function(spec)
			if spec.page == "Mamba" and spec.tab == "Qué se muestra" and spec.controls[1] and spec.controls[1].label == "Serpiente animada en el encabezado" then control = spec.controls[1] end
		end)
		Polestar.UI.ShowPicker()
		local s = S.actual
		control.set(false)
		local apagada = not s.host:IsShown() and control.get() == false and AsistenteDB.ajustes.serpiente.animada == false
		local t0 = s.t
		stub.advance(1)
		local quieta = s.t == t0
		control.set(true)
		emit({ etiqueta = control.label, tab = "Qué se muestra", apagada = apagada, quieta = quieta, prendida = s.host:IsShown() and control.get() })
	`);
	assert.equal(out.etiqueta, 'Serpiente animada en el encabezado');
	assert.equal(out.apagada, true);
	assert.equal(out.quieta, true);
	assert.equal(out.prendida, true);
});

test('con "Reducir movimiento" de Polestar queda acostada junto a "Mamba", sin moverse', () => {
	const [out] = run(`
		Polestar.Set("ui.reduceMotion", true)
		Polestar.UI.ShowPicker()
		local s = S.actual
		local _, _, _, x0, y0 = s.cabeza:GetPoint(1)
		stub.advance(2)
		local _, _, _, x1, y1 = s.cabeza:GetPoint(1)
		emit({ quieta = x0 == x1 and y0 == y1, puesta = x0 ~= nil, alfa = s.host:GetAlpha() })
	`);
	assert.equal(out.puesta, true);
	assert.equal(out.quieta, true);
	assert.ok(out.alfa > 0.8);
});

test('las texturas son TGA de 32 bits, potencias de 2, y el generador las reproduce', () => {
	const media = path.join(__dirname, '..', 'addon', 'Asistente', 'Media');
	for (const n of ['serpiente-cuerpo', 'serpiente-cabeza', 'serpiente-lengua']) {
		const b = fs.readFileSync(path.join(media, `${n}.tga`));
		const w = b.readUInt16LE(12);
		const h = b.readUInt16LE(14);
		assert.equal(b[2], 2, `${n}: sin compresión`);
		assert.equal(b[16], 32, `${n}: 32 bits`);
		assert.ok((w & (w - 1)) === 0 && (h & (h - 1)) === 0, `${n}: ${w}x${h}`);
		assert.equal(b.length, 18 + w * h * 4);
	}
	assert.ok(fs.existsSync(path.join(__dirname, '..', 'tools', 'asistente', 'serpiente_texturas.py')));
});

test('deja un diagnóstico en AsistenteDB.diag.serpiente: montada, geometría, texturas, cuadros y pose', () => {
	const [out] = run(`
		Polestar.UI.ShowPicker()
		stub.advance(3)
		local d = AsistenteDB.diag.serpiente
		emit({ montada = d.montada, motivo = d.motivo, hook = d.hook, puntos = d.puntos, geo = type(d.geometria),
			cuerpo = d.texturas["serpiente-cuerpo"], cabeza = d.texturas["serpiente-cabeza"], cuadros = d.cuadros,
			pose = d.pose ~= nil and d.pose.visible, encendida = d.encendida })
	`);
	assert.equal(out.montada, true);
	assert.equal(out.motivo, undefined);
	assert.equal(out.hook, true);
	assert.ok(out.puntos > 500);
	assert.equal(out.geo, 'table');
	assert.equal(out.cuerpo, true);
	assert.equal(out.cabeza, true);
	assert.ok(out.cuadros > 10, `dibujó ${out.cuadros} cuadros`);
	assert.equal(out.pose, true);
	assert.equal(out.encendida, true);
});

test('el diagnóstico dice por qué no se monta (ventana sin la palabra "Mamba")', () => {
	const [out] = run(`
		local f = CreateFrame("Frame", nil, UIParent)
		f.Sidebar = CreateFrame("Frame", nil, f)
		local s = S.Montar(f)
		emit({ s = s ~= nil, motivo = AsistenteDB.diag.serpiente.motivo })
	`);
	assert.equal(out.s, false);
	assert.match(out.motivo, /MambaMarca/);
});

test('se monta aunque la ventana se abra sin pasar por ShowPicker (respaldo por temporizador)', () => {
	const [out] = run(`
		Polestar.UI.ShowPicker()
		S.actual = nil -- como si el gancho no hubiera llegado
		stub.advance(1.5)
		emit({ montada = S.actual ~= nil })
	`);
	assert.equal(out.montada, true);
});

test('si SetRotation falla deja de girar y sigue dibujando; un error al dibujar se anota una sola vez', () => {
	const [out] = run(`
		Polestar.UI.ShowPicker()
		local s = S.actual
		s.cabeza.SetRotation = function() error("sin rotación") end
		stub.advance(1)
		local cuadrosA = AsistenteDB.diag.serpiente.cuadros
		local giraFalso = AsistenteDB.diag.serpiente.gira == false
		local errores = 0
		local viejo = geterrorhandler
		geterrorhandler = function() return function() errores = errores + 1 end end
		s.discos[1].SetPoint = function() error("roto a propósito") end
		stub.advance(1)
		geterrorhandler = viejo
		local d = AsistenteDB.diag.serpiente
		emit({ giraFalso = giraFalso, siguio = cuadrosA > 5, rota = s.rota, error = d.error, errores = errores, n = d.errores })
	`);
	assert.equal(out.giraFalso, true);
	assert.equal(out.siguio, true);
	assert.equal(out.rota, true);
	assert.match(out.error, /roto a propósito/);
	assert.equal(out.errores, 1, 'a /errores llega uno, no uno por cuadro');
	assert.equal(out.n, 1);
});

test('la geometría sale de la posición REAL en pantalla, aunque el logotipo esté anclado a otro marco', () => {
	const [out] = run(`
		Polestar.UI.ShowPicker()
		local f = PolestarPicker
		local s = S.actual
		local antes = S.Geometria(f).fuente
		-- posiciones en pantalla como las resuelve el cliente (el simulado no las calcula): la barra en (100, 800),
		-- el logotipo re-anclado a OTRO marco con un desplazamiento que no sirve para la barra
		f.Sidebar.x, f.Sidebar.y = 100, 800 - f.Sidebar:GetHeight()
		f.Wordmark:ClearAllPoints()
		f.Wordmark:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 999, -999)
		f.Wordmark.x, f.Wordmark.y = 100 + 30, 800 - 25 - 32
		f.Tagline.x, f.Tagline.y = 100 + 32, 800 - 55 - f.Tagline:GetHeight()
		f.MambaMarca.x, f.MambaMarca.y = 100 + 32, 800 - 71 - f.MambaMarca:GetHeight()
		stub.advance(0.5) -- se vuelve a medir sola
		local g = S.Geometria(f)
		local minX = 1e9
		for _, p in ipairs(s.P) do minX = math.min(minX, p[1]) end
		emit({ antes = antes, fuente = g.fuente, inkL = g.ink.l, inkT = g.ink.t, mambaT = g.mamba.t, minX = minX,
			diag = AsistenteDB.diag.serpiente.geometria.fuente })
	`);
	assert.equal(out.antes, 'anclas', 'el simulado no da posiciones: usa las anclas');
	assert.equal(out.fuente, 'pantalla');
	assert.equal(out.inkL, 32, 'el logotipo a 30 px de la barra + 2 px hasta la tinta');
	assert.equal(out.inkT, 32, '25 px + 7 px hasta la tinta');
	assert.equal(out.mambaT, 71);
	assert.ok(Math.abs(out.minX - 25) < 1.5, `la huella sigue al logotipo en pantalla (minX ${out.minX}), no a sus anclas`);
	assert.equal(out.diag, 'pantalla');
});
