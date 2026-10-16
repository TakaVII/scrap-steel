# purpose: Currency and percentage formatting utility with comma separators.
# depends on: RefCounted
# signals emitted: none
# signals listened to: none

class_name NumberFormat
extends RefCounted

static func format_credits(amount: int) -> String:
	var s: String = str(abs(amount))
	var res: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	if amount < 0:
		res = "-" + res
	return res + " cr"

static func format_percent(val: float) -> String:
	return "%d%%" % [int(round(val * 100.0))]
