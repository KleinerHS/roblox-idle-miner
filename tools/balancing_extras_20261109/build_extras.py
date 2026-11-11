"""Read-only economy analysis; writes proposal JSON only in this analysis folder."""
from pathlib import Path
import json
import math
import re

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent


def quantile_hits(p, q):
    return math.ceil(math.log1p(-q) / math.log1p(-p))


def wait_row(name, p, hits_s, luck):
    chance = p * luck
    return {
        "rarity": name,
        "hits_per_second": hits_s,
        "luck_factor": luck,
        "probability_per_hit": chance,
        "mean_minutes": 1 / chance / hits_s / 60,
        "median_minutes": quantile_hits(chance, 0.5) / hits_s / 60,
        "p90_minutes": quantile_hits(chance, 0.9) / hits_s / 60,
        "probability_at_least_one_in_15min": -math.expm1(15 * 60 * hits_s * math.log1p(-chance)),
        "probability_at_least_one_in_30h": -math.expm1(30 * 3600 * hits_s * math.log1p(-chance)),
    }


def bind_parent_model(data):
    model_path = ROOT / "tools/balancing_20261109/model.json"
    if not model_path.exists():
        return
    model = json.loads(model_path.read_text(encoding="utf-8"))
    collections = model["collections"]
    ores = {o["id"]: o for o in collections["ores"]}
    mines = {m["number"]: m for m in collections["mines"]}
    baseline = next(s for s in model["simulations"] if s["profile"] == "active" and s["prestige"] == 0 and s["rate_factor"] == 1 and s["trip_factor"] == 1)
    snapshots = baseline["snapshots"]

    def reference(snapshot):
        if "gross_cash_per_min" in snapshot:
            return snapshot["gross_cash_per_min"], "Normale theoretische Gesamt-Cashrate aus der Parent-Simulation; ohne Jackpot/Offline."
        current_mine = mines[snapshot["mine"]]
        current_price = ores[current_mine["ore_id"]]["price"]
        amount = snapshot["auto_rate_min"] + snapshot["manual_raw_rate_min"] * snapshot["manual_activity_share"]
        return max(1, amount * current_price), "Vereinfachter fixer Designanker: (automatische Rate + manuelle Rate × Aktivitätsanteil) × aktueller Roh-Erzpreis; Verarbeitung und ältere Erzsorten im Anker nicht separat bewertet. Kein behaupteter tatsächlicher Verkaufserlös."

    refs = {}
    for ore in collections["ores"]:
        first_mine = (ore["tier"] - 1) * 2 + 1
        first_snapshot = next((s for s in snapshots if s["mine"] >= first_mine), snapshots[-1])
        amount, basis = reference(first_snapshot)
        refs[ore["tier"]] = {
            "ore_id": ore["id"], "tier": ore["tier"], "required_level": mines[first_mine]["level"],
            "anchor_snapshot_level": first_snapshot["level"], "reference_gross_cash_min": amount,
            "reference_hits_per_second": next(p["speed"] for p in collections["picks"] if p["id"] == first_snapshot["pick_id"]),
            "normal_ore_price": ore["price"], "normal_ore_xp": ore["xp"], "basis": basis,
        }
    for variant in data["jackpot_variants"]:
        ref = refs[variant["base_tier"]]
        variant["sell_value"] = round(max(ref["normal_ore_price"], ref["reference_gross_cash_min"] * variant["reference_income_minutes"]))
        variant["xp"] = ref["normal_ore_xp"]
        variant["required_level"] = ref["required_level"]
        variant["reference_gross_cash_min"] = ref["reference_gross_cash_min"]
        variant["reference_anchor_snapshot_level"] = ref["anchor_snapshot_level"]
        variant["fixed_price"] = True

    upgrade_groups = [data["luck"]["levels"], data["offline"]["efficiency_upgrades"], data["offline"]["duration_upgrades"]]
    for group in upgrade_groups:
        for upgrade in group:
            snap = next((s for s in snapshots if s["level"] >= upgrade["required_level"]), snapshots[-1])
            gross_min, basis = reference(snap)
            upgrade["price"] = round(max(1, gross_min * upgrade["cost_reference_gross_minutes"]))
            upgrade["reference_gross_cash_min"] = gross_min
            upgrade["reference_basis"] = basis

    data["tier_reference_rows"] = list(refs.values())
    data["binding"] = {"source": str(model_path), "parent_generated_date": model["generated_date"],
                       "parent_baseline_minutes": baseline["active_minutes"],
                       "note": "Bei Änderungen am Hauptmodell dieses Extras-Script neu ausführen. Variantpreise dann beim Spielimport als feste Werte fixieren; niemals nach Verkäufer oder Handelswert neu bestimmen."}
    data["tests"]["all_bound_prices_positive"] = all(v["sell_value"] > 0 for v in data["jackpot_variants"])
    data["tests"]["all_bound_xp_no_greater_than_one_regular_ore_unit"] = all(v["xp"] <= ores[v["base_ore_id"]]["xp"] for v in data["jackpot_variants"])


