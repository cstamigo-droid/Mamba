-- Spanish (Spain) (esES): the guide forever/horde/40-50/05-the-hinterlands (forever/horde/40-50/05-the-hinterlands.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: Fly to Stonard
	-- {area:75} Stonard
	["Fly to {area:75}"] = "Vuela a {area:75}",
	-- {area:1446} Thorium Point
	["{area:1446} flight master"] = "Maestro de vuelo de {area:1446}",

	-- Step 2: Fly to Undercity
	-- {area:1497} Undercity
	["Fly to {area:1497}"] = "Vuela a {area:1497}",

	-- Step 3: To Dreadmaul Hold
	-- {area:1437} Dreadmaul Hold
	["To {area:1437}"] = "A {area:1437}",

	-- Step 4: The bloodmages
	["The bloodmages"] = "Los magos sangrientos",
	-- {area:75} Stonard · {zone:1419} Blasted Lands
	["Ride west out of {area:75} and south through the canyon into the {zone:1419}; the two bloodmages stand by the road just inside."] = "Sal de {area:75} hacia el oeste y ve al sur por el cañón hasta {zone:1419}; los dos magos sangrientos están junto al camino, nada más entrar.",

	-- Step 6: Dreadmaul Hold: kill these as you meet them
	-- {area:1437} Dreadmaul Hold
	["{area:1437}: kill these as you meet them"] = "{area:1437}: mata a estos cuando te los encuentres",
	-- {npc:5982} Black Slayer
	-- plural, as words: Starving Snickerfangs = {npc:5984} Starving Snickerfang · Scorpok Stingers = {npc:5988} Scorpok Stinger
	-- was: ["The five quests share the same parts: gather them all in one sweep. West of the road the {npc:5982} vultures, Starving Snickerfangs, Scorpok Stingers and Deatheye basilisks share the hills.\nEast of the road the Ashmane boars and Grunters root on the slopes beside the Redstone basilisks. Stay away from the level 52 Helboars further south.\nCareful: Scorpok Stingers use {spell:5416}; {npc:8301} adds Knockdown."] = "Las cinco misiones piden las mismas partes: reúnelas todas de una pasada. Al oeste del camino, los buitres {npc:5982}, las hienas risitas hambrientas, los aguijoneros Scorpok y los basiliscos Ojo de la Muerte comparten las colinas.\nAl este del camino, los jabalíes Crin de Ceniza y los Gruñidores hozan en las laderas junto a los basiliscos Piedrarroja. Aléjate de los Jabalíes infernales de nivel 52, más al sur.\nCuidado: los aguijoneros Scorpok usan {spell:5416}; {npc:8301} añade Derribo."
	["The five quests share the same parts: gather them all in one sweep. West of the road the {npc:5982} vultures, Starving Snickerfangs, Scorpok Stingers and Deatheye basilisks share the hills.\nEast of the road the Ashmane boars and Grunters root on the slopes beside the Redstone basilisks. Stay away from the level 52 Helboars further south."] = "Las cinco misiones comparten las mismas partes: reúnelas todas en una sola pasada. Al oeste del camino, los buitres {npc:5982}, los Starving Snickerfangs, los Scorpok Stingers y los basiliscos Deatheye comparten las colinas.\nAl este del camino, los jabalíes Ashmane y los Grunters hozan en las laderas junto a los basiliscos Redstone. Mantente lejos de los Helboars de nivel 52 más al sur.",

	-- Step 7: The bloodmages
	["Ride back north to the bloodmages."] = "Vuelve al norte con los magos sangrientos.",
	["Their follow-ups ask for the same parts again for a buff item and pay no experience: leave them."] = "Sus misiones siguientes piden otra vez las mismas partes a cambio de un objeto de mejora y no dan experiencia: déjalas.",

	-- Step 8: Dispatch Commander Ruag
	["Upstairs"] = "Arriba",
	["Inside"] = "Adentro",

	-- Step 9: Fly to Flame Crest
	-- {area:251} Flame Crest
	["Fly to {area:251}"] = "Vuela a {area:251}",
	-- {area:75} Stonard
	["{area:75} flight master"] = "Maestro de vuelo de {area:75}",

	-- Step 10: To Lake Everstill
	-- {area:68} Lake Everstill
	["To {area:68}"] = "A {area:68}",

	-- Step 11: Hilary's Necklace
	["Underwater"] = "Bajo el agua",

	-- Step 13: To Flame Crest
	-- {area:251} Flame Crest
	["To {area:251}"] = "A {area:251}",

	-- Step 14: Fly to The Sepulcher
	-- {area:228} The Sepulcher
	["Fly to {area:228}"] = "Vuela a {area:228}",
	-- {area:251} Flame Crest
	["{area:251} flight master"] = "Maestro de vuelo de {area:251}",

	-- Step 16: Fly to Undercity
	-- {area:228} The Sepulcher
	["{area:228} flight master"] = "Maestro de vuelo de {area:228}",

	-- Step 18: Undercity
	-- {npc:6741} Innkeeper Norman · {zone:1456} Thunder Bluff
	-- was: ["{npc:6741}: for {zone:1456}, around level 50"] = "{npc:6741}: para {zone:1456}, hacia el nivel 50"
	["{npc:6741}: for {zone:1456}, around level 50"] = "{npc:6741}: para {zone:1456}, alrededor del nivel 50",

	-- Step 19: Hunter trainer
	["Hunter trainer"] = "Instructor de cazadores",
	-- {npc:252389} Quel'ana Quickgale · {area:153} Ruins of Lordaeron
	["{npc:252389} in Zephras Isle; {area:153} has no hunter trainer"] = "{npc:252389} en Zephras Isle; {area:153} no tiene instructor de cazador",

	-- Step 20: Rogue trainer
	["Rogue trainer"] = "Instructor de pícaro",
	-- {npc:252379} Eltheen Nightbreeze · {area:153} Ruins of Lordaeron
	["{npc:252379} in Zephras Isle; {area:153} has no rogue trainer"] = "{npc:252379} en Zephras Isle; {area:153} no tiene instructor de pícaros",

	-- Step 21: Shaman trainer
	["Shaman trainer"] = "Instructor de chamanes",
	-- {npc:258113} Ingrid Dunwald · {zone:1426} Dun Morogh · {area:153} Ruins of Lordaeron
	["{npc:258113} in {zone:1426}; {area:153} has no shaman trainer"] = "{npc:258113} en {zone:1426}; {area:153} no tiene instructor de chamán",

	-- Step 22: Mage trainer
	["Mage trainer"] = "Instructor de mago",
	-- {npc:252373} Anathamaas Aetherwind · {area:153} Ruins of Lordaeron
	["{npc:252373} in Zephras Isle; {area:153} has no mage trainer"] = "{npc:252373} en Zephras Isle; {area:153} no tiene instructor de mago",

	-- Step 23: Druid trainer
	["Druid trainer"] = "Instructor de druidas",
	-- {npc:252359} Lotheluum Starbreeze · {area:153} Ruins of Lordaeron
	["{npc:252359} in Zephras Isle; {area:153} has no druid trainer"] = "{npc:252359} en Zephras Isle; {area:153} no tiene instructor de druida",

	-- Step 24: Fly to Tarren Mill
	-- {area:272} Tarren Mill
	["Fly to {area:272}"] = "Vuela a {area:272}",
	-- {zone:1458} Undercity
	["{zone:1458} flight master"] = "Maestro de vuelo de {zone:1458}",

	-- Step 25: To Shindigger's Camp
	-- {area:1881} Shindigger's Camp
	["To {area:1881}"] = "A {area:1881}",

	-- Step 26: Gilveradin Sunchaser's camp
	-- {npc:7801} Gilveradin Sunchaser
	["{npc:7801}'s camp"] = "Campamento de {npc:7801}",
	-- {area:272} Tarren Mill · {zone:1425} The Hinterlands · {npc:7801} Gilveradin Sunchaser · {area:350} Quel'Danil Lodge
	["Ride north-east from {area:272} into the {zone:1425} and east along the road; {npc:7801} camps on the hill south of the elves' {area:350}."] = "Ve al noreste desde {area:272} hasta {zone:1425} y sigue el camino hacia el este; {npc:7801} acampa en la colina al sur de {area:350} de los elfos.",

	-- Step 27: Highvale
	["Highvale"] = "Vallealto",
	-- {area:350} Quel'Danil Lodge · {npc:7780} Rin'ji
	-- was: ["The Highvale elves camp around {area:350}. Burn the report, the notes and the records in their camps. {npc:7780} is held inside the lodge: lead him out and fight off the ambush on the way.\nCareful: Groups of about three elves ambush the escort, usually twice."] = "Los elfos de Vallealto acampan alrededor de {area:350}. Quema el informe, las notas y los archivos de sus campamentos. {npc:7780} está preso dentro del refugio: sácalo de allí y rechaza la emboscada por el camino.\nCuidado: grupos de unos tres elfos emboscan la escolta, normalmente dos veces."
	["The Highvale elves camp around {area:350}. Burn the report, the notes and the records in their camps. {npc:7780} is held inside the lodge: lead him out and fight off the ambush on the way."] = "Los elfos Highvale acampan alrededor de {area:350}. Quema el informe, las notas y los registros en sus campamentos. {npc:7780} está retenido dentro del refugio: sácalo y repele la emboscada en el camino.",

	-- Step 28: Grim Message
	-- {item:15002} Nimboya's Pike
	["South of the lodge the Witherbark trolls hold their villages. Every one of them carries a skull: with twenty, use {item:15002} to make the Laden Pike, then plant it inside the village."] = "Al sur del refugio, los trols Secacorteza ocupan sus poblados. Todos llevan un cráneo: con veinte, usa {item:15002} para hacer el Pico cargado de Nimboya y clávalo dentro del poblado.",

	-- Step 29: Violet Tragan
	["East of the village, the violet flower grows in the hills."] = "Al este del poblado, la flor violeta crece en las colinas.",

	-- Step 30: The Atal'ai Exile
	-- {area:353} Shadra'Alor
	["South-west again, the exile hides by the ruins of {area:353}."] = "De nuevo al suroeste, el exiliado se esconde junto a las ruinas de {area:353}.",

	-- Step 31: Revantusk Village
	-- {npc:14736} Primal Torntusk · {npc:14731} Lard
	["{npc:14736} stands up on top of the inn, above {npc:14731}: go up, the arrow cannot tell the levels apart."] = "{npc:14736} está en lo alto de la posada, encima de {npc:14731}: sube, la flecha no distingue los niveles.",

	-- Step 33: Revantusk Village
	-- {quest:7845} Kidnapped Elder Torntusk!
	["These are elite mobs: grouping up is encouraged, look for people to do it with. {quest:7845} needs a group of 3. Skip it if you are alone: the route has you grind the XP back."] = "Estos son enemigos élite: se recomienda ir en grupo, busca gente con quien hacerlo. {quest:7845} requiere un grupo de 3. Omítela si estás solo: la ruta te hace farmear la experiencia.",

	-- Step 35: On the way
	["On the way"] = "Por el camino",

	-- Step 36: The Overlook Cliffs: kill these as you meet them
	-- {area:307} The Overlook Cliffs
	["{area:307}: kill these as you meet them"] = "{area:307}: mata a estos según te los encuentres",
	-- {npc:2491} Whiskey Slim · {area:307} The Overlook Cliffs
	-- was: ["The big turtles crawl along the beaches north of the village, and {npc:2491}'s bottles of port lie on the same beaches, from the village up to the {area:307}: pick them up as you go. A snapjaw can drop OOX-09/HL's distress beacon, rarely: keep it."] = "Las tortugas grandes se arrastran por las playas al norte del poblado, y las botellas de oporto de {npc:2491} están en las mismas playas, desde el poblado hasta {area:307}: recógelas sobre la marcha. Un quijaforte puede soltar, rara vez, la baliza de socorro de OOX-09/HL: guárdala."
	["The big turtles crawl along the beaches north of the village, and {npc:2491}'s bottles of port lie on the same beaches, from the village up to the {area:307}: pick them up as you go. A snapjaw can drop OOX-09/HL's distress beacon, rarely: keep it."] = "Las tortugas grandes se arrastran por las playas al norte de la aldea, y las botellas de oporto de {npc:2491} están en las mismas playas, desde la aldea hasta {area:307}: recógelas en el camino. Una tortuga mordedora puede soltar la baliza de socorro de OOX-09/HL, rara vez: guárdala.",
	-- {item:8704} OOX-09/HL Distress Beacon
	["{item:8704}, a rare drop"] = "{item:8704}, botín poco común",
	-- {object:2068} Pupellyverbos Port
	["{object:2068}, on the beaches"] = "{object:2068}, en las playas",

	-- Step 37: Rin'ji's Secret
	-- {area:307} The Overlook Cliffs
	["The secret lies on the {area:307}, above the beach."] = "El secreto está en {area:307}, sobre la playa.",
	-- {npc:7825} Oran Snakewrithe · {zone:1458} Undercity
	["for {npc:7825} in the {zone:1458}, around level 50"] = "para {npc:7825} en {zone:1458}, hacia el nivel 50",

	-- Step 38: Lard's lunch
	-- {npc:14731} Lard
	["{npc:14731}'s lunch"] = "El almuerzo de {npc:14731}",
	-- {npc:14731} Lard · {npc:14748} Vilebranch Kidnapper
	["North along the coast, {npc:14731}'s picnic basket is on the small island; a {npc:14748} guards it."] = "Al norte por la costa, la cesta de merienda de {npc:14731} está en el islote; la vigila un {npc:14748}.",

	-- Step 39: The Altar of Zul: kill these as you meet them
	-- {area:355} The Altar of Zul
	["{area:355}: kill these as you meet them"] = "{area:355}: mata a estos según te los encuentres",
	-- {area:1884} Agol'watha · {area:1917} Shaol'watha · {area:355} The Altar of Zul · {npc:8636} Morta'gya the Keeper
	["West of the island, the Vilebranch scalpers hold the temples of {area:1884} and {area:1917}. Slagtree's tools lie at one of the temples.\nOn the way back east, the Vilebranch soothsayers hold the {area:355}, the troll temple south of the central hills. Qiaga and {npc:8636} (elite, 50) stand at its top: take the soothsayers on the lower steps."] = "Al oeste de la isla, los desolladores Vilebranch ocupan los templos de {area:1884} y {area:1917}. Las herramientas de Slagtree están en uno de los templos.\nDe regreso al este, los adivinos Vilebranch ocupan {area:355}, el templo de trols al sur de las colinas centrales. Qiaga y {npc:8636} (élite, 50) están en la cima: enfréntate a los adivinos en los escalones inferiores.",

	-- Step 41: The central hills
	-- was: ["The central hills"] = "Las colinas centrales"
	["The central hills"] = "Las colinas centrales",
	-- {area:351} Skulk Rock · {item:9618} Wildkin Muisek Vessel · {npc:14738} Otho Moji'ko
	-- plural, as words: Silvermane Stalkers = {npc:2926} Silvermane Stalker · Savage Owlbeasts = {npc:2929} Savage Owlbeast · Razorbeak Skylords = {npc:2659} Razorbeak Skylord · Long Elegant Feathers = {item:4589} Long Elegant Feather
	-- was: ["The Silvermane Stalkers, Savage Owlbeasts and Razorbeak Skylords share the hills between the temples and {area:351}. Use the {item:9618} on the owlbeasts you kill. The Skylords also drop Long Elegant Feathers: keep ten for {npc:14738}'s second message."] = "Los acechadores melenargenta, las lechubestias salvajes y los Señores del Cielo Picovaja comparten las colinas entre los templos y {area:351}. Usa {item:9618} en las lechubestias que mates. Los Señores del Cielo también sueltan plumas elegantes largas: guarda diez para el segundo mensaje de {npc:14738}."
	["The Silvermane Stalkers, Savage Owlbeasts and Razorbeak Skylords share the hills between the temples and {area:351}. Use the {item:9618} on the owlbeasts you kill. The Skylords also drop Long Elegant Feathers: keep ten for {npc:14738}'s second message."] = "Los acechadores melenargenta, las lechubestias salvajes y los señores del cielo Picovaja comparten las colinas entre los templos y {area:351}. Usa el {item:9618} en las lechubestias que mates. Los señores del cielo también sueltan Plumas largas y elegantes: guarda diez para el segundo mensaje de {npc:14738}.",

	-- Step 42: Skulk Rock
	-- {item:8684} Hinterlands Honey Ripple · {area:351} Skulk Rock
	["The crates of {item:8684} lie around the abandoned Horde camp at {area:351}, among the oozes."] = "Las cajas de {item:8684} están alrededor del campamento abandonado de la Horda en {area:351}, entre los mocos.",

	-- Step 43: OOX-09/HL
	["OOX-09/HL"] = "OOX-09/HL",
	-- {area:351} Skulk Rock · {area:307} The Overlook Cliffs · {area:35} Booty Bay
	-- was: ["Only with the distress beacon: the robot sits at the head of the river west of {area:351}. Escort it east to the shore beyond the {area:307}; its reward waits with Oglethorpe in {area:35}."] = "Solo con la baliza de socorro: el robot está en el nacimiento del río, al oeste de {area:351}. Escóltalo hacia el este hasta la orilla, más allá de {area:307}; su recompensa te espera con Oglethorpe en {area:35}."
	["Only with the distress beacon: the robot sits at the head of the river west of {area:351}. Escort it east to the shore beyond the {area:307}; its reward waits with Oglethorpe in {area:35}."] = "Solo con el faro de socorro: el robot está en el nacimiento del río al oeste de {area:351}. Escóltalo al este hasta la orilla más allá de {area:307}; su recompensa te espera con Oglethorpe en {area:35}.",

	-- Step 44: Silvermane Howlers
	-- plural, as words: Silvermane Howlers = {npc:2925} Silvermane Howler
	-- was: ["Silvermane Howlers"] = "Aulladores Melenargenta"
	["Silvermane Howlers"] = "Silvermane Howlers",
	-- plural, as words: Silvermane Howlers = {npc:2925} Silvermane Howler
	-- was: ["South-west, the Silvermane Howlers roam the hills east of the Witherbark villages."] = "Al suroeste, los aulladores Melenargenta recorren las colinas al este de los poblados Secacorteza."
	["South-west, the Silvermane Howlers roam the hills east of the Witherbark villages."] = "Al suroeste, los aulladores melenargenta recorren las colinas al este de los poblados Secacorteza.",

	-- Step 45: Highvale
	-- {area:350} Quel'Danil Lodge
	["Back west to {area:350}; rangers and marksmen stay near the lodge, scouts and outrunners on the slopes south of it."] = "Vuelve al oeste a {area:350}; los forestales y tiradores están cerca del refugio, y los exploradores y avanzadas, en las laderas al sur.",

	-- Step 46: Gilveradin Sunchaser's camp
	-- {npc:6986} Dran Droffers · {zone:1454} Orgrimmar
	["for {npc:6986} in {zone:1454}, around level 50"] = "para {npc:6986} en {zone:1454}, hacia el nivel 50",

	-- Step 47: Jintha'Alor
	-- {area:354} Jintha'Alor · {npc:14757} Elder Torntusk
	-- was: ["Huntsman Malkhor's skull lies on a pile below the Vilebranch ruins, his bones on a pile at the foot of {area:354}. The Vessels of {spell:19478} sit on the lower terraces, and {npc:14757} is held at the top. Keep to the paths: the trolls inside are elite."] = "La calavera del cazador Malkhor está en un montón bajo las ruinas Vilrama, y sus huesos, en otro montón al pie de {area:354}. Las vasijas de {spell:19478} están en las terrazas inferiores, y {npc:14757} está preso en la cima. No te salgas de los senderos: los trols de dentro son élite."
	["Huntsman Malkhor's skull lies on a pile below the Vilebranch ruins, his bones on a pile at the foot of {area:354}. The Vessels of Tainted Blood sit on the lower terraces, and {npc:14757} is held at the top. Keep to the paths: the trolls inside are elite."] = "El cráneo del cazador Malkhor está en un montón bajo las ruinas Vilebranch, y sus huesos en otro montón al pie de {area:354}. Las vasijas de sangre corrupta están en las terrazas inferiores y {npc:14757} está retenido en la cima. No te salgas de los senderos: los trols de adentro son élite.",
	-- {area:355} The Altar of Zul
	["His next request, going on to the {area:355}, is for a group."] = "Su siguiente encargo, que continúa en {area:355}, es para grupo.",

	-- Step 48: Jintha'Alor
	-- {quest:7849} Separation Anxiety
	["These are elite mobs: grouping up is encouraged, look for people to do it with. {quest:7849} needs a group of 3. Skip it if you are alone: the route has you grind the XP back."] = "Estos son enemigos élite: se recomienda ir en grupo, busca gente con quien hacerlo. {quest:7849} requiere un grupo de 3. Omítela si estás solo: la ruta te hace farmear la experiencia.",

	-- Step 49: Jintha'Alor
	-- {quest:7850} Dark Vessels
	["These are elite mobs: grouping up is encouraged, look for people to do it with. {quest:7850} needs a group of 3. Skip it if you are alone: the route has you grind the XP back."] = "Estos son enemigos élite: se recomienda agruparse, busca gente para hacerlos juntos. {quest:7850} necesita un grupo de 3. Omítela si no tienes grupo: la ruta te hace recuperar la experiencia después.",

	-- Step 50: Jintha'Alor
	-- {npc:14757} Elder Torntusk · {area:354} Jintha'Alor
	["{npc:14757}, at the top of {area:354}"] = "{npc:14757}, en la cima de {area:354}",

	-- Step 51: Level 49.03
	["Level 49.03"] = "Nivel 49.03",
	-- {quest:7845} Kidnapped Elder Torntusk!
	["If you skipped {quest:7845}, grind here to level 49.03 to stay on the route's plan."] = "Si omitiste {quest:7845}, farmea aquí hasta el nivel 49.03 para mantenerte en el plan de la ruta.",
	-- {npc:2925} Silvermane Howler
	["grind on {npc:2925}"] = "sube de nivel con {npc:2925}",

	-- Step 52: Revantusk Village
	-- {npc:14731} Lard
	["{npc:14731}, inside"] = "{npc:14731}, adentro",

	-- Step 55: Aerie Peak
	-- {area:348} Aerie Peak
	["Ride all the way west to the Wildhammer town of {area:348} and place the message by the well in its centre. The town is full of Alliance guards: get in, place it and get out."] = "Ve hasta el extremo oeste, a {area:348}, la ciudad de los Martillo Salvaje, y deja el mensaje junto al pozo del centro. La ciudad está llena de guardias de la Alianza: entra, déjalo y sal.",
	-- {area:348} Aerie Peak
	["{area:348} well"] = "Pozo de {area:348}",

	-- Step 56: Level 49.42
	["Level 49.42"] = "Nivel 49.42",
	-- {quest:7849} Separation Anxiety · {quest:7850} Dark Vessels
	["If you skipped {quest:7849} or {quest:7850}, grind here to level 49.42 to stay on the route's plan."] = "Si omitiste {quest:7849} o {quest:7850}, farmea aquí hasta el nivel 49.42 para mantenerte en el plan de la ruta.",
	-- {npc:2505} Saltwater Snapjaw
	["grind on {npc:2505}"] = "sube de nivel con {npc:2505}",

	-- Step 58: Fly to Rog'mar
	-- {area:16743} Rog'mar
	["Fly to {area:16743}"] = "Vuela a {area:16743}",
	-- {area:3317} Revantusk Village
	["{area:3317} flight master"] = "Maestro de vuelo de {area:3317}",

	-- Step 59: Boat to Steamwheedle Port
	-- {area:977} Steamwheedle Port
	["Boat to {area:977}"] = "Barco a {area:977}",

	-- Step 60: Fly to Ratchet
	-- {area:392} Ratchet
	["Fly to {area:392}"] = "Vuela a {area:392}",
	-- {area:976} Gadgetzan
	["{area:976} flight master"] = "Maestro de vuelo de {area:976}",

	-- Step 61: Into Tirisfal Glades
	-- {zone:1420} Tirisfal Glades
	["Into {zone:1420}"] = "Entra a {zone:1420}",

	-- Step 62: Zeppelin to Orgrimmar
	-- {zone:1454} Orgrimmar
	["Zeppelin to {zone:1454}"] = "Zepelín a {zone:1454}",

	-- Step 63: Fly to Ratchet
	-- {zone:1454} Orgrimmar
	["{zone:1454} flight master"] = "Maestro de vuelo de {zone:1454}",

	-- Step 64: Boat to Booty Bay
	-- {area:35} Booty Bay
	["Boat to {area:35}"] = "Barco a {area:35}",

	-- Step 65: Into Westfall
	-- {zone:1436} Westfall
	["Into {zone:1436}"] = "Entra a {zone:1436}",

	-- Step 66: To Westfall Lighthouse
	-- {area:115} Westfall Lighthouse
	["To {area:115}"] = "A {area:115}",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["East of the road the Ashmane boars and Grunters root on the slopes beside the Redstone basilisks. Stay away from the level 52 Helboars further south."] = "Al este del camino, los jabalíes Cenicrín y los gruñones hozan en las laderas junto a los basiliscos Rocarroja. Evita a los jabinfernos de nivel 52, más al sur.",
	-- ["Fly to the {area:1497}"] = "Vuela a {area:1497}",
	-- ["Follow the roads east across the {area:47} to the troll village on the eastern coast."] = "Sigue los caminos hacia el este a través de {area:47} hasta el poblado trol de la costa este.",
	-- ["Follow the roads east across the {zone:1425} to the troll village on the eastern coast."] = "Sigue los caminos hacia el este a través de {zone:1425} hasta el poblado trol de la costa este.",
	-- ["Grind to 48"] = "Sube al nivel 48",
	-- ["Huntsman Malkhor's skull lies on a pile below the Vilebranch ruins, his bones on a pile at the foot of {area:354}. The Vessels of Tainted Blood sit on the lower terraces, and {npc:14757} is held at the top. The trolls inside are elite: stay with your group and keep to the paths."] = "La calavera del cazador Malkhor está en un montón bajo las ruinas Vilrama, y sus huesos, en otro montón al pie de {area:354}. Las vasijas de sangre contaminada están en las terrazas inferiores, y {npc:14757} está preso en la cima. Los trols de dentro son élite: no te separes de tu grupo y no te salgas de los senderos.",
	-- ["Huntsman Malkhor's skull lies on a pile below the Vilebranch ruins, his bones on a pile at the foot of {area:354}. The Vessels of {spell:19478} sit on the lower terraces, and {npc:14757} is held at the top. Keep to the paths: the trolls inside are elite."] = "La calavera del cazador Malkhor está en un montón bajo las ruinas Vilrama, y sus huesos, en otro montón al pie de {area:354}. Las vasijas de {spell:19478} están en las terrazas inferiores, y {npc:14757} está preso en la cima. No te salgas de los senderos: los trols de dentro son élite.",
	-- ["No flight path to {area:75} yet: the arrow takes the quickest way there (by the {object:3202} flight and the road through {zone:1431} and {zone:1430}). Learn {area:75}'s flight path when you arrive."] = "Aún no tienes la ruta de vuelo a {area:75}: la flecha toma el camino más rápido (con el vuelo a {object:3202} y el camino por {zone:1431} y {zone:1430}). Aprende la ruta de vuelo de {area:75} al llegar.",
	-- ["Only if you are not level 48 yet."] = "Solo si aún no eres de nivel 48.",
	-- ["Only with the distress beacon: the robot sits at the head of the river west of {area:351}. Escort it east to the shore beyond the {area:307}; its reward waits with Oglethorpe in {area:35}."] = "Solo con la baliza de socorro: el robot está en el nacimiento del río, al oeste de {area:351}. Escóltalo hacia el este hasta la orilla, más allá de {area:307}; su recompensa te espera con Oglethorpe en {area:35}.",
	-- ["Ride north back to {area:75} and fly to the {area:1497}."] = "Vuelve al norte a {area:75} y vuela a {area:1497}.",
	-- ["Ride north-east from {area:272} into the {area:47} and east along the road; {npc:7801} camps on the hill south of the elves' {area:350}."] = "Ve al noreste desde {area:272} hasta {area:47} y sigue el camino hacia el este; {npc:7801} acampa en la colina al sur de {area:350} de los elfos.",
	-- ["Saltwater Snapjaws"] = "Quijafortes Aguasalada",
	-- ["Silvermane Howlers"] = "Aulladores Melenargenta",
	-- ["South-west of the lake, the Vilebranch soothsayers hold the {area:355}, the troll temple south of the central hills. Qiaga and {npc:8636} (elite, 50) stand at its top: take the soothsayers on the lower steps.\nSouth-west, the Silvermane Howlers roam the hills east of the Witherbark villages."] = "Al suroeste del lago, los adivinos Vilrama ocupan {area:355}, el templo trol al sur de las colinas centrales. Qiaga y {npc:8636} (élite, 50) están en la cima: mata a los adivinos de los escalones inferiores.\nAl suroeste, los Aulladores Crinpladas recorren las colinas al este de los poblados Secacorteza.",
	-- ["South-west, the Silvermane Howlers roam the hills east of the Witherbark villages."] = "Al suroeste, los aulladores Melenargenta recorren las colinas al este de los poblados Secacorteza.",
	-- ["The Highvale elves camp around {area:350}. Burn the report, the notes and the records in their camps. {npc:7780} is held inside the lodge: lead him out and fight off the ambush on the way.\nCareful: Groups of about three elves ambush the escort, usually twice."] = "Los elfos de Vallealto acampan alrededor de {area:350}. Quema el informe, las notas y los archivos de sus campamentos. {npc:7780} está preso dentro del refugio: sácalo de allí y rechaza la emboscada por el camino.\nCuidado: grupos de unos tres elfos emboscan la escolta, normalmente dos veces.",
	-- ["The Silvermane Stalkers, Savage Owlbeasts and Razorbeak Skylords share the hills between the temples and {area:351}. Use the {item:9618} on the owlbeasts you kill. The Skylords also drop Long Elegant Feathers: keep ten for {npc:14738}'s second message."] = "Los acechadores melenargenta, las lechubestias salvajes y los Señores del Cielo Picovaja comparten las colinas entre los templos y {area:351}. Usa {item:9618} en las lechubestias que mates. Los Señores del Cielo también sueltan plumas elegantes largas: guarda diez para el segundo mensaje de {npc:14738}.",
	-- ["The Vilebranch temples"] = "Los templos Vilrama",
	-- ["The big turtles crawl along the beaches north of the village, and {npc:2491}'s bottles of port lie on the same beaches, from the village up to the {area:307}: pick them up as you go. A snapjaw can drop OOX-09/HL's distress beacon, rarely: keep it."] = "Las tortugas grandes se arrastran por las playas al norte del poblado, y las botellas de oporto de {npc:2491} están en las mismas playas, desde el poblado hasta {area:307}: recógelas sobre la marcha. Un quijaforte puede soltar, rara vez, la baliza de socorro de OOX-09/HL: guárdala.",
	-- ["The big turtles crawl along the beaches north of the village, and {npc:2491}'s bottles of port lie on the same beaches, from the village up to the {area:307}: pick them up as you go. A snapjaw can drop OOX-09/HL's distress beacon, rarely: keep it.\nCareful: the biggest Saltwater Snapjaws are 50: pull them one at a time."] = "Las tortugas grandes se arrastran por las playas al norte del poblado, y las botellas de oporto de {npc:2491} están en las mismas playas, desde el poblado hasta {area:307}: recógelas sobre la marcha. Un quijaforte puede soltar, rara vez, la baliza de socorro de OOX-09/HL: guárdala.\nCuidado: los Quijafortes Aguasalada más grandes son de nivel 50: atráelos de uno en uno.",
	-- ["The central hills"] = "Las colinas centrales",
	-- ["The eastern slopes"] = "Las laderas del este",
	-- ["The five quests share the same parts: gather them all in one sweep. West of the road the {npc:5982} vultures, Starving Snickerfangs, Scorpok Stingers and Deatheye basilisks share the hills.\nEast of the road the Ashmane boars and Grunters root on the slopes beside the Redstone basilisks. Stay away from the level 52 Helboars further south.\nCareful: Scorpok Stingers (50-51) use {spell:5416}; {npc:8301} adds Knockdown. Pull the Stingers one at a time."] = "Las cinco misiones piden las mismas partes: reúnelas todas de una pasada. Al oeste del camino, los buitres {npc:5982}, las Hienas risitas hambrientas, los Aguijoneros Scorpok y los basiliscos Ojo de la Muerte comparten las colinas.\nAl este del camino, los jabalíes Crin de Ceniza y los Gruñidores hozan en las laderas junto a los basiliscos Piedrarroja. Aléjate de los Jabalíes infernales de nivel 52, más al sur.\nCuidado: los Aguijoneros Scorpok (50-51) usan {spell:5416}; {npc:8301} añade Derribo. Atrae a los Aguijoneros de uno en uno.",
	-- ["The five quests share the same parts: gather them all in one sweep. West of the road the {npc:5982} vultures, Starving Snickerfangs, Scorpok Stingers and Deatheye basilisks share the hills.\nEast of the road the Ashmane boars and Grunters root on the slopes beside the Redstone basilisks. Stay away from the level 52 Helboars further south.\nCareful: Scorpok Stingers use {spell:5416}; {npc:8301} adds Knockdown."] = "Las cinco misiones piden las mismas partes: reúnelas todas de una pasada. Al oeste del camino, los buitres {npc:5982}, las hienas risitas hambrientas, los aguijoneros Scorpok y los basiliscos Ojo de la Muerte comparten las colinas.\nAl este del camino, los jabalíes Crin de Ceniza y los Gruñidores hozan en las laderas junto a los basiliscos Piedrarroja. Aléjate de los Jabalíes infernales de nivel 52, más al sur.\nCuidado: los aguijoneros Scorpok usan {spell:5416}; {npc:8301} añade Derribo.",
	-- ["The next guide starts here, at {area:3317}."] = "La siguiente guía empieza aquí, en {area:3317}.",
	-- ["The northern beasts"] = "Las bestias del norte",
	-- ["These are elite mobs: grouping up is encouraged, look for people to do it with. {npc:7977} is a level 48 elite: most classes solo it at level 50, but you may need help. Skip it if you are alone: the route has you grind the XP back.\n{npc:7977} walks the shore below the {area:307}, from the arrow south to about 75,66 and north to about 82,52: if she isn't at the arrow, follow the shore."] = "Son enemigos élite: se recomienda ir en grupo, busca a gente con quien hacerlo. {npc:7977} es élite de nivel 48: la mayoría de las clases puede con ella en solitario a nivel 50, pero quizá necesites ayuda. Sáltatela si vas solo: la ruta te hace recuperar la experiencia matando.\n{npc:7977} recorre la orilla bajo {area:307}, desde la flecha hacia el sur hasta 75,66 aprox. y hacia el norte hasta 82,52 aprox.: si no está en la flecha, sigue la orilla.",
	-- ["To {area:75}"] = "A {area:75}",
	-- ["Vilebranch soothsayers"] = "Adivinos Vilrama",
	-- ["Vulture hills"] = "Colinas de los buitres",
	-- ["West of the island, the Vilebranch scalpers hold the temples of {area:1884} and {area:1917}. Slagtree's tools lie at one of the temples."] = "Al oeste de la isla, los arrancacabelleras Vilrama ocupan los templos de {area:1884} y {area:1917}. Las herramientas del herrero Esco están en uno de los templos.",
	-- ["grind on {npc:5982} at the northern hills, {zone:1419}"] = "mata {npc:5982} en las colinas del norte, {zone:1419}",
	-- ["{npc:6741}: for {zone:1456}, around level 50"] = "{npc:6741}: para {zone:1456}, hacia el nivel 50",
	-- ["{npc:7825}, the {object:36126}"] = "{npc:7825}, {object:36126}",
}
