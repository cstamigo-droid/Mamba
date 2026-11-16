# Medidor 0.2 — experiencia, oro y profesión por hora

Addon aparte del Tasador (carpeta `Medidor`). Solo **lee** el juego; no hace nada por ti.

## Por qué no se reusó lo que ya existe (revisado el 16-11)
- **Polestar** (`Polestar\QoL\XP.lua`) mide experiencia por hora de la sesión y por nivel, **sin zona, sin actividad, sin oro ni profesión**. La parte de experiencia del Medidor son ~5 líneas (`M.DeltaXP`); depender de Polestar para eso ataría el Medidor a otro addon.
- **Forever Hispano** (MIT) mide experiencia y oro por sesión (`ForeverHispano\Companion\Modules\Session.lua`) y registra saldo de oro y transacciones por personaje (`ForeverHispano\INVENTARIO-HERRAMIENTAS.txt`, puntos 29 y 44), **no por zona ni actividad, ni el valor del botín sin vender**.
- Lo nuevo del Medidor es lo que pide `ALCANCE.md` ("oro por hora medido de cada forma de ganar oro… nadie lo mide"): **dinero + valor del botín + profesión, separados por zona y actividad**, para comparar farmear, misiones, fabricar y subasta.
- Yield, ForeverSessionGold y Farmin' Forever (CurseForge): no revisados. Pendiente compararlos antes de publicar el Medidor.

## Instalar
Copiar la carpeta `addon\Medidor` a `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\`.

## Usar
| Comando | Qué hace |
|---|---|
| `/medidor` | Lo medido en esta sesión, por zona y actividad, y dónde estás |
| `/medidor todo` | Todo lo guardado de este personaje |
| `/medidor act farmeo` | Dice qué estás haciendo: misiones, farmeo, fabricar, subasta, mazmorra, jcj, otra. En mazmorras y campos de batalla se pone solo |
| `/medidor mejor` | Lo que más oro te deja **por hora de juego** (dinero + botín), de mayor a menor; en mazmorras también el oro **por pasada**. Solo lo que tenga 5 min o más |
| `/medidor pausa` | Para o reanuda el reloj |
| `/medidor borrar si` | Borra lo de este personaje |

## Qué mide
- **Tiempo**: solo cuando no estás en pausa ni ausente (AFK). Un salto largo (pantalla de carga) cuenta como máximo 5 s.
- **Experiencia**, también al subir de nivel (lo que faltaba + lo nuevo).
- **Dinero**: monedas que entran y que salen (reparar, entrenar, comprar).
- **Botín**: valor de lo que entra o sale de tus bolsas y de lo que llevas puesto. Precio = el mayor entre vendedor y subasta (Auctionator) menos 5 %. Mientras tengas una unidad, se usa el precio con que entró. Lo que haces con el banco abierto no cuenta.
- **Total = dinero + botín.** Es la cifra para comparar formas de ganar oro: si vendes al vendedor algo que valía más en subasta, el total baja (perdiste valor).
- **Puntos de profesión** por profesión.
- **Pasadas por mazmorra**: cada vez que entras a una. Si mueres y vuelves corriendo a la misma antes de 15 min, es la misma pasada; si el juego avisa que la reiniciaste, la próxima entrada es pasada nueva. Dentro de la mazmorra se usa el nombre de la instancia.
- Se separa por **zona + actividad + nivel**; los informes juntan los niveles.
- Con menos de 5 minutos no muestra "por hora" (no sería confiable).

Se guarda en `WTF\Account\<cuenta>\SavedVariables\Medidor.lua` (variable `MedidorDB`, un apartado por personaje).

## Límites conocidos
- Mandar cosas por correo a otro personaje cuenta como pérdida (y recibirlas como ganancia).
- Equipar una bolsa nueva en un hueco de bolsa la cuenta como pérdida (los huecos de bolsa no se leen).
- Comprar en la subasta: el dinero sale al comprar y el objeto suma cuando lo sacas del correo.
- Comer, beber o tomar pociones cuenta como pérdida de botín (es un costo real de esa actividad).
- En pausa no se suma nada. Estando ausente (AFK) el reloj se detiene, pero los primeros ~5 minutos antes de que el juego te marque ausente sí cuentan.
- Un objeto conserva el precio con que entró mientras lo tengas y hasta 3 días después; así, publicarlo en la subasta y recibirlo de vuelta no parece ganancia.
- Salir con la piedra de hogar y volver después de 15 min cuenta 2 pasadas de la misma copia.
- Las alas de una misma mazmorra que comparten nombre (Monasterio Escarlata, La Masacre, Stratholme) caen en el mismo apartado.
- Las bandas se cuentan como "mazmorra".
- Reparar en la ciudad después de una mazmorra cuenta en la ciudad, no en la mazmorra: el oro por pasada sale un poco más alto que el real.
- Para el detalle de cada pasada (bichos, muertes, rapidez) ya existe ForeverDungeonJournal (`Systems\RunLog.lua`), que reconoce cada copia de la mazmorra. El Medidor no lo repite.
- Si recargas (`/reload`) o entras al juego estando dentro de una mazmorra, esa pasada no se cuenta (no se sabe si ya estaba contada).
- Forever oculta algunos valores en combate ("secretos"); si la experiencia o el dinero llegan ocultos, se cuentan en la siguiente lectura normal.

## Funciones del juego que usa (todas aparecen en addons de Forever instalados)
`issecretvalue` (Polestar `Core\Compat.lua`), `GetInstanceInfo` e `INSTANCE_RESET_SUCCESS` (ForeverDungeonJournal `Systems\RunLog.lua`), `time`, `NUM_TOTAL_EQUIPPED_BAG_SLOTS`/`NUM_BAG_SLOTS`, `DEFAULT_CHAT_FRAME`, `SlashCmdList`, `UnitXP`, `UnitXPMax`, `GetMoney`, `GetRealZoneText`, `IsInInstance`, `UnitLevel`, `UnitName`, `GetRealmName`, `UnitIsAFK`, `GetProfessions`, `GetProfessionInfo` (Forever **no** tiene `GetSkillLineInfo`: lo dice `ForeverDungeonJournal\Core\Journal.lua`; `SkillUpForever` avisa que el número de profesión puede ser raro, el Medidor solo lo usa como etiqueta), `C_Container.GetContainerNumSlots`, `C_Container.GetContainerItemInfo`, `GetInventoryItemID`, `C_Item.GetItemInfo`, `C_Item.RequestLoadItemDataByID`, `Auctionator.API.v1.GetAuctionPriceByItemID`, `CreateFrame`.
Eventos: `PLAYER_XP_UPDATE`, `PLAYER_LEVEL_UP`, `PLAYER_MONEY`, `BAG_UPDATE_DELAYED`, `PLAYER_EQUIPMENT_CHANGED`, `BANKFRAME_OPENED`, `BANKFRAME_CLOSED`, `SKILL_LINES_CHANGED`, `CHAT_MSG_SKILL`, `ZONE_CHANGED_NEW_AREA`, `CHAT_MSG_SYSTEM` (solo para leer el aviso de reinicio), `PLAYER_ENTERING_WORLD`, `ADDON_LOADED`.

## Pruebas
```bash
python addon/pruebas/test_medidor.py addon/Medidor
```
Usa Lua 5.1 (lupa) y un juego falso (`pruebas/mock_medidor.lua`). Falta probarlo en el juego real.
