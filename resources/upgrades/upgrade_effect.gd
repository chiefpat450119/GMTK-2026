class_name UpgradeEffect
extends Resource
## A single stat change applied by an Upgrade.
##
## Drag the shared Stat .tres into target_stat. When the owning Upgrade is
## applied, this adds a Modifier to that Stat via Stat.add_mod().
## MULT values are fractional bonuses: 0.1 == +10%.

@export var target_stat: Stat
@export var value: float = 0.0
@export var operation: Modifier.Operation = Modifier.Operation.ADD


# Human readable one-liner, e.g. "+5 Speed" or "+10% Max Time"
func describe() -> String:
	var stat_label := target_stat.stat_name if target_stat else "<UNKNOWN>"
	var prefix := "+" if value >= 0.0 else ""
	match operation:
		Modifier.Operation.MULT:
			return "%s%s%% %s" % [prefix, _trim(value * 100.0), stat_label]
		_:
			return "%s%s %s" % [prefix, _trim(value), stat_label]


# drops a trailing ".0" so 5.0 -> "5" but 2.5 stays "2.5"
func _trim(n: float) -> String:
	if is_equal_approx(n, roundf(n)):
		return str(int(roundf(n)))
	return str(snappedf(n, 0.01))
