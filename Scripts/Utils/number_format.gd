# purpose: [v3 manual fix] Currency and number formatting preserving Latin digits (0-9) and standard suffixes across all locales including Arabic RTL (spec §C10, §C11, §D9). Adds fmt(): safe replacement for tr(KEY) % value.
# depends on: RefCounted
# signals emitted: none
# signals listened to: none

class_name NumberFormat
extends RefCounted

## Formats integer credits into Latin digits with 'cr' suffix.
## In RTL contexts, keeps Latin numerals intact without reverse mangling.
static func format_credits(amount: int) -> String:
	return "%d cr" % amount

## Formats percentages as Latin digits with '%' suffix.
static func format_percent(val: float) -> String:
	return "%d%%" % int(round(val * 100.0))

## Formats AP values.
static func format_ap(current: int, maximum: int) -> String:
	return "%d / %d" % [current, maximum]

## Formats Day counter.
static func format_day(day: int, max_days: int) -> String:
	return "%d / %d" % [day, max_days]

## Safe replacement for `tr("KEY") % value`. If the key is untranslated (raw key returned) or the
## string has no placeholder, `%` raises "not all arguments converted"; this appends the value instead.
static func fmt(translated: String, value: Variant) -> String:
	if translated.contains("%"):
		return translated % value
	return "%s %s" % [translated, str(value)]
