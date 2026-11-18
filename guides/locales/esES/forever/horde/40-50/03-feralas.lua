-- Spanish (Spain) (esES): the guide forever/horde/40-50/03-feralas (forever/horde/40-50/03-feralas.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Guide
	-- {zone:1435} Swamp of Sorrows · {zone:1444} Feralas
	["{zone:1435} and Dustwallow first, then {zone:1444}."] = "Primero {zone:1435} y Marjal Revolcafango, luego {zone:1444}.",
	["Takes you to level 47"] = "Te lleva al nivel 47",
	-- {zone:1446} Tanaris
	["Then on to {zone:1446}"] = "Después, a {zone:1446}",
	["Stays on the main route"] = "Sigue en la ruta principal",
	["Three zones, lots of travel"] = "Tres zonas, muchos viajes",

	-- Step 2: Zeppelin to Undercity
	-- {zone:1458} Undercity
	["Zeppelin to {zone:1458}"] = "Zepelín a {zone:1458}",

	-- Step 4: Undercity
	-- {npc:7825} Oran Snakewrithe · {object:36126} Royal Quarter
	["{npc:7825}, the {object:36126}"] = "{npc:7825}, {object:36126}",

	-- Step 5: Apothecary Zinge
	-- {item:8523} Field Testing Kit · {area:976} Gadgetzan
	["the {item:8523} from these errands: keep it, Tanaris Field Sampling hands it back in {area:976}"] = "{item:8523} de estos encargos: guárdalo, Muestreo de campo de Tanaris lo devuelve en {area:976}",

	-- Step 6: Riding at 40
	["Riding at 40"] = "Equitación a nivel 40",
	-- {npc:4773} Velma Warnam · {area:159} Brill · {npc:4731} Zachariah Post · {object:3202} Grom'gol
	["Riding needs level 40 and costs 100 gold; learning it gives you a mount. Each race learns it from its own race's trainer: yours is {npc:4773} in {area:159}, a short ride north of the zeppelin towers, with {npc:4731}'s skeletal horses (20 gold each) beside her. Ride back to the towers for the {object:3202} zeppelin."] = "La equitación requiere nivel 40 y cuesta 100 de oro; al aprenderla recibes una montura. Cada raza la aprende con el instructor de su propia raza: el tuyo es {npc:4773} en {area:159}, a poca distancia al norte de las torres de zepelín, con los caballos esqueléticos de {npc:4731} (20 de oro cada uno) a su lado. Vuelve a las torres para el zepelín a {object:3202}.",
	-- {npc:4773} Velma Warnam
	["{npc:4773}, riding trainer"] = "{npc:4773}, instructora de equitación",
	-- {npc:4731} Zachariah Post · {npc:4773} Velma Warnam · {area:159} Brill
	["Skeletal horses: {npc:4731}, beside {npc:4773} in {area:159}."] = "Caballos esqueléticos: {npc:4731}, junto a {npc:4773}, en {area:159}.",

	-- Step 7: Zeppelin to Grom'gol
	-- {object:3202} Grom'gol
	["Zeppelin to {object:3202}"] = "Zepelín a {object:3202}",

	-- Step 8: Fly to Stonard
	-- {area:75} Stonard
	["Fly to {area:75}"] = "Vuela a {area:75}",
	-- {object:3202} Grom'gol
	["{object:3202} flight master"] = "Maestro de vuelo de {object:3202}",

	-- Step 9: A Soggy Scroll
	["Ride west along the road; the scroll lies at the water's edge in the swamp's far west."] = "Cabalga hacia el oeste por el camino; el pergamino está a la orilla del agua, en el extremo oeste del pantano.",
	-- {object:2555} Musty Scroll · {zone:1445} Dustwallow Marsh
	["for the {object:2555} in {zone:1445}, later in this guide"] = "para {object:2555} en {zone:1445}, más adelante en esta guía",

	-- Step 10: To Pool of Tears
	-- {quest:1424} Pool of Tears
	["To {quest:1424}"] = "A {quest:1424}",

	-- Step 11: Pool of Tears
	-- {area:75} Stonard · {quest:1424} Pool of Tears
	["Back east past {area:75}: the Atal'ai artifacts lie in the water and on the banks of the {quest:1424}."] = "Vuelve al este pasando {area:75}: los artefactos Atal'ai están en el agua y en las orillas de {quest:1424}.",
	["Underwater"] = "Bajo el agua",

	-- Step 12: Misty Reed Post
	-- {npc:5592} Tok'Kar
	["Follow the road south-east to the small Horde post on the shore. {npc:5592} takes the crocolisk flanks from the last swamp visit."] = "Sigue el camino al sureste hasta el pequeño puesto de la Horda en la orilla. {npc:5592} recibe los flancos de crocolisco de la visita anterior al pantano.",

	-- Step 13: The Forbidding Sea: kill these as you meet them
	-- {area:2403} The Forbidding Sea
	["{area:2403}: kill these as you meet them"] = "{area:2403}: mata a estos según te los encuentres",
	["Careful: a Methuselah Crab (level 60) walks the south-east strand: give it a wide berth."] = "Cuidado: un Methuselah Crab (nivel 60) camina por la playa del sureste: no te le acerques.",

	-- Step 15: Murlocs of the Misty Reed
	["Murlocs of the Misty Reed"] = "Múrlocs de Juncobruma",
	-- plural, as words: Marsh Murlocs = {npc:747} Marsh Murloc
	["The Marsh Murlocs live on the strand south of the post; the Inkspewers are along the shore east of it and the Flesheaters further west, around the huts on the western shore."] = "Los Múrlocs del pantano viven en la playa al sur del puesto; los Vomitatintas están en la orilla al este y los Comecarnes más al oeste, alrededor de las chozas de la orilla oeste.",
	["Below ground"] = "Bajo tierra",

	-- Step 17: To Stonard
	-- {area:75} Stonard
	["To {area:75}"] = "A {area:75}",

	-- Step 18: Fly to Flame Crest
	-- {area:251} Flame Crest
	["Fly to {area:251}"] = "Vuela a {area:251}",
	-- {area:75} Stonard
	["{area:75} flight master"] = "Maestro de vuelo de {area:75}",

	-- Step 19: Into Redridge Mountains
	-- {zone:1433} Redridge Mountains
	["Into {zone:1433}"] = "Entra a {zone:1433}",

	-- Step 20: Into Duskwood
	-- {zone:1431} Duskwood
	["Into {zone:1431}"] = "Entra en {zone:1431}",

	-- Step 21: Into Deadwind Pass
	-- {zone:1430} Deadwind Pass
	["Into {zone:1430}"] = "Entra a {zone:1430}",

	-- Step 22: Into Swamp of Sorrows
	-- {zone:1435} Swamp of Sorrows
	["Into {zone:1435}"] = "Entra en {zone:1435}",

	-- Step 23: Into Blasted Lands
	-- {zone:1419} Blasted Lands
	["Into {zone:1419}"] = "Entra a {zone:1419}",

	-- Step 24: To Stagalbog
	-- {area:1797} Stagalbog
	["To {area:1797}"] = "A {area:1797}",

	-- Step 25: Stagalbog
	["The same murloc shore again: Inkspewers east of the post, Flesheaters around the western huts, and the Oracles among both."] = "La misma orilla de múrlocs otra vez: escupetintas al este del puesto, devoracarnes alrededor de las chozas del oeste y los oráculos entre ambos.",

	-- Step 27: Into Riverglades
	-- {zone:2548} Riverglades
	["Into {zone:2548}"] = "Entra a {zone:2548}",
	-- {zone:2548} Riverglades · {area:16737} Bristle Hills
	["{zone:2548} is reached on foot through Redridge Pass, south of the {area:16737}."] = "{zone:2548} se llega a pie por Redridge Pass, al sur de {area:16737}.",

	-- Step 28: To Powderfuse Port
	-- {area:16727} Powderfuse Port
	["To {area:16727}"] = "A {area:16727}",

	-- Step 29: To Rog'mar
	-- {area:16743} Rog'mar
	["To {area:16743}"] = "A {area:16743}",

	-- Step 30: Fly to Stonard
	-- {area:16743} Rog'mar
	["{area:16743} flight master"] = "Maestro de vuelo de {area:16743}",

	-- Step 31: To Misty Reed Strand
	-- {area:300} Misty Reed Strand
	["To {area:300}"] = "Hacia {area:300}",

	-- Step 33: Stonard
	-- {npc:1443} Fel'zerul
	["{npc:1443}, on the top floor"] = "{npc:1443}, en el piso superior",
	-- {npc:5598} Atal'ai Exile · {zone:1425} Hinterlands
	["for the {npc:5598} in the {zone:1425}, around level 48"] = "para {npc:5598} en {zone:1425}, hacia el nivel 48",
	-- {npc:5591} Dar
	["{npc:5591}, inside"] = "{npc:5591}, adentro",

	-- Step 34: To Camp Mojache
	-- {area:1099} Camp Mojache
	["To {area:1099}"] = "Hacia {area:1099}",

	-- Step 36: Camp Mojache
	-- {zone:1425} Hinterlands
	["for the {zone:1425} owlbeasts, around level 48"] = "para las lechubestias de {zone:1425}, hacia el nivel 48",

	-- Step 37: Fly to Brackenwall Village
	-- {area:496} Brackenwall Village
	["Fly to {area:496}"] = "Vuela a {area:496}",
	-- {area:1099} Camp Mojache
	["{area:1099} flight master"] = "Maestro de vuelo de {area:1099}",

	-- Step 38: To Brackenwall Village
	-- {area:496} Brackenwall Village
	["To {area:496}"] = "Hacia {area:496}",

	-- Step 39: Brackenwall Village
	-- {npc:4500} Overlord Mok'Morokk · {npc:4502} Tharg · {npc:4501} Draz'Zilb · {area:511} Wyrmbog
	["{npc:4500}, {npc:4502} and {npc:4501} (below ground) are in the village; their quests are for the {area:511} on this trip."] = "{npc:4500}, {npc:4502} y {npc:4501} (bajo tierra) están en la aldea; sus misiones son para {area:511} en este viaje.",
	-- {npc:4501} Draz'Zilb
	["{npc:4501}, below ground"] = "{npc:4501}, bajo tierra",

	-- Step 41: The Dragonmurk: kill these as you meet them
	-- {area:510} The Dragonmurk
	["{area:510}: kill these as you meet them"] = "{area:510}: mata a estos según te los encuentres",
	-- {area:511} Wyrmbog · {npc:4331} Firemane Ash Tail · {npc:4328} Firemane Scalebane · {npc:4329} Firemane Scout
	["East through the {area:511}: the Firemane scouts and ash tails roam its northern edge with the Searing hatchlings and whelps; the scalebanes guard the dragon caves further south-east. Mok'Morokk's snuff, grog and strongbox lie in the dragonkin camps.\n{npc:4331} is elite: grouping up is advised.\n{npc:4328} is elite: grouping up is advised.\n{npc:4329} is elite: grouping up is advised."] = "Al este por {area:511}: los exploradores Crin de Fuego y los colas de ceniza recorren su borde norte junto con las crías y vástagos Abrasadores; los Scalebane guardan las cuevas de dragones más al sureste. El rapé, el grog y el cofre de Mok'Morokk están en los campamentos de dragonantes.\\n{npc:4331} es élite: se recomienda agruparse.\\n{npc:4328} es élite: se recomienda agruparse.\\n{npc:4329} es élite: se recomienda agruparse.",

	-- Step 42: The Dragonmurk: kill these as you meet them
	-- {npc:4329} Firemane Scout · {npc:4331} Firemane Ash Tail
	["These are elite mobs: grouping up is encouraged, look for people to do it with. {npc:4329}, {npc:4331} and others (level 44 elites) need a group of 4. Skip it if you are alone: the route has you grind the XP back."] = "Son enemigos élite: se recomienda agruparse, busca gente para hacerlo. {npc:4329}, {npc:4331} y otros (élites de nivel 44) necesitan un grupo de 4. Omítelos si estás solo: la ruta te hace recuperar la experiencia.",
	-- {npc:4329} Firemane Scout · {area:510} The Dragonmurk
	["{npc:4329} walks around {area:510}: look inside the circle on the map"] = "{npc:4329} da vueltas por {area:510}: búscalo dentro del círculo del mapa",

	-- Step 43: The Musty Scroll
	-- {object:2555} Musty Scroll
	-- was: ["the {object:2555}"] = "{object:2555}"
	["The {object:2555}"] = "{object:2555}",
	-- {object:2555} Musty Scroll
	["Ride south-west to the {object:2555}."] = "Ve al suroeste hasta {object:2555}.",
	-- {object:2555} Musty Scroll · {area:498} Bloodfen Burrow
	["the {object:2555}; inside {area:498}"] = "el {object:2555}; dentro de {area:498}",
	-- {area:498} Bloodfen Burrow
	["Inside {area:498}"] = "Dentro de {area:498}",

	-- Step 44: Brackenwall Village
	["Ride back north to Brackenwall."] = "Vuelve cabalgando al norte, a Murohelecho.",

	-- Step 46: Level 45.29
	["Level 45.29"] = "Nivel 45.29",
	-- {quest:1168} Army of the Black Dragon · {area:978} Zul'Farrak · {zone:1446} Tanaris
	["If you skipped {quest:1168}, grind here to level 45.29 to stay on the route's plan. With a group, the {area:978} run in the next guide, in {zone:1446}, makes up the difference."] = "Si omitiste {quest:1168}, sube de nivel aquí hasta el nivel 45.29 para seguir el plan de la ruta. En grupo, la mazmorra {area:978} de la siguiente guía, en {zone:1446}, compensa la diferencia.",
	-- {npc:4323} Searing Hatchling
	["grind on {npc:4323}"] = "farmea con {npc:4323}",

	-- Step 47: Onyxia's eggs
	["Onyxia's eggs"] = "Huevos de Onyxia",
	-- {area:511} Wyrmbog
	["The Eggs of Onyxia lie in the dragon caves in the {area:511}'s south-east, guarded by the scalebanes; smash five."] = "Los Huevos de Onyxia están en las cuevas de dragones del sureste de {area:511}, guardados por los Horrocrustos; destroza cinco.",
	["Dragon caves"] = "Cuevas de dragones",

	-- Step 48: Level 45.37
	["Level 45.37"] = "Nivel 45.37",
	-- {npc:4500} Overlord Mok'Morokk · {area:511} Wyrmbog · {area:978} Zul'Farrak
	["{npc:4500}'s challenge, back in Brackenwall, needs a group of three. Alone, grind the Firemane scouts here on the {area:511}'s northern edge to level 45.37 before you ride back north, so you don't come back down for it. Or, with a group, run the {area:978} dungeon instead."] = "El desafío de {npc:4500}, de vuelta en Murohelecho, requiere un grupo de tres. Si vas solo, mata Exploradores Pirocabello aquí, en el borde norte de {area:511}, hasta el nivel 45.37 antes de volver cabalgando al norte, para no tener que bajar otra vez a por ello. O bien, con un grupo, haz en su lugar la mazmorra de {area:978}.",
	-- {npc:4329} Firemane Scout
	["grind on {npc:4329}"] = "sube de nivel con {npc:4329}",

	-- Step 50: Challenge Overlord Mok'Morokk
	-- {quest:1173} Challenge Overlord Mok'Morokk · {npc:4500} Overlord Mok'Morokk · {npc:4501} Draz'Zilb
	["These are elite mobs: grouping up is encouraged, look for people to do it with. {quest:1173} needs a group of 3. Skip it if you are alone: the route has you grind the XP back.\n{npc:4500} is elite: grouping up is advised. Beat him down until he gives up, then report to {npc:4501}."] = "Son enemigos élite: se recomienda agruparse, busca gente para hacerlo. {quest:1173} necesita un grupo de 3. Omítela si estás solo: la ruta te hace recuperar esa experiencia matando enemigos.\n{npc:4500} es élite: se recomienda agruparse. Golpéalo hasta que se rinda y luego informa a {npc:4501}.",

	-- Step 51: Fly to Camp Mojache
	-- {area:1099} Camp Mojache
	["Fly to {area:1099}"] = "Vuela a {area:1099}",
	-- {area:496} Brackenwall Village
	["{area:496} flight master"] = "Maestro de vuelo de {area:496}",

	-- Step 52: Sprite darters and forest walkers
	["Sprite darters and forest walkers"] = "Duendes dardo y Caminabosques",
	["Careful: a Vale Screamer (level 60) flies over the forest west of the camp: keep clear of it."] = "Cuidado: un Vale Screamer (nivel 60) vuela sobre el bosque al oeste del campamento: mantente lejos de él.",

	-- Step 53: Frayfeather hippogryphs
	["Frayfeather hippogryphs"] = "Hipogrifos Plumavieja",
	["South of the vale the Frayfeather hippogryphs roost on the slopes; nearly every one drops sinew and metallic fragments."] = "Al sur del valle, los Hipogrifos Plumavieja anidan en las laderas; casi todos sueltan tendones y fragmentos metálicos.",

	-- Step 54: Zorbin Fandazzle
	-- {area:1108} Forgotten Coast · {npc:14637} Zorbin Fandazzle
	["Ride north-west to the {area:1108}; {npc:14637} waits on the dock."] = "Cabalga hacia el noroeste hasta {area:1108}; {npc:14637} espera en el muelle.",

	-- Step 55: Rogue Vale screechers
	["Rogue Vale screechers"] = "Pícaros estridadores del valle",
	-- {npc:14637} Zorbin Fandazzle · {npc:5308} Rogue Vale Screecher · {item:10699} Yeh'kinya's Bramble
	["Rogue Vale opens just north of {npc:14637}'s dock. Kill a {npc:5308}, use {item:10699} on its body before you loot it, then talk to the spirit that rises: it is friendly. Three spirits in all."] = "Rogue Vale se abre justo al norte del muelle de {npc:14637}. Mata a un {npc:5308}, usa {item:10699} sobre su cuerpo antes de despojarlo y luego habla con el espíritu que se alza: es amistoso. Son tres espíritus en total.",

	-- Step 56: Forgotten Coast: kill these as you meet them
	-- {area:1108} Forgotten Coast
	["{area:1108}: kill these as you meet them"] = "{area:1108}: mata a estos según te los encuentres",
	-- {item:18904} Zorbin's Ultra-Shrinker · {zone:1444} Feralas · {npc:14637} Zorbin Fandazzle
	-- plural, as words: Sea Sprays = {npc:5462} Sea Spray · Water Elemental Cores = {item:18958} Water Elemental Core · Sea Elementals = {npc:5461} Sea Elemental · Deep Striders = {npc:5360} Deep Strider · Land Walkers = {npc:5357} Land Walker · Cliff Giants = {npc:5358} Cliff Giant
	["The Sea Sprays (47-48) wash along the shore just south of the dock: they drop the Water Elemental Cores as well as the Sea Elementals (48-49) do. The Wave and Deep Striders (47-49) wade in the water off the same beach: zap them with {item:18904} first, and shrunken they lose their elite strength. Leave the Land Walkers and Cliff Giants (48-50) of the northern hills for your next {zone:1444} visit.\nThe Ultra-Shrinker lasts two hours: hand both quests back to {npc:14637} before you leave the coast."] = "Los Rocíos marinos (47-48) recorren la orilla justo al sur del muelle: sueltan Núcleos elementales de Agua igual que los Elementales marinos (48-49). Los Zancaolas y Zancaprofundas (47-49) vadean el agua frente a la misma playa: dispárales primero con el {item:18904} y, encogidos, pierden su fuerza de élite. Deja los Caminantes de la tierra y Gigantes del risco (48-50) de las colinas del norte para tu próxima visita a {zone:1444}.\nEl Ultra-reductor dura dos horas: entrega ambas misiones a {npc:14637} antes de dejar la costa.",
	-- {item:18904} Zorbin's Ultra-Shrinker
	-- plural, as words: Deep Striders = {npc:5360} Deep Strider
	["{item:18904}, on the Wave and Deep Striders in the water"] = "{item:18904}, sobre los Zancaolas y Zancaprofundas del agua",

	-- Step 57: Zorbin Fandazzle
	-- {npc:14637} Zorbin Fandazzle
	["Back to {npc:14637} on the dock."] = "Vuelve con {npc:14637}, en el muelle.",

	-- Step 58: Rage Scar yetis
	["Rage Scar yetis"] = "Yetis Estigmodio",
	-- {quest:7738} Perfect Yeti Hide
	["On the way back south-east from the coast, the Rage Scar yetis live around the caves in the hills by the road. Any of them can also drop a {quest:7738}, which starts a quest of its own."] = "De vuelta al sureste desde la costa, los Yetis Estigmodio viven alrededor de las cuevas de las colinas junto al camino. Cualquiera puede soltar también un {quest:7738}, que inicia su propia misión.",
	-- {quest:7738} Perfect Yeti Hide
	["{quest:7738}, a rare drop"] = "{quest:7738}, botín raro",

	-- Step 59: Camp Mojache
	-- {npc:7854} Jangdor Swiftstrider
	["{npc:7854}, inside"] = "{npc:7854}, adentro",
	-- {zone:1444} Feralas
	-- was: ["{npc:7776}'s Northspring harpies (48-50) wait for your {zone:1444} visit at about 51: keep the quest."] = "Las arpías Fuenteboreal (48-50) de {npc:7776} esperan a tu visita a {zone:1444} hacia el nivel 51: conserva la misión."
	["Talo's Northspring harpies (48-50) wait for your {zone:1444} visit at about 51: keep the quest."] = "Las arpías Northspring (48-50) de Talo esperan tu visita a {zone:1444} hacia el nivel 51: conserva la misión.",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["Fly to {object:3202}"] = "Vuela a {object:3202}",
	-- ["Forest walkers"] = "Caminabosques",
	-- ["From the flight master: the {object:172960}, then the Drag, then the {object:172958}."] = "Desde el maestro de vuelo: el {object:172960}, luego la Calle Mayor y después el {object:172958}.",
	-- ["Hearth to {area:1099}: your hearthstone is still bound there from the {zone:1444} & {zone:1446} guide."] = "Usa la piedra de hogar para ir a {area:1099}: sigue vinculada allí desde la guía de {zone:1444} y {zone:1446}.",
	-- ["Monstrous Crawlers"] = "Reptadores monstruosos",
	-- ["Murlocs of the Misty Reed"] = "Múrlocs de Juncobruma",
	-- ["No flight path to {area:75} yet (the {zone:2548} skip the {zone:1435}): ride north-east from {object:3202} through {zone:1431} and {zone:1430} into the swamp, then east along the road to {area:75}, and learn its flight path."] = "Aún no tienes la ruta de vuelo a {area:75} ({zone:2548} se saltan {zone:1435}): cabalga al noreste desde {object:3202} por {zone:1431} y {zone:1430} hasta el pantano; luego al este por el camino hasta {area:75}, y aprende su ruta de vuelo.",
	-- ["Northspring harpies"] = "Arpías Nortearroyo",
	-- ["On the way back south-east from the harpies, the Rage Scar yetis live around the caves in the hills by the road. Any of them can also drop a {quest:7738}, which starts a quest of its own."] = "De vuelta al sureste desde las arpías, los Yetis Estigmodio viven alrededor de las cuevas de las colinas junto al camino. Cualquiera puede soltar también una {quest:7738}, que inicia su propia misión.",
	-- ["Ride back east to the camp. Stay here: the next guide starts with the flight to {area:976}."] = "Vuelve cabalgando al este hasta el campamento. Quédate aquí: la siguiente guía empieza con el vuelo a {area:976}.",
	-- ["Ride south-west to the {object:2555}, then east through the {area:511}. The Firemane scouts and ash tails roam its northern edge with the Searing hatchlings and whelps; the scalebanes guard the dragon caves further south-east. Mok'Morokk's snuff, grog and strongbox lie in the dragonkin camps."] = "Cabalga hacia el suroeste hasta {object:2555} y luego al este por {area:511}. Los Exploradores y Ceniazotes Pirocabello recorren su borde norte con las Proles y Crías abrasadoras; los Horrocrustos guardan las cuevas de dragones más al sureste. El rapé, el grog y la caja fuerte de Mok'Morokk están en los campamentos de los dragonantes.",
	-- ["Sawtooth crocolisks"] = "Crocoliscos Denteserra",
	-- ["Sea elementals and sea sprays wash along the shore around the dock. Zap the giants with {item:18904} first: shrunken, they lose their elite strength. Shore striders wade in the water; the land walkers and cliff giants roam the hills further north."] = "Elementales marinos y Rocíos del mar recorren la orilla alrededor del muelle. Dispara primero a los gigantes con {item:18904}: encogidos, pierden su fuerza de élite. Los Zancacostas vadean en el agua; los Caminantes de la tierra y los Gigantes del risco recorren las colinas más al norte.",
	-- ["South-west, the yetis den in {area:1105}; every yeti there can drop a thick hide."] = "Al suroeste, los yetis tienen su guarida en {area:1105}; cualquier yeti de allí puede soltar una piel gruesa.",
	-- ["The Marsh Murlocs live on the strand south of the post; the Inkspewers are along the shore east of it and the Flesheaters further west, around the huts on the western shore."] = "Los Múrlocs del pantano viven en la playa al sur del puesto; los Vomitatintas están en la orilla al este y los Comecarnes más al oeste, alrededor de las chozas de la orilla oeste.",
	-- ["The Monstrous Crawlers walk the beaches of the east coast, few and far between: kill every one you see on the way south."] = "Los Reptadores monstruosos recorren las playas de la costa este, pocos y dispersos: mata a todos los que veas de camino al sur.",
	-- ["The Northspring harpies nest on the ridges in the far north-west. They are 48-50, a few levels above you: the Windcallers heal, so kill them first and pull one at a time."] = "Las Arpías Nortearroyo anidan en las crestas del extremo noroeste. Son de nivel 48-50, unos niveles por encima de ti: las Clamavientos curan, así que mátalas primero y atráelas de una en una.",
	-- ["The same murlocs again, plus the Oracles, who stay near the huts on the western shore."] = "Los mismos múrlocs otra vez, más los Oráculos, que se quedan cerca de las chozas de la orilla oeste.",
	-- ["The small Horde post on the southern shore."] = "El pequeño puesto de la Horda en la orilla sur.",
	-- ["The sprite darters flit over the grove just west of the camp and carry the {item:9589}; the Wandering Forest Walkers, a little further west, carry the Splintered Logs.\nCareful: a {npc:272401} (level 60) flies over the forest west of the camp: keep clear of it."] = "Los duendes dardo revolotean sobre la arboleda justo al oeste del campamento y llevan los {item:9589}; los Caminabosques deambulantes, un poco más al oeste, llevan los Troncos astillados.\nCuidado: un {npc:272401} (nivel 60) sobrevuela el bosque al oeste del campamento: no te acerques a él.",
	-- ["The zeppelin lands at {object:3202}: Stranglethorn's errands are done (40-50/02), so fly straight on to {area:75}."] = "El zepelín aterriza en {object:3202}: los encargos de Tuercespina ya están hechos (40-50/02), así que vuela directamente a {area:75}.",
	-- ["The zeppelin to {zone:1454} leaves from the tower beside {object:3202}; it lands just north-east of {zone:1454}'s main gate."] = "El zepelín a {zone:1454} sale de la torre junto a {object:3202}; aterriza justo al noreste de la puerta principal de {zone:1454}.",
	-- ["The {area:1108}"] = "{area:1108}",
	-- ["The {area:511}"] = "{area:511}",
	-- ["You start in {area:75}. Bind here: you hearth back after the coast."] = "Empiezas en {area:75}. Vincula aquí tu Piedra de hogar: volverás con ella después de la costa.",
	-- ["Your trainer is in {area:1638}: fly there (no flight path there yet? fly to {area:378} and ride west through {zone:1412}), then on to {area:496}."] = "Tu instructor está en {area:1638}: vuela allí (¿aún no tienes esa ruta de vuelo? vuela a {area:378} y cabalga hacia el oeste por {zone:1412}) y luego sigue hasta {area:496}.",
	-- ["Zeppelin to {zone:1454}"] = "Zepelín a {zone:1454}",
	-- ["Zeppelin tower"] = "Torre del zepelín",
	-- ["for the {object:2555} in {area:15}, later in this guide"] = "para {object:2555} en {area:15}, más adelante en esta guía",
	-- ["for the {zone:1425}, around level 50"] = "para {zone:1425}, hacia el nivel 50",
	-- ["the {object:2555}"] = "{object:2555}",
	-- ["{item:18958}, from the Sea Sprays"] = "{item:18958}, de los Rocíos marinos",
	-- ["{npc:2934}, on the way back to Zinge"] = "{npc:2934}, de camino de vuelta a Zinge",
	-- ["{npc:4500} is elite: grouping up is advised. Beat him down until he gives up, then report to {npc:4501}."] = "{npc:4500} es élite: se recomienda ir en grupo. Golpéalo hasta que se rinda y luego informa a {npc:4501}.",
	-- ["{npc:6986}, the Drag"] = "{npc:6986}, La Calle Mayor",
	-- ["{npc:7010}, the Drag"] = "{npc:7010}, La Calada",
	-- ["{npc:7776}'s Northspring harpies (48-50) wait for your {zone:1444} visit at about 51: keep the quest."] = "Las arpías Fuenteboreal (48-50) de {npc:7776} esperan a tu visita a {zone:1444} hacia el nivel 51: conserva la misión.",
	-- ["{npc:7875}: for {npc:7010} in {zone:1454}, around level 50"] = "{npc:7875}: para {npc:7010} en {zone:1454}, hacia el nivel 50",
	-- ["{object:172958}, then the {object:172960} and the {object:172961}."] = "{object:172958}, luego {object:172960} y {object:172961}.",
}
