-- Spanish (Spain) (esES): the guide forever/horde/50-60/07-felwood (forever/horde/50-60/07-felwood.guide).
-- Written by `forge i18n guides sync esES`, which keeps every translation (docs/TRANSLATING.md, "Guide texts").
-- Translate the right-hand sides; "" shows the English. Keep each {kind:id} as it is: the game shows its
-- name there in Spanish (Spain) (the English is listed above the line). A name the English has in the plural, as words,
-- may be written with the singular's token from its "plural, as words" line: "Bandidos ({npc:251918})", "{npc:251918} ×8".
-- A token marked "no name in this language" would show in English: write that name in Spanish (Spain) words instead.
-- The comments are rewritten by sync.
return {
	-- Step 1: Into Tirisfal Glades
	-- {zone:1420} Tirisfal Glades
	["Into {zone:1420}"] = "Entra a {zone:1420}",

	-- Step 2: Zeppelin to Orgrimmar
	-- {zone:1454} Orgrimmar
	["Zeppelin to {zone:1454}"] = "Zepelín a {zone:1454}",

	-- Step 4: Vehena
	-- {object:172961} Valley of Spirits
	["In the {object:172961}."] = "En {object:172961}.",
	-- {item:14047} Runecloth
	["sixty {item:14047}, if you carry them"] = "sesenta {item:14047}, si los llevas",

	-- Step 5: Fly to Bloodvenom Post
	-- {area:1997} Bloodvenom Post
	["Fly to {area:1997}"] = "Vuela a {area:1997}",
	-- {zone:1454} Orgrimmar
	["{zone:1454} flight master"] = "Maestro de vuelo de {zone:1454}",

	-- Step 6: The Emerald Sanctuary
	-- {area:2479} Emerald Sanctuary
	["The {area:2479}"] = "{area:2479}",
	-- {area:431} Splintertree Post · {zone:1440} Ashenvale · {zone:1448} Felwood · {area:2479} Emerald Sanctuary
	["Fly to {area:431} and ride north-west along the road out of {zone:1440} into {zone:1448}. The {area:2479} is the druids' camp just past the border."] = "Vuela a {area:431} y cabalga hacia el noroeste por el camino que sale de {zone:1440} y entra en {zone:1448}. {area:2479} es el campamento de los druidas justo pasada la frontera.",
	-- {item:11173} Irontree Heart · {zone:1448} Felwood
	-- was: ["{npc:9116}'s Silver Heart needs an {item:11173} from northern {zone:1448} and a ride back here. Skip it."] = "Corazón de plata, de {npc:9116}, pide un {item:11173} del norte de {zone:1448} y volver hasta aquí. Omítela."
	["Eridan's Silver Heart needs an {item:11173} from northern {zone:1448} and a ride back here. Skip it."] = "Eridan's Silver Heart requiere un {item:11173} del norte de {zone:1448} y volver aquí. Omítela.",

	-- Step 7: To Bloodvenom Post
	-- {area:1997} Bloodvenom Post
	["To {area:1997}"] = "A {area:1997}",

	-- Step 8: Bloodvenom Post
	-- {area:1763} Jaedenar · {area:1997} Bloodvenom Post
	["Ride north along the road, past {area:1763}, to {area:1997}."] = "Cabalga hacia el norte por el camino, dejando atrás {area:1763}, hasta {area:1997}.",
	-- {npc:10306} Trull Failbane · {quest:4741} Wild Guardians · {zone:1452} Winterspring
	["{npc:10306}'s next {quest:4741} would bring you back here from {zone:1452}. Skip it."] = "La siguiente misión de {npc:10306}, {quest:4741}, te haría volver aquí desde {zone:1452}. Omítela.",

	-- Step 10: The Jadefire moonwell
	["The Jadefire moonwell"] = "El Jadefire moonwell",

	-- Step 12: Toxic Horrors
	-- {quest:5086} Toxic Horrors · {npc:14524} Vartrus the Ancient · {area:1767} Irontree Woods
	["Careful: Ancient Irontree Walkers, level 59 elites, walk among the {quest:5086}, and {npc:14524} (63, elite) roams the woods: work the Horrors at the north tip of {area:1767}, one at a time."] = "Cuidado: los Caminantes Irontree antiguos, élites de nivel 59, caminan entre los {quest:5086}, y {npc:14524} (63, élite) recorre el bosque: trabaja los Horrors de la punta norte de {area:1767} de uno en uno.",

	-- Step 14: To Rabine Saturna
	-- {npc:11801} Rabine Saturna
	["To {npc:11801}"] = "A {npc:11801}",

	-- Step 15: Rabine Saturna
	-- {npc:11801} Rabine Saturna · {area:2577} Dire Maul
	["{npc:11801}'s Shards of the Felvine needs {area:2577}. Skip it."] = "Fragmentos de gangrevid, de {npc:11801}, requiere {area:2577}. Omítela.",

	-- Step 16: To Donova Snowden
	-- {npc:9298} Donova Snowden
	["To {npc:9298}"] = "Ve por {npc:9298}",

	-- Step 17: Donova Snowden
	-- {zone:1452} Winterspring · {npc:9298} Donova Snowden
	["Back into the Timbermaw tunnel and take the {zone:1452} exit; {npc:9298} camps by the hot springs just outside."] = "Vuelve al túnel de los Fauces de Madera y toma la salida de {zone:1452}; {npc:9298} acampa junto a las aguas termales, justo fuera.",

	-- Step 18: Winterfall Runners
	-- {area:1769} Timbermaw Hold · {area:2244} Winterfall Village · {npc:9298} Donova Snowden
	-- was: ["Only if you carry {quest:5087}: the runners walk the road from {area:1769} toward {area:2244} in small groups; wait by the road near {npc:9298} and kill them as they pass. Each one carries a crate."] = "Solo si llevas {quest:5087}: los corredores recorren en grupos pequeños el camino de {area:1769} a {area:2244}; espera junto al camino cerca de {npc:9298} y mátalos al pasar. Cada uno lleva una caja."
	["The runners walk the road from {area:1769} toward {area:2244} in small groups; wait by the road near {npc:9298} and kill them as they pass. Each one carries a crate."] = "Los corredores recorren el camino de {area:1769} hacia {area:2244} en grupos pequeños; espera junto al camino cerca de {npc:9298} y mátalos cuando pasen. Cada uno lleva una caja.",

	-- Step 20: Winterfall Runners
	-- {npc:9298} Donova Snowden · {npc:10738} High Chief Winterfall
	["{npc:9298} next sends you after {npc:10738}, an elite in his cave. Skip it."] = "Después {npc:9298} te envía a por {npc:10738}, un élite en su cueva. Omítela.",

	-- Step 21: Grind to 60
	["Grind to 60"] = "Farmea hasta 60",
	-- {area:2249} Frostwhisper Gorge · {zone:1452} Winterspring · {area:2255} Everlook
	-- plural, as words: Rabid Shardtooths = {npc:7446} Rabid Shardtooth
	["The quests run out here. Rabid Shardtooths prowl {area:2249} in southern {zone:1452}, south of the road from {area:2255}."] = "Aquí se acaban las misiones. Los Dentoesquirlas rabiosos merodean por {area:2249}, en el sur de {zone:1452}, al sur del camino que sale de {area:2255}.",
	-- {npc:7446} Rabid Shardtooth · {area:2249} Frostwhisper Gorge · {zone:1452} Winterspring
	["grind on {npc:7446} at {area:2249}, {zone:1452}"] = "farmea {npc:7446} en {area:2249}, {zone:1452}",
	-- {zone:1454} Orgrimmar · {area:2255} Everlook
	["In {zone:1454}: fly from {area:2255}"] = "En {zone:1454}: vuela desde {area:2255}",
	-- {zone:1456} Thunder Bluff · {area:2255} Everlook
	["In {zone:1456}: fly from {area:2255}"] = "En {zone:1456}: vuela desde {area:2255}",

	-- No longer in the guide (its English changed or it went away): reuse or delete.
	-- ["A {item:13140} dropped: the Jaedenar Enforcers, Darkweavers, Warlocks and Legionnaires of Shadow Hold carry one now and then. Use it to start the quest, then free {npc:11018} from her cage in the cave's south end on your way out."] = "Te ha caído una {item:13140}: los Déspotas Jaedenar, Tejeoscuros, Brujos y Legionarios de Bastión de las Sombras la llevan de vez en cuando. Úsala para empezar la misión y luego libera a {npc:11018} de su jaula en el extremo sur de la cueva al salir.",
	-- ["Any Winterfall furbolg can carry the beads; the camps just south of {npc:11556} are the closest."] = "Cualquier fúrbolg Nevada puede llevar las cuentas; los campamentos justo al sur de {npc:11556} son los más cercanos.",
	-- ["Back into the Timbermaw tunnel and take the {area:618} exit; {npc:9298} camps by the hot springs just outside."] = "Vuelve al túnel de los Fauces de Madera y toma la salida de {area:618}; {npc:9298} acampa junto a las aguas termales, justo fuera.",
	-- ["Back south to the Sanctuary, a short ride."] = "Vuelve al sur, al Santuario; está cerca.",
	-- ["Below ground"] = "Bajo tierra",
	-- ["Class trainer"] = "Instructor de clase",
	-- ["Corrupted Soul Shards from the cultists, {quest:5887}"] = "Fragmentos de alma corruptos de los cultistas, {quest:5887}",
	-- ["Dungeon instead of grinding"] = "Mazmorra en vez de farmear",
	-- ["Fly to {area:431} and ride north-west along the road out of {zone:1440} into {area:361}. The {area:2479} is the druids' camp just past the border."] = "Vuela a {area:431} y cabalga hacia el noroeste por el camino que sale de {zone:1440} y entra en {area:361}. {area:2479} es el campamento de los druidas justo pasada la frontera.",
	-- ["From Krakle in Un'Goro"] = "De Krakle en Un'Goro",
	-- ["From the {zone:1458}, take the zeppelin from the tower outside the city to {zone:1454}."] = "Desde {zone:1458}, toma el zepelín de la torre de fuera de la ciudad hasta {zone:1454}.",
	-- ["Frostfire Winterfall camp"] = "Campamento Nevada de los Baños de Fuego de Escarcha",
	-- ["North of Donova, at the tunnel's {zone:1452} exit."] = "Al norte de Donova, en la salida del túnel hacia {zone:1452}.",
	-- ["On the way back south to Greta, {npc:9529} takes the shards on the west side of the Sanctuary."] = "De vuelta al sur hacia Greta, {npc:9529} recoge los fragmentos en el lado oeste del Santuario.",
	-- ["Only if you carry {quest:5087}: the runners walk the road from {area:1769} toward {area:2244} in small groups; wait by the road near {npc:9298} and kill them as they pass. Each one carries a crate."] = "Solo si llevas {quest:5087}: los corredores recorren en grupos pequeños el camino de {area:1769} a {area:2244}; espera junto al camino cerca de {npc:9298} y mátalos al pasar. Cada uno lleva una caja.",
	-- ["Only if {npc:9298} gave you {quest:5086}: ride north up the {area:361} road to {area:1767}; the {quest:5086} ooze between the trees."] = "Solo si {npc:9298} te dio {quest:5086}: cabalga hacia el norte por el camino de {area:361} hasta {area:1767}; los {quest:5086} reptan entre los árboles.",
	-- ["Optional. Running {area:2279}, {area:2057}, Lower Blackrock Spire or {area:1584} with a group instead of grinding gets you there faster."] = "Opcional. Hacer {area:2279}, {area:2057}, Cumbre de Roca Negra inferior o {area:1584} en grupo en vez de farmear te lleva antes.",
	-- ["Optional. Running {area:2279}, {area:2057}, Lower {area:1583} or {area:1584} with a group instead of grinding gets you there faster."] = "Opcional. Hacer {area:2279}, {area:2057}, {area:1583} inferior o {area:1584} en grupo en vez de farmear te lleva antes.",
	-- ["Optional: with a group, a 55-60 dungeon replaces the grind below."] = "Opcional: en grupo, una mazmorra de 55-60 sustituye al farmeo de abajo.",
	-- ["Ride back west along the road to {area:2246}."] = "Vuelve al oeste por el camino hasta {area:2246}.",
	-- ["Ride back west to {area:2246}."] = "Vuelve al oeste hasta {area:2246}.",
	-- ["Ride east along the road to {area:2255}."] = "Cabalga hacia el este por el camino hasta {area:2255}.",
	-- ["Ride east, then south down {area:2249}. The Frostmaul giants there are elite level 59: keep to the middle and keep moving. The strange source is at the mouth of {area:2256}, at the south end."] = "Cabalga al este y luego al sur bajando por {area:2249}. Los Gigantes Machacahielo de allí son élite de nivel 59: ve por el centro y no te detengas. La fuente extraña está en la boca de {area:2256}, en el extremo sur.",
	-- ["Ride north to {area:2255}."] = "Cabalga al norte hasta {area:2255}.",
	-- ["Ride north-west to {area:1763}. The four braziers stand among the Shadow Council's buildings; use the Cleansed Water on each one.\nCareful: Shadow Council mobs of level 53-55 fill the cave and often come in large linked groups, many with stuns. A group of 2-3 players is recommended."] = "Cabalga hacia el noroeste hasta {area:1763}. Los cuatro braseros están entre los edificios del Consejo de las Sombras; usa el agua purificada en cada uno.\nCuidado: enemigos del Consejo de las Sombras de nivel 53-55 llenan la cueva y suelen venir en grandes grupos vinculados, muchos con aturdimientos. Se recomienda un grupo de 2-3 jugadores.",
	-- ["South to the Sanctuary once more."] = "Vuelve otra vez al sur, al Santuario.",
	-- ["The furbolg village fills the valley north-east of {area:2255}. Kill Shamans first; they heal. {npc:10738} (59, elite) and Xandivious (62) are in the cave at the back: stay out."] = "El poblado fúrbolg ocupa el valle al noreste de {area:2255}. Mata primero a los Chamanes, que curan. {npc:10738} (59, élite) y Xandivious (62) están en la cueva del fondo: no entres.",
	-- ["The quests run out here. Rabid Shardtooths prowl {area:2249} in southern {area:618}, south of the road from {area:2255}."] = "Aquí se acaban las misiones. Los Dentoesquirlas rabiosos merodean por {area:2249}, en el sur de {area:618}, al sur del camino que sale de {area:2255}.",
	-- ["Through the Timbermaw tunnel to {area:493}. {npc:11939} reads in a house in {area:2361}."] = "Cruza el túnel de los Fauces de Madera hasta {area:493}. {npc:11939} lee en una casa de {area:2361}.",
	-- ["Through the Timbermaw tunnel to {zone:1450}. {npc:11939} reads in a house in {area:2361}."] = "Cruza el túnel de los Fauces de Madera hasta {zone:1450}. {npc:11939} lee en una casa de {area:2361}.",
	-- ["With 30 {quest:6031} in your bags: follow the road north to {area:1769}; {npc:11557} trades just inside the entrance."] = "Con 30 de {quest:6031} en tus bolsas: sigue el camino hacia el norte hasta {area:1769}; {npc:11557} comercia justo al pasar la entrada.",
	-- ["Zeppelin to {zone:1454}"] = "Zepelín a {zone:1454}",
	-- ["grind on {npc:7446} at {area:2249}, {area:618}"] = "farmea {npc:7446} en {area:2249}, {area:618}",
	-- ["only if still carried: the {zone:1423} guide hands it in on its way through"] = "solo si aún la llevas: la guía de {zone:1423} la entrega de paso",
	-- ["{npc:10306}'s next {quest:4741} would bring you back here from {area:618}. Skip it."] = "La siguiente misión de {npc:10306}, {quest:4741}, te haría volver aquí desde {area:618}. Omítela.",
	-- ["{npc:11556} takes the beads only once {quest:8464} is handed in: any Winterfall furbolg can carry them, and the camps just south of {npc:11556} are the closest."] = "{npc:11556} solo acepta las cuentas una vez entregada {quest:8464}: cualquier fúrbolg Nevada puede llevarlas, y los campamentos justo al sur de {npc:11556} son los más cercanos.",
	-- ["{npc:9116}'s Silver Heart needs an {item:11173} from northern {area:361} and a ride back here. Skip it."] = "Corazón de plata, de {npc:9116}, pide un {item:11173} del norte de {area:361} y volver hasta aquí. Omítela.",
	-- ["{npc:9116}'s Silver Heart needs an {item:11173} from northern {zone:1448} and a ride back here. Skip it."] = "Corazón de plata, de {npc:9116}, pide un {item:11173} del norte de {zone:1448} y volver hasta aquí. Omítela.",
	-- ["{npc:9529} stands on the west side of the Sanctuary, the way out to {area:1763}. With {quest:4102} done, her {quest:5887} asks for six Corrupted Soul Shards: the Shadow Council cultists in {area:1763} and {area:1770} drop them about one kill in three, and you fight dozens of them for {npc:10922}."] = "{npc:9529} está en el lado oeste del Santuario, en la salida hacia {area:1763}. Con {quest:4102} completada, su misión {quest:5887} pide seis Fragmentos de alma corruptos: los cultistas del Consejo de las Sombras de {area:1763} y {area:1770} los sueltan más o menos uno de cada tres, y vas a matar docenas de ellos para {npc:10922}.",
	-- ["{npc:9861}, {npc:9860} and {npc:9517} wait at the back of {area:1770}, the cave in {area:1763}'s north. Clear the tunnel as you go.\nCareful: The three bosses fight as a group. Kill the nearby mobs first so you don't pull extra enemies."] = "{npc:9861}, {npc:9860} y {npc:9517} esperan al fondo de {area:1770}, la cueva del norte de {area:1763}. Despeja el túnel a tu paso.\nCuidado: los tres jefes luchan en grupo. Mata antes a los enemigos cercanos para no atraer enemigos de más.",
	-- ["{quest:8464}'s village is north-east of {area:2255}, on this guide's way back from {area:2256}."] = "El poblado de {quest:8464} está al noreste de {area:2255}, en el camino de vuelta de esta guía desde {area:2256}.",
}
