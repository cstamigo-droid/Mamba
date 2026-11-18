-- Spanish (Spain) (esES): the guide forever/horde/tauren/02-silverpine-forest (forever/horde/tauren/02-silverpine-forest.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: To Orgrimmar
	-- {zone:1454} Orgrimmar
	["To {zone:1454}"] = "A {zone:1454}",

	-- Step 2: Inn and flight master
	["Inn and flight master"] = "Posada y maestro de vuelo",

	-- Step 3: Neeru Fireblade
	-- {object:172960} Cleft of Shadow · {object:172982} Valley of Strength · {quest:829} Neeru Fireblade
	["The {object:172960} is the canyon under the {object:172982}; {quest:829} stands at its far end."] = "{object:172960} es el cañón bajo {object:172982}; {quest:829} está al fondo.",
	-- {quest:829} Neeru Fireblade · {quest:809} Ak'Zeloth · {area:379} Far Watch Post
	["{quest:829}: {quest:809} stands at {area:379}, on the next guide's road to the Crossroads"] = "{quest:829}: {quest:809} está en {area:379}, en el camino de la siguiente guía al Cruce",
	-- {quest:829} Neeru Fireblade · {quest:832} Burning Shadows · {item:4903} Eye of Burning Shadow · {area:14} Durotar
	["{quest:829}: {quest:832}, from the {item:4903} in {area:14}"] = "{quest:829}: {quest:832}, del {item:4903} en {area:14}",

	-- Step 4: Thrall
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

	-- Step 5: Thrall
	-- {npc:4949} Thrall
	["{npc:4949}, inside Grommash Hold"] = "{npc:4949}, dentro de la fortaleza de Thrall",

	-- Step 6: Nazgrel
	-- {npc:3230} Nazgrel
	["{npc:3230}, in Grommash Hold"] = "{npc:3230}, en la fortaleza de Thrall",

	-- Step 7: Snang
	-- {npc:2855} Snang · {object:172958} Valley of Honor
	["{npc:2855}, the tailoring trainer, is in the {object:172958}."] = "{npc:2855}, el instructor de sastrería, está en {object:172958}.",
	-- {npc:2855} Snang · {area:14} Durotar
	["{npc:2855}: Camping 101, from Brakk's campfire in {area:14}"] = "{npc:2855}: Camping 101, de la fogata de Brakk en {area:14}",

	-- Step 8: Sayoc
	-- {spell:197} Two-Handed Axes · {npc:11868} Sayoc · {object:172958} Valley of Honor
	["While you're here: learn {spell:197} from {npc:11868} ({object:172958}, 10 silver); two-handers level a Warrior fastest."] = "Ya que estás aquí: aprende {spell:197} con {npc:11868} ({object:172958}, 10 de plata); las armas de dos manos suben de nivel más rápido a un guerrero.",

	-- Step 9: Hanashi
	-- {npc:2704} Hanashi · {object:172958} Valley of Honor
	["While you're here: learn Staves from {npc:2704} ({object:172958}, 10 silver); a Hunter's melee weapon is mostly its stats, and two-handers carry the most."] = "Ya que estás aquí: aprende Bastones con {npc:2704} ({object:172958}, 10 de plata); el arma cuerpo a cuerpo de un cazador vale sobre todo por sus estadísticas, y las de dos manos son las que más tienen.",

	-- Step 10: Hanashi
	-- {npc:2704} Hanashi · {object:172958} Valley of Honor
	["While you're here: learn Staves from {npc:2704} ({object:172958}, 10 silver); a staff carries more spell stats than a one-hander while you level."] = "Ya que estás aquí: aprende Bastones con {npc:2704} ({object:172958}, 10 de plata); un bastón da más estadísticas de hechizo que un arma de una mano mientras subes de nivel.",

	-- Step 13: Into Durotar
	-- {area:14} Durotar
	["Into {area:14}"] = "Entra en {area:14}",

	-- Step 14: Zeppelin to Undercity
	-- {zone:1458} Undercity
	["Zeppelin to {zone:1458}"] = "Zepelín a {zone:1458}",

	-- Step 16: The Sepulcher
	-- {area:228} The Sepulcher · {npc:2226} Karos Razok
	["{area:228} is the Forsaken crypt-town in the middle of the forest. Everyone you need stands around the crypt entrance; {npc:2226}, the bat handler, is just east of it."] = "{area:228} es el pueblo cripta de los Renegados en medio del bosque. Todos los que necesitas están alrededor de la entrada de la cripta; {npc:2226}, el cuidador de murciélagos, está justo al este.",
	-- {npc:2226} Karos Razok · {npc:4556} Gordon Wendham · {zone:1458} Undercity
	["{npc:2226}: {npc:4556} in the {zone:1458}, at the end of this guide; no need to buy the flight"] = "{npc:2226}: {npc:4556} en {zone:1458}, al final de esta guía; no hace falta comprar el vuelo",
	-- {npc:1952} High Executor Hadrec
	["{npc:1952}, below ground"] = "{npc:1952}, bajo tierra",

	-- Step 19: Border Crossings
	-- {object:1627} Dalaran Crate
	-- plural, as words: Dalaran Apprentices = {npc:1867} Dalaran Apprentice
	["Follow the road south. The {object:1627} sits beside it, north of Pyrewood. Careful: Dalaran Apprentices (13) stand around the crate: pull them one at a time before you open it."] = "Sigue el camino al sur. {object:1627} está a un lado, al norte de Aldea Piroleña. Cuidado: hay aprendices de Dalaran (13) alrededor de la caja: atráelos de uno en uno antes de abrirla.",

	-- Step 20: Malden's Orchard
	-- {area:238} Malden's Orchard
	["Follow the road north-east to the Yoricks' house at {area:238}."] = "Sigue el camino al noreste hasta la casa de los Yorick en {area:238}.",

	-- Step 21: The Dead Field: kill these as you meet them
	-- {area:240} The Dead Field
	["{area:240}: kill these as you meet them"] = "{area:240}: mata a estos enemigos conforme los encuentres",
	-- {area:228} The Sepulcher · {npc:1983} Nightlash · {area:240} The Dead Field
	["North of the {area:228}. {npc:1983} haunts the {area:240}: kill it, then walk across the field. Careful: {npc:1983} (14) rises once you have killed rot hide gnolls in the field: fight her with full health."] = "Al norte de {area:228}. {npc:1983} ronda {area:240}: mátalo y luego cruza el campo. Cuidado: {npc:1983} (14) aparece cuando ya mataste gnolls Pellejo Podrido en el campo: enfréntala con la salud completa.",

	-- Step 22: Escorting Erland
	-- {npc:1978} Deathstalker Erland · {npc:1950} Rane Yorick
	["{npc:1978} waits north-east of the house. Escort him back to {npc:1950}; worgs attack on the way."] = "{npc:1978} espera al noreste de la casa. Escóltalo de vuelta con {npc:1950}; los huargos atacan en el camino.",
	-- {npc:1978} Deathstalker Erland
	["{npc:1978}, inside"] = "{npc:1978}, adentro",

	-- Step 25: The Sepulcher
	-- {npc:1937} Apothecary Renferrel · {zone:1458} Undercity
	["{npc:1937}: Zinge in the {zone:1458}, on the way to the zeppelin at the end"] = "{npc:1937}: Zinge en {zone:1458}, de camino al zepelín al final",
	-- {npc:1938} Dalar Dawnweaver · {area:227} Valgan's Field
	["{npc:1938}: his books lie in the {area:227} farmhouse, on the walk north"] = "{npc:1938}: sus libros están en la granja de {area:227}, en el camino al norte",
	["Allister's Ambermill Investigations is for the ride through Silverpine at 22; leave it."] = "Las investigaciones de Allister en Molino Ámbar son para el paso por Bosque de Argénteos al nivel 22; déjala.",

	-- Step 26: Valgan's Field farmhouse
	-- {area:227} Valgan's Field
	["{area:227} farmhouse"] = "Granja de {area:227}",
	-- {area:227} Valgan's Field · {object:1571} Dusty Spellbooks · {npc:1770} Moonrage Darkrunner
	["On the road north, the farmhouse at {area:227}: go upstairs, the {object:1571} lie on the floor in the back room. Looting them brings a {npc:1770}."] = "En el camino al norte, la granja de {area:227}: sube al piso de arriba; {object:1571} están en el suelo del cuarto del fondo. Al saquearlos aparece un {npc:1770}.",
	-- {object:1571} Dusty Spellbooks
	["{object:1571}; upstairs"] = "{object:1571}; arriba",

	-- Step 27: Quinn Yorick
	["North again to the Yoricks' house."] = "De nuevo al norte, a la casa de los Yorick.",
	-- {npc:1951} Quinn Yorick
	["{npc:1951}, inside"] = "{npc:1951}, adentro",

	-- Step 28: The Ivar Patch
	-- {zone:1420} Tirisfal Glades · {area:238} Malden's Orchard · {quest:425} Ivar the Foul
	["Take the road north toward {zone:1420}: the Yoricks' house at {area:238} is on the way. {quest:425} lurks a short walk west of it."] = "Toma el camino al norte hacia {zone:1420}: la casa de los Yorick en {area:238} está de camino. {quest:425} acecha a poca distancia al oeste.",
	["Inside"] = "Adentro",

	-- Step 29: Vile Fin murlocs
	["Vile Fin murlocs"] = "Múrlocs Anca Vil",
	-- plural, as words: Vile Fin Shredders = {npc:1767} Vile Fin Shredder
	["Follow the lake shore south-east from the Yoricks' house: the Vile Fin Shredders and Tidehunters along it drop the murloc eyes."] = "Sigue la orilla del lago hacia el sureste desde la casa de los Yorick: los Machacadores Anca Vil y Cazamareas Anca Vil de allí sueltan los ojos de múrloc.",

	-- Step 30: The Decrepit Ferry
	-- {object:1593} Corpse Laden Boat
	["Follow the lake shore south from the murlocs: the {object:1593} lies at the ferry landing."] = "Sigue la orilla del lago al sur desde los múrlocs: {object:1593} está en el embarcadero.",

	-- Step 31: The Sepulcher
	-- {area:228} The Sepulcher
	["From the ferry back west up the road to the {area:228}."] = "Desde el embarcadero, de vuelta al oeste por el camino hasta {area:228}.",
	-- {npc:1938} Dalar Dawnweaver
	["{npc:1938}, just north of Allister"] = "{npc:1938}, justo al norte de Allister",
	-- {npc:1499} Magistrate Sevren · {area:159} Brill
	["{npc:1499} in {area:159}, on the way to the zeppelin at the end"] = "{npc:1499} en {area:159}, de camino al zepelín al final",
	-- {npc:1937} Apothecary Renferrel
	["{npc:1937}: for Quinn, on the road north at the end"] = "{npc:1937}: para Quinn, en el camino al norte al final",

	-- Step 32: To Magistrate Sevren
	-- {npc:1499} Magistrate Sevren
	["To {npc:1499}"] = "A {npc:1499}",

	-- Step 33: Magistrate Sevren
	-- {area:159} Brill · {npc:1499} Magistrate Sevren
	["{area:159} is a short walk north up the road from the zeppelin towers; {npc:1499} is in the town hall."] = "{area:159} está a poca distancia al norte por el camino desde las torres de zepelín; {npc:1499} está en el ayuntamiento.",

	-- Step 34: To Undercity
	-- {zone:1458} Undercity
	["To {zone:1458}"] = "A {zone:1458}",

	-- Step 35: Gordon Wendham
	-- {object:1661} The Undercity · {area:153} Ruins of Lordaeron · {npc:2050} Raleigh Andrean · {npc:7683} Alessandro Luca · {npc:11044} Doctor Martin Felben · {npc:5204} Apothecary Zinge · {npc:2055} Master Apothecary Faranell
	["{object:1661} lies under the {area:153}, beside the zeppelin towers. {npc:2050} stands at the inn by the way down; {npc:7683} on the way down to the Apothecarium, where {npc:11044} and {npc:5204} stand beside {npc:2055}."] = "{object:1661} está bajo {area:153}, junto a las torres de zepelín. {npc:2050} está en la posada, de bajada; {npc:7683}, de bajada a la botica real, donde {npc:11044} y {npc:5204} están junto a {npc:2055}.",
	-- {npc:4556} Gordon Wendham
	["{npc:4556}, the weapon merchant beside the bat handler"] = "{npc:4556}, el vendedor de armas junto al cuidador de murciélagos",
	-- {npc:4551} Michael Garrett
	["{npc:4551}, the bat handler"] = "{npc:4551}, el cuidador de murciélagos",
	-- {npc:4551} Michael Garrett · {item:16210} Gordon's Crate · {area:228} The Sepulcher
	["{npc:4551}: keep {item:16210}, Podrig takes it on the next stop at the {area:228}, at 22"] = "{npc:4551}: guarda {item:16210}, Podrig lo recibe en la siguiente parada en {area:228}, a nivel 22",

	-- Step 36: The Undercity
	-- {npc:11044} Doctor Martin Felben
	["{npc:11044}, in the Apothecarium"] = "{npc:11044}, en la botica real",
	-- {npc:5204} Apothecary Zinge
	["{npc:5204}, in the Apothecarium"] = "{npc:5204}, en la botica real",
	-- {npc:5204} Apothecary Zinge
	["{npc:5204}: Helbrim at the Crossroads, in the next guide"] = "{npc:5204}: Helbrim en el Cruce, en la siguiente guía",
	-- {npc:260093} Garen Largo · {zone:1458} Undercity
	["{npc:260093}, the {zone:1458}'s paladin trainer"] = "{npc:260093}, el instructor de paladines de {zone:1458}",

	-- Step 37: Lady Sylvanas Windrunner
	-- {object:1661} The Undercity · {area:153} Ruins of Lordaeron · {npc:10181} Lady Sylvanas Windrunner · {object:36126} Royal Quarter
	["{object:1661} lies under the {area:153}; {npc:10181} holds court in the {object:36126}."] = "{object:1661} está bajo {area:153}; {npc:10181} tiene su corte en el {object:36126}.",
	-- {npc:10181} Lady Sylvanas Windrunner · {object:36126} Royal Quarter · {quest:93739} Exploring the Horde
	["Speak with {npc:10181}, in the {object:36126}: {quest:93739}"] = "Habla con {npc:10181}, en {object:36126}: {quest:93739}",
	-- {npc:10181} Lady Sylvanas Windrunner
	["Talk to {npc:10181}"] = "Habla con {npc:10181}",

	-- Step 38: To Bloodhoof Village
	-- {area:222} Bloodhoof Village
	["To {area:222}"] = "A {area:222}",

	-- Step 39: To Thunder Bluff
	-- {zone:1456} Thunder Bluff
	["To {zone:1456}"] = "A {zone:1456}",

	-- Step 40: Fly to Orgrimmar
	-- {area:1637} Orgrimmar
	["Fly to {area:1637}"] = "Vuela a {area:1637}",
	-- {zone:1456} Thunder Bluff
	["{zone:1456} flight master"] = "Maestro de vuelo de {zone:1456}",

	-- Step 41: Zeppelin to Orgrimmar
	-- {zone:1454} Orgrimmar
	["Zeppelin to {zone:1454}"] = "Zepelín a {zone:1454}",

	-- Step 42: Orgrimmar
	-- {zone:1454} Orgrimmar
	["{zone:1454}'s main gate"] = "La puerta principal de {zone:1454}",

	-- Step 43: The Drag
	-- {npc:3348} Kor'geld · {npc:3347} Yelmak · {npc:11046} Whuut
	["{npc:3348} and {npc:3347} run the alchemy shop in the Drag; {npc:11046} is next door."] = "{npc:3348} y {npc:3347} atienden la tienda de alquimia de la calle comercial de la ciudad; {npc:11046} está al lado.",

	-- Step 44: Sayoc
	-- {spell:197} Two-Handed Axes · {npc:11868} Sayoc · {object:172958} Valley of Honor
	["While you're here: learn {spell:197} from {npc:11868} ({object:172958}, 10 silver); two-handers level a Paladin fastest."] = "Ya que estás aquí: aprende {spell:197} con {npc:11868} ({object:172958}, 10 de plata); las armas de dos manos suben de nivel más rápido a un paladín.",

	-- Step 46: Valley of Wisdom
	-- {npc:268684} Thra · {object:172957} Valley of Wisdom · {area:379} Far Watch Post
	-- plural, as words: Smooth Boulders = {item:277952} Smooth Boulder
	["{npc:268684} and Migi sit behind Grommash Hold in the {object:172957}; the Smooth Boulders lie around them. The next guide walks from here to {area:379} and the Crossroads."] = "{npc:268684} y Migi están detrás de Grommash Hold, en el {object:172957}; las Smooth Boulders están a su alrededor. La siguiente guía camina desde aquí hasta {area:379} y el Cruce.",

	-- Step 47: Zor Lonetree
	-- {npc:4047} Zor Lonetree · {npc:4049} Seereth Stonebreak
	["{npc:4047}: {npc:4049}, on the road into Stonetalon in the next guide"] = "{npc:4047}: {npc:4049}, en el camino hacia Stonetalon, en la siguiente guía",

	-- Step 48: Valley of Strength
	-- {npc:268701} Thatog · {object:172982} Valley of Strength · {object:173016} Borstan's Firepit
	["Walk in through the main gate. {npc:268701} stands in the {object:172982}.\n{object:173016} is a few steps north."] = "Entra por la puerta principal. {npc:268701} está en {object:172982}.\\n{object:173016} está unos pasos al norte.",

	-- Step 51: Fly to Crossroads
	["Fly to Crossroads"] = "Vuela al Cruce",
	-- {zone:1454} Orgrimmar
	["{zone:1454} flight master"] = "Maestro de vuelo de {zone:1454}",
}
