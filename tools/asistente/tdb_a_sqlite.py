"""Arma data/local/forever-tdb/world.sqlite (lo que lee forge, rust/crates/forge-data/src/tdb.rs)
desde el dump oficial de ForeverTDB, sin MySQL: lee el volcado de mysqldump y pasa cada tabla a SQLite.

Fuente (autorizada por Cristian el 17-11-2026, GPL-2.0, se usa SOLO como hechos, nunca va en un zip):
  release forever-tdb-AAAA-MM-DD de https://github.com/advocaite/TrinityCore (rama forever),
  asset TDB_full_forever_*.7z; se verifica su SHA-256 contra el `digest` del release.

Uso (Windows trae tar con soporte 7z):
  gh release download forever-tdb-2026-10-14 -R advocaite/TrinityCore -p 'TDB_full_forever_*.7z' -D D:/rust/forever-tdb/descarga
  tar -xf D:/rust/forever-tdb/descarga/TDB_full_forever_2026_10_14.7z -C D:/rust/forever-tdb/dump
  python -I tools/asistente/tdb_a_sqlite.py D:/rust/forever-tdb/dump/TDB_full_world_forever_2026_10_14.sql \
      D:/rust/forever-tdb/world.sqlite --release forever-tdb-2026-10-14 --commit f2b20d1863f64ea356b221dfd639329ab64c45cd

_meta: release y release_commit son los del release; branch_head = el mismo commit (no se aplican los
sql/updates posteriores al release: el dump es la base completa a esa fecha).
"""
import argparse
import datetime
import os
import re
import sqlite3
import sys

CREATE = re.compile(r"^CREATE TABLE `([^`]+)` \(")
COL = re.compile(r"^\s+`([^`]+)` ([a-z]+)")
INSERT = re.compile(r"^INSERT INTO `([^`]+)` VALUES ")
ESC = {"0": "\0", "n": "\n", "r": "\r", "t": "\t", "Z": "\x1a", "b": "\b"}


def tuplas(s, i):
	"""Recorre `(v,v,...),(...);` desde s[i] y entrega cada fila como lista de valores Python."""
	n = len(s)
	while i < n:
		c = s[i]
		if c == "(":
			fila, i = [], i + 1
			while True:
				c = s[i]
				if c == "'":
					i += 1
					partes = []
					ini = i
					while True:
						j = s.find("'", i)
						k = s.find("\\", i, j) if j != -1 else -1
						if k != -1:
							partes.append(s[ini:k])
							e = s[k + 1]
							partes.append(ESC.get(e, e))
							i = ini = k + 2
							continue
						if j + 1 < n and s[j + 1] == "'":
							partes.append(s[ini:j + 1])
							i = ini = j + 2
							continue
						partes.append(s[ini:j])
						i = j + 1
						break
					fila.append("".join(partes))
				else:
					j = i
					while s[j] not in ",)":
						j += 1
					tok = s[i:j]
					i = j
					if tok == "NULL":
						fila.append(None)
					elif tok.startswith("0x"):
						fila.append(bytes.fromhex(tok[2:]))
					else:
						try:
							v = int(tok)
							# bigint unsigned (máscaras de razas: 18446744073709551615 = todas) no cabe en el
							# INTEGER de SQLite: se guarda con los mismos 64 bits, en complemento a dos (-1).
							fila.append(v - (1 << 64) if v >= (1 << 63) else v)
						except ValueError:
							fila.append(float(tok))
				if s[i] == ",":
					i += 1
					continue
				i += 1  # ')'
				break
			yield fila
		elif c in ",":
			i += 1
		elif c == ";":
			return
		else:
			raise ValueError(f"carácter inesperado {c!r} en la posición {i}")


def tipo(mysql):
	if mysql in ("tinyint", "smallint", "mediumint", "int", "bigint", "bit", "year"):
		return "INTEGER"
	if mysql in ("float", "double", "decimal"):
		return "REAL"
	if mysql in ("blob", "binary", "varbinary", "tinyblob", "mediumblob", "longblob"):
		return "BLOB"
	return "TEXT"


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("dump")
	ap.add_argument("salida")
	ap.add_argument("--release", required=True)
	ap.add_argument("--commit", required=True)
	a = ap.parse_args()

	tmp = a.salida + ".tmp"
	if os.path.exists(tmp):
		os.remove(tmp)
	db = sqlite3.connect(tmp)
	db.execute("PRAGMA journal_mode=OFF")
	db.execute("PRAGMA synchronous=OFF")
	cols, tabla, filas_tot = {}, None, {}
	with open(a.dump, encoding="utf-8", errors="strict", newline="\n") as f:
		for linea in f:
			m = CREATE.match(linea)
			if m:
				tabla = m.group(1)
				cols[tabla] = []
				continue
			if tabla is not None and linea.startswith(")"):
				defs = ", ".join(f'"{c}" {t}' for c, t in cols[tabla])
				db.execute(f'DROP TABLE IF EXISTS "{tabla}"')
				db.execute(f'CREATE TABLE "{tabla}" ({defs})')
				tabla = None
				continue
			if tabla is not None:
				m = COL.match(linea)
				if m:
					cols[tabla].append((m.group(1), tipo(m.group(2))))
				continue
			m = INSERT.match(linea)
			if m:
				t = m.group(1)
				ph = ",".join("?" * len(cols[t]))
				filas = list(tuplas(linea.rstrip("\r\n"), m.end()))
				for r in filas:
					if len(r) != len(cols[t]):
						sys.exit(f"{t}: fila con {len(r)} valores, la tabla tiene {len(cols[t])} columnas")
				db.executemany(f'INSERT INTO "{t}" VALUES ({ph})', filas)
				filas_tot[t] = filas_tot.get(t, 0) + len(filas)
	db.execute('CREATE TABLE "_meta" (key TEXT PRIMARY KEY, value TEXT)')
	ahora = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
	db.executemany('INSERT INTO "_meta" VALUES (?,?)', [
		("release", a.release), ("release_commit", a.commit), ("branch_head", a.commit),
		("built", ahora), ("source", "mamba tools/asistente/tdb_a_sqlite.py from " + os.path.basename(a.dump)),
	])
	db.commit()
	db.close()
	os.replace(tmp, a.salida)
	print(f"{len(cols)} tablas, {sum(filas_tot.values())} filas -> {a.salida}")
	for t in ("trainer", "trainer_spell", "creature_trainer", "creature_template", "quest_template", "npc_vendor", "creature"):
		print(f"  {t}: {filas_tot.get(t, 0)}")


if __name__ == "__main__":
	main()
