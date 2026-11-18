-- Spanish (Latin America) (esMX): the guide forever/collectibles/pets/weevil-k-neevil (forever/collectibles/pets/weevil-k-neevil.guide).
-- Written by `forge i18n guides sync esMX`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Latin America) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Latin America) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: My Little Friends
	-- {npc:217412} Amaryllis Webb · {zone:1435} Swamp of Sorrows · {zone:1417} Arathi Highlands · {zone:1443} Desolace
	-- was: ["{npc:217412}, a Forsaken bug collector, keeps her menagerie in western {zone:1435}. She hands you an {item:213565}: open it for the tools that catch the three bugs. The bugs are far apart (northern Stranglethorn, {zone:1417} and {zone:1443}), so do them while you pass. If you lose the kit, she sells another for 50s."] = "{npc:217412}, una coleccionista de bichos Renegada, tiene su colección de animales en el oeste de {zone:1435}. Te da un {item:213565}: ábrelo para obtener las herramientas que atrapan los tres bichos. Los bichos están lejos entre sí (norte de Tuercespina, {zone:1417} y {zone:1443}), así que atrápalos cuando pases por ahí. Si pierdes el kit, te vende otro por 50 p."
	["{npc:217412}, a Forsaken bug collector, keeps her menagerie in western {zone:1435}. She hands you an Entomology Starter Kit: open it for the tools that catch the three bugs. The bugs are far apart (northern Stranglethorn, {zone:1417} and {zone:1443}), so do them while you pass. If you lose the kit, she sells another for 50s."] = "{npc:217412}, una coleccionista de insectos Renegada, tiene su colección de bichos en el oeste de {zone:1435}. Te da un Entomology Starter Kit: ábrelo para obtener las herramientas que atrapan los tres insectos. Los insectos están lejos unos de otros (norte de Stranglethorn, {zone:1417} y {zone:1443}), así que hazlos de paso. Si pierdes el kit, ella vende otro por 50s.",

	-- Step 2: Arbor Tarantula in Stranglethorn Vale
	-- {zone:1434} Stranglethorn Vale
	-- was: ["{npc:217588} in {zone:1434}"] = "{npc:217588} en {zone:1434}"
	["Arbor Tarantula in {zone:1434}"] = "Arbor Tarantula en {zone:1434}",
	["The Arbor Tarantulas sit in northern Stranglethorn. Use the kit's tool on one to catch it."] = "Las tarántulas arbóreas están en el norte de Tuercespina. Usa la herramienta del kit en una para atraparla.",

	-- Step 3: Hay Weevil in Arathi Highlands
	-- {zone:1417} Arathi Highlands
	-- was: ["{npc:217589} in {zone:1417}"] = "{npc:217589} en {zone:1417}"
	["Hay Weevil in {zone:1417}"] = "Hay Weevil en {zone:1417}",
	-- {zone:1417} Arathi Highlands
	["The Hay Weevils crawl in the north-west of {zone:1417}. Use the kit's tool on one."] = "Los gorgojos del heno se arrastran por el noroeste de {zone:1417}. Usa la herramienta del kit en uno.",

	-- Step 4: Flesh Picker in Desolace
	-- {zone:1443} Desolace
	-- was: ["{npc:217590} in {zone:1443}"] = "{npc:217590} en {zone:1443}"
	["Flesh Picker in {zone:1443}"] = "Flesh Picker en {zone:1443}",
	-- {area:596} Kodo Graveyard · {zone:1443} Desolace
	["The Flesh Pickers feed in the {area:596} in the middle of southern {zone:1443}. Use the kit's tool on one."] = "Los picacarnes se alimentan en {area:596}, en medio del sur de {zone:1443}. Usa la herramienta del kit en uno.",

	-- Step 5: Back to Amaryllis Webb
	-- {npc:217412} Amaryllis Webb
	["Back to {npc:217412}"] = "De vuelta con {npc:217412}",
	-- {npc:217412} Amaryllis Webb · {item:280456} Weevil K. Neevil
	["Hand {npc:217412} the three specimens: she gives you {item:280456} and 35s."] = "Dale los tres especímenes a {npc:217412}: te da {item:280456} y 35s.",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["{npc:217412} gives you an Entomology Starter Kit: use its items to catch an {npc:217588}, a Hay Weevil Specimen and a {npc:217590}. This quest is named as the weevil's source but gives only money as its reward; the pet may come from the {npc:217589} you catch. If you lose the kit, she sells another."] = "{npc:217412} te da un kit de entomología: usa sus objetos para atrapar un {npc:217588}, un espécimen de gorgojo y un {npc:217590}. Esta misión figura como origen del gorgojo, pero solo da dinero como recompensa; la mascota puede salir del {npc:217589} que atrapes. Si pierdes el kit, ella vende otro.",
	-- ["{npc:217412}, a Forsaken bug collector, keeps her menagerie in western {zone:1435}. She hands you an Entomology Starter Kit: open it for the tools that catch the three bugs. The bugs are far apart (northern Stranglethorn, {zone:1417} and {zone:1443}), so do them while you pass. If you lose the kit, she sells another for 50s."] = "{npc:217412}, una coleccionista de bichos Renegada, tiene su colección en el oeste de {zone:1435}. Te da un kit de entomología para principiantes: ábrelo para sacar las herramientas que atrapan los tres bichos. Los bichos están lejos entre sí (norte de Tuercespina, {zone:1417} y {zone:1443}), así que atrápalos cuando pases. Si pierdes el kit, vende otro por 50s.",
	-- ["{npc:217412}, a Forsaken bug collector, keeps her menagerie in western {zone:1435}. She hands you an {item:213565}: open it for the tools that catch the three bugs. The bugs are far apart (northern Stranglethorn, {zone:1417} and {zone:1443}), so do them while you pass. If you lose the kit, she sells another for 50s."] = "{npc:217412}, una coleccionista de bichos Renegada, tiene su colección de animales en el oeste de {zone:1435}. Te da un {item:213565}: ábrelo para obtener las herramientas que atrapan los tres bichos. Los bichos están lejos entre sí (norte de Tuercespina, {zone:1417} y {zone:1443}), así que atrápalos cuando pases por ahí. Si pierdes el kit, te vende otro por 50 p.",
	-- ["{npc:217588} in {zone:1434}"] = "{npc:217588} en {zone:1434}",
	-- ["{npc:217589} in {zone:1417}"] = "{npc:217589} en {zone:1417}",
	-- ["{npc:217590} in {zone:1443}"] = "{npc:217590} en {zone:1443}",
}
