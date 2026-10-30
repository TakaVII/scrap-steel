# purpose: Contract terms (barter) in ONE place: which terms a client offers, their numbers, what each does to pay / budget / deadline / deposit / material cost, and their description text. Used by barter_panel.gd (preview) and commission_manager.gd (accept_offer) so both always agree. Numbers come from Balance.cfg (Barter group) and ClientRoster.
# depends on: RefCounted, Balance, ClientRoster, CommissionData, NumberFormat, TranslationServer
# signals emitted: none
# signals listened to: none

class_name BarterTerms
extends RefCounted

const TERM_IDS: Dictionary = {
	"deposit": CommissionData.Barter.ADVANCE_DEPOSIT,
	"profit": CommissionData.Barter.PROFIT_SHARE,
	"rush": CommissionData.Barter.RUSH,
	"extended": CommissionData.Barter.EXTENDED,
	"supplied": CommissionData.Barter.SUPPLIED,
}

const NAME_KEYS: Dictionary = {
	CommissionData.Barter.NONE: "NEG_TERM_STANDARD",
	CommissionData.Barter.ADVANCE_DEPOSIT: "NEG_TERM_DEPOSIT",
	CommissionData.Barter.PROFIT_SHARE: "NEG_TERM_PROFIT",
	CommissionData.Barter.RUSH: "NEG_TERM_RUSH",
	CommissionData.Barter.EXTENDED: "NEG_TERM_EXTENDED",
	CommissionData.Barter.SUPPLIED: "NEG_TERM_SUPPLIED",
}

static func name_key(term: int) -> String:
	return NAME_KEYS.get(term, "NEG_TERM_STANDARD")

## Standard first, then the terms this client offers (the Champion Build has no client terms).
static func available(client_id: StringName) -> Array[int]:
	var out: Array[int] = [CommissionData.Barter.NONE]
	for id in ClientRoster.term_ids(client_id):
		out.append(int(TERM_IDS[String(id)]))
	return out

## Share of the pay paid up front (deposit), pay multiplier at quality 90%+ (profit) or rush premium. 0 for other terms.
static func param(client_id: StringName, term: int) -> float:
	match term:
		CommissionData.Barter.ADVANCE_DEPOSIT:
			return ClientRoster.term_value(client_id, "deposit", Balance.cfg.deposit_pct_default)
		CommissionData.Barter.PROFIT_SHARE:
			return ClientRoster.term_value(client_id, "profit", Balance.cfg.profit_high_mult_default)
		CommissionData.Barter.RUSH:
			return ClientRoster.term_value(client_id, "rush", Balance.cfg.rush_pct_default)
	return 0.0

## What the term does to this offer (base_payout / budget_cap already include any raise won in the negotiation).
## Returns {"payout": int, "budget": int, "deadline_days": int, "deposit": int, "cost_mult": float, "param": float}
static func apply(offer: CommissionData, term: int) -> Dictionary:
	var cfg: BalanceConfig = Balance.cfg
	var p: float = param(offer.client_id, term)
	var out: Dictionary = {
		"payout": offer.base_payout, "budget": offer.budget_cap,
		"deadline_days": offer.deadline_days, "deposit": 0, "cost_mult": 1.0, "param": p,
	}
	match term:
		CommissionData.Barter.ADVANCE_DEPOSIT:
			out["deposit"] = roundi(offer.base_payout * p)
			out["payout"] = roundi(offer.base_payout * cfg.deposit_final_mult)
		CommissionData.Barter.PROFIT_SHARE:
			out["budget"] = roundi(offer.budget_cap * cfg.profit_budget_mult)
		CommissionData.Barter.RUSH:
			out["payout"] = roundi(offer.base_payout * (1.0 + p))
			out["deadline_days"] = 1
		CommissionData.Barter.EXTENDED:
			out["payout"] = roundi(offer.base_payout * cfg.extended_payout_mult)
			out["deadline_days"] = offer.deadline_days + cfg.extended_extra_days
		CommissionData.Barter.SUPPLIED:
			out["payout"] = roundi(offer.base_payout * cfg.supplied_payout_mult)
			out["cost_mult"] = cfg.supplied_cost_mult
	return out

static func _t(key: String) -> String:
	return String(TranslationServer.translate(key))

## Plain-language description with this client's numbers.
static func describe(offer: CommissionData, term: int) -> String:
	var cfg: BalanceConfig = Balance.cfg
	var t: Dictionary = apply(offer, term)
	match term:
		CommissionData.Barter.ADVANCE_DEPOSIT:
			return NumberFormat.render(_t("NEG_DESC_DEPOSIT"), {"deposit": NumberFormat.format_credits(int(t["deposit"])), "pct": roundi((1.0 - cfg.deposit_final_mult) * 100.0)})
		CommissionData.Barter.PROFIT_SHARE:
			return NumberFormat.render(_t("NEG_DESC_PROFIT2"), {"mult": "%.2f" % float(t["param"]), "low": "%.2f" % cfg.profit_low_mult, "budget": "%.2f" % cfg.profit_budget_mult})
		CommissionData.Barter.RUSH:
			return NumberFormat.render(_t("NEG_DESC_RUSH2"), {"pct": roundi(float(t["param"]) * 100.0)})
		CommissionData.Barter.EXTENDED:
			return NumberFormat.render(_t("NEG_DESC_EXTENDED"), {"days": cfg.extended_extra_days, "pct": roundi((1.0 - cfg.extended_payout_mult) * 100.0)})
		CommissionData.Barter.SUPPLIED:
			return NumberFormat.render(_t("NEG_DESC_SUPPLIED"), {"mat": roundi((1.0 - cfg.supplied_cost_mult) * 100.0), "pct": roundi((1.0 - cfg.supplied_payout_mult) * 100.0)})
	return _t("NEG_DESC_STANDARD")
