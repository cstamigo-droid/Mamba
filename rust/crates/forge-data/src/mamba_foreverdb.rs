//! Mamba (PARCHES.md P7): a build without QuestieDB lacks the quests World of Warcraft: Forever added
//! (ids 65593+, Shen'dralas, ...). forever-db (the checkout's `forever-db/data/*.jsonl`, Polestar's
//! own published data set, GPL-3.0-only) holds most of them. With `POLESTAR_FOREVER_DB_QUESTS=1` a
//! build without QuestieDB takes from it, after the pfQuest tables are normalized:
//!   - every quest pfQuest lacks, in the normalized shape (source "forever-db");
//!   - the npcs, objects and items those quests name that the tables lack, with their spawns turned
//!     into map percentages on forever-db's own ui_map frames (marked live-frame, "l");
//!   - the objective order of a quest both hold with the same objectives in another order.
//! Without the variable nothing changes. Mamba's file, not Polestar's.

use std::collections::{BTreeMap, BTreeSet};
use std::path::Path;

use forge_guide::js::{Obj, V};
use serde_json::Value;

use crate::factions::{ALL_CLASSES, ALL_RACES};
use crate::jsv::{arr, nums, strs};

pub const ENV: &str = "POLESTAR_FOREVER_DB_QUESTS";
pub const SOURCE: &str = "forever-db";
/// Points kept per map for one npc or object.
const MAX_POINTS: usize = 40;

#[derive(Default, Debug)]
pub struct Stats {
	pub quests_added: usize,
	pub npcs_added: usize,
	pub objects_added: usize,
	pub items_added: usize,
	pub objectives_reordered: usize,
	pub points_unmapped: usize,
}

fn read(dir: &Path, name: &str) -> Result<Vec<Value>, String> {
	let p = dir.join(format!("{name}.jsonl"));
	let text = std::fs::read_to_string(&p).map_err(|e| format!("{}: {e}", p.display()))?;
	text.lines().filter(|l| !l.trim().is_empty()).map(|l| serde_json::from_str(l).map_err(|e| format!("{}: {e}", p.display()))).collect()
}

fn n(v: &Value, k: &str) -> Option<f64> {
	v.get(k).and_then(Value::as_f64)
}
fn i(v: &Value, k: &str) -> Option<i64> {
	v.get(k).and_then(Value::as_i64)
}
fn s<'a>(v: &'a Value, k: &str) -> Option<&'a str> {
	v.get(k).and_then(Value::as_str)
}

/// A race or class mask on the normalized scale: the low 32 bits within `all`, null when it covers
/// every one (as pfQuest's are).
fn mask(m: Option<i64>, all: i32) -> V {
	let Some(m) = m else { return V::Null };
	let low = (m & 0xFFFF_FFFF) as i64 & all as i64;
	if low <= 0 || low == all as i64 {
		V::Null
	} else {
		V::Num(low as f64)
	}
}

struct UiMap {
	id: i64,
	map: i64,
	left: f64,
	right: f64,
	top: f64,
	bottom: f64,
}

impl UiMap {
	fn area(&self) -> f64 {
		((self.right - self.left) * (self.bottom - self.top)).abs()
	}
	/// (x, y) in percent of this map for a world point, when it falls inside.
	fn pct(&self, wx: f64, wy: f64) -> Option<(f64, f64)> {
		let x = (wy - self.left) / (self.right - self.left) * 100.0;
		let y = (wx - self.top) / (self.bottom - self.top) * 100.0;
		((0.0..=100.0).contains(&x) && (0.0..=100.0).contains(&y)).then_some(((x * 10.0).round() / 10.0, (y * 10.0).round() / 10.0))
	}
}

