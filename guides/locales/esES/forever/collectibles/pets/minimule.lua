-- Spanish (Spain) (esES): the guide forever/collectibles/pets/minimule (forever/collectibles/pets/minimule.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Guide
	["Minimule"] = "Minimula",

	-- Step 1: Azeroth Commerce Authority
	["Azeroth Commerce Authority"] = "Autoridad Comercial de Azeroth",
	-- {area:1002} Three Corners · {zone:1433} Redridge Mountains · {npc:256390} Marcy Baker
	["The Alliance camp is at {area:1002} in western {zone:1433}. Merchant's Favor comes from Waylaid Crates that mobs drop from level 10: fill one with a bundle it lists and hand it to {npc:256390}, for 5 to 30 Favor a crate. The treat costs 1,500 Favor and, by beta vendor lists, needs Revered with the Azeroth Commerce Authority. Crates pay no standing: that comes from the Craftsman's Writs, 21,000 from Neutral to Revered. The Supply Factions Reputation guide takes you there."] = "El campamento de la Alianza está en {area:1002}, en el oeste de {zone:1433}. El Merchant's Favor viene de las Waylaid Crates que sueltan los enemigos desde el nivel 10: llena una con un paquete de los que enumera y entrégala a {npc:256390}, por 5 a 30 de Favor por caja. La golosina cuesta 1,500 de Favor y, según las listas de vendedores de la beta, requiere ser Reverenciado con la Azeroth Commerce Authority. Las cajas no dan reputación: esa viene de los Craftsman's Writs, 21,000 de Neutral a Reverenciado. La guía Supply Factions Reputation te lleva hasta allí.",
	["1,500 Merchant's Favor"] = "1,500 de Favor del mercader",

	-- Step 2: Durotar Supply and Logistics
	["Durotar Supply and Logistics"] = "Suministros y Logística de Durotar",
	-- {npc:256384} Gishah · {zone:1458} Undercity
	["The Horde camp is just outside the west gate of the Crossroads. Merchant's Favor comes from Waylaid Crates that mobs drop from level 10: fill one with a bundle it lists and hand it to Dokimi, for 5 to 30 Favor a crate. The treat costs 1,500 Favor and, by beta vendor lists, needs Revered with Durotar Supply and Logistics. Crates pay no standing: that comes from the Craftsman's Writs, 21,000 from Neutral to Revered. The Supply Factions Reputation guide takes you there. (Another {npc:256384} stands in the {zone:1458}; this is the one at the camp.)"] = "El campamento de la Horda está justo afuera de la puerta oeste del Cruce. El Favor del mercader sale de los Cajones arrebatados que sueltan los enemigos desde el nivel 10: llena uno con un lote que pide y entrégaselo a Dokimi, por 5 a 30 de Favor por cajón. La golosina cuesta 1.500 de Favor y, según las listas de vendedor de la beta, pide Reverenciado con Suministros y Logística de Durotar. Los cajones no dan reputación: esa sale de los encargos de Artesano, 21.000 de Neutral a Reverenciado. La guía de reputación de las facciones de suministros te lleva hasta ahí. (Hay otro {npc:256384} en {zone:1458}; este es el del campamento.)",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["The Alliance camp is at {area:1002} in western {zone:1433}. Loot supply crates in the world, fill them and hand them in to {npc:214101} for Merchant's Favor (5-20 a crate); the treat costs 1,500."] = "El campamento de la Alianza está en {area:1002}, en el oeste de {zone:1433}. Despoja cajas de suministros por el mundo, llénalas y entrégaselas a {npc:214101} a cambio de Favor del mercader (5-20 por caja); la golosina cuesta 1,500.",
	-- ["The Horde camp is just outside the {area:380}. Loot supply crates in the world, fill them and hand them in at the camp for Merchant's Favor; the treat costs 1,500. (Another {npc:256384} stands in the {zone:1458}; this is the one at the camp.)"] = "El campamento de la Horda está a las afueras de {area:380}. Despoja cajas de suministros por el mundo, llénalas y entrégalas en el campamento a cambio de Favor del mercader; la golosina cuesta 1,500. (Hay otro {npc:256384} en {zone:1458}; este es el del campamento.)",
	-- ["{zone:1411} Supply and Logistics"] = "Suministros y Logística de {zone:1411}",
}
