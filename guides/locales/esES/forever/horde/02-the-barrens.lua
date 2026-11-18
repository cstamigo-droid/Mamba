-- Spanish (Spain) (esES): the guide forever/horde/02-the-barrens (forever/horde/02-the-barrens.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: Thun'grim Firegaze
	-- {npc:5878} Thun'grim Firegaze · {area:392} Ratchet
	["{npc:5878} camps beside the road east toward {area:392}."] = "{npc:5878} acampa junto al camino que va al este, hacia {area:392}.",

	-- Step 3: Razormane camp
	["Razormane camp"] = "Campamento Crines de Acero",

	-- Step 4: Telf Joolam
	-- {npc:5900} Telf Joolam · {item:6636} Fire Sapta · {npc:5893} Minor Manifestation of Fire · {item:6655} Glowing Ember
	["Back east over the bridge and up the trail to {npc:5900}'s shrine, as at 10. {npc:5900} makes {item:6636} from the tar and pouch. Use it by the brazier next to him to reveal the {npc:5893}, kill it for the {item:6655}, then place the ember in the brazier."] = "De vuelta al este por el puente y subiendo por el sendero hasta el santuario de {npc:5900}, como a nivel 10. {npc:5900} hace {item:6636} con el alquitrán y la bolsa. Úsalo junto al brasero a su lado para revelar a {npc:5893}, mátalo para obtener {item:6655} y luego coloca la brasa en el brasero.",

	-- Step 5: Kranal Fiss
	-- {npc:5907} Kranal Fiss · {npc:2523} Searing Totem · {item:5176} Fire Totem · {item:263412} Totem of Charged Flames
	["{npc:5907}: {npc:2523}, your {item:5176} and the {item:263412}"] = "{npc:5907}: {npc:2523}, tu {item:5176} y {item:263412}",

	-- Step 9: Fly to Crossroads
	["Fly to Crossroads"] = "Vuela al Cruce",
	-- {zone:1454} Orgrimmar
	["{zone:1454} flight master"] = "Maestro de vuelo de {zone:1454}",

	-- Step 10: The Crossroads
	-- {area:380} The Crossroads · {npc:3338} Sergra Darkthorn · {npc:3464} Gazrog · {npc:3615} Devrak · {npc:3429} Thork · {npc:3448} Tonga Runetotem · {npc:3419} Apothecary Zamah · {zone:1456} Thunder Bluff
	["{area:380} is your base for this guide. Everyone you need stands within a few steps of the inn: {npc:3338} by the inn, Helbrim and {npc:3464} by the north gate, then up the tower to {npc:3615}, the wind rider master, {npc:3429} and Darsok, and {npc:3448} at the south gate on the way out.\nAfter the spores Helbrim offers {npc:3419}, a delivery to {zone:1456} within 45 minutes: this route doesn't go there, so leave it (Druids take it on the next Crossroads stop, right before their flight to {zone:1456}). {npc:3615}, {npc:3429} and Darsok on the tower platform."] = "{area:380} es tu base en esta guía. Todos los que necesitas están a pocos pasos de la posada: {npc:3338} junto a la posada, Helbrim y {npc:3464} junto a la puerta norte, luego sube a la torre para ver a {npc:3615}, el maestro de jinetes del viento, {npc:3429} y Darsok, y a {npc:3448} en la puerta sur al salir.\nDespués de las esporas, Helbrim ofrece {npc:3419}, una entrega a {zone:1456} en 45 minutos: esta ruta no pasa por ahí, así que déjala (los druidas la aceptan en la siguiente parada en el Cruce, justo antes de su vuelo a {zone:1456}). {npc:3615}, {npc:3429} y Darsok en la plataforma de la torre.",

	-- Step 11: To Crossroads
	["To Crossroads"] = "Al Cruce",

	-- Step 17: The Crossroads
	-- {npc:3390} Apothecary Helbrim · {quest:1358} Sample for Helbrim
	["{npc:3390}: {quest:1358}, from Zinge"] = "{npc:3390}: {quest:1358}, de parte de Zinge",

	-- Step 18: The Crossroads
	-- {npc:3429} Thork
	["{npc:3429}, at the top of the tower"] = "{npc:3429}, en lo alto de la torre",

	-- Step 19: Raptor Heads as you go
	-- plural, as words: Raptor Heads = {item:5062} Raptor Head
	["Raptor Heads as you go"] = "Cabezas de raptor sobre la marcha",
	-- plural, as words: Sunscale Screechers = {npc:3255} Sunscale Screecher
	["Sunscale raptors roam the plains north and east of the Crossroads, and about three in four drop a head: kill the ones you pass on the way. Careful: Sunscale Screechers call nearby allies within 30 yd once below 30% health."] = "Los raptores Solescama recorren las llanuras al norte y al este del Cruce, y unos tres de cada cuatro sueltan una cabeza: mata a los que encuentres en el camino. Cuidado: los chilladores Solescama llaman a los aliados cercanos en 30 m cuando bajan del 30 % de salud.",

	-- Step 20: Vrang Wildgore
	-- {npc:3682} Vrang Wildgore
	["East from the keg toward Echeyakee: {npc:3682} camps below the hills, and his errands lie in the plains beside his camp."] = "Al este desde el barril hacia Echeyakee: {npc:3682} acampa bajo las colinas, y sus encargos están en las llanuras junto a su campamento.",

	-- Step 21: Savannah lions
	["Savannah lions"] = "Leones de la sabana",
	-- {npc:3682} Vrang Wildgore
	-- plural, as words: Savannah Patriarchs = {npc:3241} Savannah Patriarch
	["Savannah Patriarchs roam the plains east of {npc:3682}'s camp, and the Sprung Traps lie among them.\nSunscale raptors here count toward the heads."] = "Los Savannah Patriarchs rondan las llanuras al este del campamento de {npc:3682}, y las Sprung Traps están entre ellos.\nLos raptores Sunscale de aquí cuentan para las cabezas.",

	-- Step 22: Vrang Wildgore
	-- {npc:261366} Walton · {npc:3682} Vrang Wildgore · {area:383} Dry Hills
	["{npc:261366}, the hermit on the ridge behind {npc:3682}: on the next {area:383} visit, with Serena"] = "{npc:261366}, el ermitaño en la cresta detrás de {npc:3682}: en la próxima visita a {area:383}, con Serena",

	-- Step 23: Finish the Raptor Heads
	-- plural, as words: Raptor Heads = {item:5062} Raptor Head
	["Finish the Raptor Heads"] = "Termina las cabezas de raptor",
	-- plural, as words: Sunscale Lashtails = {npc:3254} Sunscale Lashtail
	["Still short of twelve? Sunscale Lashtails and Screechers roam the plains north-east of the Crossroads, on the way back south from Echeyakee's lair."] = "¿Aún te faltan para llegar a doce? Los colazotes y chilladores Sunscale recorren las llanuras al noreste del Cruce, de regreso al sur desde la guarida de Echeyakee.",

	-- Step 24: The Crossroads
	-- {npc:3464} Gazrog · {npc:3338} Sergra Darkthorn · {npc:3429} Thork
	-- was: ["In from the north gate: {npc:3464} first, {npc:3338} by the inn, then up to {npc:3449} and {npc:3429} on the tower platform, where the flight master stands."] = "Entra por la puerta norte: primero {npc:3464}, {npc:3338} junto a la posada y luego sube hasta {npc:3449} y {npc:3429} en la plataforma de la torre, donde está el maestro de vuelo."
	["In from the north gate: {npc:3464} first, {npc:3338} by the inn, then up to Darsok and {npc:3429} on the tower platform, where the flight master stands."] = "Entrando por la puerta norte: primero {npc:3464}, luego {npc:3338} junto a la posada, y después sube con Darsok y {npc:3429} a la plataforma de la torre, donde está el maestro de vuelo.",

	-- Step 27: Razormane camp
	-- {object:58369} Stolen Iron Chest · {item:5026} Fire Tar
	["The Razormane camp lies east of the Crossroads. Warriors: the {object:58369} stands in the camp. Shamans: the quilboar drop the {item:5026}.\nCareful: The chest stands next to a broken wagon, guarded by a pair of Razormanes, including hunters that can pull more quilboar into the fight."] = "El campamento Crines de Acero está al este del Cruce. Guerreros: {object:58369} está en el campamento. Chamanes: los jabaespines sueltan {item:5026}.\nCuidado: El cofre está junto a una carreta rota, vigilado por un par de Crines de Acero, entre ellos cazadores que pueden atraer a más jabaespines a la pelea.",

	-- Step 29: Thorn Hill: kill these as you meet them
	-- {area:1699} Thorn Hill
	["{area:1699}: kill these as you meet them"] = "{area:1699}: mata a estos según te los encuentres",
	["Careful: Razormane Flesheaters and Berserkers (18-19) are elites; they stand in the camp's north-east, beside the supply crates: pull the quilboar away from them one at a time."] = "Cuidado: los Comecarnes y Berserkers Razormane (18-19) son élites; están en el noreste del campamento, junto a las cajas de suministros: aleja a los jabaespines de ellos, de uno en uno.",

	-- Step 31: Ratchet
	-- {area:392} Ratchet
	-- was: ["Follow the road south-east to {area:392} on the coast."] = "Sigue el camino al sureste hasta {area:392}, en la costa."
	["Follow the road south-east to {area:392} on the coast."] = "Sigue el camino al sureste hasta {area:392}, en la costa.",
	-- {npc:3442} Sputtervalve · {area:382} Sludge Fen
	["{npc:3442}: the console is in the {area:382}, later"] = "{npc:3442}: la consola está en {area:382}, más tarde",
	-- {npc:3391} Gazlowe
	["{npc:3391}, upstairs"] = "{npc:3391}, en el piso de arriba",
	-- {quest:1492} Wharfmaster Dizzywig
	["{quest:1492}, on the dock"] = "{quest:1492}, en el muelle",

	-- Step 32: The Barrens: kill these as you meet them
	-- {area:17} The Barrens
	["{area:17}: kill these as you meet them"] = "{area:17}: mata a estos según te los encuentres",
	-- {area:392} Ratchet · {npc:3467} Baron Longshore
	["The pirates camp on the beach south of {area:392}: the piles of complicated parts lie in the sand among them. {npc:3467} (16) stands at the camp's southern end: leave him for the next {area:392} stop."] = "Los piratas acampan en la playa al sur de {area:392}: los montones de piezas complicadas están en la arena entre ellos. {npc:3467} (16) está en el extremo sur del campamento: déjalo para la próxima parada en {area:392}.",

	-- Step 33: Ratchet
	-- {npc:3391} Gazlowe · {area:392} Ratchet
	["{npc:3391}: the crates lie at the south end of the beach camp, on the next {area:392} stop at 18"] = "{npc:3391}: las cajas están en el extremo sur del campamento de la playa, en la próxima parada en {area:392}, a nivel 18",

	-- Step 34: Stolen Booty
	-- {npc:3467} Baron Longshore
	["East to the beach, at the south end of the pirate camp: the crate of boots and the fragile crate with the lens sit there, and {npc:3467} (16) stands beside them."] = "Ve al este, a la playa, al extremo sur del campamento pirata: la caja de botas y la caja frágil con la lente están allí, y {npc:3467} (16) está a su lado.",

	-- Step 35: Ratchet
	-- {npc:3391} Gazlowe
	["{npc:3391} stands upstairs in his building: go up inside, the arrow cannot tell the floors apart."] = "{npc:3391} está en el piso de arriba de su edificio: sube por dentro, la flecha no distingue los pisos.",

	-- Step 36: Fly to Crossroads
	-- {area:392} Ratchet
	["{area:392} flight master"] = "Maestro de vuelo de {area:392}",

	-- Step 39: Gur'ak
	-- {npc:267310} Gur'ak · {quest:97003} Chol'aruk the Ravener · {area:1699} Thorn Hill · {npc:3438} Kreenig Snarlsnout
	-- was: ["{npc:267310} stands on the north-east side of the Crossroads. {quest:97003} is a group quest: {npc:267307} is a level 20 elite boar in the Razormane's {area:1699} cave, east of the town, where the route goes back for {npc:3438} later."] = "{npc:267310} está en el lado noreste del Cruce. {quest:97003} es una misión de grupo: {npc:267307} es un jabalí élite de nivel 20 en la cueva Crines de Acero de {area:1699}, al este del pueblo, adonde la ruta vuelve más tarde por {npc:3438}."
	["{npc:267310} stands on the north-east side of the Crossroads. {quest:97003} is a group quest: Chol'aruk is a level 20 elite boar in the Razormane's {area:1699} cave, east of the town, where the route goes back for {npc:3438} later."] = "{npc:267310} está en el lado noreste del Cruce. {quest:97003} es una misión de grupo: Chol'aruk es un jabalí élite de nivel 20 en la cueva Razormane de {area:1699}, al este del pueblo, adonde la ruta vuelve después por {npc:3438}.",

	-- Step 40: Regthar Deathgate
	-- {npc:3389} Regthar Deathgate
	["West to {npc:3389}'s watch post on the Kolkar border."] = "Ve al oeste, al puesto de vigilancia de {npc:3389} en la frontera Kolkar.",

	-- Step 41: The Barrens: kill these as you meet them
	-- {npc:3389} Regthar Deathgate · {npc:3394} Barak Kodobane
	-- plural, as words: Laden Mushrooms = {object:3640} Laden Mushroom
	["The pools lie just north of {npc:3389}. Walk into the water to explore them; the Laden Mushrooms for Helbrim grow around them. Kill every Kolkar you pass for bracers. {npc:3394} stands in the Kolkar camp west of the pools."] = "Las pozas están justo al norte de {npc:3389}. Entra en el agua para explorarlas; los Champiñones cargados para Helbrim crecen a su alrededor. Mata a todo Kolkar que encuentres para conseguir brazales. {npc:3394} está en el campamento Kolkar al oeste de las pozas.",

	-- Step 42: Samophlange
	-- {object:4141} Control Console · {area:382} Sludge Fen · {item:5089} Console Key · {npc:3471} Tinkerer Sniggles
	["The {object:4141} stands at the Venture Co. research site west of the {area:382}. Close the three valves around the drill, use the console again, then take the {item:5089} from {npc:3471} beside it.\nCareful: Several guards stand within aggro range of the valves, respawn in under about 3 minutes, and run at low health to bring back help; nearby mobs also join if you use a valve while they are close."] = "{object:4141} está en el puesto de investigación de Ventura y Cía., al oeste de {area:382}. Cierra las tres válvulas alrededor de la perforadora, vuelve a usar la consola y luego quítale {item:5089} a {npc:3471}, que está al lado.\nCuidado: varios guardias están a distancia de aggro de las válvulas, reaparecen en menos de unos 3 minutos y huyen con poca salud para traer ayuda; los enemigos cercanos también se unen si usas una válvula estando ellos cerca.",

	-- Step 43: To Brakk
	-- {npc:265809} Brakk
	["To {npc:265809}"] = "Ve por {npc:265809}",

	-- Step 44: Brakk
	-- {npc:3175} Krunn · {skill:186} Mining
	["{npc:3175} takes it once your {skill:186} skill is 20: gather or craft until then, the guide carries on meanwhile."] = "{npc:3175} la recibe cuando tu habilidad de {skill:186} sea 20: recolecta o fabrica hasta entonces, la guía sigue mientras tanto.",

	-- Step 46: Brakk
	-- {npc:11025} Mukdrak · {skill:202} Engineering
	["{npc:11025} takes it once your {skill:202} skill is 20: gather or craft until then, the guide carries on meanwhile."] = "{npc:11025} la acepta cuando tu habilidad de {skill:202} es 20: recolecta o fabrica hasta entonces, mientras tanto la guía sigue.",

	-- Step 50: Krunn
	["Inside"] = "Adentro",

	-- Step 52: Class trainer
	["Class trainer"] = "Instructor de clase",

	-- Step 53: Into Durotar
	-- {area:14} Durotar
	["Into {area:14}"] = "Entra en {area:14}",

	-- Step 56: Telf Joolam
	-- {npc:5900} Telf Joolam · {item:6636} Fire Sapta · {npc:5893} Minor Manifestation of Fire · {item:6655} Glowing Ember
	["Back east over the bridge and up the trail to {npc:5900}'s shrine again. {npc:5900} makes {item:6636} from the tar and pouch. Use it by the brazier next to him to reveal the {npc:5893}, kill it for the {item:6655}, then place the ember in the brazier."] = "Vuelve al este por el puente y sube otra vez por el sendero hasta el santuario de {npc:5900}. {npc:5900} hace {item:6636} con el alquitrán y la bolsa. Úsalo junto al brasero a su lado para revelar a {npc:5893}, mátalo para conseguir {item:6655} y luego pon la ascua en el brasero.",

	-- Step 57: Into The Barrens
	-- {area:17} The Barrens
	["Into {area:17}"] = "Entra a {area:17}",

	-- Step 59: To The Disruption Ends
	-- {quest:872} The Disruption Ends
	["To {quest:872}"] = "A {quest:872}",

	-- Step 60: The Disruption Ends
	-- {npc:3438} Kreenig Snarlsnout · {area:1699} Thorn Hill
	-- was: ["Back to the Razormane camp. Geomancers and Defenders hold its eastern half; {npc:3438} walks among them. Careful: Razormane Flesheaters and Berserkers (18-19) are elites in the camp's north-east, near {npc:3438} and the supply crates, and {npc:267307} (20, elite) lies in the cave under {area:1699} beside them: pull {npc:3438} and the quilboar away from them one at a time, and leave the cave alone unless you are in a group."] = "Vuelve al campamento Crines de Acero. Los geomantes y los defensores ocupan su mitad este; {npc:3438} camina entre ellos. Cuidado: los Comecarnes y Rabiosos Crines de Acero (18-19) son élites en el noreste del campamento, cerca de {npc:3438} y de las cajas de suministros, y {npc:267307} (20, élite) está en la cueva bajo {area:1699}, junto a ellos: atrae a {npc:3438} y a los jabaespines lejos de ellos de uno en uno, y deja la cueva en paz salvo que vayas en grupo."
	["Back to the Razormane camp. Geomancers and Defenders hold its eastern half; {npc:3438} walks among them. Careful: Razormane Flesheaters and Berserkers (18-19) are elites in the camp's north-east, near {npc:3438} and the supply crates, and Chol'aruk (20, elite) lies in the cave under {area:1699} beside them: pull {npc:3438} and the quilboar away from them one at a time, and leave the cave alone unless you are in a group."] = "De vuelta al campamento Razormane. Los Geománticos y Defensores ocupan su mitad este; {npc:3438} camina entre ellos. Cuidado: los Comecarnes y Berserkers Razormane (18-19) son élites en el noreste del campamento, cerca de {npc:3438} y de las cajas de suministros, y Chol'aruk (20, élite) está en la cueva bajo {area:1699}, junto a ellos: aleja a {npc:3438} y a los jabaespines de ellos, de uno en uno, y no entres a la cueva a menos que vayas en grupo.",

	-- Step 61: The Crossroads
	-- {npc:3338} Sergra Darkthorn · {npc:3429} Thork · {npc:3432} Mankrik · {npc:3448} Tonga Runetotem · {npc:3395} Verog the Dervish · {area:388} Stagnant Oasis · {area:383} Dry Hills
	["{npc:3338} by the inn first, then Helbrim by the north gate, {npc:3429} and Darsok on the tower platform, {npc:3432} by the inn, and {npc:3448} at the south gate last. His seed test waits for the {npc:3395} pass at the {area:388}: go straight on north-west to the {area:383}."] = "Primero {npc:3338} junto a la posada, luego Helbrim junto a la puerta norte, {npc:3429} y Darsok en la plataforma de la torre, {npc:3432} junto a la posada, y {npc:3448} en la puerta sur al final. Su prueba de semillas espera en el paso de {npc:3395} en {area:388}: sigue directo al noroeste hasta {area:383}.",

	-- Step 62: Chol'aruk
	["Chol'aruk"] = "Chol'aruk",
	-- {area:1699} Thorn Hill
	-- was: ["These are elite mobs: grouping up is encouraged, look for people to do it with. {npc:267307} (level 20 elite) needs a group of 3 and sits deep in the cave under {area:1699}, past the Razormane Flesheaters and Berserkers (18-19, elite). Skip it if you are alone."] = "Son enemigos élite: se recomienda ir en grupo, busca gente con quien hacerlo. {npc:267307} (élite de nivel 20) requiere un grupo de 3 y está al fondo de la cueva bajo {area:1699}, más allá de los Comecarnes y Rabiosos Crines de Acero (18-19, élite). Sáltalo si vas solo."
	["These are elite mobs: grouping up is encouraged, look for people to do it with. Chol'aruk (level 20 elite) needs a group of 3 and sits deep in the cave under {area:1699}, past the Razormane Flesheaters and Berserkers (18-19, elite). Skip it if you are alone."] = "Son enemigos élite: se recomienda agruparse, busca gente para hacerlo. Chol'aruk (élite de nivel 20) necesita un grupo de 3 y está en lo profundo de la cueva bajo {area:1699}, pasando los Comecarnes y Berserkers Razormane (18-19, élite). Omítelo si estás solo.",

	-- Step 63: The Crossroads
	-- {npc:3338} Sergra Darkthorn · {npc:3429} Thork · {npc:3432} Mankrik · {npc:3448} Tonga Runetotem · {npc:3395} Verog the Dervish · {area:388} Stagnant Oasis · {area:383} Dry Hills · {npc:3419} Apothecary Zamah · {zone:1456} Thunder Bluff
	-- was: ["{npc:3338} by the inn first, then Helbrim by the north gate, {npc:3429} and {npc:3449} on the tower platform, {npc:3432} by the inn, and {npc:3448} at the south gate last. His seed test waits for the {npc:3395} pass at the {area:388}: go straight on north-west to the {area:383}. After the spores Helbrim offers {quest:853}, a delivery to {zone:1456} within 45 minutes: this route doesn't go there, so leave it (Druids take it on the next Crossroads stop, right before their flight to {zone:1456})."] = "Primero {npc:3338} junto a la posada, luego Helbrim junto a la puerta norte, {npc:3429} y {npc:3449} en la plataforma de la torre, {npc:3432} junto a la posada y, por último, {npc:3448} en la puerta sur. Su prueba de semillas espera a la pasada por {npc:3395} en {area:388}: sigue recto hacia el noroeste hasta {area:383}. Después de las esporas, Helbrim ofrece {quest:853}, una entrega en {zone:1456} en menos de 45 minutos: esta ruta no va allí, así que déjala (los druidas la aceptan en la siguiente parada en el Cruce, justo antes de su vuelo a {zone:1456})."
	["{npc:3338} by the inn first, then the innkeeper, Helbrim by the north gate, {npc:3429} and Darsok on the tower platform, {npc:3432} by the inn, and {npc:3448} at the south gate last. His seed test waits for the {npc:3395} pass at the {area:388}: go straight on north-west to the {area:383}. After the spores Helbrim offers {npc:3419}, a delivery to {zone:1456} within 45 minutes: this route doesn't go there, so leave it (Druids take it on the next Crossroads stop, right before their flight to {zone:1456})."] = "Primero {npc:3338} junto a la posada, luego el tabernero, Helbrim junto a la puerta norte, {npc:3429} y Darsok en la plataforma de la torre, {npc:3432} junto a la posada, y {npc:3448} en la puerta sur al final. Su prueba de semillas espera en el paso de {npc:3395} en {area:388}: sigue directo al noroeste hasta {area:383}. Después de las esporas, Helbrim ofrece {npc:3419}, una entrega a {zone:1456} en 45 minutos: esta ruta no pasa por ahí, así que déjala (los druidas la aceptan en la siguiente parada en el Cruce, justo antes de su vuelo a {zone:1456}).",

	-- Step 64: Level 16
	["Level 16"] = "Nivel 16",
	-- {area:380} The Crossroads
	["Top up here to level 16 before the hand-ins at {area:380}: they take you to level 22."] = "Sube de nivel aquí hasta el nivel 16 antes de las entregas en {area:380}: te llevan al nivel 22.",
	-- {npc:3266} Razormane Defender
	["grind on {npc:3266}"] = "farmea con {npc:3266}",

	-- Step 65: The Crossroads
	-- {npc:3429} Thork · {area:1703} Mor'shan Rampart
	["{npc:3429}, on the tower, from level 17. Keep it: Kadrak at the {area:1703}, next guide"] = "{npc:3429}, en la torre, desde el nivel 17. Guárdala: Kadrak en {area:1703}, en la siguiente guía",

	-- Step 66: Far Watch Post
	-- {npc:3337} Kargal Battlescar · {quest:840} Conscript of the Horde · {area:14} Durotar
	-- was: ["{npc:3337}: {quest:840}, from {zone:1411}"] = "{npc:3337}: {quest:840}, de {zone:1411}"
	["{npc:3337}: {quest:840}, from {area:14}"] = "{npc:3337}: {quest:840}, desde {area:14}",

	-- Step 67: Far Watch Post
	-- {zone:1454} Orgrimmar · {area:14} Durotar · {area:814} Southfury River · {area:379} Far Watch Post · {area:17} The Barrens · {npc:3337} Kargal Battlescar · {quest:809} Ak'Zeloth · {npc:5810} Uzzek
	["Leave {zone:1454} by the main gate and follow the road south through {area:14}, then west over the {area:814} bridge: {area:379} sits just above it on the {area:17} side. {npc:3337}, {quest:809} and {npc:5810} stand together."] = "Sal de {zone:1454} por la puerta principal y sigue el camino al sur a través de {area:14}, luego al oeste por el puente de {area:814}: {area:379} está justo encima, del lado de {area:17}. {npc:3337}, {quest:809} y {npc:5810} están juntos.",

	-- Step 68: Far Watch Post
	-- {quest:809} Ak'Zeloth · {npc:3337} Kargal Battlescar · {npc:3216} Neeru Fireblade · {zone:1454} Orgrimmar
	["{quest:809}, beside {npc:3337}: from {npc:3216} in {zone:1454}"] = "{quest:809}, junto a {npc:3337}: de {npc:3216} en {zone:1454}",

	-- Step 71: Far Watch Post
	-- {zone:1454} Orgrimmar · {area:14} Durotar · {area:814} Southfury River · {npc:5810} Uzzek · {area:379} Far Watch Post
	-- was: ["Leave {zone:1454} by the main gate and follow the road south through {zone:1411}, then west over the {area:814} bridge: {npc:5810} stands at {area:379} just above it, on the road to the Crossroads."] = "Sal de {zone:1454} por la puerta principal y sigue el camino al sur por {zone:1411}; luego al oeste por el puente de {area:814}: {npc:5810} está en {area:379}, justo encima, en el camino al Cruce."
	["Leave {zone:1454} by the main gate and follow the road south through {area:14}, then west over the {area:814} bridge: {npc:5810} stands at {area:379} just above it, on the road to the Crossroads."] = "Sal de {zone:1454} por la puerta principal y sigue el camino al sur por {area:14}, luego al oeste cruzando el puente de {area:814}: {npc:5810} está en {area:379}, justo arriba de él, en el camino al Cruce.",

	-- Step 72: The Crossroads
	-- {area:379} Far Watch Post · {npc:3489} Zargh · {npc:3338} Sergra Darkthorn · {npc:3464} Gazrog
	["You arrive from {area:379}. {npc:3489} and {npc:3338} stand by the inn, Helbrim and {npc:3464} by the north gate."] = "Llegas desde {area:379}. {npc:3489} y {npc:3338} están junto a la posada, Helbrim y {npc:3464} junto a la puerta norte.",

	-- Step 73: Inn and flight master
	["Inn and flight master"] = "Posada y maestro de vuelo",

	-- Step 74: The Crossroads
	-- {npc:3615} Devrak
	["{npc:3615}, on the tower"] = "{npc:3615}, en la torre",

	-- Step 75: The Crossroads
	-- {npc:3432} Mankrik
	["{npc:3432}: his wife lies at the north edge of the Bristleback camps, later"] = "{npc:3432}: su esposa yace en el borde norte de los campamentos Lomopelo, más adelante",

	-- Step 76: Fly to Ratchet
	-- {area:392} Ratchet
	["Fly to {area:392}"] = "Vuela a {area:392}",
	["Crossroads flight master"] = "Maestro de vuelo del Cruce",

	-- Step 77: Ratchet
	-- {npc:3442} Sputtervalve · {quest:1483} Ziz Fizziks · {area:1076} Webwinder Path
	["{npc:3442}: keep it, {quest:1483} is on the {area:1076} in Stonetalon, at the end of this guide"] = "{npc:3442}: guárdala, {quest:1483} está en {area:1076}, en Sierra Espolón, al final de esta guía",
	-- {npc:3453} Wharfmaster Dizzywig · {area:381} Boulder Lode Mine
	["{npc:3453}: the emerald comes from the {area:381}, later"] = "{npc:3453}: la esmeralda sale de {area:381}, más adelante",
	-- {object:3972} WANTED · {npc:3467} Baron Longshore · {area:392} Ratchet
	["The {object:3972} poster: {npc:3467} comes on the next {area:392} stop too"] = "El cartel de {object:3972}: {npc:3467} también llega en la próxima parada en {area:392}",
	-- {npc:3446} Mebok Mizzyrix · {quest:865} Raptor Horns · {npc:3467} Baron Longshore · {area:392} Ratchet
	["Keep {npc:3446}'s {quest:865} and {npc:3467} for the next {area:392} stop, at 18: Scytheclaws you meet on the plains before then drop the horns too."] = "Guarda {quest:865} de {npc:3446} y a {npc:3467} para la próxima parada en {area:392}, a nivel 18: los Segadores Solescama que encuentres antes por las llanuras también sueltan los cuernos.",
	-- {npc:3446} Mebok Mizzyrix · {object:3972} WANTED · {area:392} Ratchet
	["{npc:3446}, beside the {object:3972} poster: the Sunscale raptors come on the next {area:392} stop, at 18"] = "{npc:3446}, junto al cartel de {object:3972}: los raptores Solescama llegan en la próxima parada en {area:392}, a nivel 18",

	-- Step 82: Regthar Deathgate
	-- {npc:3389} Regthar Deathgate · {npc:3395} Verog the Dervish · {area:388} Stagnant Oasis
	["{npc:3389}: {npc:3395} comes out when you kill the Kolkar at the {area:388}, later"] = "{npc:3389}: {npc:3395} aparece cuando matas a los Kolkar en {area:388}, más adelante",

	-- Step 86: The Crossroads
	-- {npc:3464} Gazrog · {quest:3281} Stolen Silver · {area:385} Northwatch Hold
	["{npc:3464}: the {quest:3281}, in a raptor nest north-west of {area:385}"] = "{npc:3464}: {quest:3281}, en un nido de raptor al noroeste de {area:385}",

	-- Step 87: Fly to Thunder Bluff
	-- {area:1638} Thunder Bluff
	["Fly to {area:1638}"] = "Vuela a {area:1638}",

	-- Step 88: Thunder Bluff
	-- {area:1638} Thunder Bluff · {npc:3033} Turak Runetotem · {area:1639} Elder Rise
	["Fly from the Crossroads to {area:1638}: {npc:3033} trains you on {area:1639}."] = "Vuela del Cruce a {area:1638}: {npc:3033} te entrena en {area:1639}.",

	-- Step 89: Moonglade
	-- {spell:18960} Teleport: Moonglade
	["Cast {spell:18960}"] = "Lanza {spell:18960}",

	-- Step 90: Trial of the Lake
	-- {npc:11802} Dendrite Starblaze · {area:2361} Nighthaven · {area:656} Lake Elune'ara · {object:177788} Shrine of Remulos · {npc:11799} Tajarri · {quest:28} Trial of the Lake
	-- plural, as words: Shrine Baubles = {item:15877} Shrine Bauble
	["{npc:11802} stands upstairs in his building in {area:2361}: go up inside, the arrow cannot tell the floors apart. The Shrine Baubles lie on the bed of {area:656} and fade within minutes: swim one straight to the {object:177788} on the north-west shore, use it there and speak to {npc:11799}. {quest:28} runs on a timer: no teleport or Hearthstone until {npc:11799} has it."] = "{npc:11802} está en el piso de arriba de su edificio en {area:2361}: sube por dentro, la flecha no distingue los pisos. Las Baratijas del santuario están en el fondo de {area:656} y se desvanecen en pocos minutos: nada con una directo hasta {object:177788} en la orilla noroeste, úsala ahí y habla con {npc:11799}. {quest:28} tiene un límite de tiempo: no uses teletransporte ni piedra de hogar hasta que {npc:11799} la tenga.",
	-- {quest:6127} The Principal Source · {area:384} Dreadmist Peak
	["{quest:6127}: {area:384}, next guide"] = "{quest:6127}: {area:384}, en la siguiente guía",
	-- {item:15877} Shrine Bauble · {object:177785} Bauble Container
	["{item:15877}, from a {object:177785} in the lake"] = "{item:15877}, de un {object:177785} del lago",
	-- {object:177788} Shrine of Remulos
	-- was: ["At the {area:2362}"] = "En el {area:2362}"
	["At the {object:177788}"] = "En {object:177788}",
	-- {npc:11799} Tajarri · {object:177788} Shrine of Remulos
	-- was: ["{npc:11799}, at the {area:2362}"] = "{npc:11799}, en {area:2362}"
	["{npc:11799}, at the {object:177788}"] = "{npc:11799}, en {object:177788}",
	-- {quest:30} Trial of the Sea Lion · {area:382} Sludge Fen · {area:287} Hillsbrad
	["{quest:30}, carried: one half pendant in the {area:382} in this guide, the other underwater off Silverpine on the way to {area:287} at 21; the pendant is handed in after {area:287}"] = "{quest:30}, pendiente: una mitad del colgante está en {area:382} en esta guía, la otra bajo el agua frente a Bosque de Argénteos, de camino a {area:287} en el paso 21; el colgante se entrega después de {area:287}",
	-- {npc:11798} Bunthen Plainswind · {area:2361} Nighthaven
	["{npc:11798} in {area:2361} flies druids there"] = "{npc:11798}, en {area:2361}, lleva volando allí a los druidas",

	-- Step 94: To Class trainer
	["To Class trainer"] = "Al instructor de tu clase",

	-- Step 96: To Raptor Grounds: kill these as you meet them
	-- {area:1697} Raptor Grounds
	["To {area:1697}: kill these as you meet them"] = "Hacia {area:1697}: mata a estos enemigos conforme los encuentres",

	-- Step 97: Raptor Grounds: kill these as you meet them
	-- {area:1697} Raptor Grounds
	["{area:1697}: kill these as you meet them"] = "{area:1697}: mata a estos según te los encuentres",
	-- {area:1697} Raptor Grounds · {npc:3446} Mebok Mizzyrix · {area:392} Ratchet · {npc:3682} Vrang Wildgore · {area:385} Northwatch Hold
	-- plural, as words: Sunscale Scytheclaws = {npc:3256} Sunscale Scytheclaw
	["Sunscale Scytheclaws hunt the plains around the {area:1697}; they drop the horns. {npc:3446} takes them back in {area:392}; any still missing come with {npc:3682}'s hills later.\nSouth-east toward the coast: the stolen silver lies in a raptor nest north-west of {area:385}."] = "Los Segadores Solescama cazan en las llanuras alrededor de {area:1697}; sueltan los cuernos. {npc:3446} los recibe en {area:392}; los que te falten saldrán más tarde en las colinas de {npc:3682}.\nVe al sureste hacia la costa: la plata robada está en un nido de raptores al noroeste de {area:385}.",

	-- Step 99: Ratchet
	-- {area:392} Ratchet
	["Back north along the beach to {area:392}."] = "Vuelve al norte por la playa hasta {area:392}.",
	-- {npc:3446} Mebok Mizzyrix · {object:3972} WANTED
	["{npc:3446}, beside the {object:3972} poster"] = "{npc:3446}, junto al cartel de {object:3972}",

	-- Step 104: Dreadmist Peak
	-- {area:384} Dreadmist Peak · {item:15842} Empty Dreadmist Peak Sampler · {object:19464} Dreadmist Peak Pool · {npc:3448} Tonga Runetotem · {skill:182} Herbalism · {npc:3490} Hula'mahi · {item:2449} Earthroot
	["Head north from the Crossroads to {area:384} and fill the {item:15842} at the {object:19464}, then back to {npc:3448} in the Crossroads. No {skill:182}? {npc:3490} beside him sells {item:2449}, three at a time until he restocks."] = "Ve al norte desde el Cruce hasta {area:384} y llena {item:15842} en {object:19464}, luego vuelve con {npc:3448} en el Cruce. ¿No tienes {skill:182}? {npc:3490}, a su lado, vende {item:2449}, de a tres hasta que repone.",
	-- {item:2449} Earthroot · {npc:3490} Hula'mahi
	["{item:2449} from {npc:3490}; herbalists pick it on the plains"] = "{item:2449} de {npc:3490}; los herboristas la recogen en las llanuras",

	-- Step 105: Kolkar camp
	["Kolkar camp"] = "Campamento Kolkar",
	-- {npc:3389} Regthar Deathgate · {item:2449} Earthroot
	-- plural, as words: Lost Barrens Kodos = {npc:3234} Lost Barrens Kodo
	["Lost Barrens Kodos roam the plains around the Kolkar camp north-west of {npc:3389}; herbalists pick {item:2449} there too."] = "Los Kodos de Los Baldíos perdidos recorren las llanuras alrededor del campamento Kolkar al noroeste de {npc:3389}; los herboristas también recogen {item:2449} ahí.",

	-- Step 106: Into Stonetalon Mountains
	-- {area:406} Stonetalon Mountains
	["Into {area:406}"] = "Entra a {area:406}",

	-- Step 108: Walton
	-- {npc:261366} Walton · {npc:3682} Vrang Wildgore
	["{npc:261366}, the hermit, stands on the ridge behind {npc:3682}'s camp."] = "{npc:261366}, el ermitaño, está en la cresta detrás del campamento de {npc:3682}.",

	-- Step 109: Trouble in the Valley
	-- {npc:261366} Walton
	["Corporal Adamore and his marines hold the wrecked caravan south of {npc:261366}. The marines are linked: pulling one calls the rest. Pull from the edge and run; they leash short, so you can thin the camp one at a time before tackling the Corporal."] = "Corporal Adamore y sus marines tienen la caravana destrozada al sur de {npc:261366}. Los marines están enlazados: atraer a uno llama a los demás. Atrae desde el borde y corre; no te persiguen lejos, así que puedes ir reduciendo el campamento de uno en uno antes de enfrentar al Corporal.",

	-- Step 111: Into Ashenvale
	-- {zone:1440} Ashenvale
	["Into {zone:1440}"] = "Hacia {zone:1440}",

	-- Step 114: Ignition
	-- {npc:3439} Wizzlecrank's Shredder · {area:382} Sludge Fen · {npc:3445} Supervisor Lugwizzle
	["{npc:3439} stands inside the Venture Co. camp in the {area:382}; {npc:3445} carries the key."] = "{npc:3439} está dentro del campamento de Ventura y Cía. en {area:382}; {npc:3445} lleva la llave.",

	-- Step 115: Strange Lockbox
	-- {object:177794} Strange Lockbox · {area:382} Sludge Fen · {item:15883} Half Pendant of Aquatic Agility · {quest:30} Trial of the Sea Lion
	["The {object:177794} lies at the north edge of the {area:382}, by the Venture Co. tower. It holds the {item:15883} for {quest:30}."] = "{object:177794} está en el borde norte de {area:382}, junto a la torre de Ventura y Cía. Contiene {item:15883} para {quest:30}.",

	-- Step 116: The Escape
	-- {npc:3442} Sputtervalve · {area:392} Ratchet
	["Wizzlecrank drives his shredder out of the camp: stay with him and kill whatever attacks him. {npc:3442} takes it in {area:392}.\nCareful: The route leads west and climbs a ramp. Once you reach the top, two Venture Company mobs ambush you."] = "Wizzlecrank saca su trituradora del campamento: quédate con él y mata a todo lo que lo ataque. {npc:3442} la recibe en {area:392}.\nCuidado: La ruta va al oeste y sube por una rampa. Al llegar arriba, dos enemigos de Ventura y Cía. te emboscan.",

	-- Step 117: Boulder Lode Mine
	-- {item:5097} Cats Eye Emerald
	-- plural, as words: Venture Co. Overseers = {npc:3286} Venture Co. Overseer
	["The Venture Co. Overseers and Enforcers at the mine in the north-east corner of the zone drop the {item:5097}."] = "Los Sobrestantes y Déspotas de Ventura y Cía. de la mina en la esquina noreste de la zona sueltan la {item:5097}.",

	-- Step 118: Wenikee Boltbucket
	-- {npc:9316} Wenikee Boltbucket
	["West from the mine to {npc:9316}'s camp, then south down the road to the Crossroads."] = "Al oeste desde la mina hasta el campamento de {npc:9316}, luego al sur por el camino hasta el Cruce.",
	-- {quest:3923} Rilli Greasygob · {zone:1454} Orgrimmar · {object:172958} Valley of Honor
	["Keep it: {quest:3923} is in {zone:1454}'s {object:172958}, on the {zone:1454} trip at 20"] = "Guárdala: {quest:3923} está en {object:172958} de {zone:1454}, en el viaje a {zone:1454} del paso 20",

	-- Step 119: the Crossroads
	["the Crossroads"] = "el Cruce",
	-- {npc:3448} Tonga Runetotem
	["South down the road to the Crossroads: Darsok stands on the tower platform, {npc:3448} at the south gate."] = "Al sur por el camino hasta el Cruce: Darsok está en la plataforma de la torre, {npc:3448} en la puerta sur.",
	-- {item:15826} Curative Animal Salve
	["He gives you the {item:15826}"] = "Te da {item:15826}",

	-- Step 120: Verog the Dervish
	-- {npc:3395} Verog the Dervish · {area:388} Stagnant Oasis · {npc:3448} Tonga Runetotem
	["{npc:3395} doesn't wander on his own: he comes out when you kill the Kolkar centaurs at the {area:388}, south-east of the Crossroads. Keep killing them around the oasis until he appears. Test {npc:3448}'s seeds at the bubbling fissure on the oasis' east bank while you are there."] = "{npc:3395} no deambula por su cuenta: aparece cuando matas a los centauros Kolkar de {area:388}, al sureste del Cruce. Sigue matándolos alrededor del oasis hasta que aparezca. Mientras estés allí, prueba las semillas de {npc:3448} en la fisura burbujeante de la orilla este del oasis.",
	-- {npc:12296} Sickly Gazelle · {item:15826} Curative Animal Salve
	["{npc:12296}: use the {item:15826} on them; they roam the plains all around the Crossroads"] = "{npc:12296}: usa {item:15826} en ellas; recorren las llanuras alrededor del Cruce",
	-- {item:15826} Curative Animal Salve
	-- plural, as words: Sickly Gazelles = {npc:12296} Sickly Gazelle
	["Use the {item:15826} on Sickly Gazelles"] = "Usa {item:15826} sobre gacelas enfermizas",

	-- Step 121: Bristleback camps
	["Bristleback camps"] = "Campamentos Lomopelo",
	-- {area:378} Camp Taurajo · {area:458} Gold Road · {npc:3432} Mankrik · {npc:3430} Mangletooth · {quest:883} Lakota'mani
	-- was: ["The Bristleback quilboar camps spread over the plains north of {area:378}, either side of the {area:458}. {npc:3432}'s wife lies at their north edge, on your way south. Leave the quilboar for now: {npc:3430} in {area:378} wants the same camps cleared. {quest:883}, a grey kodo (level 22), sometimes wanders here: his hoof starts a quest. Leave him alone below level 21."] = "Los campamentos de jabaespines Erizapúas se extienden por las llanuras al norte de {area:378}, a ambos lados de {area:458}. La esposa de {npc:3432} yace en su borde norte, de camino al sur. Deja a los jabaespines por ahora: {npc:3430}, en {area:378}, quiere que se limpien esos mismos campamentos. {quest:883}, un kodo gris (nivel 22), a veces deambula por aquí: su pezuña inicia una misión. No te acerques a él por debajo del nivel 21."
	["The Bristleback quilboar camps spread over the plains north of {area:378}, either side of the {area:458}. {npc:3432}'s wife lies at their north edge, on your way south. Leave the quilboar for now: {npc:3430} in {area:378} wants the same camps cleared. {quest:883}, a grey kodo, sometimes wanders here: his hoof starts a quest."] = "Los campamentos de jabaespines Bristleback se extienden por las llanuras al norte de {area:378}, a ambos lados de {area:458}. La esposa de {npc:3432} yace en su borde norte, de camino al sur. Deja a los jabaespines por ahora: {npc:3430} en {area:378} quiere que despejes los mismos campamentos. {quest:883}, un kodo gris, a veces deambula por aquí: su pezuña inicia una misión.",

	-- Step 122: Camp Taurajo
	-- {area:458} Gold Road · {area:378} Camp Taurajo
	["Follow the {area:458} south to {area:378}."] = "Sigue {area:458} hacia el sur hasta {area:378}.",
	-- {npc:3430} Mangletooth
	["{npc:3430}, in the cage"] = "{npc:3430}, en la jaula",

	-- Step 123: Bramblescar: kill these as you meet them
	-- {area:1698} Bramblescar
	["{area:1698}: kill these as you meet them"] = "{area:1698}: mata a estos enemigos conforme los encuentres",
	-- {npc:3432} Mankrik · {npc:3430} Mangletooth · {item:5075} Blood Shard
	["Back north into the Bristleback camps. Any Bristleback can drop a tusk for {npc:3432}, so collect them while you kill these for {npc:3430}. Keep one {item:5075}."] = "De vuelta al norte, a los campamentos Lomopelo. Cualquier Lomopelo puede soltar un colmillo para {npc:3432}, así que júntalos mientras matas a estos para {npc:3430}. Guarda un {item:5075}.",

	-- Step 126: Fly to Crossroads
	-- {area:378} Camp Taurajo
	["{area:378} flight master"] = "Maestro de vuelo de {area:378}",

	-- Step 130: The Crossroads
	-- {area:458} Gold Road · {npc:3448} Tonga Runetotem · {npc:3432} Mankrik · {npc:3428} Korran · {item:5075} Blood Shard · {npc:3430} Mangletooth · {area:378} Camp Taurajo
	["North up the {area:458} to the Crossroads: {npc:3448} at the south gate, {npc:3432} by the inn, {npc:3428} west of the north gate. Keep the {item:5075}: {npc:3430} takes it on the next stop in {area:378}."] = "Sube al norte por {area:458} hasta el Cruce: {npc:3448} en la puerta sur, {npc:3432} junto a la posada y {npc:3428} al oeste de la puerta norte. Guarda {item:5075}: {npc:3430} lo recibe en la próxima parada en {area:378}.",
	-- {npc:3432} Mankrik · {quest:95774} Her Name Is Olgra · {quest:4921} Lost in Battle
	["{npc:3432} offers {quest:95774} once {quest:4921} is handed in"] = "{npc:3432} ofrece {quest:95774} cuando entregas {quest:4921}",
	-- {npc:3428} Korran · {quest:868} Egg Hunt · {area:17} The Barrens
	-- was: ["{npc:3428}'s {quest:868} waits for this guide's last Crossroads stop: its eggs come on the next {zone:1413} guide's walk south, at about 25."] = "{quest:868} de {npc:3428} espera a la última parada de esta guía en el Cruce: sus huevos están en el recorrido hacia el sur de la siguiente guía de {zone:1413}, hacia el nivel 25."
	["{npc:3428}'s {quest:868} waits for this guide's last Crossroads stop: its eggs come on the next {area:17} guide's walk south, at about 25."] = "{quest:868} de {npc:3428} espera a la última parada en el Cruce de esta guía: sus huevos llegan en el recorrido al sur de la próxima guía de {area:17}, hacia el nivel 25.",

	-- Step 132: To Valley of Honor
	-- {object:172958} Valley of Honor
	["To {object:172958}"] = "A {object:172958}",

	-- Step 133: Valley of Honor
	-- {quest:3923} Rilli Greasygob · {object:172958} Valley of Honor
	["{quest:3923} stands by the {object:172958}'s water, east of the Drag."] = "{quest:3923} está junto al agua de {object:172958}, al este de La Calada.",

	-- Step 134: Orgrimmar class quests
	-- {zone:1454} Orgrimmar
	["{zone:1454} class quests"] = "Misiones de clase en {zone:1454}",
	-- {npc:6018} Ur'kyo · {object:172961} Valley of Spirits
	["{npc:6018} stands in the {object:172961} on the city's west side."] = "{npc:6018} está en {object:172961}, en el lado oeste de la ciudad.",

	-- Step 135: Hanashi
	-- {npc:2704} Hanashi · {object:172958} Valley of Honor
	["While you're here: learn Staves from {npc:2704} ({object:172958}, 10 silver); a staff carries more spell stats than a one-hander while you level."] = "Ya que estás aquí: aprende Bastones con {npc:2704} ({object:172958}, 10 de plata); un bastón da más estadísticas de hechizo que un arma de una mano mientras subes de nivel.",

	-- Step 138: The Great Cat Spirit
	-- {area:1638} Thunder Bluff · {npc:3033} Turak Runetotem · {area:1639} Elder Rise · {spell:499} Cat Form · {spell:526} Cure Poison · {zone:1450} Moonglade · {npc:11798} Bunthen Plainswind · {area:392} Ratchet
	["Fly from the Crossroads to {area:1638} and train your level 20 ranks: {npc:3033} is on {area:1639}. {spell:499} and {spell:526} follow in {zone:1450} on the same trip, then {npc:11798} flies you back here and on to {area:392}."] = "Vuela del Cruce a {area:1638} y entrena tus rangos de nivel 20: {npc:3033} está en {area:1639}. {spell:499} y {spell:526} siguen en {zone:1450} en el mismo viaje; luego {npc:11798} te lleva de vuelta aquí y sigue hasta {area:392}.",

	-- Step 140: Moonglade
	-- {spell:18960} Teleport: Moonglade · {npc:11802} Dendrite Starblaze · {area:2361} Nighthaven
	["Cast {spell:18960}. {npc:11802} stands upstairs in his building in {area:2361}: go up inside, the arrow cannot tell the floors apart."] = "Lanza {spell:18960}. {npc:11802} está en el piso de arriba de su edificio, en {area:2361}: sube por dentro, la flecha no distingue los pisos.",

	-- Step 141: Moonglade
	-- {npc:11802} Dendrite Starblaze · {npc:3033} Turak Runetotem
	["{npc:11802}: the welcome from {npc:3033}"] = "{npc:11802}: la bienvenida de {npc:3033}",

	-- Step 143: Fly to Thunder Bluff
	-- {area:2361} Nighthaven
	["{area:2361} flight master"] = "Maestro de vuelo de {area:2361}",

	-- Step 145: Fly to Ratchet
	-- {area:1638} Thunder Bluff · {area:392} Ratchet
	["Fly from {area:1638} on to {area:392}."] = "Vuela de {area:1638} a {area:392}.",
	-- {area:1638} Thunder Bluff
	["{area:1638} flight master"] = "Maestro de vuelo de {area:1638}",

	-- Step 147: Fly to Ratchet
	-- {area:392} Ratchet · {npc:3310} Doras · {object:172982} Valley of Strength
	["Fly on to {area:392} from {npc:3310} on the tower in the {object:172982}."] = "Sigue en vuelo a {area:392} con {npc:3310}, en la torre de {object:172982}.",
	-- {area:1637} Orgrimmar
	["{area:1637} flight master"] = "Maestro de vuelo de {area:1637}",

	-- Step 149: Theramore Medal on the way
	-- {item:5078} Theramore Medal
	["{item:5078} on the way"] = "{item:5078} de camino",
	-- {item:5078} Theramore Medal · {area:392} Ratchet
	["{item:5078} along the way to {area:392}"] = "{item:5078} en el camino a {area:392}",

	-- Step 150: Northwatch Hold: kill these as you meet them
	-- {area:385} Northwatch Hold
	["{area:385}: kill these as you meet them"] = "{area:385}: mata a estos según te los encuentres",
	-- {area:385} Northwatch Hold · {npc:3393} Captain Fairmount
	-- plural, as words: Theramore Marines = {npc:3385} Theramore Marine
	["South along the beach past the pirate camp to {area:385}, on the coast. The Theramore Marines and Preservers (15-16) drop the medals; {npc:3393} (20) and the two cannoneers (19) stand in the keep and on its walls.\nCareful: Each named target is linked to a healer and guards, and Fairmount has three extra marines with her. Killing the healer first makes the fight easier."] = "Ve al sur por la playa, más allá del campamento pirata, hasta {area:385}, en la costa. Los Marinos y Protectores de Theramore (15-16) sueltan las medallas; {npc:3393} (20) y los dos artilleros (19) están en el bastión y en sus murallas.\nCuidado: cada objetivo con nombre está vinculado a un sanador y a guardias, y Justamonta tiene tres marinos más con ella. Matar primero al sanador facilita el combate.",
	["On the top floor"] = "En el piso superior",
	["Upstairs"] = "Arriba",

	-- Step 151: Free From the Hold
	-- {npc:3465} Gilthares Firebough · {area:392} Ratchet
	["{npc:3465} is chained inside the hold. Talk to him to start the escort and stay close: Theramore soldiers attack on the way out. He walks you back to {area:392}."] = "{npc:3465} está encadenado dentro del bastión. Habla con él para empezar la escolta y no te alejes: los soldados de Theramore atacan a la salida. Te acompaña de vuelta a {area:392}.",

	-- Step 162: Hezrul Bloodmark
	-- {npc:3396} Hezrul Bloodmark · {area:387} Lushwater Oasis · {npc:3389} Regthar Deathgate
	-- was: ["{npc:3396} leads the Kolkar on the west shore of {area:387}, south of {npc:3389}. He walks that shore, from about 46,36 in the north to 46,42 in the south: if he isn't at the arrow, follow the shore until you meet him. Hand his head to {npc:3389} on your last Crossroads stop. Oasis Snapjaws crawl in the oasis' water there: their shells are for {npc:3448}."] = "{npc:3396} dirige a los Kolkar en la orilla oeste de {area:387}, al sur de {npc:3389}. Recorre esa orilla, desde aproximadamente 46,36 en el norte hasta 46,42 en el sur: si no está donde marca la flecha, sigue la orilla hasta encontrarlo. Entrega su cabeza a {npc:3389} en tu última parada en el Cruce. Allí, los Quijafortes del oasis se arrastran por el agua del oasis: sus caparazones son para {npc:3448}."
	["{npc:3396} leads the Kolkar on the west shore of {area:387}, south of {npc:3389}. He walks that shore, from about 46,36 in the north to 46,42 in the south: if he isn't at the arrow, follow the shore until you meet him. Hand his head to {npc:3389} on your last Crossroads stop."] = "{npc:3396} dirige a los Kolkar en la orilla oeste de {area:387}, al sur de {npc:3389}. Camina por esa orilla, desde aproximadamente 46,36 en el norte hasta 46,42 en el sur: si no está en la flecha, sigue la orilla hasta encontrarlo. Entrega su cabeza a {npc:3389} en tu última parada en el Cruce.",

	-- Step 164: Camp Taurajo
	-- {area:458} Gold Road · {area:378} Camp Taurajo
	["Down the {area:458} to {area:378} again."] = "Baja otra vez por {area:458} hasta {area:378}.",

	-- Step 166: Olgra's Adornments
	-- {area:458} Gold Road · {area:378} Camp Taurajo · {item:277277} Olgra's Adornments · {npc:3432} Mankrik
	["On the way back down the {area:458} to {area:378}: the Razormane Raiders among the Bristleback camps, either side of the road north of the camp, carry {item:277277}. Hand them to {npc:3432} on your last Crossroads stop."] = "De regreso por {area:458} hacia {area:378}: los Asaltantes Crines de Acero entre los campamentos Lomopelo, a ambos lados del camino al norte del campamento, llevan {item:277277}. Entrégaselos a {npc:3432} en tu última parada en el Cruce.",

	-- Step 168: Camp Taurajo
	-- {npc:12696} Senani Thunderheart · {zone:1440} Ashenvale
	["Keep it: {npc:12696} in {zone:1440}, next guide"] = "Guárdala: {npc:12696} en {zone:1440}, en la siguiente guía",

	-- Step 171: To Grunt Dogran
	-- {npc:5908} Grunt Dogran
	["To {npc:5908}"] = "A {npc:5908}",

	-- Step 174: Enraged Thunder Lizards
	-- plural, as words: Thunder Lizards = {npc:3130} Thunder Lizard
	["Enraged Thunder Lizards"] = "Lagartos del trueno enfurecidos",
	-- {area:378} Camp Taurajo · {quest:884} Owatanka
	["Thunderheads graze on the plains just south of {area:378}. {quest:884}, a blue thunder lizard (level 24), roams among them: his Tailspike starts a quest. Leave him alone below level 23."] = "Los Tronatestas pastan en las llanuras justo al sur de {area:378}. {quest:884}, un lagarto del trueno azul (nivel 24), deambula entre ellos: su Punta de cola inicia una misión. No te acerques a él por debajo del nivel 23.",

	-- Step 175: Jorn Skyseer
	-- {area:390} Field of Giants · {npc:6394} Ruga Ragetotem
	-- plural, as words: Silithid Mounds = {object:3685} Silithid Mound
	-- was: ["Warriors: take {quest:1824} from {npc:6394} now: it runs for 30 minutes from the accept. The antennae come first, at the Silithid Mounds south of the camp, then straight back to {npc:6394}; the thunderhawks after."] = "Guerreros: acepta ahora {quest:1824} de {npc:6394}: dura 30 minutos desde que la aceptas. Primero las antenas, en los Montículos de silítidos al sur del campamento, y luego directo de vuelta con {npc:6394}; los halcones del trueno, después."
	["Warriors: take Trial at the {area:390} from {npc:6394} now: it runs for 30 minutes from the accept. The antennae come first, at the Silithid Mounds south of the camp, then straight back to Ruga; the thunderhawks after."] = "Guerreros: acepta Trial en {area:390} con {npc:6394} ahora: dura 30 minutos desde que la aceptas. Primero van las antenas, en los Silithid Mounds al sur del campamento, y luego regresa directo con Ruga; los thunderhawks después.",

	-- Step 177: To Brine
	["To Brine"] = "A Brine",

	-- Step 179: The Crossroads
	-- {area:458} Gold Road · {npc:3448} Tonga Runetotem · {npc:3432} Mankrik · {npc:3428} Korran
	["North up the {area:458} to the Crossroads: {npc:3448} at the south gate, {npc:3432} by the inn, {npc:3428} west of the north gate."] = "Sube al norte por {area:458} hasta el Cruce: {npc:3448} en la puerta sur, {npc:3432} junto a la posada y {npc:3428} al oeste de la puerta norte.",
	-- {npc:3428} Korran · {quest:868} Egg Hunt · {area:17} The Barrens · {area:378} Camp Taurajo
	-- was: ["{npc:3428}, west of the north gate: keep {quest:868}, its eggs lie on the next {zone:1413} guide's walk south from {area:378}, at about 25"] = "{npc:3428}, al oeste de la puerta norte: guarda {quest:868}, sus huevos están en el recorrido hacia el sur desde {area:378} de la siguiente guía de {zone:1413}, hacia el nivel 25"
	["{npc:3428}, west of the north gate: keep {quest:868}, its eggs lie on the next {area:17} guide's walk south from {area:378}, at about 25"] = "{npc:3428}, al oeste de la puerta norte: conserva {quest:868}, sus huevos están en el recorrido hacia el sur desde {area:378} de la siguiente guía de {area:17}, alrededor del nivel 25",

	-- Step 180: To Thun'grim Firegaze
	-- {quest:1502} Thun'grim Firegaze
	["To {quest:1502}"] = "Ve por {quest:1502}",

	-- Step 181: Thun'grim Firegaze
	-- {npc:5878} Thun'grim Firegaze
	["{npc:5878} camps beside the road east of the Crossroads."] = "{npc:5878} acampa junto al camino al este del Cruce.",
	-- {area:1717} Razorfen Kraul
	-- was: ["He offers {quest:1838} next (1838, level 30): it needs {area:1717} and sends you all over Kalimdor and the Eastern Kingdoms. The Warrior class guide {quest:1838} covers it."] = "Después ofrece {quest:1838} (1838, nivel 30): requiere {area:1717} y te envía por todo Kalimdor y los Reinos del Este. La guía de clase de guerrero {quest:1838} la cubre."
	["He offers Brutal Armor next (1838, level 30): it needs {area:1717} and sends you all over Kalimdor and the Eastern Kingdoms. The Warrior class guide Brutal Armor covers it."] = "Después ofrece Brutal Armor (1838, nivel 30): requiere {area:1717} y te envía por todo Kalimdor y los Reinos del Este. La guía de clase de Guerrero Brutal Armor la cubre.",

	-- Step 183: Counterattack!
	-- {npc:3389} Regthar Deathgate · {npc:9456} Warlord Krom'zar
	["Speak to {npc:3389} again to start the attack: the Kolkar charge the bunkers just west of him in waves. Fight beside the grunts until {npc:9456} (elite, 20) arrives with two bodyguards, usually from the south, then click the banner over his body."] = "Habla otra vez con {npc:3389} para iniciar el ataque: los Kolkar cargan contra los búnkeres justo al oeste de él en oleadas. Pelea junto a los gruñones hasta que llegue {npc:9456} (élite, 20) con dos guardaespaldas, normalmente desde el sur, y luego haz clic en el estandarte sobre su cuerpo.",

	-- Step 184: Seereth Stonebreak's camp
	-- {npc:4049} Seereth Stonebreak
	["{npc:4049}'s camp"] = "Campamento de {npc:4049}",

	-- Step 186: Seereth Stonebreak
	-- {npc:4049} Seereth Stonebreak · {npc:11857} Makaba Flathoof
	["{npc:4049} and {npc:11857} share the camp on the road west to Stonetalon."] = "{npc:4049} y {npc:11857} comparten el campamento en el camino al oeste hacia Sierra Espolón.",
	-- {npc:4049} Seereth Stonebreak · {area:461} Windshear Crag
	["{npc:4049}: the Venture loggers at {area:461}"] = "{npc:4049}: los leñadores de Ventura y Cía. en {area:461}",

	-- Step 187: Grimtotem camp
	["Grimtotem camp"] = "Dominios Tótem Siniestro",
	-- {npc:11857} Makaba Flathoof
	["The Grimtotem camp is just north of {npc:11857}, a short walk off the road: Ruffians and Mercenaries stand among the tents."] = "El campamento Tótem Siniestro está justo al norte de {npc:11857}, a poca distancia del camino: los rufianes y mercenarios están entre las tiendas.",

	-- Step 188: Makaba Flathoof
	-- {npc:11857} Makaba Flathoof
	["Back down to {npc:11857}."] = "De vuelta abajo, con {npc:11857}.",
	-- {npc:11858} Grundig Darkcloud · {area:1076} Webwinder Path
	["{npc:11858} waits up the {area:1076}"] = "{npc:11858} espera subiendo por {area:1076}",

	-- Step 189: To Malaka'jin
	-- {area:2539} Malaka'jin
	["To {area:2539}"] = "Hacia {area:2539}",

	-- Step 190: Malaka'jin
	-- {npc:4049} Seereth Stonebreak · {area:2539} Malaka'jin
	["Follow the road on west from {npc:4049} into Stonetalon. The troll village of {area:2539} sits at the entrance of the canyon."] = "Sigue el camino al oeste desde {npc:4049} hacia Sierra Espolón. La aldea trol de {area:2539} está en la entrada del cañón.",
	-- {npc:12816} Xen'Zilla · {area:1076} Webwinder Path
	["{npc:12816}: the spiders along the {area:1076}"] = "{npc:12816}: las arañas a lo largo de {area:1076}",

	-- Step 191: Grimtotem Post: kill these as you meet them
	-- {area:2537} Grimtotem Post
	["{area:2537}: kill these as you meet them"] = "{area:2537}: mata a estos cuando te los encuentres",
	-- {area:2539} Malaka'jin · {npc:11858} Grundig Darkcloud
	-- plural, as words: Grimtotem Brutes = {npc:11912} Grimtotem Brute · Deepmoss Creepers = {npc:4005} Deepmoss Creeper
	["North up the road from {area:2539}: {npc:11858} and his Grimtotem Brutes hold the bend in the road, and the Deepmoss Creepers and Venomspitters lurk in the webs on both sides of the path all the way up."] = "Al norte por el camino desde {area:2539}: {npc:11858} y sus brutos Tótem Siniestro ocupan la curva del camino, y los reptadores y escupevenenos Musgondo acechan en las telarañas a ambos lados del sendero hasta arriba.",

	-- Step 192: Sun Rock Retreat flight master
	-- {area:460} Sun Rock Retreat
	["{area:460} flight master"] = "Maestro de vuelo de {area:460}",

	-- Step 193: To Windshear Crag
	-- {area:461} Windshear Crag
	["To {area:461}"] = "Hacia {area:461}",

	-- Step 194: Ziz Fizziks
	-- {area:1076} Webwinder Path · {quest:1483} Ziz Fizziks · {area:461} Windshear Crag
	["The road climbs north as the {area:1076}. {quest:1483} has a hut where the road forks east to {area:461}."] = "El camino sube al norte como {area:1076}. {quest:1483} tiene una choza donde el camino se bifurca al este hacia {area:461}.",
	-- {quest:1483} Ziz Fizziks
	["{quest:1483}, inside"] = "{quest:1483}, dentro",

	-- Step 195: Windshear Crag: kill these as you meet them
	-- {area:461} Windshear Crag
	["{area:461}: kill these as you meet them"] = "{area:461}: mata a estos según te los encuentres",
	-- {area:461} Windshear Crag
	["East of Ziz, the Venture Company is clear-cutting {area:461}; one of the Operators carries the blueprints."] = "Al este de Ziz, Ventura y Cía. está talando {area:461}; uno de los operarios lleva los planos.",
	-- plural, as words: Venture Co. Loggers = {npc:3989} Venture Co. Logger
	["Venture Co. Loggers, all over the clear-cut"] = "Leñadores de Ventura y Cía., por toda la zona talada",

	-- Step 196: Piznik
	-- {npc:4276} Piznik · {area:2160} Windshear Mine
	["{npc:4276}'s defence is hard alone at this level: grouping up is encouraged, look for people to do it with. Skip it if you are alone. {npc:4276} mines at the bottom of the {area:2160}, past its kobolds (levels 19-23). Talk to him, then keep him alive for five minutes while he mines: a dozen or more kobolds come at him in waves, melee fighters first, then casters, and the mine's own kobolds respawn into the fight. If he dies, the quest fails."] = "La defensa de {npc:4276} es difícil sin ayuda a este nivel: se recomienda agruparse, busca gente para hacerlo juntos. Omítela si no tienes grupo. {npc:4276} mina en el fondo de {area:2160}, más allá de sus kobolds (niveles 19-23). Habla con él y mantenlo vivo cinco minutos mientras mina: una docena o más de kobolds lo atacan en oleadas, primero los de combate cuerpo a cuerpo, luego los lanzadores de hechizos, y los kobolds propios de la mina reaparecen en la pelea. Si él muere, la misión falla.",
	-- {npc:4276} Piznik
	["{npc:4276}, below ground"] = "{npc:4276}, bajo tierra",

	-- Step 197: Ziz Fizziks
	-- {npc:4201} Ziz Fizziks
	["{npc:4201}, inside"] = "{npc:4201}, dentro",
	-- {npc:4201} Ziz Fizziks · {npc:3442} Sputtervalve · {area:392} Ratchet · {area:17} The Barrens
	-- was: ["{npc:4201}: for {npc:3442}, beside {area:392}'s flight master at the end of the {zone:1413} & Stonetalon guide"] = "{npc:4201}: para {npc:3442}, junto al maestro de vuelo de {area:392}, al final de la guía de {zone:1413} y Sierra Espolón"
	["{npc:4201}: for {npc:3442}, beside {area:392}'s flight master at the end of the {area:17} & Stonetalon guide"] = "{npc:4201}: para {npc:3442}, junto al maestro de vuelo de {area:392}, al final de la guía de {area:17} y Stonetalon",

	-- Step 198: Kaya Flathoof
	-- {area:1076} Webwinder Path · {npc:11856} Kaya Flathoof · {npc:11858} Grundig Darkcloud · {area:2538} Camp Aparaje
	["On the way back down the {area:1076}, {npc:11856} is held in {npc:11858}'s hut at the bend in the road. Once you take her quest she walks straight off south-east to {area:2538}, the burned village, without waiting: stay close, or the quest fails.\nCareful: Three Grimtotems ambush her at the burned village and go for her, not you: pull them off her and kill their caster quickly."] = "Al volver a bajar por {area:1076}, {npc:11856} está retenida en la choza de {npc:11858}, en la curva del camino. En cuanto aceptas su misión, se va directa al sureste hacia {area:2538}, la aldea quemada, sin esperarte: no te alejes o la misión fallará.\nCuidado: tres Tótem Siniestro le tienden una emboscada en la aldea quemada y van a por ella, no a por ti: apártalos de ella y mata rápido a su lanzador de hechizos.",
	-- {npc:11856} Kaya Flathoof · {npc:11858} Grundig Darkcloud
	["{npc:11856}, inside {npc:11858}'s hut"] = "{npc:11856}, dentro de la choza de {npc:11858}",

	-- Step 199: Malaka'jin
	-- {area:2539} Malaka'jin · {npc:12816} Xen'Zilla
	["West from the burned village to {area:2539}: {npc:12816} stands just outside it, before the village."] = "Ve al oeste desde la aldea quemada hasta {area:2539}: {npc:12816} está justo a las afueras, antes de la aldea.",

	-- Step 201: To Seereth Stonebreak
	-- {npc:4049} Seereth Stonebreak
	["To {npc:4049}"] = "Ve por {npc:4049}",

	-- Step 202: Seereth Stonebreak
	-- {npc:4049} Seereth Stonebreak · {npc:11857} Makaba Flathoof
	["East along the road to {npc:4049} and {npc:11857}'s camp, on the way back out of Stonetalon."] = "Al este por el camino hasta el campamento de {npc:4049} y {npc:11857}, de salida de Sierra Espolón.",
	-- {npc:11857} Makaba Flathoof · {npc:11864} Tammra Windfield · {area:460} Sun Rock Retreat · {area:17} The Barrens
	-- was: ["{npc:11857}: keep it, {npc:11864} at {area:460} in the {zone:1413} & Stonetalon guide"] = "{npc:11857}: guárdala, {npc:11864} en {area:460}, en la guía de {zone:1413} y Sierra Espolón"
	["{npc:11857}: keep it, {npc:11864} at {area:460} in the {area:17} & Stonetalon guide"] = "{npc:11857}: guárdala, {npc:11864} en {area:460}, en la guía de {area:17} y Sierra Espolón",
	-- {area:17} The Barrens · {area:1703} Mor'shan Rampart · {zone:1440} Ashenvale
	["The next guide goes north-east across the {area:17} to the {area:1703} and {zone:1440}."] = "La siguiente guía va al noreste a través de {area:17} hasta {area:1703} y {zone:1440}.",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["Assist {npc:261366}: stay by him when {npc:261367} and the {area:21} marines come up the ridge"] = "Ayuda a {npc:261366}: quédate a su lado cuando {npc:261367} y los marinos de {area:21} suban la cresta",
	-- ["At the {area:2362}"] = "En el {area:2362}",
	-- ["Back north into {area:378} before the antennae fade: {npc:6394} is inside."] = "Vuelve al norte a {area:378} antes de que las antenas desaparezcan: {npc:6394} está dentro.",
	-- ["Back out of the caverns and up to the cave above the entrance."] = "Sal de las cavernas y sube a la cueva que hay encima de la entrada.",
	-- ["Back to the Razormane camp. Geomancers and Defenders hold its eastern half; {npc:3438} walks among them."] = "Vuelve al campamento Crines de Acero. Los geomantes y los defensores ocupan su mitad este; {npc:3438} camina entre ellos.",
	-- ["Back to the Razormane camp. Geomancers and Defenders hold its eastern half; {npc:3438} walks among them. Careful: Razormane Flesheaters and Berserkers (18-19) are elites in the camp's north-east, near {npc:3438} and the supply crates, and {npc:267307} (20, elite) lies in the cave under {area:1699} beside them: pull {npc:3438} and the quilboar away from them one at a time, and leave the cave alone unless you are in a group."] = "Vuelve al campamento Crines de Acero. Los geomantes y los defensores ocupan su mitad este; {npc:3438} camina entre ellos. Cuidado: los Comecarnes y Rabiosos Crines de Acero (18-19) son élites en el noreste del campamento, cerca de {npc:3438} y de las cajas de suministros, y {npc:267307} (20, élite) está en la cueva bajo {area:1699}, junto a ellos: atrae a {npc:3438} y a los jabaespines lejos de ellos de uno en uno, y deja la cueva en paz salvo que vayas en grupo.",
	-- ["Back west along the road."] = "Vuelve al oeste por el camino.",
	-- ["Bristleback Geomancers"] = "Geománticas Erizapúas",
	-- ["Burning Blade Cultists hold {area:1898} in northern {area:14}; they drop the {item:6652}. The {item:5026} comes from the Razormane on your next visit to their camp."] = "Los Fanáticos Filo Ardiente ocupan {area:1898}, en el norte de {area:14}; sueltan {item:6652}. {item:5026} lo sueltan los Crines de Acero en tu próxima visita a su campamento.",
	-- ["Burning Blade Cultists hold {area:1898} in northern {zone:1411}; they drop the {item:6652}. The {item:5026} comes from the Razormane on your next visit to their camp."] = "Los Fanáticos Filo Ardiente ocupan {area:1898}, en el norte de {zone:1411}; sueltan {item:6652}. {item:5026} lo sueltan los Crines de Acero en tu próxima visita a su campamento.",
	-- ["Dogran is chained up in the quilboar camp west of the road."] = "Dogran está encadenado en el campamento de jabaespines al oeste del camino.",
	-- ["East from {npc:261366} toward the {area:382}: {npc:9316} stands at the camp on the road north of the Crossroads."] = "Ve al este desde {npc:261366} hacia {area:382}: {npc:9316} está en el campamento del camino al norte del Cruce.",
	-- ["East to the beach, at the south end of the pirate camp: the crate of boots and the fragile crate with the lens sit there, a short walk north of {area:385}."] = "Ve al este, a la playa, al extremo sur del campamento pirata: la caja de botas y la caja frágil con la lente están allí, a poca distancia al norte de {area:385}.",
	-- ["East to {area:392}, on the coast."] = "Ve al este, a {area:392}, en la costa.",
	-- ["Fill the {item:7766} at the quilboar watering hole"] = "Llena {item:7766} en el abrevadero de los jabaespines",
	-- ["Fly from the Crossroads to {area:1638}. {quest:853} waits in the {area:2197}, the cave under {area:1640}: hand in the spores there first, while their time runs. Then {npc:3033} trains you on {area:1639}."] = "Vuela del Cruce a {area:1638}. {quest:853} espera en {area:2197}, la cueva bajo {area:1640}: entrega allí primero las esporas, mientras corre su tiempo. Después, {npc:3033} te entrena en {area:1639}.",
	-- ["Fly from {zone:1456} straight on to {area:392}."] = "Vuela desde {zone:1456} directamente a {area:392}.",
	-- ["Fly to {area:1637}"] = "Vuela a {area:1637}",
	-- ["Follow the road east to the outpost above the {area:814}."] = "Sigue el camino al este hasta el puesto sobre {area:814}.",
	-- ["Follow the road south-east to {area:392} on the coast."] = "Sigue el camino al sureste hasta {area:392}, en la costa.",
	-- ["Follow the road south-east to {area:392} on the coast: {npc:3391} and {npc:7161} at the north end of town, {npc:3442} and {npc:16227}, {npc:3446} and the {object:3972} poster, then {quest:1492} on the dock on the way out south."] = "Sigue el camino al sureste hasta {area:392}, en la costa: {npc:3391} y {npc:7161} en el extremo norte del pueblo, {npc:3442} y {npc:16227}, {npc:3446} y el cartel de {object:3972}, y luego {quest:1492} en el muelle al salir hacia el sur.",
	-- ["For your {area:718} run: {npc:3446}'s next errand, {quest:1491}."] = "Para tu incursión en {area:718}: el siguiente encargo de {npc:3446}, {quest:1491}.",
	-- ["For your {area:718} run: {npc:5767} and {npc:5768} stand in a hidden cave in the rocks above the entrance, at the north end of the oasis' west shore: climb up from the west side. Follow the arrow up."] = "Para tu incursión en {area:718}: {npc:5767} y {npc:5768} están en una cueva oculta entre las rocas encima de la entrada, en el extremo norte de la orilla oeste del oasis: sube por el lado oeste. Sigue la flecha hacia arriba.",
	-- ["He offers {quest:1838} next (1838, level 30): it needs {area:1717} and sends you all over Kalimdor and the Eastern Kingdoms. The Warrior class guide {quest:1838} covers it."] = "Después ofrece {quest:1838} (1838, nivel 30): requiere {area:1717} y te envía por todo Kalimdor y los Reinos del Este. La guía de clase de guerrero {quest:1838} la cubre.",
	-- ["In from the north gate: {npc:3464} first, {npc:3338} by the inn, then up to {npc:3449} and {npc:3429} on the tower platform, where the flight master stands."] = "Entra por la puerta norte: primero {npc:3464}, {npc:3338} junto a la posada y luego sube hasta {npc:3449} y {npc:3429} en la plataforma de la torre, donde está el maestro de vuelo.",
	-- ["In the camp, Water Seekers and Thornweavers hold the western half, Hunters the middle; the supply crates sit at its eastern end.\nPlainstriders here count toward the beaks.\nCareful: Razormane Flesheaters and Berserkers (18-19) are elites; they stand in the camp's north-east, beside the supply crates: pull the quilboar away from them one at a time."] = "En el campamento, los Buscaqua y Tejespinas ocupan la mitad oeste, y los Cazadores, el centro; las cajas de suministros están en su extremo este.\nLos Zancudos de llanura de aquí cuentan para los picos.\nCuidado: los Comecarnes y Rabiosos Crines de Acero (18-19) son élites; están en el noreste del campamento, junto a las cajas de suministros: atrae a los jabaespines lejos de ellos de uno en uno.",
	-- ["Keep it: {quest:3923} stands outside {zone:1454}; a later guide hands it in"] = "Guárdalo: {quest:3923} está fuera de {zone:1454}; una guía posterior lo entrega",
	-- ["Kolkar Wranglers and Stormers hold the camps south of {npc:3389}."] = "Los Vaqueros Kolkar y los clamatormentas ocupan los campamentos al sur de {npc:3389}.",
	-- ["Leave {zone:1454} by the main gate and follow the road south through {zone:1411}, then west over the {area:814} bridge: {npc:5810} stands at {area:379} just above it, on the road to the Crossroads."] = "Sal de {zone:1454} por la puerta principal y sigue el camino al sur por {zone:1411}; luego al oeste por el puente de {area:814}: {npc:5810} está en {area:379}, justo encima, en el camino al Cruce.",
	-- ["Level 20"] = "Nivel 20",
	-- ["North to the {area:383}. {npc:3682} camps below the hills; {npc:261366}, the hermit on the ridge behind him, has work for you only once {npc:3682} sends you up."] = "Al norte, a {area:383}. {npc:3682} acampa al pie de las colinas; {npc:261366}, el ermitaño de la cresta que hay detrás, solo tiene trabajo para ti cuando {npc:3682} te envía arriba.",
	-- ["Oasis Snapjaws crawl around {area:387}, south-west of the {area:380}, and around the {area:388}."] = "Los Quijafortes del oasis se arrastran por {area:387}, al suroeste de {area:380}, y por {area:388}.",
	-- ["Over the {area:814} bridge below {area:379} and south along the {zone:1411} bank to where a narrow trail climbs the mountain: {npc:5900} keeps the shrine at the top. Mind the edges on the way up, and come back down the same trail."] = "Cruza el puente de {area:814} bajo {area:379} y ve al sur por la orilla de {zone:1411} hasta donde un sendero estrecho sube la montaña: {npc:5900} cuida el santuario de la cima. Cuidado con los bordes al subir, y baja por el mismo sendero.",
	-- ["Plainstriders and Sunscale raptors roam the plains all around the {area:380}, thickest to the north."] = "Los zancudos y los raptores solescama recorren las llanuras alrededor de {area:380}, sobre todo al norte.",
	-- ["Plainstriders and raptors"] = "Zancudos y raptores",
	-- ["Raptor nests"] = "Nidos de raptores",
	-- ["South-east of the Crossroads. Test the seeds at the bubbling fissure on the oasis' east bank; {npc:3448} takes the result on the next Crossroads stop, so carry on north-west to the {area:383} from here."] = "Al sureste del Cruce. Prueba las semillas en la fisura burbujeante de la orilla este del oasis; {npc:3448} recibe el resultado en la próxima parada en el Cruce, así que desde aquí sigue al noroeste hacia {area:383}.",
	-- ["South-east of the {area:380}. Test the seeds at the bubbling fissure on the oasis' east bank."] = "Al sureste de {area:380}. Prueba las semillas en la fisura burbujeante de la orilla este del oasis.",
	-- ["South-west from {area:392} across the plains to the {area:1697}: the three nests sit together south-west of the oasis, and Sunscale Scytheclaws guard them. Each nest needs a {item:5165}: kill Sunscale raptors (most drop one) until you have three, then use a feather at each nest."] = "Ve al suroeste desde {area:392}, cruzando las llanuras, hasta {area:1697}: los tres nidos están juntos al suroeste del oasis y los Segadores solescama los vigilan. Cada nido necesita una {item:5165}: mata raptores solescama (la mayoría suelta una) hasta tener tres y luego usa una pluma en cada nido.",
	-- ["Southsea beach"] = "Playa del Mar del Sur",
	-- ["Tauren: the {npc:11957} waits on the southern hill above the bridge. Skyborne: the {npc:272054} stands south of the twin bridges. Then the dens east of the lake: leave your form, click the statue at the entrance for five minutes of stealth, keep clear of the spirits inside and take one of each relic; the {item:280680} lies at the foot of the white cat statue. Careful: the spirits are Territorial Terrans (level 60) that kill whoever they see: stay off their paths, and click the statue again before the stealth runs out."] = "Tauren: {npc:11957} espera en la colina sur, sobre el puente. Cielonato: {npc:272054} está al sur de los puentes gemelos. Después, las guaridas al este del lago: sal de tu forma, pulsa la estatua de la entrada para tener cinco minutos de sigilo, evita a los espíritus del interior y coge una reliquia de cada; {item:280680} está al pie de la estatua del gato blanco. Cuidado: los espíritus son Terranos territoriales (nivel 60) que matan a quien ven: no te cruces en sus rutas y pulsa la estatua otra vez antes de que se acabe el sigilo.",
	-- ["The Bristleback quilboar camps spread over the plains north of {area:378}, either side of the {area:458}. {npc:3432}'s wife lies at their north edge, on your way south. Leave the quilboar for now: {npc:3430} in {area:378} wants the same camps cleared. {quest:883}, a grey kodo (level 22), sometimes wanders here: his hoof starts a quest. Leave him alone below level 21."] = "Los campamentos de jabaespines Erizapúas se extienden por las llanuras al norte de {area:378}, a ambos lados de {area:458}. La esposa de {npc:3432} yace en su borde norte, de camino al sur. Deja a los jabaespines por ahora: {npc:3430}, en {area:378}, quiere que se limpien esos mismos campamentos. {quest:883}, un kodo gris (nivel 22), a veces deambula por aquí: su pezuña inicia una misión. No te acerques a él por debajo del nivel 21.",
	-- ["The Savannah Prowlers hunt the plains between town and the Razormane camp to the east. In the camp, Water Seekers and Thornweavers hold the western half, Hunters the middle; the supply crates sit at its eastern end."] = "Los Merodeadores de la savana cazan en las llanuras entre el pueblo y el campamento Crines de Acero, al este. En el campamento, los buscadores de agua y los tejespinas ocupan la mitad oeste y los cazadores el centro; las cajas de suministros están en el extremo este.",
	-- ["The Witchwing Slayers hold the western {area:383}; they wear the rings."] = "Los Destripadores Alabruja ocupan el oeste de {area:383}; llevan los anillos.",
	-- ["The antennae vanish fifteen minutes after they drop: kill the Silithid Swarmers and Creepers at the Silithid Mounds in the {area:390}, south of {area:378}, until you have five, then take them straight to {npc:6394} in {area:378}, before the thunderhawks. Careful: Silithid Swarmers (level 21-22) cast {npc:4196} both in and out of combat, which brings several small adds; Silithid Creepers (level 20-21) periodically cast {npc:5781} in combat, which spawns extra adds. A {npc:3253} (24, rare) also wanders the mounds: leave it."] = "Las antenas desaparecen quince minutos después de caer: mata a los Enjambristas y Trepadores silítidos de los Montículos de silítidos en {area:390}, al sur de {area:378}, hasta tener cinco y llévalas directamente a {npc:6394} en {area:378}, antes de los halcones del trueno. Cuidado: los Enjambristas silítidos (nivel 21-22) lanzan {npc:4196} dentro y fuera de combate, lo que trae varios enemigos pequeños; los Trepadores silítidos (nivel 20-21) lanzan de vez en cuando {npc:5781} en combate, lo que hace aparecer más enemigos. Un {npc:3253} (24, raro) también ronda los montículos: déjalo.",
	-- ["The antennae vanish fifteen minutes after they drop: kill the Silithid Swarmers and Creepers at the same mounds until you have five, then take them straight to {npc:6394} in {area:378}, before the thunderhawks. Careful: Silithid Swarmers (level 21-22) cast {npc:4196} both in and out of combat, which brings several small adds; Silithid Creepers (level 20-21) periodically cast {npc:5781} in combat, which spawns extra adds. A {npc:3253} (24, rare) also wanders the mounds: leave it."] = "Las antenas desaparecen quince minutos después de caer: mata a los Enjambradores y Trepadores silítidos de los mismos montículos hasta tener cinco y llévalas directamente a {npc:6394} en {area:378}, antes de los halcones del trueno. Cuidado: los Enjambradores silítidos (nivel 21-22) lanzan {npc:4196} dentro y fuera de combate, lo que trae varios enemigos pequeños; los Trepadores silítidos (nivel 20-21) lanzan de vez en cuando {npc:5781} en combate, lo que hace aparecer más enemigos. Un {npc:3253} (24, raro) también ronda los montículos: déjalo.",
	-- ["The pirates camp on the beach south of {area:392}: the piles of complicated parts lie in the sand among them, and {npc:3467} stands at the camp's southern end."] = "Los piratas acampan en la playa al sur de {area:392}: los montones de piezas complicadas están en la arena entre ellos, y {npc:3467} está en el extremo sur del campamento.",
	-- ["The three nests sit together in the {area:1697} south-west of the oasis; Sunscale Scytheclaws guard them."] = "Los tres nidos están juntos en {area:1697}, al suroeste del oasis; los Segadores solescama los vigilan.",
	-- ["The tool buckets with the slugs lie around the Venture Co. drill site in the {area:382}."] = "Los cubos de herramientas con las babosas están alrededor de la perforadora de Ventura y Cía. en {area:382}.",
	-- ["The {area:383}"] = "{area:383}",
	-- ["The {object:172960} is the canyon under the {object:172982}."] = "{object:172960} es el cañón bajo {object:172982}.",
	-- ["These are elite mobs: grouping up is encouraged, look for people to do it with. {npc:209797} (level 20 elite) needs a group of 2. Skip it if you are alone."] = "Son enemigos élite: se recomienda agruparse, busca gente con quien hacerlo. {npc:209797} (élite de nivel 20) requiere un grupo de 2. Sáltalo si vas solo.",
	-- ["These are elite mobs: grouping up is encouraged, look for people to do it with. {npc:267307} (level 20 elite) needs a group of 3 and sits deep in the cave under {area:1699}, past the Razormane Flesheaters and Berserkers (18-19, elite). Skip it if you are alone."] = "Son enemigos élite: se recomienda ir en grupo, busca gente con quien hacerlo. {npc:267307} (élite de nivel 20) requiere un grupo de 3 y está al fondo de la cueva bajo {area:1699}, más allá de los Comecarnes y Rabiosos Crines de Acero (18-19, élite). Sáltalo si vas solo.",
	-- ["Thun'grim camps beside the road from the {area:380} to {area:392}. The {object:58369} sits in the south of the Razormane camp just north of him."] = "Thun'grim acampa junto al camino de {area:380} a {area:392}. {object:58369} está en el sur del campamento Crines de Acero, justo al norte de él.",
	-- ["Thunder Lizards and Lightning Hides graze just across the bridge below {area:379}."] = "Los Truenagartos y los Lomorrayos pastan justo al otro lado del puente, bajo {area:379}.",
	-- ["Thunder Lizards and Lightning Hides graze just across the bridge below {area:379}.\nCareful: Halikor, a level 12 elite, roams {area:369} among the lizards: watch for him before you pull."] = "Los Truenagartos y los Lomorrayos pastan justo al otro lado del puente, bajo {area:379}.\nCuidado: Halikor, un élite de nivel 12, recorre {area:369} entre los lagartos: localízalo antes de atraer.",
	-- ["Thunder lizards across the river"] = "Truenagartos al otro lado del río",
	-- ["Thunderhawk Cloudscrapers circle over the plains south of the camp."] = "Los Desechanubes Truenalcón vuelan en círculos sobre las llanuras al sur del campamento.",
	-- ["Thunderheads graze on the plains just south of {area:378}. {quest:884}, a blue thunder lizard, roams among them: his Tailspike starts a quest."] = "Los Truenabezas pastan en las llanuras justo al sur de {area:378}. {quest:884}, un lagarto del trueno azul, deambula entre ellos: su Punta de cola de Owatanka inicia una misión.",
	-- ["Twitching Antennae"] = "Antenas temblorosas",
	-- ["Twitching Antennae from the silithid"] = "Antenas retorcidas de los silítidos",
	-- ["Underwater"] = "Bajo el agua",
	-- ["Walk back south to the {area:380}. The next guide starts here and takes you to {zone:1454} and the zeppelin to {zone:1420}."] = "Vuelve al sur hasta {area:380}. La próxima guía empieza aquí y te lleva a {zone:1454} y al zepelín a {zone:1420}.",
	-- ["Walk back west along the road to the {area:380}."] = "Vuelve al oeste por el camino hasta {area:380}.",
	-- ["Warriors: take {quest:1824} from {npc:6394} now: it runs for 30 minutes from the accept. The antennae come first, at the Silithid Mounds south of the camp, then straight back to {npc:6394}; the thunderhawks after."] = "Guerreros: acepta ahora {quest:1824} de {npc:6394}: dura 30 minutos desde que la aceptas. Primero las antenas, en los Montículos de silítidos al sur del campamento, y luego directo de vuelta con {npc:6394}; los halcones del trueno, después.",
	-- ["Warriors: take {quest:1824} from {npc:6394} now: it runs for 30 minutes from the accept. The eggs and the antennae come first, at the same mounds, then straight back to {npc:6394}; the thunderhawks after."] = "Guerreros: acepta ahora {quest:1824} de {npc:6394}: dura 30 minutos desde que la aceptas. Primero los huevos y las antenas, en los mismos montículos, y luego directo de vuelta con {npc:6394}; los halcones del trueno, después.",
	-- ["West to the {area:383}. Any Witchwing harpy drops a talon: keep to the eastern slopes, where the Witchwing Harpies and Roguefeathers (14-15) nest; the Slayers and Windcallers (16-17) hold the western hills. Savannah Prowlers hunt the plains between {npc:3389} and the hills: take their claws on the way.\nCareful: There are 2 Witchwing Ambushers (level 17-18). They stay stealthed with Sneak while out of combat."] = "Ve al oeste hasta {area:383}. Cualquier arpía Alabruja suelta una garra: quédate en las laderas del este, donde anidan las Arpías Alabruja y las Plumapícaras (14-15); las Asesinas y Clamavientos (16-17) ocupan las colinas del oeste. Los Merodeadores de la savana cazan en las llanuras entre {npc:3389} y las colinas: consigue sus garras por el camino.\nCuidado: hay 2 Emboscadores Alabruja (nivel 17-18). Permanecen en sigilo fuera de combate.",
	-- ["West to the {area:383}. The Witchwing harpies nest all over them; any of them can drop a talon. {quest:819} lies in their hills."] = "Ve al oeste, a {area:383}. Las arpías Alabruja anidan por todas partes; cualquiera puede soltar una garra. {quest:819} está en sus colinas.",
	-- ["While you are in the camp: {npc:3429}'s Water Seekers and Thornweavers in its western half, the Hunters in the middle, the supply crates at its eastern end.\nCareful: Razormane Flesheaters and Berserkers (18-19) are elites; they stand in the camp's north-east, beside the supply crates: pull the quilboar away from them one at a time."] = "Mientras estés en el campamento: los Buscaqua y Tejespinas de {npc:3429} en su mitad oeste, los Cazadores en el centro y las cajas de suministros en su extremo este.\nCuidado: los Comecarnes y Rabiosos Crines de Acero (18-19) son élites; están en el noreste del campamento, junto a las cajas de suministros: atrae a los jabaespines lejos de ellos de uno en uno.",
	-- ["Your {area:718} quests, if you have not taken them yet: {npc:3446} beside the {object:3972} poster, {npc:3665} on the dock by the flight master. The run is later in this guide, after {npc:3396}."] = "Tus misiones de {area:718}, si aún no las has aceptado: {npc:3446} junto al cartel de {object:3972}, {npc:3665} en el muelle junto al maestro de vuelo. La incursión es más adelante en esta guía, después de {npc:3396}.",
	-- ["Zhevra"] = "Astacebras",
	-- ["Zhevra Runners graze north and east of town."] = "Los Galopadores astacebra pastan al norte y al este del pueblo.",
	-- ["grind on {npc:3263}"] = "farmea {npc:3263}",
	-- ["{area:1898} cultists"] = "Fanáticos de {area:1898}",
	-- ["{area:380} is your base for this guide. Everyone you need stands within a few steps of the inn."] = "{area:380} es tu base en esta guía. Todos los que necesitas están a pocos pasos de la posada.",
	-- ["{area:392}: {area:718} quests"] = "{area:392}: misiones de {area:718}",
	-- ["{area:718} is a dungeon for a group of five, about levels 17 to 24, and a full run takes about an hour. Its mouth is just north of {npc:3396}'s shore, at the north end of {area:387}, under {npc:5767}'s cave.\nIn the caves before the portal: {npc:3655}, stealthed, with the {item:5334} (he moves between a few spots and comes back slowly: leave him if he's gone). Inside: the Deviates for {npc:5768}, and their hides for {npc:5767} (they drop rarely: one run may not be enough, so leave the rest for another run), {item:6464} from the Ectoplasms. After the four Fanglords, the {npc:3678} at the entrance leads you to Naralex: {npc:3654} drops the {item:10441}: its quest (someone in {area:392}, then {npc:8418} above the caverns) is not on this route; the Dungeons page's hand-in guide takes it."] = "{area:718} es una mazmorra para un grupo de cinco, de nivel 17 a 24 más o menos, y una incursión completa dura cerca de una hora. Su boca está justo al norte de la orilla de {npc:3396}, en el extremo norte de {area:387}, bajo la cueva de {npc:5767}.\nEn las cuevas antes del portal: {npc:3655}, en sigilo, con el {item:5334} (se mueve entre varios sitios y tarda en volver: déjalo si no está). Dentro: los Descarriados para {npc:5768}, y sus pieles para {npc:5767} (caen pocas veces: puede que una incursión no baste, así que deja el resto para otra), {item:6464} de los Ectoplasmas. Tras los cuatro Señores del Colmillo, el {npc:3678} de la entrada te lleva hasta Naralex: {npc:3654} suelta el {item:10441}: su misión (alguien en {area:392} y luego {npc:8418} encima de las cavernas) no está en esta ruta; la guía de entregas de la página de Mazmorras se encarga de ella.",
	-- ["{item:15885}: use a half at the {area:2362}"] = "{item:15885}: usa una mitad en {area:2362}",
	-- ["{item:6464}: the Ectoplasms"] = "{item:6464}: los Ectoplasmas",
	-- ["{npc:11799}, at the {area:2362}"] = "{npc:11799}, en {area:2362}",
	-- ["{npc:11857}: keep it, {npc:11864} at {area:460} in the {zone:1413} & Stonetalon guide"] = "{npc:11857}: guárdala, {npc:11864} en {area:460}, en la guía de {zone:1413} y Sierra Espolón",
	-- ["{npc:16227}, beside {npc:3442}"] = "{npc:16227}, junto a {npc:3442}",
	-- ["{npc:267310} stands on the north-east side of the Crossroads. {quest:97003} is a group quest: {npc:267307} is a level 20 elite boar in the Razormane's {area:1699} cave, east of the town, where the route goes back for {npc:3438} later."] = "{npc:267310} está en el lado noreste del Cruce. {quest:97003} es una misión de grupo: {npc:267307} es un jabalí élite de nivel 20 en la cueva Crines de Acero de {area:1699}, al este del pueblo, adonde la ruta vuelve más tarde por {npc:3438}.",
	-- ["{npc:3033}: Cat Form"] = "{npc:3033}: Forma felina",
	-- ["{npc:3033}: Cure Poison"] = "{npc:3033}: Curar veneno",
	-- ["{npc:3337}: {quest:840}, from {zone:1411}"] = "{npc:3337}: {quest:840}, de {zone:1411}",
	-- ["{npc:3338} by the inn first, then Helbrim by the north gate, {npc:3429} and {npc:3449} on the tower platform, {npc:3432} by the inn, and {npc:3448} at the south gate last. His seed test waits for the {npc:3395} pass at the {area:388}: go straight on north-west to the {area:383}. After the spores Helbrim offers {quest:853}, a delivery to {zone:1456} within 45 minutes: this route doesn't go there, so leave it (Druids take it on the next Crossroads stop, right before their flight to {zone:1456})."] = "Primero {npc:3338} junto a la posada, luego Helbrim junto a la puerta norte, {npc:3429} y {npc:3449} en la plataforma de la torre, {npc:3432} junto a la posada y, por último, {npc:3448} en la puerta sur. Su prueba de semillas espera a la pasada por {npc:3395} en {area:388}: sigue recto hacia el noroeste hasta {area:383}. Después de las esporas, Helbrim ofrece {quest:853}, una entrega en {zone:1456} en menos de 45 minutos: esta ruta no va allí, así que déjala (los druidas la aceptan en la siguiente parada en el Cruce, justo antes de su vuelo a {zone:1456}).",
	-- ["{npc:3390}: 45 minutes, for Zamah on the {zone:1456} step next"] = "{npc:3390}: 45 minutos, para Zamah en el siguiente paso, en {zone:1456}",
	-- ["{npc:3395} walks among the Kolkar at the {area:388} south-east of the Crossroads. Oasis Snapjaws crawl in the water around it: their shells are for {npc:3448}."] = "{npc:3395} camina entre los Kolkar de {area:388}, al sureste del Cruce. Los Quijafortes del oasis se arrastran por el agua a su alrededor: sus caparazones son para {npc:3448}.",
	-- ["{npc:3395} walks among the Kolkar at the {area:388} south-east of the Crossroads. Test {npc:3448}'s seeds at the bubbling fissure on the oasis' east bank while you are there."] = "{npc:3395} camina entre los Kolkar de {area:388}, al sureste del Cruce. Mientras estés allí, prueba las semillas de {npc:3448} en la fisura burbujeante de la orilla este del oasis.",
	-- ["{npc:3396} leads the Kolkar on the west shore of {area:387}, south of {npc:3389}. He walks that shore, from about 46,36 in the north to 46,42 in the south: if he isn't at the arrow, follow the shore until you meet him. Hand his head to {npc:3389} on your last Crossroads stop. Oasis Snapjaws crawl in the oasis' water there: their shells are for {npc:3448}."] = "{npc:3396} dirige a los Kolkar en la orilla oeste de {area:387}, al sur de {npc:3389}. Recorre esa orilla, desde aproximadamente 46,36 en el norte hasta 46,42 en el sur: si no está donde marca la flecha, sigue la orilla hasta encontrarlo. Entrega su cabeza a {npc:3389} en tu última parada en el Cruce. Allí, los Quijafortes del oasis se arrastran por el agua del oasis: sus caparazones son para {npc:3448}.",
	-- ["{npc:3428}'s {quest:868} waits for this guide's last Crossroads stop: its eggs come on the next {zone:1413} guide's walk south, at about 25."] = "{quest:868} de {npc:3428} espera a la última parada de esta guía en el Cruce: sus huevos están en el recorrido hacia el sur de la siguiente guía de {zone:1413}, hacia el nivel 25.",
	-- ["{npc:3428}, west of the north gate: keep {quest:868}, its eggs lie on the next {zone:1413} guide's walk south from {area:378}, at about 25"] = "{npc:3428}, al oeste de la puerta norte: guarda {quest:868}, sus huevos están en el recorrido hacia el sur desde {area:378} de la siguiente guía de {zone:1413}, hacia el nivel 25",
	-- ["{npc:3442} in {area:392}: on the next {area:392} stop"] = "{npc:3442} en {area:392}: en la próxima parada en {area:392}",
	-- ["{npc:3448}: the Oasis Snapjaws at the {area:388}, with {npc:3395}"] = "{npc:3448}: los Quijafortes del oasis de {area:388}, con {npc:3395}",
	-- ["{npc:3448}: the Oasis Snapjaws at {area:387}, with {npc:3396} after the {zone:1454} trip"] = "{npc:3448}: los Quijafortes del oasis de {area:387}, con {npc:3396} tras el viaje a {zone:1454}",
	-- ["{npc:3448}: the bubbling fissure at the {area:388}, on the {npc:3395} pass"] = "{npc:3448}: la fisura burbujeante de {area:388}, en la pasada por {npc:3395}",
	-- ["{npc:3449}: the harpies come later, in the {area:383}"] = "{npc:3449}: las arpías vienen más tarde, en {area:383}",
	-- ["{npc:3615}, the wind rider master"] = "{npc:3615}, el maestro de jinetes del viento",
	-- ["{npc:4049}: {quest:1063}, Magatha in {zone:1456}, on the next guide's way back from Zoram'gar"] = "{npc:4049}: {quest:1063}, Magatha en {zone:1456}, a la vuelta de Zoram'gar en la siguiente guía",
	-- ["{npc:4197} lives in {area:2539}, the troll village just inside Stonetalon at the end of the road west from {npc:3389}."] = "{npc:4197} vive en {area:2539}, la aldea trol justo al entrar en Sierra Espolón, al final del camino hacia el oeste desde {npc:3389}.",
	-- ["{npc:4201}: for {npc:3442}, beside {area:392}'s flight master at the end of the {zone:1413} & Stonetalon guide"] = "{npc:4201}: para {npc:3442}, junto al maestro de vuelo de {area:392}, al final de la guía de {zone:1413} y Sierra Espolón",
	-- ["{npc:5767} and {npc:5768}"] = "{npc:5767} y {npc:5768}",
	-- ["{npc:5878} camps beside the road from the {area:380} to {area:392}. The {object:58369} sits in the south of the Razormane camp just north of him."] = "{npc:5878} acampa junto al camino de {area:380} a {area:392}. {object:58369} está en el sur del campamento Crines de Acero, justo al norte de él.",
	-- ["{npc:5900} waits on the riverbank south of {area:379}, across the bridge."] = "{npc:5900} espera en la orilla al sur de {area:379}, al otro lado del puente.",
	-- ["{npc:5901} waits on the hill south of {area:392}, on your way north."] = "{npc:5901} espera en la colina al sur de {area:392}, de camino al norte.",
	-- ["{npc:5907} stands on the ridge north of the Razormane camp."] = "{npc:5907} está en la loma al norte del campamento Crines de Acero.",
	-- ["{npc:5909}, a few steps away"] = "{npc:5909}, a unos pasos",
	-- ["{npc:6018} stands in the {object:172961}, on the city's west side."] = "{npc:6018} está en {object:172961}, en el lado oeste de la ciudad.",
	-- ["{npc:6018}: {npc:4606} in the {zone:1458}, two guides on"] = "{npc:6018}: {npc:4606} en {zone:1458}, dos guías más adelante",
	-- ["{object:3972} poster"] = "Cartel de {object:3972}",
	-- ["{quest:3301}: the {area:228} in {zone:1421}, next guide"] = "{quest:3301}: {area:228} en {zone:1421}, en la próxima guía",
	-- ["{quest:853}, in the {area:2197}"] = "{quest:853}, en {area:2197}",
	-- ["{quest:881}, a white lion, prowls the plains north of the Razormane camp."] = "{quest:881}, un león blanco, merodea por las llanuras al norte del campamento Crines de Acero.",
	-- ["{zone:1454}'s level 20 class quests come right after the Crossroads, and they are offered only from 20. Still short of 20? The Bristleback Geomancers (19-20) hold {area:1700} around you: kill them until level 20. Or, with a group, run the {area:718} dungeon instead."] = "Las misiones de clase de nivel 20 de {zone:1454} llegan justo después del Cruce, y solo se ofrecen a partir del nivel 20. ¿Aún no eres nivel 20? Las Geománticas Erizapúas (19-20) ocupan {area:1700} a tu alrededor: mátalas hasta llegar a nivel 20. O, con un grupo, haz la mazmorra de {area:718}.",
}
