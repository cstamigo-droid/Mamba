-- Spanish (Latin America) (esMX): the guide forever/alliance/nightelf/02-darkshore (forever/alliance/nightelf/02-darkshore.guide).
-- Written by `forge i18n guides sync esMX`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Latin America) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Latin America) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: Bears and the Blackwood camp
	["Bears and the Blackwood camp"] = "Osos y el campamento Bosque Negro",
	-- {area:442} Auberdine · {item:7586} Tharnariun's Hope
	-- plural, as words: Rabid Thistle Bears = {npc:2164} Rabid Thistle Bear
	["Rabid Thistle Bears roam the hills south of {area:442}: use {item:7586} on one to capture it. Then walk up to the furbolg camp just east of them: nothing to kill yet."] = "Los osos cardo rabiosos recorren las colinas al sur de {area:442}: usa {item:7586} en uno para capturarlo. Luego sube hasta el campamento de fúrbolgs justo al este de ellos: todavía no hay nada que matar.",
	-- {npc:3701} Tharnariun Treetender
	-- plural, as words: Rabid Thistle Bears = {npc:2164} Rabid Thistle Bear
	["the Rabid Thistle Bears nearest {npc:3701}"] = "los osos cardo rabiosos más cercanos a {npc:3701}",

	-- Step 2: Ameth'Aran
	-- {npc:3639} Sentinel Tysha Moonblade · {npc:2178} Wailing Highborne · {npc:3667} Anaya Dawnrunner · {quest:4722} Beached Sea Turtle
	-- was: ["{npc:3639} stands at the north edge of the ruins. Cursed, Writhing and {npc:2178} haunt them; {npc:3667}'s ghost walks among them, {npc:270196} the owl circles east of them. The two tablets lie in the ruins; a {quest:4722} lies on the shore west of them."] = "{npc:3639} está en el borde norte de las ruinas. Altonatos malditos, Altonatos en pena y {npc:2178} las rondan; el fantasma de {npc:3667} camina entre ellos y la lechuza {npc:270196} vuela en círculos al este. Las dos tablillas están en las ruinas; {quest:4722} yace en la orilla al oeste de ellas."
	["{npc:3639} stands at the north edge of the ruins. Cursed, Writhing and {npc:2178} haunt them; {npc:3667}'s ghost walks among them, Jai'vhanel the owl circles east of them. The two tablets lie in the ruins; a {quest:4722} lies on the shore west of them."] = "",
	-- plural, as words: Highborne Relics = {item:5360} Highborne Relic
	["Highborne Relics"] = "Reliquias de Altonato",
	-- {object:17188} Lay of Ameth'Aran
	["Read the {object:17188}"] = "Lee {object:17188}",
	-- {object:17189} Fall of Ameth'Aran
	["Read the {object:17189}"] = "Lee {object:17189}",

	-- Step 3: The red crystal
	["The red crystal"] = "El cristal rojo",
	-- {area:447} Ameth'Aran · {object:175524} Mysterious Red Crystal
	["Climb the eastern mountains east of {area:447}; the {object:175524} sits on a ledge."] = "Sube a las montañas al este de {area:447}; el {object:175524} está en una cornisa.",

	-- Step 4: Bashal'Aran
	-- {npc:3650} Asterion · {quest:954} Bashal'Aran · {object:17183} Buzzbox 411 · {quest:4723} Beached Sea Creature
	-- plural, as words: Wild Grells = {npc:2190} Wild Grell · Vile Sprites = {npc:2189} Vile Sprite · Deth'ryll Satyrs = {npc:2212} Deth'ryll Satyr
	["North along the hills. {npc:3650} waits in the ruins of {quest:954}; Wild Grells and Vile Sprites fill them, Deth'ryll Satyrs the eastern edge. {object:17183} stands by the road west of the ruins; a {quest:4723} lies on the shore on the way to him."] = "Al norte por las colinas. {npc:3650} espera en las ruinas de {quest:954}; las llenan grells salvajes y duendes viles, y los sátiros Deth'ryll ocupan el borde este. {object:17183} está junto al camino al oeste de las ruinas; un {quest:4723} yace en la orilla, de camino hacia él.",
	-- plural, as words: Grell Earrings = {item:5336} Grell Earring
	["Grell Earrings"] = "Pendientes grell",
	-- {item:5338} Ancient Moonstone Seal
	-- plural, as words: Deth'ryll Satyrs = {npc:2212} Deth'ryll Satyr
	["{item:5338}: Deth'ryll Satyrs"] = "{item:5338}: sátiros Deth'ryll",

	-- Step 6: Blackwood furbolgs
	["Blackwood furbolgs"] = "Fúrbolgs Bosque Negro",
	["Careful: the Windtalkers (13-14) cast from range and the furbolgs stand in pairs: pull them one at a time."] = "",
	-- {npc:2167} Blackwood Pathfinder
	["{npc:2167} walks around here: look inside the circle on the map"] = "",

	-- Step 7: Ameth'Aran
	-- {area:447} Ameth'Aran
	["Back north to {area:447}: the flame burns in the south of the ruins."] = "De vuelta al norte hasta {area:447}: la llama arde en el sur de las ruinas.",

	-- Step 8: Bashal'Aran
	-- {npc:3650} Asterion · {area:442} Auberdine
	["North along the hills to {npc:3650}, then west down to {area:442}."] = "Al norte por las colinas hasta {npc:3650}, luego al oeste, bajando hasta {area:442}.",

	-- Step 10: Boat to Stormwind Harbor
	-- {area:17203} Stormwind Harbor
	["Boat to {area:17203}"] = "Barco al {area:17203}",

	-- Step 11: Manifest Clerk Philmor
	-- {npc:268511} Manifest Clerk Philmor · {npc:483} Elaine Trias · {object:2096} Trade District
	["Off the boat, {npc:268511} stands on the harbor: his shipment goes to {npc:483}' cheese shop in the {object:2096}, beside the flight master."] = "Al bajar del barco, {npc:268511} está en el puerto: su envío va a la quesería de {npc:483} en {object:2096}, junto al maestro de vuelo.",

	-- Step 12: To Stormwind
	-- {zone:1453} Stormwind
	["To {zone:1453}"] = "",

	-- Step 13: Inn and flight master
	["Inn and flight master"] = "Posada y maestro de vuelo",

	-- Step 14: Baros Alexston
	-- {npc:1646} Baros Alexston · {object:2098} Cathedral Square · {object:2096} Trade District · {area:40} Westfall
	-- was: ["{npc:1646} stands in {object:2098}, west of the {object:2096}: his compass is in his old house in {zone:1436}, on the way."] = "{npc:1646} está en {object:2098}, al oeste de {object:2096}: su brújula está en su vieja casa de {zone:1436}, en el camino."
	["{npc:1646} stands in {object:2098}, west of the {object:2096}: his compass is in his old house in {area:40}, on the way."] = "",

	-- Step 15: Woo Ping
	-- {spell:202} Two-Handed Swords · {npc:11867} Woo Ping · {object:2096} Trade District
	["While you're here: learn {spell:202} from {npc:11867} ({object:2096}, 10 silver); two-handers level a Warrior fastest."] = "Ya que estás aquí: aprende {spell:202} con {npc:11867} ({object:2096}, 10 de plata); con armas de dos manos un guerrero sube de nivel más rápido.",

	-- Step 16: Woo Ping
	-- {npc:11867} Woo Ping · {object:2096} Trade District
	["While you're here: learn Swords from {npc:11867} ({object:2096}, 10 silver); a sword in the main hand levels a Rogue steadily."] = "Ya que estás aquí: aprende Espadas con {npc:11867} ({object:2096}, 10 de plata); una espada en la mano principal hace subir de nivel a un pícaro a buen ritmo.",

	-- Step 17: Stormwind flight master
	-- {zone:1453} Stormwind
	["{zone:1453} flight master"] = "Maestro de vuelo de {zone:1453}",
	-- {npc:483} Elaine Trias
	["{npc:483}, in her cheese shop"] = "{npc:483}, en su quesería",
	-- was: ["Up the stairs in her shop: leave the shipment at the {object:460004}"] = "Sube la escalera de su tienda: deja el envío en {object:460004}"
	["Up the stairs in her shop: leave the shipment at the Gatehouse Door"] = "",

	-- Step 20: Druid trainer
	["Druid trainer"] = "Instructor de druidas",
	-- {npc:5504} Sheldras Moontree · {zone:1453} Stormwind · {area:87} Goldshire
	["{npc:5504} in {zone:1453}; {area:87} has no druid trainer"] = "{npc:5504} en {zone:1453}; {area:87} no tiene instructor de druidas",

	-- Step 22: Class trainer
	["Class trainer"] = "Instructor de clase",

	-- Step 23: Shaman trainer
	["Shaman trainer"] = "Instructor de chamanes",
	-- {npc:257446} Teo Hammerstorm · {zone:1426} Dun Morogh · {area:87} Goldshire
	["{npc:257446} in {zone:1426}; {area:87} has no shaman trainer"] = "{npc:257446} en {zone:1426}; {area:87} no tiene instructor de chamanes",

	-- Step 26: Gubber Blump
	-- {npc:10216} Gubber Blump · {item:12238} Darkshore Grouper
	["Fishers only: {npc:10216} stands on the pier. His {item:12238} is fished from the pier itself."] = "",
	-- {npc:10216} Gubber Blump
	["{npc:10216}, on the pier"] = "",

	-- Step 27: Moonglade
	-- {spell:18960} Teleport: Moonglade · {npc:11802} Dendrite Starblaze · {area:2361} Nighthaven · {quest:5929} Great Bear Spirit · {area:493} Moonglade · {npc:10897} Sindrayl · {npc:11800} Silva Fil'naveth · {area:702} Rut'theran Village
	["Cast {spell:18960}. {npc:11802} is in {area:2361}; the {quest:5929} sits in the woods to the north-west. Learn {area:493}'s flight path from {npc:10897}, south of the lake, for later trips. Then {npc:11800} in {area:2361} flies Druids straight to {area:702} from her gossip: hers is no flight path to learn. {npc:11802} stands upstairs in his building: go up inside, the arrow cannot tell the floors apart."] = "",

	-- Step 28: Back to Darnassus
	-- {npc:10118} Nessa Shadowsong
	["{npc:10118} stands on the Rut'theran dock where you land."] = "",

	-- Step 30: Back to Darnassus
	-- {npc:4217} Mathrengyl Bearwalker · {area:1658} Cenarion Enclave
	["Then take the portal up to {npc:4217} in the {area:1658}."] = "",
	-- {npc:4217} Mathrengyl Bearwalker · {area:1658} Cenarion Enclave
	["{npc:4217}, in the {area:1658}"] = "",

	-- Step 31: Moonglade
	-- {spell:18960} Teleport: Moonglade · {npc:11802} Dendrite Starblaze · {area:2361} Nighthaven · {quest:5929} Great Bear Spirit · {quest:5921} Moonglade · {npc:10897} Sindrayl · {npc:11800} Silva Fil'naveth · {area:702} Rut'theran Village
	["Cast {spell:18960}. {npc:11802} is in {area:2361}; the {quest:5929} sits in the woods to the north-west. Learn {quest:5921}'s flight path from {npc:10897}, south of the lake, for later trips. Then {npc:11800} in {area:2361} flies Druids straight to {area:702} from her gossip: hers is no flight path to learn. {npc:11802} stands upstairs in his building: go up inside, the arrow cannot tell the floors apart."] = "",

	-- Step 32: Moonglade
	-- {quest:5929} Great Bear Spirit
	["Speak with the {quest:5929}"] = "",

	-- Step 36: The Moonkin Stone
	-- {object:177525} Moonkin Stone
	["The {object:177525}"] = "",
	-- {area:702} Rut'theran Village · {area:442} Auberdine · {object:177525} Moonkin Stone · {item:15208} Cenarion Moondust · {npc:12144} Lunaclaw Spirit
	["Go back down to {area:702} and fly to {area:442}. The {object:177525} stands in the hills just east of the village: use the {item:15208} there, defeat Lunaclaw and speak to the {npc:12144}."] = "",

	-- Step 37: Body and Heart
	-- {area:702} Rut'theran Village · {npc:4217} Mathrengyl Bearwalker · {area:442} Auberdine
	["Fly to {area:702} once more and take the portal up to {npc:4217}, then fly back to {area:442}."] = "",

	-- Step 38: Auberdine
	["You missed this on the route's earlier visit here: it comes first now. It is quick and opens the quests after it.\nThe boat docks west of the village. The flight master stands on the hill south of the inn; the quest givers are spread along the main street."] = "No hiciste esto en la visita anterior de la ruta a esta zona: ahora va primero. Es rápido y abre las misiones que le siguen.\nEl barco atraca al oeste del pueblo. El maestro de vuelo está en la colina al sur de la posada; los asignadores de misiones están repartidos por la calle principal.",
	["The WANTED poster outside the inn"] = "El cartel de SE BUSCA fuera de la posada",

	-- Step 39: To Auberdine
	-- {area:442} Auberdine
	["To {area:442}"] = "",

	-- Step 40: The skeletal turtle
	["The skeletal turtle"] = "La tortuga esquelética",
	-- {item:12289} Sea Turtle Remains
	["{item:12289}, on the beach west of the docks; underwater"] = "{item:12289}, en la playa al oeste de los muelles; bajo el agua",

	-- Step 43: Auberdine
	["Fill the tube at the moonwell in the village"] = "Llena el tubo en el pozo de la luna del pueblo",

	-- Step 44: The southern beaches
	["The southern beaches"] = "Las playas del sur",
	-- {area:447} Ameth'Aran · {quest:4728} Beached Sea Creature · {area:450} Remtravel's Excavation
	-- plural, as words: Greymist Oracles = {npc:2207} Greymist Oracle
	["Follow the coast south past {area:447}: one {quest:4728} lies on the shore west of the Grove, another further south near {area:450}. Three more remains lie further south-west among Greymist Oracles and Tidehunters (18-20): the guide leaves them for the last loop, when you are closer to their level."] = "Sigue la costa hacia el sur más allá de {area:447}: un {quest:4728} yace en la orilla al oeste del Páramo de los Ancianos y otro más al sur, cerca de {area:450}. Otros tres restos yacen más al suroeste entre oráculos Brumagris y cazamareas Brumagris (18-20): la guía los deja para la última vuelta, cuando estés más cerca de su nivel.",

	-- Step 47: Into Elwynn Forest
	-- {area:12} Elwynn Forest
	["Into {area:12}"] = "",

	-- Step 48: Goldshire
	-- {zone:1453} Stormwind · {area:40} Westfall · {area:87} Goldshire · {npc:241} Remy "Two Times" · {npc:240} Marshal Dughan · {quest:40} A Fishy Peril · {quest:35} Further Concerns · {npc:234} Gryan Stoutmantle
	["On the road from {zone:1453} to {area:40}, {area:87} is the first stop: {npc:241} stands outside the inn, {npc:240} beside him. {npc:241}'s {quest:40} goes straight to Dughan, who then gives {quest:35}; his Report to {npc:234} goes with you to {area:40}."] = "",

	-- Step 49: The Tower of Azora
	-- {area:91} Tower of Azora
	["The {area:91}"] = "",
	-- {area:18} Crystal Lake · {npc:248242} Hamish Bergwort · {npc:248248} Blixie Fitzwink
	["East along the road past {area:18}: {npc:248242} and {npc:248248} stand at the foot of the tower."] = "",

	-- Step 51: The bridge
	["The bridge"] = "",
	-- {npc:261} Guard Thomas · {npc:248265} Ormin Pelford
	-- plural, as words: Prowlers = {npc:118} Prowler
	["{npc:261} guards the bridge on the road east; {npc:248265} stands just across it. His tools and Thomas's Prowlers and bears are south of the bridge, on the way back."] = "",

	-- Step 52: The Eastvale Logging Camp
	-- {area:88} Eastvale Logging Camp
	["The {area:88}"] = "",
	-- {area:86} Stone Cairn Lake
	["Careful: Elmpaw, a level 12 elite gnoll, walks the woods and hills from the logging camp north to {area:86} and the gnoll camps: keep clear of him when you see him coming."] = "",
	-- {npc:278} Sara Timberlain
	["{npc:278}, inside"] = "",

	-- Step 53: A half-eaten body
	["It lies by the river north-west of the logging camp."] = "",

	-- Step 54: Stone Cairn Lake
	-- {npc:6866} Defias Bodyguard
	["Careful: the Rogue Wizards cast from range and a {npc:6866} (10) walks the shore with them: pull them one at a time."] = "",
	-- plural, as words: Red Linen Bandanas = {item:1019} Red Linen Bandana
	["Red Linen Bandanas"] = "",

	-- Step 55: The gnoll camps
	["The gnoll camps"] = "",
	-- {area:86} Stone Cairn Lake · {quest:91725} Stolen Enchanting Supplies
	["Riverpaw gnolls camp in the hills west of {area:86}; the {quest:91725} lie in their camps."] = "",

	-- Step 56: The Tower of Azora
	["Follow the hills south to the tower."] = "",

	-- Step 57: Downstream
	-- {item:247813} Waterlogged Saw · {area:62} Brackwell Pumpkin Patch · {npc:390} Porcine Entourage
	-- plural, as words: Prowlers = {npc:118} Prowler · Young Forest Bears = {npc:822} Young Forest Bear
	["The {item:247813}, Axe and Toolbox lie in the river south of the bridge. Princess, a big boar, roots in the {area:62} west of the river with her {npc:390}: pull the piglets away first. Kill Prowlers and Young Forest Bears on the way. Careful: Croaky is a level 11 elite on the murloc shore. Only go for his head with a group; otherwise leave him: it's optional."] = "",

	-- Step 58: Surena Caledon
	-- {item:6810} Surena's Choker · {npc:881} Surena Caledon · {area:62} Brackwell Pumpkin Patch
	["Gakin's The Binding needs {item:6810}: {npc:881} (level 9) stands by the farmhouse of the {area:62}, just south of the river."] = "",

	-- Step 62: Goldshire
	-- {area:87} Goldshire · {area:40} Westfall · {npc:240} Marshal Dughan
	["Follow the road west to {area:87}, on the way to {area:40}: {npc:240} stands outside the inn."] = "",

	-- Step 63: To The Jansen Stead
	-- {area:916} The Jansen Stead
	["To {area:916}"] = "",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["Back north-east into the mountains to the crystal."] = "Vuelve al noreste, a las montañas, hasta el cristal.",
	-- ["Blackwood Pathfinders and Windtalkers hold the camp south-east of {area:442}."] = "Los abrecaminos y soplavientos Bosque Negro ocupan el campamento al sureste de {area:442}.",
	-- ["Blackwood Pathfinders and Windtalkers hold the camp south-east of {area:442}.\nCareful: the Windtalkers (13-14) cast from range and the furbolgs stand in pairs: pull them one at a time."] = "Los Abrecaminos Bosque Negro y los Hablavientos ocupan el campamento al sureste de {area:442}.\nCuidado: los Hablavientos (13-14) lanzan hechizos a distancia y los fúrbolgs están en parejas: atráelos de uno en uno.",
	-- ["Crawler Legs: the Tide Crawlers"] = "Patas de reptador: los reptadores de la marea",
	-- ["Into {area:148}"] = "Hacia {area:148}",
	-- ["Only if you still carry {quest:983}'s quest: the Tide Crawlers scuttle along the shore below the village, and {quest:983} stands on the beach just south of the docks."] = "Solo si todavía llevas la misión de {quest:983}: los reptadores de la marea corren por la orilla debajo de la aldea, y {quest:983} está en la playa justo al sur de los muelles.",
	-- ["The beach"] = "La playa",
	-- ["The boat docks west of the village. The flight master stands on the hill south of the inn; the quest givers are spread along the main street."] = "El barco atraca al oeste del pueblo. El maestro de vuelo está en la colina al sur de la posada; los asignadores de misiones están repartidos por la calle principal.",
	-- ["The boat docks west of the village. The flight master stands on the hill south of the inn; the quest givers are spread along the main street. {npc:3666} stands upstairs in the inn: take the stairs inside, the arrow cannot tell the floors apart."] = "El barco atraca al oeste de la aldea. El maestro de vuelo está en la colina al sur de la posada; los que dan misiones están repartidos por la calle principal. {npc:3666} está arriba en la posada: sube por la escalera de adentro, la flecha no distingue los pisos.",
	-- ["Tide Crawlers scuttle along the shore below the village; {quest:983} stands on the beach just south of the docks. Darkshore Threshers swim in the shallows. The {object:175207} lies on the shore just south of the village."] = "Los Reptadores de marea ({npc:2232}) corretean por la orilla bajo el pueblo; {quest:983} está en la playa, justo al sur de los muelles. Los Trilladores de Costa Oscura ({npc:2185}) nadan en los bajíos. {object:175207} yace en la orilla, justo al sur del pueblo.",
	-- ["Up the stairs in her shop: leave the shipment at the {object:460004}"] = "Sube la escalera de su tienda: deja el envío en {object:460004}",
	-- ["{item:5382}: {npc:3667}, level 16; pull her away from the Highborne"] = "{item:5382}: {npc:3667}, nivel 16; aléjala de los Altonato",
	-- ["{npc:1646} stands in {object:2098}, west of the {object:2096}: his compass is in his old house in {zone:1436}, on the way."] = "{npc:1646} está en {object:2098}, al oeste de {object:2096}: su brújula está en su vieja casa de {zone:1436}, en el camino.",
	-- ["{npc:3639} stands at the north edge of the ruins. Cursed, Writhing and {npc:2178} haunt them; {npc:3667}'s ghost walks among them, {npc:270196} the owl circles east of them. The two tablets lie in the ruins; a {quest:4722} lies on the shore west of them."] = "{npc:3639} está en el borde norte de las ruinas. Altonatos malditos, Altonatos en pena y {npc:2178} las rondan; el fantasma de {npc:3667} camina entre ellos y la lechuza {npc:270196} vuela en círculos al este. Las dos tablillas están en las ruinas; {quest:4722} yace en la orilla al oeste de ellas.",
	-- ["{npc:3644}, on the pier"] = "{npc:3644}, en el muelle",
	-- ["{npc:3644}, where the pier meets the shore, on the way to the boat"] = "{npc:3644}, donde el muelle se une con la orilla, de camino al barco",
	-- ["{npc:3649}, north end of the village"] = "{npc:3649}, en el extremo norte del pueblo",
	-- ["{npc:3666}, upstairs in the inn"] = "{npc:3666}, arriba en la posada",
}
