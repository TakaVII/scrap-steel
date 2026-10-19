# purpose: [v4] Number and text formatting. Latin digits in every locale. fmt() no longer uses the % operator on translated text (it raised "incomplete format" when a string held a stray %). Adds group() thousands separators and render() for {placeholder} dialogue text.
# depends on: RefCounted
# signals emitted: none
# signals listened to: none

class_name NumberFormat
extends RefCounted

## 1850 -> "1,850". Negative numbers keep the minus sign.
static func group(amount: int) -> String:
	var digits: String = str(absi(amount))
	var out: String = ""
	var count: int = 0
	for i in range(digits.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = digits[i] + out
		count += 1
	return ("-" if amount < 0 else "") + out

static func format_credits(amount: int) -> String:
	return group(amount) + " cr"

static func format_percent(val: float) -> String:
	return "%d%%" % int(round(val * 100.0))

static func format_ap(current: int, maximum: int) -> String:
	return "%d / %d" % [current, maximum]

static func format_day(day: int, max_days: int) -> String:
	return "%d / %d" % [day, max_days]

## Replaces %d / %s in translated text with the value. Never uses the % operator on the
## translation, so a stray "%" (or a CSV row cut at a comma) can no longer crash the game.
static func fmt(translated: String, value: Variant) -> String:
	var v: String = str(value)
	if translated.contains("%d"):
		return translated.replace("%d", v)
	if translated.contains("%s"):
		return translated.replace("%s", v)
	return translated + " " + v

## Replaces {name} placeholders with values from vars. Used by dialogue and tooltips.
static func render(text: String, vars: Dictionary) -> String:
	var out: String = text
	for key in vars.keys():
		out = out.replace("{" + str(key) + "}", str(vars[key]))
	return out
