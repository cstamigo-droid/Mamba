-- Spanish (Spain) (esES): the guide forever/horde/undead/02-silverpine-forest (forever/horde/undead/02-silverpine-forest.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: Brill
	-- {area:159} Brill · {npc:1738} Deathguard Terrence · {npc:1518} Apothecary Johaan · {npc:246152} Shari Stilwell
	["{area:159} is a short walk north up the road from the zeppelin towers: {npc:1738} stands by the road into town, {npc:1518} in the apothecary's house on the west side of the square; Paladins: {npc:246152} trains you in town."] = "{area:159} está a poca distancia al norte por el camino desde las torres de zepelín: {npc:1738} está junto al camino que entra al pueblo, {npc:1518} en la casa del boticario, en el lado oeste de la plaza; paladines: {npc:246152} te entrena en el pueblo.",
	-- {npc:1518} Apothecary Johaan
	["{npc:1518}, inside"] = "{npc:1518}, adentro",
	-- {npc:246152} Shari Stilwell · {area:159} Brill
	["{npc:246152}, in {area:159}"] = "{npc:246152}, en {area:159}",

	-- Step 2: To The Sepulcher
	-- {area:228} The Sepulcher
	["To {area:228}"] = "Hacia {area:228}",

	-- Step 3: The Sepulcher
	-- {area:228} The Sepulcher
	["{area:228} is the Forsaken crypt-town in the middle of the forest. Everyone you need stands around the crypt entrance."] = "{area:228} es la ciudad-cripta de los Renegados en medio del bosque. Todo lo que necesitas está alrededor de la entrada de la cripta.",
	-- {npc:1952} High Executor Hadrec
	["{npc:1952}, below ground"] = "{npc:1952}, bajo tierra",

	-- Step 4: Zeppelin to Undercity
	-- {zone:1458} Undercity
	["Zeppelin to {zone:1458}"] = "Zepelín a {zone:1458}",

	-- Step 5: Hadric Harlson
	-- {npc:1495} Deathguard Linnea · {npc:267009} Hadric Harlson
	["Back down the road past the zeppelin towers and east to {npc:1495}'s camp: {npc:267009} stands beside her."] = "De vuelta por el camino, pasando las torres de zepelín, y al este hasta el campamento de {npc:1495}: {npc:267009} está a su lado.",

	-- Step 6: The Cult of the Damned
	["The Cult of the Damned"] = "The Cult of the Damned",
	-- {npc:1495} Deathguard Linnea
	-- plural, as words: Necrotic Crystal Fragments = {item:275851} Necrotic Crystal Fragment
	["Follow the road south-east past {npc:1495}'s camp: the Cult of the Damned holds the farm just south-east of it. The Necrotic Crystal Fragments lie on the ground among the cultists, and the cultists carry some too."] = "Sigue el camino al sureste, pasando el campamento de {npc:1495}: el Cult of the Damned controla la granja justo al sureste de él. Los Necrotic Crystal Fragments están en el suelo entre los cultistas, y los cultistas también llevan algunos.",

	-- Step 9: The Sepulcher
	-- {npc:2226} Karos Razok
	["{npc:2226}, the bat handler, is just east of it."] = "{npc:2226}, el domador de murciélagos, está justo al este de allí.",

	-- Step 10: The Sepulcher
	-- {quest:264} Until Death Do Us Part · {object:24776} Yuriv's Tombstone
	["{quest:264} is handed in at {object:24776}, a grave a few steps south of the crypt entrance, not to a person."] = "{quest:264} se entrega en {object:24776}, una tumba a pocos pasos al sur de la entrada de la cripta, no a una persona.",

	-- Step 11: Border Crossings
	-- {object:1627} Dalaran Crate
	-- plural, as words: Dalaran Apprentices = {npc:1867} Dalaran Apprentice
	["Follow the road south. The {object:1627} sits beside it, north of Pyrewood. Careful: Dalaran Apprentices (13) stand around the crate: pull them one at a time before you open it."] = "Sigue el camino al sur. {object:1627} está a un lado, al norte de Aldea Piroleña. Cuidado: hay aprendices de Dalaran (13) alrededor de la caja: atráelos de uno en uno antes de abrirla.",

	-- Step 12: Malden's Orchard
	-- {area:238} Malden's Orchard
	["Follow the road north-east to the Yoricks' house at {area:238}."] = "Sigue el camino al noreste hasta la casa de los Yorick en {area:238}.",

	-- Step 13: Mottled Worgs
	-- plural, as words: Mottled Worgs = {npc:1766} Mottled Worg
	["Mottled Worgs"] = "Huargos jaspeados",
	-- plural, as words: Mottled Worgs = {npc:1766} Mottled Worg
	["Mottled Worgs prowl the hills around the house."] = "Los Huargos jaspeados merodean las colinas alrededor de la casa.",

	-- Step 14: Escorting Erland
	-- {npc:1978} Deathstalker Erland · {npc:1950} Rane Yorick
	["{npc:1978} waits north-east of the house. Escort him back to {npc:1950}; worgs attack on the way."] = "{npc:1978} espera al noreste de la casa. Escóltalo de vuelta con {npc:1950}; los huargos atacan en el camino.",
	-- {npc:1978} Deathstalker Erland
	["{npc:1978}, inside"] = "{npc:1978}, adentro",

	-- Step 17: The Sepulcher
	["Below ground"] = "Bajo tierra",
	-- {npc:1937} Apothecary Renferrel · {zone:1458} Undercity
	["{npc:1937}: Zinge in the {zone:1458}, on the way to the zeppelin at the end"] = "{npc:1937}: Zinge en {zone:1458}, de camino al zepelín al final",
	-- {npc:1938} Dalar Dawnweaver · {area:227} Valgan's Field
	["{npc:1938}: his books lie in the {area:227} farmhouse, on the walk north"] = "{npc:1938}: sus libros están en la granja de {area:227}, en el camino al norte",
	["Allister's Ambermill Investigations is for the ride through Silverpine at 22; leave it."] = "Las investigaciones de Allister en Molino Ámbar son para el paso por Bosque de Argénteos al nivel 22; déjala.",

	-- Step 18: Valgan's Field farmhouse
	-- {area:227} Valgan's Field
	["{area:227} farmhouse"] = "Granja de {area:227}",
	-- {area:227} Valgan's Field · {object:1571} Dusty Spellbooks · {npc:1770} Moonrage Darkrunner
	["On the road north, the farmhouse at {area:227}: go upstairs, the {object:1571} lie on the floor in the back room. Looting them brings a {npc:1770}."] = "En el camino al norte, la granja de {area:227}: sube al piso de arriba; {object:1571} están en el suelo del cuarto del fondo. Al saquearlos aparece un {npc:1770}.",
	-- {object:1571} Dusty Spellbooks
	["{object:1571}; upstairs"] = "{object:1571}; arriba",

	-- Step 19: Quinn Yorick
	["North again to the Yoricks' house."] = "De nuevo al norte, a la casa de los Yorick.",
	-- {npc:1951} Quinn Yorick
	["{npc:1951}, inside"] = "{npc:1951}, adentro",

	-- Step 20: The Ivar Patch
	-- {zone:1420} Tirisfal Glades · {area:238} Malden's Orchard · {quest:425} Ivar the Foul
	["Take the road north toward {zone:1420}: the Yoricks' house at {area:238} is on the way. {quest:425} lurks a short walk west of it."] = "Toma el camino al norte hacia {zone:1420}: la casa de los Yorick en {area:238} está de camino. {quest:425} acecha a poca distancia al oeste.",
	["Inside"] = "Adentro",

	-- Step 21: Vile Fin murlocs
	["Vile Fin murlocs"] = "Múrlocs Anca Vil",
	-- plural, as words: Vile Fin Shredders = {npc:1767} Vile Fin Shredder
	["Follow the lake shore south-east from the Yoricks' house: the Vile Fin Shredders and Tidehunters along it drop the murloc eyes."] = "Sigue la orilla del lago hacia el sureste desde la casa de los Yorick: los Machacadores Anca Vil y Cazamareas Anca Vil de allí sueltan los ojos de múrloc.",

	-- Step 22: The Sepulcher
	-- {area:228} The Sepulcher
	["From the ferry back west up the road to the {area:228}."] = "Desde el embarcadero, de vuelta al oeste por el camino hasta {area:228}.",
	-- {npc:1937} Apothecary Renferrel
	["{npc:1937}: for Quinn, on the road north at the end"] = "{npc:1937}: para Quinn, en el camino al norte al final",
	-- {npc:1938} Dalar Dawnweaver
	["{npc:1938}, just north of Allister"] = "{npc:1938}, justo al norte de Allister",

	-- Step 23: To Gallows' End Tavern
	-- {area:2119} Gallows' End Tavern
	["To {area:2119}"] = "A {area:2119}",

	-- Step 24: Class trainer
	["Class trainer"] = "Instructor de clase",

	-- Step 25: Shaman trainer
	["Shaman trainer"] = "Instructor de chamanes",
	-- {npc:258113} Ingrid Dunwald · {zone:1426} Dun Morogh · {area:159} Brill
	["{npc:258113} in {zone:1426}; {area:159} has no shaman trainer"] = "{npc:258113} en {zone:1426}; {area:159} no tiene instructor de chamán",

	-- Step 26: Druid trainer
	["Druid trainer"] = "Instructor de druidas",
	-- {npc:252359} Lotheluum Starbreeze · {area:159} Brill
	["{npc:252359} in Zephras Isle; {area:159} has no druid trainer"] = "{npc:252359} en Zephras Isle; {area:159} no tiene instructor de druida",

	-- Step 29: The Undercity
	-- {object:1661} The Undercity · {area:153} Ruins of Lordaeron · {npc:2050} Raleigh Andrean · {npc:7683} Alessandro Luca · {npc:11044} Doctor Martin Felben · {npc:5204} Apothecary Zinge · {npc:2055} Master Apothecary Faranell
	["{object:1661} lies under the {area:153}, beside the zeppelin towers. {npc:2050} stands at the inn by the way down; {npc:7683} on the way down to the Apothecarium, where {npc:11044} and {npc:5204} stand beside {npc:2055}."] = "{object:1661} está bajo {area:153}, junto a las torres de zepelín. {npc:2050} está en la posada, de bajada; {npc:7683}, de bajada a la botica real, donde {npc:11044} y {npc:5204} están junto a {npc:2055}.",
	-- {npc:5204} Apothecary Zinge
	["{npc:5204}, in the Apothecarium"] = "{npc:5204}, en la botica real",
	-- {npc:5204} Apothecary Zinge
	["{npc:5204}: Helbrim at the Crossroads, in the next guide"] = "{npc:5204}: Helbrim en el Cruce, en la siguiente guía",
	-- {npc:260093} Garen Largo · {area:1497} Undercity
	["{npc:260093}, the {area:1497}'s paladin trainer"] = "{npc:260093}, el instructor de paladines de {area:1497}",
	-- {npc:11044} Doctor Martin Felben
	["{npc:11044}, in the Apothecarium"] = "{npc:11044}, en la botica real",

	-- Step 30: Archibald
	-- {spell:202} Two-Handed Swords · {npc:11870} Archibald · {object:36070} War Quarter
	["While you're here: learn {spell:202} from {npc:11870} ({object:36070}, 10 silver); two-handers level a Warrior fastest."] = "Ya que estás aquí: aprende {spell:202} con {npc:11870} ({object:36070}, 10 de plata); las armas de dos manos hacen subir de nivel más rápido a un guerrero.",

	-- Step 31: Archibald
	-- {spell:202} Two-Handed Swords · {npc:11870} Archibald · {object:36070} War Quarter
	["While you're here: learn {spell:202} from {npc:11870} ({object:36070}, 10 silver); two-handers level a Paladin fastest."] = "Ya que estás aquí: aprende {spell:202} con {npc:11870} ({object:36070}, 10 de plata); las armas de dos manos hacen subir de nivel más rápido a un paladín.",

	-- Step 32: Archibald
	-- {npc:11870} Archibald · {object:36070} War Quarter
	["While you're here: learn Swords from {npc:11870} ({object:36070}, 10 silver); a sword in the main hand levels a Rogue steadily."] = "Ya que estás aquí: aprende Espadas con {npc:11870} ({object:36070}, 10 de plata); una espada en la mano principal hace subir de nivel a un pícaro de forma constante.",

	-- Step 33: Into Tirisfal Glades
	-- {zone:1420} Tirisfal Glades
	["Into {zone:1420}"] = "Entra a {zone:1420}",

	-- Step 34: Zeppelin to Orgrimmar
	-- {zone:1454} Orgrimmar
	["Zeppelin to {zone:1454}"] = "Zepelín a {zone:1454}",

	-- Step 35: To Orgrimmar
	-- {zone:1454} Orgrimmar
	["To {zone:1454}"] = "A {zone:1454}",

	-- Step 36: Orgrimmar
	-- {zone:1454} Orgrimmar
	["{zone:1454}'s main gate"] = "La puerta principal de {zone:1454}",

	-- Step 37: Valley of Strength
	-- {npc:268701} Thatog · {object:172982} Valley of Strength
	["Walk in through the main gate. {npc:268701} stands in the {object:172982}."] = "Entra por la puerta principal. {npc:268701} está en {object:172982}.",

	-- Step 38: Orgrimmar
	-- {npc:3310} Doras · {object:172982} Valley of Strength · {npc:6929} Innkeeper Gryshka · {npc:268701} Thatog · {zone:1421} Silverpine Forest · {area:17} Barrens
	["Walk in by the main gate. {npc:3310}, the wind rider master, stands on the tower in the {object:172982}; {npc:6929} keeps the inn below it, {npc:268701} stands by the bank. Bind here: the Hearthstone brings you back from {zone:1421} beside the zeppelin towers and the road to the {area:17}."] = "Entra por la puerta principal. {npc:3310}, el maestro de vuelo de los jinetes de viento, está en la torre de {object:172982}; {npc:6929} atiende la posada de abajo y {npc:268701} está junto al banco. Fija aquí tu hogar: la piedra de hogar te trae de vuelta desde {zone:1421} junto a las torres de zepelines y el camino a {area:17}.",

	-- Step 39: Neeru Fireblade
	-- {object:172960} Cleft of Shadow · {object:172982} Valley of Strength · {quest:829} Neeru Fireblade
	["The {object:172960} is the canyon under the {object:172982}; {quest:829} stands at its far end."] = "{object:172960} es el cañón bajo {object:172982}; {quest:829} está al fondo.",
	-- {quest:829} Neeru Fireblade · {quest:809} Ak'Zeloth · {area:379} Far Watch Post
	["{quest:829}: {quest:809} stands at {area:379}, on the next guide's road to the Crossroads"] = "{quest:829}: {quest:809} está en {area:379}, en el camino de la siguiente guía al Cruce",
	-- {quest:829} Neeru Fireblade · {quest:832} Burning Shadows · {item:4903} Eye of Burning Shadow · {area:14} Durotar
	["{quest:829}: {quest:832}, from the {item:4903} in {area:14}"] = "{quest:829}: {quest:832}, del {item:4903} en {area:14}",

	-- Step 40: The Drag
	-- {npc:3348} Kor'geld · {npc:3347} Yelmak · {npc:11046} Whuut
	["{npc:3348} and {npc:3347} run the alchemy shop in the Drag; {npc:11046} is next door."] = "{npc:3348} y {npc:3347} atienden la tienda de alquimia de la calle comercial de la ciudad; {npc:11046} está al lado.",

	-- Step 41: Jandi
	-- {npc:3404} Jandi
	["{npc:3404}, the herbalism trainer, keeps her shop in the Drag."] = "{npc:3404}, la instructora de herboristería, tiene su tienda en la calle comercial de la ciudad.",
	-- {npc:3404} Jandi · {area:14} Durotar
	["{npc:3404}: Camping 101, from Brakk's campfire in {area:14}"] = "{npc:3404}: Camping 101, de la fogata de Brakk en {area:14}",

	-- Step 42: Jhag
	-- {npc:11066} Jhag
	["{npc:11066}, the enchanting trainer, works in the Drag."] = "{npc:11066}, el instructor de encantamiento, trabaja en la calle comercial de la ciudad.",
	-- {npc:11066} Jhag · {area:14} Durotar
	["{npc:11066}: Camping 101, from Brakk's campfire in {area:14}"] = "{npc:11066}: Camping 101, desde la fogata de Brakk en {area:14}",

	-- Step 43: Valley of Honor
	-- {object:172958} Valley of Honor
	["The cattails and speargrass grow along the water in the {object:172958}, east of the Drag."] = "Las espadañas y el pasto lanza crecen junto al agua en {object:172958}, al este de la calle comercial de la ciudad.",

	-- Step 44: Thuwd
	-- {npc:7088} Thuwd · {object:172958} Valley of Honor
	["{npc:7088}, the skinning trainer, stands in the {object:172958}."] = "{npc:7088}, el instructor de desuello, está en {object:172958}.",
	-- {npc:7088} Thuwd · {area:14} Durotar
	["{npc:7088}: Camping 101, from Brakk's campfire in {area:14}"] = "{npc:7088}: Camping 101, de la fogata de Brakk en {area:14}",

	-- Step 45: Karolek
	-- {npc:3365} Karolek · {object:172958} Valley of Honor
	["{npc:3365}, the leatherworking trainer, works in the {object:172958}."] = "{npc:3365}, el instructor de peletería, trabaja en {object:172958}.",
	-- {npc:3365} Karolek · {area:14} Durotar
	["{npc:3365}: Camping 101, from Brakk's campfire in {area:14}"] = "{npc:3365}: Camping 101, desde la fogata de Brakk en {area:14}",

	-- Step 46: Snang
	-- {npc:2855} Snang · {object:172958} Valley of Honor
	["{npc:2855}, the tailoring trainer, is in the {object:172958}."] = "{npc:2855}, el instructor de sastrería, está en {object:172958}.",
	-- {npc:2855} Snang · {area:14} Durotar
	["{npc:2855}: Camping 101, from Brakk's campfire in {area:14}"] = "{npc:2855}: Camping 101, de la fogata de Brakk en {area:14}",

	-- Step 47: Sayoc
	-- {spell:197} Two-Handed Axes · {npc:11868} Sayoc · {object:172958} Valley of Honor
	["While you're here: learn {spell:197} from {npc:11868} ({object:172958}, 10 silver); two-handers level a Warrior fastest."] = "Ya que estás aquí: aprende {spell:197} con {npc:11868} ({object:172958}, 10 de plata); las armas de dos manos suben de nivel más rápido a un guerrero.",

	-- Step 48: Hanashi
	-- {npc:2704} Hanashi · {object:172958} Valley of Honor
	["While you're here: learn Staves from {npc:2704} ({object:172958}, 10 silver); a Hunter's melee weapon is mostly its stats, and two-handers carry the most."] = "Ya que estás aquí: aprende Bastones con {npc:2704} ({object:172958}, 10 de plata); el arma cuerpo a cuerpo de un cazador vale sobre todo por sus estadísticas, y las de dos manos son las que más tienen.",

	-- Step 49: Hanashi
	-- {npc:2704} Hanashi · {object:172958} Valley of Honor
	["While you're here: learn Staves from {npc:2704} ({object:172958}, 10 silver); a staff carries more spell stats than a one-hander while you level."] = "Ya que estás aquí: aprende Bastones con {npc:2704} ({object:172958}, 10 de plata); un bastón da más estadísticas de hechizo que un arma de una mano mientras subes de nivel.",

	-- Step 52: Whuut
	-- {npc:11046} Whuut · {npc:3348} Kor'geld
	["{npc:11046}, the alchemy trainer, stands next door to {npc:3348}."] = "{npc:11046}, el instructor de alquimia, está al lado de {npc:3348}.",
	-- {npc:11046} Whuut · {area:14} Durotar
	["{npc:11046}: Camping 101, from Brakk's campfire in {area:14}"] = "{npc:11046}: Camping 101, de la fogata de Brakk en {area:14}",

	-- Step 53: Valley of Wisdom
	-- {npc:268684} Thra · {object:172957} Valley of Wisdom
	-- plural, as words: Smooth Boulders = {item:277952} Smooth Boulder
	["{npc:268684} and Migi sit behind Grommash Hold in the {object:172957}; the Smooth Boulders lie around them."] = "{npc:268684} y Migi están detrás de Grommash Hold en {object:172957}; las Rocas lisas están a su alrededor.",

	-- Step 54: Thrall
	-- {npc:4949} Thrall · {quest:98024} Journey to the Crossroads · {quest:93739} Exploring the Horde · {quest:95350} Welcome to Azeroth
	["{npc:4949} stands in Grommash Hold. He offers {quest:98024} and {quest:93739} once {quest:95350} is handed in."] = "{npc:4949} está en la fortaleza de Thrall. Ofrece {quest:98024} y {quest:93739} una vez que entregas {quest:95350}.",
	-- {npc:4949} Thrall · {area:17} Barrens
	["{npc:4949}: keep it, Thork at the Crossroads in the {area:17} guide"] = "{npc:4949}: guárdala, Thork en el Cruce en la guía de {area:17}",
	-- {npc:4949} Thrall · {quest:93739} Exploring the Horde
	["{npc:4949}: {quest:93739}, a tour of the Horde's leaders"] = "{npc:4949}: {quest:93739}, un recorrido por los líderes de la Horda",
	-- {npc:3230} Nazgrel
	["Speak with {npc:3230}, in Grommash Hold"] = "Habla con {npc:3230}, en la fortaleza de Thrall",
	-- {npc:3230} Nazgrel
	["Talk to {npc:3230}"] = "Habla con {npc:3230}",
	-- {npc:10540} Vol'jin
	["Speak with {npc:10540}, in Grommash Hold"] = "Habla con {npc:10540}, en la fortaleza de Thrall",
	-- {npc:10540} Vol'jin
	["Talk to {npc:10540}"] = "Habla con {npc:10540}",

	-- Step 55: Thrall
	-- {npc:4949} Thrall
	["{npc:4949}, inside Grommash Hold"] = "{npc:4949}, dentro de la fortaleza de Thrall",

	-- Step 56: Nazgrel
	-- {npc:3230} Nazgrel
	["{npc:3230}, in Grommash Hold"] = "{npc:3230}, en la fortaleza de Thrall",

	-- Step 58: Deathguard Terrence
	-- {npc:1738} Deathguard Terrence · {quest:96895} The Argent Emissary · {npc:267009} Hadric Harlson · {area:159} Brill · {area:157} Agamand Mills
	["From level 10 {npc:1738} offers {quest:96895}: {npc:267009} waits at Linnea's camp, the next stop. Below 10 it waits for the {area:159} visit after {area:157}."] = "Desde el nivel 10, {npc:1738} ofrece {quest:96895}: {npc:267009} espera en el campamento de Linnea, la siguiente parada. Si eres menor de nivel 10, espera hasta tu visita a {area:159} después de {area:157}.",

	-- Step 61: Valley of Strength
	-- {object:173016} Borstan's Firepit
	["{object:173016} is a few steps north."] = "{object:173016} está a unos pasos al norte.",

	-- Step 63: Sayoc
	-- {spell:197} Two-Handed Axes · {npc:11868} Sayoc · {object:172958} Valley of Honor
	["While you're here: learn {spell:197} from {npc:11868} ({object:172958}, 10 silver); two-handers level a Paladin fastest."] = "Ya que estás aquí: aprende {spell:197} con {npc:11868} ({object:172958}, 10 de plata); las armas de dos manos suben de nivel más rápido a un paladín.",

	-- Step 65: Valley of Wisdom
	-- {npc:268684} Thra · {object:172957} Valley of Wisdom · {area:379} Far Watch Post
	-- plural, as words: Smooth Boulders = {item:277952} Smooth Boulder
	["{npc:268684} and Migi sit behind Grommash Hold in the {object:172957}; the Smooth Boulders lie around them. The next guide walks from here to {area:379} and the Crossroads."] = "{npc:268684} y Migi están detrás de Grommash Hold, en el {object:172957}; las Smooth Boulders están a su alrededor. La siguiente guía camina desde aquí hasta {area:379} y el Cruce.",

	-- Step 66: Zor Lonetree
	-- {npc:4047} Zor Lonetree · {npc:4049} Seereth Stonebreak
	["{npc:4047}: {npc:4049}, on the road into Stonetalon in the next guide"] = "{npc:4047}: {npc:4049}, en el camino hacia Stonetalon, en la siguiente guía",

	-- Step 73: To Crossroads
	["To Crossroads"] = "Al Cruce",
}
