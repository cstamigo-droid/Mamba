'use strict';
// Mamba 1.0 (ARQUITECTURA §16): las filas que Polestar ya cubre, probadas con el Polestar DEL FORK
// (con los parches de tools/asistente/parches.py) y la configuración por defecto, sin nada guardado.
//   TomTom          -> /way y la flecha, sin TomTom instalado (parche P3)
//   Pawn            -> la línea "+X% upgrade" en el cuadro del objeto
//   GearQuestForever-> la recompensa recomendada marcada al entregar
//   y los parches P1/P2: errores y avisos de versión no apuntan al Polestar oficial.
// Corre con Lua 5.1; sin lua5.1 instalado en Windows:
//   LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-reemplazos.test.js

const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { runAddon } = require('./helpers/lua');

const ADDON = path.join(__dirname, '..', 'addon');

// Mapa de prueba, como rust/crates/forge-addontest/tests/addontest/nav-journey.rs.
const WORLD = `
local nav = stub.nav
nav.maps[9100] = { c = 0, top = 2000, bottom = -2000, left = 2000, right = -2000, name = "Testland" }
function C_Map.GetMapInfo(id)
	local m = nav.maps[id]
	if m then return { mapID = id, name = m.name, mapType = id == 9100 and 2 or 3, parentMapID = id == 9100 and 0 or 9100 } end
end
function C_Map.GetBestMapForUnit() return 9000 end
function C_Map.GetMapChildrenInfo(root)
	if root ~= 9100 then return {} end
	return { { mapID = 9000, name = "Testshire", mapType = 3 } }
end
stub.foci = {}
function GetMouseFoci() return stub.foci end
Menu = { ModifyMenu = function() end }
`;

function nav(script) {
	return runAddon({
		stubs: ['stub_nav.lua'],
		before: WORLD,
		addons: [{ name: 'Polestar', files: ['Core/Init.lua', 'Nav/Nav.xml'] }],
		login: true,
		script: `local N = Polestar.Nav\n${script}`,
	}).emitted;
}

test('TomTom: con TomTom apagado, Mamba responde /way y la API de puntos de TomTom por defecto (parche P3)', () => {
	const out = nav(`
		emit({ default = Polestar.Get("nav.answerTomTom"), way = SLASH_POLESTARWAY1, shim = TomTom == N.tomtomShim })
		SlashCmdList.POLESTARWAY("45 61 Campamento")
		local t = N.GetTarget()
		emit({ map = t.map, x = t.x, y = t.y, label = t.label })
		SlashCmdList.POLESTARWAY("reset")
		emit(N.GetTarget() == nil)
		local uid = TomTom:AddWaypoint(9000, 0.25, 0.75, { title = "Instructor", from = "WhatsTraining" })
		t = N.GetTarget()
		emit({ x = t.x, y = t.y, label = t.label, valid = TomTom:IsValidWaypoint(uid) })
		TomTom:RemoveWaypoint(uid)
		emit(N.GetTarget() == nil)
	`);
	assert.deepEqual(out[0], { default: true, way: '/way', shim: true });
	assert.deepEqual(out[1], { map: 9000, x: 45, y: 61, label: 'Campamento' });
	assert.equal(out[2], true, '/way reset quita la flecha');
	assert.deepEqual(out[3], { x: 25, y: 75, label: 'Instructor', valid: true }, 'otro addon pone un punto como con TomTom');
	assert.equal(out[4], true);
});

test('TomTom: si el jugador apaga la opción, no hay TomTom falso ni /way (se respeta su elección)', () => {
	const out = runAddon({
		stubs: ['stub_nav.lua'],
		before: WORLD,
		addons: [{ name: 'Polestar', files: ['Core/Init.lua', 'Nav/Nav.xml'] }],
		saved: { Polestar: 'PolestarDB = { schema = 1, settings = { nav = { answerTomTom = false } } }' },
		login: true,
		script: 'emit({ tomtom = TomTom == nil, way = SLASH_POLESTARWAY1 == nil })',
	}).emitted;
	assert.deepEqual(out[0], { tomtom: true, way: true });
});

// Objetos de prueba en el formato de ItemDB (como gear.rs).
const ITEMS = `{
	[9001] = "1 20 15 2 4 3 str5 sta3 armor150",
	[9002] = "1 25 20 2 4 3 str10 sta4 armor170",
	[9004] = "1 20 15 2 4 1 int10 spi5 armor30",
}`;

