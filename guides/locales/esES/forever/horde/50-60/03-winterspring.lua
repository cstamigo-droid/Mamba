-- Spanish (Spain) (esES): the guide forever/horde/50-60/03-winterspring (forever/horde/50-60/03-winterspring.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: To Everlook
	-- {area:2255} Everlook
	["To {area:2255}"] = "A {area:2255}",

	-- Step 2: Fly to Everlook
	-- {area:2255} Everlook
	["Fly to {area:2255}"] = "Vuela a {area:2255}",
	-- {area:1997} Bloodvenom Post
	["{area:1997} flight master"] = "Maestro de vuelo de {area:1997}",

	-- Step 3: Everlook
	-- {area:2255} Everlook
	["{area:2255} is the goblin town on the east side of the valley, past the owlbeast hills."] = "{area:2255} es el pueblo goblin del lado este del valle, pasadas las colinas de los lechúcicos.",
	-- {npc:11118} Innkeeper Vizzie
	-- was: ["{npc:11118}: the last guide binds here, so this usually ticks at once"] = "{npc:11118}: la guía anterior te vincula aquí, así que esto suele marcarse al instante"
	["{npc:11118}: the last guide binds here, so this usually ticks at once"] = "{npc:11118}: la guía anterior te vincula aquí, así que esto suele marcarse de inmediato",
	-- {npc:10431} Gregor Greystone
	["{npc:10431}, inside"] = "{npc:10431}, adentro",
	-- was: ["Gregor's and Harlo's quests lead to other zones: keep them."] = "Las misiones de Gregor y Harlo llevan a otras zonas: guárdalas."
	["Gregor's and Harlo's quests lead to other zones: keep them."] = "Las misiones de Gregor y Harlo llevan a otras zonas: guárdalas.",

	-- Step 4: Umi Rumplesnicker
	-- {area:976} Gadgetzan
	-- was: ["Umi's third prank targets goblins in {area:976} and Un'Goro: keep it for later."] = "La tercera broma de Umi va contra goblins de {area:976} y Un'Goro: guárdala para más tarde."
	["Umi's third prank targets goblins in {area:976} and Un'Goro: keep it for later."] = "La tercera travesura de Umi apunta a goblins en {area:976} y Un'Goro: guárdala para después.",

	-- Step 5: Raging Owlbeasts
	-- plural, as words: Raging Owlbeasts = {npc:7451} Raging Owlbeast
	["Raging Owlbeasts"] = "Lechubestias enfurecidas",
	-- {area:2251} Lake Kel'Theril · {area:2246} Frostfire Hot Springs · {area:2255} Everlook
	-- plural, as words: Raging Owlbeasts = {npc:7451} Raging Owlbeast
	["Raging Owlbeasts roam the hills north of {area:2251}, by the road between {area:2246} and {area:2255}."] = "Las lechubestias furiosas recorren las colinas al norte de {area:2251}, junto al camino entre {area:2246} y {area:2255}.",

	-- Step 6: Donova Snowden
	-- {npc:9298} Donova Snowden · {area:2246} Frostfire Hot Springs
	-- was: ["Ride south from the tunnel: {npc:9298} camps among the steaming pools of {area:2246}, in the west of the valley."] = "Cabalga al sur desde el túnel: {npc:9298} acampa entre las pozas humeantes de {area:2246}, al oeste del valle."
	["{npc:9298} camps among the steaming pools of {area:2246}, in the west of the valley."] = "{npc:9298} acampa entre las pozas humeantes de {area:2246}, en el oeste del valle.",
	-- {quest:3909} The Videre Elixir · {npc:7775} Gregan Brewspewer · {area:357} Feralas
	-- was: ["{quest:3909} comes from {npc:7775} in {zone:1444}, later in this guide."] = "{quest:3909} la da {npc:7775} en {zone:1444}, más adelante en esta guía."
	["{quest:3909} comes from {npc:7775} in {area:357}, later in this guide."] = "{quest:3909} viene de {npc:7775} en {area:357}, más adelante en esta guía.",

	-- Step 7: Frostfire Winterfall camps
	-- was: ["Frostfire Winterfall camps"] = "Campamentos Nevada de los Baños de Fuego de Escarcha"
	["Frostfire Winterfall camps"] = "Campamentos Nevada de los Baños de Fuego de Escarcha",
	-- {item:14047} Runecloth
	-- plural, as words: Ragged Owlbeasts = {npc:7450} Ragged Owlbeast
	-- was: ["Pathfinders, Den Watchers and Totemics share the furbolg camps around the hot springs; Ragged Owlbeasts roam the slopes between them. Kill Totemics first. Save every {item:14047} you loot for Meilosh."] = "Abrecaminos, vigilantes del cubil y totémicos comparten los campamentos fúrbolg alrededor de las fuentes termales; las Lechubestias andrajosas deambulan por las laderas entre ellos. Mata primero a los totémicos. Guarda todo el {item:14047} que consigas para Meilosh."
	["Pathfinders, Den Watchers and Totemics share the furbolg camps around the hot springs; Ragged Owlbeasts roam the slopes between them. Kill Totemics first. Save every {item:14047} you loot for Meilosh."] = "Los Buscacaminos, Vigilantes de guarida y Totémicos comparten los campamentos de fúrbolgs alrededor de las aguas termales; los Búhobestias andrajosos recorren las laderas entre ellos. Mata primero a los Totémicos. Guarda todo {item:14047} que obtengas para Meilosh.",
	-- {item:12771} Empty Firewater Flask
	["{item:12771}: about one Winterfall furbolg in ten carries one; keep killing them until it drops"] = "{item:12771}: más o menos uno de cada diez fúrbolgs Nevada lleva uno; sigue matándolos hasta que caiga",

	-- Step 9: Donova Snowden
	-- {quest:5084} Falling to Corruption · {object:176091} Deadwood Cauldron · {zone:1448} Felwood
	["{quest:5084} is turned in at the {object:176091} in {zone:1448}, on a later trip."] = "{quest:5084} se entrega en el {object:176091} de {zone:1448}, en un viaje posterior.",

	-- Step 10: Darkwhisper Gorge
	-- {area:2249} Frostwhisper Gorge · {area:2256} Darkwhisper Gorge
	-- was: ["Ride east, then south down {area:2249}. The Frostmaul giants there are elite level 59: keep to the middle and keep moving. The strange source is at the mouth of {area:2256}, at the south end."] = "Cabalga al este y luego al sur bajando por {area:2249}. Los Gigantes Machacahielo de allí son élite de nivel 59: ve por el centro y no te detengas. La fuente extraña está en la boca de {area:2256}, en el extremo sur."
	["Ride east, then south down {area:2249}. The Frostmaul giants there are elite level 59: keep to the middle and keep moving. The strange source is at the mouth of {area:2256}, at the south end."] = "Cabalga al este y luego al sur por {area:2249}. Los gigantes Frostmaul de ahí son élite de nivel 59: quédate en el centro y sigue moviéndote. La fuente extraña está en la entrada de {area:2256}, en el extremo sur.",

	-- Step 11: Donova Snowden
	-- {area:2246} Frostfire Hot Springs
	-- was: ["Ride back west to {area:2246}."] = "Vuelve al oeste hasta {area:2246}."
	["Ride back west to {area:2246}."] = "Regresa cabalgando al oeste a {area:2246}.",

	-- Step 12: Into Felwood
	-- {zone:1448} Felwood
	["Into {zone:1448}"] = "Entra a {zone:1448}",

	-- Step 13: To Jessir Moonbow
	-- {npc:11019} Jessir Moonbow
	["To {npc:11019}"] = "A {npc:11019}",

	-- Step 15: To Splintertree Post
	-- {area:431} Splintertree Post
	["To {area:431}"] = "Hacia {area:431}",

	-- Step 16: Fly to Camp Mojache
	-- {area:1099} Camp Mojache
	["Fly to {area:1099}"] = "Vuela a {area:1099}",
	-- {area:431} Splintertree Post
	["{area:431} flight master"] = "Maestro de vuelo de {area:431}",

	-- Step 18: The Videre Elixir
	-- {area:976} Gadgetzan
	-- was: ["Back south to {npc:7775}. Keep the elixir and don't drink it yet: it kills you, and that is how you meet Gaeriyan by {area:976} later."] = "Vuelve al sur con {npc:7775}. Guarda el elixir y no lo bebas todavía: te mata, y así es como conocerás más tarde a Gaeriyan junto a {area:976}."
	["Back south to Gregan. Keep the elixir and don't drink it yet: it kills you, and that is how you meet Gaeriyan by {area:976} later."] = "De vuelta al sur con Gregan. Guarda el elixir y no lo bebas todavía: te mata, y así es como conocerás a Gaeriyan junto a {area:976} más adelante.",
	-- {item:11243} Videre Elixir
	["{item:11243}, Gregan's reward"] = "{item:11243}, recompensa de Gregan",

	-- Step 19: To Camp Mojache
	-- {area:1099} Camp Mojache
	["To {area:1099}"] = "Hacia {area:1099}",

	-- Step 20: Talo Thornhoof
	-- {area:1099} Camp Mojache
	-- was: ["Back at {area:1099}."] = "De vuelta en {area:1099}."
	["Back at {area:1099}."] = "De vuelta en {area:1099}.",

	-- Step 21: Fly to Thunder Bluff
	-- {area:1638} Thunder Bluff
	["Fly to {area:1638}"] = "Vuela a {area:1638}",
	-- {area:1099} Camp Mojache
	["{area:1099} flight master"] = "Maestro de vuelo de {area:1099}",

	-- Step 22: Bluff Runner Windstrider
	-- {area:1641} Hunter Rise
	["He stands on {area:1641}. Each donation takes sixty Wool, Silk or Mageweave from your bags: hand in what you carry, skip the rest."] = "Está en {area:1641}. Cada donación toma sesenta unidades de tela de lana, de seda o de mago de tus bolsas: entrega lo que lleves y omite el resto.",

	-- Step 23: Elder Rise
	-- {npc:3033} Turak Runetotem · {area:1639} Elder Rise · {npc:246344} Alodan the Hopeful
	["{npc:3033} on {area:1639}; {npc:246344}"] = "{npc:3033} en {area:1639}; {npc:246344}",
	-- {quest:1123} Rabine Saturna · {zone:1450} Moonglade
	["{quest:1123} waits in {zone:1450}: keep it for later."] = "{quest:1123} espera en {zone:1450}: guárdala para más tarde.",

	-- Step 24: Bashana Runetotem
	-- {npc:9087} Bashana Runetotem · {item:11040} Morrowgrain · {item:11018} Un'Goro Soil · {quest:3782} Morrowgrain Research · {item:11020} Evergreen Pouch
	["{npc:9087} buys {item:11040} grown from your {item:11018}. {quest:3782} wants ten, and the {item:11020} gives one try every ten minutes: take it only if you already have the grain."] = "{npc:9087} compra {item:11040} cultivado a partir de tu {item:11018}. {quest:3782} pide diez, y el {item:11020} da un intento cada diez minutos: tómala solo si ya tienes el grano.",

	-- Step 26: Fly to Orgrimmar
	-- {area:1637} Orgrimmar
	["Fly to {area:1637}"] = "Vuela a {area:1637}",
	-- {zone:1456} Thunder Bluff
	["{zone:1456} flight master"] = "Maestro de vuelo de {zone:1456}",

	-- Step 27: Vehena
	-- {object:172961} Valley of Spirits
	-- was: ["In the {object:172961}."] = "En {object:172961}."
	["In the {object:172961}."] = "En {object:172961}.",

	-- Step 28: Rashona Straglash
	-- {object:172958} Valley of Honor
	["In the {object:172958}."] = "En {object:172958}.",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["Any Winterfall furbolg can carry the beads; the camps just south of {npc:11556} are the closest."] = "Cualquier fúrbolg Nevada puede llevar las cuentas; los campamentos justo al sur de {npc:11556} son los más cercanos.",
	-- ["Back at {area:1099}."] = "De vuelta en {area:1099}.",
	-- ["Back south to {npc:7775}. Keep the elixir and don't drink it yet: it kills you, and that is how you meet Gaeriyan by {area:976} later."] = "Vuelve al sur con {npc:7775}. Guarda el elixir y no lo bebas todavía: te mata, y así es como conocerás más tarde a Gaeriyan junto a {area:976}.",
	-- ["Back to {area:2255}"] = "De vuelta a {area:2255}",
	-- ["Below ground"] = "Bajo tierra",
	-- ["Chillwind chimaeras"] = "Quimeras venfresco",
	-- ["From Krakle in Un'Goro"] = "De Krakle en Un'Goro",
	-- ["Frostfire Winterfall camp"] = "Campamento Nevada de los Baños de Fuego de Escarcha",
	-- ["Frostfire Winterfall camps"] = "Campamentos Nevada de los Baños de Fuego de Escarcha",
	-- ["Gregor's and Harlo's quests lead to other zones: keep them."] = "Las misiones de Gregor y Harlo llevan a otras zonas: guárdalas.",
	-- ["Gregor's quests lead to other zones: keep them."] = "Las misiones de Gregor llevan a otras zonas: guárdalas.",
	-- ["Grind to 55"] = "Sube hasta el nivel 55",
	-- ["He stands on {area:1641}. Each donation wants cloth from your bags; hand them in when you have it, later in the route."] = "Está en {area:1641}. Cada donación pide tela de tus bolsas; entrégalas cuando la tengas, más adelante en la ruta.",
	-- ["Ice Thistle yetis"] = "Yetis Cardo Nevado",
	-- ["In the {object:172961}."] = "En {object:172961}.",
	-- ["Linken's letter"] = "La carta de Linken",
	-- ["Matriarchs and Patriarchs hit hard: pull them one at a time."] = "Las matriarcas y patriarcas pegan fuerte: atráelos de uno en uno.",
	-- ["Pathfinders, Den Watchers and Totemics share the furbolg camps around the hot springs; Ragged Owlbeasts roam the slopes between them. Kill Totemics first. Save every {item:14047} you loot for Meilosh."] = "Abrecaminos, vigilantes del cubil y totémicos comparten los campamentos fúrbolg alrededor de las fuentes termales; las Lechubestias andrajosas deambulan por las laderas entre ellos. Mata primero a los totémicos. Guarda todo el {item:14047} que consigas para Meilosh.",
	-- ["Pathfinders, Den Watchers and Totemics share the furbolg camps around the hot springs; Ragged Owlbeasts roam the slopes between them. Kill Totemics first. Save every {item:14047} you loot for Meilosh.\nCareful: the Den Watchers reach 56: pull one at a time and keep clear of the camps' totems."] = "Abrecaminos, vigías del cubil y totémicos comparten los campamentos fúrbolg alrededor de las fuentes termales; las Lechubestias pulgosas deambulan por las laderas entre ellos. Mata primero a los totémicos. Guarda todo el {item:14047} que consigas para Meilosh.\nCuidado: los vigías del cubil llegan al nivel 56: atráelos de uno en uno y aléjate de los tótems de los campamentos.",
	-- ["Pristine Yeti Horns"] = "Cuernos de yeti prístinos",
	-- ["Raging Owlbeasts roam the hills north of {area:2251}, by the road between {area:2246} and {area:2255}. Careful: the biggest are level 56: pull them one at a time."] = "Las Lechubestias enfurecidas deambulan por las colinas al norte de {area:2251}, junto al camino entre {area:2246} y {area:2255}. Cuidado: las más grandes son de nivel 56: atráelas de una en una.",
	-- ["Ride back west to {area:2246}."] = "Vuelve al oeste hasta {area:2246}.",
	-- ["Ride east, then south down {area:2249}. The Frostmaul giants there are elite level 59: keep to the middle and keep moving. The strange source is at the mouth of {area:2256}, at the south end."] = "Cabalga al este y luego al sur bajando por {area:2249}. Los Gigantes Machacahielo de allí son élite de nivel 59: ve por el centro y no te detengas. La fuente extraña está en la boca de {area:2256}, en el extremo sur.",
	-- ["Ride south from the tunnel: {npc:9298} camps among the steaming pools of {area:2246}, in the west of the valley."] = "Cabalga al sur desde el túnel: {npc:9298} acampa entre las pozas humeantes de {area:2246}, al oeste del valle.",
	-- ["Ride west along the road past {area:2251}; Raging Owlbeasts roam the hills north of it."] = "Cabalga al oeste por el camino pasando {area:2251}; las Lechubestias enfurecidas deambulan por las colinas al norte.",
	-- ["The Matriarchs and Patriarchs that carry Umi's horns are 56-58: leave them for that later stop."] = "Las matriarcas y patriarcas que llevan los cuernos de Umi son de nivel 56-58: déjalos para esa parada posterior.",
	-- ["The chimaeras roam the snowfields south and west of {area:2255}. Stay clear of {area:2245}'s cave: its blue dragonkin are elite."] = "Las quimeras deambulan por los campos nevados al sur y al oeste de {area:2255}. Aléjate de la cueva de {area:2245}: sus dragonantes azules son élite.",
	-- ["The furbolg village fills the valley north-east of {area:2255}. Kill Shamans first; they heal. {npc:10738} in the cave at the back is elite: stay out."] = "El poblado fúrbolg llena el valle al noreste de {area:2255}. Mata primero a los chamanes; curan. {npc:10738}, en la cueva del fondo, es élite: no entres.",
	-- ["The yeti hills start just south-east of {area:2255}. Every yeti drops fur: work the Ice Thistle Yetis (55-56) and leave the Matriarchs and Patriarchs (56-58), whose horns come on a later visit."] = "Las colinas de los yetis empiezan justo al sureste de {area:2255}. Todos los yetis sueltan pelaje: céntrate en los Yetis Cardo Nevado (55-56) y deja las matriarcas y patriarcas (56-58), cuyos cuernos son para una visita posterior.",
	-- ["The yeti hills start just south-east of {area:2255}. Every yeti drops fur; only Matriarchs and Patriarchs drop horns, so keep those for after the turn-in."] = "Las colinas de los yetis empiezan justo al sureste de {area:2255}. Todos los yetis sueltan pelaje; solo las matriarcas y patriarcas sueltan cuernos, así que déjalos para después de la entrega.",
	-- ["The {item:11242} grows inside a ruined building north of {npc:7775}'s camp, east of the harpies' {area:1114}: climb in through the broken part of its wall."] = "La {item:11242} crece dentro de un edificio en ruinas al norte del campamento de {npc:7775}, al este de {area:1114} de las arpías: entra por la parte rota de su muro.",
	-- ["Top up here to level 55.04 before the hand-ins at {area:2255}: they take you to level 56. The Ice Thistle Yetis (55-56) are the lowest here; the Matriarchs and Patriarchs (56-58) hit harder. Or, with a group, run the {area:1584} dungeon or the {area:1583} dungeon (Lower) instead."] = "Sube aquí hasta el nivel 55.04 antes de las entregas en {area:2255}: te llevan al nivel 56. Los yetis Cardo Nevado (55-56) son los de menor nivel aquí; las matriarcas y patriarcas (56-58) pegan más fuerte. O, con un grupo, haz en su lugar la mazmorra {area:1584} o la mazmorra {area:1583} (inferior).",
	-- ["Umi's third prank targets goblins in {area:976} and Un'Goro: keep it for later."] = "La tercera broma de Umi va contra goblins de {area:976} y Un'Goro: guárdala para más tarde.",
	-- ["Umi: keep it, the Pristine Yeti Horns come on the {zone:1423} guide's {area:2255} stop at about 57"] = "Umi: guárdala, los Cuernos de yeti prístinos se consiguen en la parada de {area:2255} de la Guía de {zone:1423}, hacia el nivel 57",
	-- ["grind on {npc:7440} at {area:2244}, {zone:1452}"] = "sube de nivel con {npc:7440} en {area:2244}, {zone:1452}",
	-- ["{area:2408} flight master"] = "Maestro de vuelo de {area:2408}",
	-- ["{item:11243}, {npc:7775}'s reward"] = "{item:11243}, la recompensa de {npc:7775}",
	-- ["{item:12771}, a rare drop from the Winterfall furbolgs"] = "{item:12771}, botín raro de los fúrbolgs Nevada",
	-- ["{npc:10307}, beside him"] = "{npc:10307}, a su lado",
	-- ["{npc:11118}: the last guide binds here, so this usually ticks at once"] = "{npc:11118}: la guía anterior te vincula aquí, así que esto suele marcarse al instante",
	-- ["{npc:11556} stands right at the {zone:1452} exit of {area:1769}'s tunnel, where you come out."] = "{npc:11556} está justo en la salida a {zone:1452} del túnel de {area:1769}, por donde sales.",
	-- ["{npc:7775}, a dwarf, camps in the {area:1137} north-west of {area:1099}. He brews the {item:11243} only from an {item:11242} you bring him."] = "{npc:7775}, un enano, acampa en {area:1137}, al noroeste de {area:1099}. Solo prepara el {item:11243} a partir de una {item:11242} que le lleves.",
	-- ["{npc:7775}, a dwarf, camps in the {area:1137} north-west of {area:1099}; he has the elixir."] = "{npc:7775}, un enano, acampa en {area:1137}, al noroeste de {area:1099}; tiene el elixir.",
	-- ["{npc:9087} buys {item:11040} grown from your {quest:3761}."] = "{npc:9087} compra {item:11040} cultivado con tu {quest:3761}.",
	-- ["{quest:3909} comes from {npc:7775} in {zone:1444}, later in this guide."] = "{quest:3909} la da {npc:7775} en {zone:1444}, más adelante en esta guía.",
	-- ["{quest:8471}, a rare drop from the Winterfall furbolgs"] = "{quest:8471}, botín raro de los fúrbolgs Nevada",
}
