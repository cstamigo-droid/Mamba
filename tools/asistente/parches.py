"""Parches de Mamba sobre archivos de Polestar (ARQUITECTURA §13b.2 y §13f.4).

Cada parche es "buscar este texto exacto -> reemplazarlo". El script es
idempotente: si el parche ya está, no hace nada; si el texto original ya no
existe (una versión nueva de Polestar lo cambió), FALLA y lo dice, para
revisarlo a mano. Respeta los saltos de línea de cada archivo (CRLF o LF).
Después de cada fusión con Polestar:

    python -I tools/asistente/parches.py            # aplica
    python -I tools/asistente/parches.py --revisar  # solo dice qué falta (sale 1 si falta algo)

La lista legible, con el porqué de cada uno, está en PARCHES.md.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
ADDON = RAIZ / "addon"
FECHA = __import__("datetime").date.today().isoformat()  # el día en que se aplica (GPL-3.0 §5a)
REPO = "https://github.com/cstamigo-droid/Mamba"
CR = chr(13)
LF = chr(10)

# (id, archivo relativo a addon/, texto original, texto nuevo)
PARCHES = [
    ("P1-errores", "Polestar/Core/Init.lua",
     'ns.DiscordURL = "https://discord.gg/polestar"',
     f'ns.DiscordURL = "{REPO}/issues" -- Mamba (PARCHES.md P1): los avisos del fork no van al Discord de Polestar'),
    ("P1-errores", "Polestar/Core/Init.lua",
     'ns.IssueURL = "https://github.com/fitzforge/polestar/issues/new"',
     f'ns.IssueURL = "{REPO}/issues/new" -- Mamba (PARCHES.md P1)' + LF +
     'ns.mamba = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "X-Mamba")) or nil'),
    ("P2-version", "Polestar/Core/Update.lua",
     'local function mine()' + LF + '\tlocal v = tostring(ns.version or "")',
     'local function mine()' + LF +
     '\tif ns.mamba then return nil end -- Mamba (PARCHES.md P2): el fork no se compara con Polestar oficial' + LF +
     '\tlocal v = tostring(ns.version or "")'),
    ("P2-version", "Polestar/Core/Update.lua",
     'local base = "https://github.com/fitzforge/polestar/releases"',
     f'local base = "{REPO}/releases" -- Mamba (PARCHES.md P2)'),
    ("P2-version", "Polestar/Quests/Party.lua",
     '	if newer and not (U and U.Covers(version)) then',
     '	if newer and not ns.mamba and not (U and U.Covers(version)) then -- Mamba (PARCHES.md P2): sin "A newer version is out"'),
    ("P3-tomtom", "Polestar/Nav/Journey.lua",
     "answerTomTom = false, -- the stand-in has methods only: an addon reading TomTom.db would error",
     "answerTomTom = true, -- Mamba (PARCHES.md P3): reemplaza a TomTom (/way y su API de puntos). "
     "The stand-in has methods only: an addon reading TomTom.db would error"),
    # P8: el planificador ya arma los tramos al estimar; Mamba (Asistente/Llevame.lua) los lee y pide la ruta sin vuelos.
    ("P8-tramos", "Polestar/Nav/Travel.lua",
     "function Nav.EstimateTravel(from, to, budgeted, noHearth)" + LF,
     "-- Mamba (PARCHES.md P8): noFlights = true plans without flights; a third value, the plan's legs (read-only)." + LF +
     "function Nav.EstimateTravel(from, to, budgeted, noHearth, noFlights)" + LF),
    ("P8-tramos", "Polestar/Nav/Travel.lua",
     "tc, twx, twy, from ~= nil and 0 or timed == \"escort\" and 4 or timed and 3 or noHearth and 2 or 1, D and D.Level() or 0)",
     "tc, twx, twy, from ~= nil and 0 or timed == \"escort\" and 4 or timed and 3 or noHearth and 2 or 1, D and D.Level() or 0)" + LF +
     "	if noFlights then key = key .. \":nf\" end -- Mamba (PARCHES.md P8)"),
    ("P8-tramos", "Polestar/Nav/Travel.lua",
     "if hit and now - hit.at < CACHE_SECONDS then return hit.seconds end",
     "if hit and now - hit.at < CACHE_SECONDS then return hit.seconds, nil, hit.legs end -- Mamba (PARCHES.md P8): legs"),
    ("P8-tramos", "Polestar/Nav/Travel.lua",
     "		departure = departureFn()," + LF + "		walkOnly = ghost or timed == \"escort\",",
     "		departure = departureFn()," + LF + "		noFlights = noFlights or nil, -- Mamba (PARCHES.md P8)" + LF + "		walkOnly = ghost or timed == \"escort\","),
    ("P8-tramos", "Polestar/Nav/Travel.lua",
     "estimates[key] = { at = now, seconds = seconds }" + LF + "	return seconds" + LF,
     "estimates[key] = { at = now, seconds = seconds, legs = plan } -- Mamba (PARCHES.md P8): legs" + LF + "	return seconds, nil, plan" + LF),
    # P9-P11 (K56/K57, Mamba_Panel): las líneas de Mamba en el panel de la guía y las pestañas.
    ('P9-panel', 'Polestar/UI/GuideFrameLayout.lua',
     '\t\tif claimed(name, frame, width, h) then return y end\n\t\treturn stack(frame, y, h)\n\tend\n',
     '\t\tif claimed(name, frame, width, h) then return y end\n\t\treturn stack(frame, y, h)\n\tend\n\n\t-- Mamba (PARCHES.md P9): the lines of Mamba_Panel in the live window\'s flow, a part ("mamba") like Along the\n\t-- way: UI.MambaLineas lays out its own rows (filled beforehand) and answers its frame and height.\n\tlocal function mamba(y, width, shown)\n\t\tlocal fn = GF.live and UI.MambaLineas\n\t\tif not fn then return y end\n\t\tlocal ok, f, h = pcall(fn, GF, body, width, shown and not compact() or false, PAD, TEXT_X, UP_ROW, UP_TOGGLE)\n\t\tif ok and f and type(h) == "number" and h > 0 then return place("mamba", f, y, h, width) end\n\t\treturn y\n\tend\n'),
    ('P9-panel', 'Polestar/UI/GuideFrameLayout.lua',
     '\t\t\tfor _, f in ipairs({ card, after, along, GF.here, upnext, UI.JourneyPanel and UI.JourneyPanel.frame }) do f:Hide() end\n\t\t\tlocal outer',
     '\t\t\tfor _, f in ipairs({ card, after, along, GF.here, upnext, UI.JourneyPanel and UI.JourneyPanel.frame }) do f:Hide() end\n\t\t\tmamba(y, width, false) -- Mamba (PARCHES.md P9)\n\t\t\tlocal outer'),
    ('P9-panel', 'Polestar/UI/GuideFrameLayout.lua',
     '\t\t\tif along:IsShown() then y = place("along", along, y, layoutAlong(width), width) end\n\t\t\tif upnext:IsShown()',
     '\t\t\tif along:IsShown() then y = place("along", along, y, layoutAlong(width), width) end\n\t\t\ty = mamba(y, width, true) -- Mamba (PARCHES.md P9)\n\t\t\tif upnext:IsShown()'),
    ('P9-panel', 'Polestar/UI/GuideFrameLayout.lua',
     '\t\t\ty = stack(empty, y, layoutEmpty(width))\n\t\t\ty = stackJourney(y, width)\n\t\tend',
     '\t\t\ty = stack(empty, y, layoutEmpty(width))\n\t\t\ty = stackJourney(y, width)\n\t\t\ty = mamba(y, width, true) -- Mamba (PARCHES.md P9)\n\t\tend'),
    ('P10-leveo-fijo', 'Polestar/UI/GuideFrameTabs.lua',
     '\t\t\tif button == "MiddleButton" and E.CloseTab then return E.CloseTab(self.psIndex) end\n',
     '\t\t\tif button == "MiddleButton" and E.CloseTab and not self.psFijo then return E.CloseTab(self.psIndex) end -- Mamba (PARCHES.md P10)\n'),
    ('P10-leveo-fijo', 'Polestar/UI/GuideFrameTabs.lua',
     '\t\t\t{ text = L["Close tab"], icon = "close", onClick = function() E.CloseTab(i) end },\n',
     '\t\t\t{ text = L["Close tab"], icon = "close", disabled = self.psFijo, onClick = function() E.CloseTab(i) end }, -- Mamba (PARCHES.md P10)\n'),
    ('P10-leveo-fijo', 'Polestar/UI/GuideFrameTabs.lua',
     '\t\tlocal G = ns.Guides\n\t\tlocal x = 1\n\t\tfor i = 1, n do\n',
     '\t\tlocal G = ns.Guides\n\t\tlocal x = 1\n\t\t-- Mamba (PARCHES.md P10): the first leveling tab stays put (no close) while another tab is open.\n\t\tlocal fijo\n\t\tfor i = 1, n do if n >= 2 and not fijo and (tabs[i].category or "Leveling") == "Leveling" then fijo = i end end\n\t\tfor i = 1, n do\n'),
    ('P10-leveo-fijo', 'Polestar/UI/GuideFrameTabs.lua',
     '\t\t\tb.Bar:SetShown(b.psActive)\n',
     '\t\t\tb.Bar:SetShown(b.psActive)\n\t\t\tb.psFijo = i == fijo or nil -- Mamba (PARCHES.md P10)\n\t\t\tb.Close:SetShown(not b.psFijo)\n'),
    ('P11-otra-pestana', 'Polestar/UI/Picker.lua',
     '\tif not (E and id) then return end\n\tif inNewTab and E.OpenTab then\n',
     '\tif not (E and id) then return end\n\t-- Mamba (PARCHES.md P11): another kind of guide (cooking, a dungeon...) never replaces the leveling guide: it opens\n\t-- in a new tab.\n\tif not inNewTab and E.OpenTab and E.GetGuide then\n\t\tlocal cur, new = E.GetGuide(), ns.Guides and ns.Guides.Get and ns.Guides.Get(id)\n\t\tif cur and new and (cur.category or "Leveling") == "Leveling" and (new.category or "Leveling") ~= "Leveling" then inNewTab = true end\n\tend\n\tif inNewTab and E.OpenTab then\n'),
    ('P12-pie', 'Polestar/Theme/Widgets.lua',
     '\t\tplace(bottom[k], i, y, true)\n\t\ty = y + RAIL_ROW\n',
     '\t\tplace(bottom[k], i, y, true)\n\t\tlocal pb = f.railButtons[i] -- Mamba (P12-riel): el pie siempre a tamaño completo, con su nombre\n\t\tpb:SetHeight(RAIL_ROW); pb.Label:SetShown(true); pb.Icon:ClearAllPoints(); pb.Icon:SetPoint("TOP", pb, "TOP", 0, -10)\n\t\ty = y + RAIL_ROW\n'),
    ('P14-no-vender', 'Polestar/QoL/Vendor.lua',
     "\tif Client.SlotQuest(bag, slot) then return nil end -- a quest's item or a quest starter (#1557)\n",
     "\tif Client.SlotQuest(bag, slot) then return nil end -- a quest's item or a quest starter (#1557)\n\t-- Mamba (PARCHES.md P14): nothing Mamba says not to sell (Forever mechanics like the sleeping bag, keys,\n\t-- quest items, bound utility) goes, even when marked as junk by hand.\n\tlocal mamba = _G.MambaAPI\n\tif mamba and mamba.NoVender and mamba.NoVender(id) then return nil end\n"),
    ('P15-prefijo', 'Polestar/Quests/Party.lua',
     'Party.PREFIX = "Polestar"\n',
     '-- Mamba (PARCHES.md P15): its own prefix. On "Polestar" the fork announced itself as Polestar 0.4.1 and the\n-- official Polestar in the party or guild said "X is on Polestar ...: your guides can differ" (18-11). With\n-- "Mamba", official clients never hear the fork nor the fork them; party sync runs among Mamba players only.\nParty.PREFIX = ns.mamba and "Mamba" or "Polestar"\n'),
    ('P15-prefijo', 'Polestar/Core/Update.lua',
     'U.PREFIX = "Polestar" -- Party.PREFIX\n',
     'U.PREFIX = ns.mamba and "Mamba" or "Polestar" -- Party.PREFIX; Mamba (PARCHES.md P15): its own prefix\n'),
    # P12: la ventana de Mamba (riel que se achica, encabezado Mamba, cuadro del objeto con lista, título por sección).
    ('P12-cuadro', 'Polestar/Theme/Widgets.lua',
     '\tif extra then extra(tip) end\n\ttip:Show()',
     '\t-- Mamba: extra puede llegar como lista de líneas (no solo como función): antes eso tiraba un error en cada pasada del ratón\n\tif type(extra) == "function" then extra(tip)\n\telseif type(extra) == "table" then for _, l in ipairs(extra) do tip:AddLine(tostring(l), 0.76, 0.79, 0.87, true) end end\n\ttip:Show()'),
    ('P12-encabezado', 'Polestar/Theme/Widgets.lua',
     '\tf.Tagline:SetText(opts.tagline or L["A community project"])\n\tif opts.headerSearch then',
     '\tf.Tagline:SetText(opts.tagline or L["A community project"])\n\t-- Mamba (Cristian, 18-11): POLESTAR y "Un proyecto comunitario" quedan como siempre; debajo, "Mamba" en el tono\n\t-- de la mamba negra (gris casi negro con brillo verde oliva). La serpiente animada que rodea POLESTAR y termina\n\t-- en esta palabra es K63 (MAMBA_ACEPTACION.md): f.MambaMarca es su punto final.\n\tf.MambaMarca = W.Text(side, "label", "text")\n\tf.MambaMarca:SetPoint("TOPLEFT", f.Tagline, "TOPLEFT", 0, -16)\n\tf.MambaMarca:SetText("Mamba")\n\tW.Uncolor(f.MambaMarca)\n\tf.MambaMarca:SetTextColor(0.55, 0.62, 0.42) -- verde oliva del brillo de la mamba\n\tif f.MambaMarca.SetShadowColor then f.MambaMarca:SetShadowColor(0.05, 0.06, 0.05, 1); f.MambaMarca:SetShadowOffset(1, -1) end\n\tif opts.headerSearch then'),
    ('P12-riel', 'Polestar/Theme/Widgets.lua',
     "\ty = f.psNavTop -- the first section level with the sidebar's first row\n\tfor k = 1, #items do\n\t\tif y + RAIL_ROW > limit then break end\n\t\ti = i + 1\n\t\tn = n + 1\n\t\tplace(items[k], i, y)\n\t\ty = y + RAIL_ROW\n\tend",
     '\ty = f.psNavTop -- the first section level with the sidebar\'s first row\n\t-- Mamba: when the sections don\'t fit at full height, the rows shrink (down to 30); under 44 the label\n\t-- hides and the name shows on hover (b.psTip). Before, the sections that didn\'t fit were simply cut.\n\tlocal room = limit - y\n\tlocal row = RAIL_ROW\n\tif #items > 0 and room < #items * RAIL_ROW then\n\t\t-- no caben: empiezan más arriba (bajo el emblema) y las filas se achican, hasta 26\n\t\ty = math.min(y, 96)\n\t\troom = limit - y\n\t\trow = math.max(26, math.min(RAIL_ROW, math.floor(room / #items)))\n\tend\n\tfor k = 1, #items do\n\t\tif y + row > limit then break end\n\t\ti = i + 1\n\t\tn = n + 1\n\t\tplace(items[k], i, y)\n\t\tlocal b = f.railButtons[i]\n\t\tb:SetHeight(row)\n\t\tlocal compact = row < 44\n\t\tb.Label:SetShown(not compact)\n\t\tb.Icon:ClearAllPoints()\n\t\tif compact then b.Icon:SetPoint("CENTER", b, "CENTER", 0, 0) else b.Icon:SetPoint("TOP", b, "TOP", 0, -10) end\n\t\ty = y + row\n\tend'),
    ('P12-titulo', 'Polestar/UI/Picker.lua',
     '\tW.ShellTabs(win, nil)\n\ts.render()',
     '\tW.ShellTabs(win, nil)\n\t-- Mamba: el título de la sección por defecto (su nombre); antes quedaba el de la sección anterior si la\n\t-- nueva no ponía el suyo ("Mejorar mi equipo" en Mi plan).\n\tW.ShellTitle(win, s.label or s.key, "")\n\ts.render()'),
    # P13 (K100, Mamba_Panel/Misiones.lua): Calabozos › Misiones con lo que falta y «Guíame».
    ('P13-misiones', 'Polestar/UI/Dungeons.lua',
     '\t\tb.ChainXP:SetPoint("TOPLEFT", b, "TOPLEFT", x, -p.more)\n\tend\n\tb:Show()\nend',
     '\t\tb.ChainXP:SetPoint("TOPLEFT", b, "TOPLEFT", x, -p.more)\n\tend\n\t-- Mamba (PARCHES.md P13): K100, what is still to do and «Guíame» (Mamba_Panel/Misiones.lua).\n\tif UI.MambaMision then pcall(UI.MambaMision, b, q, key, state, target, tlabel, fin) end\n\tb:Show()\nend'),
    # P14 (Mamba_Panel, prueba de la coordinadora 18-11): la facción de una misión de mazmorra desde el Codex.
    ('P14-faccion', 'Polestar/Dungeons/Dungeons.lua',
     '\tp.attunement = p.attunement or {}\n\tlocalisePage(p)\n\topenKey, openPage = key, p\n\treturn p\nend',
     '\tp.attunement = p.attunement or {}\n\t-- Mamba (PARCHES.md P14): a quest the page gives no side takes the Codex\'s (Raleigh\'s "In the Name of the\n\t-- Light" is Alliance), so the faction filter leaves it out for the Horde, its chains too.\n\tlocal Cx = ns.Codex\n\tif Cx and Cx.Quest then\n\t\tfor _, list in ipairs({ p.quests, p.chain }) do\n\t\t\tfor _, q in pairs(list) do\n\t\t\t\tif type(q) == "table" and q.faction == nil and q.id then\n\t\t\t\t\tlocal ok, r = pcall(Cx.Quest, q.id)\n\t\t\t\t\tif ok and type(r) == "table" and (r.faction == "A" or r.faction == "H") then q.faction = r.faction end\n\t\t\t\tend\n\t\t\tend\n\t\tend\n\tend\n\tlocalisePage(p)\n\topenKey, openPage = key, p\n\treturn p\nend'),
]

# Parches al código de forge (la herramienta de Polestar que construye los datos), relativos a la raíz.
PARCHES_FORGE = [
    ("P6-kb", "rust/crates/forge-data/src/kb.rs",
     '\t\tlet Some(s0) = steps.iter().find(|x| x.get("n").to_js_string() == *n) else { return Err(format!("mechanics correction: no step {n} to correct")) };',
     '\t\tlet Some(s0) = steps.iter().find(|x| x.get("n").to_js_string() == *n) else {\n\t\t\t// Mamba (PARCHES.md P6): sin QuestieDB/EG Link/forever-vo una misión puede quedar sin el paso que la\n\t\t\t// corrección pública corrige; con POLESTAR_KB_SKIP_MISSING_STEPS=1 se avisa y se sigue.\n\t\t\tif std::env::var_os("POLESTAR_KB_SKIP_MISSING_STEPS").is_some() {\n\t\t\t\teprintln!("forge: mechanics correction: no step {n} to correct (skipped, POLESTAR_KB_SKIP_MISSING_STEPS)");\n\t\t\t\tcontinue;\n\t\t\t}\n\t\t\treturn Err(format!("mechanics correction: no step {n} to correct"));\n\t\t};'),
    ("P5-idioma", "rust/crates/forge-gamedata/src/lib.rs",
     '\tpub fn db2_bytes(&self, table: &str, locale: &str) -> Result<blte::Decoded, String> {\n\t\tlet flag',
     '\tpub fn db2_bytes(&self, table: &str, locale: &str) -> Result<blte::Decoded, String> {\n\t\t// Mamba (PARCHES.md P5): a client installed in another text language (esMX) lacks the enUS\n\t\t// copy of a table. With POLESTAR_TEXT_LOCALE_FALLBACK=esMX[,..] the first installed copy is\n\t\t// read instead, with a warning; without it nothing changes.\n\t\tmatch self.db2_bytes_at(table, locale) {\n\t\t\tErr(e) => {\n\t\t\t\tif let Ok(alt) = std::env::var("POLESTAR_TEXT_LOCALE_FALLBACK") {\n\t\t\t\t\tfor l in alt.split(\',\').map(str::trim).filter(|l| !l.is_empty() && *l != locale) {\n\t\t\t\t\t\tif let Ok(d) = self.db2_bytes_at(table, l) {\n\t\t\t\t\t\t\teprintln!("forge: {table}: no {locale} copy installed; read the {l} copy (POLESTAR_TEXT_LOCALE_FALLBACK)");\n\t\t\t\t\t\t\treturn Ok(d);\n\t\t\t\t\t\t}\n\t\t\t\t\t}\n\t\t\t\t}\n\t\t\t\tErr(e)\n\t\t\t}\n\t\t\tok => ok,\n\t\t}\n\t}\n\n\tfn db2_bytes_at(&self, table: &str, locale: &str) -> Result<blte::Decoded, String> {\n\t\tlet flag'),
    ("P7-forever-db", "rust/crates/forge-data/src/lib.rs",
     'pub mod jsv;\npub mod kb;',
     'pub mod jsv;\npub mod kb;\n/// Mamba (PARCHES.md P7): forever-db\'s quests in a build without QuestieDB.\npub mod mamba_foreverdb;'),
    ("P7-forever-db", "rust/crates/forge-data/src/build.rs",
     '\tlap("questie merge");\n',
     '\tlap("questie merge");\n\t// Mamba (PARCHES.md P7): without QuestieDB, Forever\'s own quests (and the npcs, objects and items\n\t// they name) from forever-db, with POLESTAR_FOREVER_DB_QUESTS=1; without it nothing changes.\n\tif qz.is_none() && std::env::var_os(crate::mamba_foreverdb::ENV).is_some() {\n\t\tcrate::mamba_foreverdb::apply(&o.root, &norm.quests, &norm.npcs, &norm.objects, &norm.items, log)?;\n\t}\n'),
]

# Las pruebas de Polestar que fijan esos mismos valores (rutas relativas a la raíz del repositorio).
PARCHES_PRUEBAS = [
    ("P1-errores", "tests/ui-report.test.js",
     "const INVITE = 'https://discord.gg/polestar';",
     f"const INVITE = '{REPO}/issues'; // Mamba (PARCHES.md P1)"),
    ("P1-errores", "tests/ui-report.test.js",
     "assert.equal(url.origin + url.pathname, 'https://github.com/fitzforge/polestar/issues/new');",
     f"assert.equal(url.origin + url.pathname, '{REPO}/issues/new'); // Mamba (PARCHES.md P1)"),
    ("P1-errores", "rust/crates/forge-addontest/tests/addontest/ui-welcome.rs",
     'json!({ "link": "discord.gg/polestar",',
     'json!({ "link": "github.com/cstamigo-droid/Mamba/issues", /* Mamba (PARCHES.md P1) */'),
    ("P2-version", "rust/crates/forge-addontest/tests/addontest/ui-update.rs",
     '"link": "https://github.com/fitzforge/polestar/releases/tag/v0.3.7"',
     f'"link": "{REPO}/releases/tag/v0.3.7" /* Mamba (PARCHES.md P2) */'),
    ("P3-tomtom", "rust/crates/forge-addontest/tests/addontest/nav-journey.rs",
     'assert_eq!(out[0], json!({ "tomtom": true, "answering": false, "way": true, "default": false }));',
     '// Mamba (PARCHES.md P3): on by default, so the stand-in and /way answer.' + LF +
     '\tassert_eq!(out[0], json!({ "tomtom": false, "answering": true, "way": false, "default": true }));'),
]

TITULO = re.compile(r"^(## Title(?:-\w+)?: )([^\r\n]*?)(?: · Mamba)?(\r?)$", re.M)
MARCA = re.compile(r"^## X-Mamba:[^\r\n]*", re.M)


CATEGORIA = re.compile(r"^## Category(?:-\w+)?:[^\r\n]*\r?\n", re.M)
CATEGORIAS = ("## Category: Mamba", "## Category-esMX: Mamba", "## Category-esES: Mamba")
TITULO_PRINCIPAL = "Mamba (guías · Polestar)"


def con_categoria(texto: str) -> str:
    """P4b (18-11): todo lo de Mamba en una sola categoría "Mamba" de la lista de Accesorios (Cristian no
    encontraba Mamba: Polestar estaba en "Polestar" y lo propio sin categoría)."""
    texto = CATEGORIA.sub("", texto)
    lineas = texto.splitlines(keepends=True)
    ultimo = max(i for i, l in enumerate(lineas) if l.startswith("## ") and not l.startswith("## X-Mamba:"))
    fin = CR + LF if lineas[ultimo].endswith(CR + LF) else LF
    for k, c in enumerate(CATEGORIAS):
        lineas.insert(ultimo + 1 + k, c + fin)
    return "".join(lineas)


def _toc(texto: str, nombre: str = "") -> str:
    """P4: título "… · Mamba" (el principal, "Mamba (guías · Polestar)"), categoría "Mamba" y la marca
    X-Mamba (aviso de modificación, GPL-3.0 §5a)."""
    if nombre == "Polestar":
        texto = re.sub(r"^(## Title(?:-\w+)?: )[^\r\n]*?(\r?)$", lambda m: f"{m.group(1)}{TITULO_PRINCIPAL}{m.group(2)}", texto, flags=re.M)
    else:
        texto = TITULO.sub(lambda m: f"{m.group(1)}{m.group(2)} · Mamba{m.group(3)}", texto)
    texto = con_categoria(texto)
    marca = f"## X-Mamba: fork de Polestar, modificado {FECHA} ({REPO}). No es el Polestar oficial."
    if MARCA.search(texto):
        return texto  # ya avisado: se conserva la fecha en que se aplicó
    lineas = texto.splitlines(keepends=True)
    ultimo = max(i for i, l in enumerate(lineas) if l.startswith("## "))
    fin = CR + LF if lineas[ultimo].endswith(CR + LF) else LF
    lineas.insert(ultimo + 1, marca + fin)
    return "".join(lineas)


def _con_fin(texto_archivo: str, s: str) -> str:
    """El texto del parche con los saltos de línea del archivo."""
    return s.replace(LF, CR + LF) if CR + LF in texto_archivo else s


def aplicar(solo_revisar: bool) -> int:
    faltan, cambiados = [], []
    todos = [(pid, ADDON / rel, viejo, nuevo) for pid, rel, viejo, nuevo in PARCHES]
    todos += [(pid, RAIZ / rel, viejo, nuevo) for pid, rel, viejo, nuevo in PARCHES_PRUEBAS]
    todos += [(pid, RAIZ / rel, viejo, nuevo) for pid, rel, viejo, nuevo in PARCHES_FORGE]
    for pid, p, viejo, nuevo in todos:
        rel = p.relative_to(RAIZ).as_posix()
        t = p.read_bytes().decode("utf-8")
        viejo, nuevo = _con_fin(t, viejo), _con_fin(t, nuevo)
        if nuevo in t:
            continue
        if t.count(viejo) != 1:
            faltan.append(f"{pid} {rel}: el texto original aparece {t.count(viejo)} veces; revisar a mano")
            continue
        if solo_revisar:
            faltan.append(f"{pid} {rel}: sin aplicar")
            continue
        p.write_bytes(t.replace(viejo, nuevo).encode("utf-8"))
        cambiados.append(f"{pid} {rel}")
    for toc in sorted(ADDON.glob("Polestar*/Polestar*.toc")):
        t = toc.read_bytes().decode("utf-8")
        n = _toc(t, toc.stem)
        if n != t:
            if solo_revisar:
                faltan.append(f"P4-toc {toc.relative_to(ADDON).as_posix()}: sin aplicar")
            else:
                toc.write_bytes(n.encode("utf-8"))
                cambiados.append(f"P4-toc {toc.relative_to(ADDON).as_posix()}")
    for c in cambiados:
        print("aplicado:", c)
    for f in faltan:
        print("FALTA:", f)
    print(f"{len(cambiados)} aplicados, {len(faltan)} pendientes")
    return 1 if faltan else 0


if __name__ == "__main__":
    sys.exit(aplicar("--revisar" in sys.argv))
