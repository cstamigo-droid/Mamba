-- Spanish (Spain) (esES): the guide forever/horde/40-50/01b-riverglades (forever/horde/40-50/01b-riverglades.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Guide
	-- {area:16743} Rog'mar
	["About 70 quests in Forever's new zone, from the fort of {area:16743}."] = "Unas 70 misiones en la nueva zona de Forever, desde el fuerte de {area:16743}.",

	-- Step 1: Fly to Kargath
	-- {area:340} Kargath
	["Fly to {area:340}"] = "Vuela a {area:340}",
	-- {zone:2548} Riverglades · {area:3} Badlands · {area:657} Harborage · {area:75} Stonard · {area:340} Kargath
	["The {zone:2548} lie south of the {area:3}. Ride east from the {area:657} to {area:75} and fly to {area:340}: the way down into the zone starts there."] = "{zone:2548} están al sur de {area:3}. Ve al este desde {area:657} hasta {area:75} y vuela a {area:340}: el camino de bajada a la zona empieza allí.",
	-- {area:75} Stonard
	["{area:75} flight master"] = "Maestro de vuelo de {area:75}",

	-- Step 2: Into the Riverglades
	-- {area:16591} Riverglades
	["Into the {area:16591}"] = "Hacia {area:16591}",
	-- {area:16591} Riverglades · {area:340} Kargath · {area:3} Badlands · {area:16685} Twilight's Shroud · {area:16743} Rog'mar
	["New in Forever: this guide follows what players did in the {area:16591}. If a step is wrong, tell us on Polestar's Discord or GitHub and name the step.\nFrom {area:340}, ride south-east across the {area:3} to the zone's southern edge: the pass of {area:16685} leads down into the {area:16591}. {area:16743}, the Horde's fort, stands in the middle of the zone, east along the valley."] = "Nuevo en Forever: esta guía sigue lo que hicieron los jugadores en {area:16591}. Si un paso está mal, avísanos en el Discord o GitHub de Polestar e indica el paso.\nDesde {area:340}, cabalga al sureste a través de {area:3} hasta el borde sur de la zona: el paso de {area:16685} baja hasta {area:16591}. {area:16743}, el fuerte de la Horda, está en el centro de la zona, al este siguiendo el valle.",

	-- Step 3: Fly to Freewind Post
	-- {area:484} Freewind Post
	["Fly to {area:484}"] = "Vuela a {area:484}",
	-- {zone:2548} Riverglades · {zone:1446} Tanaris · {area:977} Steamwheedle Port · {area:976} Gadgetzan · {area:16727} Powderfuse Port · {area:484} Freewind Post · {zone:1441} Thousand Needles · {area:439} Shimmering Flats · {area:340} Kargath · {area:3} Badlands · {area:16685} Twilight's Shroud
	["New in Forever: this guide follows what players did in the {zone:2548}. If a step is wrong, tell us on Polestar's Discord or GitHub and name the step.\nThe {zone:2548} lie across the sea from {zone:1446}: a goblin boat sails from {area:977}, north-east of {area:976}, to {area:16727}. Fly to {area:484} in {zone:1441} and head south-east through the {area:439} to {area:976}. (If you already know {area:340} in the {area:3}, the way in through {area:16685} works too.)"] = "Nuevo en Forever: esta guía sigue lo que hicieron los jugadores en {zone:2548}. Si un paso está mal, avísanos en el Discord o GitHub de Polestar e indica el paso.\n{zone:2548} están al otro lado del mar desde {zone:1446}: un barco goblin sale de {area:977}, al noreste de {area:976}, hacia {area:16727}. Vuela a {area:484} en {zone:1441} y ve al sureste por {area:439} hasta {area:976}. (Si ya conoces {area:340} en {area:3}, también puedes entrar por {area:16685}.)",

	-- Step 4: Gadgetzan
	-- {area:976} Gadgetzan
	["Learn {area:976}'s flight path: it saves the ride next time."] = "Aprende la ruta de vuelo de {area:976}: te ahorrará el viaje la próxima vez.",

	-- Step 5: Boat to Powderfuse Port
	-- {area:16727} Powderfuse Port
	["Boat to {area:16727}"] = "Barco a {area:16727}",
	-- {area:977} Steamwheedle Port · {area:976} Gadgetzan · {area:16727} Powderfuse Port
	["{area:977} is on the coast north-east of {area:976}: wait on the pier for the goblin boat to {area:16727}."] = "{area:977} está en la costa al noreste de {area:976}: espera en el muelle el barco goblin a {area:16727}.",

	-- Step 6: Powderfuse Port
	-- was: ["New in Forever: if a step is wrong, tell us on Polestar's Discord or GitHub and name the step.\n{npc:255897} keeps a stall at the west end of the docks. The port's other jobs are for later in this guide: this crate goes to the Horde's fort."] = "Nuevo en Forever: si un paso está mal, avísanos en el Discord o GitHub de Polestar e indica el paso.\n{npc:255897} tiene un puesto en el extremo oeste de los muelles. Los demás encargos del puerto son para más adelante en esta guía: esta caja va al fuerte de la Horda."
	["New in Forever: if a step is wrong, tell us on Polestar's Discord or GitHub and name the step.\nFriz Frazzlespark keeps a stall at the west end of the docks. The port's other jobs are for later in this guide: this crate goes to the Horde's fort."] = "Nuevo en Forever: si un paso está mal, avísanos en el Discord o GitHub de Polestar e indica el paso.\\nFriz Frazzlespark tiene un puesto en el extremo oeste de los muelles. Los demás trabajos del puerto son para más adelante en esta guía: esta caja va al fuerte de la Horda.",
	-- {quest:95062} Frazzlespark's Crate · {area:16743} Rog'mar
	-- was: ["{quest:95062}: for {npc:256418} in {area:16743}"] = "{quest:95062}: para {npc:256418} en {area:16743}"
	["{quest:95062}: for Krom'rosh in {area:16743}"] = "{quest:95062}: para Krom'rosh en {area:16743}",

	-- Step 7: Rog'mar
	-- {area:16743} Rog'mar
	-- was: ["West to {area:16743}, the Horde's fort in the middle of the zone. {npc:258031} stands on its east side, {npc:256657} and {npc:256418} in the middle with {npc:255993}, the wind rider master; {npc:256675} and {npc:263190} on the west side."] = "Ve al oeste hasta {area:16743}, el fuerte de la Horda en el centro de la zona. {npc:258031} está en el lado este, {npc:256657} y {npc:256418} en el centro con {npc:255993}, la maestra de jinetes del viento; {npc:256675} y {npc:263190} en el lado oeste."
	["West to {area:16743}, the Horde's fort in the middle of the zone. Neza Bloodsnout stands on its east side, Kreza Darkthorn and Krom'rosh in the middle with Grakna, the wind rider master; Innkeeper Toka and Tan'jani on the west side."] = "Al oeste, a {area:16743}, el fuerte de la Horda en medio de la zona. Neza Bloodsnout está en el lado este, Kreza Darkthorn y Krom'rosh en el centro con Grakna, el maestro de jinetes del viento; el tabernero Toka y Tan'jani en el lado oeste.",
	-- {quest:96107} Feathers for Fletching
	["Neza Bloodsnout: {quest:96107}"] = "Neza Bloodsnout: {quest:96107}",
	-- {quest:93788} Borrowed Blades
	["Kreza Darkthorn: {quest:93788}"] = "Kreza Darkthorn: {quest:93788}",
	-- {object:3202} Grom'gol
	-- was: ["{npc:256418}: Aggro'gosh's report from {object:3202}, if you carry it"] = "{npc:256418}: el informe de Aggro'gosh desde {object:3202}, si lo llevas"
	["Krom'rosh: Aggro'gosh's report from {object:3202}, if you carry it"] = "Krom'rosh: el informe de Aggro'gosh de {object:3202}, si lo llevas",
	-- was: ["{npc:255993}, in the middle of the fort"] = "{npc:255993}, en el centro del fuerte"
	["Grakna, in the middle of the fort"] = "Grakna, en el centro del fuerte",
	["Innkeeper Toka"] = "Tabernero Toka",
	-- {quest:95951} Fetch 'n' Fletch
	["Tan'jani: {quest:95951}"] = "Tan'jani: {quest:95951}",

	-- Step 8: Krom'rosh
	["Krom'rosh"] = "Krom'rosh",
	-- was: ["Frazzlespark's crate from the port goes to {npc:256418}, in the middle of the fort."] = "La caja de Frazzlespark del puerto es para {npc:256418}, en el centro del fuerte."
	["Frazzlespark's crate from the port goes to Krom'rosh, in the middle of the fort."] = "La caja de Frazzlespark del puerto va para Krom'rosh, en el centro del fuerte.",

	-- Step 9: The plains and the marsh
	["The plains and the marsh"] = "Las llanuras y la marisma",
	-- {area:16729} Terral's Watch
	-- was: ["South-east of Rog'mar the plains run down to {area:16729}. The Low Plains Buzzards circle everywhere; a picked carcass lies in the grass (its skull starts {quest:96103}), and the marsh vents are just past it."] = "Al sureste de Rog'mar, las llanuras bajan hasta {area:16729}. Los ratoneros de las Llanuras Bajas vuelan en círculos por todas partes; hay un cadáver descarnado en la hierba (su cráneo inicia {quest:96103}), y las fumarolas de la marisma están justo después."
	["South-east of Rog'mar the plains run down to {area:16729}. The Low Plains Buzzards circle everywhere; a picked carcass lies in the grass (its skull starts A Feast for Buzzards), and the marsh vents are just past it."] = "Al sureste de Rog'mar las llanuras bajan hacia {area:16729}. Los Low Plains Buzzards vuelan en círculos por todas partes; hay un cadáver picoteado en la hierba (su cráneo inicia A Feast for Buzzards), y los respiraderos del pantano están justo más allá.",

	-- Step 10: Neza Bloodsnout
	["Neza Bloodsnout"] = "Neza Bloodsnout",
	-- {area:16743} Rog'mar
	["West back to {area:16743}'s east side."] = "Vuelve al oeste, al lado este de {area:16743}.",

	-- Step 11: The vipers and the tallstriders
	["The vipers and the tallstriders"] = "Las víboras y los zancaltos",
	-- {area:16729} Terral's Watch · {area:16725} Wheeler's Grange
	-- was: ["The Glade Vipers hide in the long grass south-east of town; the Roving Tallstriders graze beside them. {npc:257079}, an Alliance elite (level 45), rides the road from {area:16729} to {area:16725} along the grass's south-west edge: keep clear of him."] = "Las Víboras del claro se esconden en la hierba alta al sureste del pueblo; los Zancaltos errantes pastan a su lado. {npc:257079}, un élite de la Alianza (nivel 45), recorre el camino de {area:16729} a {area:16725} por el borde suroeste de la hierba: no te acerques a él."
	["The Glade Vipers hide in the long grass south-east of town; the Roving Tallstriders graze beside them. Cavalry Scout Alturin, an Alliance elite (level 45), rides the road from {area:16729} to {area:16725} along the grass's south-west edge: keep clear of him."] = "Las víboras del claro se esconden en la hierba alta al sureste del pueblo; los zancaaltos errantes pastan junto a ellas. El explorador de caballería Alturin, un élite de la Alianza (nivel 45), recorre a caballo el camino de {area:16729} a {area:16725} por el borde suroeste de la hierba: mantente lejos de él.",

	-- Step 13: Turner's Logging Camp
	-- plural, as words: Wood Bundles = {item:271629} Wood Bundle · Makeshift Stickin' Spears = {item:271639} Makeshift Stickin' Spear
	-- was: ["South-west across the river to the Alliance lumber camp. The lumberjacks carry the axes. Loot Wood Bundles from the Peasant Woodpiles around the camp and use them to fletch Makeshift Stickin' Spears. {npc:263380}, an elite (level 42), prowls the river by the camp: if he comes your way, back off and let him pass."] = "Al suroeste, cruzando el río, hasta el campamento maderero de la Alianza. Los leñadores llevan las hachas. Despoja Montones de madera de las Pilas de leña de campesino del campamento y úsalos para fabricar Lanzas trinchadoras improvisadas. {npc:263380}, un élite (nivel 42), merodea por el río junto al campamento: si viene hacia ti, retrocede y déjalo pasar."
	["South-west across the river to the Alliance lumber camp. The lumberjacks carry the axes. Loot Wood Bundles from the Peasant Woodpiles around the camp and use them to fletch Makeshift Stickin' Spears. Ghostmaw, an elite (level 42), prowls the river by the camp: if he comes your way, back off and let him pass."] = "Al suroeste, cruzando el río, hasta el campamento maderero de la Alianza. Los leñadores llevan las hachas. Recoge Wood Bundles de los Peasant Woodpiles alrededor del campamento y úsalos para fabricar Makeshift Stickin' Spears. Ghostmaw, un élite (nivel 42), ronda el río junto al campamento: si viene hacia ti, aléjate y déjalo pasar.",
	-- {item:271629} Wood Bundle
	["{item:271629}, from the Peasant Woodpiles"] = "{item:271629}, de las Pilas de leña de campesino",
	-- {item:271629} Wood Bundle
	-- plural, as words: Makeshift Stickin' Spears = {item:271639} Makeshift Stickin' Spear
	["{item:271629}: fletch it into Makeshift Stickin' Spears"] = "{item:271629}: conviértelo en Lanzas trinchadoras improvisadas",

	-- Step 14: Meadowsbrook
	-- {area:16735} Meadowsbrook · {area:16744} Southern Watch
	-- was: ["East to {area:16735}, the Alliance farm by the river: the farmhands work the fields and the feed satchels lie by the barns. {area:16744}, the Alliance outpost on the road, has guards: pass south of it.\nCareful: {npc:263380}, an elite (level 42), hunts along the river by the farm: keep an eye on the riverbank."] = "Al este, hacia {area:16735}, la granja de la Alianza junto al río: los peones trabajan los campos y las bolsas de pienso están junto a los graneros. {area:16744}, el puesto de la Alianza en el camino, tiene guardias: pasa al sur de él.\nCuidado: {npc:263380}, un élite (nivel 42), caza a lo largo del río junto a la granja: vigila la orilla."
	["East to {area:16735}, the Alliance farm by the river: the farmhands work the fields and the feed satchels lie by the barns. {area:16744}, the Alliance outpost on the road, has guards: pass south of it.\nCareful: Ghostmaw, an elite (level 42), hunts along the river by the farm: keep an eye on the riverbank."] = "Ve al este a {area:16735}, la granja de la Alianza junto al río: los peones trabajan los campos y los sacos de alimento están junto a los establos. {area:16744}, el puesto de la Alianza en el camino, tiene guardias: pasa al sur de él.\\nCuidado: Ghostmaw, un élite (nivel 42), caza a lo largo del río junto a la granja: vigila la ribera.",

	-- Step 15: Rog'mar
	-- {area:16743} Rog'mar
	-- was: ["Back to {area:16743}, where your Hearthstone is set: {npc:263190} on the fort's west side first, then {npc:256418}, {npc:256655} by the cook fire, {npc:256657} and {npc:258031} on your way east through the fort."] = "Vuelve a {area:16743}, donde tienes vinculada la Piedra de hogar: primero {npc:263190}, en el lado oeste del fuerte; luego {npc:256418}, {npc:256655} junto a la hoguera, {npc:256657} y {npc:258031} de camino al este por el fuerte."
	["Back to {area:16743}, where your Hearthstone is set: Tan'jani on the fort's west side first, then Krom'rosh, Gorg by the cook fire, Kreza and Neza on your way east through the fort."] = "Vuelve a {area:16743}, donde está fijada tu piedra de hogar: primero Tan'jani en el lado oeste del fuerte, luego Krom'rosh, Gorg junto a la fogata de cocina, y Kreza y Neza en tu camino hacia el este por el fuerte.",
	["Tan'jani"] = "Tan'jani",
	["Kreza Darkthorn"] = "Kreza Darkthorn",

	-- Step 16: The river and the Farholde camp
	["The river and the Farholde camp"] = "El río y el campamento de Farholde",
	-- was: ["South-west of Rog'mar the river runs between the farms: impale the Freshwater Crocolisks with {npc:263190}'s spears. The Alliance trains its scouts and priests at a camp on the far bank. {npc:257079}, the Alliance elite, rides the road just east of the camp: pull the scouts and priests away from it.\nCareful: {npc:263380}, an elite (level 42), hunts along this river: if he comes your way, back off and let him pass."] = "Al suroeste de Rog'mar, el río corre entre las granjas: empala a los Crocoliscos de agua dulce con las lanzas de {npc:263190}. La Alianza entrena a sus exploradores y sacerdotes en un campamento en la otra orilla. {npc:257079}, el élite de la Alianza, recorre a caballo el camino justo al este del campamento: aleja a los exploradores y sacerdotes de él.\nCuidado: {npc:263380}, un élite (nivel 42), caza a lo largo de este río: si viene hacia ti, retírate y déjalo pasar."
	["South-west of Rog'mar the river runs between the farms: impale the Freshwater Crocolisks with Tan'jani's spears. The Alliance trains its scouts and priests at a camp on the far bank. Cavalry Scout Alturin, the Alliance elite, rides the road just east of the camp: pull the scouts and priests away from it.\nCareful: Ghostmaw, an elite (level 42), hunts along this river: if he comes your way, back off and let him pass."] = "Al suroeste de Rog'mar el río corre entre las granjas: empala a los Crocoliscos de agua dulce con las lanzas de Tan'jani. La Alianza entrena a sus exploradores y sacerdotes en un campamento en la otra orilla. El explorador de caballería Alturin, el élite de la Alianza, recorre a caballo el camino justo al este del campamento: aleja a los exploradores y sacerdotes de él.\nCuidado: Ghostmaw, un élite (nivel 42), caza a lo largo de este río: si viene hacia ti, retrocede y déjalo pasar.",
	["Tan'jani's spears, on the Freshwater Crocolisks in the river"] = "Las lanzas de Tan'jani, con los Freshwater Crocolisks del río",
	["Farholde Priest"] = "Sacerdote de Farholde",
	["Farholde Scout"] = "Explorador de Farholde",

	-- Step 18: Fuzzle
	["Fuzzle"] = "Fuzzle",
	-- {area:16723} Sunnyglade
	-- was: ["{npc:259158} wants out of {area:16723}: lead him west to his treasure at the edge of town and keep the cultists off him."] = "{npc:259158} quiere salir de {area:16723}: llévalo al oeste hasta su tesoro, en el borde del pueblo, y mantén a los cultistas lejos de él."
	["Fuzzle wants out of {area:16723}: lead him west to his treasure at the edge of town and keep the cultists off him."] = "Fuzzle quiere salir de {area:16723}: llévalo al oeste hasta su tesoro en el borde del pueblo y mantén a los cultistas lejos de él.",
	-- {area:16723} Sunnyglade
	-- was: ["lead {npc:259158} out of {area:16723} to his treasure, west of the town"] = "guía a {npc:259158} fuera de {area:16723} hasta su tesoro, al oeste del pueblo"
	["lead Fuzzle out of {area:16723} to his treasure, west of the town"] = "lleva a Fuzzle fuera de {area:16723} hasta su tesoro, al oeste del pueblo",

	-- Step 19: WANTED: Scoutmaster Vargas
	-- was: ["{npc:260211} is an elite (level 42) at the Alliance scouts' camp in the hills south-east of {npc:256728}, where you go next: grouping up is advised. The poster hangs in the middle of the fort; {npc:258031} takes the eye, later in this guide."] = "{npc:260211} es un élite (nivel 42) en el campamento de exploradores de la Alianza, en las colinas al sureste de {npc:256728}, adonde vas a continuación: se recomienda ir en grupo. El cartel cuelga en el centro del fuerte; {npc:258031} recibe el ojo, más adelante en esta guía."
	["Scoutmaster Vargas is an elite (level 42) at the Alliance scouts' camp in the hills south-east of Na'zok, where you go next: grouping up is advised. The poster hangs in the middle of the fort; Neza Bloodsnout takes the eye, later in this guide."] = "Scoutmaster Vargas es un élite (nivel 42) en el campamento de exploradores de la Alianza, en las colinas al sureste de Na'zok, adonde vas después: se recomienda ir en grupo. El cartel está en medio del fuerte; Neza Bloodsnout se encarga de la misión del ojo, más adelante en esta guía.",
	-- {object:707249} Wanted
	["the {object:707249} poster"] = "el cartel de {object:707249}",

	-- Step 20: Scoutmaster Vargas
	["Scoutmaster Vargas"] = "Scoutmaster Vargas",

	-- Step 21: Powderfuse Port
	-- {area:16727} Powderfuse Port
	-- was: ["South-east down out of the hills to {area:16727}, the goblins' harbour on the coast. {npc:255897} keeps a stall at the west end of the docks, {npc:259962} cooks by the inn, and {npc:259961} works the north pier."] = "Baja de las colinas hacia el sureste hasta {area:16727}, el puerto de los goblins en la costa. {npc:255897} tiene un puesto en el extremo oeste de los muelles, {npc:259962} cocina junto a la posada y {npc:259961} trabaja en el embarcadero norte."
	["South-east down out of the hills to {area:16727}, the goblins' harbour on the coast. Friz Frazzlespark keeps a stall at the west end of the docks, Fimbo Greasemitz cooks by the inn, and Wharfmaster Whizzbuzz works the north pier."] = "Baja de las colinas hacia el sureste hasta {area:16727}, el puerto de los goblins en la costa. Friz Frazzlespark tiene un puesto en el extremo oeste de los muelles, Fimbo Greasemitz cocina junto a la posada y el maestro de muelle Whizzbuzz trabaja en el muelle norte.",
	-- {quest:95121} A Taste of the Sea
	["Fimbo Greasemitz: {quest:95121}"] = "Fimbo Greasemitz: {quest:95121}",
	-- {object:628948} WANTED!
	-- was: ["The {object:628948} poster by the inn: {npc:260235}"] = "El cartel de {object:628948} junto a la posada: {npc:260235}"
	["The {object:628948} poster by the inn: Trapclaw"] = "El cartel de {object:628948} junto a la posada: Trapclaw",
	-- {quest:95118} Saltwater Savages
	["Wharfmaster Whizzbuzz: {quest:95118}"] = "Maestro de muelle Whizzbuzz: {quest:95118}",

	-- Step 22: The murlocs, south-west
	["The murlocs, south-west"] = "Los múrlocs, al suroeste",
	-- was: ["South-west along the shore from the port: the saltwater murlocs camp on the beaches. On the way, a painted hide is stretched beside the path: it starts {quest:95260} for {npc:260231} at the docks."] = "Ve al suroeste por la orilla desde el puerto: los múrlocs de agua salada acampan en las playas. Por el camino, hay una piel pintada tendida junto al sendero: inicia {quest:95260} para {npc:260231} en los muelles."
	["South-west along the shore from the port: the saltwater murlocs camp on the beaches. On the way, a painted hide is stretched beside the path: it starts Terrors From the Deep for Argo Brinewhistle at the docks."] = "Al suroeste por la orilla desde el puerto: los múrlocs de agua salada acampan en las playas. En el camino, hay un cuero pintado extendido junto al sendero: inicia Terrors From the Deep para Argo Brinewhistle en los muelles.",

	-- Step 23: Back through the port
	["Back through the port"] = "De vuelta por el puerto",
	["Back north along the shore: hand in the murlocs and the hide on the docks on your way to the crawlers."] = "Vuelve al norte por la orilla: entrega los múrlocs y la piel en los muelles de camino a los reptadores.",
	["Wharfmaster Whizzbuzz"] = "Wharfmaster Whizzbuzz",

	-- Step 24: The crawlers and Trapclaw
	-- was: ["The crawlers and {npc:260235}"] = "Los reptadores y {npc:260235}"
	["The crawlers and Trapclaw"] = "Los reptadores y Trapclaw",
	-- was: ["North along the beach from the docks: the crawlers drop the meat for {npc:259962}, and their entrails count for {npc:260231}. {npc:260235}, a big crab, scuttles along the rocks east of the docks. {npc:259758}, a rare elite of level 49, roams this coast from the docks up to the pirates' camp: if you see him, keep well away."] = "Hacia el norte por la playa desde los muelles: los reptadores sueltan la carne para {npc:259962} y sus entrañas cuentan para {npc:260231}. {npc:260235}, un cangrejo grande, corretea por las rocas al este de los muelles. {npc:259758}, un élite raro de nivel 49, recorre esta costa desde los muelles hasta el campamento pirata: si lo ves, mantente bien lejos."
	["North along the beach from the docks: the crawlers drop the meat for Fimbo, and their entrails count for Argo. Trapclaw, a big crab, scuttles along the rocks east of the docks. Gul'gash, a rare elite of level 49, roams this coast from the docks up to the pirates' camp: if you see him, keep well away."] = "Al norte por la playa desde los muelles: los cangrejos sueltan la carne para Fimbo, y sus entrañas cuentan para Argo. Trapclaw, un cangrejo grande, anda por las rocas al este de los muelles. Gul'gash, un élite raro de nivel 49, recorre esta costa desde los muelles hasta el campamento de los piratas: si lo ves, mantente bien lejos.",

	-- Step 25: The Eastsea pirates
	["The Eastsea pirates"] = "Los piratas de Mareste",
	-- was: ["North-east along the coast to the pirates' camp on the cliffs. The buccaneers and musketeers carry the smuggled goods. {npc:259758} walks the camp too: keep an eye out for him."] = "Ve al noreste por la costa hasta el campamento pirata de los acantilados. Los bucaneros y mosqueteros llevan la mercancía de contrabando. {npc:259758} también recorre el campamento: no lo pierdas de vista."
	["North-east along the coast to the pirates' camp on the cliffs. The buccaneers and musketeers carry the smuggled goods. Gul'gash walks the camp too: keep an eye out for him."] = "Ve al noreste por la costa hasta el campamento pirata en los acantilados. Los bucaneros y mosqueteros llevan la mercancía de contrabando. Gul'gash también recorre el campamento: estate atento a él.",

	-- Step 26: Powderfuse Port
	["Back to the port, from the north pier west through the docks."] = "Vuelve al puerto, desde el muelle norte hacia el oeste por los embarcaderos.",
	["Fimbo Greasemitz"] = "Fimbo Greasemitz",
	["Friz Frazzlespark"] = "Friz Frazzlespark",
	-- {quest:95293} Smuggler's Special
	-- was: ["{quest:95293}: for {npc:260390} at the pirates' camp"] = "{quest:95293}: para {npc:260390}, en el campamento pirata"
	["{quest:95293}: for Captain Bentcoin at the pirates' camp"] = "{quest:95293}: para Captain Bentcoin en el campamento pirata",

	-- Step 27: The pirates' second wave
	["The pirates' second wave"] = "La segunda oleada pirata",
	-- plural, as words: Eastsea Raiders = {npc:257915} Eastsea Raider
	-- was: ["North along the coast from the port: the Eastsea raiders and bombardiers have dug in on the slopes west of the buccaneers' camp, among their powder kegs. Watch for {npc:259758} on these cliffs.\nCareful: the Eastsea Raiders are level 44-45, a level or two over you here: pull them one at a time from the edge of the slopes and keep clear of the camp behind them."] = "Hacia el norte por la costa desde el puerto: los asaltantes y bombarderos de Mareste se han atrincherado en las laderas al oeste del campamento de los bucaneros, entre sus barriles de pólvora. Atento a {npc:259758} en estos acantilados.\nCuidado: los Asaltantes de Mareste son de nivel 44-45, uno o dos niveles por encima de ti aquí: atráelos de uno en uno desde el borde de las laderas y no te acerques al campamento que hay detrás."
	["North along the coast from the port: the Eastsea raiders and bombardiers have dug in on the slopes west of the buccaneers' camp, among their powder kegs. Watch for Gul'gash on these cliffs.\nCareful: the Eastsea Raiders are level 44-45, a level or two over you here: pull them one at a time from the edge of the slopes and keep clear of the camp behind them."] = "Al norte por la costa desde el puerto: los asaltantes y bombarderos de Eastsea se han atrincherado en las laderas al oeste del campamento de los bucaneros, entre sus barriles de pólvora. Atento a Gul'gash en estos acantilados.\nCuidado: los Asaltantes de Eastsea son de nivel 44-45, uno o dos niveles por encima de ti aquí: atráelos de uno en uno desde el borde de las laderas y mantente lejos del campamento detrás de ellos.",

	-- Step 28: Captain Bentcoin
	["Captain Bentcoin"] = "Captain Bentcoin",
	-- was: ["East along the cliffs to the far end of the pirates' camp: {npc:260390} waits by the water, {npc:260391} beside him."] = "Ve hacia el este por los acantilados hasta el otro extremo del campamento pirata: {npc:260390} espera junto al agua, con {npc:260391} a su lado."
	["East along the cliffs to the far end of the pirates' camp: Captain Bentcoin waits by the water, Captain Haynes beside him."] = "Al este por los acantilados hasta el extremo del campamento pirata: Captain Bentcoin espera junto al agua, con Captain Haynes a su lado.",

	-- Step 29: Powderfuse Port
	["Back to the port."] = "Vuelve al puerto.",
	-- {quest:95296} Shipping and Handling · {area:977} Steamwheedle Port · {zone:1444} Feralas · {zone:1446} Tanaris
	-- was: ["{npc:255897}: {quest:95296}, for {npc:260405} at {area:977} in the {zone:1444} & {zone:1446} guide"] = "{npc:255897}: {quest:95296}, para {npc:260405} en {area:977}, en la guía de {zone:1444} y {zone:1446}"
	["Friz: {quest:95296}, for Wharfmaster Steamfizzle at {area:977} in the {zone:1444} & {zone:1446} guide"] = "Friz: {quest:95296}, para el maestro de muelle Steamfizzle en {area:977}, en la guía de {zone:1444} y {zone:1446}",

	-- Step 30: The pirates' ships
	["The pirates' ships"] = "Los barcos piratas",
	-- {quest:95124} Admiral Lamora
	-- was: ["Out to the pirates' cliffs once more. Plant Whizzbuzz's charges on the three ships moored below the camp, south to north; {quest:95124} stands by the middle one, with her loot chest beside her. Keep an eye out for {npc:259758} on the way.\nCareful: {quest:95124} is level 45, a level or two over you here: clear the deck around her first and come in with full health."] = "Vuelve una vez más a los acantilados de los piratas. Coloca las cargas de Whizzbuzz en los tres barcos amarrados bajo el campamento, de sur a norte; {quest:95124} está junto al del medio, con su cofre de botín al lado. Atento a {npc:259758} por el camino.\nCuidado: {quest:95124} es de nivel 45, uno o dos niveles por encima de ti aquí: limpia primero la cubierta a su alrededor y llega con la salud al máximo."
	["Out to the pirates' cliffs once more. Plant Whizzbuzz's charges on the three ships moored below the camp, south to north; {quest:95124} stands by the middle one, with her loot chest beside her. Keep an eye out for Gul'gash on the way.\nCareful: {quest:95124} is level 45, a level or two over you here: clear the deck around her first and come in with full health."] = "De nuevo a los acantilados de los piratas. Planta las cargas de Whizzbuzz en los tres barcos amarrados bajo el campamento, de sur a norte; {quest:95124} está junto al del medio, con su cofre de botín a su lado. Atento a Gul'gash en el camino.\nCuidado: {quest:95124} es de nivel 45, uno o dos niveles por encima de ti aquí: limpia primero la cubierta a su alrededor y entra con la salud completa.",
	-- {item:268505} Remote Explosive Charge
	["{item:268505}, the southern ship"] = "{item:268505}, el barco del sur",
	["the middle ship"] = "el barco del medio",
	["the northern ship"] = "el barco del norte",

	-- Step 31: Powderfuse Port
	["Down to the port."] = "Baja al puerto.",
	-- {quest:95267} The Monster Surfaces
	-- was: ["{quest:95267}: a big beast in the shallows south-west of the port, near {npc:257001}, the elite"] = "{quest:95267}: una gran bestia en las aguas poco profundas al suroeste del puerto, cerca de {npc:257001}, el élite"
	["{quest:95267}: a big beast in the shallows south-west of the port, near Old Rot-Chum, the elite"] = "{quest:95267}: una gran bestia en las aguas poco profundas al suroeste del puerto, cerca de Old Rot-Chum, el élite",

	-- Step 32: The Monster Surfaces
	-- was: ["The {npc:260244} prowls the shallows south-west of the port, below the murlocs' beaches. {npc:257001}, an elite, walks the shore close by: give him room."] = "El {npc:260244} merodea por las aguas poco profundas al suroeste del puerto, bajo las playas de los múrlocs. {npc:257001}, un élite, recorre la orilla cerca: mantén las distancias."
	["The Monstrous Threshadon prowls the shallows south-west of the port, below the murlocs' beaches. Old Rot-Chum, an elite, walks the shore close by: give him room."] = "El Threshadon monstruoso merodea las aguas poco profundas al suroeste del puerto, bajo las playas de los múrlocs. Old Rot-Chum, un élite, recorre la orilla cerca: dale espacio.",

	-- Step 33: Argo Brinewhistle
	["Argo Brinewhistle"] = "Argo Brinewhistle",

	-- Step 34: Rog'mar
	-- {area:16743} Rog'mar
	-- was: ["Back to {area:16743} from the port, where your Hearthstone is set. {npc:256418} in the middle of the fort: {npc:255829}'s word sends him looking for {npc:258570}, his warrior in the west."] = "Vuelve desde el puerto a {area:16743}, donde tienes vinculada la Piedra de hogar. {npc:256418}, en el centro del fuerte: la palabra de {npc:255829} lo lleva a buscar a {npc:258570}, su guerrero en el oeste."
	["Back to {area:16743} from the port, where your Hearthstone is set. Krom'rosh in the middle of the fort: Clugfist's word sends him looking for Da'grosh, his warrior in the west."] = "Vuelve desde el puerto a {area:16743}, donde tienes vinculada tu piedra de hogar. Krom'rosh, en el centro del fuerte: el aviso de Clugfist lo hace buscar a Da'grosh, su guerrero en el oeste.",
	-- {quest:95428} Clugfist's Decree
	["Krom'rosh: {quest:95428}"] = "Krom'rosh: {quest:95428}",

	-- Step 36: Twilight's Shroud
	-- {area:340} Kargath · {area:3} Badlands · {area:16685} Twilight's Shroud
	-- was: ["The next guide flies from {area:340} in the {area:3}: north out of {npc:258570}'s valley and up through {area:16685}, the way through to the {area:3}."] = "La siguiente guía sale volando desde {area:340}, en {area:3}: ve al norte, fuera del valle de {npc:258570}, y sube por {area:16685}, el paso hacia {area:3}."
	["The next guide flies from {area:340} in the {area:3}: north out of Da'grosh's valley and up through {area:16685}, the way through to the {area:3}."] = "La siguiente guía vuela desde {area:340} en {area:3}: al norte saliendo del valle de Da'grosh y subiendo por {area:16685}, el paso hacia {area:3}.",

	-- Step 37: Kargath
	-- {area:3} Badlands · {area:340} Kargath
	["Across the {area:3} to {area:340}, the Horde fortress built into the cliffs at the zone's western edge: its flight master stands at the foot of the fortress."] = "Cruza {area:3} hasta {area:340}, la fortaleza de la Horda construida en los acantilados del extremo oeste de la zona: su maestro de vuelo está al pie de la fortaleza.",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["Back to {area:16743} from the port, where your Hearthstone is set. {npc:256418} in the middle of the fort: {npc:255829}'s word sends him looking for {npc:258570}, his warrior in the west."] = "Vuelve desde el puerto a {area:16743}, donde tienes vinculada la Piedra de hogar. {npc:256418}, en el centro del fuerte: la palabra de {npc:255829} lo lleva a buscar a {npc:258570}, su guerrero en el oeste.",
	-- ["Back to {area:16743}, where your Hearthstone is set: {npc:263190} on the fort's west side first, then {npc:256418}, {npc:256655} by the cook fire, {npc:256657} and {npc:258031} on your way east through the fort."] = "Vuelve a {area:16743}, donde tienes vinculada la Piedra de hogar: primero {npc:263190}, en el lado oeste del fuerte; luego {npc:256418}, {npc:256655} junto a la hoguera, {npc:256657} y {npc:258031} de camino al este por el fuerte.",
	-- ["Back to {npc:255829} on his hill. {npc:257062} runs the {quest:94668} just below it."] = "Vuelve con {npc:255829} a su colina. {npc:257062} lleva {quest:94668} justo debajo.",
	-- ["Bonegnaw"] = "Roehuesos",
	-- ["Careful: {npc:256899}, the two-headed ogre at the western edge of {area:16723}, is an elite (level 41): grouping up is advised under 43. Clear the cultists around him first and come in with full health and mana: recorded players of 42-43 killed him alone. {npc:255829}'s quests in {area:16726} wait on this one: skip him and {quest:95420}, the {area:16726} quests and {npc:258570}'s camp in the west go with him (about 21,000 XP); the guide then leaves them out."] = "Cuidado: {npc:256899}, el ogro de dos cabezas del borde oeste de {area:16723}, es un élite (nivel 41): se recomienda ir en grupo por debajo del nivel 43. Limpia primero a los cultores que lo rodean y entra con la salud y el maná al máximo: hay jugadores de nivel 42-43 que lo han matado solos. Las misiones de {npc:255829} en {area:16726} dependen de esta: si lo saltas, también pierdes {quest:95420}, las misiones de {area:16726} y el campamento de {npc:258570} en el oeste (unos 21.000 PX); la guía las omite entonces.",
	-- ["Each bout is a fight in the ring below {npc:255829}'s hill against an elite: Buzzbeak (41), Kronk and Bonegnaw (42), {npc:258626} (43), Snufflesnout (44) and {npc:257059} (45). Come in rested, with full health and mana; if a bout goes wrong, {npc:257062} offers it again."] = "Cada combate es una pelea en el anillo bajo la colina de {npc:255829} contra un élite: Picozumbón (41), Kronk y Roehuesos (42), {npc:258626} (43), Hocicorresopla (44) y {npc:257059} (45). Ve descansado, con la salud y el maná al máximo; si un combate sale mal, {npc:257062} te lo vuelve a ofrecer.",
	-- ["East along the cliffs to the far end of the pirates' camp: {npc:260390} waits by the water, {npc:260391} beside him."] = "Ve hacia el este por los acantilados hasta el otro extremo del campamento pirata: {npc:260390} espera junto al agua, con {npc:260391} a su lado.",
	-- ["East back to {area:16743}."] = "Vuelve al este a {area:16743}.",
	-- ["East back to {area:16743}: {npc:260931}'s word goes to {npc:256710}, and {npc:256710}'s to {npc:255829}, the ogres' chieftain."] = "Vuelve al este a {area:16743}: el mensaje de {npc:260931} va para {npc:256710}, y el de {npc:256710} para {npc:255829}, el jefe de los ogros.",
	-- ["East of Rog'mar, on the hill above the road to {area:16727}: {npc:263367} has his workshop there. The gas vents are in the marsh south-west of it, on your first hunt for {npc:258031}."] = "Al este de Rog'mar, en la colina sobre el camino a {area:16727}: allí tiene su taller {npc:263367}. Las fumarolas de gas están en la marisma al suroeste, en tu primera cacería para {npc:258031}.",
	-- ["East to {area:16735}, the Alliance farm by the river: the farmhands work the fields and the feed satchels lie by the barns. {area:16744}, the Alliance outpost on the road, has guards: pass south of it.\nCareful: {npc:263380}, an elite (level 42), hunts along the river by the farm: keep an eye on the riverbank."] = "Al este, hacia {area:16735}, la granja de la Alianza junto al río: los peones trabajan los campos y las bolsas de pienso están junto a los graneros. {area:16744}, el puesto de la Alianza en el camino, tiene guardias: pasa al sur de él.\nCuidado: {npc:263380}, un élite (nivel 42), caza a lo largo del río junto a la granja: vigila la orilla.",
	-- ["Finish the {item:268632}"] = "Termina las {item:268632}",
	-- ["Frazzlespark's crate from the port goes to {npc:256418}, in the middle of the fort."] = "La caja de Frazzlespark del puerto es para {npc:256418}, en el centro del fuerte.",
	-- ["Kronk"] = "Kronk",
	-- ["Most beasts in the {zone:2548} drop {item:268632} for {npc:260231}: the shore crawlers on this coast and the boars on the ridge west of the pirates.\nCareful: {npc:257001} (elite, 42) wanders the shore and {npc:263380} (elite, 42) the river: take your beasts away from them."] = "La mayoría de las bestias de {zone:2548} sueltan {item:268632} para {npc:260231}: los reptadores de la orilla de esta costa y los jabalíes de la cresta al oeste de los piratas.\nCuidado: {npc:257001} (élite, 42) deambula por la orilla y {npc:263380} (élite, 42) por el río: aleja de ellos a tus bestias.",
	-- ["New in Forever: if a step is wrong, tell us on Polestar's Discord or GitHub and name the step.\n{npc:255897} keeps a stall at the west end of the docks. The port's other jobs are for later in this guide: this crate goes to the Horde's fort."] = "Nuevo en Forever: si un paso está mal, avísanos en el Discord o GitHub de Polestar e indica el paso.\n{npc:255897} tiene un puesto en el extremo oeste de los muelles. Los demás encargos del puerto son para más adelante en esta guía: esta caja va al fuerte de la Horda.",
	-- ["North along the beach from the docks: the crawlers drop the meat for {npc:259962}, and their entrails count for {npc:260231}. {npc:260235}, a big crab, scuttles along the rocks east of the docks. {npc:259758}, a rare elite of level 49, roams this coast from the docks up to the pirates' camp: if you see him, keep well away."] = "Hacia el norte por la playa desde los muelles: los reptadores sueltan la carne para {npc:259962} y sus entrañas cuentan para {npc:260231}. {npc:260235}, un cangrejo grande, corretea por las rocas al este de los muelles. {npc:259758}, un élite raro de nivel 49, recorre esta costa desde los muelles hasta el campamento pirata: si lo ves, mantente bien lejos.",
	-- ["North along the coast from the port: the Eastsea raiders and bombardiers have dug in on the slopes west of the buccaneers' camp, among their powder kegs. Watch for {npc:259758} on these cliffs.\nCareful: the Eastsea Raiders are level 44-45, a level or two over you here: pull them one at a time from the edge of the slopes and keep clear of the camp behind them."] = "Hacia el norte por la costa desde el puerto: los asaltantes y bombarderos de Mareste se han atrincherado en las laderas al oeste del campamento de los bucaneros, entre sus barriles de pólvora. Atento a {npc:259758} en estos acantilados.\nCuidado: los Asaltantes de Mareste son de nivel 44-45, uno o dos niveles por encima de ti aquí: atráelos de uno en uno desde el borde de las laderas y no te acerques al campamento que hay detrás.",
	-- ["North of the camps the cult works ogre miners in a mine: talk five of them into rising up against their masters.\nCareful: Twilight Enforcers (elites, level 45) walk past the mine's mouth on their way through the camps. Wait for one to pass before you go in."] = "Al norte de los campamentos, el culto hace trabajar a mineros ogros en una mina: convence a cinco de que se rebelen contra sus amos.\nCuidado: los Ejecutores Crepusculares (élites, nivel 45) pasan por la entrada de la mina en su ronda por los campamentos. Espera a que pase uno antes de entrar.",
	-- ["North of the fort the Rog'mar Trainees drill: use {npc:256655}'s {item:265066} on them.\nCareful: {npc:263380}, an elite (level 42), can come up from the river south of the fort: let him pass."] = "Al norte del fuerte entrenan los Aprendices de Rog'mar: usa el {item:265066} de {npc:256655} con ellos.\nCuidado: {npc:263380}, un élite (nivel 42), puede subir desde el río al sur del fuerte: déjalo pasar.",
	-- ["North-east along the coast to the pirates' camp on the cliffs. The buccaneers and musketeers carry the smuggled goods. {npc:259758} walks the camp too: keep an eye out for him."] = "Ve al noreste por la costa hasta el campamento pirata de los acantilados. Los bucaneros y mosqueteros llevan la mercancía de contrabando. {npc:259758} también recorre el campamento: no lo pierdas de vista.",
	-- ["North-east from {area:16743} up into the hills: {npc:256728} watches the Paletusk boars from his camp."] = "Al noreste de {area:16743}, subiendo a las colinas: {npc:256728} vigila a los jabalíes Colmillo Pálido desde su campamento.",
	-- ["North-east to the workshop. {npc:263367}'s stress test is a fight with his G45-B4G beside the workshop: hand the quest in once it's beaten."] = "Ve al noreste hasta el taller. La prueba de esfuerzo de {npc:263367} es un combate contra su G45-B4G junto al taller: entrega la misión cuando lo derrotes.",
	-- ["North-west to {area:16726}, the ogres' town. {npc:255829}, its chieftain, sits on the hill. The ogres are friendly while you leave them alone."] = "Ve al noroeste hasta {area:16726}, el pueblo de los ogros. {npc:255829}, su jefe, está sentado en la colina. Los ogros son amistosos mientras no los molestes.",
	-- ["Out to the pirates' cliffs once more. Plant Whizzbuzz's charges on the three ships moored below the camp, south to north; {quest:95124} stands by the middle one, with her loot chest beside her. Keep an eye out for {npc:259758} on the way.\nCareful: {quest:95124} is level 45, a level or two over you here: clear the deck around her first and come in with full health."] = "Vuelve una vez más a los acantilados de los piratas. Coloca las cargas de Whizzbuzz en los tres barcos amarrados bajo el campamento, de sur a norte; {quest:95124} está junto al del medio, con su cofre de botín al lado. Atento a {npc:259758} por el camino.\nCuidado: {quest:95124} es de nivel 45, uno o dos niveles por encima de ti aquí: limpia primero la cubierta a su alrededor y llega con la salud al máximo.",
	-- ["Rotflesh Mushrooms"] = "Champiñones putricarne",
	-- ["Snufflesnout (44)"] = "Hocicohusmeador (44)",
	-- ["South down the hills, round the west side of the Alliance scouts' camp: tap the Young Paletusks with {npc:256728}'s staff to send them home; the Mature Paletusks around the hills drop the boar meat."] = "Baja al sur por las colinas, rodeando por el oeste el campamento de exploradores de la Alianza: toca a los Colmillo Pálido jóvenes con el bastón de {npc:256728} para mandarlos a casa; los Colmillo Pálido adultos de las colinas sueltan la carne de jabalí.",
	-- ["South-east back towards the port: the shore crawlers on the beach north of the docks are the quickest entrails. {npc:259758} wanders down to this beach too."] = "Vuelve hacia el sureste hacia el puerto: los reptadores de la playa al norte de los muelles son las entrañas más rápidas. {npc:259758} también baja a esta playa.",
	-- ["South-east down out of the hills to {area:16727}, the goblins' harbour on the coast. {npc:255897} keeps a stall at the west end of the docks, {npc:259962} cooks by the inn, and {npc:259961} works the north pier."] = "Baja de las colinas hacia el sureste hasta {area:16727}, el puerto de los goblins en la costa. {npc:255897} tiene un puesto en el extremo oeste de los muelles, {npc:259962} cocina junto a la posada y {npc:259961} trabaja en el embarcadero norte.",
	-- ["South-east of Rog'mar the plains run down to {area:16729}. The Low Plains Buzzards circle everywhere; a picked carcass lies in the grass (its skull starts {quest:96103}), and the marsh vents are just past it."] = "Al sureste de Rog'mar, las llanuras bajan hasta {area:16729}. Los ratoneros de las Llanuras Bajas vuelan en círculos por todas partes; hay un cadáver descarnado en la hierba (su cráneo inicia {quest:96103}), y las fumarolas de la marisma están justo después.",
	-- ["South-east out of the hills: {npc:262399}, a prospector who deals with both sides, has camped by the Cinderscale dragonkin's hollow."] = "Al sureste, saliendo de las colinas: {npc:262399}, una prospectora que trata con ambos bandos, ha acampado junto a la hondonada de los dragontantes Escamaceniza.",
	-- ["South-west across the river to the Alliance lumber camp. The lumberjacks carry the axes. Loot Wood Bundles from the Peasant Woodpiles around the camp and use them to fletch Makeshift Stickin' Spears. {npc:263380}, an elite (level 42), prowls the river by the camp: if he comes your way, back off and let him pass."] = "Al suroeste, cruzando el río, hasta el campamento maderero de la Alianza. Los leñadores llevan las hachas. Despoja Montones de madera de las Pilas de leña de campesino del campamento y úsalos para fabricar Lanzas trinchadoras improvisadas. {npc:263380}, un élite (nivel 42), merodea por el río junto al campamento: si viene hacia ti, retrocede y déjalo pasar.",
	-- ["South-west along the shore from the port: the saltwater murlocs camp on the beaches. On the way, a painted hide is stretched beside the path: it starts {quest:95260} for {npc:260231} at the docks."] = "Ve al suroeste por la orilla desde el puerto: los múrlocs de agua salada acampan en las playas. Por el camino, hay una piel pintada tendida junto al sendero: inicia {quest:95260} para {npc:260231} en los muelles.",
	-- ["South-west of Rog'mar the river runs between the farms: impale the Freshwater Crocolisks with {npc:263190}'s spears. The Alliance trains its scouts and priests at a camp on the far bank. {npc:257079}, the Alliance elite, rides the road just east of the camp: pull the scouts and priests away from it.\nCareful: {npc:263380}, an elite (level 42), hunts along this river: if he comes your way, back off and let him pass."] = "Al suroeste de Rog'mar, el río corre entre las granjas: empala a los Crocoliscos de agua dulce con las lanzas de {npc:263190}. La Alianza entrena a sus exploradores y sacerdotes en un campamento en la otra orilla. {npc:257079}, el élite de la Alianza, recorre a caballo el camino justo al este del campamento: aleja a los exploradores y sacerdotes de él.\nCuidado: {npc:263380}, un élite (nivel 42), caza a lo largo de este río: si viene hacia ti, retírate y déjalo pasar.",
	-- ["The Cinderscale hollow"] = "La hondonada Escamaceniza",
	-- ["The Glade Vipers hide in the long grass south-east of town; the Roving Tallstriders graze beside them. {npc:257079}, an Alliance elite (level 45), rides the road from {area:16729} to {area:16725} along the grass's south-west edge: keep clear of him."] = "Las Víboras del claro se esconden en la hierba alta al sureste del pueblo; los Zancaltos errantes pastan a su lado. {npc:257079}, un élite de la Alianza (nivel 45), recorre el camino de {area:16729} a {area:16725} por el borde suroeste de la hierba: no te acerques a él.",
	-- ["The Twilight Maulers and Firecallers camp on the ridge east of {npc:256728}. {npc:260973}, who carries the {item:269257}, stands among them. Just south of the ogres, {npc:260211} (an Alliance elite, level 42) and his Farholde Ambushers hold the scouts' camp: keep north of it unless you came with a group for him."] = "Los Machacadores Crepusculares y los Clamafuegos acampan en la loma al este de {npc:256728}. {npc:260973}, que lleva {item:269257}, está entre ellos. Justo al sur de los ogros, {npc:260211} (un élite de la Alianza, nivel 42) y sus Emboscadores de Farholde ocupan el campamento de exploradores: mantente al norte salvo que vengas en grupo a por él.",
	-- ["The Twilight camps"] = "Los campamentos Crepusculares",
	-- ["The Twilight ogres' camp"] = "El campamento de los ogros Crepusculares",
	-- ["The Wildplains lions roam the plains just south of {area:16743}.\nCareful: {npc:263315}, an elite lion (level 41), prowls the same plains around 59.6,53.2: keep an eye out for him and pull the lions away from where he walks."] = "Los leones de las Llanuras Salvajes deambulan por las llanuras justo al sur de {area:16743}.\nCuidado: {npc:263315}, un león élite (nivel 41), merodea por las mismas llanuras hacia 59.6,53.2: vigílalo y aleja a los leones de su camino.",
	-- ["The crawlers and {npc:260235}"] = "Los reptadores y {npc:260235}",
	-- ["The cult's camps fill the valley south and west of {npc:258570}. Free the captive Rog'mar Scouts as you find them. Twilight Enforcers (elites, level 45) patrol through the camps: watch where they walk before each pull. {npc:256881} and {npc:256891} (elites, 46) hold the fortress at the valley's head: pull the cultists away from them. {npc:258023}'s Alliance camp sits at the valley's south end, and its Farholde Lookouts (level 46) attack the Horde: stay north of it."] = "Los campamentos del culto llenan el valle al sur y al oeste de {npc:258570}. Libera a los Exploradores Rog'mar cautivos según los encuentres. Los Ejecutores Crepusculares (élites, nivel 45) patrullan los campamentos: fíjate por dónde caminan antes de cada pull. {npc:256881} y {npc:256891} (élites, 46) ocupan la fortaleza en la cabecera del valle: aleja a los cultistas de ellos. El campamento de la Alianza de {npc:258023} está en el extremo sur del valle, y sus Vigías de Farholde (nivel 46) atacan a la Horda: quédate al norte.",
	-- ["The cultists fill the streets and fields; the Shadowmancers on the town's northern side carry the missives. The finger bones drop from all of them.\nCareful: {npc:256899}, an elite ogre (level 41), walks the western streets of {area:16723}, around 44-47,47-52. Pull the cultists out towards you and let him pass."] = "Los cultores llenan las calles y los campos; los Umbromantes del lado norte del pueblo llevan las misivas. Los huesos de dedo los sueltan todos.\nCuidado: {npc:256899}, un ogro élite (nivel 41), recorre las calles occidentales de {area:16723}, hacia 44-47,47-52. Atrae a los cultores hacia ti y déjalo pasar.",
	-- ["The lions"] = "Los leones",
	-- ["The next guide flies from {area:340} in the {area:3}: north out of {npc:258570}'s valley and up through {area:16685}, the way through to the {area:3}."] = "La siguiente guía sale volando desde {area:340}, en {area:3}: ve al norte, fuera del valle de {npc:258570}, y sube por {area:16685}, el paso hacia {area:3}.",
	-- ["The ogre mine"] = "La mina de los ogros",
	-- ["The paletusks"] = "Los Colmillo Pálido",
	-- ["The ritual grounds"] = "Los terrenos del ritual",
	-- ["The ritualists and their empowered brutes gather at the ritual circles in the middle of {area:16723}: wreck five of the circles.\nCareful: {npc:256899}, the elite ogre (level 41), walks through here from the western streets: watch for him before each pull."] = "Los ritualistas y sus brutos potenciados se reúnen en los círculos rituales del centro de {area:16723}: destruye cinco de los círculos.\nCuidado: {npc:256899}, el ogro élite (nivel 41), pasa por aquí desde las calles occidentales: búscalo antes de cada pull.",
	-- ["The training grounds"] = "El campo de entrenamiento",
	-- ["The whelps nest all over the hollow; the warriors guard its back, by the {item:271611}. The warriors are level 41-42: pull them one at a time. Scaldaron, a rare elite drake, can be up here too: leave him be unless you have a group."] = "Las crías anidan por toda la hondonada; los guerreros guardan el fondo, junto a la {item:271611}. Los guerreros son de nivel 41-42: atráelos de uno en uno. Scaldaron, un draco élite raro, también puede estar aquí: no lo toques salvo que vayas en grupo.",
	-- ["The {area:16737}"] = "{area:16737}",
	-- ["The {npc:260244} prowls the shallows south-west of the port, below the murlocs' beaches. {npc:257001}, an elite, walks the shore close by: give him room."] = "El {npc:260244} merodea por las aguas poco profundas al suroeste del puerto, bajo las playas de los múrlocs. {npc:257001}, un élite, recorre la orilla cerca: mantén las distancias.",
	-- ["The {object:628948} poster by the inn"] = "El cartel de {object:628948} junto a la posada",
	-- ["The {object:628948} poster by the inn: {npc:260235}"] = "El cartel de {object:628948} junto a la posada: {npc:260235}",
	-- ["The {quest:94670}: Buzzbeak"] = "{quest:94670}: Picozumbón",
	-- ["The {quest:94670}: Kronk and Bonegnaw"] = "{quest:94670}: Kronk y Roehuesos",
	-- ["The {quest:94962}: {npc:258626}"] = "{quest:94962}: {npc:258626}",
	-- ["The {quest:94964}: Snufflesnout and {npc:257059}"] = "{quest:94964}: Hocicohusmeador y {npc:257059}",
	-- ["West from the northern ship, up the ridge: the Rotflesh Mushrooms grow among the rocks, close to the Twilight ogres' camp. The Mature Paletusks on the ridge give entrails too."] = "Al oeste del barco del norte, sube la cresta: los Champiñones putricarne crecen entre las rocas, cerca del campamento de los ogros Crepusculares. Los Colmipálidos maduros de la cresta también dan entrañas.",
	-- ["West from {area:16743} through {area:16723} and on up the valley towards {area:16685}: {npc:258570}, {npc:256418}'s wayward warrior, keeps a camp in the hills below the Twilight cult's fortress."] = "Hacia el oeste desde {area:16743}, pasando por {area:16723} y subiendo por el valle hacia {area:16685}: {npc:258570}, el guerrero descarriado de {npc:256418}, tiene un campamento en las colinas bajo la fortaleza del culto Crepuscular.",
	-- ["West into the {area:16737}: the Redridge gnolls camp along the slopes and carry the stolen ore. Work south-west through their camps.\nCareful: {npc:255906}, an elite gnoll (level 40), roams the south-western camps: pull the gnolls away from him."] = "Al oeste, hacia {area:16737}: los gnolls Crestagrana acampan por las laderas y llevan el mineral robado. Avanza hacia el suroeste por sus campamentos.\nCuidado: {npc:255906}, un gnoll élite (nivel 40), deambula por los campamentos del suroeste: aleja a los gnolls de él.",
	-- ["West of Rog'mar the Twilight cult holds the farm town of {area:16723}. {npc:259158}, a kobold who wants out, hides in the middle of the town."] = "Al oeste de Rog'mar, el culto Crepuscular controla el pueblo agrícola de {area:16723}. {npc:259158}, un kóbold que quiere salirse, se esconde en el centro del pueblo.",
	-- ["West to {area:16723} again: {npc:260931}, a Twilight miner who wants out, waits at the town's eastern edge. Talk him round, then hand {npc:256710}'s quest in; one of the missing ogres stands a few steps west."] = "Vuelve al oeste a {area:16723}: {npc:260931}, un minero Crepuscular que quiere salirse, espera en el borde este del pueblo. Convéncelo y luego entrega la misión de {npc:256710}; uno de los ogros desaparecidos está a unos pasos al oeste.",
	-- ["West to {area:16743}, the Horde's fort in the middle of the zone. {npc:258031} stands on its east side, {npc:256657} and {npc:256418} in the middle with {npc:255993}, the wind rider master; {npc:256675} and {npc:263190} on the west side."] = "Ve al oeste hasta {area:16743}, el fuerte de la Horda en el centro de la zona. {npc:258031} está en el lado este, {npc:256657} y {npc:256418} en el centro con {npc:255993}, la maestra de jinetes del viento; {npc:256675} y {npc:263190} en el lado oeste.",
	-- ["West up the road from the port: {npc:263367} has his workshop on the hill. The gas vents are in the marsh south-west of it, on your first hunt for {npc:258031}."] = "Ve al oeste por el camino desde el puerto: {npc:263367} tiene su taller en la colina. Las fumarolas de gas están en la marisma al suroeste, en tu primera cacería para {npc:258031}.",
	-- ["beat Buzzbeak"] = "derrota a Picozumbón",
	-- ["destroy 5 Twilight Ritual Circles"] = "destruye 5 Círculos rituales Crepusculares",
	-- ["free five captive Rog'mar Scouts"] = "libera a cinco Exploradores Rog'mar cautivos",
	-- ["help {npc:258048} reach {area:16726}"] = "ayuda a {npc:258048} a llegar a {area:16726}",
	-- ["lead {npc:259158} out of {area:16723} to his treasure, west of the town"] = "guía a {npc:259158} fuera de {area:16723} hasta su tesoro, al oeste del pueblo",
	-- ["recruit five Ogre Miners"] = "recluta a cinco Mineros ogros",
	-- ["talk {npc:260931} round"] = "convence a {npc:260931}",
	-- ["the stress test: beat G45-B4G beside the workshop"] = "la prueba de resistencia: derrota a G45-B4G junto al taller",
	-- ["the {object:645164} poster"] = "el cartel de {object:645164}",
	-- ["{item:268521}, on the Young Paletusks"] = "{item:268521}, sobre los Colmillo Pálido jóvenes",
	-- ["{item:268632} as you go"] = "{item:268632} sobre la marcha",
	-- ["{item:269257}, from {npc:260973}"] = "{item:269257}, de {npc:260973}",
	-- ["{item:769}, from the Mature Paletusks"] = "{item:769}, de los Colmillo Pálido adultos",
	-- ["{npc:255829}, on the hill"] = "{npc:255829}, en la colina",
	-- ["{npc:255897}: {quest:95296}, for {npc:260405} at {area:977} in the {zone:1444} & {zone:1446} guide"] = "{npc:255897}: {quest:95296}, para {npc:260405} en {area:977}, en la guía de {zone:1444} y {zone:1446}",
	-- ["{npc:255906} is an elite gnoll (level 40) who roams the south-western camps of the {area:16737}: grouping up is advised."] = "{npc:255906} es un gnoll élite (nivel 40) que recorre los campamentos del suroeste de {area:16737}: se recomienda ir en grupo.",
	-- ["{npc:255993}, in the middle of the fort"] = "{npc:255993}, en el centro del fuerte",
	-- ["{npc:256418}: Aggro'gosh's report from {object:3202}, if you carry it"] = "{npc:256418}: el informe de Aggro'gosh desde {object:3202}, si lo llevas",
	-- ["{npc:256655}, by the cook fire"] = "{npc:256655}, junto a la hoguera",
	-- ["{npc:256710} stands beside {npc:256418} in the middle of {area:16743}: now that the Farholde camp has had its lesson, he has work in {area:16723}."] = "{npc:256710} está junto a {npc:256418} en el centro de {area:16743}: ahora que el campamento de Farholde ha recibido su lección, tiene trabajo en {area:16723}.",
	-- ["{npc:256728}'s camp"] = "Campamento de {npc:256728}",
	-- ["{npc:256881} is an elite (level 46) in the fortress at the head of the valley, with the Enforcers around him: grouping up is advised."] = "{npc:256881} es un élite (nivel 46) en la fortaleza al fondo del valle, rodeado de Ejecutores: se recomienda ir en grupo.",
	-- ["{npc:257001} is an elite (level 42) on the south shore: grouping up is advised."] = "{npc:257001} es un élite (nivel 42) en la orilla sur: se recomienda ir en grupo.",
	-- ["{npc:257062} offers the last two once Gobam's errands are done (players' recordings), which this guide leaves out. They are level 44 and 45: leave them for later if {npc:258626} was a close fight."] = "{npc:257062} ofrece las dos últimas cuando terminas los recados de Gobam (según grabaciones de jugadores), que esta guía omite. Son de nivel 44 y 45: déjalas para más tarde si {npc:258626} fue un combate ajustado.",
	-- ["{npc:258031}'s elites"] = "Los élites de {npc:258031}",
	-- ["{npc:258048} waits by the Twilight ogres' camp north-east of {npc:256728}: take him home to {area:16726} and keep the cultists off him. If he falls, take the quest from him again."] = "{npc:258048} espera junto al campamento de los ogros Crepusculares, al noreste de {npc:256728}: llévalo a casa, a {area:16726}, y protégelo de los cultistas. Si muere, vuelve a aceptar la misión de él.",
	-- ["{npc:259158} wants out of {area:16723}: lead him west to his treasure at the edge of town and keep the cultists off him."] = "{npc:259158} quiere salir de {area:16723}: llévalo al oeste hasta su tesoro, en el borde del pueblo, y mantén a los cultistas lejos de él.",
	-- ["{npc:259961} on the north pier takes Lozgil's {item:277974}."] = "{npc:259961}, en el embarcadero norte, recibe el {item:277974} de Lozgil.",
	-- ["{npc:260211} is an elite (level 42) at the Alliance scouts' camp in the hills south-east of {npc:256728}, where you go next: grouping up is advised. The poster hangs in the middle of the fort; {npc:258031} takes the eye, later in this guide."] = "{npc:260211} es un élite (nivel 42) en el campamento de exploradores de la Alianza, en las colinas al sureste de {npc:256728}, adonde vas a continuación: se recomienda ir en grupo. El cartel cuelga en el centro del fuerte; {npc:258031} recibe el ojo, más adelante en esta guía.",
	-- ["{npc:260993}, a {area:16726} ogre, hides in the cave west of {npc:258570}'s camp."] = "{npc:260993}, un ogro de {area:16726}, se esconde en la cueva al oeste del campamento de {npc:258570}.",
	-- ["{npc:261208}, a few steps west"] = "{npc:261208}, a unos pasos al oeste",
	-- ["{npc:263190}'s spears, on the Freshwater Crocolisks"] = "Las lanzas de {npc:263190}, en los Crocoliscos de agua dulce",
	-- ["{npc:263190}: {quest:95033}, for {npc:8115} at {area:1099} in the {zone:1444} guide"] = "{npc:263190}: {quest:95033}, para {npc:8115} en {area:1099}, en la guía de {zone:1444}",
	-- ["{npc:263315}, an elite lion (level 41), prowls the plains south of {area:16743}, where the lions are: grouping up is advised."] = "{npc:263315}, un león élite (nivel 41), merodea por las llanuras al sur de {area:16743}, donde están los leones: se recomienda ir en grupo.",
	-- ["{npc:263367}'s workshop"] = "Taller de {npc:263367}",
	-- ["{npc:263380} is an elite (level 42) who hunts along the river south-west of {area:16743}, by the Farholde camp you go to next: grouping up is advised. The poster hangs in the middle of the fort."] = "{npc:263380} es un élite (nivel 42) que caza a lo largo del río al suroeste de {area:16743}, junto al campamento de Farholde al que vas después: se recomienda ir en grupo. El cartel cuelga en el centro del fuerte.",
	-- ["{quest:93976}: for {npc:255897} in {area:16727}, keep it"] = "{quest:93976}: para {npc:255897} en {area:16727}, guárdala",
	-- ["{quest:94669}: the Ring's bouts, one-on-one fights with elites (41-45); a deposit first"] = "{quest:94669}: los combates del Anillo, peleas uno contra uno con élites (41-45); antes hay que pagar un depósito",
	-- ["{quest:94670}: Buzzbeak"] = "{quest:94670}: Picozumbón",
	-- ["{quest:94727}: for {npc:260931} in {area:16723}"] = "{quest:94727}: para {npc:260931} en {area:16723}",
	-- ["{quest:94744}: for {npc:258570}, west of {area:16723}"] = "{quest:94744}: para {npc:258570}, al oeste de {area:16723}",
	-- ["{quest:95062}: for {npc:256418} in {area:16743}"] = "{quest:95062}: para {npc:256418} en {area:16743}",
	-- ["{quest:95261}: the beasts' entrails come as you go; the mushrooms grow on the ridge west of the pirates"] = "{quest:95261}: las entrañas de las bestias salen sobre la marcha; los champiñones crecen en la cresta al oeste de los piratas",
	-- ["{quest:95267}: a big beast in the shallows south-west of the port, near {npc:257001}, the elite"] = "{quest:95267}: una gran bestia en las aguas poco profundas al suroeste del puerto, cerca de {npc:257001}, el élite",
	-- ["{quest:95293}: for {npc:260390} at the pirates' camp"] = "{quest:95293}: para {npc:260390}, en el campamento pirata",
	-- ["{quest:95418}: for {npc:256710} in {area:16743}"] = "{quest:95418}: para {npc:256710} en {area:16743}",
	-- ["{quest:95420}: for {npc:255829} in {area:16726}"] = "{quest:95420}: para {npc:255829} en {area:16726}",
	-- ["{quest:95428}: for {npc:256418} in {area:16743}, later in this guide"] = "{quest:95428}: para {npc:256418} en {area:16743}, más adelante en esta guía",
}