/// Spawns of one npc or object as `{ "<uiMap>": { f: "l", pts: [[x, y], ..] } }`: each point on the
/// smallest forever-db map that holds it.
fn spawns_of(points: &[(i64, f64, f64)], maps: &[UiMap], unmapped: &mut usize) -> V {
	let mut by: BTreeMap<i64, Vec<(f64, f64)>> = BTreeMap::new();
	for &(map, wx, wy) in points {
		let best = maps.iter().filter(|m| m.map == map).filter_map(|m| m.pct(wx, wy).map(|p| (m, p))).min_by(|a, b| a.0.area().total_cmp(&b.0.area()));
		match best {
			Some((m, p)) => {
				let l = by.entry(m.id).or_default();
				if l.len() < MAX_POINTS && !l.contains(&p) {
					l.push(p);
				}
			}
			None => *unmapped += 1,
		}
	}
	let o = Obj::new();
	for (id, pts) in by {
		let e = Obj::new();
		e.set("f", "l");
		e.set("pts", arr(pts.iter().map(|&(x, y)| nums(&[x, y])).collect()));
		o.set(&id.to_string(), e);
	}
	V::Obj(o)
}

/// The first map an entity's spawns name.
fn first_map(e: &V) -> Option<f64> {
	e.get("spawns").as_obj().and_then(|o| o.keys().first().and_then(|k| k.parse::<f64>().ok()))
}

/// "A", "H", "AH" or Null from a faction template, by the game's FactionTemplate table (the newest
/// data/sources/wago/<build>/FactionTemplate.csv): a side whose players the template is friends
/// with (FriendGroup, or its own FactionGroup) and not enemies with (EnemyGroup). Bits: 1 player,
/// 2 Alliance, 4 Horde.
fn faction_sides(root: &Path) -> BTreeMap<i64, &'static str> {
	let mut out = BTreeMap::new();
	let Ok(rd) = std::fs::read_dir(root.join("data").join("sources").join("wago")) else { return out };
	let mut dirs: Vec<_> = rd.filter_map(|e| e.ok()).map(|e| e.path().join("FactionTemplate.csv")).filter(|p| p.is_file()).collect();
	dirs.sort();
	let Some(f) = dirs.last() else { return out };
	let Ok(text) = std::fs::read_to_string(f) else { return out };
	let mut lines = text.lines();
	let head: Vec<&str> = lines.next().unwrap_or("").split(',').collect();
	let col = |n: &str| head.iter().position(|h| *h == n);
	let (Some(ci), Some(cg), Some(cf), Some(ce)) = (col("ID"), col("FactionGroup"), col("FriendGroup"), col("EnemyGroup")) else { return out };
	for l in lines {
		let c: Vec<&str> = l.split(',').collect();
		let g = |k: usize| c.get(k).and_then(|x| x.parse::<i64>().ok()).unwrap_or(0);
		let (id, grp, fr, en) = (g(ci), g(cg), g(cf), g(ce));
		let side = |b: i64| (fr & (1 | b) != 0 || grp & b != 0) && en & (1 | b) == 0;
		let v = match (side(2), side(4)) {
			(true, true) => "AH",
			(true, false) => "A",
			(false, true) => "H",
			_ => continue,
		};
		out.insert(id, v);
	}
	out
}