function gear(script, cls = ['WARRIOR', 'Warrior', 1]) {
	return runAddon({
		stubs: ['stub_world.lua', 'stub_gear.lua'],
		before: `w = stub.world; g = stub.gear\nw.class, w.className, w.classID, w.level = "${cls[0]}", "${cls[1]}", ${cls[2]}, 30\nw.race, w.raceName, w.raceID, w.faction = "Tauren", "Tauren", 6, "Horde"`,
		addons: [{ name: 'Polestar', files: ['Core/Core.xml', 'Gear/Gear.xml'] }],
		login: true,
		script: `G = Polestar.Gear\nPolestar.ItemDB.Register({ schema = 1, build = "test" }, ${ITEMS})\n${script}`,
	}).emitted;
}

test('Pawn: el cuadro del objeto dice si es mejora y cuánto, encendido por defecto', () => {
	const out = gear(`
		emit({ enabled = Polestar.Get("gear.enabled"), tooltip = Polestar.Get("gear.tooltip") })
		g.equip(1, "item:9001")
		emit(g.showTooltip(GameTooltip, "item:9002"))
		emit(g.showTooltip(GameTooltip, "item:9004"))
	`);
	assert.deepEqual(out[0], { enabled: true, tooltip: true });
	assert.match(out[1][0], /^Polestar \| \+\d+% upgrade · Head$/, 'mejora con porcentaje y ranura');
	assert.match(out[2][0], /^Polestar \| -\d+% downgrade · Head$/, 'peor: también lo dice');
});

test('Pawn: para un druida (Hope) el mismo cuadro funciona', () => {
	const out = gear(`
		g.equip(1, "item:9001")
		emit(g.showTooltip(GameTooltip, "item:9004"))
	`, ['DRUID', 'Druid', 11]);
	assert.match(out[0][0], /^Polestar \| [+-]\d+% (upgrade|downgrade) · Head$/);
});

test('GearQuestForever: la recompensa recomendada sale marcada por defecto al entregar', () => {
	const out = runAddon({
		stubs: ['stub_qol.lua'],
		addons: [{ name: 'Polestar', files: ['Core/Init.lua', 'Core/Compat.lua', 'Theme/Theme.xml', 'QoL/QoL.xml'] }],
		login: true,
		script: `
		local q, QoL = stub.qol, Polestar.QoL
		emit({ highlight = Polestar.Get("qol.rewardHighlight"), autopick = Polestar.Get("qol.rewardAutoPick") })
		q.items[11] = { name = "Capa", price = 120 }
		q.items[13] = { name = "Botas", price = 90 }
		q.choices = { { id = 11 }, { id = 13 } }
		Polestar.Gear = {
			IsEnabled = function() return true end,
			CompareToEquipped = function() return { usable = true } end,
			IsUpgrade = function(link) if link:find("item:13") then return true, 8 end return false, -1 end,
		}
		q.questComplete()
		stub.runTimers()
		local picks = 0
		for _, c in ipairs(q.calls) do if c[1] == "GetQuestReward" then picks = picks + 1 end end
		emit({ best = QoL.Rewards.best, reason = QoL.Rewards.reason, picks = picks })
	`,
	}).emitted;
	assert.deepEqual(out[0], { highlight: true, autopick: false }, 'marca sí; elegir por ti, no');
	assert.deepEqual(out[1], { best: 2, reason: 'upgrade', picks: 0 }, 'marca las botas (la mejora) y no entrega sola');
});

