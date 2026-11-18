'use strict';
// K100 (MAMBA_ACEPTACION.md): Calabozos › Misiones con el estado real y lo que falta, y «Guíame» al paso pendiente.
// Mamba_Panel/Misiones.lua sobre la tarjeta de Polestar (parche P13 en UI/Dungeons.lua), contra el Polestar real
// con un Codex de prueba (el mismo armado que drop-prerequisite-ui.test.js).
//   LUA=lupa51 node --require ./tools/asistente/lua51/shim.js --test tests/mamba-misiones.test.js

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { runAddon } = require('./helpers/lua');
const { writeCodexPack } = require('./helpers/codex');
const { buildJournal, emitJournal } = require('../tools/lib/codex/journal');
const fixture = require('./fixtures/codex/dungeons.json');

const QUEST = 90044;
const PRE = 90043;

function card({ state, conPanel = true }) {
	const { codex, inputs } = structuredClone(fixture);
	const base = { level: 15, minLevel: 10, faction: null, races: null, classes: null, end: { npc: [5767], object: [] },
		objectives: [], zone: 1413, rewards: [], choices: [], preAny: [] };
	codex.quests[PRE] = { ...base, id: PRE, title: 'Primer paso', start: { npc: [5767], object: [], item: [] }, pre: [] };
	codex.quests[QUEST] = { ...base, id: QUEST, title: 'Segundo paso', start: { npc: [5767], object: [], item: [] }, pre: [PRE] };
	inputs.forever.quests[QUEST] = { area: 718 };
	inputs.forever.quests[PRE] = { area: 718 };
	const journal = buildJournal(inputs, codex);
	const page = journal.dungeons['wailing-caverns'];
	let q = page.quests.find((x) => x.id === QUEST);
	if (!q) {
		q = { id: QUEST, title: 'Segundo paso', level: 15, minLevel: 10,
			start: { kind: 'npc', id: 5767, name: 'Nalpak', map: 1413, x: 46, y: 36, f: 'e' }, chain: [PRE], rewards: {} };
	}
	q.chain = [PRE];
	page.chain = page.chain || {};
	page.chain[PRE] = { id: PRE, title: 'Primer paso', level: 15, start: { kind: 'npc', id: 5767, name: 'Nalpak', map: 1413, x: 46, y: 36, f: 'e' } };
	page.quests = [q];
	const pack = writeCodexPack(codex, { extraFiles: emitJournal(journal) });
	const done = state === 'log' ? `id == ${PRE}` : 'false';
	const onq = state === 'log' ? `id == ${QUEST}` : 'false';
	try {
		return runAddon({
			stubs: ['stub_ui.lua'], before: pack.stubLua,
			addons: [{ name: 'Polestar', files: ['Core/Core.xml', 'Theme/Theme.xml', 'Gear/Gear.xml', 'Lookup/Lookup.xml', 'Dungeons/Dungeons.xml', 'UI/UI.xml'] },
				...(conPanel ? ['Mamba_Panel'] : [])],
			script: `
uistub.install()
stub.login()
uistub.player.level, uistub.player.race, uistub.player.class, uistub.player.faction = 20, 'Tauren', 'DRUID', 'Horde'
Polestar.Compat.IsQuestCompleted = function(id) return ${done} end
Polestar.Compat.IsOnQuest = function(id) return ${onq} end
Polestar.Compat.IsQuestReadyForTurnIn = function() return false end
-- stub_ui pone un Compat falso: los objetivos con la forma del real (Compat.GetQuestObjectives / ObjectiveLabel)
Polestar.Compat.GetQuestObjectives = function(id)
  if id == ${QUEST} then return { { text = "Serpiente de las cavernas: 2/5", finished = false, numFulfilled = 2, numRequired = 5 },
    { text = "Colmillo: 1/1", finished = true, numFulfilled = 1, numRequired = 1 } } end
end
Polestar.Compat.ObjectiveLabel = function(t) return (t:gsub("%s*:%s*%d+%s*/%s*%d+%s*$", "")) end
assert(Polestar.Codex.Load())
local pedido
MambaAPI = MambaAPI or {}
MambaAPI.Llevame = function(d) pedido = d; return true end
local D = Polestar.Dungeons
D.Open('wailing-caverns')
local b
for _, v in ipairs(Polestar.UI.DungeonsSection.blocks) do
  if v:IsShown() and v.psQuest == ${QUEST} then b = v; break end
end
assert(b, 'quest card missing')
local subs = {}
for _, r in ipairs(b.Chains or {}) do if r:IsShown() then subs[#subs + 1] = r.Sub:GetText() end end
local g = rawget(b, "MambaGuiame")
if g and g:IsShown() then g:Click() end
emit({ meta = b.Meta:GetText(), guiame = g and g:IsShown() or false, pedido = pedido, subs = subs })
`,
		}).emitted[0];
	} finally { pack.cleanup(); }
}

test('K100: en el registro dice qué falta, la cadena dice "hecha", y Guíame lleva a la entrada', () => {
	const r = card({ state: 'log' });
	assert.match(r.meta, /Falta: Serpiente de las cavernas 2\/5/, 'el objetivo que falta, con su cuenta');
	assert.doesNotMatch(r.meta, /Colmillo/, 'lo ya hecho no se repite');
	assert.equal(r.guiame, true);
	assert.ok(r.pedido && r.pedido.map, 'Guíame pide la ruta a un punto');
	assert.ok(r.subs.some((s) => /hecha$/.test(s)), `el paso anterior dice "hecha" (${JSON.stringify(r.subs)})`);
});

test('K100: sin tomarla, dice a quién y Guíame lleva al primer paso que falta', () => {
	const r = card({ state: 'open' });
	assert.match(r.meta, /Falta tomarla/, r.meta);
	assert.equal(r.guiame, true);
	assert.ok(r.subs.some((s) => /falta$/.test(s)), `los pasos que faltan lo dicen (${JSON.stringify(r.subs)})`);
});

test('K100 control negativo: sin Mamba_Panel la tarjeta queda como la de Polestar', () => {
	const r = card({ state: 'log', conPanel: false });
	assert.doesNotMatch(r.meta, /Falta/);
	assert.equal(r.guiame, false);
});
