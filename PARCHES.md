# PARCHES.md: cambios de Mamba dentro de archivos de Polestar

Regla (ARQUITECTURA §13b): lo de Mamba va en carpetas propias. Dentro de los archivos de Polestar solo se hacen **estos** cambios, mínimos y anotados. Todos los aplica `tools/asistente/parches.py`, que se puede correr las veces que haga falta: si un parche ya está, no hace nada, y si Polestar cambió el texto original, falla y avisa.

**Después de cada fusión con una versión nueva de Polestar:**
```
python -I tools/asistente/parches.py            # vuelve a aplicar todo
python -I tools/asistente/parches.py --revisar  # 0 pendientes = listo
python -I tools/asistente/generados.py          # rehace GENERADOS.txt
```

| Id | Archivo | Qué cambia | Por qué |
|---|---|---|---|
| P1 | `addon/Polestar/Core/Init.lua` | `IssueURL` y `DiscordURL` apuntan a los issues de Mamba. Se agrega `ns.mamba`, que lee el campo `X-Mamba` del `.toc` | §13f.4: los errores del fork no deben llegarle al autor de Polestar. Mamba no tiene Discord: el enlace "Discord" de la ventana de errores abre los issues de Mamba |
| P2 | `addon/Polestar/Core/Update.lua`, `addon/Polestar/Quests/Party.lua` | `mine()` devuelve `nil` si es Mamba y `ReleaseURL` apunta a los releases de Mamba. En el grupo sigue diciendo "your guides can differ", pero sin "A newer version is out" | §13f.4: sin esto, Polestar compara su versión con la de otros jugadores y con Polestar Client, y pide "actualiza Polestar". Si el jugador hace caso, CurseForge **reemplaza el fork por el oficial**. Con `mine() = nil`, Mamba no avisa ni manda su versión por el canal de la hermandad ni por susurro. En el grupo sí la manda (`Party.EncodeHello`), porque es parte del protocolo de grupo de Polestar; lo que manda es la versión base ("0.4.0"). Las versiones nuevas de Polestar las vigila `polestar_al_dia.py` |
| P3 | `addon/Polestar/Nav/Journey.lua` | `nav.answerTomTom` pasa a `true` por defecto | §16, fila TomTom: con TomTom apagado, Polestar responde `/way` y la API de puntos de TomTom (`AddWaypoint`, etc.). Polestar lo trae apagado porque el reemplazo no tiene `TomTom.db`. Revisado el 16-11 con grep sobre **todos** los addons instalados en el juego de Cristian: fuera del propio TomTom, ninguno lee `TomTom.db` ni `TomTom.profile`. El jugador lo puede apagar en Opciones › Navegación |
| P4 | todos los `addon/Polestar*/Polestar*.toc` (41) | `## Title…` termina en "· Mamba" y se agrega `## X-Mamba: fork de Polestar, modificado AAAA-MM-DD (repo). No es el Polestar oficial.` | GPL-3.0 §5a: aviso de modificación con fecha, visible en la lista de addons del juego |

Pruebas de Polestar que fijan esos mismos valores y se ajustan junto con el parche (las aplica el mismo script):

| Id | Archivo | Qué cambia |
|---|---|---|
| P1 | `tests/ui-report.test.js` | `INVITE` y la URL del issue esperan los de Mamba |
| P1 | `rust/crates/forge-addontest/tests/addontest/ui-welcome.rs` | el texto del enlace es el de Mamba |
| P2 | `rust/crates/forge-addontest/tests/addontest/ui-update.rs` | el enlace del release es el de Mamba |
| P3 | `rust/crates/forge-addontest/tests/addontest/nav-journey.rs` | la prueba "off by default" espera encendido |

**No verificado:** las pruebas en Rust (`forge-addontest`), porque en este PC no hay Rust. Las de Node sí se corrieron (ver `MAMBA.md`, "Pruebas").

**Para proponerle a Polestar** (si los acepta, dejan de ser parches nuestros): P1 y P2 como un campo del `.toc` (por ejemplo `X-Fork`) que Polestar respete. P3 no, porque es una decisión de Mamba.