test('Parches P1/P2: los errores van al repositorio de Mamba y no hay aviso de "actualiza Polestar"', () => {
	// El simulador no lee el .toc: le damos el campo X-Mamba como lo leería el juego
	// (que el .toc lo trae lo prueba el test siguiente).
	const xmamba = fs.readFileSync(path.join(ADDON, 'Polestar', 'Polestar.toc'), 'utf8').match(/^## X-Mamba: ([^\r\n]+)/m)[1];
	const out = runAddon({
		stubs: ['stub_world.lua'],
		before: `stub.addonMeta.Polestar = { ["X-Mamba"] = ${JSON.stringify(xmamba)}, Version = "0.4.0" }`,
		addons: [{ name: 'Polestar', files: ['Core/Core.xml'] }],
		login: true,
		script: `
		emit({ issue = Polestar.IssueURL, discord = Polestar.DiscordURL, mamba = Polestar.mamba ~= nil })
		local U = Polestar.Update
		emit({ counts = U.NotePeer("0.4.1"), notice = U.Notice() == nil, release = U.ReleaseURL() })
	`,
	}).emitted;
	assert.match(out[0].issue, /^https:\/\/github\.com\/cstamigo-droid\/Mamba\/issues\/new$/);
	assert.match(out[0].discord, /cstamigo-droid\/Mamba/);
	assert.equal(out[0].mamba, true, 'el .toc lleva X-Mamba');
	assert.deepEqual(out[1], { counts: false, notice: true, release: 'https://github.com/cstamigo-droid/Mamba/releases/latest' });
});

// Como party.rs (party_a_member_s_version_is_said_once...): Ben, en el grupo, trae un Polestar más nuevo.
function grupo(mamba) {
	const xmamba = mamba ? `stub.addonMeta.Polestar = { ["X-Mamba"] = "fork", Version = "0.3.7" }` : '';
	return runAddon({
		stubs: ['stub_world.lua', 'stub_party.lua'],
		before: xmamba,
		saved: { Polestar: 'PolestarDB = { schema = 1, settings = { party = { share = true, show = true } } }' },
		addons: [{ name: 'Polestar', files: ['Core/Core.xml', 'Quests/Party.lua'] }],
		login: true,
		script: `
		local p = stub.party
		local E = Polestar.Engine
		E.GetGuide = function() return { id = "test/g", pack = "test" } end
		E.GetLiveStep = function() return 5 end
		Polestar.Guides.Pack = function(id) if id == "test" then return { id = "test", title = "Test", version = "3" } end end
		E.GetStepView = function(i) if i == 5 then return { goals = {} } end end
		stub.messages = {}
		Polestar.version = "0.3.7"
		p.join("Ben")
		p.receive("Ben-TestRealm", "1Y|0.3.8")
		local out = {}
		for _, m in ipairs(stub.messages) do if m:find("Ben is on", 1, true) then out[#out + 1] = m:gsub("^.-: ", "") end end
		emit(out)
	`,
	}).emitted;
}

// P15 (19-11): con Mamba el prefijo es "Mamba": un Polestar oficial del grupo no se oye y no hay ningún aviso de
// versión (los compañeros con el oficial 0.4.1.1 recibían avisos por Mamba, y al revés). Sin Mamba, los de siempre.
test('P15 en el grupo: con Mamba, cero avisos de los Polestar oficiales; sin Mamba, los avisos de siempre', () => {
	assert.deepEqual(grupo(false)[0], ['Ben is on Polestar 0.3.8: your guides can differ. A newer version is out.'], 'sin Mamba: Polestar tal cual');
	// el simulado tiene que haber corrido y emitido su lista (vacía): sin emitir, la prueba no probaba nada (revisor t6)
	const emitido = grupo(true);
	assert.equal(emitido.length, 1, 'con Mamba: el simulado corrió y emitió su lista');
	assert.ok(emitido[0] && typeof emitido[0] === 'object', 'con Mamba: lo emitido es la lista de avisos');
	assert.equal(Object.keys(emitido[0]).length, 0, 'con Mamba: ningún aviso de un Polestar oficial');
});

test('Aviso de modificación (GPL-3.0 §5a): cada .toc de Polestar dice "· Mamba" y X-Mamba con fecha', () => {
	for (const dir of fs.readdirSync(ADDON).filter((d) => d.startsWith('Polestar'))) {
		const toc = path.join(ADDON, dir, `${dir}.toc`);
		if (!fs.existsSync(toc)) continue;
		const t = fs.readFileSync(toc, 'utf8');
		// Polestar lleva el título principal "Mamba (guías · Polestar)" (f9d036dcd, TITULO_PRINCIPAL de parches.py);
		// las demás carpetas, "… · Mamba".
		const titulo = dir === 'Polestar' ? /^## Title: Mamba \(guías · Polestar\)\r?$/m : /^## Title: .* · Mamba\r?$/m;
		assert.match(t, titulo, `${dir}: título`);
		assert.match(t, /^## X-Mamba: fork de Polestar, modificado \d{4}-\d{2}-\d{2} /m, `${dir}: aviso`);
	}
});
