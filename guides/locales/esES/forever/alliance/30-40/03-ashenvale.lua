-- Spanish (Spain) (esES): the guide forever/alliance/30-40/03-ashenvale (forever/alliance/30-40/03-ashenvale.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: Tram to Ironforge
	-- {zone:1455} Ironforge
	["Tram to {zone:1455}"] = "Tranvía a {zone:1455}",

	-- Step 2: Fly to Menethil Harbor
	-- {area:150} Menethil Harbor
	["Fly to {area:150}"] = "Vuela a {area:150}",
	-- {zone:1455} Ironforge
	["{zone:1455} flight master"] = "Maestro de vuelo de {zone:1455}",

	-- Step 3: Glorin Steelbrow
	-- {npc:1217} Glorin Steelbrow · {area:2104} Deepwater Tavern · {npc:4963} Mikhail · {npc:5082} Vincent Hyal
	["{npc:1217} stands in the {area:2104}, south of the keep, where {npc:4963} and {npc:5082} wait too."] = "{npc:1217} está en {area:2104}, al sur del torreón, donde también esperan {npc:4963} y {npc:5082}.",
	["Inside"] = "Adentro",

	-- Step 4: Deepwater Tavern
	-- {quest:1248} The Missing Diplomat · {npc:4963} Mikhail
	["Tapoke Jahn (34) slips out of the tavern once you take {quest:1248}: stay close behind him. He turns on you outside, a friend joins him, and he gives up once badly hurt. If you lose him the quest fails: abandon it and take it again from {npc:4963}."] = "Tapoke Jahn (34) sale de la taberna en cuanto tomas {quest:1248}: síguelo de cerca. Afuera se vuelve contra ti, se le suma un amigo, y se rinde cuando está muy herido. Si lo pierdes, la misión fracasa: abandónala y vuelve a tomarla de {npc:4963}.",

	-- Step 5: Waterlogged Chest
	["The wreck of the Flying Osprey lies in the shallows south of the keep."] = "El pecio del Flying Osprey está en las aguas poco profundas al sur del torreón.",

	-- Step 6: Lightforge Ingots
	["The Bluegill murlocs on the beach south-west of Menethil carry the ingots."] = "Los múrlocs Branquiazul de la playa al suroeste de Menethil llevan los lingotes.",
	-- {item:2702} Lightforge Ingot
	["{item:2702}; underwater"] = "{item:2702}; bajo el agua",

	-- Step 7: Glorin Steelbrow
	-- {npc:1416} Grimand Elmore · {zone:1453} Stormwind
	["For {npc:1416} in {zone:1453}, after Stranglethorn"] = "Para {npc:1416} en {zone:1453}, después de Tuercespina",

	-- Step 9: Theramore
	["Theramore"] = "Theramore",
	-- {area:514} Foothold Citadel · {npc:5083} Clerk Lendry · {npc:4964} Commander Samaul
	["The flight master stands by the gate of {area:514}; {npc:5083} and {npc:4964} are inside the citadel."] = "El maestro de vuelo está junto a la puerta de {area:514}; {npc:5083} y {npc:4964} están dentro de la ciudadela.",
	-- {npc:4964} Commander Samaul
	["{npc:4964}, on the top floor"] = "{npc:4964}, en el piso de arriba",
	-- {quest:1132} Fiora Longears
	["{quest:1132}, inside the inn in the north of town"] = "{quest:1132}, dentro de la posada, en el norte del pueblo",
	-- {npc:4456} Fiora Longears · {area:415} Astranaar
	["{npc:4456}'s next errand goes to {area:415}, off this route: leave it."] = "El siguiente encargo de {npc:4456} va a {area:415}, fuera de esta ruta: déjalo.",
	-- {quest:1132} Fiora Longears · {area:400} Thousand Needles
	["{quest:1132}: the wyverns are in {area:400}, later in this guide"] = "",

	-- Step 10: The Shady Rest Inn
	-- {zone:1413} Barrens
	["Follow the road west out of Theramore to the burned inn on the road toward the {zone:1413}: the black shield lies in the ashes and the hoofprints are in the mud beside the inn."] = "Sigue el camino al oeste saliendo de Theramore hasta la posada quemada del camino hacia {zone:1413}: el escudo negro está entre las cenizas y las huellas de cascos están en el barro junto a la posada.",

	-- Step 11: Into Barrens
	-- {zone:1413} Barrens
	["Into {zone:1413}"] = "Hacia {zone:1413}",

	-- Step 12: Takar the Seer
	-- {zone:1413} Barrens · {npc:6244} Takar the Seer · {area:378} Camp Taurajo
	["On the road south through the {zone:1413}, {npc:6244} camps east of the road, north-east of {area:378}; come in from the east and keep clear of the Horde guards."] = "En el camino al sur por {zone:1413}, {npc:6244} acampa al este del camino, al noreste de {area:378}; acércate desde el este y evita a los guardias de la Horda.",
	-- {quest:1738} Heartswood · {zone:1440} Ashenvale · {zone:1443} Desolace
	["{quest:1738}: in {zone:1440}, on the way to {zone:1443}"] = "{quest:1738}: en {zone:1440}, de camino a {zone:1443}",
	-- {quest:65602} What Is Love? · {item:190309} Wooden Figurine · {quest:1738} Heartswood
	["{quest:65602}: the incubus, beside the succubus; the {item:190309} is near the {quest:1738}"] = "{quest:65602}: el íncubo, junto a la súcubo; la {item:190309} está cerca de {quest:1738}",

	-- Step 13: To The Great Lift
	-- {area:485} The Great Lift
	["To {area:485}"] = "A {area:485}",

	-- Step 14: Back to The Great Lift
	-- {area:485} The Great Lift
	["Back to {area:485}"] = "",

	-- Step 15: To Highperch
	-- {area:482} Highperch
	["To {area:482}"] = "A {area:482}",

	-- Step 16: Highperch
	-- {area:485} The Great Lift · {area:400} Thousand Needles · {area:482} Highperch
	["Down the {area:485} into {area:400}, then west to the wyverns' cliffs at {area:482}. Every wyvern there can drop a venom sac. Careful: wait on the platform until the lift is level with it before you step on, and stay on it until it stops; the drop beside it kills."] = "",

	-- Step 17: Thousand Needles
	-- {area:482} Highperch
	["The canyons east of {area:482}"] = "Los cañones al este de {area:482}",

	-- Step 19: Mirage Raceway
	-- {area:2240} Mirage Raceway
	["Follow the canyons east to the salt flats. The goblins and gnomes of the {area:2240} are neutral and give quests to both factions."] = "Sigue los cañones al este hasta El Desierto de Sal. Los goblins y gnomos del {area:2240} son neutrales y dan misiones a ambas facciones.",
	-- {quest:5762} Hemet Nesingwary
	["For {quest:5762} in Stranglethorn, later"] = "Para {quest:5762}, en la Vega de Tuercespina, más tarde",

	-- Step 20: Mirage Raceway: kill these as you meet them
	-- {area:2240} Mirage Raceway
	["{area:2240}: kill these as you meet them"] = "{area:2240}: mata a estos según te los encuentres",
	-- {object:19868} Rocket Car Rubble
	-- plural, as words: Scorpid Reavers = {npc:4140} Scorpid Reaver · Salt Flats Scavengers = {npc:4154} Salt Flats Scavenger · Sparkleshell Tortoises = {npc:4142} Sparkleshell Tortoise · Sparkleshell Snappers = {npc:4143} Sparkleshell Snapper · Saltstone Gazers = {npc:4150} Saltstone Gazer · Scorpid Terrors = {npc:4139} Scorpid Terror
	["{object:19868} lies all over the flats. Scorpid Reavers and Salt Flats Scavengers roam the north half, Sparkleshell Tortoises (30-31) the middle of the flats: hunt them for the shells. Careful: Sparkleshell Snappers (34-35) wander the whole flats, and the Saltstone Gazers (34-35) and Scorpid Terrors (33-34) hold the far south: leave them and keep to the north half."] = "Hay {object:19868} por todo el llano. Los Atracadores escórpidos y los Carroñeros de los Llanos de Sal deambulan por la mitad norte, y las Tortugas brillavalva (30-31) por el centro: mátalas para conseguir los caparazones. Cuidado: los Sacudidores caparallantes (34-35) deambulan por todo el llano, y los Observadores Gapo Salino (34-35) y los Terrores escórpidos (33-34) ocupan el extremo sur: déjalos y quédate en la mitad norte.",
	-- {item:5795} Hardened Tortoise Shell
	-- plural, as words: Sparkleshell Tortoises = {npc:4142} Sparkleshell Tortoise
	["{item:5795}, from the Sparkleshell Tortoises"] = "{item:5795}, de las Tortugas brillavalva",

	-- Step 21: Fly to Stonetalon Peak
	-- {area:467} Stonetalon Peak
	["Fly to {area:467}"] = "Vuela a {area:467}",
	-- {area:442} Auberdine
	["{area:442} flight master"] = "Maestro de vuelo de {area:442}",

	-- Step 22: To The Charred Vale
	-- {area:465} The Charred Vale
	["To {area:465}"] = "",

	-- Step 24: Into Stonetalon Mountains
	-- {zone:1442} Stonetalon Mountains
	["Into {zone:1442}"] = "Entra a {zone:1442}",

	-- Step 50: The Charred Vale
	-- {npc:4078} Collin Mauren · {zone:1453} Stormwind
	-- plural, as words: Saltstone Basilisks = {npc:4147} Saltstone Basilisk
	["Crystalized Scale, from the Saltstone Basilisks: eight for {npc:4078} in {zone:1453}"] = "Escama cristalizada, de los basiliscos Piedra de sal: ocho para {npc:4078} en {zone:1453}",

	-- Step 52: Into Thousand Needles
	-- {area:400} Thousand Needles
	["Into {area:400}"] = "",

	-- Step 54: Mirage Raceway
	-- {npc:4454} Fizzle Brassbolts · {zone:1418} Badlands
	["{npc:4454}: for Martek in the {zone:1418}, at the end of 30-40"] = "{npc:4454}: para Martek en {zone:1418}, al final de 30-40",

	-- Step 55: To Freewind Post
	-- {area:484} Freewind Post
	["To {area:484}"] = "Hacia {area:484}",

	-- Step 57: Into Dustwallow Marsh
	-- {zone:1445} Dustwallow Marsh
	["Into {zone:1445}"] = "",

	-- Step 58: Fly to Theramore
	["Fly to Theramore"] = "Vuela a Theramore",
	-- {area:976} Gadgetzan
	["{area:976} flight master"] = "Maestro de vuelo de {area:976}",

	-- Step 61: To Theramore
	["To Theramore"] = "",

	-- Step 62: Theramore
	-- {npc:4456} Fiora Longears · {area:514} Foothold Citadel · {npc:4941} Caz Twosprocket
	["{npc:4456} is in the north of town, Captain Vimes in {area:514}; {npc:4941} stands in the town."] = "{npc:4456} está en el norte del pueblo, el capitán Vimes en {area:514}; {npc:4941} está en el pueblo.",
	-- {npc:4456} Fiora Longears
	["{npc:4456}, inside"] = "",
	-- {npc:4944} Captain Garran Vimes
	["{npc:4944}, on the top floor"] = "{npc:4944}, en el piso de arriba",
	-- {npc:4941} Caz Twosprocket
	["{npc:4941}, inside"] = "",

	-- Step 63: Class trainer
	["Class trainer"] = "Instructor de clase",

	-- Step 64: Warrior trainer
	["Warrior trainer"] = "Instructor de guerrero",
	-- {npc:252377} Seena Skybreaker · {zone:1426} Dun Morogh
	["{npc:252377} in Zephras Isle; {zone:1426} has no warrior trainer"] = "",

	-- Step 65: Hunter trainer
	["Hunter trainer"] = "Instructor de cazadores",
	-- {npc:248415} Tordrin Sternblade · {zone:1429} Elwynn Forest · {zone:1426} Dun Morogh
	["{npc:248415} in {zone:1429}; {zone:1426} has no hunter trainer"] = "",

	-- Step 66: Rogue trainer
	["Rogue trainer"] = "Instructor de pícaro",
	-- {npc:252379} Eltheen Nightbreeze · {zone:1426} Dun Morogh
	["{npc:252379} in Zephras Isle; {zone:1426} has no rogue trainer"] = "",

	-- Step 67: Mage trainer
	["Mage trainer"] = "Instructor de mago",
	-- {npc:252373} Anathamaas Aetherwind · {zone:1426} Dun Morogh
	["{npc:252373} in Zephras Isle; {zone:1426} has no mage trainer"] = "",

	-- Step 68: Druid trainer
	["Druid trainer"] = "Instructor de druidas",
	-- {npc:270459} Alfina Nightgaze · {zone:1416} Alterac Mountains · {zone:1426} Dun Morogh
	["{npc:270459} in {zone:1416}; {zone:1426} has no druid trainer"] = "",

	-- Step 69: Boat to Menethil Harbor
	-- {area:150} Menethil Harbor
	-- was: ["Boat to {area:150}"] = "Barco a {area:150}"
	["Boat to {area:150}"] = "Barco a {area:150}",

	-- Step 70: Fly to Ironforge
	-- {area:1537} Ironforge
	["Fly to {area:1537}"] = "Vuela a {area:1537}",
	-- {area:150} Menethil Harbor
	["{area:150} flight master"] = "Maestro de vuelo de {area:150}",

	-- Step 71: To Bronk Guzzlegear
	-- {npc:1702} Bronk Guzzlegear
	["To {npc:1702}"] = "",

	-- Step 72: Bronk Guzzlegear
	["Below ground"] = "Bajo tierra",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["Back west along the road to the satyr camps of {area:429}."] = "Vuelve al oeste por el camino hasta los campamentos sátiros de {area:429}.",
	-- ["Boat to {area:150}"] = "Barco a {area:150}",
	-- ["Boat to {area:35}"] = "Barco a {area:35}",
	-- ["Dartol's Rod"] = "Vara de transformación de Dartol",
	-- ["East through the canyons. {area:484}, a Horde camp with guards, sits on the mesa here: keep to the canyon floor and give the foot of its lifts a wide berth."] = "Al este por los cañones. {area:484}, un campamento de la Horda con guardias, está sobre la meseta: quédate en el fondo del cañón y mantente bien lejos del pie de sus elevadores.",
	-- ["Follow the road east to the satyr camps of {area:429}; {npc:3920} hides at their edge."] = "Sigue el camino hacia el este hasta los campamentos sátiros de {area:429}; {npc:3920} se esconde en su borde.",
	-- ["Follow the road west out of {area:415}; {area:413} lies north of it."] = "Sigue el camino hacia el oeste desde {area:415}; {area:413} queda al norte.",
	-- ["For {quest:1132} in Theramore's inn, where this guide's boat goes"] = "Para {quest:1132} en la posada de Theramore, adonde va el barco de esta guía",
	-- ["From {area:608}"] = "Desde {area:608}",
	-- ["Geltharis"] = "Geltharis",
	-- ["Insane druids"] = "Druidas dementes",
	-- ["Lightforge Ingots"] = "Lingotes Forjaluz",
	-- ["Melyria and {npc:3901}"] = "Melyria e {npc:3901}",
	-- ["Rusty chests lie around the Shadethicket furbolg camps west of the Forsaken; open them until one holds the pommel."] = "Hay cofres oxidados alrededor de los campamentos furbolg Sombramatorral al oeste de los Renegados; ábrelos hasta que uno tenga el pomo.",
	-- ["Take the boat to {area:150} from {area:442}'s docks."] = "Toma el barco a {area:150} en los muelles de {area:442}.",
	-- ["Take the tunnel into the {area:419}; the tome lies in the ruins at its west end."] = "Entra por el túnel en {area:419}; el tomo está en las ruinas de su extremo oeste.",
	-- ["The Crazed and Withered Ancients north of the moonwell carry the {item:5475}; the worn chest it opens stands among them."] = "Los Ancianos enloquecidos y los Ancianos marchitos al norte del pozo de la luna llevan la {item:5475}; el cofre gastado que abre está entre ellos.",
	-- ["The Forsaken's camp lies in the woods south of {area:2358}."] = "El campamento de los Renegados está en el bosque al sur de {area:2358}.",
	-- ["The moonwell lies in the hills north-east of {area:415}."] = "El pozo de la luna está en las colinas al noreste de {area:415}.",
	-- ["The second {object:19901} lies in the valley of {area:428}, on the way west."] = "El segundo {object:19901} está en el valle de {area:428}, de camino al oeste.",
	-- ["The shrine sits on the hill just south-east of the moonwell; follow the winding path up."] = "El santuario está en la colina justo al sureste del pozo de la luna; sube por el sendero sinuoso.",
	-- ["The three druids stand together at the Forsaken camp south of {area:2358}."] = "Los tres druidas están juntos en el campamento de los Renegados al sur de {area:2358}.",
	-- ["The two stand together at the western end of the road."] = "Las dos están juntas en el extremo oeste del camino.",
	-- ["The wreck of the Flying Osprey lies in the shallows south of the keep."] = "El pecio del Flying Osprey está en las aguas poco profundas al sur del torreón.",
	-- ["The {npc:3931} walks the shore of {quest:1035}, south-west of the chests; the {object:669176} lies north of the lake, on the way."] = "El {npc:3931} recorre la orilla del {quest:1035}, al suroeste de los cofres; el {object:669176} está al norte del lago, de camino.",
	-- ["The {object:19901} stands in the satyr camp of {area:430}, further east along the road."] = "El {object:19901} está en el campamento sátiro de {area:430}, más al este por el camino.",
	-- ["{area:2358}, the Night Elf outpost at the eastern end of the road: {npc:3848} and {npc:221269} stand there."] = "{area:2358}, el puesto de los elfos de la noche en el extremo este del camino: allí están {npc:3848} y {npc:221269}.",
	-- ["{area:2358}, the Night Elf outpost at the eastern end of the road: {npc:3848} stands there."] = "{area:2358}, el puesto de los elfos de la noche en el extremo este del camino: allí está {npc:3848}.",
	-- ["{area:429} satyrs"] = "Sátiros de {area:429}",
	-- ["{npc:1217} stands on the upper floor of Menethil's keep."] = "{npc:1217} está en la planta superior del torreón de Menethil.",
	-- ["{npc:3696} and his guards camp just east of {npc:3897}."] = "{npc:3696} y sus guardias acampan justo al este de {npc:3897}.",
	-- ["{npc:3897}, a furbolg untouched by the corruption, sits south of the road below {area:421}."] = "{npc:3897}, un furbolg al que no ha tocado la corrupción, está sentado al sur del camino, bajo {area:421}.",
	-- ["{npc:3970}: for {npc:1480} in Menethil, at the end of this guide"] = "{npc:3970}: para {npc:1480} en Menethil, al final de esta guía",
	-- ["{npc:4455} stands by {area:2103}'s door, just north of the flight master."] = "{npc:4455} está junto a la puerta de {area:2103}, justo al norte del maestro de vuelo.",
	-- ["{npc:4619} leads the {area:429} satyrs; he carries the branch."] = "{npc:4619} lidera a los sátiros de {area:429}; él lleva la rama.",
	-- ["{npc:5082}, {npc:4963} and Tapoke Jahn are all at Menethil's inn; {npc:4962} fights you when you talk to {npc:4963}, but gives up once beaten. {npc:1480} stands a short walk north-east of the inn."] = "{npc:5082}, {npc:4963} y {npc:4962} están en la posada de Menethil; Tapoke te ataca cuando hablas con {npc:4963}, pero se rinde al ser derrotado. {npc:1480} está a poca distancia al noreste de la posada.",
	-- ["{object:669176}: for {npc:3961} in {area:415}"] = "{object:669176}: para {npc:3961} en {area:415}",
}
