# purpose: [v2] Currency and number formatting preserving Latin digits (0-9) and standard suffixes across all locales including Arabic RTL (spec §C10, §C11, §D9).
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