def make_extras():
    rarities = [
        {"id_suffix": "pristine", "display_name": "Pristine", "chance_per_hit": 1 / 6000,
         "reference_income_minutes": 5, "amount": 1},
        {"id_suffix": "radiant", "display_name": "Radiant", "chance_per_hit": 1 / 60000,
         "reference_income_minutes": 30, "amount": 1},
        {"id_suffix": "ancient", "display_name": "Ancient", "chance_per_hit": 1 / 600000,
         "reference_income_minutes": 180, "amount": 1},
    ]
    waiting = [wait_row(r["id_suffix"], r["chance_per_hit"], speed, luck)
               for r in rarities for speed in [1, 1.8, 2.4] for luck in [1, 2]]
    jackpot_rate = sum(r["chance_per_hit"] for r in rarities)
    expected_rate = []
    for speed in [1, 1.8, 2.4]:
        for luck in [1, 2]:
            expected_rate.append({
                "hits_per_second": speed, "luck_factor": luck,
                "gross_jackpot_cash_per_reference_cash_minute": sum(
                    r["chance_per_hit"] * luck * speed * 60 * r["reference_income_minutes"] for r in rarities),
                "no_jackpot_in_30min_probability": (1 - jackpot_rate * luck) ** (speed * 1800),
                "note": "Brutto-Erwartungswert, bezogen auf eine feste tierbezogene Referenzfirma; ersetzt normale Hit-Auszahlung, daher netto minimal niedriger. Kein garantierter Fortschritt.",
            })

    # Global tier statistics and parent binding data are deliberately separate.
    ore_text = (ROOT / "src/shared/Definitions/Ores.luau").read_text(encoding="utf-8-sig")
    ore_ids = re.findall(r'\{ Id = "(ore_[^"]+)", DisplayName = "([^"]+)"', ore_text)
    variants = [{
        "id": ore_id + "_" + r["id_suffix"], "base_ore_id": ore_id,
        "base_tier": tier, "display_name": r["display_name"] + " " + name,
        "rarity": r["id_suffix"], "chance_per_hit": r["chance_per_hit"],
        "reference_income_minutes": r["reference_income_minutes"],
        "xp_base_ore_unit_multiple": 1, "max_amount_per_drop": 1,
        "sell_value_rule": "round(max(base_ore_sell_value, reference_gross_cash_per_min_at_first_unlock * reference_income_minutes))",
        "tradeable_proposal": False,
        "status": "VORSCHLAG / neuer Inhalt / TODO_BALANCE",
    } for tier, (ore_id, name) in enumerate(ore_ids, 1) for r in rarities]

    luck_levels = [5, 12, 20, 28, 36, 44, 52, 62, 74, 86]
    luck_minutes = [2, 3, 4, 6, 8, 10, 13, 17, 22, 30]
    luck = [{"level": n, "required_level": req,
             "relative_chance_factor": round(1 + n * 0.1, 6),
             "cost_reference_gross_minutes": cost, "previous_level_required": n - 1,
             "status": "VORSCHLAG / TODO_BALANCE"}
            for n, (req, cost) in enumerate(zip(luck_levels, luck_minutes), 1)]

    drill_levels = []
    cumulative = 0
    for lvl in range(1, 11):
        cost = 0 if lvl == 1 else 0.03 * 1.18 ** (lvl - 2)
        cumulative += cost
        drill_levels.append({"level": lvl, "production_multiplier": round(1 + (lvl - 1) * 0.04, 8),
                             "incremental_cost_fraction_of_drill_purchase_price": cost,
                             "cumulative_upgrade_cost_fraction": cumulative,
                             "buffer_multiplier": round(1 + (lvl - 1) * 0.04, 8),
                             "previous_level_required": max(1, lvl - 1)})

    efficiency = [
        {"id": "offline_efficiency_1", "required_level": 15, "efficiency": 0.35, "cost_reference_gross_minutes": 25},
        {"id": "offline_efficiency_2", "required_level": 35, "efficiency": 0.40, "cost_reference_gross_minutes": 45},
        {"id": "offline_efficiency_3", "required_level": 55, "efficiency": 0.45, "cost_reference_gross_minutes": 90},
        {"id": "offline_efficiency_4", "required_level": 75, "efficiency": 0.50, "cost_reference_gross_minutes": 180},
    ]
    duration = [
        {"id": "offline_duration_1", "required_level": 30, "cap_hours": 10, "cost_reference_gross_minutes": 60},
        {"id": "offline_duration_2", "required_level": 65, "cap_hours": 12, "cost_reference_gross_minutes": 180},
    ]
    for i, upgrade in enumerate(efficiency):
        upgrade["previous_id"] = None if i == 0 else efficiency[i - 1]["id"]
        upgrade["incremental_normal_minutes_per_capped_8h_return"] = 0.05 * 8 * 60
        upgrade["capped_8h_returns_to_repay_at_purchase_reference_rate"] = upgrade["cost_reference_gross_minutes"] / (0.05 * 8 * 60)
    for i, upgrade in enumerate(duration):
        upgrade["previous_id"] = None if i == 0 else duration[i - 1]["id"]
        upgrade["incremental_normal_minutes_per_capped_return_at_30pct"] = 0.3 * 2 * 60
        upgrade["capped_returns_to_repay_at_purchase_reference_rate_30pct"] = upgrade["cost_reference_gross_minutes"] / (0.3 * 2 * 60)

    afk = []
    # This demonstrates the real conflict; it must not be hidden by economic labels.
    for minutes in [15, 30, 60, 120, 480]:
        for efficiency_rate in [0.3, 0.5]:
            online_income_mins = min(minutes, 15)  # one initial free storage fill, no sale
            offline_income_mins = minutes * efficiency_rate
            afk.append({"absence_minutes": minutes, "offline_efficiency": efficiency_rate,
                        "online_idle_stored_reference_minutes": online_income_mins,
                        "offline_cash_reference_minutes": offline_income_mins,
                        "offline_exceeds_online_idle_stored_value": offline_income_mins > online_income_mins,
                        "note": "Illustrativer 15-Minuten-Lagerspeicher, konstante Rate, keine Löhne; Online-Material muss noch aktiv verkauft werden."})

    result = {
        "date": "2026-11-09", "status": "VORSCHLAG / TESTING_REQUIRED",
        "no_game_code_or_workbook_changed": True,
        "binding_required": "Für feste Preise parent model.json referenzieren: base_tier, reference_gross_cash_per_min_at_first_unlock, base_ore_sell_value, base_ore_xp. Hier keine alten Workbookwerte als neue Anker verwenden.",
        "jackpot_rarities": rarities,
        "jackpot_variants": variants,
        "jackpot_waiting_time_rows": waiting,
        "jackpot_expected_cash_rows": expected_rate,
        "quantity_bonus": {"base_probability_per_hit": 0.01, "multipliers": [2,3,4,5,6,7,8,9,10],
                           "weights": [50,25,12,6,3,2,1,0.7,0.3], "mean_multiplier": 3.023,
                           "net_manual_quantity_bonus_at_luck0": 0.02023,
                           "net_manual_quantity_bonus_at_luck10": 0.04046},
        "next_tier_ore_bonus": {"base_probability_per_hit": 0.0015, "tier_offsets": [1,2,3,4],
                                "weights": [8,4,2,1], "amount": 1,
                                "separate_from_new_jackpot_variants": True,
                                "top_tier_policy": "Wenn kein höheres reguläres Erz existiert: Wahrscheinlichkeit dieses Ergebnisses geht in normales Mining über, nicht in Jackpot."},
        "event_resolution": {"single_uniform_roll": True,
                             "mutually_exclusive": ["jackpot_variant", "next_tier_ore", "quantity_bonus", "ordinary"],
                             "normal_result_min_probability_at_luck10": 1 - 2 * (jackpot_rate + 0.0015 + 0.01),
                             "jackpot_replaces_entire_normal_hit": True,
                             "workers_drills_offline_eligible": False,
                             "one_time_backpack_overflow": True},
        "luck": {"max_level": 10, "max_relative_chance_factor": 2, "relative_bonus_per_level": 0.10,
                 "reset_on_prestige": True, "levels": luck,
                 "effects": "Skaliert die drei festen seltenen Ergebniswahrscheinlichkeiten sowie Mengen-/Next-Tier-Proc relativ. Kein Einfluss auf Verkäufe, XP, normalen Erzpreis oder Höhe eines Jackpotpreises."},
        "drill_upgrades": {"max_level": 10, "production_bonus_per_level": 0.04,
                           "upgrade_cost_share": 0.03, "upgrade_cost_growth": 1.18,
                           "max_production_multiplier": 1.36, "levels": drill_levels,
                           "cost_basis_rule": "Fixierter Kaufpreis des jeweiligen Drilltyps, nicht Verkäuferumsatz und nicht Originalpreis vor zusätzlichen versteckten Aufschlägen.",
                           "usefulness_check": "Payback = Mehrkosten / echter zusätzlicher Netto-Cashrate nach Engpässen; Level darf nicht als Voraussetzung für Kauf des nächsten Drilltyps gelten. Wenn Nachfolger sehr nah: Geld sparen darf sinnvoll bleiben."},
        "offline": {"base_efficiency": 0.30, "base_cap_hours": 8, "max_proposed_efficiency": 0.50,
                    "max_proposed_cap_hours": 12, "cash_only": True, "xp": 0, "rare_bonus": 0,
                    "wage_deduction": 0, "reset_upgrades_on_prestige": True,
                    "efficiency_upgrades": efficiency, "duration_upgrades": duration,
                    "cash_formula": "eligible_automatic_gross_cash_per_min * min(actual_offline_minutes, cap_hours*60) * efficiency",
                    "baseline_excludes": ["manual mining", "rare results", "trade", "single historic sales", "uninstalled drills"],
                    "material_rule": "Offline-Cash beansprucht nur neu virtuell erzeugte Menge; keine zusätzliche physische/logische Materialgutschrift. Logout-Bestände unverändert erhalten.",
                    "rounding_rule": "Cash-Anspruch serverseitig samt Bruchteilen persistieren; kleine Reconnects dürfen weder mehrfach auszahlen noch Rundungsverluste aufsummieren.",
                    "capped_base_income_reference_minutes": 144,
                    "capped_max_income_reference_minutes": 360,
                    "online_afk_conflict": "OFFEN / DESIGNENTSCHEIDUNG: Acht Stunden Offline-Cash mit dauerhaftem virtuellen Abnehmer schlagen untätigen Onlinebetrieb bei nur 15 Minuten Lagerspeicher. Rechnerisch unausweichlich, solange Onlineproduktion bei vollem Lager stoppt und Offline nicht. Kein Online-Autosell ungefragt einführen.",
                    "online_afk_comparisons": afk},
        "tests": {"counts": {"ore_types": len(ore_ids), "jackpot_variants": len(variants), "waiting_rows": len(waiting)},
                  "finite_positive_probabilities": all(0 < r["chance_per_hit"] < 1 for r in rarities),
                  "event_probability_sum_at_max_luck_below_one": 2 * (jackpot_rate + 0.0015 + 0.01) < 1,
                  "all_variant_ids_unique": len({v["id"] for v in variants}) == len(variants),
                  "max_drill_upgrade_share": cumulative},
        "limitations": [
            "Keine garantierte Fundzeit. Wahrscheinlichkeiten gelten nur bei erfolgreichen Hits und konstanter Fundchance.",
            "Erwarteter Jackpot-Cashanteil ist zur tierbezogenen Referenzfirma normiert, nicht zum derzeitigen Verkäuferumsatz. Ausgereizte ältere Minen können andere Quoten zeigen.",
            "Neue Varianten derzeit nur Balancevorschläge, nicht im Spiel und nicht für Handel freigegeben.",
            "Offline-Kaufamortisation setzt eine lange Abwesenheit je Rückkehr und konstante Firmenleistung voraus; bei kurzen Sitzungen anders.",
        ],
    }
    assert len(ore_ids) == 50
    assert len(variants) == 150
    assert abs(sum(result["quantity_bonus"]["weights"]) - 100) < 1e-9
    mean = sum(m*w for m,w in zip(result["quantity_bonus"]["multipliers"], result["quantity_bonus"]["weights"])) / 100
    assert abs(mean - result["quantity_bonus"]["mean_multiplier"]) < 1e-10
    assert all(result["tests"][name] for name in ["finite_positive_probabilities", "event_probability_sum_at_max_luck_below_one", "all_variant_ids_unique"])
    return result


if __name__ == "__main__":
    data = make_extras()
    bind_parent_model(data)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "extras.json").write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"status": data["status"], "tests": data["tests"],
                      "expected_cash": data["jackpot_expected_cash_rows"],
                      "offline_base_minutes": data["offline"]["capped_base_income_reference_minutes"]}, ensure_ascii=False))
