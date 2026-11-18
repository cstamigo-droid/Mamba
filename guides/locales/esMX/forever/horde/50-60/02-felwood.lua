-- Spanish (Latin America) (esMX): the guide forever/horde/50-60/02-felwood (forever/horde/50-60/02-felwood.guide).
-- Written by `forge i18n guides sync esMX`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Latin America) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Latin America) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 2: Janice Felstone
	-- {zone:1458} Undercity · {zone:1420} Tirisfal Glades · {area:152} Bulwark
	-- was: ["Leave the {area:1497} and ride east along the road through {zone:1420}, past the {area:152}. Felstone Farm is the first farm along the road; {npc:10778} waits in the house."] = "Sal de {area:1497} y cabalga al este por el camino a través de {zone:1420}, pasando {area:152}. La granja de Piedramácula es la primera granja del camino; {npc:10778} espera en la casa."
	["Leave the {zone:1458} and ride east along the road through {zone:1420}, past the {area:152}. Felstone Farm is the first farm along the road; Janice waits in the house."] = "Sal de {zone:1458} y cabalga al este por el camino a través de {zone:1420}, pasando {area:152}. Felstone Farm es la primera granja del camino; Janice espera en la casa.",
	-- {npc:10781} Royal Overseer Bauhaus · {zone:1458} Undercity
	-- was: ["Keep the parcel: {npc:10781} is in the {area:1497}."] = "Guarda el paquete: {npc:10781} está en {area:1497}."
	["Keep the parcel: {npc:10781} is in the {zone:1458}."] = "Guarda el paquete: {npc:10781} está en {zone:1458}.",

	-- Step 3: Scarlet forward camp
	["Scarlet forward camp"] = "Campamento avanzado Escarlata",
	-- {area:199} Felstone Field · {area:200} Dalson's Tears · {object:176092} Box of Incendiaries
	-- was: ["The Scarlet Crusade's tents stand between {area:199} and {area:200}. Torch the command tent with the {object:176092} and plant the Scourge banner."] = "Las tiendas de la Cruzada Escarlata están entre {area:199} y {area:200}. Quema la tienda de mando con {object:176092} y planta el estandarte de la Plaga."
	["The Scarlet Crusade's tents stand between {area:199} and {area:200}. Torch the command tent with the {object:176092} and plant the Scourge banner."] = "Las tiendas de la Cruzada Escarlata están entre {area:199} y {area:200}. Quema la tienda de mando con {object:176092} y planta el estandarte de la Plaga.",

	-- Step 4: Bulwark
	-- {area:152} Bulwark
	["Ride south-west past Felstone Farm and follow the road west back to the {area:152}."] = "Cabalga al suroeste pasando la granja de Piedramácula y sigue el camino al oeste de vuelta a {area:152}.",

	-- Step 5: Into Western Plaguelands
	-- {area:28} Western Plaguelands
	["Into {area:28}"] = "Entra a {area:28}",

	-- Step 6: Into Eastern Plaguelands
	-- {area:139} Eastern Plaguelands
	["Into {area:139}"] = "Entra a {area:139}",

	-- Step 8: Tirion Fordring
	-- {npc:1855} Tirion Fordring · {area:2619} Thondroril River · {area:139} Eastern Plaguelands
	-- was: ["Ride north along the eastern hills; {npc:1855} lives in a small house by the {area:2619}, at the border with the {zone:1423}."] = "Cabalga al norte por las colinas del este; {npc:1855} vive en una casita junto a {area:2619}, en la frontera con {zone:1423}."
	["Ride north along the eastern hills; {npc:1855} lives in a small house by the {area:2619}, at the border with the {area:139}."] = "Cabalga al norte por las colinas del este; {npc:1855} vive en una casita junto a {area:2619}, en la frontera con {area:139}.",
	-- {npc:1855} Tirion Fordring · {area:139} Eastern Plaguelands
	-- was: ["{npc:1855}'s hunts are in the {zone:1423}: keep them for later."] = "Las cacerías de {npc:1855} están en {zone:1423}: guárdalas para más adelante."
	["{npc:1855}'s hunts are in the {area:139}: keep them for later."] = "Las cacerías de {npc:1855} están en {area:139}: guárdalas para después.",

	-- Step 11: Kirsta Deepshadow
	-- {area:192} Northridge Lumber Camp · {npc:11610} Kirsta Deepshadow
	-- was: ["Ride back west over the river and on to the {area:192}; {npc:11610} hides on the hill north-east of it."] = "Cabalga de vuelta al oeste cruzando el río y sigue hasta {area:192}; {npc:11610} se esconde en la colina al noreste."
	["Ride back west over the river and on to the {area:192}; {npc:11610} hides on the hill north-east of it."] = "Cabalga de vuelta al oeste cruzando el río y sigue hasta {area:192}; {npc:11610} se esconde en la colina al noreste.",

	-- Step 12: Scarlet Crusade
	-- was: ["Scarlet Crusade"] = "Cruzada Escarlata"
	["Scarlet Crusade"] = "Cruzada Escarlata",
	-- {area:192} Northridge Lumber Camp
	-- was: ["Knights and magi work the {area:192}; the medics and hunters camp south of it."] = "Los caballeros y magus trabajan en {area:192}; los médicos y cazadores acampan al sur."
	["Knights and magi work the {area:192}; the medics and hunters camp south of it."] = "Caballeros y magos trabajan en {area:192}; los médicos y cazadores acampan al sur.",
	-- {npc:1833} Scarlet Knight · {area:192} Northridge Lumber Camp
	["{npc:1833} walks around {area:192}: look inside the circle on the map"] = "{npc:1833} camina por {area:192}: busca dentro del círculo en el mapa",

	-- Step 14: The western hills
	["The western hills"] = "Las colinas del oeste",
	-- {area:2260} Marris Stead · {area:2627} Terrordale
	-- plural, as words: Plaguehound Runts = {npc:8596} Plaguehound Runt · Plaguebats = {npc:8600} Plaguebat · Carrion Grubs = {npc:8603} Carrion Grub
	["Plaguehound Runts and Plaguebats roam the hills north of the {area:2260}, Carrion Grubs crawl among them; work north toward {area:2627}."] = "Los Plaguehound Runts y Plaguebats rondan las colinas al norte de {area:2260}, y entre ellos se arrastran Carrion Grubs; avanza al norte hacia {area:2627}.",
	-- {npc:8597} Plaguehound
	["{npc:8597}, 90 yd north"] = "{npc:8597}, 90 yd al norte",

	-- Step 19: Tirion Fordring
	-- {npc:1855} Tirion Fordring · {area:2619} Thondroril River
	["Ride east to {npc:1855}'s hut by the {area:2619} and hear him out."] = "Cabalga al este hasta la cabaña de {npc:1855} junto a {area:2619} y escúchalo.",

	-- Step 20: To Terrordale: kill these as you meet them
	-- {area:2627} Terrordale
	-- was: ["{area:2627}: kill these as you meet them"] = "{area:2627}: mátalos cuando te los encuentres"
	["To {area:2627}: kill these as you meet them"] = "Hacia {area:2627}: mata a estos enemigos conforme los encuentres",
	-- {npc:8598} Frenzied Plaguehound
	["{npc:8598}, 100 yd south-west"] = "{npc:8598}, 100 yd al suroeste",

	-- Step 21: Terrordale: kill these as you meet them
	-- {area:2627} Terrordale
	-- was: ["{area:2627}: kill these as you meet them"] = "{area:2627}: mátalos cuando te los encuentres"
	["{area:2627}: kill these as you meet them"] = "{area:2627}: mata a estos cuando te los encuentres",
	-- {area:2627} Terrordale · {item:15042} Empty Termite Jar
	-- plural, as words: Large Termite Mounds = {object:177464} Large Termite Mound
	-- was: ["The book lies in the ruined inn of {area:2627}; the undead in the town are 54-56, so pull them one at a time.\nThe Large Termite Mounds stand all over the hills east of {area:2627}. Use the {item:15042} on each mound you pass."] = "El libro está en la posada en ruinas de {area:2627}; los no-muertos del pueblo son de nivel 54-56, así que atráelos de uno en uno.\nLos Grandes Montículos de Termitas están por todas las colinas al este de {area:2627}. Usa el {item:15042} en cada montículo por el que pases."
	["The book lies in the ruined inn of {area:2627}.\nThe Large Termite Mounds stand all over the hills east of {area:2627}. Use the {item:15042} on each mound you pass."] = "El libro está en la posada en ruinas de {area:2627}.\nLos Large Termite Mounds están por todas las colinas al este de {area:2627}. Usa el {item:15042} en cada montículo por el que pases.",

	-- Step 23: Light's Hope Chapel
	-- {area:2268} Light's Hope Chapel
	["Ride south back to the road and follow it east across the whole zone to {area:2268}."] = "Cabalga al sur de vuelta al camino y síguelo al este por toda la zona hasta {area:2268}.",

	-- Step 24: Pamela Redpath
	-- {npc:10926} Pamela Redpath · {area:2262} Darrowshire
	["{npc:10926}'s ghost stands in the ruins of {area:2262}, in the south-west."] = "El fantasma de {npc:10926} está en las ruinas de {area:2262}, en el suroeste.",

	-- Step 25: Pamela's Doll
	-- {npc:10926} Pamela Redpath
	["The doll's head and its two sides lie in the houses around {npc:10926}; join them from your bags."] = "La cabeza de la muñeca y sus dos lados están en las casas alrededor de {npc:10926}; únelos desde tus bolsas.",
	["Inside"] = "Adentro",

	-- Step 26: Pamela Redpath
	-- {npc:10927} Marlene Redpath · {area:197} Sorrow Hill · {area:28} Western Plaguelands
	["Keep Auntie Marlene: {npc:10927} lives at {area:197} in the {area:28}."] = "Guarda a Auntie Marlene: {npc:10927} vive en {area:197} en {area:28}.",

	-- Step 27: Back to Light's Hope Chapel
	-- {area:2268} Light's Hope Chapel
	["Back to {area:2268}"] = "De vuelta a {area:2268}",
	-- {area:2264} Corin's Crossing
	["Defenders of Darrowshire's spirits come with the {area:2264} stop later in this guide: keep it."] = "Los espíritus de Defenders of Darrowshire llegan con la parada de {area:2264} más adelante en esta guía: guárdala.",

	-- Step 28: To Dalson's Tears farmhouse
	-- {area:200} Dalson's Tears
	["To {area:200} farmhouse"] = "A la casa de campo de {area:200}",

	-- Step 29: Dalson's Tears farmhouse
	-- {area:200} Dalson's Tears
	["{area:200} farmhouse"] = "Granja de {area:200}",
	-- {npc:10816} Wandering Skeleton · {npc:10836} Farmer Dalson
	["The diary lies in the farmhouse, the cabinet stands inside and the outhouse is behind it. A {npc:10816} carries the outhouse key; {npc:10836} comes out when you open the outhouse and carries the cabinet key."] = "El diario está en la granja, el armario está dentro y el retrete está detrás. Un {npc:10816} lleva la llave del retrete; {npc:10836} sale cuando abres el retrete y lleva la llave del armario.",
	-- {quest:5058} Mrs. Dalson's Diary
	["{quest:5058}, inside"] = "{quest:5058}, adentro",
	-- {object:175924} Locked Cabinet
	["{object:175924}, inside"] = "{object:175924}, adentro",

	-- Step 30: Sorrow Hill
	-- {npc:10840} Argent Officer Pureheart · {area:197} Sorrow Hill · {area:272} Tarren Mill · {npc:10927} Marlene Redpath · {npc:10936} Joseph Redpath
	["{npc:10840} stands at the south end of the {area:197} graveyard, where the road from {area:272} comes in; {npc:10927}'s house stands by the road, and {npc:10936}'s monument is in the graveyard behind it."] = "{npc:10840} está en el extremo sur del cementerio de {area:197}, donde llega el camino desde {area:272}; la casa de {npc:10927} está junto al camino, y el monumento de {npc:10936} está en el cementerio detrás de ella.",
	-- was: ["Upstairs"] = "Arriba"
	["Upstairs"] = "Arriba",
	-- {quest:5142} Little Pamela · {npc:10926} Pamela Redpath · {area:2262} Darrowshire
	-- was: ["Keep Little Pamela: Pamela is in {area:2262}, visited again later."] = "Guarda La pequeña Pamela: Pamela está en {area:2262}, que visitarás de nuevo más adelante."
	["Keep {quest:5142}: {npc:10926} is in {area:2262}, visited again later."] = "Guarda {quest:5142}: {npc:10926} está en {area:2262}, que visitarás de nuevo más adelante.",

	-- Step 31: Mulgris Deepriver
	-- {area:202} Writhing Haunt · {area:200} Dalson's Tears
	["He camps by the {area:202}, south-east of {area:200}."] = "Acampa junto a {area:202}, al sureste de {area:200}.",

	-- Step 32: Chromie
	["Chromie"] = "Chromie",
	-- {area:2268} Light's Hope Chapel
	-- was: ["{quest:5210} goes to {area:2268}: keep it for later."] = "{quest:5210} va a {area:2268}: guárdala para más adelante."
	["Brother Carlin goes to {area:2268}: keep it for later."] = "Brother Carlin va a {area:2268}: guárdala para después.",

	-- Step 33: Diseased Wolves
	["Diseased Wolves"] = "Lobos malsanos",
	-- {area:200} Dalson's Tears · {area:202} Writhing Haunt
	-- was: ["The wolves roam the fields between Andorhal, {area:200} and the {area:202}. Finish them on the ride back east."] = "Los lobos deambulan por los campos entre Andorhal, {area:200} y {area:202}. Termínalos en el camino de vuelta al este."
	["The wolves roam the fields between Andorhal, {area:200} and the {area:202}. Finish them on the ride back east."] = "Los lobos deambulan por los campos entre Andorhal, {area:200} y {area:202}. Termínalos en el camino de vuelta al este.",

	-- Step 34: Level 53
	-- was: ["Level 53"] = "Nivel 53"
	["Level 53"] = "Nivel 53",
	-- {npc:10739} Mulgris Deepriver · {area:200} Dalson's Tears · {area:202} Writhing Haunt · {area:1417} Sunken Temple · {area:1584} Blackrock Depths
	-- plural, as words: Carrion Lurkers = {npc:1821} Carrion Lurker
	-- was: ["Top up here to level 53 before {npc:10739} sends you after the Diseased Grizzlies (55-56): the Carrion Lurkers (52-53) on the way from {area:200} to the {area:202} are at your level. Or, with a group, run the {area:1417} dungeon or the {area:1584} dungeon instead."] = "Completa aquí hasta el nivel 53 antes de que {npc:10739} te mande por los osos pardos malsanos (55-56): los acechadores carroñeros (52-53) del camino de {area:200} a {area:202} tienen tu nivel. O, en grupo, haz la mazmorra {area:1417} o la mazmorra {area:1584}."
	["Top up here to level 53 before {npc:10739} sends you after the Diseased Grizzlies (55-56): the Carrion Lurkers (52-53) on the way from {area:200} to the {area:202} are at your level. Or, with a group, run the {area:1417} dungeon or the {area:1584} dungeon instead."] = "Sube aquí hasta el nivel 53 antes de que {npc:10739} te mande por los Diseased Grizzlies (55-56): los Carrion Lurkers (52-53) en el camino de {area:200} a {area:202} están a tu nivel. O, en grupo, haz la mazmorra {area:1417} o la mazmorra {area:1584}.",
	-- {npc:1821} Carrion Lurker
	-- was: ["grind on {npc:1821}"] = "sube de nivel con {npc:1821}"
	["grind on {npc:1821}"] = "sube de nivel con {npc:1821}",

	-- Step 36: Diseased Grizzlies
	-- was: ["Diseased Grizzlies"] = "Osos pardos malsanos"
	["Diseased Grizzlies"] = "Osos pardos malsanos",
	-- {area:202} Writhing Haunt
	-- was: ["The bears roam the hills north and east of the {area:202}."] = "Los osos deambulan por las colinas al norte y al este de {area:202}."
	["The bears roam the hills north and east of the {area:202}."] = "Los osos deambulan por las colinas al norte y al este de {area:202}.",

	-- Step 37: Mulgris Deepriver
	-- {npc:5770} Nara Wildmane · {zone:1456} Thunder Bluff
	-- was: ["Keep the branch: {npc:5770} is in {zone:1456}."] = "Guarda la rama: {npc:5770} está en {zone:1456}."
	["Keep the branch: {npc:5770} is in {zone:1456}."] = "Guarda la rama: {npc:5770} está en {zone:1456}.",

	-- Step 39: To Augustus the Touched
	-- {npc:12384} Augustus the Touched
	["To {npc:12384}"] = "A {npc:12384}",

	-- Step 40: Augustus the Touched
	-- {area:28} Western Plaguelands · {area:139} Eastern Plaguelands · {area:2627} Terrordale · {npc:12384} Augustus the Touched
	["Follow the road east through the {area:28} and across the river into the {area:139}; leave it north for {area:2627}, the ruined town in the north-west. {npc:12384} sits in a hut at its edge."] = "Sigue el camino al este a través de {area:28} y cruza el río hasta {area:139}; sal de él hacia el norte hasta {area:2627}, el pueblo en ruinas del noroeste. {npc:12384} está en una choza en su borde.",
	-- {area:2627} Terrordale
	["Inside; walks around {area:2627}: the map marks where to look"] = "Adentro; camina por {area:2627}: el mapa marca dónde buscar",

	-- Step 42: Terrordale: kill these as you meet them
	-- {area:2627} Terrordale · {item:15042} Empty Termite Jar
	-- plural, as words: Large Termite Mounds = {object:177464} Large Termite Mound
	-- was: ["The book lies in the ruined inn of {area:2627}; the undead in the town are 54-56, so pull them one at a time.\nThe Large Termite Mounds stand all over the hills east of {area:2627}. Use the {item:15042} on each mound you pass."] = "El libro está en la posada en ruinas de {area:2627}; los no-muertos del pueblo son de nivel 54-56, así que atráelos de uno en uno.\nLos Grandes Montículos de Termitas están por todas las colinas al este de {area:2627}. Usa el {item:15042} en cada montículo por el que pases."
	["The book lies in the ruined inn of {area:2627}; the undead in the town are 54-56, so pull them one at a time.\nThe Large Termite Mounds stand all over the hills east of {area:2627}. Use the {item:15042} on each mound you pass."] = "El libro está en la posada en ruinas de {area:2627}; los no-muertos del pueblo son de nivel 54-56, así que atráelos de uno en uno.\\nLos grandes montículos de termitas están por todas las colinas al este de {area:2627}. Usa el {item:15042} en cada montículo que pases.",
	-- {quest:5408} Minion's Scourgestones · {area:2627} Terrordale · {item:12846} Argent Dawn Commission
	-- was: ["{quest:5408}: the {area:2627} undead drop them while you wear the {item:12846}"] = "{quest:5408}: los no-muertos de {area:2627} las sueltan mientras llevas puesta {item:12846}"
	["{quest:5408}: the {area:2627} undead drop them while you wear the {item:12846}"] = "{quest:5408}: los no-muertos de {area:2627} las sueltan mientras llevas puesto {item:12846}",
	-- {quest:6164} Augustus' Receipt Book · {npc:12384} Augustus the Touched · {area:139} Eastern Plaguelands · {area:2627} Terrordale
	-- was: ["Keep {quest:6164}: {npc:12384} takes it back on the {zone:1423} guide's {area:2627} stop."] = "Guarda {quest:6164}: {npc:12384} lo recibe de vuelta en la parada de {area:2627} de la guía de {zone:1423}."
	["Keep {quest:6164}: {npc:12384} takes it back on the {area:139} guide's {area:2627} stop."] = "Guarda {quest:6164}: {npc:12384} la recibe en la parada de {area:2627} de la guía de {area:139}.",

	-- Step 43: Into Tirisfal Glades
	-- {zone:1420} Tirisfal Glades
	["Into {zone:1420}"] = "Entra a {zone:1420}",

	-- Step 44: Bulwark
	-- {npc:11615} Mickey Levine
	-- was: ["Derrington's watchtowers, Vandis' cauldron and {npc:11615}'s barrel are done on a later visit: keep them."] = "Las atalayas de Derrington, la caldera de Vandis y la barrica de {npc:11615} se hacen en una visita posterior: guárdalas."
	["Derrington's watchtowers, Vandis' cauldron and {npc:11615}'s barrel are done on a later visit: keep them."] = "Las atalayas de Derrington, la caldera de Vandis y la barrica de {npc:11615} se hacen en una visita posterior: guárdalas.",

	-- Step 45: To Class trainer
	["To Class trainer"] = "Al instructor de tu clase",

	-- Step 46: Class trainer
	["Class trainer"] = "Instructor de clase",

	-- Step 47: Warrior trainer
	["Warrior trainer"] = "Instructor de guerrero",
	-- {npc:252377} Seena Skybreaker · {area:159} Brill
	["{npc:252377} in Zephras Isle; {area:159} has no warrior trainer"] = "{npc:252377} en Zephras Isle; {area:159} no tiene instructor de guerrero",

	-- Step 48: Hunter trainer
	["Hunter trainer"] = "Instructor de cazadores",
	-- {npc:252389} Quel'ana Quickgale · {area:159} Brill
	["{npc:252389} in Zephras Isle; {area:159} has no hunter trainer"] = "{npc:252389} en Zephras Isle; {area:159} no tiene instructor de cazador",

	-- Step 49: Rogue trainer
	["Rogue trainer"] = "Instructor de pícaro",
	-- {npc:252379} Eltheen Nightbreeze · {area:159} Brill
	["{npc:252379} in Zephras Isle; {area:159} has no rogue trainer"] = "{npc:252379} en Zephras Isle; {area:159} no tiene instructor de pícaros",

	-- Step 50: Shaman trainer
	["Shaman trainer"] = "Instructor de chamanes",
	-- {npc:258113} Ingrid Dunwald · {zone:1426} Dun Morogh · {area:159} Brill
	["{npc:258113} in {zone:1426}; {area:159} has no shaman trainer"] = "{npc:258113} en {zone:1426}; {area:159} no tiene instructor de chamán",

	-- Step 51: Mage trainer
	["Mage trainer"] = "Instructor de mago",
	-- {npc:252373} Anathamaas Aetherwind · {area:159} Brill
	["{npc:252373} in Zephras Isle; {area:159} has no mage trainer"] = "{npc:252373} en Zephras Isle; {area:159} no tiene instructor de magos",

	-- Step 52: Druid trainer
	["Druid trainer"] = "Instructor de druidas",
	-- {npc:252359} Lotheluum Starbreeze · {area:159} Brill
	["{npc:252359} in Zephras Isle; {area:159} has no druid trainer"] = "{npc:252359} en Zephras Isle; {area:159} no tiene instructor de druida",

	-- Step 53: Zeppelin to Orgrimmar
	-- {zone:1454} Orgrimmar
	["Zeppelin to {zone:1454}"] = "Zepelín a {zone:1454}",

	-- Step 54: To Orgrimmar
	-- {zone:1454} Orgrimmar
	["To {zone:1454}"] = "A {zone:1454}",

	-- Step 55: Fly to Splintertree Post
	-- {area:431} Splintertree Post
	["Fly to {area:431}"] = "Vuela a {area:431}",
	-- {zone:1454} Orgrimmar
	["{zone:1454} flight master"] = "Maestro de vuelo de {zone:1454}",

	-- Step 56: To Emerald Sanctuary
	-- {area:2479} Emerald Sanctuary
	["To {area:2479}"] = "A {area:2479}",

	-- Step 57: Emerald Sanctuary
	["The druids' camp is just past the border."] = "El campamento de los druidas está justo pasada la frontera.",
	-- {npc:11554} Grazle
	["{npc:11554}, at the south edge of the camp"] = "{npc:11554}, en el borde sur del campamento",
	-- {npc:9529} Maybess Riverbreeze
	-- was: ["{npc:9529}, just west of the camp"] = "{npc:9529}, justo al oeste del campamento"
	["{npc:9529}, just west of the camp"] = "{npc:9529}, justo al oeste del campamento",

	-- Step 58: Southern Jaedenar
	-- {area:1763} Jaedenar
	["Southern {area:1763}"] = "Sur de {area:1763}",
	-- {area:1763} Jaedenar
	["Follow the road north-west. The south of {area:1763}, around its corrupted moonwell, is held by Shadow Council cultists, adepts, guardsmen and their hounds."] = "Sigue el camino al noroeste. El sur de {area:1763}, alrededor de su pozo de la luna corrupto, lo ocupan sectarios, adeptos, guardias y canes del Consejo de la Sombra.",

	-- Step 59: A Strange Red Key
	-- {item:13140} Blood Red Key · {npc:11018} Arko'narin · {area:1770} Shadow Hold · {area:1763} Jaedenar
	-- was: ["Only if a {item:13140} dropped: use it to start the quest, then free {npc:11018} in her cage in {area:1770}, the cave at the north end of {area:1763}, and escort her out."] = "Solo si cayó una {item:13140}: úsala para iniciar la misión, luego libera a {npc:11018} de su jaula en {area:1770}, la cueva del extremo norte de {area:1763}, y escóltala afuera."
	["Only if a {item:13140} dropped: use it to start the quest, then free {npc:11018} in her cage in {area:1770}, the cave at the north end of {area:1763}, and escort her out."] = "Solo si cayó una {item:13140}: úsala para iniciar la misión, luego libera a {npc:11018} de su jaula en {area:1770}, la cueva en el extremo norte de {area:1763}, y escóltala hasta afuera.",
	-- {npc:11016} Captured Arko'narin
	-- was: ["{npc:11016}, below ground"] = "{npc:11016}, bajo tierra"
	["{npc:11016}, below ground"] = "{npc:11016}, bajo tierra",

	-- Step 61: Captured Arko'narin
	["Below ground"] = "Bajo tierra",

	-- Step 64: Deadwood Village
	-- {area:1769} Timbermaw Hold
	["The Deadwood furbolg village lies just south of the Sanctuary. Every Deadwood kill also raises your {area:1769} reputation; keep the headdress feathers."] = "La aldea de los fúrbolgs Muertobosque está justo al sur del Santuario. Cada Muertobosque que mates también sube tu reputación con {area:1769}; guarda las plumas de penacho.",

	-- Step 65: Grazle
	-- plural, as words: Deadwood Headdress Feathers = {item:21377} Deadwood Headdress Feather
	-- was: ["Only with 5 Deadwood Headdress Feathers"] = "Solo con 5 plumas de penacho de Muertobosque"
	["Only with 5 Deadwood Headdress Feathers"] = "Solo con 5 Deadwood Headdress Feathers",

	-- Step 67: Nafien
	-- {npc:15395} Nafien · {area:1769} Timbermaw Hold
	["The road ends at {npc:15395}, outside the {area:1769} tunnel in the far north-east."] = "El camino termina en {npc:15395}, fuera del túnel de {area:1769}, en el extremo noreste.",

	-- Step 68: Felpaw Village
	-- {npc:9462} Chieftain Bloodmaw
	["The Deadwood furbolg village just west of the tunnel. {npc:9462} (56) stands among them."] = "La aldea de los furbolgs Deadwood justo al oeste del túnel. {npc:9462} (56) está entre ellos.",

	-- Step 69: Nafien
	-- {quest:8465} Speak to Salfa · {zone:1452} Winterspring
	["Keep {quest:8465} for {zone:1452}."] = "Guarda {quest:8465} para {zone:1452}.",

	-- Step 70: Felpaw Village
	-- {npc:11557} Meilosh · {quest:6031} Runecloth · {area:1769} Timbermaw Hold
	["{npc:11557}, a friendly furbolg, sits at the north end of the village. Only with 30 {quest:6031}, and only at Neutral with the Timbermaw: follow the road north to {area:1769}; {npc:11557} trades just inside the entrance."] = "{npc:11557}, un fúrbolg amistoso, está en el extremo norte de la aldea. Solo con 30 {quest:6031}, y solo con reputación Neutral con los Timbermaw: sigue el camino al norte hasta {area:1769}; {npc:11557} comercia justo dentro de la entrada.",
	-- {npc:11557} Meilosh · {quest:6031} Runecloth
	["{npc:11557}: keep 30 {quest:6031} for him; he trades only at Neutral with the Timbermaw; below ground"] = "{npc:11557}: guarda 30 {quest:6031} para él; solo comercia si eres Neutral con los Fauces de Madera; bajo tierra",

	-- Step 71: Through Timbermaw Hold
	-- {area:1769} Timbermaw Hold
	-- was: ["Through {area:1769}"] = "A través de {area:1769}"
	["Through {area:1769}"] = "Por {area:1769}",
	-- {area:1769} Timbermaw Hold · {npc:15395} Nafien · {npc:11556} Salfa · {zone:1452} Winterspring · {area:2255} Everlook
	["Walk into the {area:1769} tunnel beside {npc:15395} and never attack the Timbermaw furbolgs inside. {npc:11556} stands at the tunnel's {zone:1452} exit; then follow the road east to {area:2255}, the goblin town where the next guide starts."] = "Entra al túnel de {area:1769} junto a {npc:15395} y nunca ataques a los furbolgs Timbermaw de adentro. {npc:11556} está en la salida del túnel hacia {zone:1452}; luego sigue el camino al este hasta {area:2255}, el pueblo goblin donde empieza la siguiente guía.",

	-- Step 72: Fly to Valormok
	-- {area:1237} Valormok
	["Fly to {area:1237}"] = "Vuela a {area:1237}",
	-- {area:1997} Bloodvenom Post
	["{area:1997} flight master"] = "Maestro de vuelo de {area:1997}",

	-- Step 73: Into Ashenvale
	-- {zone:1440} Ashenvale
	["Into {zone:1440}"] = "Hacia {zone:1440}",

	-- Step 74: Into Felwood
	-- {zone:1448} Felwood
	["Into {zone:1448}"] = "Entra a {zone:1448}",

	-- Step 75: Into Winterspring
	-- {zone:1452} Winterspring
	["Into {zone:1452}"] = "Hacia {zone:1452}",

	-- Step 76: To Everlook
	-- {area:2255} Everlook
	["To {area:2255}"] = "A {area:2255}",

	-- Step 78: Fly to Bloodvenom Post
	-- {area:1997} Bloodvenom Post
	["Fly to {area:1997}"] = "Vuela a {area:1997}",

	-- Step 80: On the way
	["On the way"] = "Por el camino",

	-- Step 81: The Jaedenar moonwell
	-- {area:1763} Jaedenar
	["The {area:1763} moonwell"] = "El pozo de la luna de {area:1763}",
	-- {area:1763} Jaedenar · {npc:10922} Greta Mosshoof
	-- was: ["Back north to {area:1763}. Fill Greta's canteen at the corrupted moonwell in the middle of the southern camp."] = "De vuelta al norte a {area:1763}. Llena la cantimplora de Greta en el pozo de la luna corrupto en medio del campamento sur."
	["Back north to {area:1763}. Fill {npc:10922}'s canteen at the corrupted moonwell in the middle of the southern camp."] = "De vuelta al norte a {area:1763}. Llena la cantimplora de {npc:10922} en el pozo lunar corrupto en medio del campamento sur.",

	-- Step 82: Rakaiah
	-- {npc:11018} Arko'narin · {npc:9518} Rakaiah · {area:1763} Jaedenar · {npc:11020} Remains of Trey Lightforge
	-- was: ["Only if you rescued {npc:11018}: the succubus {npc:9518} waits in the middle of {area:1763}, beside the {npc:11020}."] = "Solo si rescataste a {npc:11018}: la súcubo {npc:9518} espera en medio de {area:1763}, junto a {npc:11020}."
	["Only if you rescued {npc:11018}: the succubus {npc:9518} waits in the middle of {area:1763}, beside the {npc:11020}."] = "Solo si rescataste a {npc:11018}: la súcubo {npc:9518} espera en medio de {area:1763}, junto al {npc:11020}.",

	-- Step 83: Bloodvenom Post
	-- {area:1763} Jaedenar
	["The Horde camp just north of {area:1763}."] = "El campamento de la Horda justo al norte de {area:1763}.",
	-- {npc:10306} Trull Failbane · {zone:1452} Winterspring
	["{npc:10306}: the owlbeasts are in {zone:1452}"] = "{npc:10306}: las lechubestias están en {zone:1452}",

	-- Step 84: Shatter Scar Vale
	-- plural, as words: Entropic Beasts = {npc:9878} Entropic Beast
	["East of Bloodvenom Post, the cratered vale where the Entropic Beasts and Horrors roam. Kill two of each, then walk to each of the three fel-water craters."] = "Al este de Puesto del Veneno, la cañada de cráteres donde deambulan las bestias entrópicas ({npc:9878}) y los horrores. Mata dos de cada uno y luego camina hasta cada uno de los tres cráteres de agua vil.",
	["Southern crater"] = "Cráter sur",
	["Western crater"] = "Cráter oeste",
	["Northern crater"] = "Cráter norte",

	-- Step 85: Irontree Woods: kill these as you meet them
	-- {area:1767} Irontree Woods
	["{area:1767}: kill these as you meet them"] = "{area:1767}: mata a estos según te los encuentres",
	-- {area:1767} Irontree Woods · {item:11503} Blood Amber · {area:1997} Bloodvenom Post · {area:2479} Emerald Sanctuary · {area:1584} Blackrock Depths · {area:1417} Sunken Temple
	-- plural, as words: Warpwood Moss Flayers = {npc:7100} Warpwood Moss Flayer · Felpaw Ravagers = {npc:8961} Felpaw Ravager
	-- was: ["Follow the road north-east to {area:1767}. The Warpwood Moss Flayers and Shredders on the east side of the woods each carry a {item:11503}; Angerclaw Grizzlies and Felpaw Ravagers roam the same woods for Talo. Below level 54.21, keep hunting the grizzlies and ravagers: the hand-ins at {area:1997} and the {area:2479} take you to level 55. Or, with a group, run the {area:1584} dungeon or the {area:1417} dungeon instead."] = "Sigue el camino al noreste hasta {area:1767}. Los desolladores y trituradores de musgo Madeguerra del lado este del bosque llevan cada uno {item:11503}; los osos pardos Zarpaira y los devastadores Zarpavil recorren el mismo bosque para Talo. Por debajo del nivel 54.21, sigue cazando osos y devastadores: las entregas en {area:1997} y {area:2479} te llevan al nivel 55. O, en grupo, haz la mazmorra {area:1584} o la mazmorra {area:1417}."
	["Follow the road north-east to {area:1767}. The Warpwood Moss Flayers and Shredders on the east side of the woods each carry a {item:11503}; Angerclaw Grizzlies and Felpaw Ravagers roam the same woods for Talo. Below level 54.21, keep hunting the grizzlies and ravagers: the hand-ins at {area:1997} and the {area:2479} take you to level 55. Or, with a group, run the {area:1584} dungeon or the {area:1417} dungeon instead."] = "Sigue el camino al noreste hasta {area:1767}. Los Desolladores y Trituradores de musgo Warpwood del lado este del bosque llevan cada uno {item:11503}; los Osos pardos Angerclaw y los Devastadores Felpaw recorren el mismo bosque para Talo. Por debajo del nivel 54.21, sigue cazando osos pardos y devastadores: las entregas en {area:1997} y {area:2479} te llevan al nivel 55. O, en grupo, haz la mazmorra {area:1584} o la mazmorra {area:1417}.",

	-- Step 86: Felpaw Village
	-- {quest:8470} Deadwood Ritual Totem
	-- was: ["{quest:8470}, a rare drop"] = "{quest:8470}, botín raro"
	["{quest:8470}, a rare drop"] = "{quest:8470}, botín raro",

	-- Step 87: Emerald Sanctuary
	-- {zone:1448} Felwood
	["Ride the road south through {zone:1448} to the Sanctuary."] = "Cabalga al sur por el camino a través de {zone:1448} hasta el Santuario.",
	-- {npc:9529} Maybess Riverbreeze
	["{npc:9529}, on the west side of the Sanctuary"] = "{npc:9529}, en el lado oeste del Santuario",
	-- {npc:5901} Islen Waterseer · {zone:1413} Barrens
	-- was: ["Keep {quest:5158}: {npc:5901} is in the {zone:1413}."] = "Guarda {quest:5158}: {npc:5901} está en {zone:1413}."
	["Keep Seeking Spiritual Aid: {npc:5901} is in the {zone:1413}."] = "Guarda Seeking Spiritual Aid: {npc:5901} está en {zone:1413}.",

	-- Step 88: Overlord Ror
	-- {area:1761} Deadwood Village
	["Ror stands at the far south end of {area:1761}."] = "Ror está en el extremo sur de {area:1761}.",

	-- Step 89: Bloodvenom Post
	["Ride north up the road again."] = "Cabalga otra vez al norte por el camino.",

	-- Step 92: Felpaw Village
	-- {area:1762} Felpaw Village
	-- was: ["Back at {area:1762}, the Deadwood furbolgs (53-54) are close to the tunnel and every kill raises your Timbermaw reputation."] = "De vuelta en {area:1762}, los fúrbolgs Muertobosque (53-54) están cerca del túnel y cada muerte sube tu reputación con los Fauces de Madera."
	["Back at {area:1762}, the Deadwood furbolgs (53-54) are close to the tunnel and every kill raises your Timbermaw reputation."] = "De vuelta en {area:1762}, los fúrbolgs Deadwood (53-54) están cerca del túnel y cada muerte sube tu reputación con los Timbermaw.",
	-- {npc:11558} Kernda
	-- was: ["{npc:11558}, at the tunnel mouth"] = "{npc:11558}, en la entrada del túnel"
	["{npc:11558}, at the tunnel mouth"] = "{npc:11558}, a la entrada del túnel",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["A {item:13140} dropped: use it to start the quest, then free {npc:11018} from her cage in {area:1770}, the cave at the north end of {area:1763}."] = "Te salió {item:13140}: úsala para empezar la misión y luego libera a {npc:11018} de su jaula en {area:1770}, la cueva en el extremo norte de {area:1763}.",
	-- ["Back at the {area:2479}."] = "De vuelta en {area:2479}.",
	-- ["Back at {area:1762}, the Deadwood furbolgs (53-54) are close to the tunnel and every kill raises your Timbermaw reputation."] = "De vuelta en {area:1762}, los fúrbolgs Muertobosque (53-54) están cerca del túnel y cada muerte sube tu reputación con los Fauces de Madera.",
	-- ["Back north to {area:1763}. Fill Greta's canteen at the corrupted moonwell in the middle of the southern camp."] = "De vuelta al norte a {area:1763}. Llena la cantimplora de Greta en el pozo de la luna corrupto en medio del campamento sur.",
	-- ["Careful: Den Watchers are level 53-54 and the Deadwood Avengers 54-55; they call nearby allies within 25 yd once below 50% health and run off for help below 15%.\nKeep killing them until one drops a {quest:8470}, about one kill in thirty, then right-click it: {npc:11558} in {area:1769} takes it once the Timbermaw are Neutral to you, now if they already are, or when the last guide passes the cave again at 59."] = "Cuidado: Los vigías del cubil son de nivel 53-54 y los Vengadores Muertobosque de 54-55; llaman a los aliados cercanos en 25 m al bajar del 50 % de salud y huyen a pedir ayuda por debajo del 15 %.\nSigue matándolos hasta que uno suelte {quest:8470}, más o menos una vez de cada treinta, y haz clic derecho sobre él: {npc:11558} en {area:1769} lo recibe cuando seas Neutral con los Fauces de Madera, ahora si ya lo eres, o cuando la última guía vuelva a pasar por la cueva a nivel 59.",
	-- ["Careful: Den Watchers are level 53-54; they call nearby allies within 25 yd once below 50% health and run off for help below 15%.\nBelow level 54.54, keep fighting the Deadwood here after {npc:15395}'s count: the hand-ins at {area:1769} and the {area:2479} take you to level 55. Or, with a group, run the {area:1584} dungeon or the {area:1417} dungeon instead.\nKeep killing them until one drops a {quest:8470}, about one kill in thirty, then right-click it: {npc:11558} in {area:1769} takes it once the Timbermaw are Neutral to you, now if they already are, or when the last guide passes the cave again at 59."] = "Cuidado: Los vigías de la guarida son de nivel 53-54; llaman a los aliados cercanos en 25 m al bajar del 50 % de salud y huyen a pedir ayuda por debajo del 15 %.\nPor debajo del nivel 54.54, sigue peleando con los Muertobosque aquí después del conteo de {npc:15395}: las entregas en {area:1769} y {area:2479} te llevan al nivel 55. O, en grupo, haz la mazmorra {area:1584} o la mazmorra {area:1417}.\nSigue matándolos hasta que uno suelte {quest:8470}, más o menos una vez de cada treinta, y haz clic derecho sobre él: {npc:11558} en {area:1769} lo recibe cuando seas Neutral con los Fauces de Madera, ahora si ya lo eres, o cuando la última guía vuelva a pasar por la cueva a nivel 59.",
	-- ["Cross the river east into {area:2627}, the ruined town in the north-west of the {zone:1423}. {npc:12384} sits in a hut at its edge."] = "Cruza el río al este hacia {area:2627}, el pueblo en ruinas del noroeste de {zone:1423}. {npc:12384} está sentado en una choza en su borde.",
	-- ["Derrington's watchtowers and Vandis' cauldron are done on a later visit: keep them."] = "Las atalayas de Derrington y la caldera de Vandis se hacen en una visita posterior: guárdalas.",
	-- ["Derrington's watchtowers, Vandis' cauldron and {npc:11615}'s barrel are done on a later visit: keep them."] = "Las atalayas de Derrington, la caldera de Vandis y la barrica de {npc:11615} se hacen en una visita posterior: guárdalas.",
	-- ["Diseased Grizzlies"] = "Osos pardos malsanos",
	-- ["Fly to the {area:1497}"] = "Vuela a {area:1497}",
	-- ["Fly to {area:272}"] = "Vuela a {area:272}",
	-- ["Follow the road north-east to {area:1767}. The Warpwood Moss Flayers and Shredders on the east side of the woods each carry a {item:11503}; Angerclaw Grizzlies and Felpaw Ravagers roam the same woods for Talo, and their organs are {npc:10920}'s.\n{area:1762}'s Deadwood Den Watchers (53-54) and Avengers (54-55) are next: below level 54, keep hunting the grizzlies and ravagers (51-52) here until 54. The hand-ins at {area:1769}, the {area:2479} and {area:1997} that follow take you most of the way to 55. Or, with a group, run the {area:1417} dungeon or the {area:1584} dungeon instead."] = "Sigue el camino al noreste hasta {area:1767}. Los Arrancamusgos Alabeo y los trituradores del lado este del bosque llevan cada uno {item:11503}; los osos pardos Zarpaira y los Devastadores Zarpayel recorren el mismo bosque para Talo, y sus órganos son para {npc:10920}.\nLuego vienen los Vigías del cubil Muertobosque (53-54) y los vengadores (54-55) de {area:1762}: por debajo del nivel 54, sigue cazando osos y devastadores (51-52) aquí hasta el 54. Las entregas siguientes en {area:1769}, {area:2479} y {area:1997} te llevan casi hasta el 55. O, en grupo, haz el calabozo {area:1417} o el calabozo {area:1584}.",
	-- ["Follow the road north-east to {area:1767}. The Warpwood Moss Flayers and Shredders on the east side of the woods each carry a {item:11503}; Angerclaw Grizzlies and Felpaw Ravagers roam the same woods for Talo."] = "Sigue el camino al noreste hasta {area:1767}. Los arrancamusgos y machacadores Alabeo del lado este del bosque llevan cada uno un {item:11503}; los pardos Zarpira y los devastadores Zarpayel deambulan por el mismo bosque para Talo.",
	-- ["Follow the road north-east to {area:1767}. The Warpwood Moss Flayers and Shredders on the east side of the woods each carry a {item:11503}; Angerclaw Grizzlies and Felpaw Ravagers roam the same woods for Talo. Below level 54.21, keep hunting the grizzlies and ravagers: the hand-ins at {area:1997} and the {area:2479} take you to level 55. Or, with a group, run the {area:1584} dungeon or the {area:1417} dungeon instead."] = "Sigue el camino al noreste hasta {area:1767}. Los desolladores y trituradores de musgo Madeguerra del lado este del bosque llevan cada uno {item:11503}; los osos pardos Zarpaira y los devastadores Zarpavil recorren el mismo bosque para Talo. Por debajo del nivel 54.21, sigue cazando osos y devastadores: las entregas en {area:1997} y {area:2479} te llevan al nivel 55. O, en grupo, haz la mazmorra {area:1584} o la mazmorra {area:1417}.",
	-- ["From the {area:152}, follow the road east into the {zone:1422}. The Scarlet Crusade's tents stand just past Felstone Farm, between {area:199} and {area:200}. Torch the command tent with the {object:176092} and plant the Scourge banner. Careful: the Scarlets around the tents reach 54 and the Invokers cast: come in from the side nearest the command tent and leave the others be."] = "Desde {area:152}, sigue el camino al este hacia {zone:1422}. Las tiendas de la Cruzada Escarlata están justo pasando la Granja Piedramácula, entre {area:199} y {area:200}. Quema la tienda de mando con {object:176092} y planta el estandarte de la Plaga. Cuidado: los Escarlata alrededor de las tiendas llegan al nivel 54 y los invocadores lanzan hechizos: entra por el lado más cercano a la tienda de mando y deja en paz a los demás.",
	-- ["From {area:2268}'s flight master, fly to the {area:1497}."] = "Desde el maestro de vuelo de {area:2268}, vuela a {area:1497}.",
	-- ["His next hunt, the Diseased Grizzlies (55-56), waits for the Plaguelands visit at about 58."] = "Su siguiente cacería, los osos pardos enfermos (55-56), espera a la visita a las Tierras de la Peste hacia el nivel 58.",
	-- ["Jadefire moonwell"] = "Pozo de la luna Fuego de Jade",
	-- ["Keep Little Pamela: Pamela is in {area:2262}, visited again later."] = "Guarda La pequeña Pamela: Pamela está en {area:2262}, que visitarás de nuevo más adelante.",
	-- ["Keep the branch: {npc:5770} is in {zone:1456}."] = "Guarda la rama: {npc:5770} está en {zone:1456}.",
	-- ["Keep the parcel: {npc:10781} is in the {area:1497}."] = "Guarda el paquete: {npc:10781} está en {area:1497}.",
	-- ["Keep {quest:5158}: {npc:5901} is in the {zone:1413}."] = "Guarda {quest:5158}: {npc:5901} está en {zone:1413}.",
	-- ["Keep {quest:6164}: {npc:12384} takes it back on the {zone:1423} guide's {area:2627} stop."] = "Guarda {quest:6164}: {npc:12384} lo recibe de vuelta en la parada de {area:2627} de la guía de {zone:1423}.",
	-- ["Knights and magi work the {area:192}; the medics and hunters camp south of it."] = "Los caballeros y magus trabajan en {area:192}; los médicos y cazadores acampan al sur.",
	-- ["Leave the {area:1497} and ride east along the road through {zone:1420}, past the {area:152}. Felstone Farm is the first farm along the road; {npc:10778} waits in the house."] = "Sal de {area:1497} y cabalga al este por el camino a través de {zone:1420}, pasando {area:152}. La granja de Piedramácula es la primera granja del camino; {npc:10778} espera en la casa.",
	-- ["Level 52.63"] = "Nivel 52.63",
	-- ["Level 53"] = "Nivel 53",
	-- ["Level 53.34"] = "Nivel 53.34",
	-- ["Level 54.7"] = "Nivel 54.7",
	-- ["Level 54.87"] = "Nivel 54.87",
	-- ["Level 55"] = "Nivel 55",
	-- ["Only if a {item:13140} dropped: use it to start the quest, then free {npc:11018} in her cage in {area:1770}, the cave at the north end of {area:1763}, and escort her out."] = "Solo si cayó una {item:13140}: úsala para iniciar la misión, luego libera a {npc:11018} de su jaula en {area:1770}, la cueva del extremo norte de {area:1763}, y escóltala afuera.",
	-- ["Only if you rescued {npc:11018}: the succubus {npc:9518} waits in the middle of {area:1763}, beside the {npc:11020}."] = "Solo si rescataste a {npc:11018}: la súcubo {npc:9518} espera en medio de {area:1763}, junto a {npc:11020}.",
	-- ["Only with 5 Deadwood Headdress Feathers"] = "Solo con 5 plumas de penacho de Muertobosque",
	-- ["Paladin trainer"] = "Instructor de paladines",
	-- ["Radley and Durgen"] = "Radley y Durgen",
	-- ["Ride back south past {area:1763} to the corrupted moonwell of the Jadefire satyrs and fill {npc:9996}'s flasket there."] = "Cabalga de vuelta al sur pasando {area:1763} hasta el pozo de la luna corrupto de los sátiros Fuego de Jade y llena allí el frasquito de {npc:9996}.",
	-- ["Ride back south-east to the Sanctuary."] = "Cabalga de vuelta al sureste hasta el Santuario.",
	-- ["Ride back to the {area:1497}, take the zeppelin to {zone:1454} and fly to {area:431}. Follow the road west out of Splintertree and take the fork north into {zone:1448}."] = "Cabalga de vuelta a {area:1497}, toma el zepelín a {zone:1454} y vuela a {area:431}. Sigue el camino al oeste fuera del Puesto del Hachazo y toma el desvío al norte hacia {zone:1448}.",
	-- ["Ride back west over the river and on to the {area:192}; {npc:11610} hides on the hill north-east of it."] = "Cabalga de vuelta al oeste cruzando el río y sigue hasta {area:192}; {npc:11610} se esconde en la colina al noreste.",
	-- ["Ride north along the eastern hills; {npc:1855} lives in a small house by the {area:2619}, at the border with the {zone:1423}."] = "Cabalga al norte por las colinas del este; {npc:1855} vive en una casita junto a {area:2619}, en la frontera con {zone:1423}.",
	-- ["Ride north-west into Andorhal. {npc:10667} waits in the ruined inn on the west side of town; the skeletons inside are 54-57, so keep to the edges."] = "Cabalga al noroeste hacia Andorhal. {npc:10667} espera en la posada en ruinas del lado oeste del pueblo; los esqueletos de dentro son de nivel 54-57, así que no te alejes de los bordes.",
	-- ["Ride south past the {area:202} to {area:197}; {npc:10927}'s house stands by the road, and {npc:10936}'s monument is in the graveyard behind it. Kill the Diseased Wolves you meet in the fields on the way."] = "Cabalga al sur pasando {area:202} hasta {area:197}; la casa de {npc:10927} está junto al camino, y el monumento de {npc:10936} está en el cementerio detrás. Mata los lobos malsanos que encuentres en los campos por el camino.",
	-- ["Ride the road south through {area:361} to the Sanctuary."] = "Cabalga al sur por el camino a través de {area:361} hasta el Santuario.",
	-- ["Ride west to the {area:192}; {npc:11610} hides on the hill north-east of it."] = "Cabalga al oeste hasta {area:192}; {npc:11610} se esconde en la colina al noreste.",
	-- ["Scarlet Crusade"] = "Cruzada Escarlata",
	-- ["Scarlet forward camp"] = "Campamento avanzado Escarlata",
	-- ["Step into the cave: {npc:11558} stands just inside."] = "Entra a la cueva: {npc:11558} está justo en la entrada.",
	-- ["Take the kitten to the same moonwell and release it there with {item:12565}; once it has turned into a {npc:10042}, bring it back to {npc:9996} and click on it to hand it over."] = "Lleva al gatito al mismo pozo de la luna y suéltalo allí con {item:12565}; cuando se haya convertido en un {npc:10042}, llévaselo a {npc:9996} y haz clic en él para entregarlo.",
	-- ["Take the kitten to the same moonwell and release it there; once it has turned into a {npc:10042}, bring it back to {npc:9996} and click on it to hand it over."] = "Lleva al gatito al mismo pozo de la luna y suéltalo allí; cuando se haya convertido en un {npc:10042}, llévaselo a {npc:9996} y haz clic en él para entregarlo.",
	-- ["The Annals lie among the Musty Tomes in Andorhal's town hall; open them until you find the right one."] = "Las Crónicas están entre los libros enmohecidos del ayuntamiento de Andorhal; ábrelos hasta encontrar el correcto.",
	-- ["The Deadwood furbolg village just west of the tunnel. {npc:9462} (56) stands among them. {npc:11557}, a friendly furbolg, sits at the north end of the village."] = "La aldea de los fúrbolgs Muertobosque justo al oeste del túnel. {npc:9462} (56) está entre ellos. {npc:11557}, un fúrbolg amistoso, está sentado en el extremo norte de la aldea.",
	-- ["The Deadwood furbolg village lies just south of the Sanctuary. Every Deadwood kill also raises your {area:1769} reputation; keep the headdress feathers."] = "La aldea de los fúrbolgs Muertobosque está justo al sur del Santuario. Cada Muertobosque que mates también sube tu reputación con {area:1769}; guarda las plumas de penacho.",
	-- ["The Deadwood furbolg village lies just south of the Sanctuary. Every Deadwood kill also raises your {area:1769} reputation; keep the headdress feathers. Keep killing them until level 53.92: the Sanctuary's next hand-ins and {area:1763} want it. Or, with a group, run the {area:1417} dungeon or the {area:1584} dungeon instead."] = "La aldea de los fúrbolgs Muertobosque está justo al sur del Santuario. Cada Muertobosque que matas también sube tu reputación con {area:1769}; guarda las plumas de los tocados. Sigue matándolos hasta el nivel 53.92: las siguientes entregas del Santuario y {area:1763} lo piden. O, en grupo, haz la mazmorra {area:1417} o la mazmorra {area:1584}.",
	-- ["The Jadefire moonwell"] = "El pozo de la luna Fuego de Jade",
	-- ["The Scarlet Crusade's tents stand between {area:199} and {area:200}. Torch the command tent with the {object:176092} and plant the Scourge banner."] = "Las tiendas de la Cruzada Escarlata están entre {area:199} y {area:200}. Quema la tienda de mando con {object:176092} y planta el estandarte de la Plaga.",
	-- ["The bears roam the hills north and east of the {area:202}."] = "Los osos deambulan por las colinas al norte y al este de {area:202}.",
	-- ["The bears roam the hills north and east of the {area:202}. Below level 53.02, keep hunting them after the eighth: the hand-ins at the {area:202} take you to level 54. Or, with a group, run the {area:1417} dungeon or the {area:1584} dungeon instead."] = "Los osos recorren las colinas al norte y al este de {area:202}. Por debajo del nivel 53.02, sigue cazándolos después del octavo: las entregas en {area:202} te llevan al nivel 54. O, en grupo, haz la mazmorra {area:1417} o la mazmorra {area:1584}.",
	-- ["The book lies in the ruined inn of {area:2627}; the undead in the town are 54-56, so pull them one at a time.\nThe Large Termite Mounds stand all over the hills east of {area:2627}. Use the {item:15042} on each mound you pass."] = "El libro está en la posada en ruinas de {area:2627}; los no-muertos del pueblo son de nivel 54-56, así que atráelos de uno en uno.\nLos Grandes Montículos de Termitas están por todas las colinas al este de {area:2627}. Usa el {item:15042} en cada montículo por el que pases.",
	-- ["The middle of {zone:1454}"] = "El centro de {zone:1454}",
	-- ["The succubus {npc:9518} waits in the middle of {area:1763}, beside the {npc:11020}."] = "La súcubo {npc:9518} espera en el centro de {area:1763}, junto a {npc:11020}.",
	-- ["The wolves roam the fields between Andorhal, {area:200} and the {area:202}. Finish them on the ride back east."] = "Los lobos deambulan por los campos entre Andorhal, {area:200} y {area:202}. Termínalos en el camino de vuelta al este.",
	-- ["The wolves roam the fields between Andorhal, {area:200} and the {area:202}. Finish them on the ride back east. Careful: the biggest are 54: pull them one at a time."] = "Los lobos deambulan por los campos entre Andorhal, {area:200} y {area:202}. Termínalos en el camino de vuelta al este. Cuidado: los más grandes son de nivel 54: atráelos de uno en uno.",
	-- ["The {area:152}"] = "{area:152}",
	-- ["The {object:661778} stands just south of the vale, by the road north: its bauble starts a quest for {npc:9996} at {area:1997}."] = "La {object:661778} está justo al sur del valle, junto al camino al norte: su chuchería inicia una misión para {npc:9996} en {area:1997}.",
	-- ["Through {area:1769}"] = "A través de {area:1769}",
	-- ["To {zone:1448}"] = "A {zone:1448}",
	-- ["Top up here to level 52.63 before the hand-ins at {area:200}: they take you to level 53. The Carrion Lurkers (52-53) west of the Scarlet camp are at your level; the Scarlet Mages and Knights (54-56) are higher. Or, with a group, run the {area:1417} dungeon or the {area:2100} dungeon instead."] = "Completa aquí hasta el nivel 52.63 antes de las entregas en {area:200}: te llevan al nivel 53. Los acechadores carroñeros (52-53) al oeste del campamento Escarlata tienen tu nivel; los magos y caballeros Escarlata (54-56) son de nivel más alto. O, en grupo, haz la mazmorra {area:1417} o la mazmorra {area:2100}.",
	-- ["Top up here to level 53 before {npc:10739} sends you after the Diseased Grizzlies (55-56): the Carrion Lurkers (52-53) on the way from {area:200} to the {area:202} are at your level. Or, with a group, run the {area:1417} dungeon or the {area:1584} dungeon instead."] = "Completa aquí hasta el nivel 53 antes de que {npc:10739} te mande por los osos pardos malsanos (55-56): los acechadores carroñeros (52-53) del camino de {area:200} a {area:202} tienen tu nivel. O, en grupo, haz la mazmorra {area:1417} o la mazmorra {area:1584}.",
	-- ["Top up here to level 53.34 before the hand-ins at {area:1763}: they take you to level 54. Or, with a group, run the {area:1417} dungeon or the {area:1584} dungeon instead."] = "Completa aquí hasta el nivel 53.34 antes de las entregas en {area:1763}: te llevan al nivel 54. O, en grupo, haz la mazmorra {area:1417} o la mazmorra {area:1584}.",
	-- ["Top up here to level 54.7 before the hand-ins at {area:1997} : they take you to level 55. Or, with a group, run the {area:1584} dungeon or the {area:1417} dungeon instead."] = "Completa aquí hasta el nivel 54.7 antes de las entregas en {area:1997}: te llevan al nivel 55. O, en grupo, haz la mazmorra {area:1584} o la mazmorra {area:1417}.",
	-- ["Top up here to level 54.87 before the hand-ins in {zone:1452}: they take you to level 55. Or, with a group, run the {area:1584} dungeon or the {area:1417} dungeon instead."] = "Completa aquí hasta el nivel 54.87 antes de las entregas en {zone:1452}: te llevan al nivel 55. O, en grupo, haz la mazmorra {area:1584} o la mazmorra {area:1417}.",
	-- ["Upstairs"] = "Arriba",
	-- ["Walk into the {area:1769} tunnel beside {npc:15395} and never attack the Timbermaw furbolgs inside. The tunnel opens into {zone:1452}; follow the road east to {area:2255}, the goblin town where the next guide starts."] = "Entra en el túnel de {area:1769} junto a {npc:15395} y nunca ataques a los fúrbolgs Fauces de Madera de dentro. El túnel sale a {zone:1452}; sigue el camino al este hasta {area:2255}, el pueblo goblin donde empieza la siguiente guía.",
	-- ["Walk {npc:11018} out of {area:1770} and keep her alive until she is out of the cave."] = "Saca a {npc:11018} de {area:1770} y mantenla con vida hasta que salga de la cueva.",
	-- ["You missed this on the route's earlier visit here: it comes first now. It is quick and opens the quests after it.\nTake a {object:176092} from the crate next to Derrington for {quest:5096}."] = "No hiciste esto en la visita anterior de la ruta a esta zona: ahora va primero. Es rápido y abre las misiones que le siguen.\nToma una {object:176092} del cajón junto a Derrington para {quest:5096}.",
	-- ["grind on Deadwood Avengers at {area:1762}, {zone:1448}"] = "farmea vengadores Muertobosque en {area:1762}, {zone:1448}",
	-- ["grind on Scarlet Knights at {area:192}, {zone:1422}"] = "farmea caballeros Escarlata en {area:192}, {zone:1422}",
	-- ["grind on {npc:10605}"] = "sube de nivel con {npc:10605}",
	-- ["grind on {npc:1816}"] = "sube de nivel con {npc:1816}",
	-- ["grind on {npc:1821}"] = "sube de nivel con {npc:1821}",
	-- ["grind on {npc:7101}"] = "sube de nivel con {npc:7101}",
	-- ["grind on {npc:7125}"] = "sube de nivel con {npc:7125}",
	-- ["grind on {npc:7153}"] = "sube de nivel con {npc:7153}",
	-- ["grind on {npc:7155}"] = "sube de nivel con {npc:7155}",
	-- ["grind on {npc:7156}"] = "sube de nivel con {npc:7156}",
	-- ["grind on {npc:7157}"] = "sube de nivel con {npc:7157}",
	-- ["grind on {npc:8957}"] = "sube de nivel con {npc:8957}",
	-- ["{area:190}'s Scarlets are level 58-60. Ride in to the high point marked on your map, look over the town, and get out."] = "Los Escarlata de {area:190} son de nivel 58-60. Entra cabalgando hasta el punto alto marcado en tu mapa, observa el pueblo y sal.",
	-- ["{area:2627}: kill these as you meet them"] = "{area:2627}: mátalos cuando te los encuentres",
	-- ["{item:12565}, at the Jadefire moonwell"] = "{item:12565}, en el pozo de la luna Fuego de Jade",
	-- ["{item:277958}, from the Angerclaw bears"] = "{item:277958}, de los osos Zarpaira",
	-- ["{item:277959}, from the Felpaw wolves"] = "{item:277959}, de los lobos Zarpayel",
	-- ["{npc:10840}, at the graveyard's south end"] = "{npc:10840}, en el extremo sur del cementerio",
	-- ["{npc:10920}, beside {npc:10921}: {quest:86577}, the organs of {zone:1448}'s bears and wolves"] = "{npc:10920}, junto a {npc:10921}: {quest:86577}, los órganos de los osos y lobos de {zone:1448}",
	-- ["{npc:11016}, below ground"] = "{npc:11016}, bajo tierra",
	-- ["{npc:11018}, below ground"] = "{npc:11018}, bajo tierra",
	-- ["{npc:11020}, below ground"] = "{npc:11020}, bajo tierra",
	-- ["{npc:11557}: keep 30 {quest:6031} for him; he trades only at Neutral with the Timbermaw"] = "{npc:11557}: guárdale 30 {quest:6031}; solo comercia a partir de Neutral con los Fauces de Madera",
	-- ["{npc:11558}, at the tunnel mouth"] = "{npc:11558}, en la entrada del túnel",
	-- ["{npc:11558}: the Timbermaw speak to you only from Neutral; walks around here: look inside the circle on the map"] = "{npc:11558}: los Fauces de Madera solo te hablan desde Neutral; da vueltas por aquí: búscala dentro del círculo del mapa",
	-- ["{npc:11610}'s last task needs level 53. The Scarlet Knights and Magi (54-55) working the lumber camp just south-west of her are the closest camp."] = "La última tarea de {npc:11610} requiere nivel 53. Los caballeros y magus Escarlata (54-55) que trabajan en el aserradero justo al suroeste de ella son el campamento más cercano.",
	-- ["{npc:11613} stands east of the lumber camp; {npc:11611} guards the road north-east of {npc:11610}, toward {area:190}."] = "{npc:11613} está al este del aserradero; {npc:11611} vigila el camino al noreste de {npc:11610}, hacia {area:190}.",
	-- ["{npc:1855}'s hunts are in the {zone:1423}: keep them for later."] = "Las cacerías de {npc:1855} están en {zone:1423}: guárdalas para más adelante.",
	-- ["{npc:246152} in {zone:1420}; {zone:1454} has no paladin trainer"] = "{npc:246152} en {zone:1420}; {zone:1454} no tiene instructor de paladines",
	-- ["{npc:3034} in {zone:1412}; {zone:1454} has no druid trainer"] = "{npc:3034} en {zone:1412}; {zone:1454} no tiene instructor de druidas",
	-- ["{npc:8659} takes the ravasaur claws from Un'Goro; he stands in the {object:172960}, a short walk from the middle of the city."] = "{npc:8659} recibe las garras de ravasaurio de Un'Goro; está en {object:172960}, a poca distancia del centro de la ciudad.",
	-- ["{npc:8659}, the {object:172960}"] = "{npc:8659}, {object:172960}",
	-- ["{npc:9529}, just west of the camp"] = "{npc:9529}, justo al oeste del campamento",
	-- ["{npc:9529}, on the west side of the camp"] = "{npc:9529}, en el lado oeste del campamento",
	-- ["{npc:9996}'s kitten"] = "El gatito de {npc:9996}",
	-- ["{npc:9996}: the {quest:86612}"] = "{npc:9996}: {quest:86612}",
	-- ["{object:175894}, beside the house"] = "{object:175894}, junto a la casa",
	-- ["{quest:5210} goes to {area:2268}: keep it for later."] = "{quest:5210} va a {area:2268}: guárdala para más adelante.",
	-- ["{quest:5408}: the {area:2627} undead drop them while you wear the {item:12846}"] = "{quest:5408}: los no-muertos de {area:2627} las sueltan mientras llevas puesta {item:12846}",
	-- ["{quest:8470}, a rare drop"] = "{quest:8470}, botín raro",
	-- ["{zone:1452}'s quests are 55-58. Below 55 after {npc:9996}'s hand-ins? {area:1762}'s Deadwood furbolgs (53-55) are at your level and on your way north to {area:1769}'s tunnel: kill them until level 55. Every kill also raises your Timbermaw reputation. Careful: the Den Watchers and Avengers call nearby allies once below half health and run off for help when nearly dead: pull one at a time from the village's edge. This is a long top-up for a player who follows only this route. Or, with a group, run the {area:1584} dungeon or the {area:1417} dungeon instead."] = "Las misiones de {zone:1452} son de nivel 55-58. ¿Por debajo del 55 tras las entregas de {npc:9996}? Los fúrbolgs Muertobosque de {area:1762} (53-55) son de tu nivel y están de camino al norte hacia el túnel de {area:1769}: mátalos hasta el nivel 55. Cada muerte también sube tu reputación con los Fauces de Madera. Cuidado: los vigías y vengadores llaman a aliados cercanos al bajar de la mitad de salud y huyen a pedir ayuda casi muertos: atráelos de uno en uno desde el borde del poblado. Es un relleno largo si solo sigues esta ruta. O, en grupo, haz el calabozo {area:1584} o el calabozo {area:1417}.",
}