pub fn apply(root: &Path, quests: &Obj, npcs: &Obj, objects: &Obj, items: &Obj, log: &dyn Fn(&str)) -> Result<Stats, String> {
	let dir = root.join("forever-db").join("data");
	let mut st = Stats::default();
	let sides = faction_sides(root);
	let fq = read(&dir, "quest")?;
	let mut starts: BTreeMap<i64, Vec<(String, i64)>> = BTreeMap::new();
	for r in read(&dir, "quest_start")? {
		if let (Some(q), Some(k), Some(id)) = (i(&r, "quest"), s(&r, "kind"), i(&r, "id")) {
			starts.entry(q).or_default().push((k.to_string(), id));
		}
	}
	let mut ends: BTreeMap<i64, Vec<(String, i64)>> = BTreeMap::new();
	for r in read(&dir, "quest_end")? {
		if let (Some(q), Some(k), Some(id)) = (i(&r, "quest"), s(&r, "kind"), i(&r, "id")) {
			ends.entry(q).or_default().push((k.to_string(), id));
		}
	}
	let mut objs: BTreeMap<i64, Vec<Value>> = BTreeMap::new();
	for r in read(&dir, "quest_objective")? {
		if let Some(q) = i(&r, "quest") {
			objs.entry(q).or_default().push(r);
		}
	}
	for l in objs.values_mut() {
		l.sort_by_key(|r| i(r, "n").unwrap_or(0));
	}
	let mut pre_any: BTreeMap<i64, Vec<f64>> = BTreeMap::new();
	let mut pre_all: BTreeMap<i64, Vec<f64>> = BTreeMap::new();
	for r in read(&dir, "quest_prereq")? {
		if let (Some(q), Some(p)) = (i(&r, "quest"), n(&r, "pre")) {
			let m = if s(&r, "mode") == Some("all") { &mut pre_all } else { &mut pre_any };
			m.entry(q).or_default().push(p);
		}
	}
	let fnpc: BTreeMap<i64, Value> = read(&dir, "npc")?.into_iter().filter_map(|r| i(&r, "id").map(|id| (id, r))).collect();
	let fobj: BTreeMap<i64, Value> = read(&dir, "object")?.into_iter().filter_map(|r| i(&r, "id").map(|id| (id, r))).collect();
	let fitem: BTreeMap<i64, Value> = read(&dir, "item")?.into_iter().filter_map(|r| i(&r, "id").map(|id| (id, r))).collect();
	let maps: Vec<UiMap> = read(&dir, "ui_map")?
		.iter()
		.filter_map(|r| Some(UiMap { id: i(r, "ui_map")?, map: i(r, "map")?, left: n(r, "left")?, right: n(r, "right")?, top: n(r, "top")?, bottom: n(r, "bottom")? }))
		.collect();

	let name_of = |kind: &str, id: i64| -> V {
		let (t, f) = match kind {
			"npc" | "kill" | "talk" => (npcs, &fnpc),
			"object" => (objects, &fobj),
			_ => (items, &fitem),
		};
		// A placeholder target's name ("Credit", "[DNT] …", #2614) is not the quest log's words: no text,
		// and credit.rs makes the objective an event (Polestar v0.4.1 stops the build on one that ships).
		let have = t.get(&id.to_string());
		let nm = have.get("name").as_str().map(str::to_string).or_else(|| f.get(&id).and_then(|r| s(r, "name")).map(str::to_string));
		match nm {
			Some(n) if !forge_guide::placeholder::banned(&n) => V::str(&n),
			_ => V::Null,
		}
	};
	let objective = |r: &Value| -> Obj {
		let kind = s(r, "kind").unwrap_or("");
		let target = i(r, "target");
		let o = Obj::new();
		o.set("type", kind);
		o.set("id", target.map(|t| V::Num(t as f64)).unwrap_or(V::Null));
		let count = n(r, "count");
		match kind {
			"item" | "kill" | "talk" => {
				o.set("count", V::Num(count.unwrap_or(1.0)));
				o.set("text", target.map(|t| name_of(kind, t)).unwrap_or(V::Null));
			}
			"object" => {
				o.set("count", count.map(V::Num).unwrap_or(V::Null));
				o.set("text", target.map(|t| name_of(kind, t)).unwrap_or(V::Null));
			}
			_ => {
				o.set("count", count.map(V::Num).unwrap_or(V::Null));
				o.set("text", V::Null);
			}
		}
		o
	};

	// 1. Objective order of the quests both hold, when the objectives are the same ones.
	for (&qid, list) in &objs {
		let q = quests.get(&qid.to_string());
		if q.is_undef() {
			continue;
		}
		let have = q.get("objectives").items();
		if have.len() < 2 {
			continue;
		}
		// The objectives forever-db lists come first, in its order (the game's, which the guides
		// number by); the ones only pfQuest has keep their order after them. Each one is kept.
		let key = |t: &str, id: f64| format!("{t}:{id}");
		let have_keys: Vec<String> = have.iter().map(|o| key(o.get("type").as_str().unwrap_or(""), o.get("id").num())).collect();
		let want_keys: Vec<String> = list.iter().map(|r| key(s(r, "kind").unwrap_or(""), n(r, "target").unwrap_or(f64::NAN))).collect();
		let mut order: Vec<usize> = Vec::new();
		for k in &want_keys {
			if let Some(p) = have_keys.iter().position(|h| h == k) {
				if !order.contains(&p) {
					order.push(p);
				}
			}
		}
		if order.is_empty() {
			continue;
		}
		for p in 0..have.len() {
			if !order.contains(&p) {
				order.push(p);
			}
		}
		if order.iter().enumerate().all(|(a, b)| a == *b) {
			continue;
		}
		let reordered: Vec<V> = order.iter().map(|&p| have[p].clone()).collect();
		if reordered.len() == have.len() {
			q.set("objectives", arr(reordered));
			let mut src = q.get("source").items();
			src.push(V::str("forever-db:order"));
			q.set("source", arr(src));
			st.objectives_reordered += 1;
		}
	}

	// 2. The quests pfQuest lacks.
	let mut need: BTreeMap<&str, BTreeSet<i64>> = BTreeMap::new();
	let mut added: Vec<i64> = Vec::new();
	for r in &fq {
		let Some(id) = i(r, "id") else { continue };
		let Some(title) = s(r, "title").filter(|t| !t.is_empty()) else { continue };
		if quests.has(&id.to_string()) {
			continue;
		}
		let rec = Obj::new();
		rec.set("id", id as f64);
		rec.set("title", title);
		rec.set("level", n(r, "level").filter(|x| *x != 0.0).map(V::Num).unwrap_or(V::Null));
		rec.set("minLevel", n(r, "min_level").filter(|x| *x != 0.0).map(V::Num).unwrap_or(V::Null));
		rec.set("races", mask(i(r, "races"), ALL_RACES));
		rec.set("classes", mask(i(r, "classes"), ALL_CLASSES));
		let side = |list: Option<&Vec<(String, i64)>>, kinds: &[&str]| -> Obj {
			let o = Obj::new();
			for k in kinds {
				let ids: Vec<f64> = list.into_iter().flatten().filter(|(kk, _)| kk == k).map(|(_, x)| *x as f64).collect();
				o.set(k, nums(&ids));
			}
			o
		};
		let sl = starts.get(&id);
		let el = ends.get(&id);
		for (k, x) in sl.into_iter().flatten().chain(el.into_iter().flatten()) {
			need.entry(if k == "npc" { "npc" } else if k == "object" { "object" } else { "item" }).or_default().insert(*x);
		}
		rec.set("start", side(sl, &["npc", "object", "item"]));
		rec.set("end", side(el, &["npc", "object"]));
		let any = pre_any.get(&id).cloned().unwrap_or_default();
		let all = pre_all.get(&id).cloned().unwrap_or_default();
		rec.set("pre", nums(if !any.is_empty() { &any } else { &all }));
		rec.set("excl", V::arr());
		rec.set("next", V::Null);
		let ol = objs.get(&id).cloned().unwrap_or_default();
		for o in &ol {
			if let Some(t) = i(o, "target") {
				match s(o, "kind") {
					Some("kill") | Some("talk") => {
						need.entry("npc").or_default().insert(t);
					}
					Some("object") => {
						need.entry("object").or_default().insert(t);
					}
					Some("item") => {
						need.entry("item").or_default().insert(t);
					}
					_ => {}
				}
			}
		}
		rec.set("objectives", arr(ol.iter().map(|o| V::Obj(objective(o))).collect()));
		rec.set("objectiveText", V::Null);
		rec.set("zone", V::Null);
		rec.set("xp", n(r, "xp").map(V::Num).unwrap_or(V::Null));
		rec.set("skill", V::Null);
		rec.set("event", V::Null);
		rec.set("source", strs(&[SOURCE]));
		if !all.is_empty() {
			rec.set("preAll", nums(&all));
		}
		if !any.is_empty() {
			rec.set("preAny", nums(&any));
		}
		if r.get("repeatable").and_then(Value::as_bool) == Some(true) {
			rec.set("repeatable", true);
		}
		quests.set(&id.to_string(), rec);
		added.push(id);
		st.quests_added += 1;
	}

	// The npcs, objects and items the guides name (data/local/forever-db-need.txt, lines "item N",
	// "npc N", "object N", written by tools/asistente/guias_sin_fuente.py --necesita): only the ones
	// data lacks and forever-db has are added below.
	if let Ok(t) = std::fs::read_to_string(root.join("data").join("local").join("forever-db-need.txt")) {
		for l in t.lines() {
			let mut w = l.split_whitespace();
			if let (Some(k @ ("item" | "npc" | "object")), Some(Ok(id))) = (w.next(), w.next().map(str::parse::<i64>)) {
				let (kind, missing) = match k {
					"item" => ("item", !items.has(&id.to_string()) && fitem.contains_key(&id)),
					"npc" => ("npc", !npcs.has(&id.to_string()) && fnpc.contains_key(&id)),
					_ => ("object", !objects.has(&id.to_string()) && fobj.contains_key(&id)),
				};
				if missing {
					need.entry(kind).or_default().insert(id);
				}
			}
		}
	}

	// Forever's class trainers (subname "<Class> Trainer"), so the KB's trainer list (ForeverTDB) has
	// them in npcs.json with their spawns: `train class` finds the Alliance shaman trainers (17-11).
	const CLASSES: [&str; 9] = ["Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Shaman", "Mage", "Warlock", "Druid"];
	for (&id, r) in &fnpc {
		if s(r, "subname").is_some_and(|sub| CLASSES.iter().any(|c| sub == format!("{c} Trainer"))) && !npcs.has(&id.to_string()) {
			need.entry("npc").or_default().insert(id);
		}
	}

	// 3. The npcs, objects and items they name, with spawns and drops.
	let mut item_sources: BTreeMap<i64, Vec<(String, i64, Option<f64>)>> = BTreeMap::new();
	let want_items = need.get("item").cloned().unwrap_or_default();
	for r in read(&dir, "item_source")? {
		if let (Some(it), Some(k), Some(id)) = (i(&r, "item"), s(&r, "kind"), i(&r, "id")) {
			if want_items.contains(&it) {
				item_sources.entry(it).or_default().push((k.to_string(), id, n(&r, "chance")));
				if k == "npc" || k == "object" {
					need.entry(if k == "npc" { "npc" } else { "object" }).or_default().insert(id);
				}
			}
		}
	}
	let want_npcs: BTreeSet<i64> = need.get("npc").cloned().unwrap_or_default().into_iter().filter(|x| !npcs.has(&x.to_string()) && fnpc.contains_key(x)).collect();
	let want_objs: BTreeSet<i64> = need.get("object").cloned().unwrap_or_default().into_iter().filter(|x| !objects.has(&x.to_string()) && fobj.contains_key(x)).collect();
	let mut pts: BTreeMap<(bool, i64), Vec<(i64, f64, f64)>> = BTreeMap::new();
	if !want_npcs.is_empty() || !want_objs.is_empty() {
		for r in read(&dir, "spawn")? {
			let (Some(k), Some(id), Some(map), Some(x), Some(y)) = (s(&r, "kind"), i(&r, "id"), i(&r, "map"), n(&r, "x"), n(&r, "y")) else { continue };
			let is_npc = k == "npc";
			if (is_npc && want_npcs.contains(&id)) || (!is_npc && want_objs.contains(&id)) {
				pts.entry((is_npc, id)).or_default().push((map, x, y));
			}
		}
	}
	for &id in &want_npcs {
		let r = &fnpc[&id];
		let rec = Obj::new();
		rec.set("id", id as f64);
		rec.set("name", s(r, "name").map(V::str).unwrap_or(V::Null));
		let (lo, hi) = (n(r, "level_min"), n(r, "level_max"));
		rec.set("level", lo.or(hi).map(V::Num).unwrap_or(V::Null));
		if let (Some(l), Some(h)) = (lo, hi) {
			if h != l {
				rec.set("levelMax", h);
			}
		}
		if let Some(rank) = n(r, "rank").filter(|x| *x != 0.0) {
			rec.set("rank", rank);
		}
		rec.set("faction", i(r, "faction_template").and_then(|ft| sides.get(&ft)).map(|x| V::str(x)).unwrap_or(V::Null));
		if let Some(sub) = s(r, "subname").filter(|x| !x.is_empty()) {
			rec.set("subName", sub);
		}
		rec.set("spawns", spawns_of(pts.get(&(true, id)).map(Vec::as_slice).unwrap_or(&[]), &maps, &mut st.points_unmapped));
		rec.set("source", strs(&[SOURCE]));
		npcs.set(&id.to_string(), rec);
		st.npcs_added += 1;
	}
	for &id in &want_objs {
		let r = &fobj[&id];
		let rec = Obj::new();
		rec.set("id", id as f64);
		rec.set("name", s(r, "name").map(V::str).unwrap_or(V::Null));
		rec.set("spawns", spawns_of(pts.get(&(false, id)).map(Vec::as_slice).unwrap_or(&[]), &maps, &mut st.points_unmapped));
		rec.set("source", strs(&[SOURCE]));
		objects.set(&id.to_string(), rec);
		st.objects_added += 1;
	}
	for &id in &want_items {
		if items.has(&id.to_string()) {
			continue;
		}
		let Some(r) = fitem.get(&id) else { continue };
		let rec = Obj::new();
		rec.set("id", id as f64);
		rec.set("name", s(r, "name").map(V::str).unwrap_or(V::Null));
		let drops = Obj::new();
		let (dn, dob) = (Obj::new(), Obj::new());
		for (k, src, chance) in item_sources.get(&id).into_iter().flatten() {
			let t = if k == "npc" { &dn } else if k == "object" { &dob } else { continue };
			t.set(&src.to_string(), chance.map(V::Num).unwrap_or(V::Null));
		}
		drops.set("npc", dn);
		drops.set("object", dob);
		rec.set("drops", drops);
		rec.set("vendors", V::arr());
		rec.set("source", strs(&[SOURCE]));
		items.set(&id.to_string(), rec);
		st.items_added += 1;
	}

	// 4. Each added quest's zone: its first giver's (or turn-in's) first map.
	for id in &added {
		let q = quests.get(&id.to_string());
		let first = |side: &str, kind: &str, t: &Obj| -> Option<f64> { q.get(side).get(kind).at(0).as_num().and_then(|e| first_map(&t.get(&forge_guide::js::num_str(e)))) };
		let z = first("start", "npc", npcs).or_else(|| first("start", "object", objects)).or_else(|| first("end", "npc", npcs)).or_else(|| first("end", "object", objects));
		q.set("zone", z.map(V::Num).unwrap_or(V::Null));
	}
	// A follow-up for the added quests: the single quest listing one as its prerequisite.
	let mut successors: BTreeMap<i64, Vec<f64>> = BTreeMap::new();
	for q in quests.values() {
		for p in q.get("pre").items() {
			successors.entry(p.num() as i64).or_default().push(q.get("id").num());
		}
	}
	for id in &added {
		if let Some(l) = successors.get(id).filter(|l| l.len() == 1) {
			quests.get(&id.to_string()).set("next", l[0]);
		}
	}
	log(&format!(
		"  data: forever-db ({ENV}): {} quests, {} npcs, {} objects, {} items added; {} objective orders taken; {} spawn points on no map",
		st.quests_added, st.npcs_added, st.objects_added, st.items_added, st.objectives_reordered, st.points_unmapped
	));
	Ok(st)
}
