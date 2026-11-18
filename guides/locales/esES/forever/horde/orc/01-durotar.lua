-- Spanish (Spain) (esES): the guide forever/horde/orc/01-durotar (forever/horde/orc/01-durotar.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: Kaltunk
	-- {npc:10176} Kaltunk
	["{npc:10176}, where you start"] = "{npc:10176}, donde empiezas",

	-- Step 2: Gornek
	-- {npc:3143} Gornek · {npc:10176} Kaltunk
	["{npc:3143} waits inside the Den, the building just west of {npc:10176}."] = "{npc:3143} espera dentro de El Cubil, el edificio justo al oeste de {npc:10176}.",
	["Inside"] = "Adentro",

	-- Step 3: Training weapons and boars
	["Training weapons and boars"] = "Armas de entrenamiento y jabalíes",
	-- plural, as words: Mottled Boars = {npc:3098} Mottled Boar
	["The weapons lie around the Den and the training grounds; the Mottled Boars roam the whole valley floor."] = "Las armas están alrededor de El Cubil y del campo de entrenamiento; los jabalíes jaspeados recorren todo el fondo del valle.",

	-- Step 4: The Den
	-- {npc:3143} Gornek · {npc:3159} Kzan Thornslash
	["{npc:3143} stands just inside the cave mouth; {npc:3159} at the back of the cave behind him."] = "{npc:3143} está nada más entrar en la cueva; {npc:3159}, al fondo de la cueva, detrás de él.",
	-- {npc:3143} Gornek
	["{npc:3143}, inside"] = "{npc:3143}, adentro",
	-- {npc:3156} Nartok
	["{npc:3156}, the warlock trainer at the back of the cave"] = "{npc:3156}, el instructor de brujos, al fondo de la cueva",
	-- {npc:3155} Rwag
	["{npc:3155}, the rogue trainer in the Den"] = "{npc:3155}, el instructor de pícaros, en El Cubil",
	-- {npc:3153} Frang
	["{npc:3153}, the warrior trainer beside the Den"] = "{npc:3153}, el instructor de guerreros, junto a El Cubil",
	-- {npc:3154} Jen'shan
	["{npc:3154}, the hunter trainer beside the Den"] = "{npc:3154}, el instructor de cazadores, junto a El Cubil",
	-- {npc:3157} Shikrik
	["{npc:3157}, the shaman trainer beside the Den"] = "{npc:3157}, el instructor de chamanes, junto a El Cubil",
	-- {npc:5884} Mai'ah
	["{npc:5884}, the mage trainer, at the entrance to the Den"] = "{npc:5884}, la instructora de magos, en la entrada de El Cubil",
	-- {npc:3159} Kzan Thornslash
	["{npc:3159}, at the back of the cave; below ground"] = "{npc:3159}, al fondo de la cueva; bajo tierra",
	-- {npc:9796} Galgar
	["{npc:9796}, by the cooking fire"] = "{npc:9796}, junto al fuego de cocina",

	-- Step 5: Hana'zua
	-- {npc:3287} Hana'zua
	["{npc:3287} lies wounded at the foot of the hills north-west of the Den."] = "{npc:3287} yace herido al pie de las colinas, al noroeste de El Cubil.",

	-- Step 6: Valley of Trials: kill these as you meet them
	-- {area:363} Valley of Trials
	["{area:363}: kill these as you meet them"] = "{area:363}: mata a estos según te los encuentres",
	-- {npc:3287} Hana'zua · {quest:792} Vile Familiars · {area:365} Burning Blade Coven
	-- plural, as words: Scorpid Workers = {npc:3124} Scorpid Worker · Cactus Apples = {item:11583} Cactus Apple
	["The Scorpid Workers roam the slope south of {npc:3287}; pick the Cactus Apples by the cactuses on the way.\nThe {quest:792} swarm the slope below the {area:365}, the cave on the valley's north side."] = "Los trabajadores escórpidos recorren la ladera al sur de {npc:3287}; recoge las manzanas de cactus junto a los cactus por el camino.\nLos {quest:792} abundan en la ladera bajo {area:365}, la cueva del lado norte del valle.",

	-- Step 7: Galgar
	-- {npc:9796} Galgar
	["{npc:9796} stands just outside the Den's entrance."] = "{npc:9796} está justo afuera de la entrada de la Guarida.",
	-- {npc:11378} Foreman Thazz'ril
	["{npc:11378}, at the lumber pile east of the Den"] = "{npc:11378}, en la pila de madera al este de la Guarida",

	-- Step 8: Lazy Peons
	["The peons doze around the Den, east and south of it."] = "Los peones dormitan alrededor de la Guarida, al este y al sur de ella.",
	-- {quest:5441} Lazy Peons · {item:16114} Foreman's Blackjack
	["Wake {quest:5441} with the {item:16114}"] = "Despierta a los {quest:5441} con {item:16114}",

	-- Step 10: Sarkoth
	-- {quest:790} Sarkoth · {npc:3287} Hana'zua · {area:365} Burning Blade Coven
	["{quest:790}, a large scorpid (level 4), prowls the slope just west of the Den, below {npc:3287}, on the way north to the {area:365}."] = "{quest:790}, un gran escórpido (nivel 4), merodea por la ladera justo al oeste de la Guarida, bajo {npc:3287}, de camino al norte hacia {area:365}.",

	-- Step 13: Thazz'ril's Pick
	["Inside the cave, go straight on at the first split, then right and follow the stream on your left to the waterfall: the pick glows by the water, behind a column of rock."] = "Dentro de la cueva, sigue recto en la primera bifurcación, luego a la derecha, y sigue el arroyo que tienes a la izquierda hasta la cascada: el pico brilla junto al agua, detrás de una columna de roca.",

	-- Step 14: Yarrog Baneshadow
	-- {npc:3183} Yarrog Baneshadow
	["Inside the cave, keep to the right wall all the way round, over the stream: {npc:3183} waits at the end."] = "Dentro de la cueva, sigue la pared derecha durante todo el recorrido, cruzando el arroyo: {npc:3183} espera al final.",
	["Below ground"] = "Bajo tierra",

	-- Step 15: Felstalker hooves
	-- {npc:3102} Felstalker
	["{npc:3102} hooves"] = "Pezuñas de {npc:3102}",
	-- plural, as words: Felstalkers = {npc:3102} Felstalker
	["Felstalkers roam the slope below the cave, on the valley's north side."] = "Los acechadores viles recorren la ladera bajo la cueva, en el lado norte del valle.",

	-- Step 17: Zureetha Fargaze
	-- {item:275022} Lost Journal
	-- was: ["the {object:654925} on the ground beside her"] = "{object:654925}, en el suelo a su lado"
	["the {item:275022} on the ground beside her"] = "{item:275022}, en el suelo a su lado",

	-- Step 18: Call of Earth
	-- {npc:5887} Canaga Earthcaller · {area:639} Spirit Rock · {item:6635} Earth Sapta · {npc:5891} Minor Manifestation of Earth · {item:6656} Rough Quartz
	["{npc:5887} stands outside the Den. {area:639} is the hill just south of it: drink the {item:6635} there to see the {npc:5891}, then take the {item:6656} back to {npc:5887}."] = "{npc:5887} está fuera de El Cubil. {area:639} es la colina justo al sur: bebe {item:6635} allí para ver a {npc:5891} y lleva {item:6656} a {npc:5887}.",
	-- {npc:5891} Minor Manifestation of Earth · {area:639} Spirit Rock
	["{npc:5891}, on {area:639}"] = "{npc:5891}, en {area:639}",
	-- {npc:5887} Canaga Earthcaller · {npc:5873} Stoneskin Totem · {item:5175} Earth Totem
	["{npc:5887}: {npc:5873} and your {item:5175}"] = "{npc:5887}: {npc:5873} y tu {item:5175}",

	-- Step 19: Ukor
	-- {npc:6786} Ukor
	["{npc:6786} stands on the road at the valley's eastern exit."] = "{npc:6786} está en el camino, en la salida este del valle.",

	-- Step 20: Sen'jin Village
	-- {area:367} Sen'jin Village
	["Follow the road east out of the valley to {area:367} on the coast."] = "Sigue el camino al este, fuera del valle, hasta {area:367}, en la costa.",
	-- {npc:5880} Un'Thuwa
	["{npc:5880}, the mage trainer in Sen'jin"] = "{npc:5880}, el instructor de magos en Sen'jin",
	-- {npc:3140} Lar Prowltusk · {area:367} Sen'jin Village
	["{npc:3140}: he offers it at level 5, on this first stop (11 recorded windows); walks around {area:367}: the map marks where to look"] = "{npc:3140}: la ofrece a nivel 5, en esta primera parada (11 ventanas registradas); anda por {area:367}: el mapa marca dónde buscar",

	-- Step 21: Ridgeshade spiders
	["Ridgeshade spiders"] = "Arañas Ridgeshade",
	-- {area:362} Razor Hill
	["Careful: Ukorsbane (8) is elite and walks among the Ridgeshade spiders in the camp south of {area:362}: pull the spiders away from him."] = "Cuidado: Ukorsbane (8) es élite y anda entre las arañas Sombracresta en el campamento al sur de {area:362}: atrae a las arañas lejos de él.",

	-- Step 22: Razor Hill
	-- {npc:3147} Furl Scornbrow
	["{npc:3147}, in the watchtower"] = "{npc:3147}, en la atalaya",

	-- Step 23: Brakk's campfire
	-- {npc:265809} Brakk
	["{npc:265809}'s campfire"] = "La hoguera de {npc:265809}",
	-- {npc:265809} Brakk · {area:362} Razor Hill · {spell:1229451} Boosted Rest · {zone:1454} Orgrimmar
	["{npc:265809} camps just south of {area:362}. Sit by his campfire (/sit) until the {spell:1229451} buff appears. With a profession learned, {npc:265809} also offers its Camping 101, which its trainer takes: in {area:362} or in {zone:1454} at the start of the next guide."] = "{npc:265809} acampa justo al sur de {area:362}. Siéntate junto a su hoguera (/sit) hasta que aparezca el beneficio {spell:1229451}. Con una profesión aprendida, {npc:265809} también ofrece su Acampada 101, que recoge su instructor: en {area:362} o en {zone:1454}, al principio de la siguiente guía.",

	-- Step 24: Razor Hill
	-- {npc:266940} Turroc
	["{npc:266940}, on the east side of town; inside"] = "{npc:266940}, en el lado este del pueblo; adentro",
	-- {npc:3191} Cook Torka
	["{npc:3191}: Camping 101 asks you to learn it"] = "{npc:3191}: Campamento 101 te pide aprenderla",

	-- Step 26: Tiragarde Keep
	-- {area:362} Razor Hill · {item:4870} Canvas Scraps
	["The keep stands on the coast south-east of {area:362}. The raiders' axe, bow and shield lie on its outskirts. Sailors and marines drop the {item:4870}."] = "El fuerte está en la costa, al sureste de {area:362}. El hacha, el arco y el escudo de asaltante están en sus alrededores. Los marineros y los soldados de marina sueltan {item:4870}.",

	-- Step 27: Lieutenant Benedict
	-- {npc:3192} Lieutenant Benedict · {item:4881} Aged Envelope
	["{npc:3192} waits at the top of the keep; his key opens the chest beside him, which holds the {item:4881}."] = "{npc:3192} espera en lo alto del fuerte; su llave abre el cofre que tiene al lado, que contiene {item:4881}.",
	["Upstairs"] = "Arriba",

	-- Step 28: Class trainer
	["Class trainer"] = "Instructor de clase",

	-- Step 29: Canvas Scraps on the way
	-- {item:4870} Canvas Scraps
	["{item:4870} on the way"] = "{item:4870} en el camino",
	-- {item:4870} Canvas Scraps · {area:362} Razor Hill
	["{item:4870} along the way to {area:362}"] = "{item:4870} de camino a {area:362}",

	-- Step 30: Level 7
	["Level 7"] = "Nivel 7",
	-- {npc:3192} Lieutenant Benedict
	["Top up here to level 7 before {npc:3192} (8) and the marines at the top of the keep."] = "Sube aquí hasta el nivel 7 antes de enfrentarte a {npc:3192} (8) y a los soldados de marina de lo alto del fuerte.",
	-- {npc:3128} Kul Tiras Sailor
	["grind on {npc:3128}"] = "mata {npc:3128}",

	-- Step 32: Razor Hill
	-- {npc:266940} Turroc
	["{npc:266940}, inside"] = "{npc:266940}, adentro",

	-- Step 33: The wreckage
	["The wreckage"] = "Los restos del naufragio",
	-- {area:362} Razor Hill
	["The gnomish toolboxes lie in the wreckage along the shore east and south-east of {area:362}. Follow the shore south to Sen'jin."] = "Las cajas de herramientas gnómicas están entre los restos del naufragio a lo largo de la costa, al este y al sureste de {area:362}. Sigue la costa hacia el sur hasta Sen'jin.",
	["Underwater"] = "Bajo el agua",

	-- Step 34: Sen'jin Village
	-- {npc:266881} Pa'zula
	["{npc:266881}: enchanters only, the residue is disenchanted from Hexed Pendants"] = "{npc:266881}: solo encantadores; el residuo se obtiene desencantando colgantes embrujados",

	-- Step 35: Makrura and crawlers
	["Makrura and crawlers"] = "Makrura y reptadores",
	["Makrura and surf crawlers line the beaches north-east of Sen'jin."] = "Los makrura y los cangrejos de oleaje pueblan las playas al noreste de Sen'jin.",

	-- Step 37: Kolkar Crag
	-- {area:366} Kolkar Crag · {npc:275811} Pal'juh
	["{area:366} lies west of Sen'jin. The three attack plans sit on the ground among the centaur tents. {npc:275811} is held at the crag as well."] = "{area:366} está al oeste del poblado Sen'jin. Los tres planes de ataque están en el suelo entre las tiendas de los centauros. {npc:275811} también está presa en el risco.",
	-- {npc:275811} Pal'juh
	["Free {npc:275811} and see her safely out of the crag"] = "Libera a {npc:275811} y sácala sana y salva del risco",

	-- Step 38: Sen'jin Village
	-- {npc:3140} Lar Prowltusk · {area:367} Sen'jin Village
	["{npc:3140} walks around {area:367}: the map marks where to look"] = "{npc:3140} anda por {area:367}: el mapa marca dónde buscar",

	-- Step 39: South-east shore
	["South-east shore"] = "Costa sureste",
	-- plural, as words: Durotar Tigers = {npc:3121} Durotar Tiger
	["Durotar Tigers roam the isle as well as the shore south of Sen'jin, and the Taillasher eggs sit in nests on the isles and along the beach."] = "Los tigres de Durotar merodean por la isla y por la orilla al sur de Sen'jin, y los huevos de Taillasher están en nidos en las islas y a lo largo de la playa.",

	-- Step 40: Bloodtalon Matriarch
	["Wade across to the northern Echo Isle. The Matriarch prowls among the raptors there."] = "Cruza vadeando hasta la isla norte de las Islas del Eco. La Matriarca merodea entre los raptores de allí.",

	-- Step 41: Level 9
	["Level 9"] = "Nivel 9",
	-- {quest:826} Zalazane
	-- plural, as words: Hexed Trolls = {npc:3207} Hexed Troll
	["Top up here to level 9 before the southern isles: the Voodoo and Hexed Trolls there are 8-9 and {quest:826} is 10."] = "Sube aquí hasta el nivel 9 antes de las islas del sur: los trols vudú y los trols embrujados de allí son de nivel 8-9 y {quest:826} es de nivel 10.",
	-- {npc:3121} Durotar Tiger
	["grind on {npc:3121}"] = "mata {npc:3121}",

	-- Step 42: Echo Isles
	-- {quest:826} Zalazane
	-- plural, as words: Hexed Trolls = {npc:3207} Hexed Troll
	-- was: ["Head south through the isles. The Loa idols lie all over the southern isles; Voodoo and Hexed Trolls hold them and drop the Hexed Pendants. {quest:826} and Minshina's cage are on the southernmost isle."] = "Ve al sur por las islas. Los ídolos loa están por todas las islas del sur; los trols de vudú y los trols maléficos las ocupan y sueltan los colgantes embrujados. {quest:826} y la jaula de Minshina están en la isla más al sur."
	["Head south through the isles. The Loa idols lie all over the southern isles; Voodoo and Hexed Trolls hold them and drop the Hexed Pendants. {quest:826} and Minshina's cage are on the southernmost isle."] = "Ve al sur por las islas. Los ídolos loa están por todas las islas del sur; los trols vudú y embrujados los custodian y sueltan los Colgantes embrujados. {quest:826} y la jaula de Minshina están en la isla más al sur.",

	-- Step 44: Razor Hill
	-- {area:362} Razor Hill
	["Follow the road north to {area:362}."] = "Sigue el camino al norte hasta {area:362}.",
	-- {npc:3169} Tarshaw Jaggedscar
	["{npc:3169}, inside"] = "{npc:3169}, adentro",
	-- {npc:3294} Ophek
	["{npc:3294}, by the inn"] = "{npc:3294}, junto a la posada",

	-- Step 45: Swart
	-- {npc:3173} Swart · {area:362} Razor Hill
	["{npc:3173}, the shaman trainer, stands on the east side of {area:362}."] = "{npc:3173}, el instructor de chamanes, está en el lado este de {area:362}.",

	-- Step 46: To step
	["To step"] = "Al paso",

	-- Step 50: Kranal Fiss
	-- {area:814} Southfury River · {area:379} Far Watch Post · {npc:5907} Kranal Fiss
	["West over the {area:814} bridge, past {area:379} and on along the ridge: {npc:5907} stands alone above the Razormane camp."] = "Al oeste por el puente de {area:814}, pasando {area:379} y siguiendo por la cresta: {npc:5907} está solo sobre el campamento Crines de Acero.",

	-- Step 51: Telf Joolam
	-- {zone:1411} Durotar · {npc:5900} Telf Joolam
	["Back over the bridge and south along the {zone:1411} bank of the river to where a narrow trail climbs the mountain: {npc:5900} keeps the shrine at the top. Mind the edges on the way up, and come back down the same trail."] = "Vuelve a cruzar el puente y ve al sur por la orilla de {zone:1411} del río hasta donde un sendero angosto sube la montaña: {npc:5900} cuida el santuario de la cima. Cuidado con los bordes al subir, y baja por el mismo sendero.",

	-- Step 52: Razormane Grounds
	["Quilboars and scouts hold the huts west of town, where the prickly pears grow; dustrunners and battleguards hold the camps farther west."] = "Los jabaespines y exploradores ocupan las chozas al oeste del pueblo, donde crecen los higos chumbos; los correpolvos y guardias de batalla ocupan los campamentos más al oeste.",

	-- Step 53: Rezlak
	-- {zone:1454} Orgrimmar · {npc:3293} Rezlak
	["Head north-east to the road toward {zone:1454}. {npc:3293} camps beside it; the stolen sacks lie along the road south of him."] = "Ve al noreste hasta el camino hacia {zone:1454}. {npc:3293} acampa a su lado; los sacos robados están a lo largo del camino al sur de él.",

	-- Step 54: Drygulch Ravine
	-- {area:370} Drygulch Ravine · {npc:3293} Rezlak · {item:277661} Dull Storm Orb · {area:371} Dustwind Cave · {item:6652} Reagent Pouch
	-- plural, as words: Burning Blade Cultists = {npc:3199} Burning Blade Cultist
	["Savages and Storm Witches nest in {area:370}, east of {npc:3293}. A Storm Witch drops the {item:277661}. Shamans: the Burning Blade Cultists by {area:371}, at the ravine's south end, drop the {item:6652}."] = "Los salvajes y las brujas de la tormenta anidan en {area:370}, al este de {npc:3293}. Una bruja de la tormenta suelta {item:277661}. Chamanes: los sectarios del Filo Ardiente junto a {area:371}, en el extremo sur del barranco, sueltan {item:6652}.",

	-- Step 57: Thunder lizards
	["Thunder lizards"] = "Truenagartos",
	-- {area:369} Thunder Ridge
	["Careful: Halikor, a level 12 elite, roams {area:369} among the lizards: watch for him before you pull."] = "Cuidado: Halikor, un élite de nivel 12, ronda por {area:369} entre las lagartijas: búscalo antes de atacar.",

	-- Step 59: Misha Tor'kren
	-- {area:814} Southfury River · {item:4891} Kron's Amulet
	["Misha's hut stands south of the lizards. The crocolisks along the {area:814} to the west carry {item:4891}."] = "La choza de Misha está al sur de los lagartos. Los crocoliscos de {area:814}, al oeste, llevan {item:4891}.",

	-- Step 60: Level 11
	["Level 11"] = "Nivel 11",
	-- {npc:3203} Fizzle Darkstorm
	-- plural, as words: Thunder Lizards = {npc:3130} Thunder Lizard
	["Top up here to level 11 before {npc:3203} (12) and his imp: the Thunder Lizards (9-10) graze on the ridge just west of Misha's hut."] = "Sube aquí hasta el nivel 11 antes de {npc:3203} (12) y su diablillo: los truenagartos (9-10) pastan en el risco justo al oeste de la choza de Misha.",
	-- {npc:3130} Thunder Lizard
	["grind on {npc:3130}"] = "mata {npc:3130}",

	-- Step 61: Fizzle Darkstorm
	-- {item:15908} Taming Rod
	["Tame it with the {item:15908}"] = "Domestícalo con {item:15908}",

	-- Step 63: Razor Hill
	-- {area:362} Razor Hill
	-- was: ["Back south to {area:362}."] = "Vuelve al sur a {area:362}."
	["Back south to {area:362}."] = "De vuelta al sur, a {area:362}.",

	-- Step 65: Heglan Shadeeye
	-- {npc:275657} Heglan Shadeeye · {area:362} Razor Hill
	["{npc:275657} stands on the shore east of {area:362}. The trident, banner and dagger lie on the beach around him."] = "{npc:275657} está en la orilla, al este de {area:362}. El tridente, el estandarte y la daga están en la playa a su alrededor.",

	-- Step 66: Margoz
	-- {quest:828} Margoz · {quest:827} Skull Rock
	["{quest:828} camps on the hill west of the naga beach, south of {quest:827}."] = "{quest:828} acampa en la colina al oeste de la playa de los naga, al sur de {quest:827}.",

	-- Step 67: To Orgrimmar
	-- {zone:1454} Orgrimmar
	["To {zone:1454}"] = "A {zone:1454}",

	-- Step 68: Gan'rul Bloodeye
	-- {zone:1454} Orgrimmar · {area:817} Skull Rock · {npc:5875} Gan'rul Bloodeye · {object:172960} Cleft of Shadow · {object:172982} Valley of Strength
	["{zone:1454}'s main gate is just west of {area:817}. {npc:5875} stands in the {object:172960}, the canyon under the {object:172982}."] = "La puerta principal de {zone:1454} está justo al oeste de {area:817}. {npc:5875} está en {object:172960}, el cañón bajo {object:172982}.",

	-- Step 69: Hanashi
	-- {npc:2704} Hanashi · {object:172958} Valley of Honor
	["While you're here: learn Staves from {npc:2704} ({object:172958}, 10 silver); a staff carries more spell stats than a one-hander while you level."] = "Ya que estás aquí: aprende Bastones con {npc:2704} ({object:172958}, 10 de plata); un bastón da más estadísticas de hechizo que un arma de una mano mientras subes de nivel.",

	-- Step 70: Back to Skull Rock
	-- {area:817} Skull Rock
	["Back to {area:817}"] = "De vuelta a {area:817}",
	-- {area:817} Skull Rock
	["To {area:817}"] = "A {area:817}",

	-- Step 71: Skull Rock's mouth
	-- {area:817} Skull Rock
	["{area:817}'s mouth"] = "Entrada de {area:817}",

	-- Step 72: Skull Rock
	-- {quest:827} Skull Rock · {npc:3204} Gazz'uz · {item:4903} Eye of Burning Shadow
	-- was: ["Burning Blade cultists hold the caves of {quest:827}; any of them drops a {item:4871}. {npc:3204}, a level 14 warlock, stands deep inside and drops the {item:4903}.\nCareful: voidwalkers fight beside the Burning Blade cultists in {quest:827} and {npc:3204} (14) waits at the back with his own: pull one cultist at a time near the entrance for the collars. The {item:4903} is optional: leave {npc:3204} unless you are 13 or have a friend."] = "Los fieles Filo Ardiente ocupan las cuevas de {quest:827}; cualquiera de ellos suelta {item:4871}. {npc:3204}, un brujo de nivel 14, está en lo más hondo y suelta {item:4903}.\nCuidado: los abisarios luchan junto a los fieles Filo Ardiente en {quest:827} y {npc:3204} (14) espera al fondo con el suyo: atrae a un fiel cada vez cerca de la entrada para los collares. {item:4903} es opcional: deja a {npc:3204} en paz salvo que seas de nivel 13 o vayas con un amigo."
	["Careful: voidwalkers fight beside the Burning Blade cultists in {quest:827} and {npc:3204} (14) waits at the back with his own: pull one cultist at a time near the entrance for the collars. The {item:4903} is optional: leave {npc:3204} unless you are 13 or have a friend."] = "Cuidado: hay abisarios que luchan junto a los cultistas de Burning Blade en {quest:827}, y {npc:3204} (14) espera al fondo con los suyos: atrae a un cultista a la vez cerca de la entrada para conseguir los collares. {item:4903} es opcional: deja a {npc:3204} a menos que seas nivel 13 o tengas un amigo.",

	-- Step 73: Tablet of Verga
	-- {object:58595} Burning Blade Stash · {area:817} Skull Rock
	["The {object:58595} stands in {area:817}, among the cultists you just fought."] = "{object:58595} está en {area:817}, entre los fieles con los que acabas de luchar.",

	-- Step 75: The Binding
	-- {zone:1454} Orgrimmar
	["Careful: the voidwalker you summon hits hard and it is the fight Warlocks die to most in {zone:1454}: start at full health and mana, send your imp in, keep Corruption and Immolate on it, and use a healthstone if you have one."] = "Cuidado: el abisario que invocas pega fuerte y es la pelea en la que más mueren los brujos en {zone:1454}: empieza con salud y maná al máximo, manda a tu diablillo, mantén Corrupción e Inmolar sobre él y usa una piedra de salud si tienes una.",

	-- Step 76: Into Durotar
	-- {zone:1411} Durotar
	["Into {zone:1411}"] = "Hacia {zone:1411}",

	-- Step 78: Spitelash naga
	["Spitelash naga"] = "Nagas Látigo de Ira",
	-- {npc:275657} Heglan Shadeeye · {area:370} Drygulch Ravine · {npc:3107} Surf Crawler
	-- was: ["North-east to the beach below {area:370}, north of {npc:275657}: Spitelash Scouts and Attendants hold it. Hunters: tame a {npc:3107} on the beach."] = "Al noreste, a la playa bajo {area:370}, al norte de {npc:275657}: la ocupan los exploradores y ayudantes Látigo de Ira. Cazadores: domestica un {npc:3107} en la playa."
	["Back east to the shore north of {npc:275657}. Spitelash Scouts and Attendants hold the beach below {area:370}. Hunters: tame a {npc:3107} on the beach."] = "De vuelta al este, hasta la orilla al norte de {npc:275657}. Los exploradores y asistentes de Spitelash dominan la playa bajo {area:370}. Cazadores: domestica un {npc:3107} en la playa.",

	-- Step 79: Razor Hill
	-- {area:362} Razor Hill
	["Back to {area:362}."] = "Vuelve a {area:362}.",

	-- Step 83: To Armored Scorpid
	-- {npc:3126} Armored Scorpid
	["To {npc:3126}"] = "A {npc:3126}",

	-- Step 84: Armored Scorpid
	-- {area:362} Razor Hill · {npc:3171} Thotar
	-- plural, as words: Armored Scorpids = {npc:3126} Armored Scorpid
	["Armored Scorpids crawl over the plains west of {area:362}. Tame one, then return to {npc:3171}."] = "Los escórpidos acorazados se arrastran por las llanuras al oeste de {area:362}. Domestica uno y vuelve con {npc:3171}.",
	-- {npc:3171} Thotar · {npc:3352} Ormak Grimshot · {zone:1454} Orgrimmar · {spell:5149} Beast Training
	["{npc:3171}: {npc:3352} in {zone:1454} teaches {spell:5149}"] = "{npc:3171}: {npc:3352} en {zone:1454} enseña {spell:5149}",

	-- Step 85: Razor Hill
	-- {npc:3142} Orgnil Soulscar
	-- was: ["{npc:3142}: {npc:275666}, an elite sea giant"] = "{npc:3142}: {npc:275666}, un gigante de mar élite"
	["{npc:3142}: Aggor the Young, an elite sea giant"] = "{npc:3142}: Aggor the Young, un gigante marino élite",

	-- Step 86: Aggor the Young
	["Aggor the Young"] = "Aggor the Young",
	-- {zone:1411} Durotar
	["Aggor the Young, a young sea giant, walks {zone:1411}'s north coast, north of the naga beach. Aggor the Young is elite: grouping up is advised."] = "Aggor the Young, un gigante marino joven, camina por la costa norte de {zone:1411}, al norte de la playa de los nagas. Aggor the Young es élite: se recomienda ir en grupo.",
	-- {npc:3142} Orgnil Soulscar · {area:362} Razor Hill
	["{npc:3142}, back in {area:362}"] = "{npc:3142}, de vuelta en {area:362}",

	-- Step 87: Into Orgrimmar
	-- {zone:1454} Orgrimmar
	["Into {zone:1454}"] = "Entra a {zone:1454}",

	-- Step 88: To Ormak Grimshot
	-- {npc:3352} Ormak Grimshot
	["To {npc:3352}"] = "A {npc:3352}",

	-- Step 89: Ormak Grimshot
	-- {area:362} Razor Hill · {zone:1454} Orgrimmar · {area:817} Skull Rock · {npc:3352} Ormak Grimshot · {object:172958} Valley of Honor
	-- was: ["Follow the road north from {area:379} to {zone:1454}'s main gate, just west of {area:817}. {npc:3352} stands with the hunter trainers in the {object:172958}."] = "Sigue el camino hacia el norte desde {area:379} hasta la puerta principal de {zone:1454}, justo al oeste de {area:817}. {npc:3352} está con los instructores de cazadores en {object:172958}."
	["Follow the road north from {area:362} to {zone:1454}'s main gate, just west of {area:817}. {npc:3352} stands with the hunter trainers in the {object:172958}."] = "Sigue el camino al norte desde {area:362} hasta la puerta principal de {zone:1454}, justo al oeste de {area:817}. {npc:3352} está con los instructores de cazador en {object:172958}.",

	-- Step 90: Hanashi
	-- {npc:2704} Hanashi · {object:172958} Valley of Honor
	["While you're here: learn Staves from {npc:2704} ({object:172958}, 10 silver); a Hunter's melee weapon is mostly its stats, and two-handers carry the most."] = "Ya que estás aquí: aprende Bastones con {npc:2704} ({object:172958}, 10 de plata); el arma cuerpo a cuerpo de un cazador vale sobre todo por sus estadísticas, y las de dos manos son las que más tienen.",

	-- Step 91: To Uzzek
	-- {npc:5810} Uzzek
	["To {npc:5810}"] = "A {npc:5810}",

	-- Step 92: Uzzek
	-- {area:362} Razor Hill · {area:814} Southfury River · {npc:5810} Uzzek · {area:379} Far Watch Post · {zone:1413} Barrens
	["Follow the road west from {area:362} over the {area:814} bridge; {npc:5810} stands at {area:379}, just above it on the {zone:1413} side."] = "Sigue el camino al oeste desde {area:362} y cruza el puente de {area:814}; {npc:5810} está en {area:379}, justo arriba, del lado de {zone:1413}.",

	-- Step 93: Thunder lizards across the river
	-- was: ["Thunder lizards across the river"] = "Truenagartos al otro lado del río"
	["Thunder lizards across the river"] = "Truenagartos al otro lado del río",

	-- Step 94: To Far Watch Post
	-- {area:379} Far Watch Post
	["To {area:379}"] = "A {area:379}",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["Back east to Sen'jin on the way to the {area:368}."] = "Vuelve al este, al poblado Sen'jin, de camino a {area:368}.",
	-- ["Back south to {area:362}."] = "Vuelve al sur a {area:362}.",
	-- ["Back to the Den"] = "Vuelve a El Cubil",
	-- ["Back to the Den: {npc:3143} takes {quest:804}'s claw and {npc:5887}, just outside, has {quest:1516} now that you are level 4."] = "Vuelve a la Guarida: {npc:3143} recoge la garra de {quest:804} y {npc:5887}, justo fuera, tiene {quest:1516} ahora que eres de nivel 4.",
	-- ["Back to {npc:5875} in the {object:172960}. Use the {item:7464} on the summoning circle there and defeat the voidwalker to bind it."] = "Vuelve con {npc:5875} en {object:172960}. Usa {item:7464} en el círculo de invocación de allí y derrota al abisario para vincularlo.",
	-- ["Burning Blade cultists hold the caves of {quest:827}; any of them drops a {item:4871}. {npc:3204}, a level 14 warlock, stands deep inside and drops the {item:4903}.\nCareful: voidwalkers fight beside the Burning Blade cultists in {quest:827} and {npc:3204} (14) waits at the back with his own: pull one cultist at a time near the entrance for the collars. The {item:4903} is optional: leave {npc:3204} unless you are 13 or have a friend."] = "Los fieles Filo Ardiente ocupan las cuevas de {quest:827}; cualquiera de ellos suelta {item:4871}. {npc:3204}, un brujo de nivel 14, está en lo más hondo y suelta {item:4903}.\nCuidado: los abisarios luchan junto a los fieles Filo Ardiente en {quest:827} y {npc:3204} (14) espera al fondo con el suyo: atrae a un fiel cada vez cerca de la entrada para los collares. {item:4903} es opcional: deja a {npc:3204} en paz salvo que seas de nivel 13 o vayas con un amigo.",
	-- ["Druid trainer"] = "Instructor de druidas",
	-- ["Fizzle holds the Burning Blade camp on {area:369}, just north of Misha's hut. Hunters: tame a {npc:3099} with the {item:15908} on the way.\nCareful: Burning Blade cultists surround Fizzle, some linked so they aggro in pairs, and they respawn quickly.\nCareful: Halikor, a level 12 elite, roams {area:369} among the lizards: watch for him before you pull."] = "Fizzle ocupa el campamento del Filo Ardiente en {area:369}, justo al norte de la choza de Misha. Cazadores: domestica un {npc:3099} con la {item:15908} por el camino.\nCuidado: los fieles del Filo Ardiente rodean a Fizzle, algunos vinculados, así que atacan por parejas, y reaparecen rápido.\nCuidado: Halikor, un élite de nivel 12, recorre {area:369} entre los lagartos: localízalo antes de atraer.",
	-- ["Follow the road north from {area:379} to {zone:1454}'s main gate, just west of {area:817}. {npc:3352} stands with the hunter trainers in the {object:172958}."] = "Sigue el camino hacia el norte desde {area:379} hasta la puerta principal de {zone:1454}, justo al oeste de {area:817}. {npc:3352} está con los instructores de cazadores en {object:172958}.",
	-- ["Head south through the isles. The Loa idols lie all over the southern isles; Voodoo and Hexed Trolls hold them and drop the Hexed Pendants. {quest:826} and Minshina's cage are on the southernmost isle."] = "Ve al sur por las islas. Los ídolos loa están por todas las islas del sur; los trols de vudú y los trols maléficos las ocupan y sueltan los colgantes embrujados. {quest:826} y la jaula de Minshina están en la isla más al sur.",
	-- ["Head south through the isles. The Loa idols lie all over the southern isles; Voodoo and Hexed Trolls hold them and drop the Hexed Pendants. {quest:826} and Minshina's cage are on the southernmost isle.\nCareful: the trolls stand close together and the Voodoo Trolls cast from range: pull one at a time. {quest:826} himself is level 10."] = "Ve al sur por las islas. Los ídolos loa están por todas las islas del sur; los trols vudú y los trols embrujados los llevan y sueltan los colgantes embrujados. {quest:826} y la jaula de Minshina están en la isla más al sur.\nCuidado: los trols están muy juntos y los trols vudú lanzan hechizos a distancia: atráelos de uno en uno. El propio {quest:826} es de nivel 10.",
	-- ["North-east to the beach below {area:370}, north of {npc:275657}: Spitelash Scouts and Attendants hold it. Hunters: tame a {npc:3107} on the beach."] = "Al noreste, a la playa bajo {area:370}, al norte de {npc:275657}: la ocupan los exploradores y ayudantes Látigo de Ira. Cazadores: domestica un {npc:3107} en la playa.",
	-- ["Prickly pears"] = "Peras espinosas",
	-- ["Quilboars and scouts hold the huts west of town; dustrunners and battleguards hold the camps farther west."] = "Los jabaespines y exploradores ocupan las chozas al oeste del pueblo; los correpolvos y guardias de batalla ocupan los campamentos más al oeste.",
	-- ["The keep stands on the coast south-east of {area:362}. The raiders' axe, bow and shield lie on its outskirts. Sailors and marines drop the {item:4870}. {npc:3192} waits at the top of the keep; his key opens the chest beside him, which holds the {item:4881}."] = "El fuerte está en la costa, al sureste de {area:362}. El hacha, el arco y el escudo de asaltante están en sus alrededores. Los marineros y los soldados de marina sueltan {item:4870}. {npc:3192} espera en lo alto del fuerte; su llave abre el cofre que tiene al lado, que contiene {item:4881}.",
	-- ["The prickly pears grow among the quilboar huts just west of town."] = "Las peras espinosas crecen entre las chozas de los jabaespines, justo al oeste del pueblo.",
	-- ["Through Sen'jin on the way west to {area:366}: {npc:3304} takes the eyes and mucus now."] = "Pasa por el poblado Sen'jin de camino al oeste hacia {area:366}: {npc:3304} recoge ya los ojos y la mucosidad.",
	-- ["Thunder Lizards and Lightning Hides graze on {area:369} across the bridge; any of them can drop a {item:6486}."] = "Los truenagartos y los lomorrayos pastan en {area:369}, al otro lado del puente; cualquiera de ellos puede soltar {item:6486}.",
	-- ["Thunder Lizards and Lightning Hides graze on {area:369}, beside the road north to {zone:1454}; any of them can drop a {item:6486}. {npc:5810} takes it when the next guide passes {area:379}.\nCareful: Halikor, a level 12 elite, roams {area:369} among the lizards: watch for him before you pull."] = "Los truenagartos y los lomorrayos pastan en {area:369}, junto al camino al norte hacia {zone:1454}; cualquiera de ellos puede soltar {item:6486}. {npc:5810} la recoge cuando la siguiente guía pasa por {area:379}.\nCuidado: Halikor, un élite de nivel 12, recorre {area:369} entre los lagartos: localízalo antes de atraer.",
	-- ["Thunder Lizards and Lightning Hides graze on {area:369}, just west and south-west of {npc:3293}.\nCareful: Halikor, a level 12 elite, roams {area:369} among the lizards: watch for him before you pull."] = "Los truenagartos y los lomorrayos pastan en {area:369}, justo al oeste y suroeste de {npc:3293}.\nCuidado: Halikor, un élite de nivel 12, recorre {area:369} entre los lagartos: localízalo antes de atraer.",
	-- ["Thunder Lizards and Lightning Hides graze on {area:369}, just west and south-west of {npc:3293}.\nFizzle holds the Burning Blade camp on {area:369}, north-west of {area:362}. Hunters: tame a {npc:3099} with the {item:15908} on the way.\nCareful: Burning Blade cultists surround Fizzle, some linked so they aggro in pairs, and they respawn quickly.\nCareful: Halikor, a level 12 elite, roams {area:369} among the lizards: watch for him before you pull."] = "Los Truenagartos y los Lomorrayos pastan en {area:369}, justo al oeste y suroeste de {npc:3293}.\nFizzle ocupa el campamento del Filo Ardiente en {area:369}, al noroeste de {area:362}. Cazadores: domestica un {npc:3099} con la {item:15908} por el camino.\nCuidado: los fieles del Filo Ardiente rodean a Fizzle, algunos vinculados, así que atacan por parejas, y reaparecen rápido.\nCuidado: Halikor, un élite de nivel 12, recorre {area:369} entre los lagartos: localízalo antes de atraer.",
	-- ["Thunder lizards across the river"] = "Truenagartos al otro lado del río",
	-- ["Thunder lizards on the way north"] = "Truenagartos de camino al norte",
	-- ["Top up here to level 10: {quest:840}, at {area:362}, needs level 10.\nThe prickly pears for {quest:96825} grow by these huts: pick them while you grind."] = "Sube aquí hasta el nivel 10: {quest:840}, en {area:362}, requiere nivel 10.\nLos higos chumbos de {quest:96825} crecen junto a estas chozas: recógelos mientras matas.",
	-- ["Wade across to the northern Echo Isle. The Matriarch prowls among the raptors there.\nDurotar Tigers roam the isle as well as the shore south of Sen'jin, and the Taillasher eggs sit in nests on the isles and along the beach."] = "Cruza vadeando hasta la isla del Eco del norte. La matriarca merodea allí entre los raptores.\nLos tigres de Durotar recorren la isla y también la orilla al sur del poblado Sen'jin, y los huevos de coleador están en nidos en las islas y a lo largo de la playa.",
	-- ["With {skill:129} learned, {npc:265809} also offers its Camping 101: {npc:5943} in {area:362} takes it."] = "Con {skill:129} aprendidos, {npc:265809} también ofrece su Acampada 101: la recoge {npc:5943}, en {area:362}.",
	-- ["With {skill:165} learned, {npc:265809} also offers its Camping 101: {npc:3365} in {zone:1454} (next guide) takes it."] = "Con {skill:165} aprendida, {npc:265809} también ofrece su Acampada 101: la recoge {npc:3365}, en {zone:1454} (siguiente guía).",
	-- ["With {skill:171} learned, {npc:265809} also offers its Camping 101: {npc:11046} in {zone:1454} (next guide) takes it."] = "Con {skill:171} aprendida, {npc:265809} también ofrece su Acampada 101: la recoge {npc:11046}, en {zone:1454} (siguiente guía).",
	-- ["With {skill:182} learned, {npc:265809} also offers its Camping 101: {npc:3404} in {zone:1454} (next guide) takes it."] = "Con {skill:182} aprendida, {npc:265809} también ofrece su Acampada 101: la recoge {npc:3404}, en {zone:1454} (siguiente guía).",
	-- ["With {skill:186} learned, {npc:265809} also offers its Camping 101: {npc:3175} in {area:362} takes it."] = "Con {skill:186} aprendida, {npc:265809} también ofrece su Acampada 101: la recoge {npc:3175}, en {area:362}.",
	-- ["With {skill:197} learned, {npc:265809} also offers its Camping 101: {npc:2855} in {zone:1454} (next guide) takes it."] = "Con {skill:197} aprendida, {npc:265809} también ofrece su Acampada 101: la recoge {npc:2855}, en {zone:1454} (siguiente guía).",
	-- ["With {skill:202} learned, {npc:265809} also offers its Camping 101: {npc:11025} in {area:362} takes it."] = "Con {skill:202} aprendida, {npc:265809} también ofrece su Acampada 101: la recoge {npc:11025}, en {area:362}.",
	-- ["With {skill:333} learned, {npc:265809} also offers its Camping 101: {npc:11066} in {zone:1454} (next guide) takes it."] = "Con {skill:333} aprendido, {npc:265809} también ofrece su Acampada 101: la recoge {npc:11066}, en {zone:1454} (siguiente guía).",
	-- ["With {skill:393} learned, {npc:265809} also offers its Camping 101: {npc:7088} in {zone:1454} (next guide) takes it."] = "Con {skill:393} aprendido, {npc:265809} también ofrece su Acampada 101: la recoge {npc:7088}, en {zone:1454} (siguiente guía).",
	-- ["the {object:654925} on the ground beside her"] = "{object:654925}, en el suelo a su lado",
	-- ["{npc:11025} takes it once your {skill:202} skill is 20: gather or craft until then, the guide carries on meanwhile."] = "{npc:11025} la recoge en cuanto tu habilidad de {skill:202} llegue a 20: recolecta o fabrica hasta entonces, la guía sigue mientras tanto.",
	-- ["{npc:265809}: for Jandi"] = "{npc:265809}: para Jandi",
	-- ["{npc:265809}: for Jhag"] = "{npc:265809}: para Jhag",
	-- ["{npc:265809}: for Karolek"] = "{npc:265809}: para Karolek",
	-- ["{npc:265809}: for Snang"] = "{npc:265809}: para Snang",
	-- ["{npc:265809}: for Thuwd"] = "{npc:265809}: para Thuwd",
	-- ["{npc:265809}: for Whuut"] = "{npc:265809}: para Whuut",
	-- ["{npc:265809}: for {npc:11025}"] = "{npc:265809}: para {npc:11025}",
	-- ["{npc:265809}: for {npc:11046}"] = "{npc:265809}: para {npc:11046}",
	-- ["{npc:265809}: for {npc:11066}"] = "{npc:265809}: para {npc:11066}",
	-- ["{npc:265809}: for {npc:2855}"] = "{npc:265809}: para {npc:2855}",
	-- ["{npc:265809}: for {npc:3175}"] = "{npc:265809}: para {npc:3175}",
	-- ["{npc:265809}: for {npc:3365}"] = "{npc:265809}: para {npc:3365}",
	-- ["{npc:265809}: for {npc:3404}"] = "{npc:265809}: para {npc:3404}",
	-- ["{npc:265809}: for {npc:5943}"] = "{npc:265809}: para {npc:5943}",
	-- ["{npc:265809}: for {npc:7088}"] = "{npc:265809}: para {npc:7088}",
	-- ["{npc:3142}: {npc:275666}, an elite sea giant"] = "{npc:3142}: {npc:275666}, un gigante de mar élite",
	-- ["{npc:3175} takes it once your {skill:186} skill is 20: gather or craft until then, the guide carries on meanwhile."] = "{npc:3175} la recoge en cuanto tu habilidad de {skill:186} llegue a 20: recolecta o fabrica hasta entonces, la guía sigue mientras tanto.",
	-- ["{npc:5875} stands in the {object:172960}, the canyon under the {object:172982}. Hand him the {item:6535}, then use the {item:7464} on the summoning circle beside him and defeat the voidwalker to bind it.\nCareful: the voidwalker you summon hits hard and it is the fight Warlocks die to most in {zone:1454}: start at full health and mana, send your imp in, keep Corruption and Immolate on it, and use a healthstone if you have one."] = "{npc:5875} está en {object:172960}, el cañón bajo {object:172982}. Entrégale {item:6535}, luego usa {item:7464} en el círculo de invocación junto a él y derrota al abisario para vincularlo.\nCuidado: el abisario que invocas pega fuerte y es el combate en el que más mueren los brujos en {zone:1454}: empieza con la salud y el maná al máximo, manda a tu diablillo por delante, mantén Corrupción e Inmolar sobre él y usa una piedra de salud si tienes una.",
	-- ["{npc:5943} takes it once your {skill:129} skill is 20: gather or craft until then, the guide carries on meanwhile."] = "{npc:5943} la recoge en cuanto tu habilidad de {skill:129} llegue a 20: recolecta o fabrica hasta entonces, la guía sigue mientras tanto.",
}
