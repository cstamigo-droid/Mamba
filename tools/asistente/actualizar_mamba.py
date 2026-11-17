"""Mamba se actualiza sola cuando Polestar publica una versión (pedido de Cristian, 17-11 20:20: "que sea todo
automático, y que si falla nosotros metamos mano"). SIN Claude: lo lanza el Programador de tareas de Windows.

    python -I tools/asistente/actualizar_mamba.py                corrida normal (la de la tarea programada)
    python -I tools/asistente/actualizar_mamba.py --prueba --addons D:/rust/prueba_addons
        prueba de punta a punta sobre una carpeta de instalación de PRUEBA (los avisos dicen [PRUEBA])
    ... --forzar-fallo ETAPA     la etapa ETAPA falla a propósito (probar la alerta y que nada quede tocado)
    ... --sin-construir          salta la construcción (probar instalar con lo ya construido)

Etapas, cada una con su criterio de éxito MEDIDO POR EFECTO (no por el código de salida):
  recuperar   si una corrida anterior murió a mitad de instalar (diario de instalación o carpetas *.mamba_vieja),
              vuelve a poner lo viejo, lo comprueba y avisa. Va ANTES de leer la versión instalada.
  versiones   última publicada (GitHub) contra la INSTALADA (Polestar.toc). Igual o más nueva → nada, sin aviso.
  fusion      seguir_polestar.sh --preparar vX: la etiqueta dentro de fusion/vX, registro LISTO y 0 pruebas falladas.
              Si vX ya está construida en la copia (marca con el commit), se reusa y no se rehace.
  construir   seguir_polestar.sh --construir (con caché, ~1,5 h): estado LISTO escrito DESPUÉS de empezar y guías
              regeneradas. Con forge o el juego ocupados: ESPERA (no es un fallo; la próxima corrida reintenta).
  controles   incluidos.py revisar: 0 errores.
  respaldo    (recién con el juego cerrado) zip de las carpetas que se van a cambiar o quitar; se relee y se cuenta.
  instalar    diario en disco → por carpeta: copia al lado, compara sha256 con la fuente, mira que el juego siga
              cerrado y cambia. Quita las carpetas de Polestar que la versión nueva eliminó. Comprueba TODO antes de
              borrar las copias viejas. Si algo falla, vuelve atrás carpeta por carpeta (sigue aunque una falle).
Avisos por Telegram (notificador de OLIMPO): "Mamba actualizada a vX" o "falló en <etapa>, registro en <ruta>".
Un mismo fallo se avisa una vez (y otra vez a las 24 h si sigue); un aviso que Telegram no aceptó se reintenta en la
corrida siguiente. Lo que necesita juicio (funciones nuevas, estética) NO frena: queda en polestar_versiones/vX.md.
Salida: 0 al día / actualizada / en espera · 1 falló · 3 otra corrida en curso.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

AQUI = Path(__file__).resolve().parent
REPO = Path(r"C:\Users\<usuario>\Mamba")
FUSION = Path(r"C:\Users\<usuario>\Mamba-fusion")
ADDONS_REAL = Path(r"C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns")
WOW = Path(r"C:\Users\<usuario>\OneDrive\Escritorio\WOW_FOREVER")
BASH = r"C:\Program Files\Git\bin\bash.exe"
OLIMPO_ALERTAS = Path(r"C:\Users\<usuario>\OneDrive\Escritorio\OLIMPO\ALERTAS")
CONSTRUCCION_ESTADO = Path("D:/rust/noche/ESTADO.txt")
COMPILAR_LOG = Path("D:/rust/noche/compilar.log")
CERROJO = Path("D:/rust/actualizar/EN_CURSO")  # uno solo para la tarea y las pruebas: comparten Mamba-fusion
# Qué se instala: las carpetas de Mamba y los addons incluidos, siempre; las de Polestar que ya están instaladas
# (se respeta lo que el jugador eligió: un idioma o una apariencia que no instaló no se le agrega) y las que la
# versión nueva trae y la instalada no tenía (Polestar_Arcade llegó en 0.4.1).
SIEMPRE = re.compile(r"^(Asistente.*|Tasador|Medidor|SkillUpForever|ForeverCore|WhatsTraining|ForeverLootSparkles)$")
VIEJA, NUEVA = ".mamba_vieja", ".mamba_nueva"


class Espera(Exception):
    """No es un fallo: falta una condición (juego abierto, forge ocupado). La próxima corrida reintenta."""


class Fallo(Exception):
    pass


def huellas(raiz: Path):
    return {p.relative_to(raiz).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in raiz.rglob("*") if p.is_file()}


class Corrida:
    def __init__(self, a):
        self.a = a
        self.addons = Path(a.addons) if a.addons else ADDONS_REAL
        self.dir = Path(a.estado or ("D:/rust/actualizar_prueba" if a.prueba else "D:/rust/actualizar"))
        self.dir.mkdir(parents=True, exist_ok=True)
        self.log = self.dir / f"registro_{dt.datetime.now():%Y-%m-%d_%H%M}.log"
        self.diario = self.addons / "Mamba_instalando.json"  # en la MISMA carpeta: viaja con lo que describe
        self.etapa = "inicio"
        self.tag = None
        self.instalada = None

    # ------------------------------------------------------------------ utilidades
    def anota(self, texto):
        linea = f"[{dt.datetime.now():%H:%M:%S}] {texto}"
        print(linea)
        with open(self.log, "a", encoding="utf-8") as f:
            f.write(linea + "\n")

    def corre(self, args):
        self.anota("$ " + " ".join(str(x) for x in args))
        r = subprocess.run(args, capture_output=True)
        salida = (r.stdout + r.stderr).decode("utf-8", errors="replace")
        with open(self.log, "a", encoding="utf-8") as f:
            f.write(salida + "\n")
        return r.returncode, salida

    def forzar(self, etapa):
        if self.a.forzar_fallo == etapa:
            if etapa == "limpiar":  # simula que el proceso MUERE (corte de luz): sin avisos ni limpieza propia
                self.anota("MUERTE SIMULADA durante la limpieza (prueba)")
                os._exit(9)
            raise Fallo(f"fallo forzado a propósito en «{etapa}» (prueba)")

    def escribir_diario(self, d):
        """De una sola vez: un corte a mitad no deja un diario roto (temporal + reemplazo atómico)."""
        tmp = self.diario.with_suffix(".tmp")
        tmp.write_text(json.dumps(d), encoding="utf-8")
        os.replace(tmp, self.diario)

    def mandar(self, texto) -> bool:
        if self.a.sin_aviso:
            self.anota("(sin aviso) " + texto)
            return True
        os.environ["OLIMPO_TG_REAL"] = "1"  # tarea programada: manda de verdad (OLIMPO/ALERTAS/notify.py)
        try:
            if str(OLIMPO_ALERTAS) not in sys.path:
                sys.path.insert(0, str(OLIMPO_ALERTAS))
            import notify  # noqa: E402
            ok = bool(notify.cristian(texto))  # devuelve False si Telegram no lo aceptó: NO lanza excepción
        except Exception as e:
            self.anota(f"error del notificador: {e}")
            ok = False
        self.anota(("AVISADO: " if ok else "NO PUDE AVISAR (se reintenta en la próxima corrida): ") + texto)
        return ok

    def avisar(self, texto, clave=None):
        """clave: el mismo fallo no se repite cada 2 h (sí a las 24 h). Lo que no salió queda en pendiente."""
        texto = ("[PRUEBA] " if self.a.prueba else "") + texto
        marcas = self.dir / "avisos.json"
        try:
            m = json.loads(marcas.read_text(encoding="utf-8"))
        except Exception:
            m = {}
        ahora = dt.datetime.now().timestamp()
        if clave and m.get(clave, 0) > ahora - 24 * 3600:
            self.anota(f"(aviso ya dado, no se repite) {texto}")
            return
        if self.mandar(texto):
            if clave:
                m[clave] = ahora
                marcas.write_text(json.dumps(m), encoding="utf-8")
        else:  # queda pendiente UNA vez por clave (sin Telegram un día entero no se juntan 12 iguales)
            pend = self.dir / "avisos_pendientes.json"
            try:
                d = json.loads(pend.read_text(encoding="utf-8"))
            except Exception:
                d = {}
            d[clave or texto] = texto
            pend.write_text(json.dumps(d, ensure_ascii=False), encoding="utf-8")

    def reintentar_avisos(self):
        p = self.dir / "avisos_pendientes.json"
        if not p.exists():
            return
        try:
            d = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            d = {}
        quedan, marcas = {}, self.dir / "avisos.json"
        try:
            m = json.loads(marcas.read_text(encoding="utf-8"))
        except Exception:
            m = {}
        for k, t in d.items():
            if self.mandar(t):
                m[k] = dt.datetime.now().timestamp()  # ya dado: si el mismo fallo sigue, no sale dos veces
            else:
                quedan[k] = t
        marcas.write_text(json.dumps(m), encoding="utf-8")
        if quedan:
            p.write_text(json.dumps(quedan, ensure_ascii=False), encoding="utf-8")
        else:
            p.unlink()

    def estado(self, texto):
        (self.dir / "ESTADO.txt").write_text(f"{dt.datetime.now():%Y-%m-%d %H:%M} {texto}\n", encoding="utf-8")

    @staticmethod
    def corriendo(exe):
        r = subprocess.run(["tasklist", "/FI", f"IMAGENAME eq {exe}"], capture_output=True)
        if r.returncode != 0:  # si no se pudo mirar, se asume que SÍ corre (nunca instalar a ciegas)
            return True
        return exe.lower() in r.stdout.decode("utf-8", errors="replace").lower()

    def juego_abierto(self):
        return self.corriendo("Wow.exe") and not self.a.ignorar_juego

    # ------------------------------------------------------------------ etapas
    def recuperar(self):
        """Una corrida anterior murió a mitad de instalar: lo viejo vuelve a su lugar."""
        self.etapa = "recuperar"
        viejas = sorted(self.addons.glob("*" + VIEJA))
        nuevas = sorted(self.addons.glob("*" + NUEVA))
        if not (viejas or nuevas or self.diario.exists()):
            return
        if self.juego_abierto():
            raise Espera("hay una instalación cortada para recuperar, pero el juego está abierto")
        try:
            d = json.loads(self.diario.read_text(encoding="utf-8")) if self.diario.exists() else {}
        except Exception:
            d = {}
        errores = []
        if d.get("fase") == "limpiando":
            # La instalación ya estaba COMPROBADA completa y se cortó al borrar lo viejo: se termina hacia adelante.
            self.anota(f"TERMINANDO la limpieza de una instalación ya comprobada: {len(viejas)} carpetas viejas")
            for v in viejas:
                try:
                    shutil.rmtree(v)
                except Exception as e:
                    errores.append(f"{v.name}: {e}")
            for n in nuevas:
                shutil.rmtree(n, ignore_errors=True)
            if errores:  # la instalación está bien: no es un "falló"; se reintenta borrar en la próxima corrida
                self.anota("quedan copias viejas por borrar: " + "; ".join(errores[:5]))
                return
            self.diario.unlink(missing_ok=True)
            # el proceso que instaló murió antes de avisar: el aviso de éxito sale ahora (misma clave: no se repite)
            if d.get("tag"):
                self.avisar(f"Mamba actualizada a {d['tag']} (la corrida que instaló se cortó al final; ya quedó limpia).",
                            clave=f"exito_{d['tag']}")
            return
        self.anota(f"RECUPERANDO una instalación cortada: {len(viejas)} carpetas viejas, {len(nuevas)} a medio copiar")
        # las carpetas que la instalación cortada AGREGÓ (no existían antes) se quitan
        for c in d.get("agregadas", []):
            dst = self.addons / c
            if dst.is_dir() and not (self.addons / (c + VIEJA)).exists():
                try:
                    shutil.rmtree(dst)
                except Exception as e:
                    errores.append(f"{c}: {e}")
        for v in viejas:
            dst = self.addons / v.name[: -len(VIEJA)]
            try:
                if dst.exists():
                    shutil.rmtree(dst)
                v.rename(dst)
            except Exception as e:
                errores.append(f"{dst.name}: {e}")
        for n in nuevas:
            try:
                shutil.rmtree(n)
            except Exception as e:
                errores.append(f"{n.name}: {e}")
        if errores or list(self.addons.glob("*" + VIEJA)):
            raise Fallo("no pude recuperar la instalación cortada: " + "; ".join(errores[:5]))
        self.diario.unlink(missing_ok=True)
        self.avisar("Mamba: una actualización se había cortado a mitad de instalar. Volví a poner la versión "
                    "anterior completa. La próxima corrida intenta de nuevo.")

    def versiones(self):
        self.etapa = "versiones"
        sys.path.insert(0, str(AQUI / "generador"))
        import polestar_al_dia as v  # noqa: E402
        ultima = self.a.version or v.ultima_version()
        toc = self.addons / "Polestar" / "Polestar.toc"
        m = re.search(r"^## Version:\s*(\S+)", toc.read_text(encoding="utf-8", errors="replace"), re.M) if toc.exists() else None
        self.instalada = re.sub(r"-asistente.*$", "", m.group(1)) if m else None
        self.anota(f"última publicada {ultima} · instalada {self.instalada or 'ninguna'} · carpeta {self.addons}")
        if not self.instalada:
            raise Fallo(f"no encuentro Polestar instalado en {self.addons}")
        # Si lo instalado es Polestar OFICIAL (sin la marca X-Mamba en Polestar.toc: CurseForge o Polestar Client lo
        # reemplazaron, MAMBA.md), hay que poner Mamba aunque el número de versión sea el mismo.
        if "X-Mamba" not in toc.read_text(encoding="utf-8", errors="replace"):
            self.anota("lo instalado es Polestar OFICIAL (sin X-Mamba): se instala Mamba")
            return ultima if v.numeros(ultima) >= v.numeros(self.instalada) else None
        return ultima if v.numeros(ultima) > v.numeros(self.instalada) else None

    def marca_construida(self):
        return self.dir / f"construida_{self.tag}.json"

    def ya_construida(self):
        mc = self.marca_construida()
        if not mc.exists():
            return False
        head = subprocess.run(["git", "-C", str(FUSION), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
        limpio = not subprocess.run(["git", "-C", str(FUSION), "status", "--porcelain"], capture_output=True, text=True).stdout.strip()
        return json.loads(mc.read_text(encoding="utf-8")).get("commit") == head and limpio

    def fusion(self):
        self.etapa = "fusion"
        self.forzar("fusion")
        _, salida = self.corre([BASH, str(AQUI / "seguir_polestar.sh"), "--preparar", self.tag])
        if "ESTADO: OCUPADO" in salida:
            raise Espera("otra corrida de seguir_polestar.sh está trabajando")
        rlog = Path("D:/rust/seguir") / f"fusion_{self.tag}.log"
        texto = rlog.read_text(encoding="utf-8", errors="replace") if rlog.exists() else ""
        dentro = subprocess.run(["git", "-C", str(FUSION), "merge-base", "--is-ancestor", self.tag, "HEAD"]).returncode == 0
        rama = subprocess.run(["git", "-C", str(FUSION), "branch", "--show-current"], capture_output=True, text=True).stdout.strip()
        fallas = re.findall(r"ℹ fail [1-9]|FALLAS [1-9]|^ALTO", texto, re.M)
        if not (dentro and rama == f"fusion/{self.tag}" and "LISTO:" in texto and not fallas
                and "ESTADO: FUSIONADA Y PROBADA" in salida):
            raise Fallo(f"la fusión no quedó: etiqueta dentro={dentro}, rama={rama}, LISTO={'LISTO:' in texto}, "
                        f"fallas={fallas[:3]} (registro {rlog})")

    def construir(self):
        self.etapa = "construir"
        self.forzar("construir")
        if self.a.sin_construir:
            self.anota("construcción saltada (--sin-construir)")
            return
        if self.corriendo("forge.exe"):
            raise Espera("forge.exe está corriendo (otra construcción)")
        if self.juego_abierto():
            raise Espera("el juego está abierto: forge lee el cliente y el lanzador podría actualizarlo a mitad")
        inicio = dt.datetime.now().timestamp()
        _, salida = self.corre([BASH, str(AQUI / "seguir_polestar.sh"), "--construir"])
        if "ESTADO: OCUPADO" in salida:
            raise Espera("forge u otra corrida ocupados")
        est = CONSTRUCCION_ESTADO.read_text(encoding="utf-8", errors="replace") if CONSTRUCCION_ESTADO.exists() else ""
        if "NO CORRIÓ: el juego" in est:
            raise Espera("el juego se abrió antes de construir")
        nuevo = lambda p: p.exists() and p.stat().st_mtime > inicio  # noqa: E731
        guias = [p for p in (FUSION / "addon").glob("Polestar_Guides*/*.lua") if nuevo(p)]
        compilado = nuevo(COMPILAR_LOG) and COMPILAR_LOG.read_text(encoding="utf-8", errors="replace").rstrip().endswith("LISTO")
        if not (nuevo(CONSTRUCCION_ESTADO) and est.startswith("LISTO") and compilado and guias and "LISTA PARA INSTALAR" in salida):
            raise Fallo(f"la construcción no quedó: estado «{est.strip()[:80]}», compilado={compilado}, "
                        f"guías regeneradas={len(guias)} (registros en D:/rust/noche)")

    def controles(self):
        self.etapa = "controles"
        self.forzar("controles")
        _, salida = self.corre([sys.executable, "-I", str(FUSION / "tools/asistente/incluidos.py"), "revisar"])
        if not re.search(r"addons incluidos, 0 errores", salida):
            raise Fallo("un addon incluido no coincide con su huella: " + salida.strip()[-200:])

    def carpetas(self):
        """-> (a instalar, a quitar). A quitar: carpetas de Polestar instaladas que la versión nueva ya no trae."""
        fuente = FUSION / "addon"
        r = subprocess.run(["git", "-C", str(REPO), "ls-tree", "--name-only", f"v{self.instalada}:addon"], capture_output=True, text=True)
        if r.returncode != 0:
            raise Fallo(f"no pude leer las carpetas de la versión instalada v{self.instalada} en git: {r.stderr.strip()}")
        antes = set(r.stdout.split())
        nuevas = {p.name for p in fuente.iterdir() if p.is_dir() and any(p.glob("*.toc"))}
        instalar = sorted(d for d in nuevas if SIEMPRE.match(d) or (self.addons / d).is_dir() or d not in antes)
        quitar = sorted(d for d in antes - nuevas if d.startswith("Polestar") and (self.addons / d).is_dir())
        if "Polestar" not in instalar:
            raise Fallo("la lista de carpetas a instalar no trae Polestar")
        return instalar, quitar

    def respaldo(self, carpetas):
        self.etapa = "respaldo"
        self.forzar("respaldo")
        dest = (self.dir if self.a.prueba else WOW / "respaldos") / f"Mamba_antes_de_{self.tag}_{dt.datetime.now():%Y-%m-%d_%H%M}.zip"
        dest.parent.mkdir(parents=True, exist_ok=True)
        n = 0
        with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as z:
            for c in carpetas:
                if (self.addons / c).is_dir():
                    for p in (self.addons / c).rglob("*"):
                        if p.is_file():
                            z.write(p, p.relative_to(self.addons).as_posix())
                            n += 1
        with zipfile.ZipFile(dest) as z:
            malo, total = z.testzip(), len(z.namelist())
        if malo or total != n or n == 0:
            raise Fallo(f"el respaldo {dest} no se puede releer bien ({total} de {n} archivos, dañado={malo})")
        self.anota(f"respaldo: {dest} ({n} archivos)")
        # se guardan solo los 5 respaldos más nuevos de Mamba (cada uno ~40 MB)
        for viejo in sorted(dest.parent.glob("Mamba_antes_de_*.zip"), key=lambda p: p.stat().st_mtime)[:-5]:
            viejo.unlink(missing_ok=True)
        return dest

    def instalar(self, instalar, quitar):
        self.etapa = "instalar"
        diario = {"tag": self.tag, "desde": self.instalada, "instalar": instalar, "quitar": quitar, "fase": "cambiando",
                  "agregadas": [c for c in instalar if not (self.addons / c).exists()], "inicio": dt.datetime.now().isoformat()}
        self.escribir_diario(diario)
        hechas = []  # (carpeta, había vieja)
        try:
            for c in instalar + quitar:
                if self.juego_abierto():
                    raise Espera("el juego se abrió en medio de la instalación: se volvió atrás y se reintenta después")
                dst, nueva, vieja = self.addons / c, self.addons / (c + NUEVA), self.addons / (c + VIEJA)
                if nueva.exists():
                    shutil.rmtree(nueva)
                if c in instalar:
                    src = FUSION / "addon" / c
                    shutil.copytree(src, nueva)
                    if huellas(nueva) != huellas(src):
                        raise Fallo(f"la copia de {c} no coincide con la fuente")
                habia = dst.exists()
                if habia:
                    dst.rename(vieja)
                hechas.append((c, habia))
                if c in instalar:
                    nueva.rename(dst)
                self.forzar("instalar")  # cae DESPUÉS de cambiar una carpeta: prueba la vuelta atrás
            # comprobación de TODO antes de borrar lo viejo
            for c in instalar:
                if huellas(self.addons / c) != huellas(FUSION / "addon" / c):
                    raise Fallo(f"{c} instalada no coincide con la fuente")
            for c in quitar:
                if (self.addons / c).exists():
                    raise Fallo(f"{c} debía quitarse y sigue ahí")
            toc = (self.addons / "Polestar" / "Polestar.toc").read_text(encoding="utf-8", errors="replace")
            if not re.search(rf"^## Version:\s*{re.escape(self.tag.lstrip('v'))}(\s|$)", toc, re.M):
                raise Fallo("después de instalar, Polestar.toc no dice la versión nueva")
        except Exception:
            self.volver_atras(hechas)
            raise
        # Todo comprobado: desde aquí solo se avanza. Si la corrida muere borrando lo viejo, «recuperar» lo termina
        # (no vuelve atrás: eso mezclaría versiones).
        diario["fase"] = "limpiando"
        self.escribir_diario(diario)
        self.forzar("limpiar")
        restos = []
        for c, habia in hechas:
            if habia:
                try:
                    shutil.rmtree(self.addons / (c + VIEJA))
                except Exception as e:  # instalada y comprobada: no es un fallo; el diario queda y se termina después
                    restos.append(f"{c}: {e}")
        if restos:
            self.anota("quedan copias viejas por borrar (se terminan en la próxima corrida): " + "; ".join(restos[:5]))
        else:
            self.diario.unlink(missing_ok=True)

    def volver_atras(self, hechas):
        self.anota(f"VUELTA ATRÁS de {len(hechas)} carpetas")
        errores = []
        for c, habia in reversed(hechas):
            dst, vieja = self.addons / c, self.addons / (c + VIEJA)
            try:
                if dst.exists():
                    shutil.rmtree(dst)
                if habia:
                    vieja.rename(dst)
            except Exception as e:  # se sigue con las demás; lo que quede lo arregla «recuperar» la próxima vez
                errores.append(f"{c}: {e}")
        for p in self.addons.glob("*" + NUEVA):
            shutil.rmtree(p, ignore_errors=True)
        if errores:
            self.anota("la vuelta atrás no pudo con: " + "; ".join(errores))
        else:
            self.diario.unlink(missing_ok=True)

    def instaladas(self, carpetas):
        return {c: huellas(self.addons / c) for c in carpetas if (self.addons / c).is_dir()}

    # ------------------------------------------------------------------ corrida
    def ejecutar(self):
        antes = None
        try:
            self.reintentar_avisos()
            self.recuperar()
            self.tag = self.versiones()
            if not self.tag:
                self.estado("AL DÍA")
                self.anota("AL DÍA: nada que hacer")
                return 0
            if self.ya_construida():
                self.anota(f"{self.tag} ya está fusionada y construida en la copia: se reusa")
            else:
                self.fusion()
                self.construir()
                if not self.a.sin_construir:
                    head = subprocess.run(["git", "-C", str(FUSION), "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
                    self.marca_construida().write_text(json.dumps({"commit": head}), encoding="utf-8")
            self.controles()
            if self.juego_abierto():
                self.etapa = "instalar"
                raise Espera("el juego está abierto: se instala en la próxima corrida con el juego cerrado")
            instalar, quitar = self.carpetas()
            antes = self.instaladas(instalar + quitar)
            self.respaldo(instalar + quitar)
            self.instalar(instalar, quitar)
            self.estado(f"ACTUALIZADA a {self.tag}")
            self.avisar(f"Mamba actualizada a {self.tag} ({len(instalar)} carpetas"
                        + (f", {len(quitar)} quitadas porque Polestar ya no las trae" if quitar else "")
                        + f"). Lo nuevo de Polestar y la revisión de estética quedan para mirar con calma en "
                          f"polestar_versiones/{self.tag}.md.", clave=f"exito_{self.tag}")
            return 0
        except Espera as e:
            self.estado(f"EN ESPERA ({self.tag}): {e}")
            self.anota(f"EN ESPERA: {e}")
            if self.tag and self.etapa == "instalar":
                self.avisar(f"Mamba {self.tag} está lista para instalarse. Se instala sola en la próxima revisión "
                            f"(cada 2 horas) con el juego cerrado.", clave=f"espera_{self.tag}")
            return 0
        except Exception as e:
            if antes is not None:
                intacto = (" Lo instalado quedó como estaba." if self.instaladas(list(antes)) == antes
                           else " ⚠️ OJO: lo instalado NO quedó igual que antes; la próxima corrida intenta recuperarlo.")
            else:
                intacto = " No se tocó lo instalado."
            self.estado(f"FALLÓ en {self.etapa} ({self.tag}): {e}")
            self.anota(f"FALLÓ en {self.etapa}: {e}")
            self.avisar(f"Mamba {self.tag or ''}: falló en «{self.etapa}». {e}.{intacto} Registro: {self.log}",
                        clave=f"fallo_{self.tag}_{self.etapa}_{str(e)[:60]}")
            return 1


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser()
    p.add_argument("--addons", help="carpeta AddOns (por defecto la del juego)")
    p.add_argument("--estado", help="carpeta de registros y estado")
    p.add_argument("--version", help="tratar esta etiqueta como la última publicada (pruebas)")
    p.add_argument("--prueba", action="store_true", help="avisos marcados [PRUEBA]; respaldo en la carpeta de estado")
    p.add_argument("--forzar-fallo", choices=["fusion", "construir", "controles", "respaldo", "instalar", "limpiar"])
    p.add_argument("--sin-construir", action="store_true")
    p.add_argument("--sin-aviso", action="store_true", help="no mandar Telegram (solo registro)")
    p.add_argument("--ignorar-juego", action="store_true", help="solo con --prueba: instalar aunque el juego esté abierto")
    a = p.parse_args()
    if (a.ignorar_juego or a.forzar_fallo or a.sin_construir) and not (a.prueba and a.addons):
        p.error("--ignorar-juego, --forzar-fallo y --sin-construir solo valen con --prueba y una carpeta --addons de prueba")
    CERROJO.parent.mkdir(parents=True, exist_ok=True)
    if CERROJO.exists():  # de una corrida que murió (corte de luz): su proceso ya no existe, o pasaron 8 h
        m = re.search(r"pid (\d+)", CERROJO.read_text(encoding="utf-8", errors="replace"))
        vivo = False
        if m:
            r = subprocess.run(["tasklist", "/FI", f"PID eq {m.group(1)}"], capture_output=True)
            vivo = r.returncode != 0 or f" {m.group(1)} " in r.stdout.decode("utf-8", errors="replace")
        if not vivo or dt.datetime.now().timestamp() - CERROJO.stat().st_mtime > 8 * 3600:
            CERROJO.unlink(missing_ok=True)
    try:
        fd = os.open(CERROJO, os.O_CREAT | os.O_EXCL | os.O_WRONLY)  # crear-si-no-existe en un solo paso
    except FileExistsError:
        print("OCUPADO: otra corrida en curso desde", CERROJO.read_text(encoding="utf-8", errors="replace"))
        return 3
    os.write(fd, f"{dt.datetime.now():%Y-%m-%d %H:%M} pid {os.getpid()}".encode())
    os.close(fd)
    try:
        return Corrida(a).ejecutar()
    finally:
        CERROJO.unlink(missing_ok=True)


if __name__ == "__main__":
    sys.exit(main())
