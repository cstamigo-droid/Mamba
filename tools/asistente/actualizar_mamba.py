"""Mamba se actualiza sola cuando Polestar publica una versión (pedido de Cristian, 17-11 20:20: "que sea todo
automático, y que si falla nosotros metamos mano"). SIN Claude: lo lanza el Programador de tareas de Windows.

    python -I tools/asistente/actualizar_mamba.py                corrida normal (la de la tarea programada)
    python -I tools/asistente/actualizar_mamba.py --prueba --addons D:/rust/prueba_addons
        prueba de punta a punta sobre una carpeta de instalación de PRUEBA (los avisos dicen [PRUEBA])
    ... --forzar-fallo ETAPA     la etapa ETAPA falla a propósito (para probar la alerta y que nada se toque)
    ... --sin-construir          salta la construcción (solo para probar instalar con lo ya construido)

Etapas, cada una con su criterio de éxito MEDIDO POR EFECTO (no por el código de salida):
  versiones   última publicada (GitHub) contra la INSTALADA (Polestar.toc). Igual o más nueva → nada, sin aviso.
  fusion      seguir_polestar.sh --preparar vX: la etiqueta queda dentro de fusion/vX y el registro dice LISTO
              con 0 pruebas falladas.
  construir   seguir_polestar.sh --construir (con caché, ~1,5 h): ESTADO de la construcción = LISTO y escrito
              DESPUÉS de empezar, y las guías regeneradas después de empezar. Con forge o el juego ocupados: ESPERA.
  controles   incluidos.py revisar: 0 errores.
  respaldo    zip de las carpetas instaladas que se van a reemplazar; se relee y cuenta sus archivos.
  instalar    solo con Wow.exe cerrado (si no: ESPERA). Copia cada carpeta al lado, la compara archivo por
              archivo (sha256) con la fuente y recién entonces la cambia por la vieja. La versión instalada
              queda = vX. Si algo falla, vuelve a poner las carpetas viejas y lo comprueba.
Avisa por Telegram (notificador de OLIMPO): "Mamba actualizada a vX" o "falló en <etapa>, registro en <ruta>".
Lo que necesita juicio (funciones nuevas, estética) NO frena: queda en WOW_FOREVER/polestar_versiones/vX.md.
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
# Qué se instala: las carpetas propias de Mamba y los addons incluidos, siempre; las de Polestar que ya están
# instaladas (se respeta lo que el jugador eligió: un idioma o una apariencia que no instaló no se le agrega), y
# las que la versión nueva trae y la instalada no tenía (Polestar_Arcade llegó en 0.4.1: sin ella, falta una parte).
SIEMPRE = re.compile(r"^(Asistente.*|Tasador|Medidor|SkillUpForever|ForeverCore|WhatsTraining|ForeverLootSparkles)$")


class Espera(Exception):
    """No es un fallo: falta una condición (juego abierto, forge ocupado). La próxima corrida reintenta."""


class Fallo(Exception):
    pass


class Corrida:
    def __init__(self, a):
        self.a = a
        self.addons = Path(a.addons) if a.addons else ADDONS_REAL
        self.dir = Path(a.estado or ("D:/rust/actualizar_prueba" if a.prueba else "D:/rust/actualizar"))
        self.dir.mkdir(parents=True, exist_ok=True)
        self.log = self.dir / f"registro_{dt.datetime.now():%Y-%m-%d_%H%M}.log"
        self.etapa = "inicio"
        self.tag = None

    # ------------------------------------------------------------------ utilidades
    def anota(self, texto):
        linea = f"[{dt.datetime.now():%H:%M:%S}] {texto}"
        print(linea)
        with open(self.log, "a", encoding="utf-8") as f:
            f.write(linea + "\n")

    def corre(self, args, **kw):
        self.anota("$ " + " ".join(str(x) for x in args))
        r = subprocess.run(args, capture_output=True, **kw)
        salida = (r.stdout + r.stderr).decode("utf-8", errors="replace")
        with open(self.log, "a", encoding="utf-8") as f:
            f.write(salida + "\n")
        return r.returncode, salida

    def forzar(self, etapa):
        if self.a.forzar_fallo == etapa:
            raise Fallo(f"fallo forzado a propósito en «{etapa}» (prueba)")

    def avisar(self, texto):
        texto = ("[PRUEBA] " if self.a.prueba else "") + texto
        self.anota("AVISO: " + texto)
        if self.a.sin_aviso:
            return
        os.environ["OLIMPO_TG_REAL"] = "1"  # tarea programada: manda de verdad (OLIMPO/ALERTAS/notify.py)
        try:
            sys.path.insert(0, str(OLIMPO_ALERTAS))
            import notify  # noqa: E402
            notify.cristian(texto)
        except Exception as e:  # el aviso no puede tapar el resultado: queda en el registro y en ESTADO
            self.anota(f"NO PUDE AVISAR por Telegram: {e}")

    def estado(self, texto):
        (self.dir / "ESTADO.txt").write_text(f"{dt.datetime.now():%Y-%m-%d %H:%M} {texto}\n", encoding="utf-8")

    @staticmethod
    def corriendo(exe):
        r = subprocess.run(["tasklist", "/FI", f"IMAGENAME eq {exe}"], capture_output=True)
        return exe.lower() in r.stdout.decode("utf-8", errors="replace").lower()

    # ------------------------------------------------------------------ etapas
    def versiones(self):
        self.etapa = "versiones"
        sys.path.insert(0, str(AQUI / "generador"))
        import polestar_al_dia as v  # noqa: E402
        ultima = self.a.version or v.ultima_version()
        toc = self.addons / "Polestar" / "Polestar.toc"
        m = re.search(r"^## Version:\s*(\S+)", toc.read_text(encoding="utf-8", errors="replace"), re.M) if toc.exists() else None
        instalada = re.sub(r"-asistente.*$", "", m.group(1)) if m else None
        self.instalada = instalada
        self.anota(f"última publicada {ultima} · instalada {instalada or 'ninguna'} · carpeta {self.addons}")
        if not instalada:
            raise Fallo(f"no encuentro Polestar instalado en {self.addons}")
        if v.numeros(ultima) <= v.numeros(instalada):
            return None
        return ultima

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
        if not (dentro and rama == f"fusion/{self.tag}" and "LISTO:" in texto and not fallas):
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
        if self.corriendo("Wow.exe"):
            raise Espera("el juego está abierto: forge lee el cliente y el lanzador podría actualizarlo a mitad")
        inicio = dt.datetime.now().timestamp()
        _, salida = self.corre([BASH, str(AQUI / "seguir_polestar.sh"), "--construir"])
        if "ESTADO: OCUPADO" in salida:
            raise Espera("forge u otra corrida ocupados")
        est = CONSTRUCCION_ESTADO.read_text(encoding="utf-8", errors="replace") if CONSTRUCCION_ESTADO.exists() else ""
        nuevo = lambda p: p.exists() and p.stat().st_mtime > inicio  # noqa: E731
        guias = [p for p in (FUSION / "addon").glob("Polestar_Guides*/*.lua") if nuevo(p)]
        compilado = nuevo(COMPILAR_LOG) and COMPILAR_LOG.read_text(encoding="utf-8", errors="replace").rstrip().endswith("LISTO")
        if not (nuevo(CONSTRUCCION_ESTADO) and est.startswith("LISTO") and compilado and guias and "LISTA PARA INSTALAR" in salida):
            raise Fallo(f"la construcción no quedó: estado «{est.strip()[:80]}», compilado={compilado}, "
                        f"guías regeneradas={len(guias)} (registros D:/rust/noche y {self.log})")

    def controles(self):
        self.etapa = "controles"
        self.forzar("controles")
        _, salida = self.corre([sys.executable, "-I", str(FUSION / "tools/asistente/incluidos.py"), "revisar"])
        if not re.search(r"addons incluidos, 0 errores", salida):
            raise Fallo("un addon incluido no coincide con su huella: " + salida.strip()[-200:])

    def carpetas(self):
        fuente = FUSION / "addon"
        r = subprocess.run(["git", "-C", str(REPO), "ls-tree", "--name-only", f"v{self.instalada}:addon"], capture_output=True, text=True)
        if r.returncode != 0:
            raise Fallo(f"no pude leer las carpetas de la versión instalada v{self.instalada} en git: {r.stderr.strip()}")
        antes = set(r.stdout.split())
        out = []
        for d in sorted(p for p in fuente.iterdir() if p.is_dir()):
            if not any(d.glob("*.toc")):
                continue
            if SIEMPRE.match(d.name) or (self.addons / d.name).is_dir() or d.name not in antes:
                out.append(d.name)
        if "Polestar" not in out:
            raise Fallo("la lista de carpetas a instalar no trae Polestar")
        return out

    @staticmethod
    def huellas(raiz: Path):
        return {p.relative_to(raiz).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in raiz.rglob("*") if p.is_file()}

    def respaldo(self, carpetas):
        self.etapa = "respaldo"
        self.forzar("respaldo")
        dest = (self.dir if self.a.prueba else WOW / "respaldos") / f"Mamba_antes_de_{self.tag}_{dt.datetime.now():%Y-%m-%d_%H%M}.zip"
        dest.parent.mkdir(parents=True, exist_ok=True)
        n = 0
        with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as z:
            for c in carpetas:
                for p in (self.addons / c).rglob("*") if (self.addons / c).is_dir() else []:
                    if p.is_file():
                        z.write(p, p.relative_to(self.addons).as_posix())
                        n += 1
        with zipfile.ZipFile(dest) as z:
            malo, total = z.testzip(), len(z.namelist())
        if malo or total != n or n == 0:
            raise Fallo(f"el respaldo {dest} no se puede releer bien ({total} de {n} archivos, dañado={malo})")
        self.anota(f"respaldo: {dest} ({n} archivos)")
        return dest

    def instalar(self, carpetas):
        self.etapa = "instalar"
        if self.corriendo("Wow.exe") and not self.a.ignorar_juego:
            raise Espera("el juego está abierto: se instala en la próxima corrida con el juego cerrado")
        hechas = []  # (carpeta, había vieja)
        try:
            for c in carpetas:
                src, dst = FUSION / "addon" / c, self.addons / c
                nueva, vieja = self.addons / (c + ".mamba_nueva"), self.addons / (c + ".mamba_vieja")
                for x in (nueva, vieja):
                    if x.exists():
                        shutil.rmtree(x)
                shutil.copytree(src, nueva)
                if self.huellas(nueva) != self.huellas(src):
                    raise Fallo(f"la copia de {c} no coincide con la fuente")
                habia = dst.exists()
                if habia:
                    dst.rename(vieja)
                nueva.rename(dst)
                hechas.append((c, habia))
                self.forzar("instalar")  # el fallo forzado cae DESPUÉS de cambiar una carpeta: prueba la vuelta atrás
            toc = (self.addons / "Polestar" / "Polestar.toc").read_text(encoding="utf-8", errors="replace")
            if not re.search(rf"^## Version:\s*{re.escape(self.tag.lstrip('v'))}\b", toc, re.M):
                raise Fallo("después de instalar, Polestar.toc no dice la versión nueva")
        except Exception:
            self.volver_atras(hechas)
            raise
        for c, habia in hechas:
            vieja = self.addons / (c + ".mamba_vieja")
            if habia and vieja.exists():
                shutil.rmtree(vieja)

    def volver_atras(self, hechas):
        self.anota(f"VUELTA ATRÁS de {len(hechas)} carpetas")
        for c, habia in reversed(hechas):
            dst, vieja = self.addons / c, self.addons / (c + ".mamba_vieja")
            if dst.exists():
                shutil.rmtree(dst)
            if habia:
                vieja.rename(dst)
        for p in self.addons.glob("*.mamba_nueva"):
            shutil.rmtree(p)

    # ------------------------------------------------------------------ corrida
    def ejecutar(self):
        antes = None
        try:
            self.tag = self.versiones()
            if not self.tag:
                self.estado("AL DÍA")
                self.anota("AL DÍA: nada que hacer")
                return 0
            hecho = self.dir / f"instalada_{self.tag}"
            self.fusion()
            self.construir()
            self.controles()
            carpetas = self.carpetas()
            antes = self.huellas_instaladas(carpetas)
            self.respaldo(carpetas)
            self.instalar(carpetas)
            self.etapa = "comprobación final"
            for c in carpetas:
                if self.huellas(self.addons / c) != self.huellas(FUSION / "addon" / c):
                    raise Fallo(f"{c} instalada no coincide con la fuente")
            hecho.write_text(dt.datetime.now().isoformat(), encoding="utf-8")
            pend = WOW / "polestar_versiones" / f"{self.tag}.md"
            self.estado(f"ACTUALIZADA a {self.tag}")
            self.avisar(f"Mamba actualizada a {self.tag} ({len(carpetas)} carpetas). Lo nuevo de Polestar y la "
                        f"revisión de estética quedan para mirar con calma en {pend.name}.")
            return 0
        except Espera as e:
            self.estado(f"EN ESPERA ({self.tag}): {e}")
            self.anota(f"EN ESPERA: {e}")
            marca = self.dir / f"avisada_espera_{self.tag}"
            if self.tag and not marca.exists() and self.etapa == "instalar":
                marca.write_text("1", encoding="utf-8")  # un solo aviso por versión, no uno cada corrida
                self.avisar(f"Mamba {self.tag} está lista para instalarse. Se instala sola la próxima vez que "
                            f"el juego esté cerrado a la hora de la revisión.")
            return 0
        except Exception as e:
            intacto = ""
            if antes is not None:
                ahora = self.huellas_instaladas(list(antes))
                intacto = " Lo instalado quedó como estaba." if ahora == antes else " ⚠️ OJO: lo instalado NO quedó igual que antes."
            else:
                intacto = " No se tocó lo instalado."
            self.estado(f"FALLÓ en {self.etapa} ({self.tag}): {e}")
            self.anota(f"FALLÓ en {self.etapa}: {e}")
            self.avisar(f"Mamba {self.tag or ''}: falló en «{self.etapa}». {e}.{intacto} Registro: {self.log}")
            return 1

    def huellas_instaladas(self, carpetas):
        return {c: self.huellas(self.addons / c) for c in carpetas if (self.addons / c).is_dir()}


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    p = argparse.ArgumentParser()
    p.add_argument("--addons", help="carpeta AddOns (por defecto la del juego)")
    p.add_argument("--estado", help="carpeta de registros y estado")
    p.add_argument("--version", help="tratar esta etiqueta como la última publicada (pruebas)")
    p.add_argument("--prueba", action="store_true", help="avisos marcados [PRUEBA]; respaldo en la carpeta de estado")
    p.add_argument("--forzar-fallo", choices=["fusion", "construir", "controles", "respaldo", "instalar"])
    p.add_argument("--sin-construir", action="store_true")
    p.add_argument("--sin-aviso", action="store_true", help="no mandar Telegram (solo registro)")
    p.add_argument("--ignorar-juego", action="store_true", help="solo con --prueba: instalar aunque el juego esté abierto")
    a = p.parse_args()
    if a.ignorar_juego and not (a.prueba and a.addons):
        p.error("--ignorar-juego solo vale con --prueba y una carpeta --addons de prueba")
    c = Corrida(a)
    cerrojo = c.dir / "EN_CURSO"
    if cerrojo.exists() and dt.datetime.now().timestamp() - cerrojo.stat().st_mtime < 8 * 3600:
        print("OCUPADO: otra corrida en curso desde", cerrojo.read_text(encoding="utf-8"))
        return 3
    cerrojo.write_text(f"{dt.datetime.now():%Y-%m-%d %H:%M} pid {os.getpid()}", encoding="utf-8")
    try:
        return c.ejecutar()
    finally:
        cerrojo.unlink(missing_ok=True)


if __name__ == "__main__":
    sys.exit(main())
